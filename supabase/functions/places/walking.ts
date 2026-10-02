// Walking directions from TMAP (SK Open API). Naver's Directions API is
// driving-only, and Google has no walking routes in Korea.
import { CatalogError } from './catalog.ts';

export type WalkingRoute = {points: [number, number][]; meters: number; seconds: number};

const TMAP_URL = 'https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1';
const inKorea = (lat: unknown, lng: unknown): lat is number =>
  typeof lat === 'number' && typeof lng === 'number' && lat >= 33 && lat <= 38.8 && lng >= 124.5 && lng <= 132;

/// TMAP's GeoJSON → [lat, lng] points in order, with the route totals.
export function parseWalking(data: unknown): WalkingRoute {
  const features = (data as {features?: unknown})?.features;
  if (!Array.isArray(features)) throw new Error('No features');
  const totals = features[0]?.properties ?? {};
  const points: [number, number][] = [];
  for (const f of features) {
    if (f?.geometry?.type !== 'LineString') continue;
    for (const [lng, lat] of f.geometry.coordinates as [number, number][]) {
      const last = points.at(-1);
      if (!last || last[0] !== lat || last[1] !== lng) points.push([lat, lng]);
    }
  }
  if (points.length < 2) throw new Error('No line');
  return {points, meters: Number(totals.totalDistance) || 0, seconds: Number(totals.totalTime) || 0};
}

export async function walkingRoute(
  body: Record<string, unknown>,
  key: string | undefined,
  fetcher: typeof fetch = fetch,
): Promise<WalkingRoute> {
  const {fromLatitude: fy, fromLongitude: fx, toLatitude: ty, toLongitude: tx} = body;
  if (!inKorea(fy, fx) || !inKorea(ty, tx)) {
    throw new CatalogError(400, 'INVALID_ROUTE', '한국 안의 출발지와 도착지만 안내할 수 있어요.');
  }
  // ponytail: straight-line cap; TMAP rejects very long walks anyway.
  const dy = (ty - fy) * 111_000, dx = ((tx as number) - (fx as number)) * 111_000 * Math.cos(fy * Math.PI / 180);
  if (Math.hypot(dx, dy) > 20_000) throw new CatalogError(400, 'ROUTE_TOO_FAR', '걸어가기엔 너무 멀어요.');
  if (!key) throw new CatalogError(503, 'ROUTE_UNAVAILABLE', '길찾기를 준비 중이에요.');
  const response = await fetcher(TMAP_URL, {
    method: 'POST',
    headers: {appKey: key, 'Content-Type': 'application/json', Accept: 'application/json'},
    // Names must be URL-encoded UTF-8, per the TMAP reference.
    body: JSON.stringify({
      startX: fx, startY: fy, endX: tx, endY: ty,
      startName: encodeURIComponent('출발'), endName: encodeURIComponent('도착'),
      reqCoordType: 'WGS84GEO', resCoordType: 'WGS84GEO', searchOption: '0',
    }),
  });
  if (!response.ok) {
    console.error('tmap pedestrian failed', response.status, await response.text());
    throw new CatalogError(502, 'ROUTE_FAILED', '도보 경로를 찾지 못했어요. 잠시 후 다시 시도해 주세요.');
  }
  try {
    return parseWalking(await response.json());
  } catch (error) {
    console.error('tmap pedestrian parse failed', error);
    throw new CatalogError(502, 'ROUTE_FAILED', '도보 경로를 찾지 못했어요. 잠시 후 다시 시도해 주세요.');
  }
}
