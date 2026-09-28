# 온보딩 구현 — 2026-09-28

일반 앱의 첫 진입은 로그인 → 국가 선택 → 기본 정보 → 닉네임/아이디 → 위치 권한 → 가게 우선순위 3개 → 외식 선호도 → 좋아하는 음식 순서다. 마지막 선택을 저장하면 기존 지도 화면으로 이동한다. 완료한 계정의 기기 기록이 있으면 다음 실행에서 온보딩을 생략한다.

## 디자인과 화면

Figma 파일은 `AepN5S4XiejtlWS52Q7Arg`이며 아래 다섯 화면의 원본 컨텍스트·스크린샷·에셋을 사용했다. 시스템 상태 표시줄과 홈 인디케이터는 운영체제가 표시한다.

| 화면 | Figma 노드 | 구현 |
| --- | --- | --- |
| 로그인 | [531:18341](https://www.figma.com/design/AepN5S4XiejtlWS52Q7Arg/Pind?node-id=531-18341) | 노란 배경, 원본 보라색 경로·PIN, Braah One/Bayon 브랜드 서체, 카카오·Apple·Google 버튼 |
| 국가 | [531:18621](https://www.figma.com/design/AepN5S4XiejtlWS52Q7Arg/Pind?node-id=531-18621) | 국가 검색, 6개 국가, 선택 표시 |
| 기본 정보 | [531:20155](https://www.figma.com/design/AepN5S4XiejtlWS52Q7Arg/Pind?node-id=531-20155) | 이름, 성별, 생년월일, 나이, 필수/선택 동의 |
| 닉네임/아이디 | [531:18681](https://www.figma.com/design/AepN5S4XiejtlWS52Q7Arg/Pind?node-id=531-18681) | 이모지 아바타, `@` 아이디 입력, 형식 검증 |
| 위치 | [531:18369](https://www.figma.com/design/AepN5S4XiejtlWS52Q7Arg/Pind?node-id=531-18369) | 원본 지도 일러스트, 혜택 안내, 위치 허용·건너뛰기·설정 열기 |

취향 선택 세 화면은 기존 디자인과 검증 로직을 재사용한다. 국가·기본 정보·아이디는 1/3~3/3, 취향 선택은 별도로 1/3~3/3을 표시한다. 우선순위는 순서가 있는 정확히 3개, 외식 상황은 최대 3개(선택하지 않아도 진행), 음식은 최소 3개다.

필수 동의와 만 14세 이상 생년월일을 확인한 뒤 기본 정보를 진행할 수 있다. 아이디는 영문·숫자·밑줄 3~20자를 허용하고 소문자로 정규화한다. 사용 가능 표시는 형식 검증 결과이며 중복 검사를 뜻하지 않는다. 위치 요청은 허용 버튼을 누를 때만 실행하며, 거부해도 건너뛰어 지도 검색을 사용할 수 있다. 이전 단계로 이동하면 입력이 유지되고, 윤년 변경으로 유효하지 않게 된 날짜는 해당 월의 마지막 날로 조정한다.

## MVC 연결과 저장 범위

- `model/registration_model.dart`: 계정 식별자, 단계, 기본 정보 draft, 현재 세션의 취향 선택, 검증·진행 상태.
- `controllers/registration_controller.dart`: 인증 상태 구독, 계정별 복원, 단계 이동·저장, 위치 요청, 완료 처리. OAuth 브라우저가 열렸다는 이유로 다음 화면으로 이동하지 않는다.
- `services/auth_service.dart`: Supabase Auth 세션과 OAuth 호출. `services/registration_service.dart`: 계정 ID별 SharedPreferences draft. 위치 SDK 호출은 `services/location_service.dart`가 담당한다.
- `view/onboarding/`: 화면·위젯·에셋 배치. 서비스와 Supabase를 직접 호출하지 않는다. `AppController`가 가입 컨트롤러를 소유하고 `PindApp`이 상태를 구독한다.

앞의 입력 단계는 다음 버튼에서 기기에 저장한다. 취향 선택은 현재 세션에서 이전 화면으로 돌아가도 유지되며, 마지막 완료 버튼에서 기존 `PreferenceService`를 통해 기기에 저장한다. 중복 완료 요청과 다른 계정으로 바뀐 뒤 도착한 위치 응답은 진행 상태에 반영하지 않는다.

이 구현의 완료 상태는 **기기 내 완료**다. Supabase의 계정 프로필·동의·취향 테이블을 수정하거나 서버 완료 RPC를 호출하지 않는다. 서버 저장은 [구현 설계의 데이터 확장](implementation-design.md)에 정의된 계약을 실제 DB와 대조한 뒤 연결해야 한다. 국가/locale/통화는 draft에 기록되며, 앱 전체 언어·통화 전환이나 해외 장소 공급자는 구현하지 않았다. 기본 정보도 현재 추천 점수에 반영되지 않는다.

## 소셜 로그인 설정

`config/local.json`에는 기존 공개 Supabase 설정을 사용한다. `AUTH_REDIRECT_URL`의 기본값은 `com.pind.app://login-callback`이다. iOS URL scheme과 Android VIEW intent filter를 등록했고, SDK의 app_links가 콜백을 처리하도록 Flutter 자체 deeplinking을 비활성화했다.

실제 로그인에는 Supabase Auth의 카카오·Apple·Google 공급자 설정과 해당 앱의 OAuth 자격 증명, redirect allowlist에 `com.pind.app://login-callback` 등록이 필요하다. 공급자별 콘솔 설정과 실제 계정 로그인은 이번 검증에서 수행하지 않았다. 원격 설정과 DB migration도 변경하지 않았다. 리다이렉트 값을 바꾸면 두 플랫폼의 scheme/host 등록도 함께 맞춰야 한다.

로그인 없이 체험하는 버튼은 debug 빌드에서만 표시한다. 백엔드가 있는 경우 `ALLOW_ANONYMOUS_AUTH=true`가 있어야 익명 체험을 제공한다. release 빌드는 이 우회를 제공하지 않으며, 기존 익명 세션만으로 소셜 로그인을 완료한 것으로 취급하지 않는다.

출시 연결에는 아이디 중복 검사·확정 후 불변성, 닉네임 변경 API, 비공개 기본 정보의 본인 전용 저장, 실제 개인정보 처리방침 및 동의 버전/시각 기록, 취향과 가입 완료의 서버 저장이 남아 있다. 현재 동의 상세 문구와 이모지 아바타는 로컬 화면 구현이다.

## 검증과 캡처

`flutter analyze`, 전체 `flutter test`와 iPhone 17 Pro / iOS 26.5의 아래 실행으로 검증한다.

```sh
flutter drive -d <simulator-id> \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/registration_flow_test.dart
```

네이티브 테스트는 가짜 인증 이벤트와 기기 저장소를 주입하고 8단계 진행·완료 후 지도 진입을 확인한다. 실제 소셜 계정, 서버 가입, 실기기 권한 허용을 검증한 결과는 아니다. 단위/위젯 테스트는 인증 완료 전 차단, 계정별 복원, 필수 동의·나이·아이디, 위치 거부와 설정 오류, 비동기 응답·중복 완료, 이전 화면의 선택 유지, 320px 화면/200% 글자 크기와 날짜 조정을 확인한다. 별도 에셋 테스트가 원본 파일·화면별 슬롯·SVG 루트 및 렌더링 크기를 확인한다.

원본 에셋은 `assets/figma`, 브랜드 서체와 OFL 라이선스는 `assets/fonts`에 보관한다. SVG의 HTML backdrop/filter 효과는 Flutter의 blur/shadow로 렌더링하며 벡터 원본과 투명 여백은 변경하지 않았다. 로그인 점선은 두 SVG 렌더러에서 디자인과 간격 차이가 있어 개별 벡터 노드 `531:18360`의 원본 PNG 에셋을 사용한다. 전체 화면 캡처를 구현 에셋으로 사용하지 않는다.

캡처는 테스트 데이터가 들어간 화면이다.

- [로그인](../artifacts/ios/onboarding-qa-login.png), [국가](../artifacts/ios/onboarding-qa-country.png), [기본 정보](../artifacts/ios/onboarding-qa-basic.png), [닉네임/아이디](../artifacts/ios/onboarding-qa-handle.png)
- [위치 권한](../artifacts/ios/onboarding-qa-location.png), [우선순위](../artifacts/ios/onboarding-qa-priorities.png), [외식 선호도](../artifacts/ios/onboarding-qa-occasions.png), [좋아하는 음식](../artifacts/ios/onboarding-qa-cuisines.png)
