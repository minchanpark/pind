# Flutter / Supabase 구현 설계

2026-09-26. 기준: [PRD v3](prd.md), [Figma 화면 목록](figma-screen-map.md), 기존 소스와 7개 migration. 이번 요청에 따라 설계 후 P0 개발을 시작한다. 별도 Strict DDD 잠금/승인 체계는 도입하지 않으며 사용자 승인 기록을 만들어내지 않는다.

## 1. 현재 프로젝트 전환

| 자산 | 처리 |
| --- | --- |
| mobile/ Expo 57·React Native·TS | 2026-09-26 사용자 요청으로 프로젝트에서 제거; 프로젝트 밖 복구용 백업 보존 |
| posts.ts 미커밋 변경, .serena/ | posts.ts는 외부 백업에 포함, .serena/ 사용자 변경 보존 |
| Supabase migration/ID/글/사진/친구 | 재사용, reset/기존 이력 재작성 없음 |
| google-places Edge Function | search/nearby/resolve/detail/details 재사용 |
| Auth/RLS/Storage | 계약 유지 후 추가 migration으로 확장 |
| TS 지도 범위 규칙 | 순수 Dart로 포팅·경계값 테스트 |
| 기존 매칭 42점 기본/98점 상한 | 새 3축 모델에서 폐기; 데이터 없으면 NULL |
| 앱 화면/내비게이션/권한/업로드 | Flutter에서 새 구현 |

기존 문서의 개발 Supabase ref는 mkfgqobwededpzdekvxg. 현재 관리 MCP는 permission denied여서 원격 스키마/설정을 직접 확인하지 못했다. 로컬 migration을 원격 적용 완료로 간주하지 않는다. 클라이언트 API 연결 가능 여부를 별도로 검증한다.

## 2. 앱 구조와 경로

`lib`는 `model`, `view`, `controllers`, `services`로 구성한다. `model`은 데이터 정의·검증·점수 계산과 ChangeNotifier 상태, `view`는 화면·위젯·테마, `controllers`는 화면 이벤트와 조회·저장 흐름, `services`는 Supabase·기기 저장소·위치·외부 앱 접근을 담당한다. `main.dart`는 설정·초기화·의존성 연결, `view/app.dart`는 앱 화면 구성을 맡는다. 상세 구조와 수명 관리는 [MVC 아키텍처](architecture.md)를 따른다. `assets/<화면>/`은 화면별 정적 자산([목록](../assets/README.md)), `test`는 모델·서비스·컨트롤러·위젯, `integration_test`는 실제 여정이다.

상태 알림은 model의 ChangeNotifier, 의존성 연결은 생성자 주입을 사용한다. API 호출은 services, 데이터 규칙은 model, 요청 순서·에러 처리·저장 흐름은 controllers로 분리한다. DI 컨테이너·코드 생성·별도 BFF는 추가하지 않는다. P0은 Navigator, 로그인/딥링크 P1에서 go_router를 도입한다.

| 경로 | 역할 |
| --- | --- |
| /auth, /setup | 공급자 로그인, 미완료 계정 설정 복원 |
| /onboarding | 위치/선택/상황/음식, 뒤로 가기 선택 유지 |
| /discover?mode=community\|friends | 피드/스크롤/모드 보존 |
| /map | 기본 탭, 카메라/출처/카테고리 보존 |
| /places/:id | 상세 시트/직접 링크, 호출 탭으로 복귀 |
| /posts/new?placeId=..., /posts/:id | 작성·보기·수정, draft 보존 |
| /me?tab=map\|saved\|posts, /saved | 프로필/저장 |
| /invite/:token | 로그인 후 초대 목적 경로 재개 |

작성 아이콘은 현재 탭 위 composer를 연다. back은 시트→검색→현재 탭 순. PindTheme, SelectionCard, PrimaryButton, PhotoChoice, FloatingNavigation, PlacePin, PlaceCard, RatingTriplet, PlaceSheet, PostPhotoStack 공유. OS 한글 fallback 사용 후 배포 권한 있는 지정 글꼴 확보 시 번들한다.

지도는 실제 SDK, 사진 PIN은 bitmap+원형 테두리, 실패 시 카테고리 표시. 수량/클러스터는 실기기 측정으로 결정. BackdropFilter는 필요한 시트/메뉴만 적용. 구현 전 기능을 동작 가능한 메뉴처럼 노출하지 않는다.

## 3. 기존 API 계약

### 2026-09-28 온보딩 — 구현 단위 O1

