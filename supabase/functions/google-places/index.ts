import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.112.3";
import { explicitGoogleAction, dailyLimit } from "./policy.ts";
type GoogleAccess = { key: string; userId: string };

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
  currentOpeningHours?: { openNow?: boolean; weekdayDescriptions?: string[] };
  userRatingCount?: number;
  utcOffsetMinutes?: number;
  nationalPhoneNumber?: string;
  editorialSummary?: { text?: string; languageCode?: string };
};

type PlacePayload = {
  provider: "google_places";
  sourceUri: string;
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
  userRatingCount: number | null;
  utcOffsetMinutes: number | null;
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
    const userId = await requireUser(request);
    const body = await readBody(request);
    if (!explicitGoogleAction(body)) {
      throw new RequestError(400, "EXPLICIT_GOOGLE_ONLY", "Google 추가 검색이나 선택한 상세 요청만 허용합니다.");
    }
    const key = Deno.env.get("GOOGLE_PLACES_API_KEY");
    if (!key || Deno.env.get("GOOGLE_FALLBACK_ENABLED") === "false") {
      throw new RequestError(503, "GOOGLE_DISABLED", "Google 추가 정보를 현재 사용할 수 없어요.");
    }
    const access: GoogleAccess = {key, userId};
    if (body.action === "google_search") {
      return json({places: await searchGooglePlaces(body,access),googleSearchEnabled:true});
    }
    if (body.action === "resolve") return await resolvePlace(body,access);
    return await placeDetail(body,access);
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
  return data.user.id;
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

async function searchGooglePlaces(body: Record<string, unknown>, apiKey: GoogleAccess): Promise<PlacePayload[]> {
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
  const candidates = await Promise.all(foodPlaces.slice(0, 8).map((place) => normalizePlace(place, apiKey, 0)));
  return candidates.flatMap((place) => (place ? [place] : []));
}

async function resolvePlace(body: Record<string, unknown>, apiKey: GoogleAccess) {
  const externalPlaceId = requiredString(body.externalPlaceId, "externalPlaceId", 8, 255);
  const place = await getPlace(externalPlaceId, apiKey);
  const normalized = await normalizePlace(place, apiKey, 0);
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

async function placeDetail(body: Record<string, unknown>, apiKey: GoogleAccess) {
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
  const normalized = await normalizePlace(place, apiKey, 1);
  if (!normalized) throw new RequestError(404, "PLACE_NOT_FOUND", "Google did not return this place.");
  return json({ place: { ...normalized, internalId: Number(data.id) } });
}

async function getPlace(externalPlaceId: string, apiKey: GoogleAccess, extended = false): Promise<GooglePlace> {
  return await googleFetch<GooglePlace>(
    `${googleApiBase}/places/${encodeURIComponent(externalPlaceId)}?languageCode=ko&regionCode=KR`,
    apiKey,
    {
      headers: {
        "X-Goog-FieldMask": [
          basePlaceFields(),
          ...(extended
            ? ["photos", "regularOpeningHours", "currentOpeningHours", "userRatingCount", "utcOffsetMinutes", "editorialSummary"]
            : []),
        ].join(","),
      },
    },
  );
}

async function normalizePlace(place: GooglePlace, apiKey: GoogleAccess, photoLimit: number): Promise<PlacePayload | null> {
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
    provider: "google_places",
    sourceUri: googleMapsUri,
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
    isOpenNow: (place.currentOpeningHours ?? place.regularOpeningHours)?.openNow ?? null,
    weekdayDescriptions: (place.currentOpeningHours ?? place.regularOpeningHours)?.weekdayDescriptions ?? [],
    userRatingCount: place.userRatingCount ?? null,
    utcOffsetMinutes: place.utcOffsetMinutes ?? null,
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
    "businessStatus",
  ].map((field) => `${prefix}${field}`).join(",");
}

async function getPhotoUri(photoName: string, apiKey: GoogleAccess): Promise<string | null> {
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

async function googleFetch<T>(url: string, apiKey: GoogleAccess, init: RequestInit): Promise<T> {
  const { error: budgetError } = await adminClient().rpc("take_place_google_budget", {
    p_user_id: apiKey.userId,
    p_user_limit: dailyLimit(Deno.env.get("GOOGLE_USER_DAILY_REQUESTS"),20),
    p_total_limit: dailyLimit(Deno.env.get("GOOGLE_TOTAL_DAILY_REQUESTS"),1000),
  });
  if (budgetError) {
    const limited = /GOOGLE_(DAILY_LIMIT|USER_LIMIT|BUDGET_DISABLED)/.test(budgetError.message);
    throw new RequestError(limited ? 429 : 503, limited ? "GOOGLE_BUDGET_LIMIT" : "GOOGLE_BUDGET_UNAVAILABLE",
      limited ? "오늘의 Google 추가 조회 한도에 도달했어요. 기본 장소 정보는 계속 사용할 수 있어요."
        : "조회량 제한을 확인하지 못해 Google 요청을 중단했어요.");
  }
  const headers = new Headers(init.headers);
  headers.set("X-Goog-Api-Key", apiKey.key);
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
