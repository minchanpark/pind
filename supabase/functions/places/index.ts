import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.112.3';
import { GoogleGenAI } from 'npm:@google/genai@2.24.0';
import { catalogRequest, CatalogError } from './catalog.ts';
import { INSIGHT_SCHEMA, INSIGHT_SYSTEM, INSIGHT_MODELS, insightPrompt, parseInsight, withFallback } from './insights.ts';

const headers = {
  'Access-Control-Allow-Origin':'*',
  'Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods':'POST, OPTIONS',
  'Content-Type':'application/json; charset=utf-8',
};
// Clients cache images by storage path, so a long-lived URL only needs to
// outlast one session; a hidden post's photo stays reachable at most this long.
const SIGNED_URL_SECONDS = 24 * 60 * 60;
const json = (body:unknown,status=200) => new Response(JSON.stringify(body),{status,headers});
declare const EdgeRuntime: {waitUntil(promise: Promise<unknown>): void};
const geminiKey = Deno.env.get('GEMINI_API_KEY');
const gemini = geminiKey ? new GoogleGenAI({apiKey:geminiKey}) : null;

const admin = createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{
  auth:{persistSession:false,autoRefreshToken:false},
});

// Runs after the response. A failure frees the claim and records why;
// claim_place_insight then waits a minute before the next try.
async function refreshInsight(placeId:number,claimed=false) {
  if (!claimed) ({data:claimed} = await admin.rpc('claim_place_insight',{p_place_id:placeId}));
  if (!claimed) return;
  try {
    // ponytail: newest 50 posts only; summarise in batches if places outgrow that.
    const {data:posts,count,error} = await admin.from('posts')
      .select('body,ratings,taste_score,portion_score,ambience_score',{count:'exact'})
      .eq('place_id',placeId).eq('is_public',true).eq('status','published')
      .order('created_at',{ascending:false}).limit(50);
    if (error) throw error;
    let insight = {summary:'',criteria:{}};
    if (posts.length) {
      const response = await withFallback(INSIGHT_MODELS,model => gemini!.models.generateContent({
        model,
        contents:insightPrompt(posts),
        config:{systemInstruction:INSIGHT_SYSTEM,responseMimeType:'application/json',responseJsonSchema:INSIGHT_SCHEMA},
      }));
      const finish = response.candidates?.[0]?.finishReason;
      if (finish !== 'STOP' || !response.text) throw new Error(`Insight stopped: ${finish}`);
      insight = parseInsight(response.text);
    }
    const {error:saveError} = await admin.from('place_insights').update({
      ...insight,post_count:count ?? posts.length,claimed_at:null,last_error:null,failed_at:null,
      updated_at:new Date().toISOString(),
    }).eq('place_id',placeId);
    if (saveError) throw saveError;
  } catch (error) {
    await admin.from('place_insights').update({
      claimed_at:null,failed_at:new Date().toISOString(),last_error:String(error).slice(0,500),
    }).eq('place_id',placeId);
    throw error;
  }
}
const queueInsight = (placeId:number,claimed=false) => {
  if (gemini) EdgeRuntime.waitUntil(refreshInsight(placeId,claimed).catch(error => console.error('insight refresh failed',error)));
};
Deno.serve(async request => {
  if (request.method === 'OPTIONS') return new Response('ok',{headers});
  if (request.method !== 'POST') return json({error:{message:'Use POST.'}},405);
  try {
    const auth = request.headers.get('Authorization');
    if (!auth?.startsWith('Bearer ')) throw new CatalogError(401,'UNAUTHORIZED','로그인이 필요합니다.');
    const client = createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_ANON_KEY')!,{
      global:{headers:{Authorization:auth}},auth:{persistSession:false,autoRefreshToken:false},
    });
    // posts trigger (public.request_place_insight). Only service_role may
    // execute claim_place_insight, so the database itself checks the caller.
    const raw = await request.text();
    const webhook = (() => { try { return JSON.parse(raw)?.refreshInsight; } catch { return undefined; } })();
    if (webhook !== undefined) {
      if (!Number.isSafeInteger(webhook) || webhook <= 0) throw new CatalogError(400,'INVALID_JSON','잘못된 요청입니다.');
      const {data:claimed,error} = await client.rpc('claim_place_insight',{p_place_id:webhook});
      if (error) throw new CatalogError(401,'UNAUTHORIZED','로그인이 필요합니다.');
      if (claimed) queueInsight(webhook,true);
      return json({queued:Boolean(claimed)},202);
    }
    const {data:user,error:authError} = await client.auth.getUser();
    if (authError || !user.user) throw new CatalogError(401,'UNAUTHORIZED','로그인이 필요합니다.');
    let body;
    try { body = JSON.parse(raw); } catch { throw new CatalogError(400,'INVALID_JSON','잘못된 요청입니다.'); }
    if (!body || typeof body !== 'object' || Array.isArray(body)) throw new CatalogError(400,'INVALID_JSON','잘못된 요청입니다.');
    return json(await catalogRequest(body,async args => {
      const {data,error} = await client.rpc('get_catalog_places',args);
      if (error) throw new CatalogError(503,'CATALOG_UNAVAILABLE','장소 DB에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.');
      return data;
    },async (paths,bucket) => {
      if(bucket==='post-media')return paths.map(path => client.storage.from(bucket).getPublicUrl(path).data.publicUrl);
      if(bucket!=='post-media-v2')return paths.map(() => null);
      const {data,error}=await client.storage.from(bucket).createSignedUrls(paths,SIGNED_URL_SECONDS);
      return error ? paths.map(() => null) : data.map(item => item.error ? null : item.signedUrl);
    },
    Deno.env.get('GOOGLE_FALLBACK_ENABLED') !== 'false',
    queueInsight));
  } catch(error) {
    if (error instanceof CatalogError) return json({error:{code:error.code,message:error.message}},error.status);
    return json({error:{code:'CATALOG_UNAVAILABLE',message:'장소 DB에 연결하지 못했어요.'}},503);
  }
});
