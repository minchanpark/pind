import test from 'node:test';
import assert from 'node:assert/strict';
import { parseWalking, walkingRoute } from './walking.ts';

// Shape of TMAP's pedestrian response: points for turns, lines between them.
const tmap = {features: [
  {geometry: {type: 'Point', coordinates: [127.055, 37.544]}, properties: {totalDistance: 420, totalTime: 310}},
  {geometry: {type: 'LineString', coordinates: [[127.055, 37.544], [127.056, 37.545]]}, properties: {}},
  {geometry: {type: 'Point', coordinates: [127.056, 37.545]}, properties: {}},
  {geometry: {type: 'LineString', coordinates: [[127.056, 37.545], [127.058, 37.546]]}, properties: {}},
]};
const route = {fromLatitude: 37.544, fromLongitude: 127.055, toLatitude: 37.546, toLongitude: 127.058};

test('lines join into one [lat, lng] path with the totals', () => {
  assert.deepEqual(parseWalking(tmap), {
    points: [[37.544, 127.055], [37.545, 127.056], [37.546, 127.058]], meters: 420, seconds: 310,
  });
  assert.throws(() => parseWalking({features: [tmap.features[0]]}));
  assert.throws(() => parseWalking({error: {code: 'INVALID_API_KEY'}}));
});

test('asks TMAP with the key and WGS84 coordinates', async () => {
  const calls: [string, RequestInit][] = [];
  const result = await walkingRoute(route, 'k', async (url, init) => {
    calls.push([String(url), init!]);
    return new Response(JSON.stringify(tmap));
  });
  assert.equal(result.points.length, 3);
  const [url, init] = calls[0];
  assert.match(url, /tmap\/routes\/pedestrian\?version=1$/);
  assert.equal((init.headers as Record<string, string>).appKey, 'k');
  const sent = JSON.parse(String(init.body));
  assert.deepEqual([sent.startX, sent.startY, sent.endX, sent.endY], [127.055, 37.544, 127.058, 37.546]);
  assert.equal(sent.reqCoordType, 'WGS84GEO');
  assert.equal(sent.resCoordType, 'WGS84GEO');
});

test('bad input, missing key and TMAP errors become friendly failures', async () => {
  const never = async () => { throw new Error('should not call'); };
  await assert.rejects(walkingRoute({...route, toLatitude: 51}, 'k', never), {code: 'INVALID_ROUTE'});
  await assert.rejects(walkingRoute({...route, toLatitude: 37.8}, 'k', never), {code: 'ROUTE_TOO_FAR'});
  await assert.rejects(walkingRoute(route, undefined, never), {code: 'ROUTE_UNAVAILABLE'});
  await assert.rejects(walkingRoute(route, 'k', async () => new Response('{"error":{}}', {status: 403})), {code: 'ROUTE_FAILED'});
});
