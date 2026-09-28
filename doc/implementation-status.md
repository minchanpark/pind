# 구현 및 검증 상태

## 2026-09-28 Google Cloud Pind API 연결

- Google Cloud `pind` (`inductive-time-509809-p4`)로 지도·Google Places 키 연결을 맞췄다. 사용자가 수정한 앱 지도 키의 프로젝트 소속을 확인하고 iOS 앱을 재빌드하여 설치 산출물에 반영된 것을 비교했다.
- Pind 프로젝트에 Places API (New) 전용 서버 키를 생성했다. Git 제외된 `supabase/functions/.env`와 연결된 Supabase 프로젝트의 `GOOGLE_PLACES_API_KEY`를 갱신했고 원격 digest 일치를 검증했다.
- Places API (New), Maps SDK for iOS/Android 활성화와 billing 상태를 확인했다. Google Places 실요청 HTTP 200 / 장소 ID 1개 반환을 확인했다. iOS 지도 SDK 단독 검증 화면에서 실제 포항 타일을 확인했고 [네이티브 캡처](../artifacts/ios/google-cloud-pind-map.png)를 남겼다.
- Android 지도 기기 렌더링은 이번에 검증하지 않았다. 상세 설정은 [지도·장소 공급자 안내](google-maps-setup.md)를 따른다.

## 2026-09-28 전체 온보딩 구성

- 로그인 → 국가 → 기본 정보 → 닉네임/아이디 → 위치 권한 → 우선순위 3개 → 외식 선호도 → 음식 선택 → 지도 진입을 일반 앱에 연결했다. 제공한 Figma 다섯 화면의 원본 에셋·브랜드 서체를 사용하고 기존 취향 세 화면을 재사용했다.
- MVC 책임에 따라 가입 model/controller/auth·draft services를 추가했다. OAuth 호출 후 실제 인증 이벤트에서만 진행하며 계정별 draft 복원, 필수 동의·만 14세·아이디 형식, 위치 거부/건너뛰기/설정 오류, 이전 화면 선택 유지와 중복 완료 요청을 처리한다.
- `flutter analyze` 문제 없음, 전체 `flutter test` **72개 통과**. 기존 60개와 가입 단위/위젯 11개, 원본 에셋의 파일·슬롯·렌더링 크기 검증 1개를 포함한다.
- iPhone 17 Pro / iOS 26.5에서 `registration_flow_test.dart` 네이티브 테스트 통과. 가짜 인증과 로컬 저장소를 주입하여 8단계·완료 후 지도 진입을 검증하고 `artifacts/ios/onboarding-qa-*.png` 8장을 확인했다. 실제 소셜 공급자 로그인·실기기 권한 검증과 구분한다.
- 현재 기본 정보와 완료는 기기에 저장한다. 공급자 콘솔/redirect 설정, 아이디 중복·불변성, 닉네임 변경, 서버 프로필·동의 버전·취향·완료 저장은 연결이 남아 있다. 원격 DB·인증 설정은 변경하지 않았다. 구현 범위·설정·캡처는 [온보딩 안내](onboarding.md)를 따른다.

## 2026-09-28 MVC 구조 전환

- `lib`를 `model`, `view`, `controllers`, `services`, `main.dart`로 정리했다. 데이터·ChangeNotifier 상태는 model, 화면·테마는 view, 조회·저장 흐름은 controllers, Supabase·기기 기능 접근은 services에 배치했다. 자세한 책임과 수명 관리는 [MVC 아키텍처](architecture.md)를 따른다.
- 앱·탐색·상세·온보딩·탭 상태와 서비스 연결을 분리했다. 상세 시트가 화면 크기 변경으로 다시 그려져도 같은 컨트롤러를 유지한다.
- `flutter analyze` 문제 없음, `flutter test` **60개 통과**. 기존 53개와 요청 순서·해제 후 응답·저장 실패 복구·중복 제출 관련 컨트롤러 테스트 7개를 포함한다. 일반 앱의 상세 화면 크기 변경 시 재조회가 발생하지 않는 것도 확인했다.
- 계층 간 의존성 및 이전 Dart import 경로의 잔존 여부를 확인했다. 이번 구조 변경 후 실제 Supabase 연동·시뮬레이터/실기기 통합 테스트·배포 빌드는 다시 실행하지 않았다.

## 2026-09-27 앱 ID 통일 및 서울·포항 공공 장소 조회 연결

