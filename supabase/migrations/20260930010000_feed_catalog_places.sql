-- Feed and My Page only show posts on places the app can render: the same
-- catalog filter as get_catalog_places. Google reference-only rows (ID only,
-- no name/coordinates) and demo places made the client parser throw and
-- blanked the whole feed.
create or replace function public.get_discover_feed(
  p_query text default null, p_before_created timestamptz default null,
  p_before_id bigint default null, p_limit integer default 20
) returns jsonb language sql stable security invoker set search_path='' as $$
  with q as (
    select '%' || replace(replace(replace(nullif(trim(p_query),''),chr(92),chr(92)||chr(92)),
      '%',chr(92)||'%'),'_',chr(92)||'_') || '%' as pattern
  ), feed as (
    select post.* from q,public.posts post
    join public.places p on p.id=post.place_id
    where post.is_public and post.status='published'
      -- Same places the map shows; reference-only/demo rows have no name or pin.
      and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
      and (p_before_created is null or (post.created_at,post.id) < (p_before_created,p_before_id))
      and (q.pattern is null or p.name_ko ilike q.pattern or p.category ilike q.pattern
        or post.body ilike q.pattern)
    order by post.created_at desc,post.id desc
    limit least(greatest(coalesce(p_limit,20),1),50)
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',post.id,
    'author',jsonb_build_object('id',post.author_id,'handle',author.handle,
      'displayName',author.display_name,'avatarUrl',author.avatar_url),
    'place',jsonb_build_object(
      'provider',p.external_provider,'internalId',p.id,'externalPlaceId',p.external_place_id,
      'name',p.name_ko,'category',p.category,'address',p.address_ko,
      'latitude',p.latitude,'longitude',p.longitude,
      'sourceUri','https://www.google.com/maps/search/?api=1&query=' || p.latitude || ',' || p.longitude,
      'heroImageUrl',p.hero_image_url,'pindPhotoPath',photo.photo_path,'pindPhotoBucket',photo.bucket),
    'body',post.body,
    'ratings',coalesce(post.ratings,jsonb_strip_nulls(jsonb_build_object('taste',post.taste_score,
      'portion',post.portion_score,'ambience',post.ambience_score))),
    'bucket',case when post.client_request_id is null then 'post-media' else 'post-media-v2' end,
    'photos',coalesce((select jsonb_agg(media.path order by media.position) from public.post_media media
      where media.post_id=post.id),jsonb_build_array(post.photo_path)),
    'createdAt',post.created_at,
    'likeCount',(select count(*) from public.post_likes l where l.post_id=post.id),
    'liked',exists(select 1 from public.post_likes l where l.post_id=post.id and l.user_id=(select auth.uid()))
  ) order by post.created_at desc,post.id desc),'[]'::jsonb)
  from feed post
  join public.places p on p.id=post.place_id
  left join public.profiles author on author.id=post.author_id
  left join lateral (
    select latest.photo_path,
      case when latest.client_request_id is null then 'post-media' else 'post-media-v2' end as bucket
    from public.posts latest
    where latest.place_id=p.id and latest.is_public and latest.status='published'
    order by latest.created_at desc,latest.id desc limit 1
  ) photo on true
  having (select auth.uid()) is not null;
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
      'friends',(select count(*) from public.friendships where status='accepted'
        and (requester_id=(select auth.uid()) or addressee_id=(select auth.uid()))),
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

notify pgrst, 'reload schema';
