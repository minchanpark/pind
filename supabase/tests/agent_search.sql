\set ON_ERROR_STOP on
begin;
insert into auth.users(id) select ('98000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,2) n;
-- Me: 맛 > 양 > 분위기.
insert into public.taste_profiles(user_id,priorities,discoverable) values
 ('98000000-0000-0000-0000-000000000001',array['taste','portion','ambience'],false);
select public.import_sbiz_places('[
 {"id":"ag-a","name":"성수 포차","category":"요리 주점","address":"서울 성동구 성수동 1","latitude":37.5440,"longitude":127.0550},
 {"id":"ag-b","name":"조용한집","category":"한식","address":"서울 성동구 성수동 2","latitude":37.5441,"longitude":127.0551},
 {"id":"ag-c","name":"연남 이자카야","category":"요리 주점","address":"서울 마포구 연남동 3","latitude":37.5620,"longitude":126.9250},
 {"id":"ag-d","name":"동네 포차","category":"요리 주점","address":"서울 성동구 성수동 4","latitude":37.5445,"longitude":127.0555},
 {"id":"ag-e","name":"먼 포차","category":"요리 주점","address":"경기 어딘가","latitude":37.7000,"longitude":127.2000}]','2026-10-01');
create temp table qa as select
 (select id from public.places where external_place_id='ag-a') a,
 (select id from public.places where external_place_id='ag-b') b,
 (select id from public.places where external_place_id='ag-c') c,
 (select id from public.places where external_place_id='ag-d') d,
 (select id from public.places where external_place_id='ag-e') e;
grant select on qa to authenticated;
-- a, b, c posted (b only mentions 혼술 in its post); d, e unposted.
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '98000000-0000-0000-0000-000000000002',p,'',p||'.png','🍺',body,true,'published'
 from qa,lateral (values (qa.a,'안주가 좋아요'),(qa.b,'혼술 하기 딱 좋아요'),(qa.c,'맛있어요')) v(p,body);
-- b tastes better than a on my priorities.
insert into public.place_ratings(user_id,place_id,criterion,rating,is_public)
select '98000000-0000-0000-0000-000000000002',p,crit,r,true from qa,lateral (values
 (qa.a,'taste',3),(qa.a,'portion',3),(qa.a,'ambience',3),
 (qa.b,'taste',5),(qa.b,'portion',5),(qa.b,'ambience',4)) v(p,crit,r);

set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='98000000-0000-0000-0000-000000000001';
do $$ declare q qa; r jsonb; ids bigint[]; begin select * into q from qa;
 -- 혼술/포차/이자카야 near 성수.
 r:=public.agent_search_places(array['혼술','포차','이자카야'],null,37.5440,127.0550)->'places';
 select array_agg((e->>'internalId')::bigint) into ids from jsonb_array_elements(r) e;
 assert ids[1:3]=array[q.a,q.b,q.c] or ids[1:3]=array[q.b,q.a,q.c],'posted first: a (name), b (post text), c (name)';
 assert ids @> array[q.d] and not ids @> array[q.e],'unposted only within 3km';
 assert ids[cardinality(ids)]=q.d,'unposted after posted';
 assert (select (e->>'tasteMatch')::int from jsonb_array_elements(r) e where (e->>'internalId')::bigint=q.b)=95,'b match 95';
 -- Equal hits: taste breaks the tie (b 95 > a 50).
 r:=public.agent_search_places(array['좋아요'],null,null,null)->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.b,q.a],'taste order on a tie';
 -- Area narrows to 연남.
 r:=public.agent_search_places(array['이자카야','포차'],'연남동',37.5440,127.0550)->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.c],'area filter';
 -- Bad input.
 begin perform public.agent_search_places(array[]::text[]); raise exception 'empty accepted';
 exception when raise_exception then null; end;
end $$;
reset role;
set local role anon;
do $$ begin
 begin perform public.agent_search_places(array['포차']); raise exception 'anon callable';
 exception when insufficient_privilege then null; end;
end $$;
rollback;
