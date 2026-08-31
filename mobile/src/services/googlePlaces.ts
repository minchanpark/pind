import type { GooglePlaceCandidate, Place } from '../domain/types';
import type { MapRegion } from '../domain/mapRegion';
import { nearbyRadiusMeters } from '../domain/mapRegion';
import { supabase } from '../lib/supabase';
import { ensureWriterSession } from './posts';

type GooglePlacePayload = GooglePlaceCandidate & { internalId?: number };

type FunctionPayload = {
  places?: GooglePlacePayload[];
  place?: GooglePlacePayload;
  error?: { code?: string; message?: string };
};

export class GooglePlacesError extends Error {
  constructor(
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export async function searchGooglePlaces(query: string): Promise<GooglePlaceCandidate[]> {
  const data = await invokeGooglePlaces({ action: 'search', query, languageCode: 'en' });
  return data.places ?? [];
}

export async function fetchNearbyGooglePlaces(region: MapRegion): Promise<Place[]> {
  const data = await invokeGooglePlaces({
    action: 'nearby',
    latitude: region.latitude,
    longitude: region.longitude,
    radiusMeters: nearbyRadiusMeters(region),
    languageCode: 'en',
  });
  return (data.places ?? []).flatMap((place) => (place.internalId ? [toPlace(place)] : []));
}

export async function fetchGooglePlaceDetails(internalPlaceId: number): Promise<Place> {
  const data = await invokeGooglePlaces({ action: 'detail', internalPlaceId });
  if (!data.place?.internalId) throw new GooglePlacesError('INVALID_RESPONSE', 'Google returned incomplete place details.');
  return toPlace(data.place);
}

export async function resolveGooglePlace(externalPlaceId: string): Promise<Place> {
  const data = await invokeGooglePlaces({ action: 'resolve', externalPlaceId });
  if (!data.place?.internalId) throw new GooglePlacesError('INVALID_RESPONSE', 'Google returned an incomplete place.');
  return toPlace(data.place);
}

export async function hydrateGooglePlaces(internalPlaceIds: number[]): Promise<Place[]> {
  const uniqueIds = [...new Set(internalPlaceIds)].filter(Number.isSafeInteger).slice(0, 20);
  if (uniqueIds.length === 0) return [];

  const data = await invokeGooglePlaces({ action: 'details', internalPlaceIds: uniqueIds });
  return (data.places ?? []).flatMap((place) => (place.internalId ? [toPlace(place)] : []));
}

async function invokeGooglePlaces(body: Record<string, unknown>): Promise<FunctionPayload> {
  if (process.env.EXPO_PUBLIC_GOOGLE_MAPS_ENABLED !== 'true') {
    throw new GooglePlacesError(
      'GOOGLE_MAPS_BUILD_REQUIRED',
      'Real-place search needs a Google Maps-enabled native build. Add the Maps SDK key, enable the build flag, and rebuild the app.',
    );
  }
  await ensureWriterSession();
  const { data, error } = await supabase.functions.invoke<FunctionPayload>('google-places', { body });
  if (!error) return data ?? {};

  let code = 'GOOGLE_PLACES_ERROR';
  let message = error.message || 'Could not load Google Maps places.';
  const context = 'context' in error ? error.context : null;
  if (context && typeof context === 'object' && 'json' in context && typeof context.json === 'function') {
    try {
      const payload = (await context.json()) as FunctionPayload;
      code = payload.error?.code ?? code;
      message = payload.error?.message ?? message;
    } catch {
      // Keep the client error when the response is not JSON.
    }
  }
  throw new GooglePlacesError(code, message);
}

function toPlace(payload: GooglePlacePayload): Place {
  return {
    id: payload.internalId!,
    slug: `google-${payload.externalPlaceId}`,
    provider: 'google_places',
    externalPlaceId: payload.externalPlaceId,
    nameEn: payload.name,
    nameKo: payload.name,
    category: payload.category,
    addressEn: payload.address,
    addressKo: payload.address,
    latitude: payload.latitude,
    longitude: payload.longitude,
    heroImageUrl: payload.heroImageUrl,
    googleMapsUri: payload.googleMapsUri,
    photoGoogleMapsUri: payload.photoGoogleMapsUri,
    photoAttributions: payload.photoAttributions,
    gallery: payload.gallery,
    shortDescriptionEn: placeDescription(payload),
    shortDescriptionKo: `${payload.name}은(는) ${payload.address}에 있는 ${payload.category} 장소입니다. Google Maps에서 최신 장소 정보를 불러왔습니다.`,
    businessStatus: payload.businessStatus ?? null,
    isOpenNow: payload.isOpenNow ?? null,
    weekdayDescriptions: payload.weekdayDescriptions ?? [],
    websiteUri: payload.websiteUri ?? null,
    phoneNumber: payload.phoneNumber ?? null,
    editorialSummary: payload.editorialSummary ?? null,
    isDemo: false,
    tastes: [],
  };
}

function placeDescription(payload: GooglePlacePayload): string {
  const status = payload.businessStatus === 'OPERATIONAL'
    ? 'Google Maps currently lists it as operating.'
    : payload.businessStatus
      ? `Google Maps lists its business status as ${payload.businessStatus.toLowerCase().replaceAll('_', ' ')}.`
      : 'Opening and contact details are loaded live when available.';
  return `${payload.name} is a ${payload.category.toLowerCase()} at ${payload.address}. ${status}`;
}
