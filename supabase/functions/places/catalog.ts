export class CatalogError extends Error {
  readonly status: number;
  readonly code: string;
  constructor(status: number, code: string, message: string) { super(message); this.status=status; this.code=code; }
}
type Payload = Record<string, unknown>;
export async function catalogRequest(
  body: Payload,
  query: (args: Payload) => Promise<Payload>,
  photoUrls: (paths: string[], bucket: string) => Promise<(string | null)[]>,
  googleEnabled: boolean,
  refreshInsight: (placeId: number) => void = () => {},
): Promise<Payload> {
  const args: Payload = {};
  if (body.action === 'nearby') {
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
  const result = await query(args);
  const places = await Promise.all(((result.places ?? []) as Payload[])
    .filter(p => (body.action !== 'nearby' && body.action !== 'posted') || (typeof p.pindPostCount === 'number' && p.pindPostCount > 0))
    .map(async p => {
    const place: Payload = {...p, googleSearchEnabled:googleEnabled};
    if (!place.heroImageUrl && typeof place.pindPhotoPath === 'string') {
      [place.heroImageUrl] = await photoUrls([place.pindPhotoPath], typeof place.pindPhotoBucket === 'string' ? place.pindPhotoBucket : 'post-media');
      place.photoAttributions = [{displayName:place.pindPhotoAuthor ?? 'Pind 사용자'}];
    }
    if (Array.isArray(place.pindPosts)) {
      // All photos are signed (one batch per post) so the viewer can page through them.
      place.posts = await Promise.all((place.pindPosts as Payload[]).map(async p => {
        const paths = Array.isArray(p.photos) ? p.photos as string[] : [];
        const photos = paths.length ? await photoUrls(paths,String(p.bucket)) : [];
        return {id:p.id,author:p.author,avatar:p.avatar,body:p.body,ratings:p.ratings,photos:photos.filter(Boolean)};
      }));
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
  }));
  if (body.action === 'catalog_detail') {
    if (!places.length) throw new CatalogError(404,'PLACE_NOT_FOUND','공개된 장소를 찾지 못했어요.');
    return {place:places[0],googleSearchEnabled:googleEnabled};
  }
  return {places,googleSearchEnabled:googleEnabled,
    notice:result.catalogReady === false ? '공공 장소 데이터를 준비 중이에요. 준비된 지역부터 표시됩니다.' : null};
}
