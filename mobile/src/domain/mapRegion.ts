export type MapRegion = {
  latitude: number;
  longitude: number;
  latitudeDelta: number;
  longitudeDelta: number;
};

export const initialMapRegion: MapRegion = {
  latitude: 37.5665,
  longitude: 126.978,
  latitudeDelta: 0.15,
  longitudeDelta: 0.15,
};

const koreaBounds = {
  south: 33,
  west: 124.5,
  north: 38.8,
  east: 132,
};

export function isRegionCenterInKorea(region: Pick<MapRegion, 'latitude' | 'longitude'>): boolean {
  return region.latitude >= koreaBounds.south &&
    region.latitude <= koreaBounds.north &&
    region.longitude >= koreaBounds.west &&
    region.longitude <= koreaBounds.east;
}

export function nearbyRadiusMeters(region: MapRegion): number {
  const halfLatitudeMeters = Math.abs(region.latitudeDelta) * 111_320 / 2;
  const halfLongitudeMeters = Math.abs(region.longitudeDelta) * 111_320 *
    Math.cos(region.latitude * Math.PI / 180) / 2;
  return Math.round(Math.min(50_000, Math.max(500, Math.hypot(halfLatitudeMeters, halfLongitudeMeters))));
}

export function regionQueryKey(region: MapRegion): string {
  const radiusBucket = Math.round(nearbyRadiusMeters(region) / 2_500);
  return `${region.latitude.toFixed(2)}:${region.longitude.toFixed(2)}:${radiusBucket}`;
}

export function isCoordinateVisible(
  coordinate: Pick<MapRegion, 'latitude' | 'longitude'>,
  region: MapRegion,
): boolean {
  return Math.abs(coordinate.latitude - region.latitude) <= Math.abs(region.latitudeDelta) / 2 &&
    Math.abs(coordinate.longitude - region.longitude) <= Math.abs(region.longitudeDelta) / 2;
}

export function zoomedMapRegion(region: MapRegion, scale: number): MapRegion {
  return {
    ...region,
    latitudeDelta: clamp(Math.abs(region.latitudeDelta) * scale, 0.005, 6),
    longitudeDelta: clamp(Math.abs(region.longitudeDelta) * scale, 0.005, 7.5),
  };
}

export function mapRegionAtCoordinate(
  coordinate: Pick<MapRegion, 'latitude' | 'longitude'>,
  currentRegion: MapRegion,
): MapRegion {
  return {
    latitude: coordinate.latitude,
    longitude: coordinate.longitude,
    latitudeDelta: clamp(Math.abs(currentRegion.latitudeDelta), 0.02, 0.08),
    longitudeDelta: clamp(Math.abs(currentRegion.longitudeDelta), 0.02, 0.08),
  };
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(maximum, Math.max(minimum, value));
}
