# 새로운 식당 100개: 영어 이름 생성 방식 비교

실행 완료: 2026-10-05T09:03:16.164Z. 운영 DB에는 적용하지 않았다.

동일한 실제 카탈로그 100개를 각 방식으로 3번씩 처리했다. 기존 20개 상호는 제외했다. NVIDIA `deepseek-ai/deepseek-v4.1-flash`를 사용했고 24개 요청 모두 thinking을 껐다. 25개씩 배치 처리해 총 600개 이름 응답을 평가했다.

## 비교 결과

| 방식 | 1회 | 2회 | 3회 | 300개 응답 기준 통과 | 3회 중 정상 후보 존재 | 다수결 정답 |
|---|---:|---:|---:|---:|---:|---:|
| 기존: LLM 전체 이름 생성 | 86/100 | 90/100 | 89/100 | 265/300 (88.3%) | 92/100 | 85/100 |
| 혼합: LLM 분류 + 규칙 음역 | 74/100 | 72/100 | 76/100 | 222/300 (74.0%) | 83/100 | 74/100 |

혼합 방식 수치는 처리 코드 수정 후 **동일한 원본 모델 응답을 재처리한 값**이다. 처음에는 공백 literal 조각을 잘못 거부하고, Coffee/Cafe 사전을 restore 조각에만 적용했다. 공백 조각 허용과 기존 공통 외래어 사전의 적용 범위를 수정했다. 모델 프롬프트, 사전의 항목, 허용 답은 바꾸지 않았고 추가 API 호출도 하지 않았다.

수정 전 혼합 방식: 회차별 40/100, 52/100, 54/100, 3회 중 정상 후보 57/100. 초기 처리 결과는 원래 실행 디렉터리에 보존했다. 이 수정은 결과를 확인한 뒤 이루어졌으므로, 수정된 구현에 대한 완전히 새로운 검증셋 실험으로 해석해서는 안 된다.

“3회 중 정상 후보 존재”는 사전에 정한 허용 답을 사용해 고른 결과다. 새로운 상호의 정답을 모르는 상태에서 자동으로 이 정확도를 달성한다는 의미가 아니다. 다수결 정답은 같은 이름이 두 번 이상 나온 후보만 고르며, 잘못된 철자가 반복되면 실패로 계산한다.

## 유형별 비교

| 유형 | 장소 수 | 기존 3회 응답 기준 통과 | 혼합 3회 응답 기준 통과 | 기존 정상 후보 존재 | 혼합 정상 후보 존재 |
|---|---:|---:|---:|---:|---:|
| 한국어 음역 | 25 | 72/75 | 75/75 | 24/25 | 25/25 |
| 외래어 포함 | 45 | 118/135 | 96/135 | 41/45 | 39/45 |
| 지점명 포함 | 20 | 48/60 | 37/60 | 18/20 | 14/20 |
| 영문·숫자 포함 | 10 | 27/30 | 14/30 | 9/10 | 5/10 |

## 평가 기준과 한계

- 샘플은 공개된 SBIZ/PIND 카탈로그에서 상호별 한 장소를 추출했다. 고정 문자열의 MD5 순서로 한국어 후보 40개, 외래어 후보 30개, 지점명 20개, 영문·숫자 10개를 선정했다. 이름을 검토한 뒤 실제 유형은 한국어 25개, 외래어 45개, 지점명 20개, 영문·숫자 10개로 분류했다.
- 허용 표기는 모든 API 호출 전에 작성·고정했다. 모델 요청에는 원문 이름만 전달하며 허용 답, 평가 그룹, 정답 목록은 넣지 않았다. 전체 100개 이름에 대한 사전 매핑을 혼합 구현에 넣지도 않았다.
- 점수는 음역 우선·외래어 복원 정책에 대한 사전 허용 표기와 비교한 것이다. 100개 상호의 공식 영문명을 모두 외부 확인한 정답셋은 아니다. 출처 철자나 조각 경계가 불명확한 10개는 별도로 표시했다.
- 대소문자·공백·구두점·라틴 악센트는 무시하고 `and`와 `&`는 동등하게 비교한다. 지점 위치를 보존하면 Branch 접미사 생략도 허용한다. 의미 번역으로 한국 상호를 바꾸거나 없는 글자를 더하는 것은 허용하지 않는다.
- 기존 프롬프트는 이전 실험의 v2 그대로다. 혼합 방식은 LLM이 romanize/restore/literal 조각만 만들고, 한국어 조각은 `koroman@1.0.16`이 변환한다. Coffee/Cafe 등 공통 외래어 사전이 복원 철자를 보정한다. 이번 결과를 본 뒤 프롬프트나 허용 표기를 변경해 재평가하지 않았다.
- 구조 검증 오류도 실패에 포함한다. 누락·추가 글자, 원문 불일치, 잘못된 조각 유형은 생성 이름으로 채택하지 않는다.