- iOS Debug/Profile/Release의 bundle ID, Android namespace/applicationId, MainActivity 패키지를 모두 `com.pind.app`으로 수정했다. RunnerTests는 `com.pind.app.RunnerTests`다. 기존 사용자 변경 및 React Native 삭제 상태는 보존했다.
- iOS 시뮬레이터 빌드 성공 및 설치된 앱의 `CFBundleIdentifier=com.pind.app` 확인. `lib/main.dart` 일반 앱에서 Google 지도 타일 표시를 확인했다. 증거: `artifacts/ios/com-pind-app-map.png`. 키의 허용 ID와 앱 ID가 일치하며 이전 타일 미표시 진단은 해결됐다.
- Android debug APK 빌드 성공. aapt로 `package=com.pind.app`, `launchable-activity=com.pind.app.MainActivity` 확인. Android 지도 런타임/전용 API 키·서명, 배포용 iOS 서명 검증은 별도다.
- Flutter 분석 문제 없음, 테스트 **53개 통과**. 앱 ID 회귀 검사 및 일반 앱의 공공 장소 검색→상세에서 Google 호출이 없음을 포함한다.
- 공공/Pind 우선 클라이언트·새 `places` 함수·Google 명시적 요청/일일 제한·SQL migration·CSV importer를 로컬 구현했다. Edge 타입 검사, Node 계약/수입 테스트 **19개**, 격리 PostgreSQL에서 전체 migration 적용 및 공개 범위/ID 유지/권한/공간 조회/Google 한도 롤백 검증을 통과했다.
- 공식 2026-06-30 공공 CSV의 서울 범위 554,092행 중 음식점 141,126건을 원격 프로젝트 `mkfgqobwededpzdekvxg`에 수입했다. 서울 수입 직후 DB 크기는 135 MB였다. 공개 Pind 자체 장소는 당시 0건이었다.
- 같은 원본의 경북 파일에서 `시도명=경상북도`, `시군구명=포항시 남구/북구`, 음식점 업종 `I2`만 추가 수입했다. 남구 5,079건·북구 5,096건, 합계 10,175건이다. 원격 `public.places` 공공 장소 총수는 151,301건, DB 크기는 142 MB다. `get_catalog_places`의 포항 주변 조회와 ‘포항’ 검색이 각각 최대 30건을 반환함을 확인했다. 경북의 다른 시·군은 수입하지 않았다.
- 원격 이력을 가져와 로컬 초기 migration 파일명을 맞췄다. 이전 로컬 변형은 `doc/archive/migration-variants/`에 보존했다. `db push --dry-run`에서 신규 두 migration만 표시됨을 확인한 뒤 적용했다. 기존 이력을 재실행하거나 수정하지 않았다. `places`와 `google-places` 함수를 배포했다.
- 일반 iPhone 시뮬레이터 앱에서 실제 공공 장소 PIN과 상세의 상호명·주소·기준일 표시를 확인했다. 사진·영업시간이 없는 경우 미확인으로 표시된다. 원격 보안 advisor에서 오류 0건, 경고 9건을 확인했다. 익명 인증 정책 및 유출 암호 방지 설정 경고는 별도 운영 검토 대상이다. 다른 지역 수입과 실제 다중 사용자/친구 데이터 검증은 남아 있다. 설계와 데이터 범위는 [공공/Pind 우선 설계](public-first-places.md).

## 2026-09-27 지도·상세 UI 정리

- 일반 앱의 ‘주변 N곳 보기’ 버튼을 제거했다. PIN 상세 진입은 유지하며, 검색·추가 검색 완료 시 결과 목록이 열려 보완 제공자 장소도 선택할 수 있다. 늦은 이전 검색으로 목록이 중복 열리지 않도록 보호했다.
- 상세에서 웹사이트·전화번호·주간 시간표·본문 Google 길찾기 버튼을 제거했다. 오늘 시간과 고정 저장/공유/길찾기는 유지한다.
- Figma `524:30186` 기준으로 50% 너비의 소개/게시물 탭과 선택 밑줄을 적용했다. 사진 저작자/원본 링크는 각 사진 아래 9pt로 옮겼다. 게시물 데이터 연결은 이전과 같이 미완료이며 이번 변경은 탭 UI에 한정한다.
- 검증: Flutter 단위/위젯 테스트 47개와 정적 분석 통과. 삭제 대상 부재, 탭 너비/밑줄/전환, 사진별 출처 연결과 200% 글자 확대, 일반 앱 상세 진입/복귀 및 보완 검색 선택을 확인했다.
- `lib/main.dart`와 기존 로컬 설정으로 iPhone 17 Pro 시뮬레이터를 실행하여 실제 지도 PIN → 명동교자 상세를 확인했다. 캡처: `artifacts/ios/detail-cleanup-map.png`, `artifacts/ios/detail-cleanup-live.png`.
- 원격 DB/함수는 변경·배포하지 않았다. 기존 지도 배경 타일 미표시와 원격 취향/친구 정보 연결 문제는 이번 범위 밖이다.

