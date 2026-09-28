# MVC 아키텍처

앱 코드는 역할별로 `model`, `view`, `controllers`, `services`에 배치한다.

```text
lib/
├── main.dart
├── model/
│   ├── places.dart, place_context.dart, preferences.dart
│   ├── place_search_result.dart
│   ├── registration_model.dart
│   └── app_model.dart, explore_model.dart, place_detail_model.dart,
│       onboarding_model.dart, navigation_model.dart, detail_preview_model.dart
├── view/
│   ├── app.dart, theme.dart
│   ├── explore/
│   ├── navigation/
│   ├── onboarding/
│   └── preview/
├── controllers/
│   ├── app_controller.dart, explore_controller.dart
│   ├── place_detail_controller.dart, onboarding_controller.dart
│   ├── registration_controller.dart
│   └── navigation_controller.dart, detail_preview_controller.dart
└── services/
    ├── config.dart
    ├── auth_service.dart, registration_service.dart
    ├── place_service.dart, place_context_service.dart, preference_service.dart
    ├── location_service.dart, place_action_service.dart
    └── preview/detail_fixture.dart
```

| 역할 | 책임 |
| --- | --- |
| model | 데이터 정의, JSON 변환, 취향 검증·점수 계산, 화면에서 구독하는 ChangeNotifier 상태 |
| view | 화면·위젯·테마, 지도 렌더링, 화면 전환, 컨트롤러에 사용자 이벤트 전달 |
| controllers | 서비스를 통한 조회·저장, 요청 순서·오류 처리, 중복 요청 차단, model 상태 갱신 |
| services | Supabase Edge Function·RPC·테이블 접근, 기기 취향 저장, 위치 조회, 공유·외부 링크 |

조회·저장은 `view → controllers → services → Supabase/기기 기능`으로 진행한다. 서비스 응답을 컨트롤러가 model에 반영하고, view는 model의 알림을 구독해 다시 그린다. model은 controllers·services·view를 참조하지 않는다. services는 model을 참조하며 화면을 참조하지 않는다. view는 서비스나 Supabase를 직접 호출하지 않는다.

`main.dart`에서 Supabase와 기기 저장소를 초기화하고 서비스를 생성해 `AppController`에 주입한다. `PindApp`은 앱 컨트롤러를 소유하고 해제한다. 앱 컨트롤러는 탐색 컨트롤러를 소유하므로 탭 전환과 취향 수정 중에도 지도 데이터가 유지된다. `ExploreScreen`은 탐색 model의 구독만 해제한다.

상세 시트마다 별도 `PlaceDetailController`를 생성하며 시트를 닫을 때 해제한다. 완료된 오래된 요청이나 해제 후 도착한 응답은 상태에 반영하지 않는다. 저장은 낙관적으로 표시하고 실패하면 이전 값으로 되돌린다. `RegistrationController`는 앱 컨트롤러가 소유하며 인증·기본 정보·위치·완료 흐름을 연결한다. 취향 선택의 `OnboardingController`와 탭 컨트롤러는 해당 화면에서 생성·해제한다. 스크롤·지도 플랫폼 컨트롤러 등 렌더링에 필요한 객체는 view가 관리한다.

온보딩 입력과 상태는 `RegistrationModel`에 있고, 인증은 `AuthService`, 계정별 기기 draft는 `RegistrationService`, 위치 권한은 `LocationService`를 통해 접근한다. `view/onboarding/registration_screen.dart`는 로그인·국가·기본 정보·아이디·위치 화면과 기존 취향 선택 세 화면을 순서대로 보여준다. 실제 연결 및 저장 범위는 [온보딩 안내](onboarding.md)를 따른다.

로컬 상세 QA 진입점은 `lib/view/preview/detail_preview.dart`다. `DetailPreviewController`가 `services/preview/detail_fixture.dart`의 가짜 서비스를 연결한다. 운영 진입점인 `main.dart`에서는 이를 생성하지 않는다.

```sh
flutter analyze
flutter test
flutter run -t lib/main.dart --dart-define-from-file=config/local.json
```
