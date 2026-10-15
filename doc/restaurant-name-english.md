# 게시물 식당 검색: 영어 이름 저장 설계와 20개 평가

2026-10-05. 초기 1·2차는 프롬프트 설계와 NVIDIA API 실측 평가만 수행했다. 이후 같은 20개를 3번 실행해 가장 적합한 후보만 `name_en`에 저장하는 스크립트를 추가했다. 앱 검색/표시 및 Edge Function 배포는 이 작업 범위에 포함하지 않는다. 실제 저장 결과는 아래 3회 실행 기록에 남긴다.

## 이름 규칙

- 한국 이름은 의미 번역보다 국어의 로마자 표기법에 따른 음역을 우선한다. 음식명·업종명도 한국 상호의 일부이면 음역한다. `일품대패 → Ilpum Daepae`, `고향식당 → Gohyang Sikdang`.
- 한글로 적힌 외래어는 원래 철자 또는 영어에서 통용되는 표기로 복원한다. `그레그커피 → Greg Coffee`, `굿베이커리 → Good Bakery`, `갈스시 → Gal Sushi`. `Keopi`처럼 외래어를 다시 음역하지 않는다.
- 확실히 아는 공식 영문 브랜드명을 우선한다. 모르는 공식 철자를 추측하지 않는다. 지점은 생략하지 않는다.
- 이미 있는 라틴 문자·숫자는 유지한다. 이름에 없는 업종 설명이나 재료명을 붙이지 않는다. 단순 음역으로 외국어 표현을 복원하기 어려운 부분만 적절하게 옮긴다.
- 영어 이름 하나만 생성한다. 일본어·중국어 이름을 별도 생성하거나 저장하지 않는다. 이 규칙은 식당명에만 적용한다.

## 저장·검색에 연결할 때

기존 `public.places.name_ko`에는 원문을 보존하고 `name_en`에는 영어 결과만 저장한다. `name_en`이 비어 있거나 한글을 포함하면 미처리 상태로 간주한다. 외부 공급자의 영어 철자가 검증되어 있다면 그 표기를 보존한다. Google의 식별자 전용 레코드는 기존 제약에 따라 이름을 저장하지 않는다.

현재 조회 SQL은 `name_ko`를 표시하고 한국어 이름·주소로 검색한다. 번역 값을 저장하는 것만으로 앱이 영어 이름을 보여주거나 영어 검색을 지원하지는 않는다. 연결 단계에서는 다음을 함께 변경해야 한다.

1. 기존 공개 카탈로그를 작은 배치로 처리하고, 신규/변경 상호는 가져오기 단계에서 번역한다. 결과는 장소 ID와 입력 원문이 여전히 일치할 때만 `name_en`에 저장한다. 이름이 바뀌면 이전 번역을 재사용하지 않는다.
2. 검색은 저장된 `name_ko`와 `name_en`을 함께 조회한다. 한국어 UI는 한국어 이름, 그 외 UI는 저장된 영어 이름을 표시하며 미처리 결과는 원문으로 대체한다. 최근 방문·저장한 곳의 로컬 필터도 두 이름으로 검색한다. 주소 검색은 기존 규칙을 유지한다.
3. `import_sbiz_places`는 현재 `name_en`에 한국어 원문을 넣고 재가져오기 시 덮어쓴다. 동일 상호의 기존 영어 결과는 보존하고 상호 변경 시만 무효화하도록 수정해야 한다.
4. 검색 타이핑마다 모델을 호출하지 않는다. 모델 실패·유효성 검증 실패 시 영어 값을 저장하지 않고 원문 검색을 유지한다. 키는 서버 환경변수로만 사용한다.

이번 평가의 키는 저장소 `.env`의 `NVDIA_API_KEY`다. 정확한 키 이름을 그대로 지원하며 `NVIDIA_API_KEY`도 사용할 수 있다. 모델 대체나 Gemini/Groq fallback은 없다.

## 실제 요청과 재현

