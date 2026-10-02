import test from 'node:test';
import assert from 'node:assert/strict';
import { geocodeArea, parseArea } from './area.ts';

// Google's answer for "성수동" (성수동2가), trimmed.
const seongsu = {places: [{
  location: {latitude: 37.5406846, longitude: 127.0566319},
  viewport: {low: {latitude: 37.528318, longitude: 127.048919}, high: {latitude: 37.551110, longitude: 127.067464}},
}]};

test('a 동 becomes its center and half its viewport diagonal', () => {
  const area = parseArea(seongsu)!;
  assert.equal(area.latitude, 37.5406846);
  assert.equal(area.longitude, 127.0566319);
  assert.ok(area.radiusMeters > 1500 && area.radiusMeters < 2000, String(area.radiusMeters));
});

test('tiny and huge viewports are clamped; nothing or abroad is null', () => {
  const at = {latitude: 37.5446, longitude: 127.0557};
  const box = (d: number) => ({places: [{location: at, viewport: {
    low: {latitude: at.latitude - d, longitude: at.longitude - d}, high: {latitude: at.latitude + d, longitude: at.longitude + d}}}]});
  assert.equal(parseArea(box(0.0005))!.radiusMeters, 1000);
  assert.equal(parseArea(box(0.5))!.radiusMeters, 5000);
  assert.equal(parseArea({places: [{location: at}]})!.radiusMeters, 1000);
  assert.equal(parseArea({}), null);
  assert.equal(parseArea({places: [{location: {latitude: 35.68, longitude: 139.76}}]}), null);
});

test('asks Text Search for location only; any failure is null', async () => {
  let sent: RequestInit | undefined;
  const area = await geocodeArea('성수동', 'k', async (_url, init) => { sent = init; return new Response(JSON.stringify(seongsu)); });
  assert.ok(area);
  const headers = sent!.headers as Record<string, string>;
  assert.equal(headers['X-Goog-Api-Key'], 'k');
  assert.equal(headers['X-Goog-FieldMask'], 'places.location,places.viewport');
  assert.equal(JSON.parse(String(sent!.body)).textQuery, '성수동');
  assert.equal(await geocodeArea('성수동', undefined), null);
  assert.equal(await geocodeArea('성수동', 'k', async () => new Response('{}', {status: 403})), null);
  assert.equal(await geocodeArea('성수동', 'k', async () => { throw new Error('offline'); }), null);
});