## 2026-09-27 일반 앱 상세 진입 확인

- 별도 `detail_preview.dart` 대신 `lib/main.dart` + 기존 `config/local.json`으로 일반 앱을 실행했다. Flutter 파일의 프로젝트 루트 이동은 보존하고 IDE 기본 실행 구성도 일반 앱으로 지정했다.
- 네이티브 지도에 노출된 ‘명동교자 본점’을 실제로 클릭하여 새 유리 질감 상세와 원격 장소 사진/영업시간/고정 액션이 열리는 것을 확인했다. 증거: `artifacts/ios/app-place-detail-live.png`. 서버 상세 응답 이름은 `Myeongdong Kyoja`다.
- `test/app_detail_flow_test.dart`는 미리보기 대신 `PindApp → MainShell → 장소 목록 → PlaceSheet → 지도 복귀`를 검사한다. 취향/데이터 어댑터 전달, 상세 요청, 고정 버튼, 지도 조회 상태 유지까지 포함한다.
- 현재 프로젝트 루트에서 전체 Flutter 테스트 **42개 통과**, `flutter analyze` 문제 없음, 일반 앱 iOS 빌드·실행 성공. 생성된 네이티브 실행 대상도 루트의 `lib/main.dart`로 확인했다.
- 일반 앱 UI 연결과 서버 기능 완료는 별개다. 원격 취향/친구 RPC·저장 테이블과 리뷰 수 필드 배포는 여전히 미완료이며 연결 오류/평가 부족/확인 필요가 표시된다. 테스트 점수나 친구를 일반 앱에 주입하지 않았다.

## 2026-09-27 가게 상세: 로컬 검증 완료 / 원격 연결 대기

- 사용자 승인: 우선순위 3개, 가중치 50·30·20%, 내 평가가 있으면 가게 공개 평균과 절반씩 반영. 선택한 항목의 평균이 누락되면 ‘평가 부족’. 기존 2개 취향은 보존하고 세 번째 선택을 받는다.
- Figma `524:30239`와 첨부 이미지 기준으로 유리 질감 상세 시트, 원본 SVG 5개, 가로 사진 목록, 확장 안내, 고정 저장/공유/길찾기를 구현했다. Flutter blur/하이라이트 방식이며 네이티브 iOS Liquid Glass API는 아니다.
- 오늘 영업시간·현재 위치의 직선거리·리뷰 개수를 표시한다. 시간/거리/리뷰 수가 없으면 미확인으로 처리한다. Google 상세 응답 필드 확장을 준비했지만 원격 Edge Function에는 아직 배포하지 않았다.
- 로컬 테스트 프로필 `pind_test_friend`로 친구 없음/수락 대기/수락/해제/비공개 방문을 검증했다. 수락된 친구의 공개 방문이 없으면 해당 행을 숨긴다. 실제 Auth 테스트 계정은 사용자 결정에 따라 생성하지 않았다.
- 검증: Flutter 단위/위젯 테스트 **41개 통과**, 정적 분석 문제 없음, iPhone 17 Pro / iOS 26.5 기기 통합 테스트 통과(확장·스크롤 중 액션 고정, 저장 상태 복원, 친구 행 유무). 320px/글자 200%, 저장 실패 복구, 공유 URL/앵커와 길찾기 URL도 테스트했다. OS 공유 대상 앱의 실제 전달까지 검증한 것은 아니다.
- 서버 검증: Edge Function Deno 타입 검사 통과, 기존 공급자 테스트 **11개 통과**. 격리된 PostgreSQL 17 컨테이너에 전체 migration을 적용하고 `supabase/tests/place_detail_context.sql`로 관계·공개 범위·RLS·저장·함수 권한 검증 통과. Auth/Storage는 테스트 하네스이며 원격 Supabase 환경의 전수 검증을 대신하지 않는다.
- 캡처: `mobile_flutter/artifacts/ios/detail-qa-friend.png`, `detail-qa-expanded.png`, `detail-qa-no-friends.png`. 원본 사진은 명시적 로컬 QA 데이터이며 실제 가게 데이터로 보완하지 않는다. 실행 진입점은 `lib/view/preview/detail_preview.dart`.
- 남은 연결: migration/Edge Function 원격 적용, 실제 회원 로그인과 취향 동기화, 항목별 평가 작성, 실제 친구 요청·수락 UI/계정, 게시물 목록. 일반 앱에는 새 상세 UI와 데이터 어댑터를 연결했지만 원격 저장/평가/친구 기능이 운영 완료된 것은 아니다. 지도 배경 미표시 문제는 이번 변경 대상 밖이다.

