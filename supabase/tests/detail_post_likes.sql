\set ON_ERROR_STOP on
begin;
insert into auth.users(id) select ('96000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,3) n;
select public.import_sbiz_places('[{"id":"like-qa-a","name":"좋아요A","category":"한식","address":"서울 종로구","latitude":37.575,"longitude":126.985}]','2026-10-01');
create temp table qa as select (select id from public.places where external_place_id='like-qa-a') a;
grant select on qa to authenticated;
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '96000000-0000-0000-0000-000000000001',a,'',x,'🍚',x,true,'published' from qa,(values ('liked.png'),('plain.png')) v(x);
insert into public.post_likes(user_id,post_id)
select ('96000000-0000-0000-0000-00000000000'||n)::uuid,(select id from public.posts where body='liked.png') from generate_series(1,2) n;

set local role authenticated;
set local request.jwt.claims='{"is_anonymous":false}';
set local request.jwt.claim.sub='96000000-0000-0000-0000-000000000002';
do $$ declare q qa; posts jsonb; begin select * into q from qa;
 posts:=public.get_catalog_places(p_place_id:=q.a)->'places'->0->'pindPosts';
 assert (select (e->>'likeCount')::int from jsonb_array_elements(posts) e where e->>'body'='liked.png')=2,'count';
 assert (select (e->>'liked')::boolean from jsonb_array_elements(posts) e where e->>'body'='liked.png'),'I liked it';
 assert (select (e->>'likeCount')||'/'||(e->>'liked') from jsonb_array_elements(posts) e where e->>'body'='plain.png')='0/false','unliked post';
end $$;
set local request.jwt.claim.sub='96000000-0000-0000-0000-000000000003';
do $$ declare q qa; begin select * into q from qa;
 assert not (select (e->>'liked')::boolean from jsonb_array_elements(public.get_catalog_places(p_place_id:=q.a)->'places'->0->'pindPosts') e
   where e->>'body'='liked.png'),'someone else did not like it';
end $$;
rollback;
