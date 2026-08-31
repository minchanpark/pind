import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.112.3";

const corsHeaders = {
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Origin": "*",
};

const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" };
const googleApiBase = "https://places.googleapis.com/v1";
const koreaViewport = {
  low: { latitude: 33, longitude: 124.5 },
  high: { latitude: 38.8, longitude: 132 },
};
const foodTypes = new Set([
  "bakery",
  "bar",
  "cafe",
  "coffee_shop",
  "confectionery",
  "dessert_shop",
  "food",
  "food_court",
  "ice_cream_shop",
  "juice_shop",
  "meal_delivery",
  "meal_takeaway",
  "restaurant",
  "sandwich_shop",
  "tea_house",
]);

type GoogleAuthorAttribution = {
  displayName?: string;
  photoUri?: string;
  uri?: string;
};

type GooglePhoto = {
  name?: string;
  googleMapsUri?: string;
  authorAttributions?: GoogleAuthorAttribution[];
};

type GooglePlace = {
  id?: string;
  types?: string[];
  displayName?: { text?: string; languageCode?: string };
  formattedAddress?: string;
  addressComponents?: Array<{ longText?: string; shortText?: string; types?: string[] }>;
  location?: { latitude?: number; longitude?: number };
  primaryType?: string;
  primaryTypeDisplayName?: { text?: string };
  googleMapsUri?: string;
  photos?: GooglePhoto[];
  businessStatus?: string;
  regularOpeningHours?: {
    openNow?: boolean;
    weekdayDescriptions?: string[];
  };
  websiteUri?: string;
  nationalPhoneNumber?: string;
  editorialSummary?: { text?: string; languageCode?: string };
};

type PlacePayload = {
  internalId?: number;
  externalPlaceId: string;
  name: string;
  category: string;
  address: string;
  latitude: number;
  longitude: number;
  heroImageUrl: string | null;
  googleMapsUri: string;
  photoGoogleMapsUri: string | null;
  photoAttributions: Array<{ displayName: string; uri: string | null; photoUri: string | null }>;
  gallery: Array<{
    uri: string;
    googleMapsUri: string | null;
    attributions: Array<{ displayName: string; uri: string | null; photoUri: string | null }>;
  }>;
  businessStatus: string | null;
  isOpenNow: boolean | null;
  weekdayDescriptions: string[];
  websiteUri: string | null;
  phoneNumber: string | null;
  editorialSummary: string | null;
};

class RequestError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return json({ error: { code: "METHOD_NOT_ALLOWED", message: "Use POST." } }, 405);

  try {
    await requireUser(request);

    const apiKey = Deno.env.get("GOOGLE_PLACES_API_KEY");
    if (!apiKey) {
      throw new RequestError(
        503,
        "GOOGLE_PLACES_NOT_CONFIGURED",
        "Real-place search is ready, but the Google Places server key has not been configured yet.",
      );
    }

    const body = await readBody(request);
    if (body.action === "nearby") return await nearbyPlaces(body, apiKey);
    if (body.action === "search") return await searchPlaces(body, apiKey);
    if (body.action === "resolve") return await resolvePlace(body, apiKey);
    if (body.action === "detail") return await placeDetail(body, apiKey);
    if (body.action === "details") return await hydratePlaces(body, apiKey);

    throw new RequestError(400, "INVALID_ACTION", "Action must be nearby, search, resolve, detail, or details.");
  } catch (caught) {
    if (caught instanceof RequestError) {
      return json({ error: { code: caught.code, message: caught.message } }, caught.status);
    }
    console.error(caught instanceof Error ? caught.message : "Unknown Google Places function error");
    return json({ error: { code: "INTERNAL_ERROR", message: "Could not load place data." } }, 500);
  }
});

async function requireUser(request: Request) {
  const authorization = request.headers.get("Authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  if (!authorization || !supabaseUrl || !anonKey) {
    throw new RequestError(401, "UNAUTHORIZED", "Sign in before searching for places.");
  }

  const client = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: authorization } },
  });
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) throw new RequestError(401, "UNAUTHORIZED", "Your session is no longer valid.");
}

