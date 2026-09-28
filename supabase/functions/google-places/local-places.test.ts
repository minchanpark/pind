import { strict as assert } from "node:assert";
import { test } from "node:test";
import {
  configuredProviders,
  googleFirstSearch,
  LocalPlacesError,
  normalizeKakao,
  normalizeNaver,
  searchLocalPlaces,
} from "./local-places.ts";

const kakao = {
  id: "123",
  place_name: "검증용 카페",
  category_group_code: "CE7",
  category_name: "카페",
  road_address_name: "서울 테스트로 1",
  x: "127.01",
  y: "37.51",
};
const naver = {
  title: "<b>검증용</b> 카페 &amp; 빵",
  category: "카페,디저트>카페",
  roadAddress: "서울 테스트로 1",
  mapx: "1270100000",
  mapy: "375100000",
};
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status });

test("Google results do not invoke supplemental providers", async () => {
  const result = await googleFirstSearch(async () => ["google"], async () => {
    throw new Error("must not call");
  }, true);
  assert.deepEqual(result.places, ["google"]);
});
test("empty Google results invoke opted-in fallback only", async () => {
  let calls = 0;
  const fallback = async () => {
    calls++;
    return { places: [normalizeKakao(kakao)!] };
  };
  assert.equal(
    (await googleFirstSearch(async () => [], fallback, true)).places.length,
    1,
  );
  assert.equal(
    (await googleFirstSearch(async () => [], fallback, false)).places.length,
    0,
  );
  assert.equal(calls, 1);
});
test("Google errors propagate without fallback", async () => {
  await assert.rejects(
    googleFirstSearch(async () => {
      throw new Error("Google 429");
    }, async () => {
      assert.fail("fallback on error");
    }, true),
    /Google 429/,
  );
});
test("provider configuration is disabled by default and bounded", () => {
  assert.deepEqual(configuredProviders(undefined), []);
  assert.deepEqual(configuredProviders("naver,kakao,kakao,unknown"), [
    "kakao",
    "naver",
  ]);
});
test("basic payload never claims photos, descriptions, hours or open status", () => {
  const place = normalizeKakao({
    ...kakao,
    isOpenNow: true,
    editorialSummary: "not trusted",
    heroImageUrl: "not trusted",
  })!;
  assert.equal(place.provider, "kakao_local");
  assert.equal(place.sourceUri, "https://place.map.kakao.com/123");
  assert.equal(place.isOpenNow, null);
  assert.equal(place.editorialSummary, null);
  assert.equal(place.heroImageUrl, null);
  assert.deepEqual(place.weekdayDescriptions, []);
});
test("Naver strips result markup, normalizes coordinates, and does not use vendor website as map URL", () => {
  const place = normalizeNaver({ ...naver, link: "https://merchant.example" })!;
  assert.equal(place.name, "검증용 카페 & 빵");
  assert.equal(place.latitude, 37.51);
  assert.equal(place.longitude, 127.01);
  assert.match(place.externalPlaceId, /^result:/);
  assert.match(place.sourceUri, /^https:\/\/map.naver.com\/p\/search\//);
  assert.equal(
    normalizeNaver({ ...naver, mapx: "127.01", mapy: "37.51" })!.latitude,
    37.51,
  );
});
test("invalid, foreign, and non-food candidates are omitted", () => {
  assert.equal(normalizeKakao({ ...kakao, x: "139" }), null);
  assert.equal(normalizeKakao({ ...kakao, id: "../evil" }), null);
  assert.equal(normalizeKakao({ ...kakao, category_group_code: "HP8" }), null);
  assert.equal(normalizeNaver({ ...naver, mapy: "NaN" }), null);
  assert.equal(normalizeNaver({ ...naver, category: "병원" }), null);
});
test("no configured providers returns an explicit notice without network", async () => {
  const result = await searchLocalPlaces(
    "서울 카페",
    { providers: [] },
    async () => {
      assert.fail("network disabled");
    },
  );
  assert.deepEqual(result.places, []);
  assert.match(result.notice!, /연결되지/);
});
test("Kakao hit stops before Naver and sends key only as a header", async () => {
  let calls = 0;
  const result = await searchLocalPlaces("서울 카페", {
    providers: ["kakao", "naver"],
    kakaoKey: "fixture-key",
  }, async (url, init) => {
    calls++;
    assert.match(String(url), /^https:\/\/dapi.kakao.com\//);
    assert.doesNotMatch(String(url), /fixture-key/);
    assert.equal(
      (init!.headers as Record<string, string>).Authorization,
      "KakaoAK fixture-key",
    );
    return reply({ documents: [kakao, kakao] });
  });
  assert.equal(calls, 1);
  assert.equal(result.places.length, 1);
});
test("Kakao empty calls Naver API HUB at most once", async () => {
  let calls = 0;
  const result = await searchLocalPlaces("서울 카페", {
    providers: ["kakao", "naver"],
    kakaoKey: "fixture",
    naverClientId: "fixture-id",
    naverClientSecret: "fixture-secret",
  }, async (url, init) => {
    calls++;
    if (calls === 1) return reply({ documents: [] });
    assert.match(String(url), /^https:\/\/naverapihub.apigw.ntruss.com\//);
    assert.equal(
      (init!.headers as Record<string, string>)["X-NCP-APIGW-API-KEY-ID"],
      "fixture-id",
    );
    return reply({ items: [naver] });
  });
  assert.equal(calls, 2);
  assert.equal(result.places[0].provider, "naver_local");
});
test("missing credentials, 429, network and malformed responses are errors, not empty success", async () => {
  await assert.rejects(
    searchLocalPlaces("서울 카페", { providers: ["kakao"] }),
    (e: unknown) =>
      e instanceof LocalPlacesError && e.code === "LOCAL_PLACES_NOT_CONFIGURED",
  );
  for (const status of [403, 429, 500]) {
    let calls = 0;
    await assert.rejects(
      searchLocalPlaces("서울 카페", {
        providers: ["kakao", "naver"],
        kakaoKey: "fixture",
      }, async () => {
        calls++;
        return reply({}, status);
      }),
      LocalPlacesError,
    );
    assert.equal(calls, 1);
  }
  await assert.rejects(
    searchLocalPlaces("서울 카페", {
      providers: ["kakao"],
      kakaoKey: "fixture",
    }, async () => {
      throw new Error("timeout");
    }),
    LocalPlacesError,
  );
  await assert.rejects(
    searchLocalPlaces("서울 카페", {
      providers: ["kakao"],
      kakaoKey: "fixture",
    }, async () => reply({})),
    LocalPlacesError,
  );
});
