\set ON_ERROR_STOP on
begin;
-- 1 me, 2 a friend I follow (and who follows me), 3 a stranger.
insert into auth.users(id) select ('96000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,3) n;
update public.profiles set display_name=v.n, handle=v.h from (values
  ('96000000-0000-0000-0000-000000000001'::uuid,'나','me_'),
  ('96000000-0000-0000-0000-000000000002'::uuid,'하람','haram'),
  ('96000000-0000-0000-0000-000000000003'::uuid,'모르는','stranger')) v(id,n,h)
where profiles.id=v.id;
select public.import_sbiz_places('[{"id":"noti-a","name":"을지로 숯불갈비","category":"돼지고기 구이/찜","address":"서울 중구","latitude":37.566,"longitude":126.991}]','2026-10-01');
create temp table qa as select (select id from public.places where external_place_id='noti-a') a;
grant select on qa to authenticated;
insert into public.follows(follower_id,followee_id,created_at) values
  ('96000000-0000-0000-0000-000000000001','96000000-0000-0000-0000-000000000002',now()-interval '3 days'),
  ('96000000-0000-0000-0000-000000000002','96000000-0000-0000-0000-000000000001',now()-interval '1 day');
-- My post (liked by the friend), the friend's post, a stranger's post, and
-- an old friend post past 30 days.
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status,created_at)
select v.a::uuid,qa.a,'',v.b||'.jpg','🍖',v.b,true,'published',now()-v.ago from qa,(values
  ('96000000-0000-0000-0000-000000000001','mine',interval '5 hours'),
  ('96000000-0000-0000-0000-000000000002','friend',interval '3 hours'),
  ('96000000-0000-0000-0000-000000000003','stranger',interval '2 hours'),
  ('96000000-0000-0000-0000-000000000002','old',interval '40 days')) v(a,b,ago);
insert into public.post_likes(user_id,post_id,created_at)
select '96000000-0000-0000-0000-000000000002',id,now()-interval '1 hour' from public.posts where body='mine';
-- I like my own post: no notification for that.
insert into public.post_likes(user_id,post_id) select '96000000-0000-0000-0000-000000000001',id from public.posts where body='mine';

set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='96000000-0000-0000-0000-000000000001';
do $$ declare q qa; r jsonb; items jsonb; begin select * into q from qa;
 r:=public.get_notifications();
 items:=r->'items';
 assert (select array_agg(e->>'kind') from jsonb_array_elements(items) e)=array['like','visit','follow'],
   'like (1h), friend visit (3h), follow (1d); no stranger post, no self like, nothing past 30 days';
 assert items->0->'actor'->>'handle'='haram' and items->0->'actor'->>'displayName'='하람','actor';
 assert items->0->>'photoPath'='mine.jpg' and items->0->>'photoBucket'='post-media','liked post photo';
 assert items->1->'place'->>'name'='을지로 숯불갈비' and (items->1->'place'->>'internalId')::bigint=q.a,'visited place';
 assert items->2->'place'='null'::jsonb and items->2->'postId'='null'::jsonb,'a follow has no place or post';
 assert r->'seenAt'='null'::jsonb,'nothing read yet';
 -- 모두 읽음.
 assert public.mark_notifications_read() is not null;
 assert (public.get_notifications()->>'seenAt')::timestamptz <= now(),'seen time stored';
 assert jsonb_array_length(public.get_notifications(1)->'items')=1,'limit';
end $$;
-- Someone else's read time is not mine to set.
set local request.jwt.claim.sub='96000000-0000-0000-0000-000000000002';
do $$ declare mine timestamptz; begin
 select notifications_seen_at into mine from public.profiles where id='96000000-0000-0000-0000-000000000001';
 -- The friend sees their own events: my visit (they follow me) and my follow.
 assert (select array_agg(e->>'kind') from jsonb_array_elements(public.get_notifications()->'items') e)
   =array['visit','follow'],'their own events only';
 perform public.mark_notifications_read();
 assert (select notifications_seen_at from public.profiles where id='96000000-0000-0000-0000-000000000001')=mine,
   'their 모두 읽음 leaves mine alone';
end $$;
reset role;
set local role anon;
do $$ begin
 begin perform public.get_notifications(); raise exception 'anon callable';
 exception when insufficient_privilege then null; end;
end $$;
rollback;
