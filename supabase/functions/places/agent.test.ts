import test from 'node:test';
import assert from 'node:assert/strict';
import { fallbackPlan, parseAgentPlan } from './agent.ts';

test('parser trims, dedupes, caps terms and drops a blank area',()=>{
  assert.deepEqual(parseAgentPlan(JSON.stringify({terms:[' 혼술 ','이자카야','혼술','','a','b','c','d'],area:' ',label:''})),
    {terms:['혼술','이자카야','a','b','c','d'],area:null,label:'혼술 · 이자카야 · a · b · c · d'});
  assert.deepEqual(parseAgentPlan(JSON.stringify({terms:['바'],area:'성수동',label:'성수 바'})),{terms:['바'],area:'성수동',label:'성수 바'});
  assert.throws(()=>parseAgentPlan('{"terms":[],"area":"","label":""}'));
  assert.throws(()=>parseAgentPlan('not json'));
});

test('fallback keeps the meaningful words of the sentence',()=>{
  assert.deepEqual(fallbackPlan('혼술 하기 좋은 식당').terms,['혼술']);
  assert.deepEqual(fallbackPlan('서울 성수동에 분위기 좋은 바').terms,['서울','성수동','분위기']);
  assert.deepEqual(fallbackPlan('식당').terms,['식당']);
});
