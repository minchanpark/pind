#!/usr/bin/env node
// Resumable translation of the complete published catalog, with DB backups.
import {readFileSync,writeFileSync,mkdirSync,existsSync,appendFileSync,unlinkSync,renameSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {setTimeout as sleep} from 'node:timers/promises';
import {romanize} from 'koroman';
import {englishNameRequest,parseEnglishNameResponse,ENGLISH_NAME_MODEL,ENGLISH_NAME_POLICY} from '../../supabase/functions/places/names-en.ts';
import {normalizeName} from './benchmark.mjs';
import {buildNameSaveSql} from '../save_best_name_english.mjs';

const ROOT=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const REF='mkfgqobwededpzdekvxg';
const PENDING=/[\p{Script=Hangul}\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}]/u;
const digest=s=>createHash('sha256').update(s).digest('hex');
const dump=(file,data)=>{
  const temp=file+'.tmp';writeFileSync(temp,JSON.stringify(data,null,2)+'\n');renameSync(temp,file);
};
export const needsEnglish=r=>!r.name_en?.trim()||PENDING.test(r.name_en);

export function catalogGroups(rows){
  const groups=new Map();
  for(const r of rows){
    if(!r.is_published||r.is_demo||r.is_reference_only||!['sbiz','pind'].includes(r.external_provider)||!needsEnglish(r))continue;
    if(!Number.isSafeInteger(r.id)||r.id<1||typeof r.name_ko!=='string'||!r.name_ko.trim())throw new Error('Invalid catalog row');
    if(!groups.has(r.name_ko))groups.set(r.name_ko,{ko:r.name_ko,rows:[]});
    groups.get(r.name_ko).rows.push(r);
  }
  return [...groups.values()].sort((a,b)=>a.rows[0].id-b.rows[0].id);
}

function distance(a,b){
  let previous=Array.from({length:b.length+1},(_,i)=>i);
  for(let i=1;i<=a.length;i++){
    const next=[i];
    for(let j=1;j<=b.length;j++)next[j]=Math.min(next[j-1]+1,previous[j]+1,previous[j-1]+Number(a[i-1]!==b[j-1]));
    previous=next;
  }
  return previous[b.length];
}
const REQUIRED_LOANS={'커피':'coffee','카페':'cafe','치킨':'chicken','피자':'pizza','버거':'burger','베이커리':'bakery','브런치':'brunch','스시':'sushi'};

export function chooseBulkName(ko,candidates,reference){
  const violations=en=>Object.entries(REQUIRED_LOANS).filter(([text,target])=>ko.includes(text)&&
    !normalizeName(en).includes(target)&&!(target==='cafe'&&normalizeName(en).includes('caffe')));
  const digits=s=>JSON.stringify((s.normalize('NFKC').match(/\d+/gu)??[]).sort());
  const valid=candidates.filter(c=>c.en&&!violations(c.en).length&&
    digits(ko)===digits(c.en)&&
    (!reference||reference.some(en=>normalizeName(en)===normalizeName(c.en))));
  if(!valid.length)return {ko,en:null,reason:'no_valid_candidate',candidates};
  const expected=normalizeName(romanize(ko,{usePronunciationRules:true}));
  const votes=c=>valid.filter(v=>normalizeName(v.en)===normalizeName(c.en)).length;
  const rank=c=>reference?reference.findIndex(en=>normalizeName(en)===normalizeName(c.en)):0;
  valid.sort((a,b)=>rank(a)-rank(b)||votes(b)-votes(a)||
    distance(normalizeName(a.en),expected)-distance(normalizeName(b.en),expected)||a.trial-b.trial);
  const winner=valid[0];
  return {ko,en:winner.en,source_trial:winner.trial,agreement:votes(winner),
    reason:reference?'reviewed_reference':votes(winner)>=2?'agreement':'no_agreement_phonetic_tiebreak',
    needs_review:!reference&&votes(winner)<2,candidates};
}

