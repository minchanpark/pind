#!/usr/bin/env node
// Read-only live model evaluation; never writes to the catalog.
import {existsSync, readFileSync, mkdirSync, writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {ENGLISH_NAME_MODEL, ENGLISH_NAME_POLICY, englishNameRequest, parseEnglishNameResponse} from '../supabase/functions/places/names-en.ts';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const looseEnglishName = s => s.normalize('NFD').replace(/[\u0300-\u036f]/gu, '').toLowerCase().replace(/[\s\-'’.]/gu, '');

export async function runEnglishNameEvaluation(out, fixture) {
  out = path.resolve(ROOT, out);
  if (!process.env.NVDIA_API_KEY && !process.env.NVIDIA_API_KEY && existsSync(path.join(ROOT, '.env'))) {
    process.loadEnvFile(path.join(ROOT, '.env'));
  }
  const key = process.env.NVDIA_API_KEY ?? process.env.NVIDIA_API_KEY;
  if (!key) throw new Error('Set NVDIA_API_KEY in .env');
  fixture ??= JSON.parse(readFileSync(path.join(ROOT, 'supabase/functions/places/name_english.golden.json'), 'utf8'));
  const names = fixture.cases.map(c => c.ko);
  const request = englishNameRequest(names);
  mkdirSync(path.dirname(out), {recursive: true});
  writeFileSync(out.replace(/\.json$/u, '') + '.request.json', JSON.stringify(request, null, 2) + '\n');
  const started = Date.now();
  const response = await fetch('https://integrate.api.nvidia.com/v1/chat/completions', {
    method: 'POST',
    headers: {Authorization: `Bearer ${key}`, 'Content-Type': 'application/json'},
    body: JSON.stringify(request),
    signal: AbortSignal.timeout(120_000),
  });
  const data = await response.json();
  if (!response.ok) throw new Error(`NVIDIA HTTP ${response.status}: ${data?.error?.message ?? data?.detail ?? 'request failed'}`);
  // Save provider evidence before validation so a failed evaluation is reviewable.
  writeFileSync(out.replace(/\.json$/u, '') + '.response.json', JSON.stringify(data, null, 2) + '\n');
  const answers = parseEnglishNameResponse(data, names);
  const results = answers.map((answer, i) => ({
    id: fixture.cases[i].id,
    ...answer,
    group: fixture.cases[i].group,
    accepted: fixture.cases[i].en,
    ok: fixture.cases[i].en.some(en => looseEnglishName(en) === looseEnglishName(answer.en)),
  }));
  const report = {
    generated_at: new Date().toISOString(),
    model: ENGLISH_NAME_MODEL,
    response_model: data.model,
    policy: ENGLISH_NAME_POLICY,
    request_sha256: createHash('sha256').update(JSON.stringify(request)).digest('hex'),
    thinking: request.thinking,
    chat_template_kwargs: request.chat_template_kwargs,
    reasoning_content_present: Boolean(data.choices?.[0]?.message?.reasoning_content || data.choices?.[0]?.message?.reasoning),
    reasoning_tokens: data.usage?.completion_tokens_details?.reasoning_tokens ?? null,
    duration_ms: Date.now() - started,
    usage: data.usage,
    total: results.length,
    passed: results.filter(r => r.ok).length,
    results,
  };
  writeFileSync(out, JSON.stringify(report, null, 2) + '\n');
  console.log(`${report.passed}/${report.total} accepted; ${report.duration_ms}ms; reasoning content: ${report.reasoning_content_present}`);
  for (const r of results) console.log(`${r.ok ? 'PASS' : 'REVIEW'} ${r.id} ${r.ko} -> ${r.en}`);
  console.log(`Saved ${path.relative(ROOT, out)}`);
  return report;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const args = process.argv.slice(2);
  if (args.length > 2 || (args.length && (args[0] !== '--out' || !args[1]))) {
    throw new Error('Usage: node scripts/eval_name_english.mjs [--out results.json]');
  }
  const report = await runEnglishNameEvaluation(args[1] ?? 'artifacts/name-english-20261005/results.json');
  if (report.passed !== report.total) process.exitCode = 2;
}
