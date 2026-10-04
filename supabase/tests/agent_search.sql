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
-- c also has a bakery-style post: "바삭" is not a 바 (bar).
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '98000000-0000-0000-0000-000000000002',qa.c,'',qa.c||'-2.png','🥐','소금빵이 바삭해요',true,'published' from qa;
-- b tastes better than a on my priorities.
insert into public.place_ratings(user_id,place_id,criterion,rating,is_public)
select '98000000-0000-0000-0000-000000000002',p,crit,r,true from qa,lateral (values
 (qa.a,'taste',3),(qa.a,'portion',3),(qa.a,'ambience',3),
 (qa.b,'taste',5),(qa.b,'portion',5),(qa.b,'ambience',4)) v(p,crit,r);

insert into public.saved_places(user_id,place_id) select '98000000-0000-0000-0000-000000000001',b from qa;

set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='98000000-0000-0000-0000-000000000001';
do $$ declare q qa; r jsonb; ids bigint[]; begin select * into q from qa;
 -- 혼술/포차/이자카야 near 성수.
 r:=public.agent_search_places(array['혼술','포차','이자카야'],null,37.5440,127.0550)->'places';
 select array_agg((e->>'internalId')::bigint) into ids from jsonb_array_elements(r) e;
 assert ids[1:3]=array[q.a,q.b,q.c] or ids[1:3]=array[q.b,q.a,q.c],'posted first: a (name), b (post text), c (name)';
 assert cardinality(ids)=3,'posted places only, even the nearby unposted 포차';
 assert (select (e->>'tasteMatch')::int from jsonb_array_elements(r) e where (e->>'internalId')::bigint=q.b)=95,'b match 95';
 -- Card fields: averages, review count, my save, distance from the center.
 assert (select e->'averages'->>'taste' from jsonb_array_elements(r) e where (e->>'internalId')::bigint=q.b)::numeric=5,'b taste average';
 assert (select (e->>'reviewCount')::int from jsonb_array_elements(r) e where (e->>'internalId')::bigint=q.b)=1,'b one review';
 assert (select (e->>'saved')::boolean from jsonb_array_elements(r) e where (e->>'internalId')::bigint=q.b),'b saved by me';
 assert (select (e->>'meters')::int from jsonb_array_elements(r) e where (e->>'internalId')::bigint=q.a)=0,'a at the center';
 -- Equal hits: taste breaks the tie (b 95 > a 50).
 r:=public.agent_search_places(array['좋아요'],null,null,null)->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.b,q.a],'taste order on a tie';
 -- An area is a circle around its geocoded point: 연남 (c) only, whatever
 -- the address says; the old address match is gone (c's address has 연남동,
 -- a/b's road addresses never name 성수동).
 r:=public.agent_search_places(array['이자카야','포차'],null,37.5620,126.9250,1000)->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.c],'radius filter';
 r:=public.agent_search_places(array['포차'],'성수동',37.5440,127.0550,1000)->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.a],'p_area ignored, radius used';
 begin perform public.agent_search_places(array['포차'],null,null,null,1000); raise exception 'radius without center accepted';
 exception when raise_exception then if sqlerrm<>'Invalid radius' then raise; end if; end;
 -- The kind must match; mood words only rank. b's post says 좋아요, but b
 -- is no 포차.
 r:=public.agent_search_places(array['좋아요'],null,37.5440,127.0550,null,array['포차'])->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.a],'kind filters, terms rank';
 -- A place of the kind stays even when no post uses the mood word.
 r:=public.agent_search_places(array['사진'],null,null,null,null,array['한식'])->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.b],'kind without term hits';
 -- Matching mood words go first among the kind: 혼술 (b's post) before c.
 r:=public.agent_search_places(array['혼술'],null,null,null,null,array['주점','한식'])->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)[1]=q.b,'hits rank within the kind';
 -- No place of the kind: nothing, not lookalikes.
 r:=public.agent_search_places(array['좋아요'],null,null,null,null,array['치킨'])->'places';
 assert jsonb_array_length(r)=0,'unknown kind finds nothing';
 -- Kinds alone are a valid search.
 r:=public.agent_search_places(array[]::text[],null,null,null,null,array['이자카야'])->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.c],'kinds only';
 -- One-letter words count only as whole words (particles allowed).
 assert not public.agent_text_hit('소금빵이 바삭해요','바'),'바 in 바삭';
 assert public.agent_text_hit('바에서 혼술했어요','바'),'바 + particle';
 assert public.agent_text_hit('분위기 좋은 바','바'),'바 at the end';
 assert public.agent_text_hit('바, 포차 둘 다 좋아요','바'),'바 before a comma';
 assert not public.agent_text_hit('냉면이 맛있어요','면'),'면 in 냉면';
 assert public.agent_text_hit('냉면/밀면','면',true),'categories match inside';
 assert public.agent_text_hit('돼지고기 구이/찜','고기'),'longer words still match inside';
 assert not public.agent_text_hit(null,'바') and not public.agent_text_hit('바','');
 r:=public.agent_search_places(array['바'],null,null,null,null,null)->'places';
 assert jsonb_array_length(r)=0,'바삭 no longer finds c';
 -- "Pick for me": no words at all, every posted place by my taste match
 -- (b 95 > a 50; c has no ratings and goes last).
 r:=public.agent_search_places(array[]::text[],null,null,null,null,null,true)->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.b,q.a,q.c],'by taste, no words';
 -- My foods filter, and match beats the occasion word: a mentions 안주
 -- (hits 1) but b's match is higher.
 r:=public.agent_search_places(array['안주'],null,null,null,null,array['주점','한식'],true)->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.b,q.a,q.c],'match before hits';
 -- Without p_by_taste the same words rank by hits first.
 r:=public.agent_search_places(array['안주'],null,null,null,null,array['주점','한식'])->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)[1]=q.a,'hits first otherwise';
 -- Many food words are kept, not just the first four.
 r:=public.agent_search_places(array[]::text[],null,null,null,null,
   array['카페','디저트','커피','빵','고기','구이','이자카야'],true)->'places';
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.c],'7th kind still counts';
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
