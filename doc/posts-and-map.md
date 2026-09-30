# 게시물 작성과 지도 노출

2026-09-28 구현·검증 기록.

## 동작 기준

- 식당별로 공개 상태(`is_public=true`, `status=published`) 게시물이 한 개 이상 있을 때 지도에 표시한다. 모든 작성자의 게시물을 기준으로 하며, 현재 사용자의 첫 게시 여부로 지도 전체를 잠그지 않는다.
- 게시물 없는 SBIZ/Pind 식당도 검색과 방문 식당 선택에는 노출된다. Google 기본 지도 사업장 POI는 숨겨 Pind 게시물 조건을 우회하는 식당 표시를 막는다.
- 마지막 공개 게시물 숨김·삭제 후에는 다음 지도 조회에서 식당이 제외된다. 주변 조회는 게시물 조건을 적용한 다음 가까운 식당 30개를 선택한다.
- 사진 1–10장과 맛·양·분위기 각 1–5점이 필수다. 본문은 선택이며 최대 200 Unicode codepoints다. 기기 사진은 2048px 이하로 선택하고 한 장당 10MB 이하 JPEG/PNG/WebP/HEIC/HEIF를 허용한다.
- 실제 저장이 성공한 경우에만 작성 화면을 닫고 지도 탭으로 돌아간다. 식당 좌표 주변을 서버에서 다시 조회해 게시 수를 반영한다. 실패한 경우 입력 내용을 유지한다.
- 동일 작성 요청 ID 재시도는 게시물·방문 기록을 중복 생성하지 않는다. 저장 중 사진·식당·평점·본문 변경과 화면 닫기를 막는다.

## 피그마와 클라이언트 구조

파일 `AepN5S4XiejtlWS52Q7Arg`: 작성 `531:18182`, 입력 완료 `531:18260`, 전체 칩 `542:22927`, 카테고리 칩 `542:22930`.

`531:18260`은 사진·평점·본문이 채워지고 게시 버튼이 활성화된 작성 상태다. 별도의 축하 페이지를 추가하지 않았다.

- `lib/model/post_model.dart`: 초안, 사진, 평점, 게시 가능 상태.
- `lib/controllers/post_controller.dart`: 사진 선택, 식당 검색, 게시 요청·중복 방지.
- `lib/services/post_photo_service.dart`: 기기 사진 선택.
- `lib/services/post_service.dart`: Supabase 업로드 및 게시 RPC.
- `lib/view/posts/`: 작성 화면과 식당 선택 화면.
- `lib/view/components/pind_glass.dart`, `lib/view/explore/map_filter_chip.dart`: 블러·테두리·그림자와 필터 칩.

원본 SVG는 수정 없이 로컬 자산으로 사용한다. SVG의 필터는 flutter_svg가 지원하지 않으며 유리 표면 효과는 Flutter에서 렌더링한다. 원본 사진은 테스트에만 사용하고 실제 게시물에는 기기 사진을 사용한다. 자산 위치·출처·원본 크기는 `assets/README.md`에 기록했다.

## 서버 반영

연결 프로젝트 `mkfgqobwededpzdekvxg`에 `20260928071712_published_posts_map.sql`과 `places` Edge Function을 반영했다. Google Places 전용 함수·키는 이번 변경에 포함하지 않는다.

- `publish_post_v2`: 인증 사용자 소유의 실제 업로드를 확인하고 게시물, 사진 목록, 세 축 평점, 방문 기록을 한 트랜잭션으로 저장한다. 익명 Auth 사용자의 게시를 거부한다.
- `post_media` 및 비공개 `post-media-v2` 버킷: 사진 소유자와 공개 게시물 독자만 접근한다. 타인 사진 첨부·타인 경로 업로드를 거부하고 이미 첨부된 사진은 업로드 실패 정리 과정에서 삭제하지 못한다.
- 지도 대표 사진은 5분짜리 signed URL을 생성한다. 기존 공개 `post-media` 버킷과 레거시 게시물은 유지한다.
- 직접 SQL 점검에서 RLS 활성화, 비공개 버킷, 익명 역할의 게시 RPC 실행·사진 테이블 조회 권한 차단을 확인했다.
- 기존 게시물 9개와 공개 카탈로그 151,301개가 유지됐다. 반영 시점에 지도 조건을 만족하는 SBIZ/Pind 식당은 0개다. 첫 공개 게시물 등록 전 지도에 식당 핀이 없는 것은 이 기준에 따른 결과다.

## 검증

- `flutter analyze`: 경고·오류 없음.
- `flutter test`: 80개 통과. 게시 필수 조건·중복 요청·실패 시 초안 유지·늦은 사진 선택 응답·게시 후 좌표/카운트 갱신·모든 SVG의 원본 및 렌더링 크기·320px/200% 글자/키보드를 확인했다. 지도 조건 변경으로 길찾기가 차단되지 않는 회귀 검증도 포함한다.
- `node --test supabase/functions/places/catalog.test.ts`: 6개 통과.
- `python3 scripts/test_post_sql.py`: 새 컨테이너에서 전체 마이그레이션과 카탈로그·소셜·게시물 SQL 세 묶음 통과. 게시물 조건이 nearby limit보다 먼저 적용되는지, 숨김·삭제, 권한, 원자적 저장, 중복 방지를 검증했다. Storage HTTP 서버 대신 최소 테이블을 사용하는 SQL harness다.
- iOS 26.5 / iPhone 17 Pro 시뮬레이터: 작성 화면, 실제 이미지 바이트 표시, 평점, 본문 입력, 버튼 상태, 저장 결과로 화면 복귀, 칩 렌더링 통과. 이 작성 테스트는 가짜 게시 서비스를 사용하며 운영 서버에 테스트 게시물을 생성하지 않는다.
- 캡처: `artifacts/ios/post-composer-empty.png`, `post-composer-filled.png`, `post-composer-filled-bottom.png`, `map-filter-chips.png`.

실제 Google 로그인 계정의 사진 선택·Storage 업로드·게시까지의 전체 흐름과 Android 기기 검증은 남아 있다. iOS UI 테스트와 SQL/RLS 검증을 해당 검증이나 출시 승인으로 간주하지 않는다.

재실행 명령:

```sh
flutter test
node --test supabase/functions/places/catalog.test.ts
python3 scripts/test_post_sql.py
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/post_flow_test.dart -d <ios-device-id> --dart-define-from-file=config/local.json
```

`integration_test/posts_catalog_live_test.dart`는 기존 기기 인증 세션으로 배포된 카탈로그 함수의 주변 조회·미게시 식당 검색을 읽기만 한다. 테스트 계정이나 게시물을 만들지 않는다.

이번 실행에서는 시뮬레이터에 기존 인증 세션이 없어 이 읽기 테스트가 실행 전 조건에서 중단됐다. 서버 확인은 마이그레이션 배포와 읽기 전용 SQL 점검까지이며, 로그인한 기기의 Edge HTTP 호출 검증은 남아 있다.
