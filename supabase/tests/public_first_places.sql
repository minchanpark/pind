\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values('20000000-0000-0000-0000-000000000001');
select public.import_sbiz_places('[{"id":"catalog-test","name":"검증카페","category":"카페","address":"서울 종로구","latitude":37.57,"longitude":126.98}]','2026-06-30');
create temp table catalog_test_id as select id from public.places where external_place_id='catalog-test';
update public.places set short_description_ko='Pind 소개' where id=(select id from catalog_test_id);
select public.import_sbiz_places('[{"id":"catalog-test","name":"검증카페 새이름","category":"카페","address":"서울 종로구","latitude":37.57,"longitude":126.98}]','2026-06-30');
do $$ begin
  assert (select id from public.places where external_place_id='catalog-test')=(select id from catalog_test_id),'ID preserved';
  assert (select short_description_ko from public.places where external_place_id='catalog-test')='Pind 소개','Pind data preserved';
  assert not has_function_privilege('authenticated','public.import_sbiz_places(jsonb,date)','execute');
  assert not has_function_privilege('authenticated','public.take_place_google_budget(uuid,integer,integer)','execute');
  assert not has_table_privilege('authenticated','private.place_api_daily_total','select');
  begin
    insert into public.places(slug,external_provider,external_place_id,name_ko,category,address_ko,latitude,longitude,is_demo,is_published)
      values('bad-google-cache','google_places','google-test-id','금지','카페','서울',37.57,126.98,false,true);
    raise exception 'Google content cached';
  exception when check_violation then null; end;
end $$;
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public)
select '20000000-0000-0000-0000-000000000001',id,'커피','private/photo.png','☕','비공개',false from catalog_test_id;
set local role authenticated;
set local request.jwt.claim.sub='20000000-0000-0000-0000-000000000001';
do $$ declare data jsonb; begin
  data:=public.get_catalog_places(p_query=>'검증카페');
  assert jsonb_array_length(data->'places')=1;
  assert data->'places'->0->>'provider'='sbiz';
  assert data->'places'->0->>'pindPhotoPath' is null,'even owners private photos excluded';
  assert (data->'places'->0->>'pindPostCount')::int=0;
  assert jsonb_array_length(public.get_catalog_places(p_query=>'%_')->'places')=0,'LIKE wildcards literal';
  assert jsonb_array_length(public.get_catalog_places(p_lat=>33.5,p_lng=>126.5,p_radius=>1000)->'places')=0;
  assert jsonb_array_length(public.get_catalog_places(p_lat=>37.57,p_lng=>126.98,p_radius=>1000)->'places')=1;
end $$;
do $$ begin
  begin
    update public.places set name_ko='user overwrite' where external_place_id='catalog-test';
    if found then raise exception 'Catalog was writable by a user'; end if;
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
update public.posts set is_public=true where place_id=(select id from catalog_test_id);
set local role authenticated;
do $$ declare data jsonb; begin
  data:=public.get_catalog_places(p_query=>'검증카페');
  assert (data->'places'->0->>'pindPostCount')::int=1;
  assert data->'places'->0->>'pindPhotoPath'='private/photo.png';
end $$;
reset role;
set local role service_role;
select public.take_place_google_budget('20000000-0000-0000-0000-000000000001',1,2);
do $$ begin
  begin
    perform public.take_place_google_budget('20000000-0000-0000-0000-000000000001',1,2);
    raise exception 'Limit failed';
  exception when raise_exception then assert sqlerrm='GOOGLE_USER_LIMIT'; end;
  assert (select requests from private.place_api_daily_total where day=(now() at time zone 'Asia/Seoul')::date)=1,'no partial global charge';
  perform public.take_place_google_budget('20000000-0000-0000-0000-000000000002',1,2);
  begin
    perform public.take_place_google_budget('20000000-0000-0000-0000-000000000003',1,2);
    raise exception 'Limit failed';
  exception when raise_exception then assert sqlerrm='GOOGLE_DAILY_LIMIT'; end;
end $$;
reset role;
rollback;
select 'PASS: catalog, IDs, privacy, permissions, Google budget rollback';
