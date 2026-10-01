\set ON_ERROR_STOP on
begin;
insert into auth.users(id) select ('97000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,2) n;
select public.import_sbiz_places('[{"id":"del-qa-a","name":"삭제A","category":"한식","address":"서울 종로구","latitude":37.575,"longitude":126.985}]','2026-10-01');
create temp table qa as select (select id from public.places where external_place_id='del-qa-a') a;
grant select on qa to authenticated;
-- Me: two posts at A (first with two photos); someone else: one post.
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select ('97000000-0000-0000-0000-00000000000'||u)::uuid,a,'',x,'🍚',x,true,'published' from qa,(values (1,'one'),(1,'two'),(2,'theirs')) v(u,x);
insert into public.post_media(post_id,position,path,mime,bytes)
select id,pos,'97000000-0000-0000-0000-000000000001/'||pos||'.jpg','image/jpeg',10 from public.posts,generate_series(0,1) pos where body='one';
insert into public.place_ratings(user_id,place_id,criterion,rating,is_public)
select ('97000000-0000-0000-0000-00000000000'||u)::uuid,a,'taste',r,true from qa,(values (1,5),(2,1)) v(u,r);
insert into public.post_likes(user_id,post_id) select '97000000-0000-0000-0000-000000000002',id from public.posts where body='one';

set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='97000000-0000-0000-0000-000000000001';
do $$ declare q qa; r jsonb; posts jsonb; begin select * into q from qa;
 posts:=public.get_catalog_places(p_place_id:=q.a)->'places'->0->'pindPosts';
 assert (select bool_and((e->>'mine')::boolean=(e->>'body' in ('one','two'))) from jsonb_array_elements(posts) e),'mine flags my posts only';
 -- Someone else's post: refused, untouched.
 begin perform public.delete_post((select id from public.posts where body='theirs')); raise exception 'deleted theirs';
 exception when no_data_found then null; end;
 assert exists(select 1 from public.posts where body='theirs'),'theirs kept';
 r:=public.delete_post((select id from public.posts where body='one'));
 assert r->'placeId'=to_jsonb(q.a) and r->'paths'='["97000000-0000-0000-0000-000000000001/0.jpg","97000000-0000-0000-0000-000000000001/1.jpg"]'::jsonb,'returns photo paths';
 assert not exists(select 1 from public.post_media where path like '97000000-0000-0000-0000-000000000001/%'),'media rows cascade';
 assert (select public_post_count from public.places where id=q.a)=2,'counter follows';
 assert exists(select 1 from public.place_ratings where user_id='97000000-0000-0000-0000-000000000001'),'rating kept: another post of mine remains';
 perform public.delete_post((select id from public.posts where body='two'));
 assert not exists(select 1 from public.place_ratings where user_id='97000000-0000-0000-0000-000000000001'),'last post: my rating goes';
 assert (select average from public.place_rating_stats where place_id=q.a and criterion='taste')=1,'average drops my 5';
end $$;
rollback;
