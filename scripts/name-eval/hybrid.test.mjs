import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {buildHybridName,hybridNameRequest} from './hybrid.mjs';
import {checkedItems,matchesReference,aggregate} from './benchmark.mjs';

test('code fixes the repeated final-consonant mistake while restoring loanwords',()=>{
  assert.equal(buildHybridName({ko:'엄마손칼국수',parts:[{text:'엄마손',kind:'romanize'},{text:'칼국수',kind:'romanize'}]},'엄마손칼국수').en,'Eommason Kalguksu');
  assert.equal(buildHybridName({ko:'그레그커피',parts:[{text:'그레그',kind:'restore',en:'Greg'},{text:'커피',kind:'restore',en:'Keopi'}]},'그레그커피').en,'Greg Coffee');
});

test('standard pronunciation changes are handled by the converter',()=>{
  for(const [ko,en] of [['신림','Sillim'],['독립문','Dongnimmun'],['볶는','Bongneun']]) {
    assert.equal(buildHybridName({ko,parts:[{text:ko,kind:'romanize'}]},ko).en,en);
  }
});

test('known loanwords override model misclassification inside Korean chunks',()=>{
  assert.equal(buildHybridName({ko:'커피거리',parts:[{text:'커피거리',kind:'romanize'}]},'커피거리').en,'Coffee Geori');
  assert.equal(buildHybridName({ko:'카페고래',parts:[{text:'카페고래',kind:'romanize'}]},'카페고래').en,'Cafe Gorae');
});

test('literal whitespace preserves source boundaries without causing a false rejection',()=>{
  assert.equal(buildHybridName({ko:'고래 카페',parts:[{text:'고래',kind:'romanize'},{text:' ',kind:'literal'},
    {text:'카페',kind:'restore',en:'Cafe'}]},'고래 카페').en,'Gorae Cafe');
});

test('missing or added source characters, hidden English and Korean literals are rejected',()=>{
  assert.throws(()=>buildHybridName({ko:'가나다',parts:[{text:'가나',kind:'romanize'}]},'가나다'),/reconstruct/);
  assert.throws(()=>buildHybridName({ko:'가나',parts:[{text:'가나',kind:'romanize',en:'invented'}]},'가나'),/romanization/);
  assert.throws(()=>buildHybridName({ko:'가나',parts:[{text:'가나',kind:'literal'}]},'가나'),/Literal/);
});

test('hybrid requests disable reasoning and response validation requires zero tokens',()=>{
  const r=hybridNameRequest(['새로운 이름']);
  assert.deepEqual(r.thinking,{type:'disabled'});
  assert.deepEqual(r.chat_template_kwargs,{enable_thinking:false});
  const data={choices:[{finish_reason:'stop',message:{content:'{"items":[]}'}}],usage:{completion_tokens_details:{reasoning_tokens:1}}};
  assert.throws(()=>checkedItems(data,[]),/Reasoning/);
});

test('three matching wrong answers are reported separately from correct-candidate coverage',()=>{
  const c={id:1,ko:'새이름',group:'romanize',en:['Correct']};
  const reports=[];
  for(const method of ['baseline','hybrid']) for(const trial of [1,2,3]) {
    const en=method==='hybrid'&&trial===3?'Correct':'Wrong';
    reports.push({method,trial,results:[{id:1,ko:c.ko,group:c.group,en,ok:matchesReference(c,en)}]});
  }
  const s=aggregate([c],reports);
  assert.equal(s.baseline.best_of_three,0);
  assert.equal(s.hybrid.best_of_three,1);
  assert.equal(s.hybrid.majority_correct,0);
});

test('100-case holdout excludes the prior 20 and reference names stay out of both prompts',()=>{
  const fixture=JSON.parse(readFileSync(new URL('./name_english_100.golden.json',import.meta.url),'utf8'));
  const old=JSON.parse(readFileSync(new URL('../../supabase/functions/places/name_english.golden.json',import.meta.url),'utf8')).cases;
  assert.equal(fixture.cases.length,100);
  assert.equal(new Set(fixture.cases.map(c=>c.ko)).size,100);
  assert.ok(!fixture.cases.some(c=>old.some(p=>p.ko===c.ko)));
  const request=JSON.stringify(hybridNameRequest(fixture.cases.map(c=>c.ko)));
  assert.ok(!request.includes('accepted'));
  assert.ok(!request.includes('Myeongok Ppyeodagwi Gamjatang'));
});
