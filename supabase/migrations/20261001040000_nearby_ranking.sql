-- Map category list: posted places within p_radius of a point, nearest first,
-- with what the client needs to rank them (rating averages) and the social
-- line (people I follow who posted or shared a save there).

-- Total saves are shown as a number only; the rows stay owner/follower-only.
create function public.place_save_count(p_place_id bigint)
returns bigint language sql stable security definer set search_path='' as $$
  select count(*) from public.saved_places where place_id=p_place_id;
$$;
revoke all on function public.place_save_count(bigint) from public,anon;
grant execute on function public.place_save_count(bigint) to authenticated;

-- Invoker keeps RLS: only shared saves of people I follow are visible.
create function public.get_nearby_ranking(
  p_lat double precision, p_lng double precision, p_radius integer default 10000
) returns jsonb language sql stable security invoker set search_path='' as $$
  with here as (
    select extensions.st_setsrid(extensions.st_makepoint(p_lng,p_lat),4326)::extensions.geography as g
  ), near as (
    select p.*, extensions.st_distance(p.location,here.g) as meters
    from public.places p, here
    where (select auth.uid()) is not null
      and p_lat between -90 and 90 and p_lng between -180 and 180
      and p_radius between 100 and 50000
      and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
      and extensions.st_dwithin(p.location,here.g,p_radius)
      and exists(select 1 from public.posts post where post.place_id=p.id
        and post.is_public and post.status='published')
    order by meters limit 200
  ), friends as (
    select followee_id as id from public.follows where follower_id=(select auth.uid())
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'provider',n.external_provider,'internalId',n.id,'externalPlaceId',n.external_place_id,
    'name',n.name_ko,'category',n.category,'address',n.address_ko,
    'latitude',n.latitude,'longitude',n.longitude,
    'sourceUri','https://www.google.com/maps/search/?api=1&query=' || n.latitude || ',' || n.longitude,
    'heroImageUrl',n.hero_image_url,'pindPhotoPath',photo.photo_path,'pindPhotoBucket',photo.bucket,
    'meters',round(n.meters),
    'averages',coalesce((select jsonb_object_agg(criterion,value) from (select criterion,avg(rating) as value
      from public.place_ratings where place_id=n.id and is_public group by criterion) a),'{}'::jsonb),
    'reviewCount',(select count(*) from public.posts post where post.place_id=n.id
      and post.is_public and post.status='published'),
    'saveCount',public.place_save_count(n.id),
    'saved',exists(select 1 from public.saved_places s where s.place_id=n.id
      and s.user_id=(select auth.uid())),
    'visitedBy',visit.j,'savedBy',save.j
  ) order by n.meters),'[]'::jsonb)
  from near n
  left join lateral (
    select post.photo_path,
      case when post.client_request_id is null then 'post-media' else 'post-media-v2' end as bucket
    from public.posts post
    where post.place_id=n.id and post.is_public and post.status='published'
    order by post.created_at desc,post.id desc limit 1
  ) photo on true
  left join lateral (
    select jsonb_build_object('count',count(*),'people',coalesce(jsonb_agg(jsonb_build_object(
      'name',x.name,'avatar',x.avatar_url) order by x.name) filter (where x.rn<=2),'[]'::jsonb)) as j
    from (select coalesce(nullif(pr.display_name,''),pr.handle) as name,pr.avatar_url,
        row_number() over (order by coalesce(nullif(pr.display_name,''),pr.handle)) as rn
      from public.profiles pr join friends f on f.id=pr.id
      where exists(select 1 from public.posts post where post.author_id=pr.id
        and post.place_id=n.id and post.is_public and post.status='published')) x
  ) visit on true
  left join lateral (
    select jsonb_build_object('count',count(*),'people',coalesce(jsonb_agg(jsonb_build_object(
      'name',x.name,'avatar',x.avatar_url) order by x.name) filter (where x.rn<=2),'[]'::jsonb)) as j
    from (select coalesce(nullif(pr.display_name,''),pr.handle) as name,pr.avatar_url,
        row_number() over (order by coalesce(nullif(pr.display_name,''),pr.handle)) as rn
      from public.saved_places s join friends f on f.id=s.user_id join public.profiles pr on pr.id=s.user_id
      where s.place_id=n.id and s.share_with_friends) x
  ) save on true;
$$;
revoke all on function public.get_nearby_ranking(double precision,double precision,integer) from public,anon;
grant execute on function public.get_nearby_ranking(double precision,double precision,integer) to authenticated;
