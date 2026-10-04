export class CatalogError extends Error {
  readonly status: number;
  readonly code: string;
  constructor(status: number, code: string, message: string) { super(message); this.status=status; this.code=code; }
}
type Payload = Record<string, unknown>;
export async function catalogRequest(
  body: Payload,
  query: (args: Payload, fn?: string) => Promise<Payload>,
  photoUrls: (paths: string[], bucket: string) => Promise<(string | null)[]>,
  googleEnabled: boolean,
  refreshInsight: (placeId: number) => void = () => {},
  /// The insight in another app language; null keeps the Korean.
  translateInsight: (placeId: number, postCount: number, insight: Payload, lang: string) =>
    Promise<Payload | null> = async () => null,
): Promise<Payload> {
  const args: Payload = {};
  let fn = 'get_catalog_places';
  if (body.action === 'agent_search') {
    // index.ts fills terms from the sentence, and center/radius from its area.
    const list = (v: unknown) => Array.isArray(v) ? (v as unknown[]).filter(t => typeof t === 'string' && t.trim()) : [];
    const terms = list(body.terms), kinds = list(body.kinds);
    const byTaste = body.byTaste === true;
    if (!terms.length && !kinds.length && !byTaste) throw new CatalogError(400,'QUERY_NOT_UNDERSTOOD','검색어를 이해하지 못했어요. 다르게 말해 주세요.');
    const lat = body.latitude, lng = body.longitude;
    const near = typeof lat === 'number' && typeof lng === 'number' && lat >= 33 && lat <= 38.8 && lng >= 124.5 && lng <= 132;
    const radius = body.radiusMeters;
    const circle = near && typeof radius === 'number' && Number.isInteger(radius) && radius >= 100 && radius <= 50000;
    Object.assign(args,{p_terms:terms,p_lat:near ? lat : null,p_lng:near ? lng : null,
      ...(circle ? {p_radius:radius} : {}),...(kinds.length ? {p_kinds:kinds} : {}),
      ...(byTaste ? {p_by_taste:true} : {})});
    fn = 'agent_search_places';
  } else if (body.action === 'nearby') {
    const lat = body.latitude, lng = body.longitude, radius = body.radiusMeters;
    if (typeof lat !== 'number' || typeof lng !== 'number' || typeof radius !== 'number' ||
      !Number.isFinite(lat) || !Number.isFinite(lng) || !Number.isInteger(radius) ||
      lat < 33 || lat > 38.8 || lng < 124.5 || lng > 132 || radius < 100 || radius > 50000) {
      throw new CatalogError(400,'INVALID_VIEWPORT','대한민국 안에서 지도를 이동해 주세요.');
    }
    Object.assign(args,{p_lat:lat,p_lng:lng,p_radius:radius});
  } else if (body.action === 'posted') {
    // Every place with a published post; the map loads this once.
  } else if (body.action === 'search') {
    const q = typeof body.query === 'string' ? body.query.trim() : '';
    if (q.length < 2 || q.length > 120) throw new CatalogError(400,'INVALID_QUERY','검색어를 2~120자로 입력해 주세요.');
    args.p_query = q;
  } else if (body.action === 'catalog_detail') {
    if (!Number.isSafeInteger(body.internalPlaceId) || Number(body.internalPlaceId) < 1) {
      throw new CatalogError(400,'INVALID_PLACE','장소 ID를 확인해 주세요.');
    }
    args.p_place_id = body.internalPlaceId;
  } else {
    throw new CatalogError(400,'INVALID_ACTION','기본 장소 조회만 지원합니다.');
  }
  // Errors stay errors. This function has no Google/network fallback dependency.
  const result = await query(args, fn);
  const rows = ((result.places ?? []) as Payload[])
    .filter(p => (body.action !== 'nearby' && body.action !== 'posted') || (typeof p.pindPostCount === 'number' && p.pindPostCount > 0));
  // One signing call per bucket for the whole response, not one per place/post.
  const coverBucket = (p: Payload) => typeof p.pindPhotoBucket === 'string' ? p.pindPhotoBucket : 'post-media';
  const postPaths = (p: Payload) => Array.isArray(p.photos) ? p.photos as string[] : [];
  const wanted = new Map<string, Set<string>>();
  const want = (bucket: string, path: string) => wanted.set(bucket, (wanted.get(bucket) ?? new Set()).add(path));
  for (const p of rows) {
    if (!p.heroImageUrl && typeof p.pindPhotoPath === 'string') want(coverBucket(p), p.pindPhotoPath);
    for (const post of Array.isArray(p.pindPosts) ? p.pindPosts as Payload[] : []) {
      for (const path of postPaths(post)) want(String(post.bucket), path);
    }
  }
  const signed = new Map<string, string | null>();
  await Promise.all([...wanted].map(async ([bucket, set]) => {
    const paths = [...set], urls = await photoUrls(paths, bucket);
    paths.forEach((path, i) => signed.set(`${bucket}\n${path}`, urls[i] ?? null));
  }));
  const url = (bucket: string, path: string) => signed.get(`${bucket}\n${path}`) ?? null;
  const places = rows.map(p => {
    const place: Payload = {...p, googleSearchEnabled:googleEnabled};
    if (!place.heroImageUrl && typeof place.pindPhotoPath === 'string') {
      place.heroImageUrl = url(coverBucket(place), place.pindPhotoPath);
      place.photoAttributions = [{displayName:place.pindPhotoAuthor ?? 'Pind 사용자'}];
    }
    if (Array.isArray(place.pindPosts)) {
      // All photos are signed so the viewer can page through them.
      place.posts = (place.pindPosts as Payload[]).map(p => {
        const photos = postPaths(p).map(path => url(String(p.bucket), path));
        return {id:p.id,author:p.author,handle:p.handle,avatar:p.avatar,body:p.body,ratings:p.ratings,photos:photos.filter(Boolean),
          likeCount:p.likeCount ?? 0,liked:p.liked === true,mine:p.mine === true};
      });
      place.gallery = (place.posts as Payload[]).flatMap(p => (p.photos as string[]).map(uri =>
        ({uri,attributions:[{displayName:p.author ?? 'Pind 사용자'}]}))).slice(0,5);
    }
    if (body.action === 'catalog_detail') {
      const insight = place.insight as Payload | null | undefined;
      if (typeof place.pindPostCount === 'number' && place.pindPostCount > 0 && insight?.postCount !== place.pindPostCount) {
        refreshInsight(Number(place.internalId));
      }
      if (insight && typeof insight.postCount === 'number' && insight.postCount > 0) {
        place.insight = {summary:insight.summary, criteria:insight.criteria};
      } else delete place.insight;
    }
    delete place.pindPosts;
    delete place.pindPhotoPath;
    delete place.pindPhotoAuthor;
    delete place.pindPhotoBucket;
    return place;
  });
  if (body.action === 'catalog_detail') {
    if (!places.length) throw new CatalogError(404,'PLACE_NOT_FOUND','공개된 장소를 찾지 못했어요.');
    const place = places[0], lang = body.lang;
    if (place.insight && typeof lang === 'string' && ['en','ja','zh-Hans','zh-Hant'].includes(lang)) {
      const translated = await translateInsight(Number(place.internalId), Number(place.pindPostCount ?? 0),
        place.insight as Payload, lang).catch(() => null);
      if (translated) place.insight = translated;
    }
    return {place,googleSearchEnabled:googleEnabled};
  }
  if (body.action === 'agent_search') {
    // The app words the notice in its own language from label/personal;
    // notice stays for builds that predate that.
    return {places,googleSearchEnabled:googleEnabled,label:body.label ?? null,
      personal:body.personal === true,notice:`${body.label} 기준으로 찾았어요.`};
  }
  return {places,googleSearchEnabled:googleEnabled,
    notice:result.catalogReady === false ? '공공 장소 데이터를 준비 중이에요. 준비된 지역부터 표시됩니다.' : null};
}
