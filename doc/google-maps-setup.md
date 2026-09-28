# Flutter 지도·장소 공급자 설정

클라이언트는 저장소 루트의 Flutter 앱 하나다. React Native/Expo 설정은 제거했다.

## 2026-09-28 Google Cloud Pind 프로젝트 연결

Google 지도·Places의 프로젝트는 `pind` (`inductive-time-509809-p4`, project number `1079540377803`)다. API 주소는 공통 Google 엔드포인트를 사용하고 키의 소속 프로젝트로 요청이 연결된다.

- 앱: 사용자가 변경한 `config/local.json`의 `GOOGLE_MAPS_API_KEY`가 Pind 소속임을 확인했고 iOS 앱을 재빌드했다. 설치 산출물에도 같은 새 키가 들어 있는지 값 노출 없이 비교했다.
- 서버: Pind에 `Pind Places Server` 키를 생성하고 API 사용 범위를 `places.googleapis.com`으로 제한했다. `supabase/functions/.env`와 연결된 Supabase 프로젝트 `mkfgqobwededpzdekvxg`의 `GOOGLE_PLACES_API_KEY`에 적용했다. 로컬 서버 env는 Git 제외·파일 권한 600이며 앱에는 서버 키를 넣지 않는다.
- 활성화: Places API (New), Maps SDK for iOS, Maps SDK for Android. 프로젝트 billing 활성 상태를 확인했다.
- 검증: 새 서버 키로 `places:searchText`에 ID 필드만 요청하여 HTTP 200과 장소 1개를 확인했다. 원격 secret digest가 새 서버 키와 일치하며 변경된 secret이 `GOOGLE_PLACES_API_KEY` 하나뿐인 것도 확인했다. iPhone 17 Pro / iOS 26.5의 지도 SDK 단독 화면에서 포항 지도 타일 표시를 [캡처](../artifacts/ios/google-cloud-pind-map.png)했다. 검증 후 일반 앱 진입점으로 재실행했다. Android는 SDK 활성화를 확인했으며 기기 렌더링은 이번에 검증하지 않았다.

서버 키 분리는 [Google API 키 보안 안내](https://developers.google.com/maps/api-security-best-practices)를 따른다. [Supabase Edge Functions secrets 안내](https://supabase.com/docs/guides/functions/secrets)에 따라 secret 변경은 재배포 없이 기존 함수에 적용된다.

## 앱 실행

```sh
flutter pub get
# config/local.json이 없을 때만 config/example.json을 복사해 설정한다.
flutter run --dart-define-from-file=config/local.json
```

`config/local.json`은 Git에서 제외한다. `SUPABASE_URL`, 공개 `SUPABASE_PUBLISHABLE_KEY`, OS별 제한된 `GOOGLE_MAPS_API_KEY`를 넣는다. 개발 익명 인증은 `ALLOW_ANONYMOUS_AUTH`로 명시적으로 허용한다.

- iOS Maps SDK 키 제한: `com.pind.app`.
- Android Maps SDK 키 제한: `com.pind.app`와 해당 서명 인증서.
- Places API 서버 키와 service_role은 앱에 넣지 않는다.
- 실제 Google 지도가 비어 있으면 Maps SDK 활성화, billing, OS/API 제한, 현재 bundle ID를 확인한다. PIN이 표시돼도 지도 타일 정상 로드를 증명하지 않는다.

2026-09-27: iOS의 Debug/Profile/Release, Android의 namespace/applicationId와 MainActivity 패키지를 `com.pind.app`으로 통일했다. RunnerTests는 `com.pind.app.RunnerTests`다. iOS 시뮬레이터 빌드·설치 ID와 지도 타일 표시, Android debug APK의 application ID/launchable activity를 확인했다. Android 지도 실기기·서명·전용 키는 별도 확인이 필요하다. 기존 ID 앱의 데이터가 새 앱으로 자동 이전되지는 않는다.

## 서버

`supabase/functions/.env.example`은 값 없는 템플릿이다. 실제 키는 Supabase Edge Function secrets로 관리한다.

| 설정 | 용도 |
| --- | --- |
| `GOOGLE_PLACES_API_KEY` | 기존 Google 검색·상세·사진 |
| `LOCAL_PLACES_PROVIDERS` | 기본 빈 값(보완 검색 꺼짐), 검토 후 `kakao` 또는 `kakao,naver` |
| `KAKAO_LOCAL_REST_API_KEY` | 카카오 Local REST API |
| `NAVER_LOCAL_CLIENT_ID`, `NAVER_LOCAL_CLIENT_SECRET` | NAVER API HUB 인증; 구형 Naver Search API 키와 구분 |

함수 이름은 하위 호환을 위해 `google-places`를 유지한다. 새로운 `supplemental` action과 Google `search`의 `allowSupplemental` 처리는 수정된 함수를 배포해야 적용된다. 원격 배포/키 등록/공급자 이용권한 확인을 로컬 테스트 성공으로 대신하지 않는다.

보완 정보는 목록·상세·원본 링크에만 사용한다. 사진/설명/운영시간을 추정하지 않으며 Google 지도 위 보완 PIN, AI 입력, 영구 저장·게시물 연결은 이용권한 검토 후 별도 확장한다.

## 오프라인 검증

```sh
node --experimental-strip-types --test supabase/functions/google-places/local-places.test.ts
flutter analyze
flutter test
```

위 테스트는 네이버·카카오의 실제 인증·응답·요금·원격 배포를 검증하지 않는다. 공급자 키 없이 mock 데이터로 계약과 오류 처리를 검증한다.
