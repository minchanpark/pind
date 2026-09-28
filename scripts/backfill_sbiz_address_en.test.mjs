import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {
  loadJusoApiKey,
  isFullKoreanRoadAddress,
  lookupEnglishAddress,
  normalizeAddress,
  parseArgs,
  resolveJusoMatch,
} from './backfill_sbiz_address_en.mjs';

test('normalizes Unicode and whitespace without translating address content', () => {
  assert.equal(normalizeAddress('  경상북도  포항시 남구  '), '경상북도 포항시 남구');
});

test('accepts complete PoHang road addresses and rejects incomplete imported addresses', () => {
  for (const address of [
    '경상북도 포항시 북구 양학로9번길 26',
    '경상북도 포항시 북구 새천년대로 526',
    '경상북도 포항시 북구 상대로 10-1',
    '경상북도 포항시 북구 상대로 31',
    '경상북도 포항시 북구 새천년대로 486',
    '경상북도 포항시 북구 중흥로113번길 12',
  ]) assert.equal(isFullKoreanRoadAddress(address), true, address);
  assert.equal(isFullKoreanRoadAddress('경상북도 32-1'), false);
  assert.equal(isFullKoreanRoadAddress('경상북도 25'), false);
});

test('accepts one exact Korean-address result and returns the official English road address', () => {
  const match = resolveJusoMatch('경상북도 포항시 남구 시청로 1', [{
    korAddr: '경상북도 포항시 남구 시청로 1',
    roadAddr: '1 Sicheong-ro, Nam-gu, Pohang-si, Gyeongsangbuk-do',
    admCd: '47111', rnMgtSn: '471114000000', udrtYn: '0', buldMnnm: '1', buldSlno: '0',
  }]);
  assert.deepEqual(match, {
    status: 'matched',
    addressEn: '1 Sicheong-ro, Nam-gu, Pohang-si, Gyeongsangbuk-do',
  });
});

test('skips missing, inexact, ambiguous and Korean-only results', () => {
  assert.equal(resolveJusoMatch('서울 종로구', []).status, 'no_exact_match');
  assert.equal(resolveJusoMatch('서울 종로구', [{ korAddr: '서울특별시 종로구', roadAddr: 'Jongno-gu, Seoul' }]).status, 'no_exact_match');
  const address = '경상북도 포항시 남구 시청로 1';
  const base = { korAddr: address, roadAddr: '1 Sicheong-ro', admCd: '47111', rnMgtSn: '471114000000', udrtYn: '0', buldMnnm: '1' };
  assert.equal(resolveJusoMatch(address, [base, { ...base, buldSlno: '2' }]).status, 'ambiguous');
  assert.equal(resolveJusoMatch(address, [{ ...base, buldSlno: '0', roadAddr: address }]).status, 'no_english_address');
});

test('parses the complete API key after the first equals sign without printing it', () => {
  const dir = mkdtempSync(path.join(os.tmpdir(), 'pind-juso-test-'));
  const file = path.join(dir, 'juso.local.env');
  writeFileSync(file, 'JUSO_API_KEY=examplekey==\n');
  try {
    assert.equal(loadJusoApiKey(file), 'examplekey==');
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test('limits each run to explicit place IDs and defaults to dry-run', () => {
  assert.deepEqual(parseArgs(['--ids', '145731,148127']), { help: false, ids: [145731, 148127], apply: false });
  assert.equal(parseArgs(['--ids', '145731', '--apply']).apply, true);
  assert.throws(() => parseArgs([]), /--ids is required/u);
  assert.throws(() => parseArgs(['--ids', Array.from({ length: 21 }, (_, i) => i + 1).join(',')]), /At most 20/u);
});

test('calls the Juso English endpoint with encoded parameters and exact-matches Korean response', async () => {
  let requested;
  const result = await lookupEnglishAddress('경상북도 포항시 남구 시청로 1', 'unit=test==', async (url) => {
    requested = new URL(url);
    return {
      ok: true,
      json: async () => ({
        results: {
          common: { errorCode: '0' },
          juso: [{ korAddr: '경상북도 포항시 남구 시청로 1', roadAddr: '1 Sicheong-ro', admCd: '47111', rnMgtSn: '471114000000', udrtYn: '0', buldMnnm: '1', buldSlno: '0' }],
        },
      }),
    };
  });
  assert.equal(requested.origin + requested.pathname, 'https://business.juso.go.kr/addrlink/addrEngApi.do');
  assert.equal(requested.searchParams.get('confmKey'), 'unit=test==');
  assert.equal(requested.searchParams.get('keyword'), '경상북도 포항시 남구 시청로 1');
  assert.equal(result.addressEn, '1 Sicheong-ro');
});

test('reports only the Juso error code when a key is rejected', async () => {
  await assert.rejects(
    lookupEnglishAddress('경상북도 포항시 남구 시청로 1', 'never-print-this', async () => ({
      ok: true,
      json: async () => ({ results: { common: { errorCode: 'E0001' }, juso: null } }),
    })),
    (error) => {
      assert.match(error.message, /E0001/u);
      assert.doesNotMatch(error.message, /never-print-this/u);
      return true;
    },
  );
});