async function readBody(request: Request): Promise<Record<string, unknown>> {
  try {
    const body = await request.json();
    if (!body || typeof body !== "object" || Array.isArray(body)) throw new Error("Invalid body");
    return body as Record<string, unknown>;
  } catch {
    throw new RequestError(400, "INVALID_JSON", "Send a JSON request body.");
  }
}

async function nearbyPlaces(body: Record<string, unknown>, apiKey: string) {
  const latitude = requiredNumber(body.latitude, "latitude", -90, 90);
  const longitude = requiredNumber(body.longitude, "longitude", -180, 180);
  if (!isInKorea(latitude, longitude)) {
    throw new RequestError(400, "OUTSIDE_KOREA", "Move the map within South Korea to load places.");
  }
  const radiusMeters = requiredNumber(body.radiusMeters, "radiusMeters", 100, 50000);
  const languageCode = body.languageCode === "ko" ? "ko" : "en";
  const response = await googleFetch<{ places?: GooglePlace[] }>(
    `${googleApiBase}/places:searchNearby`,
    apiKey,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-FieldMask": basePlaceFields("places."),
      },
      body: JSON.stringify({
        includedPrimaryTypes: ["restaurant", "cafe", "bakery", "dessert_shop"],
        maxResultCount: 20,
        rankPreference: "POPULARITY",
        languageCode,
        regionCode: "KR",
        locationRestriction: {
          circle: { center: { latitude, longitude }, radius: radiusMeters },
        },
      }),
    },
  );

  const normalized = await Promise.all(
    (response.places ?? [])
      .filter(isSouthKoreanPlace)
      .map((place) => normalizePlace(place, apiKey, 1)),
  );
  return json({ places: await attachInternalIds(normalized.flatMap((place) => (place ? [place] : []))) });
}

async function searchPlaces(body: Record<string, unknown>, apiKey: string) {
  const query = requiredString(body.query, "query", 2, 120);
  const languageCode = body.languageCode === "ko" ? "ko" : "en";
  const response = await googleFetch<{ places?: GooglePlace[] }>(
    `${googleApiBase}/places:searchText`,
    apiKey,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Goog-FieldMask": [
          "places.id",
          "places.types",
          "places.displayName",
          "places.formattedAddress",
          "places.addressComponents",
          "places.location",
          "places.primaryType",
          "places.primaryTypeDisplayName",
          "places.googleMapsUri",
          "places.photos",
        ].join(","),
      },
      body: JSON.stringify({
        textQuery: query,
        languageCode,
        regionCode: "KR",
        pageSize: 10,
        locationBias: { rectangle: koreaViewport },
      }),
    },
  );

  const foodPlaces = (response.places ?? []).filter((place) =>
    isInKorea(place.location?.latitude, place.location?.longitude) &&
    isSouthKoreanPlace(place) &&
    (place.types ?? []).some((type) => foodTypes.has(type) || type.endsWith("_restaurant")),
  );
  const candidates = await Promise.all(foodPlaces.slice(0, 8).map((place) => normalizePlace(place, apiKey, 1)));
  return json({ places: candidates.flatMap((place) => (place ? [place] : [])) });
}

async function resolvePlace(body: Record<string, unknown>, apiKey: string) {
  const externalPlaceId = requiredString(body.externalPlaceId, "externalPlaceId", 8, 255);
  const place = await getPlace(externalPlaceId, apiKey);
  const normalized = await normalizePlace(place, apiKey, 1);
  if (!normalized) throw new RequestError(404, "PLACE_NOT_FOUND", "Google did not return this place.");

  const admin = adminClient();
  const { data, error } = await admin
    .from("places")
    .upsert(
      {
        slug: `google-${externalPlaceId}`,
        external_provider: "google_places",
        external_place_id: externalPlaceId,
        is_reference_only: true,
        is_demo: false,
        is_published: true,
        name_en: null,
        name_ko: null,
        category: null,
        address_en: null,
        address_ko: null,
        latitude: null,
        longitude: null,
        hero_image_url: null,
        short_description_en: null,
        short_description_ko: null,
      },
      { onConflict: "external_provider,external_place_id" },
    )
    .select("id")
    .single();
  if (error || !data) throw new RequestError(500, "REFERENCE_WRITE_FAILED", "Could not attach this place to Pind.");

  return json({ place: { ...normalized, internalId: Number(data.id) } });
}

