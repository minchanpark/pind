-- One-way follows replace request/accept friendships; taste profiles power "취향이 비슷한 사람".
create table public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  followee_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);
create index follows_followee_idx on public.follows(followee_id);
alter table public.follows enable row level security;
grant select, insert, delete on public.follows to authenticated;
create policy follows_read on public.follows for select to authenticated using (true);
create policy follows_insert on public.follows for insert to authenticated
  with check (follower_id = (select auth.uid())
    and not coalesce(((select auth.jwt())->>'is_anonymous')::boolean, false));
create policy follows_delete on public.follows for delete to authenticated
  using (follower_id = (select auth.uid()));

-- An accepted friendship was mutual: keep it as a follow both ways.
-- Some environments never created friendships; skip the copy there.
do $$ begin
  if to_regclass('public.friendships') is not null then
    insert into public.follows(follower_id, followee_id)
    select requester_id, addressee_id from public.friendships where status = 'accepted'
    union
    select addressee_id, requester_id from public.friendships where status = 'accepted';
  end if;
end $$;

-- Shared saves are visible to the owner's followers.
drop policy if exists saved_read on public.saved_places;
create policy saved_read on public.saved_places for select to authenticated
  using (user_id = (select auth.uid()) or (share_with_friends and exists (
    select 1 from public.follows f
    where f.follower_id = (select auth.uid()) and f.followee_id = user_id
  )));

-- "friends" on place detail now means people I follow.
create or replace function public.get_place_detail_context(p_place_id bigint)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with friends as (
    select followee_id as id from public.follows where follower_id = (select auth.uid())
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

create or replace function public.get_my_profile_overview()
returns jsonb language sql stable security invoker set search_path='' as $$
  with recent as (
    select place_id,viewed_at from public.place_views
    where user_id=(select auth.uid()) and viewed_at >= now() - interval '24 hours'
    order by viewed_at desc limit 20
  ), saved as (
    select place_id,saved_at from public.saved_places
    where user_id=(select auth.uid()) order by saved_at desc limit 100
  ), my_visible as (
    select post.* from public.posts post join public.places p on p.id=post.place_id
    where post.author_id=(select auth.uid()) and post.is_public and post.status='published'
      and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
  ), mine as (
    select * from my_visible order by created_at desc,id desc limit 50
  ), cards as (
    select p.id,jsonb_build_object(
      'provider',p.external_provider,'internalId',p.id,'externalPlaceId',p.external_place_id,
      'name',p.name_ko,'category',p.category,'address',p.address_ko,
      'latitude',p.latitude,'longitude',p.longitude,
      'sourceUri','https://www.google.com/maps/search/?api=1&query=' || p.latitude || ',' || p.longitude,
      'heroImageUrl',p.hero_image_url,'pindPhotoPath',photo.photo_path,'pindPhotoBucket',photo.bucket) as j
    from public.places p
    left join lateral (
      select post.photo_path,
        case when post.client_request_id is null then 'post-media' else 'post-media-v2' end as bucket
      from public.posts post
      where post.place_id=p.id and post.is_public and post.status='published' order by post.created_at desc,post.id desc limit 1
    ) photo on true
    where p.id in (select place_id from recent union select place_id from saved union select place_id from mine)
      and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
  )
  select jsonb_build_object(
    'profile',(select jsonb_build_object('id',id,'handle',handle,'displayName',display_name,
      'avatarUrl',avatar_url,'bio',bio) from public.profiles where id=(select auth.uid())),
    'counts',jsonb_build_object(
      'followers',(select count(*) from public.follows where followee_id=(select auth.uid())),
      'following',(select count(*) from public.follows where follower_id=(select auth.uid())),
      'posts',(select count(*) from my_visible),
      'saved',(select count(*) from public.saved_places where user_id=(select auth.uid()))),
    'recentViews',coalesce((select jsonb_agg(c.j order by r.viewed_at desc)
      from recent r join cards c on c.id=r.place_id),'[]'::jsonb),
    'savedPlaces',coalesce((select jsonb_agg(c.j || jsonb_build_object('averages',coalesce((
        select jsonb_object_agg(criterion,value) from (select criterion,avg(rating) as value
          from public.place_ratings where place_id=s.place_id and is_public group by criterion) a),'{}'::jsonb))
      order by s.saved_at desc) from saved s join cards c on c.id=s.place_id),'[]'::jsonb),
    'posts',coalesce((select jsonb_agg(jsonb_build_object(
      'id',post.id,'place',c.j,'body',post.body,
      'ratings',coalesce(post.ratings,jsonb_strip_nulls(jsonb_build_object('taste',post.taste_score,
        'portion',post.portion_score,'ambience',post.ambience_score))),
      'bucket',case when post.client_request_id is null then 'post-media' else 'post-media-v2' end,
      'photos',coalesce((select jsonb_agg(media.path order by media.position) from public.post_media media
        where media.post_id=post.id),jsonb_build_array(post.photo_path)),
      'createdAt',post.created_at
    ) order by post.created_at desc,post.id desc) from mine post join cards c on c.id=post.place_id),'[]'::jsonb)
  ) where (select auth.uid()) is not null;
$$;

drop table if exists public.friendships;

-- Onboarding priorities, ordered 1st..3rd. discoverable mirrors the optional
-- "맞춤 추천을 위한 정보 활용" consent: only consenting users are recommended.
create table public.taste_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  priorities text[] not null check (
    array_ndims(priorities) = 1 and cardinality(priorities) = 3
    and priorities <@ array['taste','ambience','value','portion','service','photogenic','quiet','parking']
    and priorities[1] <> priorities[2] and priorities[1] <> priorities[3]
    and priorities[2] <> priorities[3]),
  discoverable boolean not null default false
);
alter table public.taste_profiles enable row level security;
grant select, insert, update on public.taste_profiles to authenticated;
create policy taste_profiles_own_read on public.taste_profiles for select to authenticated
  using (user_id = (select auth.uid()));
