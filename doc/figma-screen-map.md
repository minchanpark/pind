# Figma 6차 디자인 분석

2026-09-26. 파일 AepN5S4XiejtlWS52Q7Arg, 개발용 468:15492, 섹션 531:17779. metadata 전수 조회, 주요 온보딩/지도/시트/작성/프로필 design context와 스크린샷을 확인했다. 읽기 API에서 flowStartingPoints는 없고 연결은 CHANGE_TO 컴포넌트 전환이었다. 전체 화면 이동을 실행 검증한 상태는 아니다.

## 화면 → 구현 단위

2026-09-28에는 아래 온보딩 8단계를 Flutter 일반 앱에 연결하고 iOS 시뮬레이터에서 전체 진행을 검증했다. 최신 구현과 실제 인증/서버 연결의 남은 범위는 [온보딩 안내](onboarding.md)를 따른다.

ID는 모두 531: 접두사. [원본 Figma](https://www.figma.com/design/AepN5S4XiejtlWS52Q7Arg/Pind?node-id=468-15492).

| ID | 화면/상태 | 구현 |
| --- | --- | --- |
| 18341 | 랜딩 | LoginScreen |
| 18621 | 국가 | RegistrationScreen country |
| 20155 | 기본 정보/동의 | RegistrationScreen basic |
| 18681 | 닉네임·아이디 | RegistrationScreen handle |
| 18369 | 위치/나중에 | LocationPermissionScreen |
| 18555 | 기준 3개 순위 (사용자 지정) | Onboarding priorities |
| 18505 | 상황 최대 3개 | Onboarding occasions |
| 18416 | 음식 최소 3개 | Onboarding cuisines |
| 19003 | Discover 커뮤니티 | Discover community |
| 19124 | Discover 친구 | Discover friends |
| 19195 | 친구 없음 | Discover empty |
| 17780 | 지도 | ExploreMap |
| 17856 | 지도 필터 | ExploreMap filter |
| 17930 | 검색 | PlaceSearch |
| 19866 | 상세 축소/사진 | PlaceSheet collapsed |
| 19733 | 소개 펼침 | PlaceSheet expanded/about |
| 18007 | 장소 게시물 | PlaceSheet posts |
| 18108 | 게시물 변형 | 미완성/중복; 별도 기능 도출 안 함 |
| 18716 | 카테고리 부분 목록 | CategorySheet |
| 18822 | 전체 목록 | CategorySheet expanded |
| 19235 | 맛 정렬 | sort=taste |
| 19401 | 양 정렬 | sort=portion |
| 19567 | 분위기 정렬 | sort=ambience |
| 18182 | 작성 초기 | PostComposer empty |
| 18260 | 작성 완료 상태 | PostComposer filled |
| 18118 | 공유 | System share |
| 19957 | 내 지도/취향/뱃지 | Profile map |
| 20051 | 저장/최근 본 | Profile saved |
| 20229 | 내 게시물 | Profile posts |
| 20313 | 전체 저장 | SavedPlaces |

30개 주요 프레임. 설명용 18609/18612/18615/18618은 화면 수에서 제외. 섹션 밖 473:40298은 이전 검색 대안이며 최신 17930 우선.

## 해석

- v2 별점 금지를 최신 3축 평점으로 변경. 기존 글 점수는 합성하지 않는다.
- 음식 화면은 일부 레이어명/실제 이미지 라벨이 다르고 하단이 잘려 있다. 화면에서 확인된 스시·회를 포함한 음식군은 스크롤로 모두 접근하도록 한다.
- Q2/Q4/Q5 이름과 표시 번호 불일치: 위치→선택 기준→상황→음식으로 정리. 중간 CTA ‘다음’, 마지막 완료 CTA.
- ‘양’의 대기시간 설명은 양에 관한 문구로 정정한다.
- 일본 장소/서울 주소, 94%, 45/35/20, 친구 수/뱃지는 예시. 실제 데이터가 없으면 준비 중/미획득.
- 저장은 기본 비공개. 친구 저장 문구는 별도 공개 허용 데이터가 있을 때만.
- 벡터 지도 배경·상태바·Dynamic Island는 실제 SDK/OS가 담당한다. 디자인 전체 이미지를 붙이지 않는다.
- 이전 대안의 AI/RAG/Graph 메모는 후속 검색 실험이며 첫 앱의 선행 인프라로 강제하지 않는다.

## 시각 규칙

402×874 기준, 긴 프레임은 스크롤. 보라 강조(#6300DB 기반 반투명), 노란 선택(#F1FE75), 밝은 회색 표면, 얇은 테두리와 약한 그림자. 내비게이션 273×58, radius 29, blur 12, 4아이콘. 고정 화면 좌표 대신 SafeArea와 레이아웃 제약을 사용한다.

음식 온보딩 사진과 정적 아이콘은 원본 Figma asset을 내려받아 로컬 사용. 장소·사용자 사진은 API 데이터다. SVG 원본 크기/비율을 유지하고 터치 영역은 44pt 이상 확보한다. 402pt 화면 비교와 작은 화면/200% 글씨/로딩/빈 데이터/오류/키보드/뒤로 가기를 검증한다.