async function placeDetail(body: Record<string, unknown>, apiKey: string) {
  const internalPlaceId = requiredNumber(body.internalPlaceId, "internalPlaceId", 1, Number.MAX_SAFE_INTEGER);
  const admin = adminClient();
  const { data, error } = await admin
    .from("places")
    .select("id,external_place_id")
    .eq("id", internalPlaceId)
    .eq("external_provider", "google_places")
    .eq("is_reference_only", true)
    .maybeSingle();
  if (error) throw new RequestError(500, "REFERENCE_READ_FAILED", "Could not read this place reference.");
  if (!data?.external_place_id) throw new RequestError(404, "PLACE_NOT_FOUND", "This Google place is not attached to Pind.");

  const place = await getPlace(String(data.external_place_id), apiKey, true);
  const normalized = await normalizePlace(place, apiKey, 6);
  if (!normalized) throw new RequestError(404, "PLACE_NOT_FOUND", "Google did not return this place.");
  return json({ place: { ...normalized, internalId: Number(data.id) } });
}

async function hydratePlaces(body: Record<string, unknown>, apiKey: string) {
  if (!Array.isArray(body.internalPlaceIds)) {
    throw new RequestError(400, "INVALID_PLACE_IDS", "internalPlaceIds must be an array.");
  }
  const internalPlaceIds = [...new Set(body.internalPlaceIds)]
    .filter((value): value is number => typeof value === "number" && Number.isSafeInteger(value) && value > 0)
    .slice(0, 20);
  if (internalPlaceIds.length === 0) return json({ places: [] });

  const admin = adminClient();
  const { data, error } = await admin
    .from("places")
    .select("id,external_place_id")
    .eq("external_provider", "google_places")
    .eq("is_reference_only", true)
    .in("id", internalPlaceIds);
  if (error) throw new RequestError(500, "REFERENCE_READ_FAILED", "Could not read place references.");

  const places = await Promise.all(
    (data ?? []).map(async (reference) => {
      try {
        const externalPlaceId = String(reference.external_place_id);
        const place = await getPlace(externalPlaceId, apiKey);
        const normalized = await normalizePlace(place, apiKey, 1);
        return normalized ? { ...normalized, internalId: Number(reference.id) } : null;
      } catch (caught) {
        console.warn(`Could not hydrate Google place reference ${reference.id}: ${caught instanceof Error ? caught.message : "unknown error"}`);
        return null;
      }
    }),
  );

  return json({ places: places.flatMap((place) => (place ? [place] : [])) });
}

async function getPlace(externalPlaceId: string, apiKey: string, extended = false): Promise<GooglePlace> {
  return await googleFetch<GooglePlace>(
    `${googleApiBase}/places/${encodeURIComponent(externalPlaceId)}?languageCode=en&regionCode=KR`,
    apiKey,
    {
      headers: {
        "X-Goog-FieldMask": [
          basePlaceFields(),
          ...(extended
            ? ["regularOpeningHours", "websiteUri", "nationalPhoneNumber", "editorialSummary"]
            : []),
        ].join(","),
      },
    },
  );
}

async function normalizePlace(place: GooglePlace, apiKey: string, photoLimit: number): Promise<PlacePayload | null> {
  const externalPlaceId = place.id;
  const name = place.displayName?.text;
  const address = place.formattedAddress;
  const latitude = place.location?.latitude;
  const longitude = place.location?.longitude;
  const googleMapsUri = place.googleMapsUri;
  if (!externalPlaceId || !name || !address || latitude === undefined || longitude === undefined || !googleMapsUri) {
    return null;
  }

  const gallery = (await Promise.all((place.photos ?? []).slice(0, photoLimit).map(async (photo) => {
    if (!photo.name) return null;
    const uri = await getPhotoUri(photo.name, apiKey);
    if (!uri) return null;
    return {
      uri,
      googleMapsUri: photo.googleMapsUri ?? null,
      attributions: normalizeAttributions(photo.authorAttributions),
    };
  }))).flatMap((photo) => photo ? [photo] : []);
  const heroPhoto = gallery[0];
  return {
    externalPlaceId,
    name,
    category: place.primaryTypeDisplayName?.text ?? formatType(place.primaryType),
    address,
    latitude,
    longitude,
    heroImageUrl: heroPhoto?.uri ?? null,
    googleMapsUri,
    photoGoogleMapsUri: heroPhoto?.googleMapsUri ?? null,
    photoAttributions: heroPhoto?.attributions ?? [],
    gallery,
    businessStatus: place.businessStatus ?? null,
    isOpenNow: place.regularOpeningHours?.openNow ?? null,
    weekdayDescriptions: place.regularOpeningHours?.weekdayDescriptions ?? [],
    websiteUri: place.websiteUri ?? null,
    phoneNumber: place.nationalPhoneNumber ?? null,
    editorialSummary: place.editorialSummary?.text ?? null,
  };
}

