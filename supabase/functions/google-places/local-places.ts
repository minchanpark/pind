// Basic search only. No scraping, persistence, AI input, or photo enrichment.
export type LocalProvider = "kakao" | "naver";
export type LocalConfig = {
  providers: LocalProvider[];
  kakaoKey?: string;
  naverClientId?: string;
  naverClientSecret?: string;
};

export type BasicPlace = {
  provider: "kakao_local" | "naver_local";
  externalPlaceId: string;
  name: string;
  category: string;
  address: string;
  latitude: number;
  longitude: number;
  sourceUri: string;
  heroImageUrl: null;
  gallery: never[];
  editorialSummary: null;
  isOpenNow: null;
  weekdayDescriptions: never[];
};
export type LocalResult = { places: BasicPlace[]; notice?: string };

export class LocalPlacesError extends Error {
  status: number;
  code: string;
  constructor(status: number, code: string, message: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export function configuredProviders(raw: string | undefined): LocalProvider[] {
  const values = (raw ?? "").split(",").map((part) => part.trim());
  // A fixed order keeps one search bounded to at most two provider requests.
  return (["kakao", "naver"] as const).filter((provider) =>
    values.includes(provider)
  );
}

export async function googleFirstSearch<T>(
  google: () => Promise<T[]>,
  supplemental: () => Promise<LocalResult>,
  allowSupplemental: boolean,
): Promise<{ places: (T | BasicPlace)[]; notice?: string }> {
  const places = await google(); // Errors must never become an empty-result fallback.
  if (places.length || !allowSupplemental) return { places };
  return await supplemental();
}

export async function searchLocalPlaces(
  query: string,
  config: LocalConfig,
  fetcher: typeof fetch = fetch,
): Promise<LocalResult> {
  query = query.trim();
  if (query.length < 2 || query.length > 120) {
    throw new LocalPlacesError(
      400,
      "INVALID_QUERY",
      "검색어를 2~120자로 입력해 주세요.",
    );
  }
  if (!config.providers.length) {
    return {
      places: [],
      notice:
        "보완 검색이 아직 연결되지 않았어요. Google 검색을 이용해 주세요.",
    };
  }
  for (const provider of config.providers) {
    let places: BasicPlace[];
    if (provider === "kakao") {
      if (!config.kakaoKey) throw notConfigured("카카오");
      const url = new URL(
        "https://dapi.kakao.com/v2/local/search/keyword.json",
      );
      url.searchParams.set("query", query);
      url.searchParams.set("size", "15");
      const data = await fetchJson(url, {
        Authorization: `KakaoAK ${config.kakaoKey}`,
      }, fetcher);
      places = records(data.documents).flatMap((raw) => {
        const place = normalizeKakao(raw);
        return place ? [place] : [];
      });
    } else {
      if (!config.naverClientId || !config.naverClientSecret) {
        throw notConfigured("네이버");
      }
      const url = new URL(
        "https://naverapihub.apigw.ntruss.com/search/v1/local",
      );
      url.searchParams.set("query", query);
      url.searchParams.set("display", "5");
      url.searchParams.set("start", "1");
      url.searchParams.set("format", "json");
      const data = await fetchJson(url, {
        "X-NCP-APIGW-API-KEY-ID": config.naverClientId,
        "X-NCP-APIGW-API-KEY": config.naverClientSecret,
      }, fetcher);
      places = records(data.items).flatMap((raw) => {
        const place = normalizeNaver(raw);
        return place ? [place] : [];
      });
    }
    if (places.length) {
      const unique = new Map(places.map((p) => [p.externalPlaceId, p]));
      return {
        places: [...unique.values()],
        notice: "보완 검색 결과예요. 운영시간은 원본 지도에서 확인해 주세요.",
      };
    }
  }
  return {
    places: [],
    notice:
      "보완 검색에서도 장소를 찾지 못했어요. 지역명과 가게 이름을 함께 입력해 주세요.",
  };
}

function notConfigured(name: string): LocalPlacesError {
  return new LocalPlacesError(
    503,
    "LOCAL_PLACES_NOT_CONFIGURED",
    `${name} 보완 검색 연결이 필요해요.`,
  );
}

async function fetchJson(
  url: URL,
  headers: Record<string, string>,
  fetcher: typeof fetch,
) {
  let response: Response;
  try {
    response = await fetcher(url, {
      headers,
      signal: AbortSignal.timeout(8000),
    });
  } catch {
    throw new LocalPlacesError(
      502,
      "LOCAL_PLACES_UNAVAILABLE",
      "보완 검색 서버에 연결하지 못했어요. 다시 시도해 주세요.",
    );
  }
  if (!response.ok) {
    throw new LocalPlacesError(
      response.status === 429 ? 429 : 502,
      response.status === 429
        ? "LOCAL_PLACES_RATE_LIMITED"
        : "LOCAL_PLACES_UNAVAILABLE",
      response.status === 429
        ? "보완 검색 한도에 도달했어요. 잠시 후 다시 시도해 주세요."
        : "보완 검색을 불러오지 못했어요.",
    );
  }
  try {
    const data = await response.json();
    if (!data || typeof data !== "object" || Array.isArray(data)) {
      throw new Error("Invalid response");
    }
    return data as Record<string, unknown>;
  } catch {
    throw invalidResponse();
  }
}

function invalidResponse() {
  return new LocalPlacesError(
    502,
    "LOCAL_PLACES_INVALID_RESPONSE",
    "보완 검색 응답을 확인하지 못했어요.",
  );
}

function records(value: unknown): Record<string, unknown>[] {
  if (!Array.isArray(value)) throw invalidResponse();
  return value.filter((item) =>
    item && typeof item === "object" && !Array.isArray(item)
  );
}

function text(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function coordinates(latitude: number, longitude: number): boolean {
  return Number.isFinite(latitude) && Number.isFinite(longitude) &&
    latitude >= 33 && latitude <= 38.8 && longitude >= 124.5 &&
    longitude <= 132;
}

function basic(
  provider: BasicPlace["provider"],
  externalPlaceId: string,
  name: string,
  category: string,
  address: string,
  latitude: number,
  longitude: number,
  sourceUri: string,
): BasicPlace | null {
  if (!name || !address || !coordinates(latitude, longitude)) return null;
  return {
    provider,
    externalPlaceId,
    name,
    category,
    address,
    latitude,
    longitude,
    sourceUri,
    heroImageUrl: null,
    gallery: [],
    editorialSummary: null,
    isOpenNow: null,
    weekdayDescriptions: [],
  };
}

export function normalizeKakao(
  raw: Record<string, unknown>,
): BasicPlace | null {
  const id = text(raw.id);
  if (
    !/^\d+$/.test(id) || !["FD6", "CE7"].includes(text(raw.category_group_code))
  ) return null;
  return basic(
    "kakao_local",
    id,
    text(raw.place_name),
    text(raw.category_name),
    text(raw.road_address_name) || text(raw.address_name),
    Number(raw.y),
    Number(raw.x),
    `https://place.map.kakao.com/${id}`,
  );
}

function plainText(value: unknown): string {
  return text(value).replace(/<[^>]*>/g, "").replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&nbsp;/g, " ")
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">").trim();
}

export function normalizeNaver(
  raw: Record<string, unknown>,
): BasicPlace | null {
  const name = plainText(raw.title);
  const address = text(raw.roadAddress) || text(raw.address);
  const category = text(raw.category);
  if (
    !/음식|식당|카페|커피|주점|술집|베이커리|제과|디저트|분식|찻집|restaurant|cafe|bakery|bar/i
      .test(category)
  ) return null;
  let latitude = Number(raw.mapy), longitude = Number(raw.mapx);
  // Support both decimal WGS84 and the legacy 10^7-scaled representation.
  if (Math.abs(latitude) > 90) latitude /= 1e7;
  if (Math.abs(longitude) > 180) longitude /= 1e7;
  const fingerprint = JSON.stringify([name, address, latitude, longitude]);
  return basic(
    "naver_local",
    `result:${fingerprint}`,
    name,
    category,
    address,
    latitude,
    longitude,
    `https://map.naver.com/p/search/${
      encodeURIComponent(`${name} ${address}`)
    }`,
  );
}