일반 앱을 로그인 → 국가 → 기본 정보 → 닉네임/아이디 → 위치 → 우선순위 → 외식 선호도 → 음식 선택으로 연결한다. 앞의 다섯 화면은 Figma `531:18341`, `531:18621`, `531:20155`, `531:18681`, `531:18369`를 기준으로 하고 기존 취향 세 화면을 재사용한다.

`RegistrationModel`이 draft/단계/검증 상태를 정의하고 `RegistrationController`가 `AuthService`, `RegistrationService`, `LocationService`를 연결한다. Supabase OAuth 호출과 인증 상태 구독을 구현하되, OAuth 실행 자체를 로그인 성공으로 판단하지 않는다. 가입 정보와 완료 표시는 계정별 기기 draft이며 현재 서버 계약을 대체하지 않는다. 서버 프로필/아이디 중복/동의와 공급자 콘솔 설정의 남은 연결, 검증 방법은 [온보딩 안내](onboarding.md)를 따른다.

### 2026-09-26 내비게이션 재설계 — 구현 단위 N1

1. `view/navigation/pind_navigation_bar.dart`: Figma `531:17799`(지도), `531:19123`(Discover), `531:20050`(마이페이지) 상태를 공통 위젯으로 구현. 아이콘은 `assets/navigation/`의 SVG 4개(비선택 회색 원본)를 원본 크기로 쓰며, 선택된 탭만 검정으로 틴트한다. Material 아이콘으로 대체하지 않는다. 273×58 / radius 29 / blur 12 / rgba(244,245,248,.62) / 흰 테두리 .95 / shadow 0,4,18,.06. 아이콘 프레임은 30.0458, 좌측 좌표 35 / 87.0458 / 145.9541 / 209, 상단 14. 터치 영역만 44로 확장한다.
2. `view/navigation/main_shell.dart`: 지도 기본 선택. `IndexedStack`으로 3개 목적지 상태를 유지하고 `TickerMode`로 비활성 탭 애니메이션을 멈춘다. 작성은 `MaterialPageRoute(fullscreenDialog: true)`이며 선택 탭을 바꾸지 않는다. 작성/상세는 루트 Navigator 위로 열린다. 미구현 목적지는 명시적 안내만 제공한다.
3. 기기 safe area와 디자인 차이: Figma 402×874 기준 하단 여백 23. 실제 기기에서는 `max(23, viewPadding.bottom)`으로 홈 인디케이터를 피한다. 폭은 273 유지. 키보드가 있으면 바를 숨긴다.
4. 기존 지도 하단 카테고리·목록 버튼을 내비게이션 위로 올리고 Google 로고 영역도 함께 조정한다. 지도 자체 디자인·키 문제는 이번 변경 범위에서 다시 구현하지 않는다. 숨겨진 지도에서 cameraIdle 자동 요청을 막아 탭 전환이 새 조회를 유발하지 않도록 한다.
5. `PindApp`: 취향 수정은 별도 route로 열어 Shell을 제거하지 않는다. 완료/취소 후 이전 탭·지도 상태를 보존한다. 기존 최초 온보딩과 저장 계약은 그대로 사용한다.
6. 검증: 402/320 폭, 200% 글씨, 홈 인디케이터·키보드, 검정 선택 상태, 각 아이콘 root 크기/슬롯, 44pt 터치, 탭 상태 보존, 작성 중복 방지/닫기, 뒤로 가기, 실제 iOS 화면. 기능 데이터가 없는 목적지는 완성됐다고 보고하지 않는다.

후속 순서: N2 지도 검색/출처 필터/카테고리 배치 → N3 장소 상세 → N4 작성 → N5 Discover → N6 마이페이지. 각 단위별로 Figma를 다시 읽고 구현·검증한다.

### 현재 적용: 2026-09-27 공공/Pind 우선

기본 지도·검색·공공 상세는 새 `places` Edge Function → 인증된 사용자 RPC/RLS로 조회한다. Google은 명시적 추가 검색/선택한 상세에만 사용하며 일일 호출 한도를 적용한다. 상세 설계·공공 CSV 수입·출처·ID 유지·검증 범위는 [공공/Pind 우선 설계](public-first-places.md)를 따른다. iOS 번들 ID는 `com.newdawn.pind`, Android 앱 ID는 `com.pind.app`이다.

### 이전 설계: 2026-09-26 장소 공급자 보완 (현재 자동 경로에서 비활성)

아래는 이전 결정 기록이다. Google 우선/빈 결과 자동 보완 및 사진 Google 전용 제한은 위 새 설계로 대체한다.