function normalizeAttributions(attributions?: GoogleAuthorAttribution[]) {
  return (attributions ?? []).map((attribution) => ({
    displayName: attribution.displayName ?? "Google Maps contributor",
    uri: attribution.uri ?? null,
    photoUri: attribution.photoUri ?? null,
  }));
}

async function attachInternalIds(places: PlacePayload[]): Promise<Array<PlacePayload & { internalId: number }>> {
  if (places.length === 0) return [];
  const admin = adminClient();
  const { data, error } = await admin
    .from("places")
    .upsert(
      places.map((place) => ({
        slug: `google-${place.externalPlaceId}`,
        external_provider: "google_places",
        external_place_id: place.externalPlaceId,
        is_reference_only: true,
        is_demo: false,
        is_published: true,
        name_en: null,
        name_ko: null,
        category: null,
        address_en: null,
        address_ko: null,
        latitude: null,
        longitude: null,
        hero_image_url: null,
        short_description_en: null,
        short_description_ko: null,
      })),
      { onConflict: "external_provider,external_place_id" },
    )
    .select("id,external_place_id");
  if (error) throw new RequestError(500, "REFERENCE_WRITE_FAILED", "Could not attach nearby places to Pind.");

  const idsByExternalId = new Map((data ?? []).map((row) => [String(row.external_place_id), Number(row.id)]));
  return places.flatMap((place) => {
    const internalId = idsByExternalId.get(place.externalPlaceId);
    return internalId ? [{ ...place, internalId }] : [];
  });
}

function basePlaceFields(prefix = ""): string {
  return [
    "id",
    "types",
    "displayName",
    "formattedAddress",
    "addressComponents",
    "location",
    "primaryType",
    "primaryTypeDisplayName",
    "googleMapsUri",
    "photos",
    "businessStatus",
  ].map((field) => `${prefix}${field}`).join(",");
}

async function getPhotoUri(photoName: string, apiKey: string): Promise<string | null> {
  try {
    const photo = await googleFetch<{ photoUri?: string }>(
      `${googleApiBase}/${photoName}/media?maxWidthPx=1200&maxHeightPx=1200&skipHttpRedirect=true`,
      apiKey,
      {},
    );
    return photo.photoUri ?? null;
  } catch (caught) {
    console.warn(caught instanceof Error ? caught.message : "Google photo unavailable");
    return null;
  }
}

async function googleFetch<T>(url: string, apiKey: string, init: RequestInit): Promise<T> {
  const headers = new Headers(init.headers);
  headers.set("X-Goog-Api-Key", apiKey);
  const response = await fetch(url, {
    ...init,
    headers,
    signal: AbortSignal.timeout(9000),
  });
  if (!response.ok) {
    const googleError = await readGoogleError(response);
    console.error(JSON.stringify({
      provider: "google_places",
      httpStatus: response.status,
      code: googleError.code,
      status: googleError.status,
      reason: googleError.reason,
      message: googleError.message,
    }));
    if (response.status === 429 || googleError.status === "RESOURCE_EXHAUSTED") {
      throw new RequestError(429, "GOOGLE_RATE_LIMITED", "Google Places is temporarily rate limited.");
    }
    if (response.status === 403 || googleError.status === "PERMISSION_DENIED") {
      const issue = classifyGooglePermissionIssue(googleError.reason, googleError.message);
      throw new RequestError(502, issue.code, issue.message);
    }
    if (response.status === 400 || googleError.status === "INVALID_ARGUMENT") {
      throw new RequestError(502, "GOOGLE_INVALID_REQUEST", "Google Places rejected the request format.");
    }
    throw new RequestError(502, "GOOGLE_API_ERROR", "Google Places could not complete the request.");
  }
  return (await response.json()) as T;
}

