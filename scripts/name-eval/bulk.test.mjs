import test from 'node:test';
import assert from 'node:assert/strict';
import {catalogGroups,needsEnglish,chooseBulkName,decodeBulkResponse,parseOptions} from './bulk.mjs';

const place=(id,name_ko,name_en=name_ko,extra={})=>({id,name_ko,name_en,is_published:true,is_demo:false,is_reference_only:false,external_provider:'sbiz',...extra});
const response=items=>({model:'deepseek-ai/deepseek-v4.1-flash',choices:[{finish_reason:'stop',message:{content:JSON.stringify({items})}}],usage:{completion_tokens_details:{reasoning_tokens:0}}});

test('catalog deduplication preserves existing English and excludes reference/demo/private rows',()=>{
  const rows=[place(1,'가게'),place(2,'가게'),place(3,'가게','Gage'),place(4,'다른가게','Different'),
    place(5,'비공개','비공개',{is_published:false}),place(6,'참조','참조',{is_reference_only:true}),
    place(7,'데모','데모',{is_demo:true})];
  const groups=catalogGroups(rows);
  assert.equal(groups.length,1);assert.deepEqual(groups[0].rows.map(r=>r.id),[1,2]);
  assert.ok(needsEnglish(place(8,'漢字','漢字')));
});

test('one reviewed correct spelling wins over a repeated error; no answer is synthesized',()=>{
  const candidates=[{trial:1,en:'Eommasong Kalguksu'},{trial:2,en:'Eommason Kalguksu'},{trial:3,en:'Eommasong Kalguksu'}];
  assert.equal(chooseBulkName('엄마손칼국수',candidates,['Eommason Kalguksu']).en,'Eommason Kalguksu');
  assert.equal(chooseBulkName('엄마손칼국수',[candidates[0],candidates[2]],['Eommason Kalguksu']).en,null);
});

test('consensus is case/spacing insensitive and cannot authorize re-romanized Coffee or missing digits',()=>{
  assert.equal(chooseBulkName('그레그커피',[{trial:1,en:'Greg Coffee'},{trial:2,en:'GregCoffee'},{trial:3,en:'Geuregeu Keopi'}]).en,'Greg Coffee');
  assert.equal(chooseBulkName('카페베네',[{trial:1,en:'Caffe Bene'}]).en,'Caffe Bene');
  assert.equal(chooseBulkName('커피',[{trial:1,en:'Keopi'},{trial:2,en:'Keopi'},{trial:3,en:'Keopi'}]).en,null);
  assert.equal(chooseBulkName('가게129',[{trial:1,en:'Gage'}]).en,null);
  assert.equal(chooseBulkName('가게129',[{trial:1,en:'Gage 129'}]).en,'Gage 129');
});

test('missing/duplicate source names do not get assigned to adjacent places',()=>{
  const data=response([{ko:'가게 B',en:'B'},{ko:'가게 A',en:'A'}]);
  assert.deepEqual(decodeBulkResponse(data,['가게 A','가게 B']),[{ko:'가게 A',en:'A'},{ko:'가게 B',en:'B'}]);
  const duplicate=decodeBulkResponse(response([{ko:'가게 A',en:'A'},{ko:'가게 A',en:'Other'}]),['가게 A','가게 B']);
  assert.ok(duplicate.every(r=>r.en===null));
});

test('unexpected scripts or reasoning are rejected before saving',()=>{
  assert.equal(decodeBulkResponse(response([{ko:'가게',en:'Ресторан'}]),['가게'])[0].en,null);
  const data=response([{ko:'가게',en:'Gage'}]);data.usage.completion_tokens_details.reasoning_tokens=1;
  assert.throws(()=>decodeBulkResponse(data,['가게']),/Reasoning/);
});

test('batch and worker settings are bounded; writes require explicit apply mode',()=>{
  assert.equal(parseOptions([]).apply,false);
  assert.equal(parseOptions(['--apply']).apply,true);
  assert.throws(()=>parseOptions(['--workers','100']),/Invalid/);
  assert.throws(()=>parseOptions(['--batch-size','0']),/Invalid/);
});
