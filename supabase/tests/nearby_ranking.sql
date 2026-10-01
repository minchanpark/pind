\set ON_ERROR_STOP on
begin;
-- 1 is me; I follow 2 (posted at A, shared save of A) and 3 (private save of A).
-- 4 is a stranger who saved A and B.
insert into auth.users(id) select ('93000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,4) n;
update public.profiles set display_name=dn,avatar_url='https://x/'||n||'.png'
 from (values (1,'나'),(2,'하람'),(3,'조용'),(4,'남')) v(n,dn) where id=('93000000-0000-0000-0000-00000000000'||n)::uuid;
insert into public.follows(follower_id,followee_id) values
 ('93000000-0000-0000-0000-000000000001','93000000-0000-0000-0000-000000000002'),
 ('93000000-0000-0000-0000-000000000001','93000000-0000-0000-0000-000000000003');
-- A ~0m, B ~1.1km, C unposted, D ~15km away.
select public.import_sbiz_places('[{"id":"near-qa-a","name":"가까운카페","category":"카페","address":"서울 종로구","latitude":37.5700,"longitude":126.9800},
 {"id":"near-qa-b","name":"조금먼카페","category":"카페","address":"서울 종로구","latitude":37.5800,"longitude":126.9800},
 {"id":"near-qa-c","name":"글없는카페","category":"카페","address":"서울 종로구","latitude":37.5710,"longitude":126.9800},
 {"id":"near-qa-d","name":"먼카페","category":"카페","address":"경기","latitude":37.7050,"longitude":126.9800}]','2026-10-01');
create temp table qa as select
 (select id from public.places where external_place_id='near-qa-a') a,
 (select id from public.places where external_place_id='near-qa-b') b,
 (select id from public.places where external_place_id='near-qa-d') d;
grant select on qa to authenticated;
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '93000000-0000-0000-0000-000000000002',p,'',p||'.png','☕','',pub,'published'
 from qa,lateral (values (qa.a,true),(qa.a,false),(qa.b,true),(qa.d,true)) v(p,pub);
insert into public.place_ratings(user_id,place_id,criterion,rating,is_public)
select '93000000-0000-0000-0000-000000000002',qa.a,c,r,true from qa,(values ('taste',4),('portion',2)) v(c,r);
insert into public.saved_places(user_id,place_id,share_with_friends)
select ('93000000-0000-0000-0000-00000000000'||u)::uuid,p,s from qa,lateral (values
 (1,qa.a,false),(2,qa.a,true),(3,qa.a,false),(4,qa.a,true),(4,qa.b,true)) v(u,p,s);

set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='93000000-0000-0000-0000-000000000001';
do $$ declare q qa; r jsonb; a jsonb; begin
 select * into q from qa;
 r:=public.get_nearby_ranking(37.5700,126.9800,10000);
 assert (select array_agg((e->>'internalId')::bigint) from jsonb_array_elements(r) e)=array[q.a,q.b],'posted, in radius, nearest first';
 a:=r->0;
 assert (a->>'meters')::int=0 and (r->1->>'meters')::int between 1000 and 1200,'distance in meters';
 assert a->'averages'='{"taste":4,"portion":2}'::jsonb,'public rating averages';
 assert (a->>'reviewCount')::int=1,'public posts only';
 assert (a->>'saveCount')::int=4 and (a->>'saved')::boolean,'every save counted; mine flagged';
 assert a->'visitedBy'='{"count":1,"people":[{"name":"하람","avatar":"https://x/2.png"}]}'::jsonb,'followed poster';
 assert a->'savedBy'->>'count'='1' and a->'savedBy'->'people'->0->>'name'='하람','followed shared save only';
 assert r->1->'savedBy'->>'count'='0' and not (r->1->>'saved')::boolean,'stranger save stays private';
 assert jsonb_array_length(public.get_nearby_ranking(37.5700,126.9800,20000))=3,'wider radius';
end $$;

reset role;
set local role anon;
do $$ begin
 begin perform public.get_nearby_ranking(37.57,126.98,10000); raise exception 'anon callable';
 exception when insufficient_privilege then null; end;
end $$;
rollback;