## 2026-09-26 내비게이션 재설계 N1

- Figma 6차 디자인의 지도/Discover/마이페이지 내비게이션을 기준으로 PRD `FR-NAV-001–006`과 구현 설계를 갱신했다. 원본 SVG 12개로 273×58 반투명 바, 선택/비선택 상태, 44×44 터치 영역을 구현했다.
- Discover / 지도 / 작성 / 마이페이지 순서다. 세 탭은 지도 검색 상태를 유지하며, 작성은 별도 전체 화면으로 열고 닫으면 이전 탭으로 돌아온다. 취향 수정도 지도 화면을 제거하지 않는 별도 경로로 변경했다.
- 기기 safe area, 키보드 표시, 시스템 뒤로 가기, 작은 화면과 큰 글씨를 검증했다. 기존 지도 하단 컨트롤은 바와 겹치지 않도록 위치만 조정했다.
- 검증: `flutter analyze` 문제 없음, 단위/위젯 테스트 **33개 통과**, 세 선택 상태 이미지 회귀 검사 통과, iPhone 17 Pro / iOS 26.5에서 `integration_test/navigation_flow_test.dart` 통과. 이 기기 테스트는 내비게이션에 한정하며 원격 Places API나 지도 타일 검증은 아니다.
- 실행/시각 증거: `mobile_flutter/artifacts/ios/navigation-map.png`, `navigation-qa-{map,discover,profile,compose}.png`. 원본 SVG 크기와 세 선택 상태를 비교했다.
- 현재 Discover/마이페이지 본문과 작성 폼은 ‘구현 예정’ 안내다. 완성된 피드/프로필/게시 기능으로 간주하지 않는다. 기존 지도 배경 타일 미표시 문제도 해결되지 않았다.
- 다음 구현 단위 N2: 지도 상단 검색, 출처 필터, 카테고리 배치를 Figma에 맞춘다. 이후 상세 → 작성 → Discover → 마이페이지 순서다.

## 2026-09-26 후속 변경: Flutter 전용 및 보완 검색

- 사용자 결정: Google 우선, 정상 검색 결과가 없거나 사용자가 추가 검색할 때만 보완. 보완 장소의 운영시간은 ‘확인 필요’와 원본 지도 링크로 안내.
- React Native/Expo `mobile/` 전체(추적 파일 44개와 node_modules/로컬 설정 포함)를 프로젝트에서 제거했다. 미커밋 `posts.ts`와 설정을 포함한 1.2GB는 프로젝트 밖 `/Users/minchanpark/Documents/pind-react-native-backup-116Aiw/`로 이동해 복구 가능하다. 구형 MVP 결정 기록/지도 설정 원본도 같은 위치에 보존했다.
- Flutter가 유일한 모바일 클라이언트다. Supabase 서버 TypeScript와 기존 데이터/migration은 유지한다. 현재 README와 지도 설정 안내에서 구형 실행 명령을 제거했다.
- PRD D-030–032 / FR-SR-003–005 / FR-PL-005–006 및 구현 설계를 수정했다. 기존 Google 함수를 확장하는 카카오/NAVER API HUB 어댑터, 공급자별 식별자·링크·상세 분기, Google 오류의 잘못된 fallback 방지, 추가 검색의 기존 결과 보존을 구현했다.
- 서버가 활성화 여부를 알리지 않으면 추가 검색 버튼을 노출하지 않는다. 키/이용권한/배포가 없는 상태를 동작 완료로 위장하지 않는다. 보완 장소의 Google 지도 PIN·영구 저장·AI 입력은 활성화하지 않았다.
- 검증: 최종 `flutter analyze` 문제 없음, Flutter 테스트 24개 통과, 서버 mock 테스트 11개와 Deno 2.9.6 타입 검사 통과, `git diff --check` 통과. 최종 iOS debug 재빌드 11.1초 후 실제 앱 실행 재확인.
- iPhone 17 Pro / iOS 26.5 시뮬레이터에서 Xcode debug 빌드 및 앱 실행, Supabase 초기화와 온보딩 실제 화면 확인. 마지막 네이티브 캡처에서는 지도 화면과 실제 장소 사진 PIN/목록 버튼이 표시됐다. `mobile_flutter/artifacts/ios/flutter-only-running.png`에 캡처를 남겼으며 디버거 detach 후에도 앱 프로세스 실행을 확인했다.
- 미완료: 보완 공급자의 실키·약관 검토·원격 함수 배포·실응답 검증. 마지막 지도 캡처에서도 배경 타일은 비어 있어 기존 문제가 남아 있다. Maps SDK 키/API/앱 ID 제한 확인이 필요하며 원인을 확정한 것은 아니다. 아래 초기 기록의 ‘기존 앱 보존’은 이 후속 변경으로 대체된다.

