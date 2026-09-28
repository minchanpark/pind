-- Sunlin University's English site confirms the campus address components:
-- https://eng.sunlin.ac.kr/Introduction/About
-- The four SBIZ listings below use that same Korean campus road address.
-- The English street-name order is normalized to the Korean road-address format.
with updated as (
  update public.places
  set address_en = '30, Chogok-gil 36beon-gil, Heunghae-eup, Buk-gu, Pohang-si, Gyeongsangbuk-do'
  where id in (145321, 149006, 150833, 151998)
    and external_provider = 'sbiz'
    and address_ko = '경상북도 포항시 북구 흥해읍 초곡길36번길 30'
    and address_en = address_ko
  returning id
)
select count(*)::int as updated_count, array_agg(id order by id) as updated_ids from updated;
