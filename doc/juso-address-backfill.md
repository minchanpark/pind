# Juso 영문 주소 보정

`public.places`의 SBIZ 장소에 저장된 한국어 도로명 주소를 행정안전부 [영문주소 검색 API](https://www.data.go.kr/data/15057017/openapi.do)의 결과로 보정한다. 주소를 자체 번역하지 않는다. 영문주소 **팝업** API 키는 검색 API에 사용할 수 없다.

승인키는 Git에서 제외되는 `config/juso.local.env`에 넣는다. 형식은 [예시 파일](../config/juso.example.env)을 참고한다. 앱 설정이나 채팅에는 키를 넣지 않는다.

## 선택한 장소만 보정

```sh
node scripts/backfill_sbiz_address_en.mjs --ids 123,456
node scripts/backfill_sbiz_address_en.mjs --ids 123,456 --apply
```

기본은 미리보기이며, 실행당 최대 20개 ID만 받는다. DB 주소와 API의 한국어 도로명 주소가 정확히 하나로 일치할 때만 수정한다. 기존 영문 주소는 보존하고, 수정 뒤 DB를 재조회한다.

## 포항 전체 배치

```sh
node scripts/backfill_pohang_addresses.mjs --max-addresses 20
node scripts/backfill_pohang_addresses.mjs --max-addresses 20 --apply
node scripts/backfill_pohang_addresses.mjs --max-addresses 10000 --apply
```

포항 배치는 동일한 `address_ko`를 공유하는 장소를 묶어 주소마다 API를 한 번만 호출한다. 100개 주소 단위로 조건부 갱신·검증한다. 기본은 20개 주소 미리보기이며 `--max-addresses` 상한은 10,000개다. 각 페이지가 출력하는 `last_address`를 사용하면 중단 위치 다음부터 재개할 수 있다.

```sh
node scripts/backfill_pohang_addresses.mjs --after '마지막 한국어 주소' --max-addresses 10000 --apply
```

API에서 정확한 공식 주소를 찾지 못하거나 한국어 원본 주소가 불완전하면 보정하지 않고 상태를 출력한다. 이런 항목은 별도 확인 대상이며, 임의로 영문 주소를 만들어 넣지 않는다. 승인키와 요청 URL은 출력하지 않는다.

테스트: `node --test scripts/backfill_sbiz_address_en.test.mjs scripts/backfill_pohang_addresses.test.mjs`.
