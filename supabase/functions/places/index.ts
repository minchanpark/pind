import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.112.3';
import { GoogleGenAI } from 'npm:@google/genai@2.24.0';
import { catalogRequest, CatalogError } from './catalog.ts';
import { INSIGHT_SCHEMA, INSIGHT_SYSTEM, insightPrompt, parseInsight } from './insights.ts';

const headers = {
  'Access-Control-Allow-Origin':'*',
  'Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods':'POST, OPTIONS',
  'Content-Type':'application/json; charset=utf-8',
};
const json = (body:unknown,status=200) => new Response(JSON.stringify(body),{status,headers});
declare const EdgeRuntime: {waitUntil(promise: Promise<unknown>): void};
const geminiKey = Deno.env.get('GEMINI_API_KEY');
const gemini = geminiKey ? new GoogleGenAI({apiKey:geminiKey}) : null;

// Runs after the response; a failed refresh retries once its claim expires.
async function refreshInsight(placeId:number) {
  const admin = createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{
    auth:{persistSession:false,autoRefreshToken:false},
  });
  const {data:claimed} = await admin.rpc('claim_place_insight',{p_place_id:placeId});
  if (!claimed) return;
  // ponytail: newest 50 posts only; summarise in batches if places outgrow that.
  const {data:posts,count,error} = await admin.from('posts')
    .select('body,ratings,taste_score,portion_score,ambience_score',{count:'exact'})
    .eq('place_id',placeId).eq('is_public',true).eq('status','published')
    .order('created_at',{ascending:false}).limit(50);
  if (error) throw error;
  const response = await gemini!.models.generateContent({
    model:'gemini-3.8-flash',
    contents:insightPrompt(posts),
    config:{systemInstruction:INSIGHT_SYSTEM,responseMimeType:'application/json',responseJsonSchema:INSIGHT_SCHEMA},
  });
  const finish = response.candidates?.[0]?.finishReason;
  if (finish !== 'STOP' || !response.text) throw new Error(`Insight stopped: ${finish}`);
  const {error:saveError} = await admin.from('place_insights').update({
    ...parseInsight(response.text),post_count:count ?? posts.length,claimed_at:null,updated_at:new Date().toISOString(),
  }).eq('place_id',placeId);
  if (saveError) throw saveError;
}
Deno.serve(async request => {
  if (request.method === 'OPTIONS') return new Response('ok',{headers});
  if (request.method !== 'POST') return json({error:{message:'Use POST.'}},405);
  try {
    const auth = request.headers.get('Authorization');
    if (!auth?.startsWith('Bearer ')) throw new CatalogError(401,'UNAUTHORIZED','로그인이 필요합니다.');
    const client = createClient(Deno.env.get('SUPABASE_URL')!,Deno.env.get('SUPABASE_ANON_KEY')!,{
      global:{headers:{Authorization:auth}},auth:{persistSession:false,autoRefreshToken:false},
    });
    const {data:user,error:authError} = await client.auth.getUser();
    if (authError || !user.user) throw new CatalogError(401,'UNAUTHORIZED','로그인이 필요합니다.');
    let body;
    try { body = await request.json(); } catch { throw new CatalogError(400,'INVALID_JSON','잘못된 요청입니다.'); }
    if (!body || typeof body !== 'object' || Array.isArray(body)) throw new CatalogError(400,'INVALID_JSON','잘못된 요청입니다.');
    return json(await catalogRequest(body,async args => {
      const {data,error} = await client.rpc('get_catalog_places',args);
      if (error) throw new CatalogError(503,'CATALOG_UNAVAILABLE','장소 DB에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.');
      return data;
    },async (paths,bucket) => {
      if(bucket==='post-media')return paths.map(path => client.storage.from(bucket).getPublicUrl(path).data.publicUrl);
      if(bucket!=='post-media-v2')return paths.map(() => null);
      const {data,error}=await client.storage.from(bucket).createSignedUrls(paths,300);
      return error ? paths.map(() => null) : data.map(item => item.error ? null : item.signedUrl);
    },
    Deno.env.get('GOOGLE_FALLBACK_ENABLED') !== 'false',
    placeId => {
      if (gemini) EdgeRuntime.waitUntil(refreshInsight(placeId).catch(error => console.error('insight refresh failed',error)));
    }));
  } catch(error) {
    if (error instanceof CatalogError) return json({error:{code:error.code,message:error.message}},error.status);
    return json({error:{code:'CATALOG_UNAVAILABLE',message:'장소 DB에 연결하지 못했어요.'}},503);
  }
});
