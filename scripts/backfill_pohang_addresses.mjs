#!/usr/bin/env node

import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { setTimeout as sleep } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import {
  isFullKoreanRoadAddress,
  loadJusoApiKey,
  lookupEnglishAddress,
} from './backfill_sbiz_address_en.mjs';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const PROJECT_REF = 'mkfgqobwededpzdekvxg';
const PAGE_SIZE = 100;
const REQUEST_GAP_MS = 500;
const POHANG_PREFIX = '경상북도 포항시%';
const MAX_LOOKUP_ATTEMPTS = 3;

export function parseArgs(argv) {
  let apply = false;
  let maxAddresses = 20;
  let after = '';
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--apply') apply = true;
    else if (arg === '--max-addresses') {
      const value = argv[++index];
      if (!/^\d+$/u.test(value ?? '')) throw new Error('--max-addresses must be an integer');
      maxAddresses = Number(value);
    } else if (arg === '--after') {
      after = argv[++index];
      if (!after) throw new Error('--after requires a Korean address');
    } else if (arg === '--help' || arg === '-h') {
      return { help: true, apply: false, maxAddresses, after };
    } else throw new Error(`Unknown argument: ${arg}`);
  }
  if (!Number.isSafeInteger(maxAddresses) || maxAddresses < 1 || maxAddresses > 10_000) {
    throw new Error('--max-addresses must be between 1 and 10000');
  }
  return { help: false, apply, maxAddresses, after };
}

export function sqlLiteral(value) {
  return `'${String(value).replaceAll("'", "''")}'`;
}

export async function lookupWithRetry(address, key, lookup = lookupEnglishAddress, pause = sleep) {
  for (let attempt = 1; attempt <= MAX_LOOKUP_ATTEMPTS; attempt += 1) {
    try {
      return await lookup(address, key);
    } catch (error) {
      if (attempt === MAX_LOOKUP_ATTEMPTS) throw error;
      await pause(attempt * 2_000);
    }
  }
}

function query(sql) {
  const result = spawnSync('npx', [
    '-y', 'supabase@2.118.0', 'db', 'query', '--linked', '--file', '/dev/stdin', '--output', 'json',
  ], { cwd: ROOT, input: sql, encoding: 'utf8', maxBuffer: 4 * 1024 * 1024 });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`Supabase query failed (exit ${result.status}): ${result.stderr.trim()}`);
  }
  const payload = JSON.parse(result.stdout);
  if (!Array.isArray(payload.rows)) throw new Error('Supabase query did not return a row array');
  return payload.rows;
}

function assertProject() {
  const linked = JSON.parse(readFileSync(path.join(ROOT, 'supabase/.temp/linked-project.json'), 'utf8'));
  if (linked.ref !== PROJECT_REF || linked.name !== 'Pind') {
    throw new Error('Linked Supabase project is not the expected Pind project');
  }
}

function fetchPage(after, limit) {
  return query(`select address_ko, count(*)::int as place_count
from public.places
where external_provider = 'sbiz'
  and address_ko like ${sqlLiteral(POHANG_PREFIX)}
  and address_en = address_ko
  and address_ko > ${sqlLiteral(after)}
group by address_ko
order by address_ko
limit ${limit};`);
}

function applyMatches(matches) {
  if (!matches.length) return 0;
  const payload = sqlLiteral(JSON.stringify(matches));
  const rows = query(`with candidate as (
  select * from jsonb_to_recordset(${payload}::jsonb)
    as v(address_ko text, address_en text)
), updated as (
  update public.places as p
  set address_en = v.address_en
  from candidate as v
  where p.external_provider = 'sbiz'
    and p.address_ko like ${sqlLiteral(POHANG_PREFIX)}
    and p.address_ko = v.address_ko
    and p.address_en = p.address_ko
  returning p.id
)
select count(*)::int as updated_count from updated;`);
  return Number(rows[0]?.updated_count ?? -1);
}

function verifyMatches(matches) {
  if (!matches.length) return;
  const payload = sqlLiteral(JSON.stringify(matches));
  const rows = query(`select count(*)::int as pending_count
from public.places as p
join jsonb_to_recordset(${payload}::jsonb) as v(address_ko text, address_en text)
  on p.address_ko = v.address_ko
where p.external_provider = 'sbiz'
  and p.address_en = p.address_ko;`);
  if (Number(rows[0]?.pending_count) !== 0) {
    throw new Error('Post-update verification found unmatched English addresses');
  }
}

export async function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);
  if (options.help) {
    console.log('Usage: node scripts/backfill_pohang_addresses.mjs --max-addresses 20 [--apply] [--after "last Korean address"]');
    console.log('Dry-run by default. Use --apply after reviewing a small sample. Up to 10000 distinct addresses per run.');
    return;
  }
  assertProject();
  const key = loadJusoApiKey();
  let cursor = options.after;
  let checked = 0;
  let matched = 0;
  let updated = 0;
  let lookupErrors = 0;
  let previousRequestAt = 0;
  while (checked < options.maxAddresses) {
    const page = fetchPage(cursor, Math.min(PAGE_SIZE, options.maxAddresses - checked));
    if (!page.length) break;
    const matches = [];
    for (const row of page) {
      cursor = row.address_ko;
      checked += 1;
      if (!isFullKoreanRoadAddress(row.address_ko)) {
        console.log(JSON.stringify({ status: 'invalid_korean_road_address', address_ko: row.address_ko }));
        continue;
      }
      const waitMs = REQUEST_GAP_MS - (Date.now() - previousRequestAt);
      if (waitMs > 0) await sleep(waitMs);
      previousRequestAt = Date.now();
      let result;
      try {
        result = await lookupWithRetry(row.address_ko, key);
      } catch (error) {
        lookupErrors += 1;
        console.log(JSON.stringify({ status: 'request_error', address_ko: row.address_ko,
          reason: error.message }));
        continue;
      }
      if (result.status === 'matched') {
        matched += 1;
        matches.push({ address_ko: row.address_ko, address_en: result.addressEn, place_count: Number(row.place_count) });
      } else {
        console.log(JSON.stringify({ status: result.status, address_ko: row.address_ko }));
      }
    }
    if (options.apply) {
      const changed = applyMatches(matches);
      const expected = matches.reduce((sum, row) => sum + row.place_count, 0);
      if (changed !== expected) {
        throw new Error(`Guarded update mismatch: expected ${expected} rows, updated ${changed}. Last address: ${cursor}`);
      }
      verifyMatches(matches);
      updated += changed;
    }
    console.log(JSON.stringify({ mode: options.apply ? 'apply' : 'dry-run', checked, matched, updated,
      lookup_errors: lookupErrors,
      last_address: cursor }));
  }
  console.log(JSON.stringify({ done: true, mode: options.apply ? 'apply' : 'dry-run', checked, matched,
    updated, lookup_errors: lookupErrors, last_address: cursor }));
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
