import assert from 'node:assert/strict';
import test from 'node:test';

import {
  initialMapRegion,
  isCoordinateVisible,
  isRegionCenterInKorea,
  mapRegionAtCoordinate,
  nearbyRadiusMeters,
  regionQueryKey,
  zoomedMapRegion,
} from './mapRegion';

test('accepts map centers across South Korea and rejects other countries', () => {
  assert.equal(isRegionCenterInKorea({ latitude: 37.5665, longitude: 126.978 }), true);
  assert.equal(isRegionCenterInKorea({ latitude: 35.1796, longitude: 129.0756 }), true);
  assert.equal(isRegionCenterInKorea({ latitude: 33.4996, longitude: 126.5312 }), true);
  assert.equal(isRegionCenterInKorea({ latitude: 35.6762, longitude: 139.6503 }), false);
});

test('converts the visible map span into a bounded nearby radius', () => {
  assert.ok(nearbyRadiusMeters(initialMapRegion) > 8_000);
  assert.equal(nearbyRadiusMeters({ ...initialMapRegion, latitudeDelta: 10, longitudeDelta: 10 }), 50_000);
  assert.equal(nearbyRadiusMeters({ ...initialMapRegion, latitudeDelta: 0.00001, longitudeDelta: 0.00001 }), 500);
});

test('query keys ignore tiny movements but change across meaningful map areas', () => {
  assert.equal(regionQueryKey(initialMapRegion), regionQueryKey({ ...initialMapRegion, latitude: 37.567 }));
  assert.notEqual(regionQueryKey(initialMapRegion), regionQueryKey({ ...initialMapRegion, latitude: 35.1796, longitude: 129.0756 }));
});

test('checks whether a place is inside the current viewport', () => {
  assert.equal(isCoordinateVisible({ latitude: 37.57, longitude: 126.98 }, initialMapRegion), true);
  assert.equal(isCoordinateVisible({ latitude: 35.18, longitude: 129.08 }, initialMapRegion), false);
});

test('zoom controls preserve the center and clamp the supported map span', () => {
  const zoomedIn = zoomedMapRegion(initialMapRegion, 0.5);
  assert.equal(zoomedIn.latitude, initialMapRegion.latitude);
  assert.equal(zoomedIn.longitude, initialMapRegion.longitude);
  assert.equal(zoomedIn.latitudeDelta, 0.075);
  assert.equal(zoomedMapRegion({ ...initialMapRegion, latitudeDelta: 0.001 }, 0.5).latitudeDelta, 0.005);
  assert.equal(zoomedMapRegion({ ...initialMapRegion, longitudeDelta: 6 }, 2).longitudeDelta, 7.5);
});

test('current-location recentering uses the coordinate and a useful local zoom', () => {
  const region = mapRegionAtCoordinate(
    { latitude: 35.1796, longitude: 129.0756 },
    { ...initialMapRegion, latitudeDelta: 2, longitudeDelta: 2 },
  );
  assert.deepEqual(region, {
    latitude: 35.1796,
    longitude: 129.0756,
    latitudeDelta: 0.08,
    longitudeDelta: 0.08,
  });
});
