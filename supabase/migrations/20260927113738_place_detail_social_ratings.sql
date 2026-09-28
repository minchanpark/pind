-- Pind-owned ratings only. Google provider content is not persisted here.
create table public.place_ratings (
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id bigint not null references public.places(id) on delete cascade,
  criterion text not null check (criterion in
    ('taste','ambience','value','portion','service','photogenic','quiet','parking')),
  rating numeric(2,1) not null check (rating between 1 and 5),
  is_public boolean not null default true,
  primary key (user_id, place_id, criterion)
);
create index place_ratings_place_idx on public.place_ratings(place_id, criterion);
alter table public.place_ratings enable row level security;
grant select, insert, update, delete on public.place_ratings to authenticated;
create policy ratings_read on public.place_ratings for select to authenticated
  using (is_public or user_id = (select auth.uid()));
create policy ratings_insert on public.place_ratings for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy ratings_update on public.place_ratings for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy ratings_delete on public.place_ratings for delete to authenticated
  using (user_id = (select auth.uid()));

create table public.saved_places (
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id bigint not null references public.places(id) on delete cascade,
  share_with_friends boolean not null default false,
  primary key (user_id, place_id)
);
create index saved_places_place_idx on public.saved_places(place_id);
alter table public.saved_places enable row level security;
grant select, insert, update, delete on public.saved_places to authenticated;
create policy saved_read on public.saved_places for select to authenticated
  using (user_id = (select auth.uid()) or (share_with_friends and exists (
    select 1 from public.friendships f where f.status = 'accepted' and
    ((f.requester_id = (select auth.uid()) and f.addressee_id = user_id) or
     (f.addressee_id = (select auth.uid()) and f.requester_id = user_id))
  )));
create policy saved_insert on public.saved_places for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy saved_update on public.saved_places for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy saved_delete on public.saved_places for delete to authenticated
  using (user_id = (select auth.uid()));

-- Invoker retains RLS; private posts/visits never become social proof.
create function public.get_place_detail_context(p_place_id bigint)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with friends as (
    select case when f.requester_id = (select auth.uid()) then f.addressee_id
      else f.requester_id end as id
    from public.friendships f where f.status = 'accepted'
      and (f.requester_id = (select auth.uid()) or f.addressee_id = (select auth.uid()))
  ), visitors as (
    select distinct p.id, p.display_name, p.avatar_url
    from friends f join public.profiles p on p.id = f.id
    where exists (select 1 from public.posts post where post.author_id = f.id
      and post.place_id = p_place_id and post.is_public)
  ), averages as (
    select criterion, avg(rating) as value from public.place_ratings
    where place_id = p_place_id and is_public group by criterion
  )
  select jsonb_build_object(
    'averages', coalesce((select jsonb_object_agg(criterion,value) from averages), '{}'::jsonb),
    'mine', coalesce((select jsonb_object_agg(criterion,rating) from public.place_ratings
      where place_id = p_place_id and user_id = (select auth.uid())), '{}'::jsonb),
    'visitors', coalesce((select jsonb_agg(jsonb_build_object(
      'id', id, 'name', display_name, 'avatar', avatar_url) order by display_name,id)
      from visitors), '[]'::jsonb),
    'saved', exists(select 1 from public.saved_places where place_id = p_place_id
      and user_id = (select auth.uid())),
    'friendSaveCount', (select count(*) from public.saved_places s join friends f on f.id=s.user_id
      where s.place_id = p_place_id and s.share_with_friends)
  ) where (select auth.uid()) is not null;
$$;
revoke all on function public.get_place_detail_context(bigint) from public, anon;
grant execute on function public.get_place_detail_context(bigint) to authenticated;
