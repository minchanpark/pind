import test from 'node:test';
import assert from 'node:assert/strict';
import { CUISINE_WORDS, fallbackPlan, parseAgentPlan, tastePlan } from './agent.ts';

test('parser trims, dedupes, caps terms and drops a blank area',()=>{
  assert.deepEqual(parseAgentPlan(JSON.stringify({kinds:[],terms:[' 혼술 ','이자카야','혼술','','a','b','c','d'],area:' ',label:''})),
    {kinds:[],terms:['혼술','이자카야','a','b','c','d'],area:null,personal:false,label:'혼술 · 이자카야 · a · b · c · d'});
  assert.deepEqual(parseAgentPlan(JSON.stringify({kinds:[],terms:['바'],area:'성수동',label:'성수 바'})),{kinds:[],terms:['바'],area:'성수동',personal:false,label:'성수 바'});
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

test('"pick for me" is personal and takes no words from the model',()=>{
  const plan=parseAgentPlan(JSON.stringify({kinds:['x'],terms:['추천'],area:'성수동',personal:true,label:'내 취향'}));
  assert.equal(plan.personal,true);
  assert.deepEqual([plan.kinds,plan.terms,plan.area],[[],[],'성수동']);
  // Personal needs no words to be valid.
  assert.doesNotThrow(()=>parseAgentPlan('{"kinds":[],"terms":[],"area":"","personal":true,"label":""}'));
  assert.equal(fallbackPlan('내가 좋아할만한 곳 추천해줘').personal,true);
  assert.equal(fallbackPlan('내 취향에 맞는 데').personal,true);
  assert.notEqual(fallbackPlan('사진 잘 나오는 치킨집').personal,true,'a named kind is not personal');
  assert.notEqual(fallbackPlan('혼술 하기 좋은 식당').personal,true);
});

test('my foods become kinds, my occasions ranking words, taste ranks first',()=>{
  const base={kinds:[],terms:[],area:'성수동',label:'',personal:true};
  const p=tastePlan(base,['dessert','barbecue','nope',3,'dessert'],['date','work']);
  assert.deepEqual(p.kinds,['카페','디저트','커피','고기','구이','삼겹살','갈비']);
  assert.deepEqual(p.terms,['데이트','분위기','카공','작업','콘센트']);
  assert.equal(p.label,'내 취향 · 카페 · 고기구이');
  assert.equal(p.byTaste,true);
  assert.equal(p.area,'성수동','the sentence\'s area stays');
  // Every food at once stays within the search's kind cap.
  assert.ok(tastePlan(base,Object.keys(CUISINE_WORDS),[]).kinds.length<=16);
  // No foods picked: just my priorities' match, over every posted place.
  const bare=tastePlan(base,undefined,null);
  assert.deepEqual([bare.kinds,bare.terms,bare.label],[[],[],'내 취향']);
});
