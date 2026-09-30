-- Other users' profile pages: the My Page overview for any user, plus follow
-- state both ways and (for consenting users) their taste priorities.

-- Priorities of a user who consented to recommendations, or my own. Definer so
-- taste_profiles keeps its owner-only RLS; this reveals nothing more.
create function public.get_profile_taste(p_user uuid)
returns text[] language sql stable security definer set search_path='' as $$
  select priorities from public.taste_profiles
  where user_id=p_user and (discoverable or user_id=(select auth.uid()));
$$;
revoke all on function public.get_profile_taste(uuid) from public,anon;
grant execute on function public.get_profile_taste(uuid) to authenticated;

-- Invoker keeps RLS: another user's saves appear only when shared and I follow
-- them; recently viewed is always mine only. p_user null = me.
create function public.get_profile_overview(p_user uuid)
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
    ) order by post.created_at desc,post.id desc) from shown post join cards c on c.id=post.place_id),'[]'::jsonb)
  ) from target
  where (select auth.uid()) is not null
    and exists(select 1 from public.profiles where id=target.id);
$$;
revoke all on function public.get_profile_overview(uuid) from public,anon;
grant execute on function public.get_profile_overview(uuid) to authenticated;

-- Older app builds still call this.
create or replace function public.get_my_profile_overview()
returns jsonb language sql stable security invoker set search_path='' as $$
  select public.get_profile_overview(null);
$$;

notify pgrst, 'reload schema';
