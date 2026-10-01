-- Everyone's public rating has equal weight, including the viewer's own rating.
create table public.place_rating_stats (
  place_id bigint not null references public.places(id) on delete cascade,
  criterion text not null check (criterion in
    ('taste','ambience','value','portion','service','photogenic','quiet','parking')),
  rating_sum numeric not null,
  rating_count bigint not null,
  average numeric generated always as
    (rating_sum / nullif(rating_count, 0)) stored,
  updated_at timestamptz not null default now(),
  primary key (place_id, criterion),
  check (rating_count >= 0),
  check (rating_sum >= rating_count and rating_sum <= 5 * rating_count)
);
alter table public.place_rating_stats enable row level security;
revoke all on public.place_rating_stats from public, anon, authenticated, service_role;
grant select on public.place_rating_stats to authenticated, service_role;
create policy rating_stats_read on public.place_rating_stats
  for select to authenticated using ((select auth.uid()) is not null);

-- Atomic deltas serialize on the aggregate row, avoiding stale-snapshot averages.
-- Empty aggregates retain count 0 and average NULL.
create function private.sync_place_rating_stats()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op = 'TRUNCATE' then
    delete from public.place_rating_stats;
    return null;
  end if;

  if tg_op = 'UPDATE' then
    if old.place_id = new.place_id and old.criterion = new.criterion
       and old.is_public and new.is_public then
      if old.rating is distinct from new.rating then
        update public.place_rating_stats
        set rating_sum = rating_sum + new.rating - old.rating, updated_at = now()
        where place_id = new.place_id and criterion = new.criterion;
      end if;
      return new;
    end if;
  end if;

  if tg_op <> 'INSERT' then
    if old.is_public then
      update public.place_rating_stats
      set rating_sum = rating_sum - old.rating,
          rating_count = rating_count - 1, updated_at = now()
      where place_id = old.place_id and criterion = old.criterion;
    end if;
  end if;

  if tg_op <> 'DELETE' then
    if new.is_public then
      insert into public.place_rating_stats as stats
        (place_id, criterion, rating_sum, rating_count)
      values (new.place_id, new.criterion, new.rating, 1)
      on conflict (place_id, criterion) do update
      set rating_sum = stats.rating_sum + excluded.rating_sum,
          rating_count = stats.rating_count + 1, updated_at = now();
    end if;
    return new;
  end if;
  return old;
end;
$$;
revoke all on function private.sync_place_rating_stats() from public, anon, authenticated;
create trigger place_rating_stats_sync
  after insert or update or delete on public.place_ratings
  for each row execute function private.sync_place_rating_stats();
create trigger place_rating_stats_truncate
  after truncate on public.place_ratings
  for each statement execute function private.sync_place_rating_stats();

-- Admin-only backfill/recovery. No client can write the stored averages.
create function private.rebuild_place_rating_stats()
returns void language plpgsql security definer set search_path = '' as $$
begin
  lock table public.place_ratings in share row exclusive mode;
  lock table public.place_rating_stats in share row exclusive mode;
  delete from public.place_rating_stats;
  insert into public.place_rating_stats (place_id, criterion, rating_sum, rating_count)
    select place_id, criterion, sum(rating), count(*)
    from public.place_ratings where is_public group by place_id, criterion;
end;
$$;
revoke all on function private.rebuild_place_rating_stats() from public, anon, authenticated;
select private.rebuild_place_rating_stats();


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
    select criterion, average as value, rating_count from public.place_rating_stats
    where place_id = p_place_id and rating_count > 0
  )
  select jsonb_build_object(
    'averages', coalesce((select jsonb_object_agg(criterion,value) from averages), '{}'::jsonb),
    'ratingCounts', coalesce((select jsonb_object_agg(criterion,rating_count) from averages), '{}'::jsonb),
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

create or replace function public.get_profile_overview(p_user uuid)
returns jsonb language sql stable security invoker set search_path='' as $$
  with target as (
    select coalesce(p_user,(select auth.uid())) as id
  ), recent as (
    select place_id,viewed_at from public.place_views, target
    where user_id=(select auth.uid()) and user_id=target.id
      and viewed_at >= now() - interval '24 hours'
    order by viewed_at desc limit 20
  ), saved as (
    select place_id,saved_at from public.saved_places, target
    where user_id=target.id order by saved_at desc limit 100
  ), visible as (
    select post.* from target, public.posts post join public.places p on p.id=post.place_id
    where post.author_id=target.id and post.is_public and post.status='published'
      and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
  ), shown as (
    select * from visible order by created_at desc,id desc limit 50
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
    where p.id in (select place_id from recent union select place_id from saved union select place_id from shown)
      and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
  )
  select jsonb_build_object(
    'profile',(select jsonb_build_object('id',id,'handle',handle,'displayName',display_name,
      'avatarUrl',avatar_url,'bio',bio) from public.profiles where id=target.id),
    'counts',jsonb_build_object(
      'followers',(select count(*) from public.follows where followee_id=target.id),
      'following',(select count(*) from public.follows where follower_id=target.id),
      'posts',(select count(*) from visible),
      'saved',(select count(*) from public.saved_places where user_id=target.id)),
    'following',exists(select 1 from public.follows
      where follower_id=(select auth.uid()) and followee_id=target.id),
    'followsMe',exists(select 1 from public.follows
      where follower_id=target.id and followee_id=(select auth.uid())),
    'taste',to_jsonb(public.get_profile_taste(target.id)),
    'recentViews',coalesce((select jsonb_agg(c.j order by r.viewed_at desc)
      from recent r join cards c on c.id=r.place_id),'[]'::jsonb),
    'savedPlaces',coalesce((select jsonb_agg(c.j || jsonb_build_object('averages',coalesce((
        select jsonb_object_agg(criterion,average)
      from public.place_rating_stats where place_id=s.place_id and rating_count > 0),'{}'::jsonb), 'ratingCounts',coalesce((
      select jsonb_object_agg(criterion,rating_count)
      from public.place_rating_stats where place_id=s.place_id and rating_count > 0
    ),'{}'::jsonb),
        'savedAt',s.saved_at,
        'reviewCount',(select count(*) from public.posts post
          where post.place_id=s.place_id and post.is_public and post.status='published'),
        'savers',coalesce((select jsonb_agg(v.avatar_url order by v.saved_at desc) from (
          select pr.avatar_url,o.saved_at from public.saved_places o join public.profiles pr on pr.id=o.user_id
          where o.place_id=s.place_id and o.user_id<>target.id order by o.saved_at desc limit 3) v),'[]'::jsonb))
      order by s.saved_at desc) from saved s join cards c on c.id=s.place_id),'[]'::jsonb),
    'posts',coalesce((select jsonb_agg(jsonb_build_object(
      'id',post.id,'place',c.j,'body',post.body,
      'ratings',coalesce(post.ratings,jsonb_strip_nulls(jsonb_build_object('taste',post.taste_score,
        'portion',post.portion_score,'ambience',post.ambience_score))),
      'bucket',case when post.client_request_id is null then 'post-media' else 'post-media-v2' end,
      'photos',coalesce((select jsonb_agg(media.path order by media.position) from public.post_media media
        where media.post_id=post.id),jsonb_build_array(post.photo_path)),
      'createdAt',post.created_at
    ) order by post.created_at desc,post.id desc) from shown post join cards c on c.id=post.place_id),'[]'::jsonb)
  ) from target
  where (select auth.uid()) is not null
    and exists(select 1 from public.profiles where id=target.id);
$$;

notify pgrst, 'reload schema';
