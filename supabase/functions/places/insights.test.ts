import test from 'node:test';
import assert from 'node:assert/strict';
import { INSIGHT_SYSTEM, insightPrompt, parseInsight, withFallback } from './insights.ts';

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

test('withFallback moves to the next model only on 429/503',async()=>{
  const fail=(status:number)=>Object.assign(new Error(`e${status}`),{status});
  let tried:string[]=[];
  assert.equal(await withFallback(['a','b'],async m=>{ tried.push(m); if(m==='a') throw fail(503); return m; },0),'b');
  assert.deepEqual(tried,['a','b']);
  tried=[];
  await assert.rejects(withFallback(['a','b'],async m=>{ tried.push(m); throw fail(429); },0),/e429/);
  assert.deepEqual(tried,['a','b']);
  tried=[];
  await assert.rejects(withFallback(['a','b'],async m=>{ tried.push(m); throw fail(400); },0),/e400/);
  assert.deepEqual(tried,['a']);
});