async function readGoogleError(response: Response): Promise<{ code: number; status: string; reason: string; message: string }> {
  try {
    const payload = await response.json() as {
      error?: {
        code?: number;
        status?: string;
        message?: string;
        details?: Array<{ reason?: string }>;
      };
    };
    return {
      code: payload.error?.code ?? response.status,
      status: payload.error?.status ?? "UNKNOWN",
      reason: payload.error?.details?.find((detail) => detail.reason)?.reason ?? "UNKNOWN",
      message: payload.error?.message ?? "Google Places request failed.",
    };
  } catch {
    return { code: response.status, status: "UNKNOWN", reason: "UNKNOWN", message: "Google Places request failed." };
  }
}

function classifyGooglePermissionIssue(reason: string, message: string): { code: string; message: string } {
  const normalizedReason = reason.toUpperCase();
  const normalized = message.toLowerCase();
  if (normalizedReason === "SERVICE_DISABLED" || normalized.includes("has not been used") || normalized.includes("is disabled")) {
    return { code: "GOOGLE_API_NOT_ENABLED", message: "Enable Places API (New) for the server key's Google Cloud project." };
  }
  if (normalizedReason === "BILLING_DISABLED" || normalized.includes("billing")) {
    return { code: "GOOGLE_BILLING_REQUIRED", message: "Enable billing for the server key's Google Cloud project." };
  }
  if (normalizedReason === "API_KEY_INVALID" || normalized.includes("api key not valid") || normalized.includes("invalid api key")) {
    return { code: "GOOGLE_INVALID_KEY", message: "The configured Google Places server key is invalid." };
  }
  if (
    normalizedReason.includes("API_KEY_") ||
    normalized.includes("referer") ||
    normalized.includes("ip address") ||
    normalized.includes("not authorized") ||
    normalized.includes("application restriction")
  ) {
    return {
      code: "GOOGLE_KEY_RESTRICTED",
      message: "Remove mobile, website, or IP application restrictions from the Google Places server key.",
    };
  }
  return {
    code: "GOOGLE_PERMISSION_DENIED",
    message: "Google Places rejected the server key. Check Places API (New), billing, and API restrictions.",
  };
}

function adminClient() {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) throw new RequestError(500, "SERVER_CONFIGURATION_ERROR", "Server access is unavailable.");
  return createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
}

function requiredString(value: unknown, field: string, minimum: number, maximum: number): string {
  if (typeof value !== "string") throw new RequestError(400, "INVALID_INPUT", `${field} must be text.`);
  const normalized = value.trim();
  if (normalized.length < minimum || normalized.length > maximum) {
    throw new RequestError(400, "INVALID_INPUT", `${field} must be ${minimum}-${maximum} characters.`);
  }
  return normalized;
}

function requiredNumber(value: unknown, field: string, minimum: number, maximum: number): number {
  if (typeof value !== "number" || !Number.isFinite(value) || value < minimum || value > maximum) {
    throw new RequestError(400, "INVALID_INPUT", `${field} must be between ${minimum} and ${maximum}.`);
  }
  return value;
}

function isInKorea(latitude?: number, longitude?: number): boolean {
  return latitude !== undefined && longitude !== undefined &&
    latitude >= koreaViewport.low.latitude && latitude <= koreaViewport.high.latitude &&
    longitude >= koreaViewport.low.longitude && longitude <= koreaViewport.high.longitude;
}

function isSouthKoreanPlace(place: GooglePlace): boolean {
  const country = place.addressComponents?.find((component) => component.types?.includes("country"));
  return country?.shortText === "KR" || country?.longText === "South Korea" || country?.longText === "대한민국";
}

function formatType(value?: string): string {
  if (!value) return "Food place";
  return value
    .split("_")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}