## 초기 P0 기록

2026-09-26. 기준: [PRD v3](prd.md), [구현 설계](implementation-design.md). 문서 완성과 제품 출시 준비를 구분한다.

## 문서 작업

- Figma 6차 디자인의 제품 화면 30개를 확인하고 [화면 대응표](figma-screen-map.md)를 작성했다. 연결 반응이 없는 여정은 화면 내용으로부터의 해석으로 표시했다.
- 별점 금지, 전화번호 필수, 단일 사진 등 이전 PRD와 달라진 요구를 수정했다. 이전 PRD는 `archive/prd-v2.md`에 보존했다.
- Flutter 전환, 기존 Supabase 재사용, 추가 DB/RPC/RLS, 익명 계정 이행 위험, 단계별 검증 조건을 설계했다. DB 확장안은 아직 적용하지 않았다.

## 구현한 첫 수직 기능

`mobile_flutter/`에 독립 클라이언트를 추가했다. 기존 Expo 앱과 데이터 이력을 대체하거나 삭제하지 않았다. 기존 `mobile/src/services/posts.ts` 사용자 변경도 그대로 보존했다.

- 취향: 순위 있는 기준 2개, 상황 0–3개, 음식군 3개 이상, 선택/해제·뒤로 이동·저장 오류, 기기 내 복원/수정.
- 디자인: Figma 음식 사진 12개, 보라/노랑 색상, 카드와 선택 상태. 작은 화면 및 큰 글씨 대응.
- 탐색: 네이티브 Google 지도 위젯, 범위 기반 조회, 검색, 사진 PIN, 기본 카테고리, 장소 목록, 현재 위치와 확대/축소.
- 상세: Google 장소 ID 확정 후 조회, 사진·제공자·영업시간 등 실제 응답, 출처/Google Maps 링크, 오류/재시도.
- 안정성: 요청 중복 억제, 늦은 응답 무시, dispose 후 처리 차단, 서버 미설정 안내.
- 점수: 3축 가중치와 NULL 처리의 순수 함수 및 테스트. 실제 개인화 랭킹/후기 데이터 연결은 아직 없다.

취향은 로컬 draft이며 서버 회원가입 완료가 아니다. 개발용 익명 인증을 명시적으로 허용했을 때만 기존 Edge Function을 호출한다.

## 검증 결과

| 검사 | 결과 |
| --- | --- |
| `flutter analyze` | 문제 없음 |
| `flutter test --reporter expanded` | 단위/위젯 테스트 15개 통과 |
| 선택 흐름/접근성 | 402×874 흐름, 320×568·글자 200%, 저장 복원/수정 취소, 오류/재시도 검증 |
| iOS simulator debug build | 성공, iPhone 17 Pro / iOS 26.5 |
| Android debug APK build | 성공. Android 기기 실행은 미검증 |
| 실제 Supabase 통합 테스트 | 1개 통과: 익명 세션, nearby, search, resolve, detail, 사용자 ID 유지, 앱 내 검색→목록→상세 |
| 캡처를 남기는 기기 테스트 | `flutter drive` 통과; `mobile_flutter/artifacts/ios/`에 로컬 PNG 저장 |
| 취향/상세/사진 PIN 시각 확인 | 캡처 확인 완료. 실제 장소 사진과 PIN 표시 |
| 지도 배경 타일 | 미해결. 테스트 캡처와 OS 직접 캡처 모두 배경이 비어 있음 |
| 원격 migration/RLS 전수 검증 | 미실시. MCP 프로젝트/SQL 접근 권한 거절 |
| 정식 OAuth·실기기·출시 서명/스토어 | 미실시 |

