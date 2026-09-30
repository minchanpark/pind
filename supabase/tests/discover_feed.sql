\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('61000000-0000-0000-0000-000000000001'),('61000000-0000-0000-0000-000000000002');
update public.profiles set handle='feed_two',display_name='둘',avatar_url='https://x/a.png'
 where id='61000000-0000-0000-0000-000000000002';
select public.import_sbiz_places('[{"id":"feed-qa-a","name":"피드A","category":"카페","address":"서울 종로구","latitude":37.575,"longitude":126.985},
 {"id":"feed-qa-b","name":"피드B","category":"한식","address":"서울 종로구","latitude":37.576,"longitude":126.986},
 {"id":"feed-qa-c","name":"피드C","category":"분식","address":"서울 종로구","latitude":37.577,"longitude":126.987}]','2026-09-29');
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status,created_at,
 client_request_id,taste_score,portion_score,ambience_score)
select u::uuid,(select id from public.places where external_place_id='feed-qa-'||k),'',photo,'☕',body,pub,st,now()-age,
 req::uuid,t,po,am from (values
 (1,'61000000-0000-0000-0000-000000000001','a','legacy/a.png','legacy',true,'published',interval '5 hours',null,null,null,null),
 (2,'61000000-0000-0000-0000-000000000001','b','61000000-0000-0000-0000-000000000001/r/0.png','100%_sale',true,'published',interval '4 hours','71000000-0000-0000-0000-000000000001',5,4,3),
 (3,'61000000-0000-0000-0000-000000000002','a','u2/a.png','friend',true,'published',interval '3 hours',null,null,null,null),
 (4,'61000000-0000-0000-0000-000000000002','b','u2/b.png','100 sale',true,'published',interval '3 hours',null,null,null,null),
 (5,'61000000-0000-0000-0000-000000000001','c','hidden.png','hidden',true,'hidden',interval '1 hour',null,null,null,null),
 (6,'61000000-0000-0000-0000-000000000001','c','private.png','private',false,'published',interval '1 hour',null,null,null,null),
 (7,'61000000-0000-0000-0000-000000000002','c','u2/c.png','x',true,'published',interval '2 hours',null,null,null,null)
) v(n,u,k,photo,body,pub,st,age,req,t,po,am) order by n;
insert into public.post_media(post_id,position,path,mime,bytes)
select id,pos,'61000000-0000-0000-0000-000000000001/r/'||pos||'.png','image/png',32
from public.posts,(values(1),(0)) v(pos) where client_request_id='71000000-0000-0000-0000-000000000001';
create temp table qa as select
 (select id from public.posts where body='legacy') p1,(select id from public.posts where body='100%_sale') p2,
 (select id from public.posts where body='friend') p3,(select id from public.posts where body='100 sale') p4,
 (select id from public.posts where body='hidden') p5,(select id from public.posts where body='x') p7;
grant select on qa to authenticated;
create function pg_temp.ids(d jsonb) returns bigint[] language sql as
 $$ select coalesce(array_agg((e->>'id')::bigint order by o),'{}') from jsonb_array_elements(d) with ordinality x(e,o) $$;