- Flutter/Google Maps/Supabase 및 `google-places` 함수 이름을 유지한다. Flutter 검색은 `allowSupplemental: true`로 새 동작을 요청한다. 구형 API 클라이언트에는 Google 응답 하위 호환성을 유지한다.
- `search`: Google 정상 결과 우선. 0개일 때만 활성화된 카카오 → 네이버 순으로 조회한다. `supplemental`: 사용자가 추가 검색을 요청한 경우 Google 재호출 없이 같은 순서로 보완한다. 공급자 오류는 빈 결과로 치환하지 않는다.
- 응답에 `provider` (`google_places`, `kakao_local`, `naver_local`)와 `sourceUri`를 추가한다. 기존 Google 응답 필드는 하위 호환성을 유지한다. 클라이언트의 키는 `provider:externalPlaceId`이며 공급자 간 자동 병합은 하지 않는다.
- 검색 응답의 `supplementalSearchEnabled`가 true일 때만 추가 검색 버튼을 노출한다. 미배포 구형 함수 또는 비활성 서버에 지원하지 않는 action을 호출하지 않는다.
- 카카오의 실제 장소 ID와 달리 네이버 지역 검색에는 안정적인 장소 ID가 없다. 네이버 식별자는 이름/주소/좌표 기반의 응답 내 식별용 fingerprint이며 영구 저장/게시물 외래키로 쓰지 않는다. 원본은 네이버 지도 검색 링크이며 업체 웹사이트를 네이버 상세 페이지로 오인하지 않는다.
- 보완 응답은 사진·설명·운영시간·영업 여부를 항상 비워둔다. Flutter는 보완 상세에 Google resolve/detail을 호출하지 않고 ‘운영시간 확인 필요’와 원본 링크를 표시한다. Google에서도 실제 설명이 없으면 주소를 설명으로 꾸미지 않는다.
- Google 기존 데이터는 ID 참조 방식 그대로 유지. 보완 데이터는 요청/화면 메모리에서만 사용하고 DB·디스크에 저장하지 않는다. 스키마/기존 데이터 변경 없음.
- 보완 장소는 출처가 표시된 목록/상세로 제공한다. 타사 지도 표시 권한이 확인되지 않았으므로 Google 지도 PIN에는 올리지 않는다. 지도 PIN 노출, AI 추천 입력, 저장/게시물 연결은 별도 출시 게이트다.
- 서버 `LOCAL_PLACES_PROVIDERS`에 검토·활성화된 공급자만 설정한다(기본 빈 값). 키는 서버 secret에만 둔다. 네이버의 검색 결과 수익화/AI/저장 제한과 카카오 이용 범위 확인 전 운영 활성화를 완료했다고 취급하지 않는다.
- 추가 검색 중에도 기존 Google 결과를 보존한다. 새 검색·지도 이동이 시작되면 이전 보완 응답은 무시한다. 동일 공급자 ID만 중복 제거하고 서로 다른 ID/공급자의 유사 장소는 자동 합병하지 않는다.
- 검증: Google 성공/빈 응답/오류, 명시적 추가 검색, 키 미설정, 429, 타임아웃, 기본 정보 누락, 네이버 좌표 정규화, 공급자 ID 충돌, 보완 상세의 미호출/사진·소개 미표시, 좁은 화면을 테스트한다. 실제 공급자 키·배포 전에는 mock 검증을 실연결 완료로 보고하지 않는다.

