# Pind

한국의 음식점을 취향으로 탐색하는 앱. 현재 제품 기준은 [PRD v3](doc/prd.md)와 Figma 6차 디자인이며, 클라이언트는 **Flutter 전용**, 서버는 **Supabase**다.

## 프로젝트 구조

- `lib/`, `ios/`, `android/`: 프로젝트 루트의 Flutter 클라이언트. 취향 선택·장소 지도/검색/상세.
- `supabase/`: 기존 DB migration, 인증·RLS·Storage, Google Places Edge Function. 이번 단계에서 원격 변경하지 않음.
- 가게 상세의 소개글·항목별 한 줄 평은 `places` Edge Function이 게시물 수가 바뀐 뒤 첫 상세 조회 때 Gemini(`gemini-3.8-flash`)로 백그라운드 생성해 `place_insights`에 저장한다. `GEMINI_API_KEY` 시크릿이 없으면 생성을 건너뛴다.
- `doc/`: 요구사항, 화면 근거, 전환 설계, 실제 검증 상태.

## Flutter 실행

일반 앱의 지도 핀이나 장소 목록을 누르면 새 가게 상세가 열린다. IDE에서는 **Pind — 일반 앱** 구성을 사용한다. `lib/view/preview/detail_preview.dart`는 개발 검증 전용이며 일반 앱 진입점이 아니다.

```sh
flutter pub get
cp config/example.json config/local.json
# local.json에 프로젝트의 공개 클라이언트 설정을 입력
flutter run -t lib/main.dart --dart-define-from-file=config/local.json
# 같은 실행을 키 확인과 함께: scripts/run.sh [ios | device-id] [flutter run 옵션]
```

첫 진입은 로그인부터 취향 선택까지 8단계 온보딩으로 진행한다. 소셜 로그인 호출·세션 연결을 구현했으며, 실제 공급자 콘솔/redirect 설정과 서버 프로필 저장은 [온보딩 안내](doc/onboarding.md)를 따른다. 개발 프로젝트에서 익명 체험을 사용할 때만 `ALLOW_ANONYMOUS_AUTH`를 `"true"`로 설정한다. 앱에 service_role 또는 서버용 Places 키를 넣지 않는다.

네이티브 지도 키, 별도 bundle ID, 테스트 명령은 [지도 설정](doc/google-maps-setup.md) 및 [검증 상태](doc/implementation-status.md)를 따른다.

## 문서

- [PRD v3](doc/prd.md)
- [Figma 화면·요구사항 대응](doc/figma-screen-map.md)
- [기존 프로젝트 전환 및 구현 설계](doc/implementation-design.md)
- [MVC 아키텍처](doc/architecture.md)
- [온보딩 화면·로그인 설정·검증 범위](doc/onboarding.md)
- [구현·검증·남은 작업](doc/implementation-status.md)
- [이전 PRD v2 보관본](doc/archive/prd-v2.md)
- [지도·장소 공급자 설정](doc/google-maps-setup.md)

## 장소 공급자

Google Places를 우선 사용하고 정상 검색 결과가 없거나 사용자가 추가 검색할 때만 카카오·네이버를 보완 조회한다. 보완 장소에는 사진·소개 대신 운영시간 확인 안내와 원본 링크를 제공한다. 보완 API는 서버 키·이용 범위 확인 후 활성화하며, 현재 로컬 구현과 원격 연결 완료는 구분한다.

2026-09-26 사용자 요청으로 React Native/Expo 코드·패키지·빌드 설정을 프로젝트에서 제거했다. 수정 중이던 파일과 로컬 설정은 프로젝트 외부 `../pind-react-native-backup-116Aiw/`에 복구용으로 보존했다. Supabase의 TypeScript Edge Function은 모바일 클라이언트가 아니라 서버 코드이므로 유지한다.

2026-09-26에 새 클라이언트의 실제 장소 연동 테스트까지 통과했다. 초기 서버 일시 장애와 남은 검증은 구현 상태 문서에 기록했다. 소셜 인증·후기·친구 등 전체 제품이나 출시 준비가 완료된 것은 아니다.
