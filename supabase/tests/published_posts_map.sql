\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('30000000-0000-0000-0000-000000000001'),('30000000-0000-0000-0000-000000000002');
select public.import_sbiz_places('[{"id":"post-qa-main","name":"게시검증카페","category":"카페","address":"서울 종로구","latitude":37.575,"longitude":126.985}]','2026-09-28');
select public.import_sbiz_places((select jsonb_agg(jsonb_build_object('id','post-qa-empty-'||n,'name','가까운 미게시 카페 '||n,
 'category','카페','address','서울 종로구','latitude',37.57,'longitude',126.98)) from generate_series(1,40) n),'2026-09-28');
set local role authenticated;
set local request.jwt.claim.sub='30000000-0000-0000-0000-000000000001';
set local request.jwt.claims='{"is_anonymous":false}';
do $$ declare p bigint; photo jsonb; photo2 jsonb; saved jsonb; data jsonb; removed integer;
begin
 select id into p from public.places where external_place_id='post-qa-main';
 assert jsonb_array_length(public.get_catalog_places(p_query=>'게시검증카페')->'places')=1,'unposted restaurant searchable';
 assert jsonb_array_length(public.get_catalog_places(p_lat=>37.57,p_lng=>126.98,p_radius=>1000)->'places')=0,'unposted excluded from map';
 assert not has_function_privilege('anon','public.publish_post_v2(uuid,bigint,integer,integer,integer,text,jsonb)','execute');
 assert not has_table_privilege('anon','public.post_media','select');
 photo:=jsonb_build_array(jsonb_build_object('path','30000000-0000-0000-0000-000000000001/40000000-0000-0000-0000-000000000001/50000000-0000-0000-0000-000000000001/0.png','mime','image/png','bytes',32));
 begin
  perform public.publish_post_v2('40000000-0000-0000-0000-000000000001',p,5,4,4,'',photo); raise exception 'Missing upload accepted';
 exception when others then assert sqlerrm='Photo must be uploaded by the current user'; end;
 insert into storage.objects(bucket_id,name,owner_id,metadata) values('post-media-v2',photo->0->>'path',auth.uid()::text,'{"mimetype":"image/png","size":32}');
 begin
  perform public.publish_post_v2('40000000-0000-0000-0000-000000000001',p,0,4,4,'',photo); raise exception 'Invalid rating accepted';
 exception when others then assert sqlerrm='Three ratings from 1 to 5 required'; end;
 begin
  perform public.publish_post_v2('40000000-0000-0000-0000-000000000001',p,5,4,4,repeat('가',201),photo); raise exception 'Long body accepted';
 exception when others then assert sqlerrm='Body exceeds 200 characters'; end;
 begin
  perform public.publish_post_v2('40000000-0000-0000-0000-000000000001',p,5,4,4,'','[]'); raise exception 'Zero photos accepted';
 exception when others then assert sqlerrm='Choose 1 to 10 photos'; end;
 begin
  perform public.publish_post_v2('40000000-0000-0000-0000-000000000001',p,5,4,4,'',photo||photo); raise exception 'Duplicate photos accepted';
 exception when others then assert sqlerrm='Duplicate photos'; end;
 assert (select count(*) from public.posts where place_id=p)=0,'failed validation left no partial post';
 saved:=public.publish_post_v2('40000000-0000-0000-0000-000000000001',p,5,4,4,'',photo);
 assert saved=public.publish_post_v2('40000000-0000-0000-0000-000000000001',p,5,4,4,'',photo),'idempotent retry';
 assert (select count(*) from public.posts where place_id=p)=1;
 assert (select count(*) from public.visits where post_id=(saved->>'id')::bigint)=1,'one visit';
 assert (select count(*) from public.post_media where post_id=(saved->>'id')::bigint)=1;
 assert (public.get_place_detail_context(p)->'mine'->>'taste')::numeric=5,'atomic rating';
 data:=public.get_catalog_places(p_lat=>37.57,p_lng=>126.98,p_radius=>1000);
 assert jsonb_array_length(data->'places')=1,'filter before limit: forty closer unposted places';
 assert (data->'places'->0->>'internalId')::bigint=p;
 data:=public.get_catalog_places();
 assert jsonb_array_length(data->'places')=1 and (data->'places'->0->>'internalId')::bigint=p,'no-arg lists every posted place only';
 assert data->'places'->0->>'pindPhotoBucket'='post-media-v2';
 delete from storage.objects where name=photo->0->>'path'; get diagnostics removed=row_count;
 assert removed=0,'cleanup cannot delete published media';
 photo2:=jsonb_build_array(jsonb_build_object('path','30000000-0000-0000-0000-000000000001/40000000-0000-0000-0000-000000000004/50000000-0000-0000-0000-000000000001/0.png','mime','image/png','bytes',32));
 insert into storage.objects(bucket_id,name,owner_id,metadata) values('post-media-v2',photo2->0->>'path',auth.uid()::text,'{"mimetype":"image/png","size":32}');
 begin
  perform public.publish_post_v3('40000000-0000-0000-0000-000000000004',p,'{"value":4,"quiet":2}','',photo2); raise exception 'Two ratings accepted';
 exception when others then assert sqlerrm='Three ratings from 1 to 5 required'; end;
 begin
  perform public.publish_post_v3('40000000-0000-0000-0000-000000000004',p,'{"value":4,"quiet":2,"price":5}','',photo2); raise exception 'Unknown criterion accepted';
 exception when others then assert sqlerrm='Three ratings from 1 to 5 required'; end;
 begin
  perform public.publish_post_v3('40000000-0000-0000-0000-000000000004',p,'{"value":4,"quiet":2.5,"parking":5}','',photo2); raise exception 'Fractional rating accepted';
 exception when others then assert sqlerrm='Three ratings from 1 to 5 required'; end;
 saved:=public.publish_post_v3('40000000-0000-0000-0000-000000000004',p,'{"value":4,"quiet":2,"parking":5}','',photo2);
 assert (select ratings from public.posts where id=(saved->>'id')::bigint)='{"value":4,"quiet":2,"parking":5}'::jsonb;
 assert (public.get_place_detail_context(p)->'mine'->>'quiet')::numeric=2,'priority ratings';
 data:=public.get_catalog_places(p_place_id=>p)->'places'->0;
 assert jsonb_array_length(data->'pindPosts')=2 and data->'pindPosts'->0->'photos'->>0=photo2->0->>'path','detail posts newest first';
 assert data->'pindPosts'->0->'ratings'='{"value":4,"quiet":2,"parking":5}'::jsonb and data->'pindPosts'->1->'ratings'='{"taste":5,"portion":4,"ambience":4}'::jsonb,'v3 and legacy ratings';
 update public.profiles set handle='map_author' where id=auth.uid();
 data:=public.get_catalog_places(p_place_id=>p)->'places'->0;
 assert data->'pindPosts'->0->>'handle'='map_author','posts carry the author handle';
 assert jsonb_typeof(data->'insight')='null','no insight before first refresh';
 assert public.get_catalog_places(p_lat=>37.57,p_lng=>126.98,p_radius=>1000)->'places'->0->'pindPosts'='null'::jsonb,'map skips posts';
 assert not has_function_privilege('authenticated','public.claim_place_insight(bigint)','execute');
 assert not has_table_privilege('authenticated','public.place_insights','update');