허용 표기 파일 SHA-256: `0f21bf0dc2af7ebc0957a95e13f42248c7117dc3fc269c16fe39863b41308f36`. reasoning 토큰 합계: **0**. 입력 18,996토큰, 출력 21,970토큰.

[음역 라이브러리 구현과 규칙](https://github.com/gerosyab/koroman) · [국어의 로마자 표기법](https://www.law.go.kr/admRulLsInfoP.do?admRulId=28477&efYd=0)

## 출처가 불명확한 10개를 제외한 결과

- 기존: LLM 전체 이름 생성: 3회 중 정상 후보 83/90. 구조 검증 오류 0/300. 다수결 후보 없음 7/100.
- 혼합: LLM 분류 + 규칙 음역: 3회 중 정상 후보 78/90. 구조 검증 오류 0/300. 다수결 후보 없음 3/100.

## 혼합 방식에서 정상 후보가 새로 나온 이름

- 구이랑탕이랑최우영복집: 기존 Guirang Tangirang Choe Wooyoung Bokjip / Guirang Tangirang Choe Wooyoung Bokjip / Guirang Tangirang Choe Wooyoung Bokjip → 혼합 Guirang Tangirang Choeuyeong Bokjip
- 쇼콜라윰: 기존 Chocolayum / Chocolayum / Chocolayum → 혼합 Chocolat Yum
- 카페오로시: 기존 Cafe Oroshi / Cafe Oroshi / Cafe Oroshi → 혼합 Cafe Orosi
- 종국이두마리치킨: 기존 Jonggugi Two Mari Chicken / Jongguki Two Mari Chicken / Jongguki Two Mari Chicken → 혼합 Jonggugi Dumari Chicken
- 영자's곱창: 기존 Youngja's Gopchang / Youngja's Gopchang / Youngja's Gopchang → 혼합 Yeongja 's Gopchang
- 수내닭꼬치구청점 동대문: 기존 Sunae Dakkochi Gucheongjeom Dongdaemun / Sunae Dakkochi Gucheng Dongdaemun / Sunae Dakkochi Guchung Branch Dongdaemun → 혼합 Sunaedakkkochi Gucheong Branch Dongdaemun

## 기존 방식만 정상 후보를 만든 이름

- 메이게츠한양대: 기존 Meigetsu Hanyangdae → 혼합 Meigecheu Hanyangdae / Meigecheu Hanyangdae / Maygetsu Hanyangdae
- 로컬팟: 기존 Local Pot → 혼합 Local Pat / Local Pat / local Pat
- 키즈카페폭스맘: 기존 Kids Cafe Fox Mom → 혼합 Kijeu Cafe Pokseumam / Kijeu Cafe Pokseumam / Kijeu Cafe Pokseumam
- 엠커피: 기존 M Coffee → 혼합 Em Coffee / Em Coffee / Em Coffee
- 폴룩스커피: 기존 Pollux Coffee → 혼합 Pollukseu Coffee / Pollukseu Coffee / Pollukseu Coffee
- 원투쓰리PCCAFE: 기존 One Two Three PC Cafe → 혼합 Wontusseuri PCCAFE / Wontusseuri PCCAFE / Wontusseuri PCCAFE
- 커피다스1리터: 기존 Coffee Das 1 Liter → 혼합 Coffee Daseu 1 Liter / Coffee Daseu 1 Liter / Coffee Daseu 1 Liter
- 블라BLA: 기존 Bla BLA → 혼합 Beulla BLA / Beulla BLA / Beulla BLA
- 우밴드7080라이브: 기존 U Band 7080 Live → 혼합 Ubaendeu 7080 Live / Ubaendeu 7080 Raibeu / Ubaendeu 7080 Live
- 스타벅스 도봉로DT: 기존 Starbucks Dobong-ro DT → 혼합 Starbucks Dobongno DT / Starbucks Dobongno DT / Starbucks Dobongno DT
- 페트리코파트너스창경궁점: 기존 Petrichor Partners Changgyeonggung Branch → 혼합 Peteurikopateuneoseu Changgyeonggung Branch / Peteurikopateuneoseu Changgyeonggung Branch / PetriCo Partners Changgyeonggung Branch
- 서울브루어리성 수지점: 기존 Seoul Brewery Seongsu Branch → 혼합 Seoulbeurueoriseong Suji Branch / Seoulbeurueoriseong Suji Branch / Seoulbeurueori Seong Suji Branch
- 마츠노하나신세계명동점 백화점: 기존 Matsunohana Shinsegae Myeongdong Department Store → 혼합 Macheunohana Shinsegae Myeongdong Branch Baekwajeom / Macheunohana Shinsegae Myeongdong Branch Baekwajeom / Matsunohana Shinsegae Myeongdong Branch Baekwajeom
- 에코사랑목 본점: 기존 Eco Sarangmok Main Branch → 혼합 Ekosarangmok Main Branch / Ekosarangmok Main Branch / Ekosarangmok Main Branch
- 도송에프엔비브이엔디종각 직영점: 기존 Dosong F&B VND Jonggak Direct Branch → 혼합 Dosong Epeuenbibeuiendi Jonggak Company-owned Branch / Dosong F&B VND Jonggak Company-owned Branch / Dosong F&B VND Jonggak Jingnyeong Branch

## 100개 전체 결과

| 장소 ID | 원문 | 유형 | 기존 3회 중 정상 후보 | 혼합 3회 중 정상 후보 | 출처 모호 |
|---|---|---|---|---|---|
| 17981 | 라인에프앤씨 | 외래어 포함 | Line F&C | Line F&C |  |
| 14239 | 면곡뼈다귀감자탕 | 한국어 음역 | Myeongok Ppyeodagwi Gamjatang | Myeongok Ppyeodagwi Gamjatang |  |
| 80718 | 빈스앤와플 | 외래어 포함 | Beans & Waffle | Beans & Waffle |  |
| 13824 | 서퍼스포케 | 외래어 포함 | Surfer's Poke | Surfers Poke |  |
| 132111 | 화양뭉티기 | 한국어 음역 | Hwayang Mungtigi | Hwayang Mungtigi |  |
| 125119 | 메이게츠한양대 | 외래어 포함 | Meigetsu Hanyangdae | — | 예 |
| 17754 | 카펜터스 | 외래어 포함 | Carpenters | Carpenters |  |
| 5706 | 푸드몽 | 외래어 포함 | Food Mong | Food Mong |  |
| 38816 | 여수해변 | 한국어 음역 | Yeosu Haebyeon | Yeosu Haebyeon |  |
| 28268 | 공화식당 | 한국어 음역 | Gonghwa Sikdang | Gonghwa Sikdang |  |
| 46448 | 거제식당 | 한국어 음역 | Geoje Sikdang | Geoje Sikdang |  |
| 53353 | 일미손칼국수 | 한국어 음역 | Ilmi Son Kalguksu | Ilmi Son Kalguksu |  |
| 129039 | 삼전생고기 | 한국어 음역 | Samjeon Saenggogi | Samjeon Saenggogi |  |
| 66516 | 고래당 | 한국어 음역 | Goraedang | Goraedang |  |
| 52310 | 구이랑탕이랑최우영복집 | 한국어 음역 | — | Guirang Tangirang Choeuyeong Bokjip |  |
| 86381 | 아시바클럽 | 외래어 포함 | Asiba Club | Asiba Club | 예 |
| 30974 | 신흥식당 | 한국어 음역 | Sinheung Sikdang | Sinheung Sikdang |  |
| 147332 | 김해숯불뒷고기 | 한국어 음역 | Gimhae Sutbul Dwitgogi | Gimhae Sutbul Dwitgogi |  |
| 77940 | 풍년곱창 | 한국어 음역 | Pungnyeon Gopchang | Pungnyeon Gopchang |  |
| 60051 | 릴렉세이션포인트 | 외래어 포함 | Relaxation Point | relaxation point |  |
| 31550 | 고대로찌개집 | 한국어 음역 | Godae Ro Jjigaejip | Godaero Jjigaejip |  |
| 8346 | 고래즉석떡볶이 | 한국어 음역 | Gorae Jeukseok Tteokbokki | Gorae Jeukseok Tteokbokki |  |
| 18915 | 남매양꼬치 | 한국어 음역 | Nammae Yangkkochi | Nammae Yangkkochi |  |
| 41265 | 대청플레이스 | 외래어 포함 | Daecheong Place | Daecheong Place |  |
| 32104 | 반기다 | 한국어 음역 | Bangida | Bangida |  |
| 69774 | 쇼콜라윰 | 외래어 포함 | — | Chocolat Yum |  |
| 60369 | 에스따떼젤라또 | 외래어 포함 | Estate Gelato | Estate Gelato |  |
| 113875 | 로컬팟 | 외래어 포함 | Local Pot | — | 예 |
| 14069 | 아빠애식탁 | 한국어 음역 | Appaae Siktak | Appaae Siktak |  |
| 117135 | 디저트다운 | 외래어 포함 | Dessert Down | Dessert Down | 예 |
| 68455 | 동심네토종꺼먹돼지 | 한국어 음역 | Dongsimne Tojong Kkeomeok Dwaeji | Dongsimne Tojong Kkeomeokdwaeji |  |
| 18722 | 을지골뱅이 | 한국어 음역 | Eulji Golbaengi | Eulji Golbaengi |  |
| 9343 | 영동원삼겹살 | 한국어 음역 | Yeongdongwon Samgyeopsal | Yeongdongwon Samgyeopsal |  |
| 94125 | 낙지야왜조개 | 한국어 음역 | Nakjiya Wae Jogae | Nakjiya Waejogae |  |
| 100982 | 황제보쌈냉면칼국수 | 한국어 음역 | Hwangje Bossam Naengmyeon Kalguksu | Hwangje Bossam Naengmyeon Kalguksu |  |
| 29544 | 다보분식 | 한국어 음역 | Dabo Bunsik | Dabo Bunsik |  |
| 142645 | 플러터 | 외래어 포함 | Flutter | Flutter |  |
| 9690 | 동산식당 | 한국어 음역 | Dongsan Sikdang | Dongsan Sikdang |  |
| 86053 | 메종드쌍문 | 외래어 포함 | Maison de Ssangmun | Maison de Ssangmun |  |
| 147054 | 청도한우갈비 | 한국어 음역 | Cheongdo Hanwoo Galbi | Cheongdo Hanu Galbi |  |
| 49680 | 강동커피，호프 | 외래어 포함 | Gangdong Coffee, Hof | Gangdong Coffee ， Hof |  |
| 115343 | 카페무드 | 외래어 포함 | Cafe Mood | Cafe Mood |  |
| 104372 | 커피볶는아침컴퍼니 | 외래어 포함 | Coffee Bongneun Achim Company | Coffee Bongneun Achim Company |  |
| 44091 | 카페오로시 | 외래어 포함 | — | Cafe Orosi |  |
| 152465 | 양덕베이커리 | 외래어 포함 | Yangdeok Bakery | Yangdeok Bakery |  |
| 112596 | 피프틴커피&아이스크림 | 외래어 포함 | Fifteen Coffee & Ice Cream | Fifteen Coffee & Ice Cream |  |
| 36649 | 카페빌라드그릭 | 외래어 포함 | Cafe Villa de Greek | Cafe Villa de Greek | 예 |
| 56010 | 커피의향기 | 외래어 포함 | Coffee ui Hyanggi | Coffee Ui Hyanggi |  |
| 148993 | 프레그런스커피 | 외래어 포함 | Fragrance Coffee | Fragrance Coffee |  |
| 24528 | 커피셀러 | 외래어 포함 | Coffee Seller | Coffee Seller | 예 |
| 36011 | 키즈카페폭스맘 | 외래어 포함 | Kids Cafe Fox Mom | — |  |
| 46874 | 카페꾸오레 | 외래어 포함 | — | — | 예 |
| 9334 | 커피거리 | 외래어 포함 | Coffee Geori | Coffee Geori |  |
| 13110 | 타임파스타 | 외래어 포함 | Time Pasta | Time Pasta |  |
| 99865 | 춘홍커피호프 | 외래어 포함 | Chunhong Coffee Hof | Chunhong Coffee Hof |  |
| 72694 | 지지보드게임카페 | 외래어 포함 | Jiji Board Game Cafe | Jiji Board Game Cafe |  |
| 132466 | 북카페담비 | 외래어 포함 | Book Cafe Dambi | Book Cafe Dambi |  |
| 90774 | 스타벅스 건국클래식 | 외래어 포함 | Starbucks Geonguk Classic | Starbucks Geonguk Classic |  |
| 44478 | 스시다마스토어 | 외래어 포함 | Sushi Dama Store | Sushi Dama Store |  |
| 151154 | 종국이두마리치킨 | 외래어 포함 | — | Jonggugi Dumari Chicken |  |
| 70402 | 엠커피 | 외래어 포함 | M Coffee | — |  |
| 89921 | 백궁커피호프 | 외래어 포함 | Baekgung Coffee Hof | Baekgung Coffee Hof |  |
| 39118 | 브라질커피숍 | 외래어 포함 | Brazil Coffee Shop | Brazil Coffee Shop |  |
| 12293 | 테이퍼드커피스탠드 | 외래어 포함 | Tapered Coffee Stand | Tapered Coffee Stand |  |
| 20249 | 정군비어 | 외래어 포함 | Jeonggun Beer | Jeonggun Beer |  |
| 87982 | 스타벅스 현대미아 | 외래어 포함 | Starbucks Hyundai Mia | Starbucks Hyeondae Mia |  |
| 97225 | 폴룩스커피 | 외래어 포함 | Pollux Coffee | — |  |
| 32225 | 비어시티 | 외래어 포함 | Beer City | Beer City |  |
| 139086 | 오리지널쿡앤커피 | 외래어 포함 | Original Cook & Coffee | Original Cook & Coffee |  |
| 6677 | 더컴포트커피 | 외래어 포함 | The Comfort Coffee | The Comfort Coffee |  |
| 119889 | 원투쓰리PCCAFE | 영문·숫자 포함 | One Two Three PC Cafe | — |  |
| 90395 | 콘체르토CONCERTO | 영문·숫자 포함 | Concerto CONCERTO | Concerto CONCERTO |  |
| 86407 | 스트릿넘버502 | 영문·숫자 포함 | Street Number 502 | Street Number 502 |  |
| 138586 | 마포래미안129스낵 | 영문·숫자 포함 | Mapo Raemian 129 Snack | Mapo Raemian 129 Snack |  |
| 74673 | 커피다스1리터 | 영문·숫자 포함 | Coffee Das 1 Liter | — |  |
| 115348 | 블라BLA | 영문·숫자 포함 | Bla BLA | — |  |
| 63167 | 우밴드7080라이브 | 영문·숫자 포함 | U Band 7080 Live | — |  |
| 120743 | 스타벅스 도봉로DT | 영문·숫자 포함 | Starbucks Dobong-ro DT | — |  |
| 85789 | 영자's곱창 | 영문·숫자 포함 | — | Yeongja 's Gopchang |  |
| 123063 | 자담치킨잠실1 | 영문·숫자 포함 | Jadam Chicken Jamsil 1 | Jadam Chicken Jamsil 1 |  |
| 130147 | 파파존스 은평점 | 지점명 포함 | Papa John's Eunpyeong Branch | Papa John's Eunpyeong Branch |  |
| 37069 | 도미노피자 상암점 | 지점명 포함 | Domino's Pizza Sangam Branch | Domino's Pizza Sangam Branch |  |
| 78890 | 수내닭꼬치구청점 동대문 | 지점명 포함 | — | Sunaedakkkochi Gucheong Branch Dongdaemun |  |
| 101408 | 페트리코파트너스창경궁점 | 지점명 포함 | Petrichor Partners Changgyeonggung Branch | — | 예 |
| 51653 | 본도시락 마포역점 | 지점명 포함 | Bondosirak Mapo Station Branch | Bondosirak Mapo Station Branch |  |
| 143647 | 김씨치킨수유 시장점 | 지점명 포함 | Kimssi Chicken Suyu Sijang | Gimssi Chicken Suyu Sijang Branch |  |
| 94205 | 서울브루어리성 수지점 | 지점명 포함 | Seoul Brewery Seongsu Branch | — | 예 |
| 152960 | 화산포갈비 창포점 | 지점명 포함 | Hwasanpo Galbi Changpo Branch | Hwasanpogalbi Changpo Branch |  |
| 107109 | 마츠노하나신세계명동점 백화점 | 지점명 포함 | Matsunohana Shinsegae Myeongdong Department Store | — |  |
| 140096 | 손정보쌈 당산역점 | 지점명 포함 | Sonjeong Bossam Dangsan Station Branch | Sonjeongbossam Dangsan Station Branch |  |
| 14547 | 투썸플레이스옥수리버젠점 | 지점명 포함 | A Twosome Place Oksu Riverzen Branch | A TWOSOME PLACE Oksu Riverzen Branch |  |
| 102507 | 에코사랑목 본점 | 지점명 포함 | Eco Sarangmok Main Branch | — |  |
| 107183 | 몽슈슈 강남점 | 지점명 포함 | — | — |  |
| 123531 | 케니야커피동 여의도점 | 지점명 포함 | Keniya Coffee Dong Yeouido Branch | Keniya Coffee Dong Yeouido Branch | 예 |
| 125162 | 핵밥 동국대점 | 지점명 포함 | Haekbap Dongguk University Branch | Haekbap Donggukdae Branch |  |
| 121539 | 하우스오브바이닐 성수점 | 지점명 포함 | House of Vinyl Seongsu Branch | House of Vinyl Seongsu Branch |  |
| 110545 | 커스텀커피 개포점 | 지점명 포함 | Custom Coffee Gaepo Branch | Custom Coffee Gaepo Branch |  |
| 102257 | 카페일분등촌역점 | 지점명 포함 | Cafe Ilbun Deungchon Station Branch | Cafe Ilbun Deungchon Station Branch |  |
| 126504 | 도송에프엔비브이엔디종각 직영점 | 지점명 포함 | Dosong F&B VND Jonggak Direct Branch | — |  |
| 88673 | 서울주막 홍대점 | 지점명 포함 | Seoul Jumak Hongdae Branch | Seouljumak Hongdae Branch |  |

## 재현과 원본 응답

```sh
npm ci --prefix scripts/name-eval --ignore-scripts
node scripts/name-eval/benchmark.mjs
node scripts/name-eval/report.mjs <실행 디렉터리>/summary.json
```

배치 평가·fixture 복사본·summary.json: `artifacts/name-english-100-20261005/comparison-2026-10-05T08-58-22-566Z/corrected-processing-v1.1`.
원본 모델 요청·응답: `/Users/minchanpark/Documents/pind/artifacts/name-english-100-20261005/comparison-2026-10-05T08-58-22-566Z`.

기존 20개 저장 스크립트는 그대로 유지했다. 이 비교 코드는 DB 쓰기 기능을 포함하지 않는다.
