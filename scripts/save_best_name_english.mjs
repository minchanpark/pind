#!/usr/bin/env node
// Three independent trials of the reviewed 20-place set, then best valid answer.
import {mkdirSync, readFileSync, writeFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {runEnglishNameEvaluation, looseEnglishName} from './eval_name_english.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const PROJECT_REF = 'mkfgqobwededpzdekvxg';
const literal = value => `'${String(value).replaceAll("'", "''")}'`;

export function selectBestEnglishNames(cases, trials) {
  if (trials.length !== 3) throw new Error('Exactly three completed trials are required');
  if (new Set(trials.map(t => t.request_sha256)).size !== 1) throw new Error('Trial requests differ');
  for (const trial of trials) {
    if (trial.reasoning_content_present || trial.reasoning_tokens !== 0 ||
        trial.results.length !== cases.length || trial.results.some((r, i) => r.id !== cases[i].id || r.ko !== cases[i].ko)) {
      throw new Error('Invalid trial identities or reasoning');
    }
  }
  return cases.map((c, i) => {
    const candidates = trials.map((trial, n) => ({trial: n + 1, en: trial.results[i].en}));
    const valid = candidates.filter(r => c.en.some(en => looseEnglishName(en) === looseEnglishName(r.en)));
    const preference = r => c.en.findIndex(en => looseEnglishName(en) === looseEnglishName(r.en));
    const count = r => valid.filter(v => looseEnglishName(v.en) === looseEnglishName(r.en)).length;
    // Reviewed spelling preference first, agreement second, exact formatting third.
    valid.sort((a, b) => preference(a) - preference(b) || count(b) - count(a) ||
      Number(c.en.includes(b.en)) - Number(c.en.includes(a.en)) || a.trial - b.trial);
    return {id: c.id, ko: c.ko, en: valid[0]?.en ?? null, source_trial: valid[0]?.trial ?? null,
      valid_trials: valid.length, candidates, status: valid.length ? 'selected' : 'no_valid_candidate'};
  });
}

function query(sql) {
  const r = spawnSync('npx', ['-y', 'supabase@2.118.0', 'db', 'query', '--linked', '--file', '/dev/stdin', '--output', 'json'],
    {cwd: ROOT, input: sql, encoding: 'utf8', maxBuffer: 4 * 1024 * 1024});
  if (r.error) throw r.error;
  if (r.status !== 0) throw new Error(`Database query failed: ${r.stderr.slice(0, 500)}`);
  const data = JSON.parse(r.stdout);
  if (!Array.isArray(data.rows)) throw new Error('Expected database rows');
  return data.rows;
}

export function buildNameSaveSql(selected, before) {
  const pending = selected.filter(s => s.en && before.find(p => p.id === s.id)?.name_en !== s.en);
  const payload = pending.map(s => {
    const p = before.find(p => p.id === s.id);
    if (!p || p.name_ko !== s.ko) throw new Error('Name changed since selection');
    return {id: s.id, ko: s.ko, en: s.en, previous_en: p.name_en};
  });
  // Compare both source and previous English text so concurrent edits survive.
  return `with candidate as (
    select * from jsonb_to_recordset(${literal(JSON.stringify(payload))}::jsonb)
      as v(id bigint, ko text, en text, previous_en text)
  ), updated as (
    update public.places p set name_en = v.en, updated_at = now()
    from candidate v
    where p.id = v.id and p.name_ko = v.ko and p.name_en is not distinct from v.previous_en
      and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
    returning p.id, p.name_ko, p.name_en
  ) select * from updated order by id;`;
}

async function main() {
  const args = process.argv.slice(2);
  if (args.some(a => a !== '--apply') || args.length > 1) throw new Error('Usage: node scripts/save_best_name_english.mjs [--apply]');
  const apply = args.includes('--apply');
  const linked = JSON.parse(readFileSync(path.join(ROOT, 'supabase/.temp/linked-project.json'), 'utf8'));
  if (linked.ref !== PROJECT_REF || linked.name !== 'Pind') throw new Error('Unexpected linked project');
  const fixture = JSON.parse(readFileSync(path.join(ROOT, 'supabase/functions/places/name_english.golden.json'), 'utf8'));
  const cases = fixture.cases;
  if (cases.length !== 20 || new Set(cases.map(c => c.id)).size !== 20) throw new Error('Expected exactly 20 distinct place IDs');
  const run = path.join(ROOT, 'artifacts/name-english-20261005', `best-of-three-${new Date().toISOString().replace(/[:.]/gu, '-')}`);
  mkdirSync(run, {recursive: true});
  const save = (file, data) => writeFileSync(path.join(run, file), JSON.stringify(data, null, 2) + '\n');
  const ids = cases.map(c => c.id);
  if (ids.some(id => !Number.isSafeInteger(id) || id < 1)) throw new Error('Invalid place ID');
  const readSql = `select id,name_ko,name_en,external_provider,is_published,is_demo,is_reference_only from public.places where id in (${ids.join(',')}) order by id;`;
  const before = query(readSql);
  save('before.json', before);
  for (const c of cases) {
    const p = before.find(p => p.id === c.id);
    if (!p || p.name_ko !== c.ko || !p.is_published || p.is_demo || p.is_reference_only || !['sbiz','pind'].includes(p.external_provider)) {
      throw new Error(`Place ${c.id} differs from the reviewed fixture`);
    }
  }
  // Calls are independent; wait for all three even if one fails. No extra calls.
  const attempts = await Promise.allSettled([1, 2, 3].map(i => runEnglishNameEvaluation(path.join(run, `trial-${i}.json`), fixture)));
  save('trial-status.json', attempts.map((r, i) => ({trial: i + 1, status: r.status, error: r.status === 'rejected' ? String(r.reason) : null})));
  if (attempts.some(a => a.status === 'rejected')) throw new Error(`Trial failed; no names saved. See ${run}`);
  const trials = attempts.map(a => a.value);
  const selected = selectBestEnglishNames(cases, trials);
  const report = {generated_at: new Date().toISOString(), project_ref: PROJECT_REF, applied: false,
    selection: 'pre-reviewed acceptable answers, preferred spelling then agreement; never synthesize a missing answer',
    trial_passed: trials.map(t => t.passed), total: cases.length, selected: selected.filter(s => s.en).length,
    skipped: selected.filter(s => !s.en).length, updated: 0, verified: 0, results: selected};
  save('selection.json', report);
  const sql = buildNameSaveSql(selected, before);
  writeFileSync(path.join(run, 'apply.sql'), sql + '\n');
  if (apply) {
    const updated = query(sql);
    save('updated.json', updated);
    const after = query(readSql);
    save('after.json', after);
    report.applied = true;
    report.updated = updated.length;
    report.verified = selected.filter(s => s.en && after.some(p => p.id === s.id && p.name_ko === s.ko && p.name_en === s.en)).length;
    save('selection.json', report);
    if (report.verified !== report.selected) throw new Error(`Post-write mismatch; see ${run}`);
  }
  console.log(JSON.stringify({trial_passed: report.trial_passed, selected: report.selected, skipped: report.skipped,
    updated: report.updated, verified: report.verified, applied: report.applied, directory: run}));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) await main();
