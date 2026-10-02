// "성수동", "성수역", "강남구" → a circle to search in. Catalog addresses are
// road names (아차산로 104) with no 동, so an area can't be matched as text.
// Google Places Text Search is the one geocoder this key has enabled.

export type Area = {latitude: number; longitude: number; radiusMeters: number};

const MIN_RADIUS = 1000, MAX_RADIUS = 5000;

/// Half the viewport's diagonal, kept between a station's walk and a 구.
export function parseArea(data: unknown): Area | null {
  const place = (data as {places?: {location?: {latitude: number; longitude: number}; viewport?: {low: {latitude: number; longitude: number}; high: {latitude: number; longitude: number}}}[]})?.places?.[0];
  const at = place?.location;
  if (!at || at.latitude < 33 || at.latitude > 38.8 || at.longitude < 124.5 || at.longitude > 132) return null;
  let radius = MIN_RADIUS;
  if (place.viewport) {
    const {low, high} = place.viewport;
    const dy = (high.latitude - low.latitude) * 111_000;
    const dx = (high.longitude - low.longitude) * 111_000 * Math.cos(at.latitude * Math.PI / 180);
    radius = Math.hypot(dx, dy) / 2;
  }
  return {latitude: at.latitude, longitude: at.longitude,
    radiusMeters: Math.round(Math.min(MAX_RADIUS, Math.max(MIN_RADIUS, radius)))};
}

/// null when there's no key or Google can't place it; search then runs
/// around the map center as if no area was named.
export async function geocodeArea(area: string, key: string | undefined, fetcher: typeof fetch = fetch): Promise<Area | null> {
  if (!key) return null;
  try {
    const response = await fetcher('https://places.googleapis.com/v1/places:searchText', {
      method: 'POST',
      headers: {'Content-Type': 'application/json', 'X-Goog-Api-Key': key,
        'X-Goog-FieldMask': 'places.location,places.viewport'},
      body: JSON.stringify({textQuery: area, languageCode: 'ko', regionCode: 'KR', pageSize: 1}),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return parseArea(await response.json());
  } catch (error) {
    console.error('area geocode failed', area, error);
    return null;
  }
}
