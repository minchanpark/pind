\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('60000000-0000-0000-0000-000000000001'),
 ('60000000-0000-0000-0000-000000000002'),('60000000-0000-0000-0000-000000000003');
select public.import_sbiz_places('[{"id":"profile-qa-a","name":"프로필A","category":"카페","address":"서울 종로구","latitude":37.575,"longitude":126.985},
 {"id":"profile-qa-b","name":"프로필B","category":"식당","address":"서울 종로구","latitude":37.576,"longitude":126.986},
 {"id":"profile-qa-c","name":"프로필C","category":"카페","address":"서울 종로구","latitude":37.577,"longitude":126.987}]','2026-09-29');
create temp table qa as select
 (select id from public.places where external_place_id='profile-qa-a') a,
 (select id from public.places where external_place_id='profile-qa-b') b,
 (select id from public.places where external_place_id='profile-qa-c') c;
grant select on qa to authenticated;
insert into public.follows(follower_id,followee_id) values
 ('60000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000002'),
 ('60000000-0000-0000-0000-000000000003','60000000-0000-0000-0000-000000000001'),
 ('60000000-0000-0000-0000-000000000002','60000000-0000-0000-0000-000000000001');
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status,created_at,
 client_request_id,taste_score,portion_score,ambience_score)
select u::uuid,case k when 'a' then qa.a when 'b' then qa.b else qa.c end,'',photo,'☕',body,pub,st,now()-age,req::uuid,t,po,am from qa,(values
 ('60000000-0000-0000-0000-000000000001','a','legacy/a.png','legacy',true,'published',interval '2 days',null,null,null,null),
 ('60000000-0000-0000-0000-000000000001','b','60000000-0000-0000-0000-000000000001/r/0.png','v2 body',true,'published',interval '1 day','70000000-0000-0000-0000-000000000001',5,4,3),
 ('60000000-0000-0000-0000-000000000001','c','hidden.png','hidden',true,'hidden',interval '1 hour',null,null,null,null),
 ('60000000-0000-0000-0000-000000000001','c','private.png','private',false,'published',interval '1 hour',null,null,null,null),
 ('60000000-0000-0000-0000-000000000002','a','u2/a.png','friend',true,'published',interval '1 hour',null,null,null,null)
) v(u,k,photo,body,pub,st,age,req,t,po,am);
insert into public.post_media(post_id,position,path,mime,bytes)
select id,pos,'60000000-0000-0000-0000-000000000001/r/'||pos||'.png','image/png',32
from public.posts,(values(1),(0)) v(pos) where client_request_id='70000000-0000-0000-0000-000000000001';
insert into public.place_ratings(user_id,place_id,criterion,rating,is_public) select u::uuid,qa.a,cr,r,pub from qa,(values
 ('60000000-0000-0000-0000-000000000001','taste',5,true),('60000000-0000-0000-0000-000000000002','taste',3,true),
 ('60000000-0000-0000-0000-000000000002','ambience',4,true),('60000000-0000-0000-0000-000000000003','taste',1,false)) v(u,cr,r,pub);
insert into public.saved_places(user_id,place_id,saved_at) select u::uuid,p,now()-age from qa,lateral (values
 ('60000000-0000-0000-0000-000000000001',qa.a,interval '1 hour'),('60000000-0000-0000-0000-000000000001',qa.b,interval '10 minutes'),
 ('60000000-0000-0000-0000-000000000002',qa.c,interval '0')) v(u,p,age);
insert into public.place_views(user_id,place_id,viewed_at) select u::uuid,p,now()-age from qa,lateral (values
 ('60000000-0000-0000-0000-000000000001',qa.a,interval '1 hour'),('60000000-0000-0000-0000-000000000001',qa.c,interval '2 hours'),
 ('60000000-0000-0000-0000-000000000001',qa.b,interval '25 hours'),('60000000-0000-0000-0000-000000000002',qa.a,interval '30 hours')) v(u,p,age);
set local role authenticated;
set local request.jwt.claim.sub='60000000-0000-0000-0000-000000000001';
set local request.jwt.claims='{"is_anonymous":false}';
do $$ begin
 assert not has_function_privilege('anon','public.get_my_profile_overview()','execute');
 assert not has_function_privilege('anon','public.record_place_view(bigint)','execute');
 begin update public.profiles set handle='No' where id=auth.uid(); raise exception 'Bad handle accepted';
 exception when check_violation then null; end;
 begin update public.profiles set bio=repeat('가',81) where id=auth.uid(); raise exception 'Long bio accepted';
 exception when check_violation then null; end;
 update public.profiles set handle='pind_me',bio='hello' where id=auth.uid();
 begin update public.profiles set handle='pind_new' where id=auth.uid(); raise exception 'Handle changed';
 exception when others then assert sqlerrm='handle is immutable'; end;
 update public.profiles set handle='pind_me',display_name='민찬' where id=auth.uid();
 insert into storage.objects(bucket_id,name,owner_id) values('avatars',auth.uid()||'/me.png',auth.uid()::text);
