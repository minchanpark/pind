\set ON_ERROR_STOP on
begin;
-- 1 and 2 follow each other, 3 follows 2. 2 consented to recommendations, 3 did not.
insert into auth.users(id) select ('90000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,3) n;
update public.profiles set handle=h,display_name=dn from (values (1,'viewer','나'),(2,'haram','하람'),(3,'quiet','조용')) v(n,h,dn)
 where id=('90000000-0000-0000-0000-00000000000'||n)::uuid;
insert into public.taste_profiles(user_id,priorities,discoverable) values
 ('90000000-0000-0000-0000-000000000002',array['taste','ambience','portion'],true),
 ('90000000-0000-0000-0000-000000000003',array['value','taste','quiet'],false);
insert into public.follows(follower_id,followee_id) values
 ('90000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000002'),
 ('90000000-0000-0000-0000-000000000002','90000000-0000-0000-0000-000000000001'),
 ('90000000-0000-0000-0000-000000000003','90000000-0000-0000-0000-000000000002');
select public.import_sbiz_places('[{"id":"other-qa-a","name":"타인A","category":"한식","address":"서울 종로구","latitude":37.575,"longitude":126.985},
 {"id":"other-qa-b","name":"타인B","category":"카페","address":"서울 종로구","latitude":37.576,"longitude":126.986}]','2026-09-30');
create temp table qa as select
 (select id from public.places where external_place_id='other-qa-a') a,
 (select id from public.places where external_place_id='other-qa-b') b;
grant select on qa to authenticated;
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '90000000-0000-0000-0000-000000000002',qa.a,'',photo,'🍚',body,pub,'published' from qa,(values
 ('u2/a.png','public',true),('u2/private.png','private',false)) v(photo,body,pub);
insert into public.saved_places(user_id,place_id,share_with_friends) select '90000000-0000-0000-0000-000000000002',p,s
 from qa,lateral (values (qa.a,true),(qa.b,false)) v(p,s);
insert into public.place_views(user_id,place_id) select '90000000-0000-0000-0000-000000000002',qa.b from qa;

set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='90000000-0000-0000-0000-000000000001';
do $$ declare q qa; d jsonb; begin
 select * into q from qa;
 d:=public.get_profile_overview('90000000-0000-0000-0000-000000000002');
 assert d->'profile'->>'handle'='haram','their profile';
 assert (d->>'following')::boolean and (d->>'followsMe')::boolean,'mutual follow';
 assert d->'taste'='["taste","ambience","portion"]'::jsonb,'consenting user shows priorities';
 assert d->'counts'='{"followers":2,"following":1,"posts":2,"saved":1}'::jsonb,'friends-only post and shared save for a follower';
 assert jsonb_array_length(d->'posts')=2,'follower sees friends-only post';
 assert jsonb_array_length(d->'savedPlaces')=1 and (d->'savedPlaces'->0->>'internalId')::bigint=q.a,'shared save visible to a follower';
 assert d->'recentViews'='[]'::jsonb,'their recently viewed stays private';

 d:=public.get_profile_overview('90000000-0000-0000-0000-000000000003');
 assert not (d->>'following')::boolean and not (d->>'followsMe')::boolean,'no follow either way';
 assert d->'taste'='null'::jsonb,'non-consenting user hides priorities';
 assert public.get_profile_taste('90000000-0000-0000-0000-000000000003') is null;

 assert public.get_profile_overview(null)=public.get_my_profile_overview(),'null means me';
 assert public.get_profile_overview('90000000-0000-0000-0000-00000000000f') is null,'unknown user';
 assert (select count(*) from public.taste_profiles)=0,'table RLS unchanged';
end $$;

set local request.jwt.claim.sub='90000000-0000-0000-0000-000000000003';
do $$ declare d jsonb := public.get_profile_overview('90000000-0000-0000-0000-000000000002'); begin
 assert (d->>'following')::boolean and not (d->>'followsMe')::boolean,'one-way follow';
 assert jsonb_array_length(d->'savedPlaces')=1,'follower sees shared save';
 assert public.get_profile_taste(auth.uid())='{value,taste,quiet}','own priorities regardless of consent';
end $$;

set local request.jwt.claim.sub='90000000-0000-0000-0000-000000000002';
do $$ begin
 delete from public.follows where follower_id='90000000-0000-0000-0000-000000000003';
end $$;
set local request.jwt.claim.sub='90000000-0000-0000-0000-000000000003';
do $$ declare d jsonb := public.get_profile_overview('90000000-0000-0000-0000-000000000002'); begin
 assert (d->>'following')::boolean,'others cannot remove my follow';
end $$;
delete from public.follows where follower_id=auth.uid();
do $$ declare d jsonb := public.get_profile_overview('90000000-0000-0000-0000-000000000002'); begin
 assert not (d->>'following')::boolean and d->'savedPlaces'='[]'::jsonb and (d->'counts'->>'saved')::int=0
  and (d->'counts'->>'posts')::int=1,'unfollowed: shared saves and friends-only posts hidden';
end $$;

set local request.jwt.claim.sub='';
do $$ begin assert public.get_profile_overview('90000000-0000-0000-0000-000000000002') is null,'no user, no data'; end $$;
reset role;
do $$ begin
 assert not has_function_privilege('anon','public.get_profile_overview(uuid)','execute');
 assert not has_function_privilege('anon','public.get_profile_taste(uuid)','execute');
end $$;
rollback;
\echo 'PASS: other profiles — follow state, consented taste, public posts, shared saves, private views'
