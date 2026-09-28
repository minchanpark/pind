import assert from 'node:assert/strict';
import test from 'node:test';
import { lookupWithRetry, parseArgs, sqlLiteral } from './backfill_pohang_addresses.mjs';

test('defaults to a small dry-run and requires an explicit large batch', () => {
  assert.deepEqual(parseArgs([]), { help: false, apply: false, maxAddresses: 20, after: '' });
  assert.deepEqual(parseArgs(['--max-addresses', '7141', '--apply']),
    { help: false, apply: true, maxAddresses: 7141, after: '' });
  assert.throws(() => parseArgs(['--max-addresses', '10001']));
  assert.throws(() => parseArgs(['--max-addresses', '1; drop table places']));
});

test('escapes database values without changing Korean text', () => {
  assert.equal(sqlLiteral("포항시 O'Brien길 1"), "'포항시 O''Brien길 1'");
});

test('retries transient Juso lookup failures and returns a later exact match', async () => {
  let calls = 0;
  let pauses = 0;
  const result = await lookupWithRetry('경상북도 포항시 남구 시청로 1', 'private', async () => {
    calls += 1;
    if (calls < 3) throw new Error('temporary network failure');
    return { status: 'matched', addressEn: '1 Sicheong-ro, Nam-gu, Pohang-si, Gyeongsangbuk-do' };
  }, async () => { pauses += 1; });
  assert.equal(result.status, 'matched');
  assert.equal(calls, 3);
  assert.equal(pauses, 2);
});
