import test from 'node:test';
import assert from 'node:assert/strict';
import { GROQ_MODELS, groqJson } from './llm.ts';
import { AGENT_SCHEMA } from './agent.ts';

const ok = (content: string, finish = 'stop') =>
  new Response(JSON.stringify({choices: [{finish_reason: finish, message: {content}}]}));

test('asks Groq for strict JSON with our schema and returns the text', async () => {
  let sent: Record<string, unknown> = {}, headers: Record<string, string> = {}, url = '';
  const text = await groqJson('k', 'sys', '<query>q</query>', AGENT_SCHEMA, async (u, init) => {
    url = String(u);
    headers = init!.headers as Record<string, string>;
    sent = JSON.parse(String(init!.body));
    return ok('{"kinds":[],"terms":["혼술"],"area":"","label":"혼술"}');
  }, 0);
  assert.equal(text, '{"kinds":[],"terms":["혼술"],"area":"","label":"혼술"}');
  assert.equal(url, 'https://api.groq.com/openai/v1/chat/completions');
  assert.equal(headers.Authorization, 'Bearer k');
  assert.equal(sent.model, GROQ_MODELS[0]);
  assert.deepEqual(sent.messages, [{role: 'system', content: 'sys'}, {role: 'user', content: '<query>q</query>'}]);
  assert.deepEqual(sent.response_format, {type: 'json_schema', json_schema: {name: 'answer', strict: true, schema: AGENT_SCHEMA}});
});

test('a rate-limited model falls to the next; other errors stop', async () => {
  const models: string[] = [];
  const text = await groqJson('k', 's', 'u', {}, async (_u, init) => {
    const model = JSON.parse(String(init!.body)).model;
    models.push(model);
    return model === GROQ_MODELS[0]
      ? new Response('{"error":{"message":"rate limit"}}', {status: 429})
      : ok('{}');
  }, 0);
  assert.equal(text, '{}');
  assert.deepEqual(models, GROQ_MODELS);

  let calls = 0;
  await assert.rejects(groqJson('k', 's', 'u', {}, async () => {
    calls++;
    return new Response('{"error":{"message":"bad schema"}}', {status: 400});
  }, 0), (e: {status?: number}) => e.status === 400);
  assert.equal(calls, 1);
  // A cut-off answer is not JSON we can trust.
  await assert.rejects(groqJson('k', 's', 'u', {}, async () => ok('{"kin', 'length'), 0), /stopped: length/);
});

test('strict mode: every object lists all its properties as required', async () => {
  const {INSIGHT_SCHEMA} = await import('./insights.ts');
  const check = (s: Record<string, unknown>) => {
    if (s.type === 'object') {
      assert.equal(s.additionalProperties, false);
      assert.deepEqual([...(s.required as string[])].sort(), Object.keys(s.properties as object).sort());
      for (const p of Object.values(s.properties as Record<string, Record<string, unknown>>)) check(p);
    }
    if (s.type === 'array') check(s.items as Record<string, unknown>);
  };
  check(AGENT_SCHEMA);
  check(INSIGHT_SCHEMA);
});
