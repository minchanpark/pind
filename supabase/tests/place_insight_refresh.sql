\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values ('92000000-0000-0000-0000-000000000001');
select public.import_sbiz_places('[{"id":"ins-qa-a","name":"요약A","category":"한식","address":"서울 종로구","latitude":37.575,"longitude":126.985},
 {"id":"ins-qa-b","name":"요약B","category":"한식","address":"서울 종로구","latitude":37.576,"longitude":126.986}]','2026-10-01');
create temp table qa as select
 (select id from public.places where external_place_id='ins-qa-a') a,
 (select id from public.places where external_place_id='ins-qa-b') b;
create temp view sent as select (convert_from(body,'utf8')::jsonb->>'refreshInsight')::bigint place_id from net.http_request_queue;

-- No Vault secrets: posts still publish and nothing is sent.
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '92000000-0000-0000-0000-000000000001',a,'','x.png','🍚','첫 글',true,'published' from qa;
do $$ begin assert (select count(*) from sent)=0,'no secrets, no request'; end $$;

select vault.create_secret('https://example.supabase.co','project_url');
select vault.create_secret('service-key','service_role_key');
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '92000000-0000-0000-0000-000000000001',a,'','y.png','🍚','둘째 글',true,'published' from qa;
create temp table p as select id from public.posts where body='둘째 글';
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '92000000-0000-0000-0000-000000000001',b,'','z.png','🍚','비공개',false,'published' from qa;
do $$ declare q qa; r record; begin
 select * into q from qa;
 assert (select array_agg(place_id) from sent)=array[q.a],'public post queues its place; private does not';
 select url, headers into r from net.http_request_queue limit 1;
 assert r.url='https://example.supabase.co/functions/v1/places','function url';
 assert r.headers->>'Authorization'='Bearer service-key','service key';
end $$;

-- Moving a post refreshes both places; hiding or deleting refreshes the old one.
delete from net.http_request_queue;
update public.posts set place_id=(select b from qa) where id=(select id from p);
do $$ declare q qa; begin select * into q from qa;
 assert (select array_agg(place_id order by place_id) from sent)=(select array_agg(x order by x) from unnest(array[q.a,q.b]) x),'move hits both'; end $$;
delete from net.http_request_queue;
update public.posts set is_public=false where id=(select id from p);
delete from public.posts where id=(select id from p);
do $$ declare q qa; begin select * into q from qa;
 assert (select array_agg(place_id) from sent)=array[q.b],'hide queues once; deleting a hidden post queues nothing'; end $$;

-- A recorded failure holds the claim for a minute, then frees it.
do $$ declare q qa; begin select * into q from qa;
 assert public.claim_place_insight(q.a),'first claim';
 assert public.claim_place_insight(q.a) is null,'claimed';
 update public.place_insights set claimed_at=null,failed_at=now(),last_error='503' where place_id=q.a;
 assert public.claim_place_insight(q.a) is null,'backoff after failure';
 update public.place_insights set failed_at=now()-interval '2 minutes' where place_id=q.a;
 assert public.claim_place_insight(q.a),'retry after a minute';
end $$;

-- The 5-minute retry picks failed, stale and missing insights only.
delete from net.http_request_queue;
do $$ declare q qa; begin select * into q from qa;
 -- a: failed; b: no public posts left, but its row still counts 1 (stale).
 update public.place_insights set failed_at=now(),post_count=1 where place_id=q.a;
 insert into public.place_insights(place_id,post_count) values(q.b,1);
 assert public.retry_place_insights()=2,'failed + stale';
 assert (select array_agg(place_id order by place_id) from sent)=(select array_agg(x order by x) from unnest(array[q.a,q.b]) x),'both requested';
 delete from net.http_request_queue;
 update public.place_insights set failed_at=null where place_id=q.a;
 update public.place_insights set post_count=0 where place_id=q.b;
 assert public.retry_place_insights()=0,'up-to-date insights are left alone';
 assert exists(select 1 from cron.job where jobname='retry-place-insights' and schedule='*/5 * * * *'),'scheduled';
end $$;

set local role authenticated;
do $$ begin
 begin perform public.retry_place_insights(); raise exception 'retry callable';
 exception when insufficient_privilege then null; end;
 begin perform public.request_place_insight(1); raise exception 'callable';
 exception when insufficient_privilege then null; end;
end $$;
rollback;