create policy taste_profiles_own_insert on public.taste_profiles for insert to authenticated
  with check (user_id = (select auth.uid())
    and not coalesce(((select auth.jwt())->>'is_anonymous')::boolean, false));
create policy taste_profiles_own_update on public.taste_profiles for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Weights over the user's three priorities, summing to 100.
-- Starts at 50/30/20 and drifts toward the user's rating evidence:
--   final = (5·base + n·learned) / (5 + n), n = places with evidence.
-- Evidence per priority criterion: the user's own public ratings, plus, for
-- each saved place, everyone else's public average. A priority with no
-- evidence scores the neutral 3.
create function private.taste_weights(p_user uuid)
returns table(criterion text, weight numeric)
language sql stable set search_path = '' as $$
  with prio as (
    select t.priorities[i] as criterion, (array[50, 30, 20])[i]::numeric as base
    from public.taste_profiles t, generate_series(1, 3) i
    where t.user_id = p_user
  ), evidence as (
    select r.place_id, r.criterion, r.rating::numeric as rating
    from public.place_ratings r join prio p on p.criterion = r.criterion
    where r.user_id = p_user and r.is_public
    union all
    select s.place_id, r.criterion, avg(r.rating)
    from public.saved_places s
    join public.place_ratings r on r.place_id = s.place_id and r.is_public and r.user_id <> p_user
    join prio p on p.criterion = r.criterion
    where s.user_id = p_user
    group by s.place_id, r.criterion
  ), learned as (
    select p.criterion, p.base, coalesce(avg(e.rating), 3) as score
    from prio p left join evidence e on e.criterion = p.criterion
    group by p.criterion, p.base
  ), n as (
    select count(distinct place_id) as n from evidence
  )
  select l.criterion, (5 * l.base + n.n * 100 * l.score / sum(l.score) over ()) / (5 + n.n)
  from learned l, n;
$$;

-- Overlap of two weight vectors, 0..100. Callers ensure both profiles exist.
create function private.taste_match(a uuid, b uuid)
returns integer language sql stable set search_path = '' as $$
  select coalesce(round(sum(least(x.weight, y.weight))), 0)::integer
  from private.taste_weights(a) x join private.taste_weights(b) y on y.criterion = x.criterion;
$$;
revoke all on function private.taste_weights(uuid), private.taste_match(uuid, uuid) from public;

-- ponytail: scores every discoverable user per call; precompute weights into
-- a table once this scan gets slow (thousands of users).
create function public.get_taste_matches(p_limit integer default 5, p_offset integer default 0)
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', m.id, 'handle', m.handle, 'displayName', m.display_name,
    'avatarUrl', m.avatar_url, 'match', m.match, 'following', false
  ) order by m.match desc, m.id), '[]'::jsonb)
  from (
    select p.id, p.handle, p.display_name, p.avatar_url,
      private.taste_match((select auth.uid()), p.id) as match
    from public.taste_profiles t join public.profiles p on p.id = t.user_id
    where t.discoverable and t.user_id <> (select auth.uid())
      and exists (select 1 from public.taste_profiles me where me.user_id = (select auth.uid()))
      and not exists (select 1 from public.follows f
        where f.follower_id = (select auth.uid()) and f.followee_id = t.user_id)
    order by match desc, p.id
    limit least(greatest(coalesce(p_limit, 5), 1), 50)
    offset greatest(coalesce(p_offset, 0), 0)
  ) m;
$$;

-- Handle or display name, a leading @ ignored. match is null unless both
-- sides have a taste profile and the other user is discoverable.
create function public.search_profiles(p_query text, p_limit integer default 20)
returns jsonb language sql stable security definer set search_path = '' as $$
  with q as (
    select '%' || replace(replace(replace(nullif(ltrim(trim(p_query), '@'), ''),
      chr(92), chr(92) || chr(92)), '%', chr(92) || '%'), '_', chr(92) || '_') || '%' as pattern
  ), me as (
    select (select auth.uid()) as id,
      exists (select 1 from public.taste_profiles where user_id = (select auth.uid())) as has_taste
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', r.id, 'handle', r.handle, 'displayName', r.display_name, 'avatarUrl', r.avatar_url,
    'match', case when r.discoverable and me.has_taste then private.taste_match(me.id, r.id) end,
    'following', exists (select 1 from public.follows f
      where f.follower_id = me.id and f.followee_id = r.id)
  ) order by r.handle nulls last, r.id), '[]'::jsonb)
  from me, (
    select p.id, p.handle, p.display_name, p.avatar_url, coalesce(t.discoverable, false) as discoverable
    from q, public.profiles p left join public.taste_profiles t on t.user_id = p.id
    where q.pattern is not null and p.id <> (select auth.uid())
      and (p.handle ilike q.pattern or p.display_name ilike q.pattern)
    order by p.handle nulls last, p.id
    limit least(greatest(coalesce(p_limit, 20), 1), 50)
  ) r
  where me.id is not null;
$$;
revoke all on function public.get_taste_matches(integer, integer), public.search_profiles(text, integer)
  from public, anon;
grant execute on function public.get_taste_matches(integer, integer), public.search_profiles(text, integer)
  to authenticated;

notify pgrst, 'reload schema';
