#!/usr/bin/env node
// Scores the place-name prompt against the golden set.
// Usage: node scripts/eval_name_translation.mjs [--model gemini-3.8-flash] [--out results.json]
// GEMINI_API_KEY comes from the environment or the repo's .env.
// A miss is an answer outside the accepted list, not necessarily wrong;
// read them (or hand them to a judge) before changing the prompt.

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { NAME_LANGS, NAME_MODELS, NAME_SCHEMA, NAME_SYSTEM, namePrompt, parseNames } from '../supabase/functions/places/names.ts';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const GOLDEN = path.join(ROOT, 'supabase/functions/places/name_translation.golden.json');
const BATCH = 25;

/// Spacing, case, Latin accents (not kana dakuten) and punctuation don't count: "Cafe" = "Café", "McDonalds" = "McDonald's".
export const loose = (s) => String(s).normalize('NFD').replace(/[\u0300-\u036f]/gu, '').normalize('NFC')
  .toLowerCase().replace(/[\s・·\-'’.]/gu, '');

/// Per-case result: kinds match and, per language, whether the answer was accepted.
export function score(golden, got) {
  const kinds = got ? got.segments.map(([, kind]) => kind).join(' ') : '';
  const want = golden.segments.map(([, kind]) => kind).join(' ');
  const langs = Object.fromEntries(NAME_LANGS.map(lang => {
    const answer = got?.names[lang] ?? null;
    return [lang, {answer, ok: answer != null && golden[lang].some(a => loose(a) === loose(answer))}];
  }));
  return {ko: golden.ko, review: golden.review === true, kinds: {got: kinds, want, ok: kinds === want}, langs};
}

/// GEMINI_API_KEY from the environment, else the `KEY = value` line in .env.
function geminiKey() {
  if (process.env.GEMINI_API_KEY) return process.env.GEMINI_API_KEY;
  const env = existsSync(path.join(ROOT, '.env')) ? readFileSync(path.join(ROOT, '.env'), 'utf8') : '';
  return env.match(/^GEMINI_API_KEY\s*=\s*["']?([^"'\s]+)/mu)?.[1];
}

/// One model, retried while Google says it's busy: the score is for that model.
async function gemini(key, model, user, tries = 4) {
  for (let i = 1; ; i++) {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
      method: 'POST',
      headers: {'x-goog-api-key': key, 'Content-Type': 'application/json'},
      body: JSON.stringify({
        systemInstruction: {parts: [{text: NAME_SYSTEM}]},
        contents: [{role: 'user', parts: [{text: user}]}],
        generationConfig: {responseMimeType: 'application/json', responseJsonSchema: NAME_SCHEMA},
      }),
    });
    const data = await response.json().catch(() => null);
    if ((response.status === 429 || response.status === 503) && i < tries) {
      await new Promise(resolve => setTimeout(resolve, 15_000 * i));
      continue;
    }
    if (!response.ok) throw new Error(`Gemini ${response.status}: ${data?.error?.message ?? ''}`.slice(0, 300));
    const candidate = data?.candidates?.[0];
    if (candidate?.finishReason !== 'STOP') throw new Error(`Gemini stopped: ${candidate?.finishReason}`);
    return candidate.content.parts.map(p => p.text ?? '').join('');
  }
}

async function main() {
  const args = process.argv.slice(2);
  const flag = (name, fallback) => (args.includes(name) ? args[args.indexOf(name) + 1] : fallback);
  const key = geminiKey();
  if (!key) throw new Error('Set GEMINI_API_KEY.');
  const model = flag('--model', NAME_MODELS[0]);
  const cases = JSON.parse(readFileSync(GOLDEN, 'utf8')).cases;

  const results = [];
  for (let i = 0; i < cases.length; i += BATCH) {
    const batch = cases.slice(i, i + BATCH);
    const names = batch.map(c => c.ko);
    const text = await gemini(key, model, namePrompt(names));
    parseNames(text, names).forEach((got, j) => results.push(score(batch[j], got)));
  }

  const pct = (n) => `${Math.round((100 * n) / results.length)}%`;
  console.log(`model ${model}, ${results.length} cases`);
  console.log(`kinds   ${pct(results.filter(r => r.kinds.ok).length)}`);
  for (const lang of NAME_LANGS) console.log(`${lang.padEnd(8)}${pct(results.filter(r => r.langs[lang].ok).length)}`);
  console.log('\nmisses (★ = golden answer still needs native review):');
  for (const r of results) {
    const misses = NAME_LANGS.filter(lang => !r.langs[lang].ok).map(lang => `${lang}=${r.langs[lang].answer ?? '∅'}`);
    if (!r.kinds.ok) misses.unshift(`kinds=${r.kinds.got || '∅'} (want ${r.kinds.want})`);
    if (misses.length) console.log(`${r.review ? '★' : ' '} ${r.ko}: ${misses.join(' | ')}`);
  }
  const out = flag('--out');
  if (out) writeFileSync(out, JSON.stringify({model, results}, null, 2));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch(error => { console.error(error.message); process.exit(1); });
}
