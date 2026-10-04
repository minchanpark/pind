#!/usr/bin/env node

import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { setTimeout as sleep } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const KEY_FILE = path.join(ROOT, 'config/juso.local.env');
const EXPECTED_PROJECT_REF = 'mkfgqobwededpzdekvxg';
const JUSO_ENDPOINT = 'https://business.juso.go.kr/addrlink/addrEngApi.do';
const JUSO_DOC = 'https://www.data.go.kr/data/15057017/openapi.do';
const MAX_IDS_PER_RUN = 20;
const MAX_BATCH = 500;
const BATCH_PARALLEL = 4;
const BATCH_GAP_MS = 400;
// Batch mode walks distinct Korean addresses in order and resumes from here.
const CURSOR_FILE = path.join(ROOT, 'build/address_en_cursor.txt');
const REQUEST_GAP_MS = 1_000;

export function normalizeAddress(value) {
  return String(value ?? '').normalize('NFC').trim().replace(/\s+/gu, ' ');
}

export function isFullKoreanRoadAddress(value) {
  const parts = normalizeAddress(value).split(' ');
  if (parts.length < 3) return false;
  const [sido, ...rest] = parts;
  if (!/(?:특별시|광역시|특별자치시|특별자치도|도)$/u.test(sido)) return false;
  const isSejong = sido.endsWith('특별자치시');
  const hasSigungu = /(?:시|군|구)$/u.test(rest[0] ?? '');
  const streetStart = isSejong && !hasSigungu ? 0 : hasSigungu ? 1 : -1;
  if (streetStart < 0) return false;
  const streetParts = rest.slice(streetStart);
  const roadIndex = streetParts.findIndex((part) => /(?:대로|로|길)$/u.test(part));
  return roadIndex >= 0 && /^\d+(?:-\d+)?(?:$|\D)/u.test(streetParts[roadIndex + 1] ?? '');
}

export function resolveJusoMatch(koreanAddress, results) {
  const input = normalizeAddress(koreanAddress);
  const candidates = (Array.isArray(results) ? results : results ? [results] : [])
    .filter((result) => normalizeAddress(result?.korAddr) === input);
  const unique = new Map();
  for (const result of candidates) {
    const identityParts = [result.admCd, result.rnMgtSn, result.udrtYn, result.buldMnnm, result.buldSlno]
      .map((part) => normalizeAddress(part));
    const identity = identityParts.every(Boolean) ? identityParts.join(':') : JSON.stringify(result);
    unique.set(identity, result);
  }
  if (unique.size !== 1) return { status: unique.size === 0 ? 'no_exact_match' : 'ambiguous', addressEn: null };
  const addressEn = normalizeAddress([...unique.values()][0]?.roadAddr);
  if (!addressEn || /[\uac00-\ud7a3]/u.test(addressEn)) return { status: 'no_english_address', addressEn: null };
  return { status: 'matched', addressEn };
}

