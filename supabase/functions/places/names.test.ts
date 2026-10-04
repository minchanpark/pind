import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fitsLang, namePrompt, parseNames } from './names.ts';

test('parser keeps good names, drops languages with Hangul or the wrong script, skips unknown items',()=>{
  const text = JSON.stringify({items:[
    {ko:'봉자막창',segments:[{text:'봉자',kind:'proper'},{text:'막창',kind:'food'},{text:'?',kind:'other'}],
      en:' Bongja  Makchang ','ja':'ポンジャ 막창','zh-Hans':'奉子烤腸','zh-Hant':'奉子烤腸'},
    {ko:'지어낸 이름',segments:[],en:'X','ja':'X','zh-Hans':'X','zh-Hant':'X'},
  ]});
  assert.deepEqual(parseNames(text,['봉자막창','스타벅스']),[
    {ko:'봉자막창',segments:[['봉자','proper'],['막창','food']],names:{en:'Bongja Makchang','zh-Hant':'奉子烤腸'}},
    null,
  ]);
  assert.throws(() => parseNames('{}',['a']));
});

test('script guard matches the golden answers it is meant to allow',()=>{
  const golden = JSON.parse(readFileSync(new URL('./name_translation.golden.json',import.meta.url),'utf8'));
  for (const c of golden.cases) for (const lang of ['en','ja','zh-Hans','zh-Hant'] as const) {
    for (const answer of c[lang]) assert.ok(fitsLang(answer,lang),`${c.ko} ${lang}: ${answer}`);
  }
  assert.equal(fitsLang('星巴克 聖水站店','zh-Hans'),false);
  assert.equal(fitsLang('スターバックス','en'),false);
  assert.match(namePrompt(['a"b']),/^<names>\n\["a\\"b"\]\n<\/names>$/);
});