export function decodeBulkResponse(data,names){
  // Enforce reasoning=0 before considering any individual item.
  const choice=data?.choices?.[0];
  if(choice?.message?.reasoning_content||choice?.message?.reasoning||/<\/?think\b/iu.test(choice?.message?.content??'')||
    data?.usage?.completion_tokens_details?.reasoning_tokens!==0)throw new Error('Reasoning is not confirmed zero');
  if(choice?.finish_reason!=='stop')throw new Error(`Incomplete response: ${choice?.finish_reason}`);
  const items=JSON.parse(choice.message.content)?.items;
  if(!Array.isArray(items))throw new Error('Invalid items');
  const byKo=new Map();
  const duplicate=new Set();
  for(const item of items){
    if(!names.includes(item?.ko))continue;
    if(byKo.has(item.ko))duplicate.add(item.ko);
    byKo.set(item.ko,item);
  }
  return names.map(ko=>{
    const item=byKo.get(ko);
    if(!item||duplicate.has(ko))return {ko,en:null,error:'missing_or_duplicate_source'};
    try{
      const answer=parseEnglishNameResponse({...data,choices:[{finish_reason:'stop',message:{content:JSON.stringify({items:[item]})}}]},[ko])[0];
      if(/[^\p{Script=Latin}\p{Number}\p{Punctuation}\p{Separator}\p{Symbol}]/u.test(answer.en))throw new Error('Not Latin-script English');
      return answer;
    }catch(e){return {ko,en:null,error:e.message};}
  });
}

function query(sql){
  const r=spawnSync('npx',['-y','supabase@2.118.0','db','query','--linked','--file','/dev/stdin','--output','json'],
    {cwd:ROOT,input:sql,encoding:'utf8',maxBuffer:128*1024*1024,timeout:180_000});
  if(r.error)throw r.error;
  if(r.status!==0)throw new Error(`Database query failed: ${r.stderr.slice(0,400)}`);
  const data=JSON.parse(r.stdout);if(!Array.isArray(data.rows))throw new Error('Expected database rows');return data.rows;
}
const readRows=ids=>query(`select id,name_ko,name_en,external_provider,is_published,is_demo,is_reference_only from public.places where id in (${ids.join(',')}) order by id;`);

async function generateTrial(names,trial,dir,key){
  const prefix=path.join(dir,`trial-${trial}`);
  const request={...englishNameRequest(names),max_tokens:Math.max(4096,names.length*48)};
  if(existsSync(prefix+'.json')){
    const cached=JSON.parse(readFileSync(prefix+'.json','utf8'));
    if(cached.model!==ENGLISH_NAME_MODEL||cached.reasoning_tokens!==0||
      cached.request_sha256!==digest(JSON.stringify(request))||cached.results.length!==names.length||
      cached.results.some((r,i)=>r.ko!==names[i]))throw new Error('Checkpoint request or sources differ');
    return cached;
  }
  dump(prefix+'.request.json',request);
  for(let attempt=1;attempt<=3;attempt++){
    const started=Date.now();
    try{
      const response=await fetch('https://integrate.api.nvidia.com/v1/chat/completions',{
        method:'POST',headers:{Authorization:`Bearer ${key}`,'Content-Type':'application/json'},
        body:JSON.stringify(request),signal:AbortSignal.timeout(600_000),
      });
      const data=await response.json();dump(prefix+`.attempt-${attempt}.response.json`,data);
      if(!response.ok){
        const message=String(data?.error?.message??JSON.stringify(data?.detail??'request failed')).replaceAll(key,'[redacted]');
        const error=Object.assign(new Error(`NVIDIA ${response.status}: ${message}`),{status:response.status});
        if([401,402,403,404].includes(response.status))throw error;
        if([429,500,502,503,504].includes(response.status)&&attempt<3){await sleep(attempt*15_000);continue;}
        throw error;
      }
      const results=decodeBulkResponse(data,names);
      const report={trial,model:data.model,policy:ENGLISH_NAME_POLICY,request_sha256:digest(JSON.stringify(request)),
        usage:data.usage,reasoning_tokens:data.usage.completion_tokens_details.reasoning_tokens,
        duration_ms:Date.now()-started,results};
      if(report.model!==ENGLISH_NAME_MODEL)throw new Error('Unexpected response model');
      dump(prefix+'.json',report);return report;
    }catch(e){
      if([401,402,403,404].includes(e.status)||/Reasoning|Unexpected response model/.test(e.message))throw e;
      if(attempt===3)throw e;
      await sleep(attempt*10_000);
    }
  }
}

export function parseOptions(argv){
  const options={apply:false,batchSize:250,workers:4,resume:null,snapshot:null};
  for(let i=0;i<argv.length;i++){
    const arg=argv[i];
    if(arg==='--apply')options.apply=true;
    else if(arg==='--batch-size')options.batchSize=Number(argv[++i]);
    else if(arg==='--workers')options.workers=Number(argv[++i]);
    else if(arg==='--resume')options.resume=argv[++i];
    else if(arg==='--snapshot')options.snapshot=argv[++i];
    else throw new Error(`Unknown option ${arg}`);
  }
  if(!Number.isInteger(options.batchSize)||options.batchSize<10||options.batchSize>1000||
    !Number.isInteger(options.workers)||options.workers<1||options.workers>12)throw new Error('Invalid batch size or workers');
  return options;
}

