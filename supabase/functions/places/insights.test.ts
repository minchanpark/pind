import test from 'node:test';
import assert from 'node:assert/strict';
import { insightPrompt, parseInsight } from './insights.ts';

test('prompt carries legacy scores and parser drops unknown or empty criteria',()=>{
  assert.match(insightPrompt([{body:' 맛있다 ',taste_score:5,portion_score:4,ambience_score:null}]),
    /"ratings":\{"taste":5,"portion":4\},"text":"맛있다"/);
  assert.deepEqual(parseInsight(JSON.stringify({summary:' 소개 ',criteria:[
    {criterion:'taste',line:' 달지 않아요 '},{criterion:'hack',line:'x'},{criterion:'quiet',line:' '},
  ]})),{summary:'소개',criteria:{taste:'달지 않아요'}});
  assert.throws(()=>parseInsight('{"summary":1}'));
});
