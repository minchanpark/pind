#!/usr/bin/env node
// 100 new places × 3 trials × 2 methods. No database writes.
import {readFileSync, writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {englishNameRequest, ENGLISH_NAME_POLICY, parseEnglishNameResponse} from '../../supabase/functions/places/names-en.ts';
import {hybridNameRequest, buildHybridName, HYBRID_POLICY} from './hybrid.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
export const normalizeName = s => s.normalize('NFD').replace(/[\u0300-\u036f]/gu, '').toLowerCase()
  .replace(/&/gu, ' and ').replace(/[^\p{L}\p{N}]/gu, '');
export const matchesReference = (c, answer) => Boolean(answer && c.en.some(en => normalizeName(en) === normalizeName(answer)));

export function checkedItems(data, names) {
  const choice = data?.choices?.[0];
  const content = choice?.message?.content;
  if (choice?.message?.reasoning_content || choice?.message?.reasoning || /<\/?think\b/iu.test(content ?? '') ||
      data?.usage?.completion_tokens_details?.reasoning_tokens !== 0) throw new Error('Reasoning is not confirmed zero');
  if (choice?.finish_reason !== 'stop' || typeof content !== 'string') throw new Error('Incomplete response');
  const items = JSON.parse(content)?.items;
  if (!Array.isArray(items) || items.length !== names.length) throw new Error('Wrong result count');
  return items;
}

async function generate(method, trial, batch, cases, key, run) {
  const names = cases.map(c => c.ko);
  const request = method === 'baseline' ? englishNameRequest(names) : hybridNameRequest(names);
  const prefix = path.join(run, `${method}-trial-${trial}-batch-${batch}`);
  const save = (suffix, value) => writeFileSync(prefix + suffix + '.json', JSON.stringify(value, null, 2) + '\n');
  save('.request', request);
  const started = Date.now();
  let data;
  const response = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
    method: 'POST', headers: {Authorization: `Bearer ${key}`, 'Content-Type': 'application/json'},
    body: JSON.stringify(request), signal: AbortSignal.timeout(180_000),
  });
  data = await response.json();
  save('.response', data);
  if (!response.ok) throw new Error(`NVIDIA HTTP ${response.status}: ${JSON.stringify(data?.error ?? data?.detail)}`);
  const items = checkedItems(data, names);
  const results = cases.map((c, i) => {
    let answer, error;
    try {
      answer = method === 'hybrid' ? buildHybridName(items[i], c.ko) :
        parseEnglishNameResponse({...data, choices: [{finish_reason: 'stop', message: {content: JSON.stringify({items: [items[i]]})}}]}, [c.ko])[0];
    } catch (e) {error = e.message;}
    return {id: c.id, ko: c.ko, group: c.group, ambiguous_source: c.ambiguous_source,
      en: answer?.en ?? null, parts: answer?.parts, accepted: c.en, error,
      ok: matchesReference(c, answer?.en)};
  });
  const report = {method, trial, batch, model: data.model,
    policy: method === 'hybrid' ? HYBRID_POLICY : ENGLISH_NAME_POLICY,
    request_sha256: createHash('sha256').update(JSON.stringify(request)).digest('hex'),
    usage: data.usage, reasoning_tokens: data.usage.completion_tokens_details.reasoning_tokens,
    duration_ms: Date.now() - started, total: cases.length, passed: results.filter(r => r.ok).length, results};
  save('', report);
  console.log(`${method} trial=${trial} batch=${batch}: ${report.passed}/${report.total}, ${Math.round(report.duration_ms/1000)}s, reasoning=0`);
  return report;
}