근거: [카카오 응답](https://developers.kakao.com/docs/ko/local/dev-guide), [네이버 응답](https://api.ncloud-docs.com/docs/naver-api-hub-search-local), [네이버 약관 공지](https://www.ncloud.com/support/notice/all/2243). 사용자 첨부 화면 및 Figma `531:19733`의 사진·소개 영역을 Google 전용으로 해석하며 Pind 평점/친구 통계를 외부 API로 위조하지 않는다.

### Google 기존 계약

places.id(bigint)가 공통 ID. 공공/Pind 소유 데이터는 출처 기준일과 함께 저장하며 Google 행과 분리한다. is_reference_only=true Google 행은 이름/주소/좌표/사진을 DB에서 쓰지 않고 서버 hydrate한다. 앱에는 publishable key와 제한된 Maps SDK 키만 포함한다.

| action | 입력 | 응답 |
| --- | --- | --- |
| nearby | latitude, longitude, radiusMeters, languageCode | places[], internalId 포함 |
| search | query, languageCode | places[], internalId 없을 수 있음 |
| resolve | externalPlaceId | place, internalId 확정 |
| detail | internalPlaceId | place, 영업/전화/사이트/사진/출처 |
| details | internalPlaceIds, 최대 20개 | places[] |

호출은 기본 조회는 supabase.functions.invoke('places'), 명시적 Google 조회만 invoke('google-places'). 장소 응답은 externalPlaceId/name/category/address/latitude/longitude/heroImageUrl/googleMapsUri/photoAttributions/gallery를 가진다. API 오류 코드/메시지를 전달하고 실패를 빈 성공으로 바꾸지 않는다. 마커 사진마다 사진 제공자 링크를 열람할 수 있어야 한다.

Edge Function은 JWT 필요. P0은 명시적으로 허용한 개발 익명 세션만 사용하며 재사용한다. 세션 갱신 실패로 임의 로그아웃/새 익명 사용자 생성은 하지 않는다. Expo와 Flutter의 토큰 저장소가 달라 익명 user_id는 자동 공유되지 않는다. 기존 글 소유권 이전은 기존 기기 identity linking 또는 검증된 서버 이관 후 수행한다.

## 4. 데이터 확장 (P1 이후)

| 테이블 | 계약 | 권한 |
| --- | --- | --- |
| profiles 확장 | handle unique 대소문자 무시/확정 후 불변, country, locale, onboarding_completed_at | 공개 최소 정보; 본인 수정 |
| account_details | user_id PK, name, birth_date, gender nullable | 본인 읽기/쓰기; 공개 테이블과 분리 |
| user_consents | user_id, purpose, document_version, accepted/revoked_at | 본인 읽기, 서버가 버전/시각 확인 |
| user_taste_preferences | user_id PK, priorities[2], occasions[0..3], cuisines[3..], version | 본인 CRUD, allowlist/중복/개수 검사 |
| saved_places | (user_id, place_id) PK, created_at | 본인 select/insert/delete |
| posts 확장 | ratings jsonb(작성자 우선순위 3개 → 1..5), 구형 taste/portion/ambience_score, client_request_id, status | 기존 NULL 보존, 신규 API 평점 3개 필수 |
| post_media | id, post_id, position 0..9, bucket/path/mime/bytes | 부모 글 권한, 소유자 쓰기, 순서 unique |
| collections/collection_places | 제목/설명/출처, 장소 순서 | 게시된 모음만 공개, 운영자 쓰기 |
| follows (friendships 대체, 20260930020000) | 팔로우=행 추가, 취소=행 삭제 | 로그인 사용자 읽기, 본인 follower 행만 추가·삭제 |
| taste_profiles | 온보딩 우선순위 3개 + 추천 동의(discoverable) | 본인 행만; 일치율은 `get_taste_matches`/`search_profiles`(definer) |
| friend_invites | 토큰 해시/만료/소비 시각 | 서버 RPC, 중복 수락 idempotent |
| blocks/reports | 주체/대상/사유/상태 | 본인 제출, 운영 검토, 신고자 비공개 |
| user_badges | user_id/badge_code/awarded_at | 공개 읽기, 서버 조건 검사 |

모든 노출 테이블 RLS 및 필요한 GRANT. UPDATE에 USING/WITH CHECK, 새 view는 security_invoker. RPC는 invoker 기본. 불가피한 definer는 private schema·빈 search_path·명시 권한·신원 검사로 제한한다. 모더레이션 status 기본값은 구형 글 가시성을 보존한다.

complete_onboarding_v1은 handle/동의/선택 개수를 검증해 한 트랜잭션으로 계정 설정과 취향을 저장하고 완료 처리한다. P0 기기 draft를 서버 완료로 취급하지 않는다.

publish_post_v3(client_request_id, place_id, ratings, body, media[])는 온보딩에서 고른 우선순위 3개 기준의 평점(`{criterion: 1..5}`)을 받아 `posts.ratings`와 `place_ratings`에 원자 저장한다. 우선순위가 없는 계정은 맛·양·분위기로 평가한다. v2는 맛·양·분위기를 v3로 넘기는 호환 래퍼다. 두 RPC 모두 사용자·장소·사진 소유 경로/실제 객체 존재·개수·평점 범위를 검증한다. 업로드→DB 원자 저장→성공 순서. 중복 키는 기존 결과 반환, 실패 시 이번 업로드만 정리, 기존 사진은 DB 성공 후 정리. v1 RPC는 구형 Expo 때문에 유지한다. 본문 200자 규칙은 v2에 적용하고 기존 글은 자르지 않는다.

신규 미디어 목표는 private post-media-v2 + 정책 검사 후 짧은 signed URL. 기존 public post-media는 즉시 비공개로 바꾸지 않는다. 복사→검증→DB 참조 전환→구형 앱 종료→기존 공개 객체 정리. 숨김 직후도 signed URL 만료까지 접근 가능함을 반영한다.

## 5. 추천·정렬 계약
2026-09-27 사용자 승인으로 이전 1/1/1 +2/+1 산식을 대체한다. 선택 기준 3개의 순서에 50%/30%/20%를 적용한다. 항목별 내 평가가 있으면 (내 평가 + 공개 가게 평균)/2, 없으면 공개 가게 평균을 쓴다. 내 취향% = round(Σ(항목 점수/5 × 가중치) × 100). 선택 항목의 가게 평균이 하나라도 없으면 NULL(평가 부족), Google 전체 평점은 항목별 값으로 전용하지 않는다.

`place_ratings`는 사용자/장소/기준당 하나의 최신 평가를 저장한다. 8개 선택 기준에 대응하되 없는 평가를 채우지 않는다. 공개 평균과 본인 평가를 구분하여 조회한다. 기존 글 작성 RPC에 평점을 자동 생성하지 않으며 작성 화면의 원자 저장 연결은 후속이다. 트렌드/정렬/서버 추천은 이번 상세 UI 검증 범위 밖이다.

### 2026-09-27 가게 상세 구현 단위

- UI 정리 (`FR-MAP-007`, `FR-PL-010`): 주변 수량 버튼을 제거한다. 명시적 검색과 추가 검색 완료 시 기존 결과 시트를 열며, 지도 이동은 결과 시트를 자동으로 열지 않는다. 사진 PIN의 기존 상세 진입은 유지한다.
- Figma `524:30186`: 소개/게시물 각각 50% 너비, 글자 14, 위/아래 여백 10. 선택 글자 `#111111`/700·밑줄 3, 비선택 `#9B9B9B`/500·밑줄 `#EDEDF1`/1. 상태 전환과 글자 확대를 Flutter에서 지원한다.
- 주간 운영시간 확장, 전화번호, 웹사이트와 본문의 중복 Google 길찾기를 제거하고 오늘 시간·거리·리뷰·고정 액션은 유지한다. 사진마다 저작자와 원본 링크를 아래에 9pt로 줄바꿈하여 표시하며 글자가 커져도 잘리지 않도록 갤러리 높이는 내용에 맞춘다. Google 사진의 필수 출처는 삭제하지 않는다. 보완 장소의 원본 링크는 유지한다.
- 사진 출처 근거: [Google Places 사진 정책](https://developers.google.com/maps/documentation/places/web-service/place-photos), [출처 표시 정책](https://developers.google.com/maps/documentation/places/web-service/policies).

- Figma `524:30239`(헤더), `524:30203`(유리 배경), `524:30207`(고정 버튼), `524:30280`(사진), `524:30204`(확장 안내)를 기준으로 구성한다. 원본 아이콘 5개를 원래 SVG 크기로 배치한다. 사진·아바타는 실제 데이터 슬롯이고 Figma 사진은 명시적 로컬 QA에서만 사용한다.
- `PlaceSheet`: `DraggableScrollableSheet` 안의 `Expanded(ListView)`와 별도 하단 액션 바. blur 20, 흰 테두리, 반투명 하이라이트로 유리 질감을 Flutter에서 렌더링한다. iOS 전용 네이티브 Liquid Glass API는 아니다. 기본 높이 70%, 확장 96%; 최소 터치 영역/홈 인디케이터 대응 때문에 원본의 고정 높이를 기기에 맞춰 조정한다.
- Google `currentOpeningHours` 우선, 없으면 `regularOpeningHours`. `userRatingCount`, `utcOffsetMinutes`는 상세 요청에만 추가하며 별도 리뷰 요청은 하지 않는다. 비용이 있는 상세 SKU이므로 무과금이라고 주장하지 않는다. 거리=실제 위치와 장소의 직선거리. 지도 중심을 내 위치로 사용하지 않고 권한 요청은 ‘거리 확인’을 눌렀을 때만 수행한다.
- `PlaceContextRepository`는 공개 항목 평균/본인 평가/수락된 친구 공개 방문/본인 저장을 가져온다. Google 전체 평점은 취향 기준으로 변환하지 않는다. 연결 실패와 평가 부족을 구분하며 친구 행은 공개 방문이 있을 때만 표시한다.
- `place_ratings`, `saved_places`, `get_place_detail_context`는 로컬 migration으로 준비한다. 신규 테이블은 RLS, 본인 쓰기, UPDATE USING/WITH CHECK 적용. RPC는 SECURITY INVOKER이며 anon/PUBLIC 실행 권한을 제거한다. 기존 `visits`의 비공개 정책을 풀지 않고 공개 `posts`와 수락된 관계를 조인한다. 저장은 기본 비공개이며 공개 동의한 친구 저장만 집계한다.
- 저장 중 중복 요청을 막고 실패 시 상태를 되돌린다. 공유는 OS 공유 시트에 이름/원본 링크를 넘기고 iPad 앵커도 지정한다. Google 길찾기는 `/maps/dir/?api=1` 링크, 보완 장소는 원본 지도로 이동한다. 보완 장소 저장/영업시간/사진을 만들어내지 않는다.
- 로컬 검증 전용 `lib/view/preview/detail_preview.dart`와 `LocalDetailContext`는 `main.dart`에서 import하지 않는다. `pind_test_friend`는 실제 Auth 계정이 아닌 테스트 프로필이다. 원격 배포/실제 계정 생성은 하지 않는다. 실제 회원 로그인·서버 취향 저장·평가 작성 화면·게시물 목록은 후속 연결이다.
- [Google 상세 필드와 과금 범주](https://developers.google.com/maps/documentation/places/web-service/place-details), [Supabase Admin 계정 생성](https://supabase.com/docs/reference/dart/auth-admin-createuser)를 확인했다. 관리 키는 모바일에 넣지 않는다.

## 6. 이행 순서·복구

1. P0 이번 개발: Flutter/설정/에셋/취향 모델·선택 화면/기존 Places 저장소/지도·검색·상세. 스키마 변경 없음, 기기 draft만 저장.
2. P1: 원격 migration/RLS/Auth 확인 후 신규 테이블/RPC/스토리지, 로컬·개발 DB 테스트. 기존 서버 데이터와 Flutter 계약 비교.
3. P2: 로그인·프로필·다중 사진·저장·Discover·친구·마이페이지. 각 디자인 상태와 수용 시나리오 연결.
4. P3: 정식 bundle ID/서명/딥링크/영어/운영/성능 검증 후 TestFlight. 구형 코드 제거와 기능 동등성/출시 완료는 별개다.

구형 클라이언트 복구가 필요하면 프로젝트 밖 `../pind-react-native-backup-116Aiw/mobile/` 백업을 사용한다. 기본 개발/실행 대상은 Flutter뿐이다. 추가 데이터가 생긴 migration을 DROP으로 되돌리지 않는다. P1 배포 전 백업/복원·구형 계약 테스트를 남긴다.

## 7. 검증·환경

| 검증 | 확인 |
| --- | --- |
| 도메인 | 선택 순위/최소최대/손상 저장값, NULL·가중치·동률, 한국 경계·50km |
| 위젯 | 선택/해제/뒤로/복원, 작은 화면/큰 글씨, 로딩/오류/재시도 |
| 저장소 | payload·파싱·오류·세션 재사용·늦은 응답 무시 |
| 실제 연결 | 주변/검색/resolve/상세의 내부 ID·출처 일치 |
| DB P1 | 두 사용자로 상대 데이터 읽기/쓰기 거절, 익명 경계, 재시도·롤백 |
| 미디어 P2 | 10장/부분 실패/중복/삭제/차단/고아 복구 |
| 네이티브 | iOS build, 사진 PIN·팬·확대·위치 거부·복귀·시각 비교 |

설치 환경은 Flutter 3.47.5, Dart 3.13.4. pubspec.lock 고정. gitignored config/local.json + dart-define-from-file 사용. 실제 지도/DB 검증 불가는 명시하며 test double 통과로 대신하지 않는다.

근거: [Flutter 구조 가이드](https://docs.flutter.dev/app-architecture/guide), [Supabase Flutter](https://supabase.com/docs/reference/dart/initializing), [익명 인증/연결](https://supabase.com/docs/guides/auth/auth-anonymous), [지도 플러그인](https://pub.dev/packages/google_maps_flutter). [Supabase changelog](https://supabase.com/changelog)는 2026-09-26 확인했으며 이번 코드가 ltree/btree_gist/legacy pgcrypto/logs.all에 의존하지 않음을 점검했다. 원격 확장 사용 여부는 관리 권한으로 별도 확인 필요.
