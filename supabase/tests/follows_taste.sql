\set ON_ERROR_STOP on
begin;
-- a..e = 1..5. a: taste>value>ambience. b swaps value/ambience (90%), c equals a (100%),
-- d shares nothing (24%), e equals a but has not consented to recommendations.
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
create function pg_temp.star(u int, c text) returns numeric language sql as
 $$ select round(star,4) from private.taste_stars(('80000000-0000-0000-0000-00000000000'||u)::uuid) where criterion=c $$;
create function pg_temp.w(u int, c text) returns numeric language sql as
 $$ select round(weight,2) from private.taste_stars(('80000000-0000-0000-0000-00000000000'||u)::uuid) where criterion=c $$;
create function pg_temp.n(u int, c text) returns bigint language sql as
 $$ select evidence from private.taste_stars(('80000000-0000-0000-0000-00000000000'||u)::uuid) where criterion=c $$;
create function pg_temp.m(a int, b int) returns integer language sql as
 $$ select private.taste_match(('80000000-0000-0000-0000-00000000000'||a)::uuid,('80000000-0000-0000-0000-00000000000'||b)::uuid) $$;
create function pg_temp.handles(d jsonb) returns text[] language sql as
 $$ select coalesce(array_agg(e->>'handle' order by o),'{}') from jsonb_array_elements(d) with ordinality x(e,o) $$;

-- Golden numbers shared with test/preferences_test.dart.
do $$ declare t jsonb; begin
 assert public.taste_star(4.3,4.3)=3 and public.taste_star(5,4.3)=5 and public.taste_star(1,4.3)=1,'average→3, ends fixed';
 assert round(public.taste_star(4.7,4.3),2)=4.14 and round(public.taste_star(4,4.3),2)=2.82,'linear on each side';
 assert public.taste_star(4,null)=3,'no average reads as 3';
 -- Start state: priorities taste·portion·ambience, Pind averages 4.3·4.0·3.9.
 t:='{"stars":{"taste":5,"portion":4.2,"ambience":3.8,"value":3},"weights":{"taste":50,"portion":30,"ambience":20,"value":0},
   "averages":{"taste":4.3,"portion":4.0,"ambience":3.9}}';
 assert public.taste_place_match(t,'{"taste":5,"portion":5,"ambience":5}')=100;
 assert public.taste_place_match(t,'{"taste":4.8,"portion":4.0,"ambience":3.9}')=76;
 assert public.taste_place_match(t,'{"taste":4,"portion":4,"ambience":4}')=57;
 assert public.taste_place_match(t,'{"taste":4,"portion":3,"ambience":2}')=40;
 assert public.taste_place_match(t,'{"taste":5,"portion":5}') is null,'unrated 20% leaves it unknown';
 assert public.taste_place_match(null,'{"taste":5}') is null,'no taste, no %';
 t:='{"stars":{"taste":5,"value":4,"ambience":3.9091,"quiet":3.1818},"weights":{"taste":48.8889,"value":24.4444,"ambience":22.2222,"quiet":4.4444},
   "averages":{"taste":4,"value":3,"ambience":4,"quiet":3}}';
 assert public.taste_place_match(t,'{"taste":5,"value":5,"ambience":5}')=100,'unrated under 20% is left out';
end $$;

