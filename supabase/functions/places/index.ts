import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.112.3';
import { catalogRequest, CatalogError } from './catalog.ts';

const headers = {
  'Access-Control-Allow-Origin':'*',
  'Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info',
  'Access-Control-Allow-Methods':'POST, OPTIONS',
  'Content-Type':'application/json; charset=utf-8',
};
const json = (body:unknown,status=200) => new Response(JSON.stringify(body),{status,headers});
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
    },path => client.storage.from('post-media').getPublicUrl(path).data.publicUrl,
    Deno.env.get('GOOGLE_FALLBACK_ENABLED') !== 'false'));
  } catch(error) {
    if (error instanceof CatalogError) return json({error:{code:error.code,message:error.message}},error.status);
    return json({error:{code:'CATALOG_UNAVAILABLE',message:'장소 DB에 연결하지 못했어요.'}},503);
  }
});