set local role authenticated;
set local request.jwt.claim.sub='61000000-0000-0000-0000-000000000001';
set local request.jwt.claims='{"is_anonymous":false}';
do $$ declare q qa; d jsonb; e jsonb; begin
 select * into q from qa;
 assert not has_function_privilege('anon','public.get_discover_feed(text,timestamptz,bigint,integer)','execute');
 assert not has_function_privilege('anon','public.toggle_post_like(bigint,boolean)','execute');
 assert q.p3<q.p4,'tiebreak fixture';
 d:=public.get_discover_feed();
 assert pg_temp.ids(d)=array[q.p7,q.p4,q.p3,q.p2,q.p1],'newest first, id tiebreak, own hidden/private excluded';
 -- keyset pages
 d:=public.get_discover_feed(p_limit=>2);
 assert pg_temp.ids(d)=array[q.p7,q.p4],'page 1';
 d:=public.get_discover_feed(null,(d->1->>'createdAt')::timestamptz,(d->1->>'id')::bigint,2);
 assert pg_temp.ids(d)=array[q.p3,q.p2],'page 2 continues without overlap or gap';
 d:=public.get_discover_feed(null,(d->1->>'createdAt')::timestamptz,(d->1->>'id')::bigint,2);
 assert pg_temp.ids(d)=array[q.p1],'page 3';
 assert public.get_discover_feed(null,(d->0->>'createdAt')::timestamptz,(d->0->>'id')::bigint,2)='[]'::jsonb,'end';
 assert jsonb_array_length(public.get_discover_feed(p_limit=>0))=1 and jsonb_array_length(public.get_discover_feed(p_limit=>-5))=1,'clamp low';
 -- search
 assert pg_temp.ids(public.get_discover_feed(' 피드B '))=array[q.p4,q.p2],'place name';
 assert pg_temp.ids(public.get_discover_feed('분식'))=array[q.p7],'category';
 assert pg_temp.ids(public.get_discover_feed('FRIEND'))=array[q.p3],'body, case-insensitive';
 assert pg_temp.ids(public.get_discover_feed('100%'))=array[q.p2],'% literal';
 assert pg_temp.ids(public.get_discover_feed('_'))=array[q.p2],'_ literal';
 assert jsonb_array_length(public.get_discover_feed('   '))=5,'blank query = all';
 assert public.get_discover_feed('hidden')='[]'::jsonb and public.get_discover_feed('private')='[]'::jsonb,'search hides hidden/private';
 -- shape
 d:=public.get_discover_feed();
 e:=d->2;
 assert e ?& array['id','author','place','body','ratings','bucket','photos','createdAt','likeCount','liked']
  and (select count(*) from jsonb_object_keys(e))=10,'post keys';
 assert e->'author'=jsonb_build_object('id','61000000-0000-0000-0000-000000000002','handle','feed_two',
  'displayName','둘','avatarUrl','https://x/a.png'),'author json';
 assert e->'place' ?& array['provider','internalId','externalPlaceId','name','category','address','latitude',
  'longitude','sourceUri','heroImageUrl','pindPhotoPath','pindPhotoBucket']
  and (select count(*) from jsonb_object_keys(e->'place'))=12,'place summary keys';
 assert e->'place'->>'name'='피드A' and e->'place'->>'pindPhotoPath'='u2/a.png' and e->'place'->>'pindPhotoBucket'='post-media','place card';
 assert e->'likeCount'='0'::jsonb and e->'liked'='false'::jsonb,'no likes yet';
 assert d->3->>'bucket'='post-media-v2' and d->3->'ratings'='{"taste":5,"portion":4,"ambience":3}'::jsonb;
 assert d->3->'photos'='["61000000-0000-0000-0000-000000000001/r/0.png","61000000-0000-0000-0000-000000000001/r/1.png"]'::jsonb,'position order';
 assert d->4->>'bucket'='post-media' and d->4->'photos'='["legacy/a.png"]'::jsonb and d->4->'ratings'='{}'::jsonb,'legacy fallback';
 assert (d->3->>'createdAt')::timestamptz=now()-interval '4 hours','ISO createdAt';
 -- likes
 assert public.toggle_post_like(q.p3,true) and public.toggle_post_like(q.p3,true),'like idempotent';
 assert (select count(*) from public.post_likes where post_id=q.p3)=1;
 begin perform public.toggle_post_like(q.p5,true); raise exception 'Hidden post liked';
 exception when insufficient_privilege then null; end;
 begin insert into public.post_likes(user_id,post_id) values('61000000-0000-0000-0000-000000000002',q.p4);
  raise exception 'Liked as someone else';
 exception when insufficient_privilege then null; end;
end $$;
set local request.jwt.claim.sub='61000000-0000-0000-0000-000000000002';
do $$ declare q qa; d jsonb; begin
 select * into q from qa;
 assert public.toggle_post_like(q.p3,true);
 d:=public.get_discover_feed();
 assert d->2->'likeCount'='2'::jsonb and d->2->'liked'='true'::jsonb,'count includes other user likes';
 assert d->1->'likeCount'='0'::jsonb and d->1->'liked'='false'::jsonb;
