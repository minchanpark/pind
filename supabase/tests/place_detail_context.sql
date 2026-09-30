\set ON_ERROR_STOP on
begin;
insert into auth.users(id) values
 ('10000000-0000-0000-0000-000000000001'),
 ('10000000-0000-0000-0000-000000000002'),
 ('10000000-0000-0000-0000-000000000003');
update public.profiles set display_name='pind_test_friend',is_demo=true
 where id='10000000-0000-0000-0000-000000000002';
-- 1 follows 2; 3 follows 1 (the reverse direction must not count).
insert into public.follows(follower_id,followee_id) values
 ('10000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002'),
 ('10000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001');
insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public)
 select id,1,'QA','qa/photo.png','☕','QA visit',true from auth.users;
insert into public.place_ratings(user_id,place_id,criterion,rating,is_public) values
 ('10000000-0000-0000-0000-000000000001',1,'taste',5,true),
 ('10000000-0000-0000-0000-000000000002',1,'taste',3,true),
 ('10000000-0000-0000-0000-000000000003',1,'taste',1,false);
insert into public.saved_places(user_id,place_id,share_with_friends) values
 ('10000000-0000-0000-0000-000000000002',1,true),
 ('10000000-0000-0000-0000-000000000003',1,true);
set local role authenticated;
set local request.jwt.claim.sub = '10000000-0000-0000-0000-000000000001';
do $$ declare data jsonb; begin
 data := public.get_place_detail_context(1);
 assert jsonb_array_length(data->'visitors')=1, 'only people I follow';
 assert data->'visitors'->0->>'name'='pind_test_friend';
 assert (data->>'friendSaveCount')::int=1, 'follower saves excluded';
 assert (data->'averages'->>'taste')::numeric=4, 'private ratings excluded';
 assert (data->'mine'->>'taste')::numeric=5, 'own rating';
 assert (select count(*) from public.saved_places)=1, 'save RLS';
 begin
  insert into public.saved_places values('10000000-0000-0000-0000-000000000003',2,false);
  raise exception 'forged owner accepted';
 exception when insufficient_privilege then null; end;
 insert into public.saved_places(user_id,place_id) values(auth.uid(),1) on conflict do nothing;
 assert (public.get_place_detail_context(1)->>'saved')::boolean;
 begin
  update public.saved_places set user_id='10000000-0000-0000-0000-000000000003' where user_id=auth.uid();
  raise exception 'owner reassignment accepted';
 exception when insufficient_privilege then null; end;
 delete from public.saved_places where user_id=auth.uid();
 assert not (public.get_place_detail_context(1)->>'saved')::boolean;
end $$;
reset role;
update public.posts set is_public=false where author_id='10000000-0000-0000-0000-000000000002';
set local role authenticated;
do $$ begin
 assert jsonb_array_length(public.get_place_detail_context(1)->'visitors')=0, 'private visit hidden';
end $$;
reset role;
update public.posts set is_public=true;
delete from public.follows;
set local role authenticated;
do $$ begin
 assert jsonb_array_length(public.get_place_detail_context(1)->'visitors')=0, 'unfollowed hidden';
 assert (public.get_place_detail_context(1)->>'friendSaveCount')::int=0;
end $$;
reset role;
do $$ begin
 assert not has_function_privilege('anon','public.get_place_detail_context(bigint)','execute');
end $$;
rollback;
\echo 'PASS: followed/follower/unfollowed/private visits, ratings, owner isolation, save idempotency, RPC grants'
