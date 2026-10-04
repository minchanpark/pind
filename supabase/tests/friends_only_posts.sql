\set ON_ERROR_STOP on
begin;
-- 1 posts, 2 follows 1, 3 is a stranger.
insert into auth.users(id) select ('98000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,3) n;
select public.import_sbiz_places('[{"id":"fo-qa-a","name":"친구공개A","category":"한식","address":"서울 종로구","latitude":37.575,"longitude":126.985}]','2026-10-03');
insert into public.follows(follower_id,followee_id) values('98000000-0000-0000-0000-000000000002','98000000-0000-0000-0000-000000000001');
create temp table qa as select (select id from public.places where external_place_id='fo-qa-a') a, null::bigint private_id;
grant select,update on qa to authenticated;

set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='98000000-0000-0000-0000-000000000001';
do $$ declare q qa; photo jsonb; begin select * into q from qa;
 for n in 1..2 loop
  photo:=jsonb_build_array(jsonb_build_object('path','98000000-0000-0000-0000-000000000001/98100000-0000-0000-0000-00000000000'||n||'/0.png','mime','image/png','bytes',32));
  insert into storage.objects(bucket_id,name,owner_id,metadata) values('post-media-v2',photo->0->>'path',auth.uid()::text,'{"mimetype":"image/png","size":32}');
  if n=1 then
   perform public.publish_post_v3('98100000-0000-0000-0000-000000000001',q.a,'{"taste":5,"portion":4,"ambience":3}','friends',photo,p_is_public=>false);
  else -- Older builds: no p_is_public.
   perform public.publish_post_v3('98100000-0000-0000-0000-000000000002',q.a,'{"taste":5,"portion":4,"ambience":3}','everyone',photo);
  end if;
 end loop;
 update qa set private_id=(select id from public.posts where body='friends');
 assert (select not is_public from public.posts where body='friends'),'private stored';
 assert (select is_public from public.posts where body='everyone'),'public by default';
 assert (public.get_profile_overview(null)->'counts'->>'posts')::int=2,'author sees own private post';
 assert (select public_post_count from public.places where id=q.a)=1,'counter stays public-only';
 assert (public.get_catalog_places(p_place_id:=q.a)->'places'->0->>'pindPostCount')::int=1,'detail count public-only';
end $$;

set local request.jwt.claim.sub='98000000-0000-0000-0000-000000000002';
do $$ declare q qa; begin select * into q from qa;
 assert (select count(*) from jsonb_array_elements(public.get_discover_feed()) e
   where e->'author'->>'id'='98000000-0000-0000-0000-000000000001')=2,'follower feed has both';
 assert (public.get_profile_overview('98000000-0000-0000-0000-000000000001')->'counts'->>'posts')::int=2,'follower profile';
 assert jsonb_array_length(public.get_catalog_places(p_place_id:=q.a)->'places'->0->'pindPosts')=2,'follower detail';
 assert (select count(*) from jsonb_array_elements(public.get_notifications()->'items') e where e->>'kind'='visit')=2,'follower notified';
 assert (select count(*) from storage.objects where name like '98000000-0000-0000-0000-000000000001/%')=2,'follower sees photos';
 insert into public.post_likes(user_id,post_id) select auth.uid(),id from public.posts where body='friends';
end $$;

set local request.jwt.claim.sub='98000000-0000-0000-0000-000000000003';
do $$ declare q qa; begin select * into q from qa;
 assert not exists(select 1 from public.posts where body='friends'),'stranger cannot read';
 assert (select string_agg(e->>'body',',') from jsonb_array_elements(public.get_discover_feed()) e
   where e->'author'->>'id'='98000000-0000-0000-0000-000000000001')='everyone','stranger feed public only';
 assert (public.get_profile_overview('98000000-0000-0000-0000-000000000001')->'counts'->>'posts')::int=1,'stranger profile';
 assert jsonb_array_length(public.get_catalog_places(p_place_id:=q.a)->'places'->0->'pindPosts')=1,'stranger detail';
 assert (select count(*) from storage.objects where name like '98000000-0000-0000-0000-000000000001/%')=1,'stranger sees public photo only';
 assert not exists(select 1 from public.post_likes where user_id='98000000-0000-0000-0000-000000000002'),'private likes hidden';
 begin
  insert into public.post_likes(user_id,post_id) values(auth.uid(),q.private_id); raise exception 'liked private';
 exception when insufficient_privilege then null; end;
 insert into public.post_likes(user_id,post_id) select auth.uid(),id from public.posts where body='everyone';
end $$;
rollback;