export function aggregate(cases, reports) {
  const methods = {};
  for (const method of ['baseline', 'hybrid']) {
    const trials = [1, 2, 3].map(trial => reports.filter(r => r.method === method && r.trial === trial).flatMap(r => r.results));
    if (trials.some(t => t.length !== cases.length || new Set(t.map(r => r.id)).size !== cases.length)) throw new Error('Incomplete trial');
    const combined = cases.map(c => {
      const candidates = trials.map((t, i) => ({trial: i + 1, ...t.find(r => r.id === c.id)}));
      const valid = candidates.filter(r => r.ok);
      const preference = r => c.en.findIndex(en => normalizeName(en) === normalizeName(r.en));
      valid.sort((a, b) => preference(a) - preference(b) || a.trial - b.trial);
      const counts = candidates.reduce((map, r) => {
        if (r.en) map.set(normalizeName(r.en), (map.get(normalizeName(r.en)) ?? 0) + 1);
        return map;
      }, new Map());
      const consensus = candidates.find(r => r.en && counts.get(normalizeName(r.en)) >= 2);
      return {id: c.id, ko: c.ko, group: c.group, ambiguous_source: c.ambiguous_source,
        accepted: c.en, candidates: candidates.map(r => ({trial: r.trial, en: r.en, ok: r.ok, error: r.error})),
        selected_en: valid[0]?.en ?? null, selected_trial: valid[0]?.trial ?? null,
        // Correct-candidate coverage uses the held-out reference as a judge.
        // Agreement is reported separately: repeated agreement can be wrong.
        majority_en: consensus?.en ?? null, majority_correct: Boolean(consensus?.ok)};
    });
    const perGroup = Object.fromEntries(['romanize','restore','branch','latin_number'].map(group => {
      const rows = combined.filter(c => c.group === group);
      return [group, {places: rows.length, correct_responses: trials.flat().filter(r => r.group === group && r.ok).length,
        total_responses: rows.length * 3, best_of_three: rows.filter(r => r.selected_en).length}];
    }));
    methods[method] = {trial_passed: trials.map(t => t.filter(r => r.ok).length),
      response_passed: trials.flat().filter(r => r.ok).length, response_total: cases.length * 3,
      best_of_three: combined.filter(r => r.selected_en).length,
      majority_correct: combined.filter(r => r.majority_correct).length,
      no_consensus: combined.filter(r => !r.majority_en).length,
      invalid_responses: trials.flat().filter(r => r.error).length,
      clear_source_best_of_three: combined.filter(r => !r.ambiguous_source && r.selected_en).length,
      clear_source_total: combined.filter(r => !r.ambiguous_source).length,
      groups: perGroup, results: combined};
  }
  return methods;
}

async function main() {
  if (process.argv.length > 2) throw new Error('Usage: node scripts/name-eval/benchmark.mjs');
  if (!process.env.NVDIA_API_KEY && !process.env.NVIDIA_API_KEY && existsSync(path.join(ROOT,'.env'))) process.loadEnvFile(path.join(ROOT,'.env'));
  const key = process.env.NVDIA_API_KEY ?? process.env.NVIDIA_API_KEY;
  if (!key) throw new Error('Missing NVDIA_API_KEY');
  const fixturePath = path.join(ROOT,'scripts/name-eval/name_english_100.golden.json');
  const bytes = readFileSync(fixturePath);
  const fixture = JSON.parse(bytes);
  const cases = fixture.cases;
  if (cases.length !== 100 || new Set(cases.map(c => c.ko)).size !== 100) throw new Error('Expected 100 distinct names');
  const old = JSON.parse(readFileSync(path.join(ROOT,'supabase/functions/places/name_english.golden.json'),'utf8')).cases;
  if (cases.some(c => old.some(p => p.ko === c.ko))) throw new Error('Old test name leaked into holdout');
  const run = path.join(ROOT,'artifacts/name-english-100-20261005',`comparison-${new Date().toISOString().replace(/[:.]/gu,'-')}`);
  mkdirSync(run,{recursive:true});
  writeFileSync(path.join(run,'fixture.json'),bytes);
  const tasks=[];
  for (const method of ['baseline','hybrid']) for (const trial of [1,2,3]) {
    for(let i=0;i<100;i+=25) tasks.push({method,trial,batch:i/25+1,cases:cases.slice(i,i+25)});
  }
  const reports=[],failures=[];
  let cursor=0;
  // Four independent requests at a time, 24 calls in total. No model retries.
  await Promise.all(Array.from({length:4},async()=>{
    while(cursor<tasks.length){
      const task=tasks[cursor++];
      try{reports.push(await generate(task.method,task.trial,task.batch,task.cases,key,run));}
      catch(e){failures.push({...task,cases:task.cases.map(c=>c.id),error:e.message});console.log(`FAILED ${task.method} ${task.trial}/${task.batch}: ${e.message}`);}
    }
  }));
  writeFileSync(path.join(run,'run-status.json'),JSON.stringify({calls:24,completed:reports.length,failures},null,2)+'\n');
  if(failures.length) throw new Error(`Incomplete benchmark; see ${run}`);
  const summary={generated_at:new Date().toISOString(),fixture_sha256:createHash('sha256').update(bytes).digest('hex'),
    total_places:100,trials_per_method:3,methods:aggregate(cases,reports),
    model_calls:24,reasoning_tokens:reports.reduce((n,r)=>n+r.reasoning_tokens,0),
    total_usage:{prompt_tokens:reports.reduce((n,r)=>n+r.usage.prompt_tokens,0),completion_tokens:reports.reduce((n,r)=>n+r.usage.completion_tokens,0)},
    applied_to_database:false,selection_is_reference_assisted:true};
  writeFileSync(path.join(run,'summary.json'),JSON.stringify(summary,null,2)+'\n');
  for(const [name,m] of Object.entries(summary.methods)) console.log(`${name}: trials ${m.trial_passed.join(',')}; best of 3 ${m.best_of_three}/100; majority ${m.majority_correct}/100`);
  console.log(`Saved ${run}`);
}

if(process.argv[1]===fileURLToPath(import.meta.url)) await main();
