\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('a6000000-0000-0000-0000-000000000001'),('a6000000-0000-0000-0000-000000000002');
select public.import_sbiz_places((select jsonb_agg(jsonb_build_object('id','pages-qa-'||n,'name','페이지검증 '||n,'category','카페','address','서울 종로구','latitude',37.575,'longitude',126.985)) from generate_series(1,1000) n),'2026-10-06');
select public.import_sbiz_places((select jsonb_agg(jsonb_build_object('id','pages-qa-'||n,'name','페이지검증 '||n,'category','카페','address','서울 종로구','latitude',37.575,'longitude',126.985)) from generate_series(1001,1105) n),'2026-10-06');
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status,created_at)
select 'a6000000-0000-0000-0000-000000000001',id,'','qa.png','☕','pin',true,'published',now() from public.places where external_place_id like 'pages-qa-%';
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status,created_at)
select 'a6000000-0000-0000-0000-000000000002',id,'','qa.png','☕','profile-'||n,false,'published',now()-interval '1 day'
from public.places cross join generate_series(1,58) n where external_place_id='pages-qa-1';
set local role authenticated;
set local request.jwt.claim.sub='a6000000-0000-0000-0000-000000000002';
set local request.jwt.claims='{"is_anonymous":false}';
do $$ declare d jsonb; cursor_id bigint; cursor_time timestamptz; total integer:=0; ids bigint[]:='{}'; row jsonb; begin
  assert not has_function_privilege('authenticated','public.take_external_request_budget(uuid,text,integer,integer,integer)','execute');
  assert not has_function_privilege('anon','public.get_posted_places_page(bigint,integer,double precision,double precision,double precision,double precision)','execute');
  loop
    d:=public.get_posted_places_page(p_after_id=>cursor_id,p_limit=>250,p_south=>37.57,p_west=>126.98,p_north=>37.58,p_east=>126.99);
    for row in select value from jsonb_array_elements(d->'places') loop
      cursor_id:=(row->>'internalId')::bigint;
      assert not cursor_id=any(ids),'duplicate pin'; ids:=array_append(ids,cursor_id);
      assert not row ? 'pindPhotoPath','pins must not include photo paths'; total:=total+1;
    end loop;
    exit when not (d->>'hasMore')::boolean;
  end loop;
  assert total=1105,'map pagination must pass the old 1000 cap';
  assert jsonb_array_length(public.get_posted_places_page(p_south=>35,p_west=>128,p_north=>36,p_east=>129)->'places')=0,'bounds must filter server-side';
  total:=0; ids:='{}'; cursor_id:=null;
  loop
    d:=public.get_profile_posts_page(p_before_created=>cursor_time,p_before_id=>cursor_id,p_limit=>20);
    for row in select value from jsonb_array_elements(d->'posts') loop
      cursor_id:=(row->>'id')::bigint; cursor_time:=(row->>'createdAt')::timestamptz;
      assert not cursor_id=any(ids),'duplicate profile post'; ids:=array_append(ids,cursor_id); total:=total+1;
    end loop;
    exit when not (d->>'hasMore')::boolean;
  end loop;
  assert total=58,'profile pagination must pass the initial 50 cap and handle equal timestamps';
end $$;
set local request.jwt.claim.sub='a6000000-0000-0000-0000-000000000001';
do $$ begin assert jsonb_array_length(public.get_profile_posts_page('a6000000-0000-0000-0000-000000000002')->'posts')=0,'private posts must remain protected by RLS'; end $$;
reset role;
set local role service_role;
do $$ begin
  perform public.take_external_request_budget('a6000000-0000-0000-0000-000000000001','agent',3,10,1);
  begin
    perform public.take_external_request_budget('a6000000-0000-0000-0000-000000000001','agent',3,10,1);
    raise exception 'minute limit bypassed';
  exception when others then assert sqlerrm='EXTERNAL_MINUTE_LIMIT'; end;
  assert (select requests from private.external_api_daily_total where kind='agent')=1,'failed budget consumption must roll back';
  perform public.take_external_request_budget('a6000000-0000-0000-0000-000000000001','walking',1,10,10);
  begin
    perform public.take_external_request_budget('a6000000-0000-0000-0000-000000000001','walking',1,10,10);
    raise exception 'user limit bypassed';
  exception when others then assert sqlerrm='EXTERNAL_USER_LIMIT'; end;
  begin
    perform public.take_external_request_budget('a6000000-0000-0000-0000-000000000002','walking',10,1,10);
    raise exception 'total limit bypassed';
  exception when others then assert sqlerrm='EXTERNAL_DAILY_LIMIT'; end;
end $$;
rollback;
\echo 'PASS: external budgets, rollback, map/profile pagination and RLS'
