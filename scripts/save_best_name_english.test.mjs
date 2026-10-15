import test from 'node:test';
import assert from 'node:assert/strict';
import {selectBestEnglishNames, buildNameSaveSql} from './save_best_name_english.mjs';

const cases = [
  {id: 1, ko: '엄마손칼국수', en: ['Eommason Kalguksu']},
  {id: 2, ko: '투썸', en: ['A Twosome Place', 'Twosome']},
];
const trial = answers => ({request_sha256: 'same-prompt', reasoning_content_present: false,
  reasoning_tokens: 0, results: answers.map((en, i) => ({id: cases[i].id, ko: cases[i].ko, en}))});

test('one correct romanization wins over two repeated spelling mistakes', () => {
  const result = selectBestEnglishNames(cases, [
    trial(['Eommasom Kalguksu', 'Twosome']), trial(['Eommason Kalguksu', 'A Twosome Place']),
    trial(['Eommasom Kalguksu', 'Twosome']),
  ]);
  assert.equal(result[0].en, 'Eommason Kalguksu');
  assert.equal(result[0].source_trial, 2);
  assert.equal(result[0].valid_trials, 1);
  assert.equal(result[1].en, 'A Twosome Place');
});

test('three mistakes leave the name unsaved instead of inserting the golden answer', () => {
  const result = selectBestEnglishNames(cases, Array.from({length: 3}, () => trial(['Eommasom Kalguksu', 'Twosome'])));
  assert.equal(result[0].en, null);
  assert.equal(result[0].status, 'no_valid_candidate');
  const sql = buildNameSaveSql(result, [{id: 1, name_ko: cases[0].ko, name_en: null},
    {id: 2, name_ko: cases[1].ko, name_en: '투썸'}]);
  assert.ok(!sql.includes('Eommason'));
  assert.match(sql, /"id":2/u);
  assert.ok(!sql.includes('"id":1'));
});

test('incomplete trials, different prompts, reasoning and mismatched places block saving', () => {
  const good = trial(['Eommason Kalguksu', 'Twosome']);
  assert.throws(() => selectBestEnglishNames(cases, [good, good]), /three/);
  assert.throws(() => selectBestEnglishNames(cases, [good, good, {...good, request_sha256: 'changed'}]), /differ/);
  assert.throws(() => selectBestEnglishNames(cases, [good, good, {...good, reasoning_tokens: 1}]), /Invalid/);
  const wrong = structuredClone(good);
  wrong.results[0].id = 999;
  assert.throws(() => selectBestEnglishNames(cases, [good, good, wrong]), /Invalid/);
});

test('writes compare original Korean and previous English names, preserving concurrent edits', () => {
  const chosen = [{id: 1, ko: '엄마손칼국수', en: 'Eommason Kalguksu'}];
  const sql = buildNameSaveSql(chosen, [{id: 1, name_ko: chosen[0].ko, name_en: "Mom's"}]);
  assert.ok(sql.includes("Mom''s"));
  assert.ok(sql.includes('p.name_ko = v.ko'));
  assert.ok(sql.includes('p.name_en is not distinct from v.previous_en'));
  assert.ok(sql.includes('not p.is_reference_only'));
  assert.throws(() => buildNameSaveSql(chosen, [{id: 1, name_ko: 'changed', name_en: null}]), /changed/);
});