실제 테스트는 기존 개발 프로젝트 `mkfgqobwededpzdekvxg`를 사용했다. 초기에 DNS 오류, 복구 중 인증 502/REST 503이 있었으나 이후 동일 주소에서 통합 테스트가 통과했다. 일시적 복구 성공을 운영 가용성 보장으로 해석하지 않는다.

스키마 변경·Edge Function 재배포·DB reset은 실행하지 않았다. 실제 앱 테스트의 개발 익명 세션과 장소 reference 행은 기존 API 동작에 따라 생성될 수 있다. 원격에 게시물·사진·계정 개인정보를 작성하지 않았다.

## 남은 구현과 알려진 한계

우선 해결할 문제는 지도 배경 타일 미표시다. `artifacts/ios/native-map.png`에서도 사진 PIN만 보이므로 단순한 테스트 캡처 누락으로 보지 않는다. 기존 `doc/google-maps-setup.md`에는 Maps 키의 허용 bundle ID가 `com.pind.app`으로 기록되어 있지만 새 앱은 `com.pind.pindFlutter`다. 따라서 키의 앱 제한 불일치를 먼저 확인해야 한다. Google Cloud의 현재 키 제한을 직접 조회하지 못했으므로 원인으로 확정하지 않는다. 기존 앱 ID를 덮어쓰거나 키 제한을 무제한으로 풀지 않았다.

현재 이 문제 때문에 지도 탐색 기능 전체를 완료 처리하지 않는다. 장소 검색·목록·상세의 서버 연결 성공과 구분한다.

키 설정 확인 기준: [Google Maps의 iOS 앱 제한 안내](https://developers.google.com/maps/api-security-best-practices#restricting-api-keys). 새 bundle ID를 허용하는 제한된 키를 사용하며, 서버용 Places 키를 클라이언트에 넣지 않는다.

- P1: 카카오/Apple/Google 인증, 국가·기본정보·동의·아이디, 서버 취향, 저장, 추가 migration/RPC/RLS 및 두 사용자 권한 테스트.
- P2: Discover/친구, 3축 후기·사진 10장과 실패 정리, 프로필, 모음, 개인화·정렬, 네 개 하단 메뉴.
- P3: 영어, 딥링크/공유, 차단/신고/계정 삭제, 운영·성능·실기기·서명·배포.
- 전체 Figma의 픽셀 단위 재현 완료가 아니다. 후속 기능을 가짜 메뉴나 통계로 노출하지 않았다.
- SVG 선택 원의 HTML backdrop/filter는 Flutter SVG에서 지원하지 않아 원본 blur와 차이가 있다. 베이커리/술집은 해당 사진 에셋이 없어 텍스트 카드다.
- 기존 Edge Function의 상세 조회는 영어로 고정되어 검색의 한국어 이름이 상세에서 영어로 바뀔 수 있다. 다음 API 정비에서 languageCode를 일관되게 전달해야 한다.
- iOS 지도 플러그인은 CocoaPods 빌드를 사용하며 Swift Package Manager 미지원 경고가 있다. Android 종속 모듈에는 Java 8 source/target 경고가 있다.
- Orca의 Simulator 접근성 읽기는 macOS 권한 문제로 막혀 Flutter 기기 테스트와 네이티브 스크린샷으로 검증했다.

기존 익명 세션을 Flutter로 자동 이전하지 않는다. 출시 앱 ID와 사용자 연결 전략을 확정하기 전 Expo 앱을 교체하지 않는다.

## 다음 작업

먼저 새 bundle ID에 맞는 제한된 Maps SDK 키와 지도 타일을 확인한다. 이어서 P1 추가 migration을 실제 프로젝트 상태와 대조하고 공급자 콘솔 설정·리다이렉트·앱 ID를 확보한다. RLS·동의·서버 취향·저장 계약을 연결한 뒤 가입 화면을 완성하고, 작성/Discover/프로필로 확장한다.

명령과 설정은 [Flutter 개발 안내](../mobile_flutter/README.md)를 따른다.
