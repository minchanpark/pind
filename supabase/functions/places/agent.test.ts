import test from 'node:test';
import assert from 'node:assert/strict';
import { fallbackPlan, parseAgentPlan } from './agent.ts';

test('parser trims, dedupes, caps terms and drops a blank area',()=>{
  assert.deepEqual(parseAgentPlan(JSON.stringify({kinds:[],terms:[' 혼술 ','이자카야','혼술','','a','b','c','d'],area:' ',label:''})),
    {kinds:[],terms:['혼술','이자카야','a','b','c','d'],area:null,label:'혼술 · 이자카야 · a · b · c · d'});
  assert.deepEqual(parseAgentPlan(JSON.stringify({kinds:[],terms:['바'],area:'성수동',label:'성수 바'})),{kinds:[],terms:['바'],area:'성수동',label:'성수 바'});
  assert.throws(()=>parseAgentPlan('{"kinds":[],"terms":[],"area":"","label":""}'));
  assert.throws(()=>parseAgentPlan('not json'));
});

test('the kind of place is kept apart from what it should be like',()=>{
  const plan=parseAgentPlan(JSON.stringify({kinds:['치킨','통닭','호프','치킨','x','y'],terms:['사진','치킨','인테리어'],area:'',label:''}));
  assert.deepEqual(plan.kinds,['치킨','통닭','호프','x']);
  assert.deepEqual(plan.terms,['사진','인테리어'],'a kind is not also a ranking word');
  // A kind alone is enough to search; older replies without kinds still parse.
  assert.deepEqual(parseAgentPlan(JSON.stringify({kinds:['카페'],terms:[],area:'',label:'카페'})).terms,[]);
  assert.deepEqual(parseAgentPlan(JSON.stringify({terms:['혼술'],area:'',label:''})).kinds,[]);
});

test('fallback keeps the meaningful words; a …집 word is the kind',()=>{
  assert.deepEqual(fallbackPlan('혼술 하기 좋은 식당').terms,['혼술']);
  assert.deepEqual(fallbackPlan('서울 성수동에 분위기 좋은 바').terms,['서울','성수동','분위기']);
  assert.deepEqual(fallbackPlan('식당').terms,['식당']);
  const chicken=fallbackPlan('사진 잘 나오는 치킨집');
  assert.deepEqual(chicken.kinds,['치킨']);
  assert.ok(chicken.terms.includes('사진'));
  assert.ok(!chicken.terms.includes('치킨집'));
});
