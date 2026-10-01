import test from 'node:test';
import assert from 'node:assert/strict';
import { INSIGHT_SYSTEM, insightPrompt, parseInsight, retryOnce } from './insights.ts';

test('prompt carries legacy scores and parser drops unknown or empty criteria',()=>{
  assert.match(insightPrompt([{body:' 맛있다 ',taste_score:5,portion_score:4,ambience_score:null}]),
    /"ratings":\{"taste":5,"portion":4\},"text":"맛있다"/);
  assert.deepEqual(parseInsight(JSON.stringify({summary:' 소개 ',criteria:[
    {criterion:'taste',line:' 달지 않아요 '},{criterion:'hack',line:'x'},{criterion:'quiet',line:' '},
  ]})),{summary:'소개',criteria:{taste:'달지 않아요'}});
  assert.throws(()=>parseInsight('{"summary":1}'));
});

test('every rated criterion gets a line; rating-only ones cite the stars',()=>{
  assert.match(INSIGHT_SYSTEM,/빠짐없이/);
  assert.match(INSIGHT_SYSTEM,/별점만 근거로/);
  assert.doesNotMatch(INSIGHT_SYSTEM,/해당 항목을 빼세요/);
});

test('retryOnce retries 429/503 once and rethrows anything else',async()=>{
  let calls=0;
  assert.equal(await retryOnce(async()=>{ if(calls++===0) throw Object.assign(new Error('busy'),{status:503}); return 'ok'; },0),'ok');
  assert.equal(calls,2);
  calls=0;
  await assert.rejects(retryOnce(async()=>{ calls++; throw Object.assign(new Error('limit'),{status:429}); },0),/limit/);
  assert.equal(calls,2);
  calls=0;
  await assert.rejects(retryOnce(async()=>{ calls++; throw Object.assign(new Error('bad'),{status:400}); },0),/bad/);
  assert.equal(calls,1);
});