async function main(){
  const options=parseOptions(process.argv.slice(2));
  const linked=JSON.parse(readFileSync(path.join(ROOT,'supabase/.temp/linked-project.json'),'utf8'));
  if(linked.ref!==REF||linked.name!=='Pind')throw new Error('Unexpected linked project');
  if(!process.env.NVDIA_API_KEY&&!process.env.NVIDIA_API_KEY)process.loadEnvFile(path.join(ROOT,'.env'));
  const key=process.env.NVDIA_API_KEY??process.env.NVIDIA_API_KEY;if(!key)throw new Error('Missing NVDIA_API_KEY');
  const run=options.resume?path.resolve(ROOT,options.resume):path.join(ROOT,'artifacts/name-english-full-20261005',`run-${new Date().toISOString().replace(/[:.]/gu,'-')}`);
  mkdirSync(run,{recursive:true});
  const lock=path.join(run,'process.json');
  if(existsSync(lock)){
    const pid=JSON.parse(readFileSync(lock,'utf8')).pid;
    try{process.kill(pid,0);throw new Error('Run is already active');}catch(e){if(e.message==='Run is already active')throw e;}
  }
  dump(lock,{pid:process.pid,started_at:new Date().toISOString()});
  let rows;
  if(existsSync(path.join(run,'before.json')))rows=JSON.parse(readFileSync(path.join(run,'before.json'),'utf8')).rows;
  else{
    const snapshot=options.snapshot?JSON.parse(readFileSync(path.resolve(ROOT,options.snapshot),'utf8')):
      {rows:query("select id,name_ko,name_en,external_provider,category,is_published,is_demo,is_reference_only from public.places where is_published and not is_demo and not is_reference_only and external_provider in ('sbiz','pind') order by id;")};
    dump(path.join(run,'before.json'),snapshot);rows=snapshot.rows;
  }
  let config;
  if(existsSync(path.join(run,'config.json'))){
    config=JSON.parse(readFileSync(path.join(run,'config.json'),'utf8'));
    if(config.apply!==options.apply)throw new Error('Apply mode differs from checkpoint');
    if(config.model!==ENGLISH_NAME_MODEL||config.policy!==ENGLISH_NAME_POLICY||
      config.snapshot_sha256!==digest(JSON.stringify(rows)))throw new Error('Checkpoint snapshot or policy differs');
    options.batchSize=config.batchSize;
  }else{
    config={...options,project_ref:REF,model:ENGLISH_NAME_MODEL,policy:ENGLISH_NAME_POLICY,snapshot_sha256:digest(JSON.stringify(rows))};
    dump(path.join(run,'config.json'),config);
  }
  const groups=catalogGroups(rows),references=new Map();
  for(const file of ['supabase/functions/places/name_english.golden.json','scripts/name-eval/name_english_100.golden.json']){
    for(const c of JSON.parse(readFileSync(path.join(ROOT,file),'utf8')).cases)references.set(c.ko,c.en);
  }
  const state={started_at:JSON.parse(readFileSync(lock,'utf8')).started_at,updated_at:new Date().toISOString(),
    status:'running',pid:process.pid,run,model:ENGLISH_NAME_MODEL,policy:ENGLISH_NAME_POLICY,apply:options.apply,
    catalog_rows:rows.length,pending_rows:groups.reduce((n,g)=>n+g.rows.length,0),distinct_names:groups.length,
    total_batches:Math.ceil(groups.length/options.batchSize),completed_batches:0,failed_batches:0,
    processed_names:0,selected_names:0,unselected_names:0,needs_review_names:0,updated_rows:0,verified_rows:0,
    conflicts:0,reasoning_tokens:0,errors:[]};
  const batches=Array.from({length:state.total_batches},(_,i)=>groups.slice(i*options.batchSize,(i+1)*options.batchSize));
  let cursor=0,fatal=null,writer=Promise.resolve();
  const progress=()=>{state.updated_at=new Date().toISOString();dump(path.join(run,'progress.json'),state);};
  const heartbeat=setInterval(progress,15_000);progress();
  console.log(`START ${run}: ${groups.length} distinct names / ${state.pending_rows} rows, ${state.total_batches} batches`);
  const addReceipt=receipt=>{
    state.completed_batches++;state.processed_names+=receipt.processed_names;state.selected_names+=receipt.selected_names;
    state.unselected_names+=receipt.unselected_names;state.needs_review_names+=receipt.needs_review_names;
    state.updated_rows+=receipt.updated_rows;state.verified_rows+=receipt.verified_rows;state.conflicts+=receipt.conflicts;
    state.reasoning_tokens+=receipt.reasoning_tokens;
  };
  try{
    await Promise.all(Array.from({length:options.workers},async()=>{
      while(cursor<batches.length&&!fatal){
        const index=cursor++,batch=batches[index],dir=path.join(run,`batch-${String(index+1).padStart(5,'0')}`);
        mkdirSync(dir,{recursive:true});
        const receiptFile=path.join(dir,'receipt.json');
        if(existsSync(receiptFile)){addReceipt(JSON.parse(readFileSync(receiptFile,'utf8')));continue;}
        try{
          const names=batch.map(g=>g.ko);
          const attempts=await Promise.allSettled([1,2,3].map(t=>generateTrial(names,t,dir,key)));
          const failed=attempts.find(a=>a.status==='rejected');if(failed)throw failed.reason;
          const trials=attempts.map(a=>a.value);
          const selection=batch.map((g,i)=>({...chooseBulkName(g.ko,trials.map(t=>({trial:t.trial,...t.results[i]})),references.get(g.ko)),rows:g.rows}));
          dump(path.join(dir,'selection.json'),selection);
          const chosen=selection.filter(s=>s.en).flatMap(s=>s.rows.map(p=>({id:p.id,ko:s.ko,en:s.en})));
          const before=batch.flatMap(g=>g.rows);
          const receipt={batch:index+1,processed_names:batch.length,selected_names:selection.filter(s=>s.en).length,
            unselected_names:selection.filter(s=>!s.en).length,needs_review_names:selection.filter(s=>s.needs_review).length,
            updated_rows:0,verified_rows:0,conflicts:0,reasoning_tokens:trials.reduce((n,t)=>n+t.reasoning_tokens,0),completed_at:null};
          writer=writer.catch(()=>{}).then(async()=>{
            if(options.apply&&chosen.length){
              const updated=[];
              for(let off=0;off<chosen.length;off+=500){
                const chunk=chosen.slice(off,off+500),sql=buildNameSaveSql(chunk,before);
                writeFileSync(path.join(dir,`apply-${off/500+1}.sql`),sql+'\n');
                updated.push(...query(sql));
              }
              dump(path.join(dir,'updated.json'),updated);
              const after=[];
              for(let off=0;off<chosen.length;off+=1000)after.push(...readRows(chosen.slice(off,off+1000).map(s=>s.id)));
              dump(path.join(dir,'after.json'),after);
              const byId=new Map(after.map(p=>[p.id,p]));
              receipt.updated_rows=updated.length;
              receipt.verified_rows=chosen.filter(s=>byId.get(s.id)?.name_ko===s.ko&&byId.get(s.id)?.name_en===s.en).length;
              receipt.conflicts=chosen.length-receipt.verified_rows;
            }
            receipt.completed_at=new Date().toISOString();dump(receiptFile,receipt);addReceipt(receipt);progress();
            appendFileSync(path.join(run,'events.jsonl'),JSON.stringify(receipt)+'\n');
            console.log(`BATCH ${index+1}/${batches.length}: ${receipt.selected_names}/${batch.length} names; verified ${receipt.verified_rows}; overall ${state.processed_names}/${groups.length}`);
          });
          await writer;
        }catch(e){
          const error={batch:index+1,message:String(e.message).replaceAll(key,'[redacted]')};
          dump(path.join(dir,'error.json'),error);state.failed_batches++;state.errors.push(error);
          console.log(`ERROR batch=${index+1} ${error.message}`);
          if([401,402,403,404].includes(e.status)||/Reasoning|Unexpected response model/.test(e.message))fatal=error;
          progress();
        }
      }
    }));
    state.status=fatal?'blocked':state.failed_batches?'retry_needed':'completed';
    state.finished_at=new Date().toISOString();progress();
    console.log(`FINISH ${JSON.stringify(state)}`);
  }finally{
    clearInterval(heartbeat);unlinkSync(lock);
  }
}

if(process.argv[1]===fileURLToPath(import.meta.url))await main();
