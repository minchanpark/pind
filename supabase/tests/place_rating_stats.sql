\set ON_ERROR_STOP on
begin;
insert into auth.users(id) select ('a1000000-0000-0000-0000-00000000000'||n)::uuid
from generate_series(1,3) n;
select public.import_sbiz_places('[
 {"id":"stats-qa-a","name":"집계A","category":"한식","address":"서울 종로구","latitude":37.575,"longitude":126.985},
 {"id":"stats-qa-b","name":"집계B","category":"한식","address":"서울 종로구","latitude":37.576,"longitude":126.986}
]', '2026-10-01');
create temp table qa as select
 (select id from public.places where external_place_id='stats-qa-a') a,
 (select id from public.places where external_place_id='stats-qa-b') b;
grant select on qa to authenticated;
insert into public.saved_places(user_id,place_id,share_with_friends)
select ('a1000000-0000-0000-0000-00000000000'||n)::uuid,a,true from qa,generate_series(1,2) n;
insert into public.follows(follower_id,followee_id) values
 ('a1000000-0000-0000-0000-000000000001','a1000000-0000-0000-0000-000000000002');
insert into public.place_ratings(user_id,place_id,criterion,rating,is_public)
select u::uuid,a,c,r,p from qa,(values
 ('a1000000-0000-0000-0000-000000000001','taste',5,true),
 ('a1000000-0000-0000-0000-000000000002','taste',3,true),
 ('a1000000-0000-0000-0000-000000000003','taste',1,false),
 ('a1000000-0000-0000-0000-000000000001','portion',3,true),
 ('a1000000-0000-0000-0000-000000000001','ambience',2,true)
) v(u,c,r,p);
do $$ begin
 assert (select average=4 and rating_sum=8 and rating_count=2
   from public.place_rating_stats,qa where place_id=a and criterion='taste');
 assert (select rating_count=1 from public.place_rating_stats,qa where place_id=a and criterion='portion');
 assert not has_table_privilege('authenticated','public.place_rating_stats','insert');
 assert not has_table_privilege('authenticated','public.place_rating_stats','update');
 assert not has_table_privilege('authenticated','public.place_rating_stats','delete');
 assert not has_table_privilege('anon','public.place_rating_stats','select');
 assert not has_function_privilege('authenticated','private.rebuild_place_rating_stats()','execute');
end $$;
set local role authenticated;
set local request.jwt.claim.sub='a1000000-0000-0000-0000-000000000001';
do $$ declare d jsonb; s jsonb; other jsonb; begin
 d:=public.get_place_detail_context((select a from qa));
 assert d->'averages'='{"taste":4,"portion":3,"ambience":2}'::jsonb;
 assert d->'ratingCounts'='{"taste":2,"portion":1,"ambience":1}'::jsonb;
 assert (d->'mine'->>'taste')::numeric=5;
 s:=public.get_my_profile_overview()->'savedPlaces'->0;
 other:=public.get_profile_overview('a1000000-0000-0000-0000-000000000002')->'savedPlaces'->0;
 assert s->'averages'=d->'averages' and other->'averages'=d->'averages';
 assert s->'ratingCounts'=d->'ratingCounts' and other->'ratingCounts'=d->'ratingCounts';
 assert s ? 'savedAt' and s ? 'reviewCount' and s ? 'savers';
 begin
   update public.place_rating_stats set rating_sum=0;
   raise exception 'client changed aggregate';
 exception when insufficient_privilege then null;
 end;
 update public.place_ratings set rating=3
   where user_id=auth.uid() and place_id=(select a from qa) and criterion='taste';
 assert (public.get_place_detail_context((select a from qa))->'averages'->>'taste')::numeric=3;
end $$;
reset role;
set local request.jwt.claim.sub='a1000000-0000-0000-0000-000000000002';
do $$ begin
 assert (public.get_place_detail_context((select a from qa))->'averages'->>'taste')::numeric=3;
end $$;
update public.place_ratings set is_public=true
where user_id='a1000000-0000-0000-0000-000000000003' and place_id=(select a from qa);
do $$ begin
 assert (select rating_sum=7 and rating_count=3 and average=7::numeric/3
   from public.place_rating_stats,qa where place_id=a and criterion='taste');
end $$;
update public.place_ratings set is_public=false
where user_id='a1000000-0000-0000-0000-000000000003' and place_id=(select a from qa);
update public.place_ratings set rating=5
where user_id='a1000000-0000-0000-0000-000000000003' and place_id=(select a from qa);
savepoint rating_change;
delete from public.place_ratings where place_id=(select a from qa) and criterion='taste';
do $$ begin
 assert (select average is null and rating_count=0 and rating_sum=0
   from public.place_rating_stats,qa where place_id=a and criterion='taste');
 assert not (public.get_place_detail_context((select a from qa))->'averages' ? 'taste');
end $$;
rollback to rating_change;
do $$ begin
 assert (select average=3 and rating_count=2 from public.place_rating_stats,qa
   where place_id=a and criterion='taste'), 'transaction rollback';
end $$;
update public.place_ratings set place_id=(select b from qa),criterion='quiet'
where user_id='a1000000-0000-0000-0000-000000000001'
  and place_id=(select a from qa) and criterion='portion';
do $$ begin
 assert (select average is null and rating_count=0 from public.place_rating_stats,qa
   where place_id=a and criterion='portion');
 assert (select average=3 and rating_count=1 from public.place_rating_stats,qa
   where place_id=b and criterion='quiet');
end $$;
delete from public.place_rating_stats;
select private.rebuild_place_rating_stats();
do $$ begin
 assert not exists (
   select 1 from (
     select place_id,criterion,sum(rating) s,count(*) n from public.place_ratings
       where is_public group by place_id,criterion
   ) r full join public.place_rating_stats a using(place_id,criterion)
   where r.s is distinct from a.rating_sum or r.n is distinct from a.rating_count
 ), 'backfill equals source ratings';
end $$;
delete from auth.users where id='a1000000-0000-0000-0000-000000000001';
delete from public.places where id=(select b from qa);
do $$ begin
 assert not exists(select 1 from public.place_rating_stats,qa where place_id=b);
 assert (select average=3 and rating_count=1 from public.place_rating_stats,qa
   where place_id=a and criterion='taste');
end $$;
select 'PASS: aggregates, counts, RLS, card RPCs, lifecycle, rollback and recovery';
rollback;
