\set ON_ERROR_STOP on
begin;
-- 1 follows 2; nobody follows 3. 2 and 3 share their save of A; 1 saved A too.
insert into auth.users(id) select ('91000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,3) n;
update public.profiles set avatar_url='https://x/'||n||'.png'
 from generate_series(1,3) n where id=('91000000-0000-0000-0000-00000000000'||n)::uuid;
insert into public.follows(follower_id,followee_id) values
 ('91000000-0000-0000-0000-000000000001','91000000-0000-0000-0000-000000000002');
select public.import_sbiz_places('[{"id":"saved-qa-a","name":"저장A","category":"한식","address":"서울 종로구","latitude":37.575,"longitude":126.985}]','2026-10-01');
create temp table qa as select (select id from public.places where external_place_id='saved-qa-a') a;
grant select on qa to authenticated;
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '91000000-0000-0000-0000-000000000002',qa.a,'',photo,'🍚','',pub,'published' from qa,(values
 ('u2/a.png',true),('u2/private.png',false)) v(photo,pub);
insert into public.saved_places(user_id,place_id,share_with_friends,saved_at)
select ('91000000-0000-0000-0000-00000000000'||n)::uuid,qa.a,n>1,now()-n*interval '1 day'
 from qa,generate_series(1,3) n;

set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='91000000-0000-0000-0000-000000000001';
do $$ declare s jsonb := public.get_profile_overview(null)->'savedPlaces'->0; begin
 assert (s->>'savedAt')::timestamptz < now() - interval '23 hours','my save time';
 assert (s->>'reviewCount')::int=1,'public posts only';
 assert s->'savers'='["https://x/2.png"]'::jsonb,'followed sharer only, never me or strangers';
end $$;
rollback;