do $$ declare q qa; begin
 select * into q from qa;
 assert pg_temp.star(1,'taste')=5 and pg_temp.star(1,'value')=4.2 and pg_temp.star(1,'ambience')=3.8
   and pg_temp.star(1,'quiet')=3,'start stars 5/4.2/3.8, 3 elsewhere';
 assert pg_temp.w(1,'taste')=50 and pg_temp.w(1,'value')=30 and pg_temp.w(1,'ambience')=20
   and pg_temp.w(1,'quiet')=0,'start is exactly 50/30/20';
 assert pg_temp.m(1,2)=90,'swapped 2nd/3rd';
 assert pg_temp.m(1,3)=100,'identical';
 assert pg_temp.m(1,4)=24,'disjoint priorities';

 -- d and e rate (Pind averages: taste 4, value 3, ambience 4, photogenic 5, quiet 3);
 -- a rates value 2 at pa and saves pb.
 insert into public.place_ratings(user_id,place_id,criterion,rating) values
  ('80000000-0000-0000-0000-000000000004',q.pb,'taste',5),('80000000-0000-0000-0000-000000000004',q.pb,'value',4),
  ('80000000-0000-0000-0000-000000000004',q.pb,'ambience',5),('80000000-0000-0000-0000-000000000004',q.pb,'photogenic',5),
  ('80000000-0000-0000-0000-000000000004',q.pb,'quiet',5),
  ('80000000-0000-0000-0000-000000000005',q.pa,'taste',3),('80000000-0000-0000-0000-000000000005',q.pa,'ambience',3),
  ('80000000-0000-0000-0000-000000000005',q.pa,'quiet',1),
  ('80000000-0000-0000-0000-000000000001',q.pa,'value',2);
 insert into public.saved_places(user_id,place_id) values('80000000-0000-0000-0000-000000000001',q.pb);
 -- value: my 2 → 2, pb's 4 → 4, mean 3 over n=2 → 4.2 + 2/12·(3 − 4.2) = 4.0
 assert pg_temp.star(1,'taste')=5 and pg_temp.star(1,'value')=4 and pg_temp.star(1,'ambience')=3.9091,'evidence moves stars';
 assert pg_temp.star(1,'quiet')=3.1818 and pg_temp.star(1,'photogenic')=3,'a non-priority rises only above the average';
 assert pg_temp.n(1,'value')=2 and pg_temp.n(1,'ambience')=1,'one per place and criterion';
 assert pg_temp.w(1,'taste')=48.89 and pg_temp.w(1,'value')=24.44 and pg_temp.w(1,'ambience')=22.22
   and pg_temp.w(1,'quiet')=4.44,'weights follow the stars';
 assert (select round(sum(weight),6) from private.taste_stars('80000000-0000-0000-0000-000000000001'))=100,'sums to 100';
 assert pg_temp.m(1,2)=94,'friend % moves with my taste';

 -- My own rating wins over the saved place's average: taste avg becomes 11/3,
 -- my 3 → 2.5, so 5 + (2.5 − 5)/11.
 insert into public.place_ratings(user_id,place_id,criterion,rating) values
  ('80000000-0000-0000-0000-000000000001',q.pb,'taste',3);
 assert pg_temp.star(1,'taste')=4.7727 and pg_temp.n(1,'taste')=1,'own rating replaces the saved average';

 delete from public.place_ratings; delete from public.saved_places;
end $$;

set local role authenticated;
set local request.jwt.claim.sub='80000000-0000-0000-0000-000000000001';
set local request.jwt.claims='{"is_anonymous":false}';
do $$ declare d jsonb; begin
 d:=public.get_my_taste();
 assert d->'priorities'='["taste","value","ambience"]'::jsonb and (d->>'evidence')::int=0,'my taste: priorities, no evidence';
 assert (d->'stars'->>'taste')::numeric=5 and (d->'weights'->>'value')::numeric=30
   and (d->'weights'->>'quiet')::numeric=0,'my taste: start stars and weights';
 d:=public.get_taste_matches();
 assert pg_temp.handles(d)=array['c_100','b_han','d_zero'],'best match first; self and non-consenting excluded';
 assert (d->0->>'match')::int=100 and (d->1->>'match')::int=90 and (d->2->>'match')::int=24;
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
 assert not has_function_privilege('authenticated','private.taste_stars(uuid)','execute');
 assert not has_function_privilege('anon','public.get_my_taste()','execute');
 assert to_regclass('public.friendships') is null,'friendships dropped';
end $$;
rollback;
\echo 'PASS: taste stars/evidence/place %/friend %, my taste, recommendations, search, follow RLS, grants'
