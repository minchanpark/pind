\set ON_ERROR_STOP on
begin;
-- a..e = 1..5. a: taste>value>ambience. b swaps value/ambience (90%), c equals a (100%),
-- d shares nothing (0%), e equals a but has not consented to recommendations.
insert into auth.users(id) select ('80000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,5) n;
update public.profiles set handle=h,display_name=dn from (values
 (1,'taste_a','에이'),(2,'b_han','비'),(3,'c_100','씨'),(4,'d_zero','디'),(5,'e_hidden','이')) v(n,h,dn)
 where id=('80000000-0000-0000-0000-00000000000'||n)::uuid;
insert into public.taste_profiles(user_id,priorities,discoverable) select ('80000000-0000-0000-0000-00000000000'||n)::uuid,p,d from (values
 (1,array['taste','value','ambience'],true),(2,array['taste','ambience','value'],true),
 (3,array['taste','value','ambience'],true),(4,array['photogenic','quiet','parking'],true),
 (5,array['taste','value','ambience'],false)) v(n,p,d);
select public.import_sbiz_places('[{"id":"taste-qa-a","name":"취향A","category":"한식","address":"서울 종로구","latitude":37.575,"longitude":126.985},
 {"id":"taste-qa-b","name":"취향B","category":"카페","address":"서울 종로구","latitude":37.576,"longitude":126.986}]','2026-09-30');
create temp table qa as select
 (select id from public.places where external_place_id='taste-qa-a') pa,
 (select id from public.places where external_place_id='taste-qa-b') pb;
create function pg_temp.w(u int, c text) returns numeric language sql as
 $$ select round(weight,2) from private.taste_weights(('80000000-0000-0000-0000-00000000000'||u)::uuid) where criterion=c $$;
create function pg_temp.handles(d jsonb) returns text[] language sql as
 $$ select coalesce(array_agg(e->>'handle' order by o),'{}') from jsonb_array_elements(d) with ordinality x(e,o) $$;

do $$ declare q qa; begin
 select * into q from qa;
 assert pg_temp.w(1,'taste')=50 and pg_temp.w(1,'value')=30 and pg_temp.w(1,'ambience')=20,'no evidence: 50/30/20';
 assert pg_temp.w(1,'quiet') is null,'non-priority criteria carry no weight';
 assert private.taste_match('80000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000002')=90,'50+20+20';
 assert private.taste_match('80000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000003')=100,'identical';
 assert private.taste_match('80000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000004')=0,'disjoint';

 -- Own rating: taste 5, value 1, ambience 3 -> learned 55.56/11.11/33.33, n=1.
 insert into public.place_ratings(user_id,place_id,criterion,rating) values
  ('80000000-0000-0000-0000-000000000001',q.pa,'taste',5),('80000000-0000-0000-0000-000000000001',q.pa,'value',1),
  ('80000000-0000-0000-0000-000000000001',q.pa,'ambience',3);
 assert pg_temp.w(1,'taste')=50.93 and pg_temp.w(1,'value')=26.85 and pg_temp.w(1,'ambience')=22.22,'own ratings blend 5:1';

 -- Saved place: others' ratings on a's priorities only (photogenic ignored, private ignored).
 insert into public.place_ratings(user_id,place_id,criterion,rating,is_public) values
  ('80000000-0000-0000-0000-000000000002',q.pb,'taste',1,true),('80000000-0000-0000-0000-000000000002',q.pb,'photogenic',5,true),
  ('80000000-0000-0000-0000-000000000003',q.pb,'value',5,false);
 insert into public.saved_places(user_id,place_id) values('80000000-0000-0000-0000-000000000001',q.pb);
 -- taste avg(5,1)=3, value 1, ambience 3 -> 42.86/14.29/42.86, n=2.
 assert pg_temp.w(1,'taste')=47.96 and pg_temp.w(1,'value')=25.51 and pg_temp.w(1,'ambience')=26.53,'saved place evidence';
 assert (select round(sum(weight),6) from private.taste_weights('80000000-0000-0000-0000-000000000001'))=100,'sums to 100';
 assert pg_temp.w(1,'photogenic') is null,'saved place non-priority rating ignored';
 delete from public.place_ratings; delete from public.saved_places;
end $$;

set local role authenticated;
set local request.jwt.claim.sub='80000000-0000-0000-0000-000000000001';
set local request.jwt.claims='{"is_anonymous":false}';
do $$ declare d jsonb; begin
 d:=public.get_taste_matches();
 assert pg_temp.handles(d)=array['c_100','b_han','d_zero'],'best match first; self and non-consenting excluded';
 assert (d->0->>'match')::int=100 and (d->1->>'match')::int=90 and (d->2->>'match')::int=0;
 assert pg_temp.handles(public.get_taste_matches(1,1))=array['b_han'],'limit/offset';

 insert into public.follows(follower_id,followee_id) values(auth.uid(),'80000000-0000-0000-0000-000000000003');
 assert pg_temp.handles(public.get_taste_matches())=array['b_han','d_zero'],'followed users drop out';

 d:=public.search_profiles('@C_1');
 assert pg_temp.handles(d)=array['c_100'] and (d->0->>'following')::boolean and (d->0->>'match')::int=100,'handle search, @ and case ignored';
 d:=public.search_profiles('이');
 assert pg_temp.handles(d)=array['e_hidden'] and d->0->'match'='null'::jsonb,'name search; non-consenting has no match';
 assert public.search_profiles('%')='[]'::jsonb and public.search_profiles('  ')='[]'::jsonb,'wildcards literal, blank empty';
 assert public.search_profiles('에이')='[]'::jsonb,'self excluded';

 begin
  insert into public.follows(follower_id,followee_id) values('80000000-0000-0000-0000-000000000002',auth.uid());
  raise exception 'forged follower accepted';
 exception when insufficient_privilege then null; end;
 begin
  insert into public.follows(follower_id,followee_id) values(auth.uid(),auth.uid());
  raise exception 'self follow accepted';
 exception when check_violation then null; end;
 delete from public.follows where followee_id='80000000-0000-0000-0000-000000000003';
 assert pg_temp.handles(public.get_taste_matches())=array['c_100','b_han','d_zero'],'unfollow restores';

 assert (select count(*) from public.taste_profiles)=1,'only own taste profile readable';
 begin
  update public.taste_profiles set priorities=array['taste','taste','value'];
  raise exception 'duplicate priorities accepted';
 exception when check_violation then null; end;
end $$;

set local request.jwt.claims='{"is_anonymous":true}';
do $$ begin
 insert into public.follows(follower_id,followee_id) values(auth.uid(),'80000000-0000-0000-0000-000000000002');
 raise exception 'anonymous follow accepted';
exception when insufficient_privilege then null; end $$;
reset role;
do $$ begin
 assert not has_function_privilege('anon','public.get_taste_matches(integer,integer)','execute');
 assert not has_function_privilege('anon','public.search_profiles(text,integer)','execute');
 assert not has_function_privilege('authenticated','private.taste_weights(uuid)','execute');
 assert to_regclass('public.friendships') is null,'friendships dropped';
end $$;
rollback;
\echo 'PASS: taste weights/evidence/match, recommendations, search, follow RLS, grants'