end $$;
set local request.jwt.claim.sub='60000000-0000-0000-0000-000000000002';
do $$ declare n integer; begin
 update public.profiles set bio='hacked' where id='60000000-0000-0000-0000-000000000001'; get diagnostics n=row_count;
 assert n=0,'other user cannot update my profile';
 begin update public.profiles set handle='pind_me' where id=auth.uid(); raise exception 'Duplicate handle accepted';
 exception when unique_violation then null; end;
 begin
  insert into storage.objects(bucket_id,name,owner_id) values('avatars','60000000-0000-0000-0000-000000000001/x.png',auth.uid()::text);
  raise exception 'Other avatar folder accepted';
 exception when insufficient_privilege then null; end;
end $$;
set local request.jwt.claim.sub='60000000-0000-0000-0000-000000000001';
do $$ declare q qa; d jsonb; begin
 select * into q from qa;
 d:=public.get_my_profile_overview();
 assert d ?& array['profile','counts','recentViews','savedPlaces','posts'];
 assert d->'profile'=jsonb_build_object('id',auth.uid(),'handle','pind_me','displayName','민찬','avatarUrl',null,'bio','hello'),'profile';
 assert d->'counts'='{"followers":2,"following":1,"posts":2,"saved":2}'::jsonb,'counts exclude hidden/private';
 assert jsonb_array_length(d->'recentViews')=2,'>24h view excluded';
 assert (d->'recentViews'->0->>'internalId')::bigint=q.a and (d->'recentViews'->1->>'internalId')::bigint=q.c,'views newest first';
 assert d->'recentViews'->0 ?& array['provider','internalId','externalPlaceId','name','category','address','latitude',
  'longitude','sourceUri','heroImageUrl','pindPhotoPath','pindPhotoBucket']
  and (select count(*) from jsonb_object_keys(d->'recentViews'->0))=12,'place summary keys';
 assert d->'recentViews'->0->>'pindPhotoPath'='u2/a.png' and d->'recentViews'->0->>'pindPhotoBucket'='post-media','latest public photo';
 assert d->'recentViews'->1->'pindPhotoPath'='null'::jsonb,'hidden/private posts give no photo';
 assert (d->'savedPlaces'->0->>'internalId')::bigint=q.b and (d->'savedPlaces'->1->>'internalId')::bigint=q.a,'saved newest first';
 assert d->'savedPlaces'->0->'averages'='{}'::jsonb and d->'savedPlaces'->0->>'pindPhotoBucket'='post-media-v2';
 assert (d->'savedPlaces'->1->'averages'->>'taste')::numeric=4 and (d->'savedPlaces'->1->'averages'->>'ambience')::numeric=4,'public averages';
 assert jsonb_array_length(d->'posts')=2,'published public posts only';
 assert d->'posts'->0 ?& array['id','place','body','ratings','bucket','photos','createdAt']
  and (select count(*) from jsonb_object_keys(d->'posts'->0))=7,'post keys';
 assert (d->'posts'->0->'place'->>'internalId')::bigint=q.b and d->'posts'->0->>'body'='v2 body';
 assert d->'posts'->0->>'bucket'='post-media-v2' and d->'posts'->0->'ratings'='{"taste":5,"portion":4,"ambience":3}'::jsonb;
 assert d->'posts'->0->'photos'='["60000000-0000-0000-0000-000000000001/r/0.png","60000000-0000-0000-0000-000000000001/r/1.png"]'::jsonb,'position order';
 assert (d->'posts'->0->>'createdAt')::timestamptz=now()-interval '1 day','ISO createdAt';
 assert d->'posts'->1->>'bucket'='post-media' and d->'posts'->1->'photos'='["legacy/a.png"]'::jsonb and d->'posts'->1->'ratings'='{}'::jsonb,'legacy post';
 update public.place_views set viewed_at=now()-interval '3 hours' where place_id=q.c;
 perform public.record_place_view(q.c);
 perform public.record_place_view(q.c);
 assert (select count(*) from public.place_views where place_id=q.c)=1,'upsert keeps one row';
 assert (select viewed_at from public.place_views where place_id=q.c)=now(),'viewed_at moves forward';
 assert not exists(select 1 from public.place_views where place_id=q.b),'own >24h row purged';
end $$;
set local request.jwt.claims='{"is_anonymous":true}';
do $$ begin
 insert into storage.objects(bucket_id,name,owner_id) values('avatars',auth.uid()||'/anon.png',auth.uid()::text);
 raise exception 'Anonymous avatar accepted';
exception when insufficient_privilege then null; end $$;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='60000000-0000-0000-0000-000000000003';
do $$ declare d jsonb := public.get_my_profile_overview(); begin
 assert d->'counts'='{"followers":0,"following":1,"posts":0,"saved":0}'::jsonb,'user 3 follows one, has no followers';
 assert d->'recentViews'='[]'::jsonb and d->'savedPlaces'='[]'::jsonb and d->'posts'='[]'::jsonb,'empty arrays';
end $$;
set local request.jwt.claim.sub='';
do $$ begin assert public.get_my_profile_overview() is null,'no user, no data'; end $$;
set local role anon;
do $$ begin
 begin perform public.get_my_profile_overview(); raise exception 'Anon overview allowed';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
do $$ begin
 assert exists(select 1 from public.place_views where user_id='60000000-0000-0000-0000-000000000002'),'other user rows untouched';
 assert (select bio from public.profiles where id='60000000-0000-0000-0000-000000000001')='hello';
 assert (select public from storage.buckets where id='avatars');
end $$;
rollback;
\echo 'PASS: profile handle/bio rules, profile RLS, avatar folders, 24h recent views, profile overview shape'
