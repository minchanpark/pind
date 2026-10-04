\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('99000000-0000-0000-0000-000000000001');
select public.import_sbiz_places('[{"id":"en-qa-a","name":"란칼국수","category":"한식","address":"서울특별시 성동구 성수일로8길 42","latitude":37.575,"longitude":126.985},
 {"id":"en-qa-b","name":"란국수","category":"한식","address":"서울특별시 성동구 성수일로8길 44","latitude":37.575,"longitude":126.985}]','2026-10-01');
update public.places set address_en='42 Seongsuil-ro 8-gil, Seongdong-gu, Seoul' where external_place_id='en-qa-a';
-- Re-import keeps the English address (20260927143732).
select public.import_sbiz_places('[{"id":"en-qa-a","name":"란칼국수","category":"한식","address":"서울특별시 성동구 성수일로8길 42","latitude":37.575,"longitude":126.985}]','2026-10-02');
set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='99000000-0000-0000-0000-000000000001';
do $$ declare a jsonb := public.get_catalog_places(p_query=>'란칼국수')->'places'->0;
  b jsonb := public.get_catalog_places(p_query=>'란국수')->'places'->0; begin
 assert a->>'address'='서울특별시 성동구 성수일로8길 42' and a->>'addressEn'='42 Seongsuil-ro 8-gil, Seongdong-gu, Seoul','address pair';
 assert b->'addressEn'='null'::jsonb,'no English yet: null, not the Korean again';
 assert not a ? 'nameEn','names stay Korean';
end $$;
rollback;
