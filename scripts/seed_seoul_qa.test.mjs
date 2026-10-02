import test from 'node:test';
import assert from 'node:assert/strict';

process.env.SUPABASE_URL ??= 'https://example.supabase.co';
process.env.SUPABASE_ANON_KEY ??= 'anon';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'service';
const { AUTHORS, BODIES, rating, requestId } = await import('./seed_seoul_qa.mjs');

test('request ids are stable UUIDs, distinct per author and place', () => {
  const id = requestId('qa_haram', 1);
  assert.match(id, /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-8[0-9a-f]{3}-[0-9a-f]{12}$/);
  assert.equal(requestId('qa_haram', 1), id);
  assert.notEqual(requestId('qa_jiwoo', 1), id);
  assert.notEqual(requestId('qa_haram', 2), id);
});

test('authors fit publish_post_v3 and taste_profiles', () => {
  const allowed = ['taste', 'ambience', 'value', 'portion', 'service', 'photogenic', 'quiet', 'parking'];
  for (const a of AUTHORS) {
    assert.equal(new Set(a.priorities).size, 3);
    assert.ok(a.priorities.every(c => allowed.includes(c)));
    assert.match(a.handle, /^[a-z0-9_]{3,20}$/);
  }
  // Any three priorities a viewer picks have ratings from someone.
  assert.deepEqual(new Set(AUTHORS.flatMap(a => a.priorities)), new Set(allowed));
  for (const lines of Object.values(BODIES)) {
    assert.ok(lines.length >= AUTHORS.length);
    assert.ok(lines.every(l => l.length <= 200));
  }
  for (let p = 0; p < 8; p++) for (let a = 0; a < 5; a++) for (let k = 0; k < 3; k++) {
    assert.ok([3, 4, 5].includes(rating(p, a, k)));
  }
});