end $$;
set local request.jwt.claim.sub='61000000-0000-0000-0000-000000000001';
do $$ declare q qa; d jsonb; begin
 select * into q from qa;
 d:=public.get_discover_feed();
 assert d->2->'likeCount'='2'::jsonb and d->2->'liked'='true'::jsonb,'same count for author of the like';
 assert not public.toggle_post_like(q.p3,false) and not public.toggle_post_like(q.p3,false),'unlike idempotent';
 d:=public.get_discover_feed();
 assert d->2->'likeCount'='1'::jsonb and d->2->'liked'='false'::jsonb,'unlike drops only mine';
end $$;
set local request.jwt.claims='{"is_anonymous":true}';
do $$ begin
 perform public.toggle_post_like((select p4 from qa),true); raise exception 'Anonymous like accepted';
exception when insufficient_privilege then null; end $$;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='';
do $$ begin assert public.get_discover_feed() is null,'no user, no feed'; end $$;
set local role anon;
do $$ begin
 begin perform public.get_discover_feed(); raise exception 'Anon feed allowed';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,created_at)
select '61000000-0000-0000-0000-000000000002',(select id from public.places where external_place_id='feed-qa-a'),
 '','bulk.png','☕','bulk',true,now()-interval '1 day' from generate_series(1,60);
set local role authenticated;
set local request.jwt.claim.sub='61000000-0000-0000-0000-000000000001';
do $$ begin
 assert jsonb_array_length(public.get_discover_feed(p_limit=>1000))=50,'clamp high';
 assert jsonb_array_length(public.get_discover_feed())=20,'default limit';
end $$;
rollback;
-- Posts on places the app can't render (Google reference-only, demo) stay out
-- of the feed and My Page; they broke the client parser before.
begin;
insert into auth.users(id) values ('61000000-0000-0000-0000-000000000001');
select public.import_sbiz_places('[{"id":"feed-qa-ok","name":"정상","category":"카페","address":"서울 종로구","latitude":37.575,"longitude":126.985}]','2026-09-29');
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public)
select '61000000-0000-0000-0000-000000000001',id,'','ok.png','☕','visible-place',true
from public.places where external_place_id='feed-qa-ok';
insert into public.places(slug,external_provider,external_place_id,is_reference_only,is_demo,is_published)
values('feed-ref-only','google_places','ChIJfeedRefOnly',true,false,true);
insert into public.places(slug,external_provider,external_place_id,name_ko,category,address_ko,latitude,longitude,is_demo,is_published)
values('feed-demo','pind_demo','feed-demo','데모','카페','서울',37.57,126.98,true,true);
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public)
select '61000000-0000-0000-0000-000000000001',id,'','x.png','☕','hidden-place',true
from public.places where slug in ('feed-ref-only','feed-demo');
set local role authenticated;
set local request.jwt.claim.sub='61000000-0000-0000-0000-000000000001';
do $$ begin
 assert not exists(select 1 from jsonb_array_elements(public.get_discover_feed(p_limit=>50)) e
   where e->>'body'='hidden-place'),'feed hides unrenderable places';
 assert not exists(select 1 from jsonb_array_elements(public.get_my_profile_overview()->'posts') e
   where e->>'body'='hidden-place'),'profile hides unrenderable places';
 assert exists(select 1 from jsonb_array_elements(public.get_discover_feed(p_limit=>50)) e
   where e->>'body'='visible-place'),'catalog post still listed';
 assert (public.get_my_profile_overview()->'counts'->>'posts')::int = 1,'count skips hidden places';
 assert (public.get_my_profile_overview()->'counts'->>'posts')::int
   = jsonb_array_length(public.get_my_profile_overview()->'posts'),'post count matches listed posts';
end $$;
rollback;
\echo 'PASS: discover feed order, keyset pages, limit clamp, search escaping, shape, likes RLS and idempotency'
