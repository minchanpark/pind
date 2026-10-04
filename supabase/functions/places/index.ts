import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.112.3';
import { GoogleGenAI } from 'npm:@google/genai@2.24.0';
import { catalogRequest, CatalogError } from './catalog.ts';
import { INSIGHT_SCHEMA, INSIGHT_SYSTEM, INSIGHT_MODELS, TRANSLATE_SYSTEM, insightPrompt, parseInsight, translatePrompt, withFallback } from './insights.ts';
import { AGENT_SCHEMA, AGENT_SYSTEM, type AgentPlan, fallbackPlan, parseAgentPlan, tastePlan } from './agent.ts';
import { walkingRoute } from './walking.ts';
import { groqJson } from './llm.ts';
import { geocodeArea } from './area.ts';

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
const groqKey = Deno.env.get('GROQ_API_KEY');
const hasLlm = Boolean(groqKey || gemini);

/// JSON text from Groq, else Gemini when Groq is missing or fails.
async function askJson(system:string,user:string,schema:object,geminiDelay?:number): Promise<string> {
  if (groqKey) {
    try {
      return await groqJson(groqKey,system,user,schema);
    } catch (error) {
      if (!gemini) throw error;
      console.error('groq failed, trying gemini',error);
    }
  }
  const response = await withFallback(INSIGHT_MODELS,model => gemini!.models.generateContent({
    model,
    contents:user,
    config:{systemInstruction:system,responseMimeType:'application/json',responseJsonSchema:schema},
  }),geminiDelay);
  const finish = response.candidates?.[0]?.finishReason;
  if (finish !== 'STOP' || !response.text) throw new Error(`Gemini stopped: ${finish}`);
  return response.text;
}

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
      insight = parseInsight(await askJson(INSIGHT_SYSTEM,insightPrompt(posts),INSIGHT_SCHEMA));
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
/// Sentence → search plan; if no model can read it, the sentence's words.
const LANGS = new Set(['ko','en','ja','zh-Hans','zh-Hant']);
/// The app's language as a tag the agent prompt knows; Korean otherwise.
const langOf = (v:unknown) => {
  const tag = typeof v === 'string' ? (v === 'zh' ? 'zh-Hans' : v) : 'ko';
  return LANGS.has(tag) ? tag : 'ko';
};
async function agentPlan(query:string,lang='ko'): Promise<AgentPlan> {
  if (!hasLlm) return fallbackPlan(query);
  try {
    return parseAgentPlan(await askJson(AGENT_SYSTEM,
      `<query>${query}</query>\n<label_language>${lang}</label_language>`,AGENT_SCHEMA,500));
  } catch (error) {
    console.error('agent plan failed',error);
    return fallbackPlan(query);
  }
}

/// A summary in another language, cached until the place's post count
/// moves; any failure keeps the Korean.
async function translateInsight(placeId:number,postCount:number,insight:Record<string,unknown>,lang:string) {
  if (!hasLlm) return null;
  const {data:cached} = await admin.from('place_insight_translations').select('summary,criteria,post_count')
    .eq('place_id',placeId).eq('lang',lang).maybeSingle();
  if (cached && cached.post_count === postCount) return {summary:cached.summary,criteria:cached.criteria};
  const source = {summary:String(insight.summary ?? ''),criteria:(insight.criteria ?? {}) as Record<string,string>};
  const translated = parseInsight(await askJson(TRANSLATE_SYSTEM,translatePrompt(source,lang),INSIGHT_SCHEMA));
  await admin.from('place_insight_translations').upsert({place_id:placeId,lang,post_count:postCount,
    summary:translated.summary,criteria:translated.criteria,updated_at:new Date().toISOString()});
  return translated;
}

const queueInsight = (placeId:number,claimed=false) => {
  if (hasLlm) EdgeRuntime.waitUntil(refreshInsight(placeId,claimed).catch(error => console.error('insight refresh failed',error)));
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
    if (body.action === 'walking_route') return json(await walkingRoute(body,Deno.env.get('TMAP_APP_KEY')));
    if (body.action === 'agent_search') {
      const q = typeof body.query === 'string' ? body.query.trim() : '';
      if (q.length < 2 || q.length > 120) throw new CatalogError(400,'INVALID_QUERY','검색어를 2~120자로 입력해 주세요.');
      let plan:AgentPlan = await agentPlan(q,langOf(body.lang));
      // "Pick for me": the app's onboarding foods and occasions fill it in.
      if (plan.personal) plan = tastePlan(plan,body.cuisines,body.occasions);
      // A named area searches around it instead of the map center.
      const area = plan.area ? await geocodeArea(plan.area,Deno.env.get('GOOGLE_PLACES_API_KEY')) : null;
      body = {...body,...plan,...(area ?? {})};
    }
    return json(await catalogRequest(body,async (args,fn) => {
      const {data,error} = await client.rpc(fn ?? 'get_catalog_places',args);
      if (error) throw new CatalogError(503,'CATALOG_UNAVAILABLE','장소 DB에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.');
      return data;
    },async (paths,bucket) => {
      if(bucket==='post-media')return paths.map(path => client.storage.from(bucket).getPublicUrl(path).data.publicUrl);
      if(bucket!=='post-media-v2')return paths.map(() => null);
      const {data,error}=await client.storage.from(bucket).createSignedUrls(paths,SIGNED_URL_SECONDS);
      return error ? paths.map(() => null) : data.map(item => item.error ? null : item.signedUrl);
    },
    Deno.env.get('GOOGLE_FALLBACK_ENABLED') !== 'false',
    queueInsight,translateInsight));
  } catch(error) {
    if (error instanceof CatalogError) return json({error:{code:error.code,message:error.message}},error.status);
    return json({error:{code:'CATALOG_UNAVAILABLE',message:'장소 DB에 연결하지 못했어요.'}},503);
  }
});