export function loadJusoApiKey(filePath = KEY_FILE) {
  const content = readFileSync(filePath, 'utf8');
  const line = content.split(/\r?\n/u).find((entry) => /^\s*JUSO_API_KEY\s*=/u.test(entry));
  if (!line) throw new Error('JUSO_API_KEY is missing from config/juso.local.env');
  const key = line.slice(line.indexOf('=') + 1).trim().replace(/^(['"])(.*)\1$/u, '$2');
  if (key.length < 10 || /[\s\r\n]/u.test(key)) throw new Error('JUSO_API_KEY has an invalid format');
  return key;
}

export function parseArgs(argv) {
  const ids = [];
  let apply = false;
  let batch = 0;
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === '--apply') apply = true;
    else if (argv[i] === '--batch') {
      batch = Number(argv[++i]);
      if (!Number.isSafeInteger(batch) || batch < 1 || batch > MAX_BATCH) {
        throw new Error(`--batch must be 1 to ${MAX_BATCH} addresses`);
      }
    }
    else if (argv[i] === '--ids') {
      const list = argv[++i];
      if (!list) throw new Error('--ids requires comma-separated place IDs');
      for (const value of list.split(',')) {
        if (!/^\d+$/u.test(value)) throw new Error('--ids must contain positive integer IDs only');
        ids.push(Number(value));
      }
    } else if (argv[i] === '--help' || argv[i] === '-h') {
      return { help: true, ids: [], apply: false, batch: 0 };
    } else {
      throw new Error(`Unknown argument: ${argv[i]}`);
    }
  }
  if (batch) {
    if (ids.length) throw new Error('Use either --ids or --batch');
    return { help: false, ids, apply, batch };
  }
  if (!ids.length) throw new Error('--ids or --batch is required');
  if (ids.some((id) => !Number.isSafeInteger(id) || id < 1)) throw new Error('Place IDs must be positive safe integers');
  if (new Set(ids).size !== ids.length) throw new Error('--ids contains duplicates');
  if (ids.length > MAX_IDS_PER_RUN) throw new Error(`At most ${MAX_IDS_PER_RUN} IDs are allowed per run`);
  return { help: false, ids, apply, batch: 0 };
}

function runSupabaseSql(sql) {
  const result = spawnSync('npx', [
    '-y', 'supabase@2.118.0', 'db', 'query', '--linked', '--file', '/dev/stdin', '--output', 'json',
  ], { cwd: ROOT, input: sql, encoding: 'utf8', maxBuffer: 1024 * 1024 });
  if (result.status !== 0) {
    // Supabase CLI errors can contain query details. Do not echo them.
    throw new Error('Supabase query failed; no address values or credentials were logged');
  }
  try {
    return JSON.parse(result.stdout).rows ?? [];
  } catch {
    throw new Error('Supabase CLI returned an unexpected response');
  }
}

function assertPindProject() {
  const linked = JSON.parse(readFileSync(path.join(ROOT, 'supabase/.temp/linked-project.json'), 'utf8'));
  if (linked.ref !== EXPECTED_PROJECT_REF || linked.name !== 'Pind') {
    throw new Error('Linked Supabase project is not the expected Pind project');
  }
}

function fetchPlaceRows(ids) {
  return runSupabaseSql(`select id, external_place_id, external_provider, address_ko, address_en
from public.places where id in (${ids.join(',')}) order by id;`);
}

async function lookupEnglishAddress(koreanAddress, apiKey, fetchImpl = fetch) {
  const url = new URL(JUSO_ENDPOINT);
  url.search = new URLSearchParams({
    confmKey: apiKey,
    currentPage: '1',
    countPerPage: '100',
    keyword: koreanAddress,
    resultType: 'json',
  }).toString();
  let response;
  try {
    response = await fetchImpl(url, { signal: AbortSignal.timeout(15_000) });
  } catch {
    throw new Error('Juso English address API request failed');
  }
  if (!response.ok) throw new Error(`Juso English address API returned HTTP ${response.status}`);
  let payload;
  try {
    payload = await response.json();
  } catch {
    throw new Error('Juso English address API returned invalid JSON');
  }
  const results = payload?.results;
  const common = results?.common;
  if (common?.errorCode !== '0') {
    if (common?.errorCode === 'E0001') {
      throw new Error('Juso rejected the key for this API (E0001). Use an English address search API key, not a popup API key.');
    }
    throw new Error(`Juso English address API returned error code ${String(common?.errorCode ?? 'unknown')}`);
  }
  return resolveJusoMatch(koreanAddress, results?.juso);
}

function updatePlaces(rows) {
  const json = JSON.stringify(rows).replaceAll("'", "''");
  return runSupabaseSql(`update public.places as p
set address_en = v.address_en
from jsonb_to_recordset('${json}'::jsonb) as v(id bigint, external_place_id text, address_ko text, address_en text)
where p.id = v.id
  and p.external_provider = 'sbiz'
  and p.external_place_id = v.external_place_id
  and p.address_ko = v.address_ko
  and p.address_en = p.address_ko
returning p.id, p.address_ko, p.address_en;`);
}

const sqlText = (value) => `'${String(value).replaceAll("'", "''")}'`;

/// The next distinct Korean addresses still lacking English, after [cursor].
function fetchPendingAddresses(cursor, limit) {
  return runSupabaseSql(`select address_ko from public.places
where external_provider = 'sbiz' and address_en = address_ko
  and address_ko > ${sqlText(cursor)}
group by address_ko order by address_ko limit ${limit};`).map((row) => row.address_ko);
}

/// Every SBIZ place at each address, still on its Korean fallback.
function updateAddresses(rows) {
  const json = JSON.stringify(rows).replaceAll("'", "''");
  return runSupabaseSql(`update public.places as p set address_en = v.address_en
from jsonb_to_recordset('${json}'::jsonb) as v(address_ko text, address_en text)
where p.external_provider = 'sbiz' and p.address_ko = v.address_ko and p.address_en = p.address_ko
returning p.id;`);
}

async function mainBatch({ batch, apply }, lookup = lookupEnglishAddress) {
  assertPindProject();
  const apiKey = loadJusoApiKey();
  const cursor = existsSync(CURSOR_FILE) ? readFileSync(CURSOR_FILE, 'utf8') : '';
  const addresses = fetchPendingAddresses(cursor, batch);
  const matched = [];
  const counts = {};
  // A few lookups at a time with a pause between rounds (~10/s), so a full
  // pass over ~80k addresses takes hours, not days.
  for (let i = 0; i < addresses.length; i += BATCH_PARALLEL) {
    if (i > 0) await sleep(BATCH_GAP_MS);
    await Promise.all(addresses.slice(i, i + BATCH_PARALLEL).map(async (address) => {
      let status = 'invalid_korean_road_address';
      if (isFullKoreanRoadAddress(address)) {
        let match;
        for (let attempt = 1; ; attempt += 1) {
          try {
            match = await lookup(address, apiKey);
            break;
          } catch (error) {
            // Transient network errors; the cursor only moves after a full batch.
            if (attempt === 3) throw error;
            await sleep(attempt * 2_000);
          }
        }
        status = match.status;
        if (match.status === 'matched') matched.push({ address_ko: address, address_en: match.addressEn });
      }
      counts[status] = (counts[status] ?? 0) + 1;
    }));
  }
  const updated = apply && matched.length ? updateAddresses(matched).length : 0;
  // Unmatched addresses stay Korean; the cursor moves past them either way.
  if (apply && addresses.length) {
    mkdirSync(path.dirname(CURSOR_FILE), { recursive: true });
    writeFileSync(CURSOR_FILE, addresses.at(-1));
  }
  console.log(JSON.stringify({
    mode: apply ? 'apply' : 'dry-run', addresses: addresses.length, counts,
    places_updated: updated, done: addresses.length < batch,
    sample: matched.slice(0, 3),
  }));
}

const usage = `Usage: node scripts/backfill_sbiz_address_en.mjs --ids 123,456 [--apply]
       node scripts/backfill_sbiz_address_en.mjs --batch 200 [--apply]
--batch looks up the next distinct addresses still in Korean and resumes from
build/address_en_cursor.txt; run it repeatedly until "done": true.
Default mode is dry-run. --ids is mandatory and limited to ${MAX_IDS_PER_RUN} rows.
Only exact, unique Juso Korean-address matches with an English address are eligible.
config/juso.local.env must contain a Juso English address search API key (not a popup API key).`;

async function main(argv = process.argv.slice(2)) {
  let options;
  try {
    options = parseArgs(argv);
  } catch (error) {
    console.error(error.message);
    console.error(usage);
    process.exitCode = 2;
    return;
  }
  if (options.help) {
    console.log(usage);
    return;
  }

  if (options.batch) return mainBatch(options);

  assertPindProject();
  const apiKey = loadJusoApiKey();
  const rows = fetchPlaceRows(options.ids);
  const chosen = rows.filter((row) => row.external_provider === 'sbiz' && row.address_ko);
  const eligible = [];
  const outcomes = [];

  const addressMatches = new Map();
  for (const row of chosen) {
    if (!isFullKoreanRoadAddress(row.address_ko)) {
      outcomes.push({ id: row.id, status: 'invalid_korean_road_address', address_ko: row.address_ko });
      continue;
    }
    const key = normalizeAddress(row.address_ko);
    let match = addressMatches.get(key);
    if (!match) {
      if (addressMatches.size > 0) await sleep(REQUEST_GAP_MS);
      match = await lookupEnglishAddress(row.address_ko, apiKey);
      addressMatches.set(key, match);
    }
    const alreadyEnglish = row.address_en && !/[\uac00-\ud7a3]/u.test(row.address_en);
    const agreesWithExisting = alreadyEnglish && normalizeAddress(row.address_en) === match.addressEn;
    const candidate = match.status === 'matched' && !alreadyEnglish;
    outcomes.push({
      id: row.id,
      status: alreadyEnglish
        ? (agreesWithExisting ? 'already_correct' : 'existing_english_preserved')
        : match.status,
      address_ko: row.address_ko,
      address_en: match.addressEn,
    });
    if (candidate && row.address_en === row.address_ko) {
      eligible.push({
        id: row.id,
        external_place_id: row.external_place_id,
        address_ko: row.address_ko,
        address_en: match.addressEn,
      });
    }
  }

  for (const id of options.ids) {
    if (!rows.some((row) => row.id === id)) outcomes.push({ id, status: 'not_found' });
  }

  if (options.apply && eligible.length) {
    const updated = updatePlaces(eligible);
    if (updated.length !== eligible.length) {
      throw new Error(`Expected ${eligible.length} guarded row updates but received ${updated.length}; inspect the database before retrying`);
    }
    const verified = fetchPlaceRows(eligible.map((row) => row.id));
    for (const row of eligible) {
      const actual = verified.find((entry) => entry.id === row.id);
      if (!actual || actual.address_en !== row.address_en || actual.address_ko !== row.address_ko) {
        throw new Error(`Post-update verification failed for place id ${row.id}`);
      }
    }
    console.log(JSON.stringify({ mode: 'apply', updated: updated.length, verified: eligible.length, outcomes }));
  } else {
    console.log(JSON.stringify({ mode: options.apply ? 'apply' : 'dry-run', updated: 0, would_update: eligible.length, outcomes, source: JUSO_DOC }));
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

export { lookupEnglishAddress, main };
