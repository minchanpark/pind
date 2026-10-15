import test from 'node:test';
import assert from 'node:assert/strict';
import {englishNameRequest, parseEnglishNameResponse} from './names-en.ts';

const response = (items: unknown[], extra: object = {}) => ({
  choices: [{finish_reason: 'stop', message: {content: JSON.stringify({items}), ...extra}}],
});

test('NVIDIA requests disable reasoning generation and ask for English only', () => {
  const request = englishNameRequest(['식당 A']);
  assert.equal(request.model, 'deepseek-ai/deepseek-v4.1-flash');
  assert.deepEqual(request.thinking, {type: 'disabled'});
  assert.deepEqual(request.chat_template_kwargs, {enable_thinking: false});
  assert.equal(request.stream, false);
  assert.match(request.messages[1].content, /\["식당 A"\]/u);
});

test('reasoning output or billed reasoning tokens abort the evaluation', () => {
  const items = [{ko: '테스트', en: 'Test'}];
  assert.throws(() => parseEnglishNameResponse(response(items, {reasoning_content: 'thought'}), ['테스트']), /Reasoning/);
  assert.throws(() => parseEnglishNameResponse(response([{ko: '테스트', en: '<think>thought</think>Test'}]), ['테스트']), /Reasoning/);
  const data = {...response(items), usage: {completion_tokens_details: {reasoning_tokens: 1}}};
  assert.throws(() => parseEnglishNameResponse(data, ['테스트']), /Reasoning/);
});

test('missing, reordered, duplicated, extra-language or non-English results cannot be saved', () => {
  const names = ['가게 A', '가게 B'];
  for (const items of [
    [{ko: names[0], en: 'A'}],
    [{ko: names[1], en: 'B'}, {ko: names[0], en: 'A'}],
    [{ko: names[0], en: 'A'}, {ko: names[0], en: 'B'}],
    [{ko: names[0], en: 'A', ja: 'エー'}, {ko: names[1], en: 'B'}],
    [{ko: names[0], en: '가게 A'}, {ko: names[1], en: 'B'}],
  ]) assert.throws(() => parseEnglishNameResponse(response(items), names));
});

test('valid names preserve source identity and normalize whitespace', () => {
  assert.deepEqual(parseEnglishNameResponse(response([{ko: '테스트', en: '  Test   Cafe  '}]), ['테스트']),
    [{ko: '테스트', en: 'Test Cafe'}]);
  assert.throws(() => englishNameRequest(['a', 'a']), /unique/);
});
