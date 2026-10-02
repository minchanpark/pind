// QA data around 성수역: five test authors each post once to eight real
// catalog restaurants (40 posts, 1–4 photos each), through the app's own
// path: sign in, upload to post-media-v2, publish_post_v3.
//
//   env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
//   node scripts/seed_seoul_qa.mjs <places.json> <photo.jpg>...   seed (rerun-safe)
//   node scripts/seed_seoul_qa.mjs --remove                        delete it all
//
// Everything hangs off the qa*@pind.test accounts: deleting them cascades to
// their posts, ratings and media rows, and the counters follow by trigger.
import { createHash, randomBytes } from 'node:crypto';
import { readFileSync } from 'node:fs';

const url = process.env.SUPABASE_URL, anon = process.env.SUPABASE_ANON_KEY;
const service = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !anon || !service) throw new Error('SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are required');
const BUCKET = 'post-media-v2';

// Between them the priorities cover every criterion, so any viewer's taste
// match has all three averages.
export const AUTHORS = [
  {handle: 'qa_haram', name: '하람', priorities: ['ambience', 'value', 'photogenic']},
  {handle: 'qa_jiwoo', name: '지우', priorities: ['taste', 'ambience', 'value']},
  {handle: 'qa_seoyeon', name: '서연', priorities: ['value', 'photogenic', 'portion']},
  {handle: 'qa_dohyun', name: '도현', priorities: ['taste', 'portion', 'service']},
  {handle: 'qa_yuna', name: '유나', priorities: ['photogenic', 'quiet', 'parking']},
];

/// One line per author, keyed by a word in the place's category.
export const BODIES = {
  카페: ['창가 자리가 예뻐서 사진이 잘 나와요', '라떼가 고소하고 디저트도 맛있어요', '조용해서 작업하기 좋아요', '주말엔 웨이팅이 조금 있어요', '원두를 고를 수 있어서 좋았어요',
    '루프탑에서 보는 노을이 예뻐요', '핸드드립이 산미 있고 깔끔해요', '콘센트 많아서 노트북 하기 편해요', '쿠키가 꾸덕하고 커피랑 잘 어울려요', '인테리어가 감성적이라 데이트하기 좋아요',
    '아인슈페너 크림이 진하고 달지 않아요', '좌석 간격이 넓어서 대화하기 좋아요', '시그니처 음료가 독특하고 맛있어요', '반려견 동반 가능해서 좋았어요', '가격은 조금 있지만 분위기 값 해요'],
  백반: ['집밥 느낌 그대로, 반찬이 계속 바뀌어요', '가격 대비 양이 정말 많아요', '된장찌개가 진하고 맛있어요', '점심시간엔 회전이 빨라요', '혼밥하기 편한 자리 많아요'],
  주점: ['혼술 하기 딱 좋은 바 자리가 있어요', '안주가 다 맛있고 하이볼이 진해요', '분위기 좋고 음악 선곡이 좋아요', '2차로 오기 좋은 곳', '이자카야 느낌의 꼬치가 맛있어요'],
  돼지고기: ['고기를 직접 구워줘서 편해요', '삼겹살 두께가 두툼하고 육즙이 많아요', '된장찌개 서비스가 감동', '회식하기 좋은 넓은 자리', '한국 BBQ 제대로 즐길 수 있어요'],
  국수: ['칼국수 국물이 시원하고 면이 쫄깃해요', '양이 많아서 배불러요', '김치가 맛있어서 계속 리필했어요', '비 오는 날 생각나는 맛', '만두도 같이 꼭 드세요'],
  빵: ['소금빵이 바삭하고 버터향이 좋아요', '오픈 직후에 가야 다 있어요', '포장이 예뻐서 선물하기 좋아요', '크루아상 결이 살아있어요', '가격이 착한 편이에요'],
  초밥: ['네타가 두툼하고 신선해요', '런치 코스 가성비 최고', '카운터석에서 셰프님이 설명해줘요', '조용해서 대화하기 좋아요', '데이트 코스로 추천해요'],
  베트남: ['쌀국수 국물이 깊고 고수 추가 가능해요', '분짜가 새콤달콤 맛있어요', '현지 느낌 나는 인테리어', '양이 넉넉하고 가격도 괜찮아요', '반미가 바삭해서 좋았어요'],
};
/// Author [i]'s line at place [p]; places of one kind rotate through the list.
const bodyFor = (category, p, i) => {
  const lines = Object.entries(BODIES).find(([k]) => category.includes(k))?.[1] ?? BODIES.백반;
  return lines[(p * AUTHORS.length + i) % lines.length];
};

