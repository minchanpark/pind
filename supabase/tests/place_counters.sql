\set ON_ERROR_STOP on
begin;
insert into auth.users(id) select ('95000000-0000-0000-0000-00000000000'||n)::uuid from generate_series(1,2) n;
select public.import_sbiz_places('[{"id":"cnt-qa-a","name":"카운트A","category":"한식","address":"서울 종로구","latitude":37.575,"longitude":126.985},
 {"id":"cnt-qa-b","name":"카운트B","category":"한식","address":"서울 종로구","latitude":37.576,"longitude":126.986}]','2026-10-01');
create temp table qa as select
 (select id from public.places where external_place_id='cnt-qa-a') a,
 (select id from public.places where external_place_id='cnt-qa-b') b;
create temp view c as select id, public_post_count posts, save_count saves from public.places where id in (select a from qa union select b from qa);

insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,status)
select '95000000-0000-0000-0000-000000000001',a,'',x,'🍚','',pub,st from qa,(values
 ('1.png',true,'published'),('2.png',true,'published'),('3.png',false,'published'),('4.png',true,'hidden')) v(x,pub,st);
insert into public.saved_places(user_id,place_id) select ('95000000-0000-0000-0000-00000000000'||n)::uuid,a from qa,generate_series(1,2) n;
do $$ declare q qa; begin select * into q from qa;
 assert (select (posts,saves) from c where id=q.a)=(2,2),'only public published posts count; every save counts';
 -- Hide one, move one, publish a draft; unsave and move a save.
 update public.posts set is_public=false where photo_path='1.png';
 update public.posts set place_id=q.b where photo_path='2.png';
 update public.posts set status='published' where photo_path='4.png';
 delete from public.saved_places where user_id='95000000-0000-0000-0000-000000000001';
 update public.saved_places set place_id=q.b where user_id='95000000-0000-0000-0000-000000000002';
 assert (select (posts,saves) from c where id=q.a)=(1,0),'a after edits';
 assert (select (posts,saves) from c where id=q.b)=(1,1),'b after moves';
 delete from public.posts where photo_path in ('2.png','4.png');
 assert (select sum(posts) from c)=0,'deletes drop to zero';
 -- Counters equal a fresh count.
 assert not exists(select 1 from public.places p where p.public_post_count <> (select count(*) from public.posts
   where place_id=p.id and is_public and status='published') or p.save_count <> (select count(*) from public.saved_places where place_id=p.id)),'matches recount';
end $$;
rollback;