end $$;
reset role;
set local role service_role;
do $$ declare p bigint; begin
 select id into p from public.places where external_place_id='post-qa-main';
 assert public.claim_place_insight(p),'first claim wins';
 assert public.claim_place_insight(p) is null,'concurrent claim rejected';
 update public.place_insights set summary='소개',criteria='{"taste":"맛있어요"}',post_count=2,claimed_at=now()-interval '3 minutes' where place_id=p;
 assert public.claim_place_insight(p),'stale claim expires';
end $$;
reset role;
set local role authenticated;
do $$ begin
 assert public.get_catalog_places(p_place_id=>(select id from public.places where external_place_id='post-qa-main'))
  ->'places'->0->'insight'='{"summary":"소개","criteria":{"taste":"맛있어요"},"postCount":2}'::jsonb,'insight readable';
end $$;
set local request.jwt.claim.sub='30000000-0000-0000-0000-000000000002';
do $$ declare p bigint; begin
 select id into p from public.places where external_place_id='post-qa-main';
 assert (select count(*) from public.post_media)=2,'published media readable by another user';
 assert (select count(*) from storage.objects where bucket_id='post-media-v2')=2,'signed access authorized';
 begin
  perform public.publish_post_v2('40000000-0000-0000-0000-000000000002',p,5,4,4,'',
   '[{"path":"30000000-0000-0000-0000-000000000001/40000000-0000-0000-0000-000000000001/50000000-0000-0000-0000-000000000001/0.png","mime":"image/png","bytes":32}]');
  raise exception 'Other user photo accepted';
 exception when others then assert sqlerrm='Invalid photo metadata'; end;
 begin
  insert into storage.objects(bucket_id,name,owner_id,metadata) values('post-media-v2','30000000-0000-0000-0000-000000000001/forged.png',auth.uid()::text,'{}');
  raise exception 'Other user folder accepted';
 exception when insufficient_privilege then null; end;
end $$;
set local request.jwt.claim.sub='30000000-0000-0000-0000-000000000001';
set local request.jwt.claims='{"is_anonymous":true}';
do $$ begin
 begin
  perform public.publish_post_v2('40000000-0000-0000-0000-000000000003',1,5,4,4,'','[]'); raise exception 'Anonymous publish accepted';
 exception when insufficient_privilege then null; end;
end $$;
set local request.jwt.claims='{"is_anonymous":false}';
update public.posts set status='hidden' where place_id=(select id from public.places where external_place_id='post-qa-main');
do $$ begin assert jsonb_array_length(public.get_catalog_places(p_lat=>37.57,p_lng=>126.98,p_radius=>1000)->'places')=0,'hidden last post removes pin'; end $$;
set local request.jwt.claim.sub='30000000-0000-0000-0000-000000000002';
do $$ begin
 assert (select count(*) from public.post_media)=0,'hidden media unreadable';
 assert (select count(*) from storage.objects where bucket_id='post-media-v2')=0,'hidden signed access denied';
end $$;
set local request.jwt.claim.sub='30000000-0000-0000-0000-000000000001';
delete from public.posts where place_id=(select id from public.places where external_place_id='post-qa-main');
do $$ begin
 assert jsonb_array_length(public.get_catalog_places(p_lat=>37.57,p_lng=>126.98,p_radius=>1000)->'places')=0,'deleted last post removes pin';
 assert (select count(*) from public.post_media)=0,'media references cascade';
end $$;
rollback;
\echo 'PASS: posted-only map, searchable catalog, media privacy, atomic ratings, priority ratings, idempotency, deletion, detail photos, insight claims'