/// Stable per (author, place), so a rerun finds the same post.
export function requestId(handle, placeId) {
  const h = createHash('sha256').update(`pind-qa:${handle}:${placeId}`).digest('hex');
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-4${h.slice(13, 16)}-8${h.slice(17, 20)}-${h.slice(20, 32)}`;
}

/// 3–5, varied by place and author.
export const rating = (placeIndex, authorIndex, k) => 3 + ((placeIndex * 7 + authorIndex * 3 + k * 5) % 3);

async function call(path, {method = 'GET', key = service, token = key, body, headers = {}} = {}) {
  const response = await fetch(`${url}${path}`, {
    method,
    headers: {apikey: key, Authorization: `Bearer ${token}`,
      ...(body && !(body instanceof Uint8Array) ? {'Content-Type': 'application/json'} : {}), ...headers},
    body: body instanceof Uint8Array ? body : body && JSON.stringify(body),
  });
  const text = await response.text();
  if (!response.ok) throw new Error(`${method} ${path.split('?')[0]} → ${response.status} ${text.slice(0, 200)}`);
  return text ? JSON.parse(text) : null;
}

const email = a => `${a.handle}@pind.test`;

async function qaUsers() {
  const {users} = await call('/auth/v1/admin/users?per_page=1000');
  return users.filter(u => u.email?.endsWith('@pind.test'));
}

async function remove() {
  for (const user of await qaUsers()) {
    const objects = await call(`/storage/v1/object/list/${BUCKET}`, {method: 'POST',
      body: {prefix: `${user.id}/`, limit: 1000}});
    // Two levels deep: <uid>/<request>/<attempt>/<n>.jpg
    const paths = [];
    for (const req of objects) {
      for (const attempt of await call(`/storage/v1/object/list/${BUCKET}`, {method: 'POST', body: {prefix: `${user.id}/${req.name}/`, limit: 1000}})) {
        for (const file of await call(`/storage/v1/object/list/${BUCKET}`, {method: 'POST', body: {prefix: `${user.id}/${req.name}/${attempt.name}/`, limit: 1000}})) {
          paths.push(`${user.id}/${req.name}/${attempt.name}/${file.name}`);
        }
      }
    }
    if (paths.length) await call(`/storage/v1/object/${BUCKET}`, {method: 'DELETE', body: {prefixes: paths}});
    await call(`/auth/v1/admin/users/${user.id}`, {method: 'DELETE'});
    console.log(`removed ${user.email}: ${paths.length} photos`);
  }
}

async function seed(places, photos) {
  const existing = new Map((await qaUsers()).map(u => [u.email, u]));
  // A fresh password each run; nobody signs in as these by hand.
  const password = randomBytes(18).toString('base64url');
  let posted = 0;
  for (const [a, author] of AUTHORS.entries()) {
    let user = existing.get(email(author));
    if (user) await call(`/auth/v1/admin/users/${user.id}`, {method: 'PUT', body: {password}});
    else user = await call('/auth/v1/admin/users', {method: 'POST', body: {email: email(author), password, email_confirm: true}});
    await call(`/rest/v1/profiles?id=eq.${user.id}`, {method: 'PATCH',
      body: {display_name: author.name, handle: author.handle, bio: 'Pind QA 테스트 계정'}});
    await call('/rest/v1/taste_profiles', {method: 'POST', headers: {Prefer: 'resolution=merge-duplicates'},
      body: {user_id: user.id, priorities: author.priorities, discoverable: true}});
    const {access_token: token} = await call('/auth/v1/token?grant_type=password', {method: 'POST', key: anon,
      body: {email: email(author), password}});
    for (const [p, place] of places.entries()) {
      const request = requestId(author.handle, place.id);
      // 1, 2, 3, 4, 1… photos: every PostCard layout, including "+1".
      const count = ((p + a) % 4) + 1;
      const media = [];
      for (let n = 0; n < count; n++) {
        const bytes = photos[(p * 5 + a + n) % photos.length];
        const path = `${user.id}/${request}/seed/${n}.jpg`;
        await call(`/storage/v1/object/${BUCKET}/${path}`, {method: 'POST', key: anon, token, body: bytes,
          headers: {'Content-Type': 'image/jpeg', 'x-upsert': 'true'}});
        media.push({path, mime: 'image/jpeg', bytes: bytes.length});
      }
      await call('/rest/v1/rpc/publish_post_v3', {method: 'POST', key: anon, token, body: {
        p_client_request_id: request, p_place_id: place.id,
        p_ratings: Object.fromEntries(author.priorities.map((c, k) => [c, rating(p, a, k)])),
        p_body: bodyFor(place.category, p, a), p_media: media,
      }});
      posted++;
    }
    console.log(`${author.name} (@${author.handle}): ${places.length} posts`);
  }
  console.log(`${posted} posts on ${places.length} places`);
}

if (process.argv[2] === '--remove') await remove();
else if (process.argv[2]) {
  const places = JSON.parse(readFileSync(process.argv[2], 'utf8'));
  const photos = process.argv.slice(3).map(f => new Uint8Array(readFileSync(f)));
  if (!places.length || !photos.length) throw new Error('places.json and at least one photo are required');
  await seed(places, photos);
}