모델은 `deepseek-ai/deepseek-v4.1-flash`, 엔드포인트는 NVIDIA의 `https://integrate.api.nvidia.com/v1/chat/completions`다. [NVIDIA 모델 페이지](https://build.nvidia.com/deepseek-ai/deepseek-v4.1-flash/build)에서 모델 ID와 API 주소를 확인했다. [DeepSeek thinking 설정](https://api-docs.deepseek.com/guides/thinking_mode/)에 맞춰 `thinking: {type: 'disabled'}`를 보내고 NVIDIA 요청에는 `chat_template_kwargs: {enable_thinking: false}`도 명시한다.

응답에 reasoning 내용, `<think>` 태그 또는 0보다 큰 reasoning 토큰 수가 있으면 실패 처리한다. 개수·순서·원문·영어 문자 검증을 통과해야 결과 파일을 만든다. JSON은 `ko`와 `en`만 허용한다. reasoning을 숨기기만 하는 설정으로 대체하지 않는다.

```sh
node scripts/eval_name_english.mjs --out artifacts/name-english-20261005/recheck.json
node --test supabase/functions/places/names-en.test.ts supabase/functions/places/names.test.ts
```

- 프롬프트/요청/파서: `supabase/functions/places/names-en.ts`
- 사전에 정한 20개 실제 장소 ID·원문·허용 답: `supabase/functions/places/name_english.golden.json`
- 운영 DB에서 읽은 후보 근거: `artifacts/name-english-20261005/selected-candidates.json`
- 1차 요청/응답/평가: `artifacts/name-english-20261005/results{,.request,.response}.json`
- 2차 요청/응답/평가: `artifacts/name-english-20261005/results-v2{,.request,.response}.json`

20개는 공개된 SBIZ/PIND 카탈로그의 서로 다른 상호다. 사용자 예시 `일품대패`와 DB 원문 `그레그커피`를 포함하고, 한국 음식·식당명 및 외래어·브랜드 유형을 섞었다. 허용 답은 API 호출 전에 고정했다. 공백·대소문자·하이픈·라틴 악센트 차이는 점수에 영향을 주지 않는다. 브랜드의 공식 철자를 외부 확인했다는 의미는 아니다. 사용자 예시 2개는 규칙 확인용으로 프롬프트에도 있으며 나머지 18개는 적용 결과를 확인한다.

## 평가 결과

1차는 18/20(90%)였다. `Eommasong Kalguksu`는 원문 `엄마손칼국수`에 없는 받침을 추가했고, `Wonjo Halmai Gukbap`은 `원조할매국밥`의 `ㅐ` 표기가 틀렸다. 음식·업종의 과잉 의미 번역이나 `Coffee`의 재음역은 발생하지 않았다. 응답 reasoning 내용 없음, reasoning 토큰 0. 646 입력 + 325 출력 = 971 토큰, 요청부터 결과까지 약 33.4초였다.

2차에서는 정답 목록을 그대로 유지하고 일반 표기 규칙(ㅐ→ae, 불필요한 ng 금지)을 프롬프트에 추가했다. 결과는 다시 18/20(90%)였다. `원조할매국밥`은 교정됐지만 `엄마손칼국수 → Eommasom Kalguksu`, `수냉면 → Sunangmyeon`이 기준에 맞지 않았다. 응답 reasoning 내용 없음, reasoning 토큰 0. 784 입력 + 324 출력 = 1,108 토큰, 약 53.4초. 두 실행에서 오류 사례가 달라져 음역의 안정성은 확보하지 못했다. 1차 결과 파일은 비교용으로 보존했다.

초기 두 실행 모두 API에 20개 전체를 한 번에 보내 평가했다. API 오류 시 모델을 바꾸거나 thinking을 켜지 않는다. 문자열 형식 검증을 통과한 결과도 실제 음역이 틀릴 수 있으므로, 초기 결과를 그대로 일괄 DB 저장하지 않았다. 3회 후보 선정에서는 사전에 검토한 허용 이름을 기준으로 이런 오류를 제외한다.

### 같은 20개를 3번 실행하고 가장 적합한 후보만 저장

```sh
node scripts/save_best_name_english.mjs          # 3회 실행 + 선정 결과/SQL 파일만 저장
node scripts/save_best_name_english.mjs --apply  # 3회 실행 + 선정 + DB 저장 + 재조회 검증
node --test scripts/save_best_name_english.test.mjs supabase/functions/places/names-en.test.ts supabase/functions/places/names.test.ts
```

- 동일한 프롬프트와 20개 원문으로 독립된 NVIDIA 요청 3개를 보낸다. 기존 초기 1·2차 응답은 이번 3회 후보에 섞지 않는다. reasoning을 끄고 세 응답의 reasoning 토큰이 모두 0인지 확인한다.
- 상호마다 사전에 정한 허용 답과 맞는 후보만 남긴다. 허용 답의 선호 순서, 같은 정상 답의 출현 횟수, 정확한 표기 형식 순으로 고른다. 잘못된 답이 다수여도 한 번 나온 올바른 답을 우선한다.
- 저장하는 이름은 반드시 세 모델 응답 중 실제로 나온 이름이다. 세 번 모두 틀리면 저장하지 않으며 정답 목록의 이름을 임의로 넣지 않는다.
- 프로젝트 `Pind`와 정확한 20개 장소 ID를 확인한다. `name_ko`와 기존 `name_en`이 조회 당시와 같은 행만 수정해 동시 수정이나 상호 변경을 덮어쓰지 않는다. 한국어 원문은 수정하지 않는다.
- 실행마다 별도 디렉터리에 3개 요청·응답·평가, 선정 결과, 저장 SQL, 저장 전/후 DB 값을 남긴다. 업데이트 후 실제 `name_en`을 다시 조회해 선정값과 일치하는지 확인한다.

이 스크립트는 검토한 20개에 대한 선정·저장 실험이다. 새로운 임의의 상호까지 정확히 평가하는 범용 판정기가 아니며, 평가셋을 확대할 때는 해당 이름의 허용 표기를 먼저 검토해야 한다. 선정·오류 제외·동시 수정 보호 및 기존 이름 파서를 확인하는 로컬 테스트 10개가 통과했다.

이 20개 평가만으로 모든 상호의 정확성이나 운영 검색 통합을 검증한 것은 아니다. 지점 접미사·숫자·띄어쓰기 변형·덜 알려진 브랜드는 추가 평가 대상이다.

요청의 thinking 비활성화, reasoning 응답 거부, 잘못된 원문·순서·개수·다른 언어 응답 거부 및 기존 이름 파서를 확인하는 로컬 테스트 6개가 통과했다.

### 2차 20개 결과

| 장소 ID | 원문 | 모델 결과 | 평가 |
|---|---|---|---|
| 59989 | 일품대패 | Ilpum Daepae | 통과 |
| 146764 | 그레그커피 | Greg Coffee | 통과 |
| 10547 | 엄마손칼국수 | Eommasom Kalguksu | 오류: Eommason Kalguksu |
| 148809 | 원조할매국밥 | Wonjo Halmae Gukbap | 통과 |
| 101706 | 봉자막창 | Bongja Makchang | 통과 |
| 68441 | 가화반점 | Gahwa Banjeom | 통과 |
| 6921 | 고향식당 | Gohyang Sikdang | 통과 |
| 7858 | 삼거리식당 | Samgeori Sikdang | 통과 |
| 25672 | 수냉면 | Sunangmyeon | 오류: Su Naengmyeon |
| 62363 | 갈스시 | Gal Sushi | 통과 |
| 111976 | 뉴버거 | New Burger | 통과 |
| 22915 | 굿베이커리 | Good Bakery | 통과 |
| 13662 | 고피자 | Go Pizza | 통과 |
| 26057 | 꽉치킨 | Kkwak Chicken | 통과 |
| 11487 | 블루문 | Blue Moon | 통과 |
| 115050 | 몽브런치 | Mong Brunch | 통과 |
| 135023 | 스타벅스 강변 | Starbucks Gangbyeon | 통과 |
| 10185 | 투썸 | Twosome | 통과 |
| 7197 | 카페 | Cafe | 통과 |
| 25024 | 커피 | Coffee | 통과 |

## 3회 실행 및 실제 DB 저장 기록

- 실행: `best-of-three-2026-10-05T08-34-00-279Z` (2026-10-05).
- 회차별 기준 통과: **19/20, 19/20, 18/20**.
- 합쳐서 선정: **19개**, 저장 및 재조회 일치: **19개**, 제외: **1개**.
- 세 실행 모두 reasoning 내용 없음, reasoning 토큰 **0**.
- `엄마손칼국수`는 1·3회에서 `Eommasong Kalguksu`, 2회에서 `Eommasom Kalguksu`였으므로 제외했다. 사전 정답 `Eommason Kalguksu`를 모델 결과인 것처럼 저장하지 않았다.
- 20개 한국어 원문을 모두 보존했으며 제외한 행의 기존 `name_en`도 유지했다.
- 저장 전/후 값과 각 회차 원본 응답은 `artifacts/name-english-20261005/best-of-three-2026-10-05T08-34-00-279Z/`에 보존했다.

| 장소 ID | 원문 | 저장한 영어 이름 | 출처 회차 |
|---|---|---|---|
| 59989 | 일품대패 | Ilpum Daepae | 1 |
| 146764 | 그레그커피 | Greg Coffee | 1 |
| 10547 | 엄마손칼국수 | 저장 제외 | - |
| 148809 | 원조할매국밥 | Wonjo Halmae Gukbap | 1 |
| 101706 | 봉자막창 | Bongja Makchang | 1 |
| 68441 | 가화반점 | Gahwa Banjeom | 1 |
| 6921 | 고향식당 | Gohyang Sikdang | 1 |
| 7858 | 삼거리식당 | Samgeori Sikdang | 1 |
| 25672 | 수냉면 | Su Naengmyeon | 1 |
| 62363 | 갈스시 | Gal Sushi | 1 |
| 111976 | 뉴버거 | New Burger | 1 |
| 22915 | 굿베이커리 | Good Bakery | 1 |
| 13662 | 고피자 | Go Pizza | 1 |
| 26057 | 꽉치킨 | Kkwak Chicken | 1 |
| 11487 | 블루문 | Blue Moon | 1 |
| 115050 | 몽브런치 | Mong Brunch | 1 |
| 135023 | 스타벅스 강변 | Starbucks Gangbyeon | 1 |
| 10185 | 투썸 | Twosome | 1 |
| 7197 | 카페 | Cafe | 1 |
| 25024 | 커피 | Coffee | 1 |
