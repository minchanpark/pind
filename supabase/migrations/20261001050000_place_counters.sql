-- Counters instead of per-request counts, and indexes that start from the
-- few posted places instead of all ~150k catalog rows.
-- Before: the map's posted list ran an EXISTS over posts for every published
-- place (~2.6s); the category list counted posts/saves and averaged ratings per
-- row. Now both read places.public_post_count / save_count (O(1) per place) and
-- walk only posted places through partial indexes.

alter table public.places
  add column public_post_count integer not null default 0 check (public_post_count >= 0),
  add column save_count integer not null default 0 check (save_count >= 0);

update public.places p set public_post_count=c.n
from (select place_id, count(*) n from public.posts
  where is_public and status='published' group by place_id) c
where c.place_id=p.id;
update public.places p set save_count=c.n
from (select place_id, count(*) n from public.saved_places group by place_id) c
where c.place_id=p.id;

-- Row-level deltas; the places row lock serializes concurrent writers.
create function private.count_place_posts()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_op <> 'INSERT' and old.is_public and old.status='published' then
    update public.places set public_post_count=public_post_count-1 where id=old.place_id;
  end if;
  if tg_op <> 'DELETE' and new.is_public and new.status='published' then
    update public.places set public_post_count=public_post_count+1 where id=new.place_id;
  end if;
  return null;
end;
$$;
create trigger posts_count_place
  after insert or delete or update of is_public,status,place_id on public.posts
  for each row execute function private.count_place_posts();

create function private.count_place_saves()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_op <> 'INSERT' then
    update public.places set save_count=save_count-1 where id=old.place_id;
  end if;
  if tg_op <> 'DELETE' then
    update public.places set save_count=save_count+1 where id=new.place_id;
  end if;
  return null;
end;
$$;
create trigger saved_places_count_place
  after insert or delete or update of place_id on public.saved_places
  for each row execute function private.count_place_saves();

-- Only posted catalog places: the map list and the 10km ranking start here.
create index places_posted_idx on public.places(id)
  where public_post_count>0 and is_published and not is_demo and not is_reference_only;
create index places_posted_location_idx on public.places using gist(location)
  where public_post_count>0 and is_published and not is_demo and not is_reference_only;

-- The saved list sorts by saved_at.
create index saved_places_user_saved_idx on public.saved_places(user_id, saved_at desc);

create or replace function public.get_catalog_places(
  p_query text default null, p_lat double precision default null,
  p_lng double precision default null, p_radius integer default 5000,
  p_place_id bigint default null
) returns jsonb language plpgsql stable security invoker set search_path = ''
-- Custom plans fold the unused filters away so the posted-only index applies.
set plan_cache_mode = force_custom_plan as $$
declare result jsonb; pattern text;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if p_query is not null and length(trim(p_query)) not between 2 and 120 then
    raise exception 'Invalid query';
  end if;
  if (p_lat is null) <> (p_lng is null) or
     (p_lat is not null and not (p_lat between 33 and 38.8 and p_lng between 124.5 and 132)) or
     p_radius is null or p_radius not between 100 and 50000 then
    raise exception 'Invalid viewport';
  end if;
  pattern := '%' || replace(replace(replace(trim(p_query),chr(92),chr(92)||chr(92)),
    '%',chr(92)||'%'),'_',chr(92)||'_') || '%';
  with candidates as (
    select p.* from public.places p
    where p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
      and ((p_query is not null or p_place_id is not null) or p.public_post_count>0)
      and (p_place_id is null or p.id = p_place_id)
      and (p_query is null or (coalesce(p.name_ko,'') || ' ' || coalesce(p.address_ko,'')) ilike pattern)
      and (p_lat is null or extensions.st_dwithin(p.location,
        extensions.st_setsrid(extensions.st_makepoint(p_lng,p_lat),4326)::extensions.geography,p_radius))
    order by case when p_lat is not null then p.location operator(extensions.<->)
      extensions.st_setsrid(extensions.st_makepoint(p_lng,p_lat),4326)::extensions.geography end,
      p.name_ko,p.id
    -- ponytail: every posted place in one response; page by region once posts outgrow this.
    limit case when p_query is null and p_lat is null and p_place_id is null then 1000 else 30 end
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'provider',p.external_provider,'internalId',p.id,'externalPlaceId',p.external_place_id,
    'name',p.name_ko,'category',p.category,'address',p.address_ko,
    'latitude',p.latitude,'longitude',p.longitude,
    'sourceUri','https://www.google.com/maps/search/?api=1&query=' || p.latitude || ',' || p.longitude,
    'dataSourceUri',p.source_url,'sourceDate',p.source_date,
    'heroImageUrl',p.hero_image_url,'editorialSummary',p.short_description_ko,
    'pindPhotoPath',photo.photo_path,'pindPhotoAuthor',photo.display_name,'pindPhotoBucket',photo.bucket,
    'pindPostCount',p.public_post_count,
    'pindPosts',case when p_place_id is not null then (select coalesce(jsonb_agg(jsonb_build_object(
      'id',post.id,'author',profile.display_name,'handle',profile.handle,'avatar',profile.avatar_url,'body',post.body,
      'ratings',coalesce(post.ratings,jsonb_strip_nulls(jsonb_build_object('taste',post.taste_score,
        'portion',post.portion_score,'ambience',post.ambience_score))),
      'bucket',case when post.client_request_id is null then 'post-media' else 'post-media-v2' end,
      'photos',coalesce((select jsonb_agg(media.path order by media.position) from public.post_media media
        where media.post_id=post.id),jsonb_build_array(post.photo_path))
    ) order by post.created_at desc,post.id desc),'[]'::jsonb)
      -- ponytail: newest 10 posts only; paginate when the posts tab needs more.
      from (select * from public.posts where place_id=p.id and is_public and status='published'
        order by created_at desc,id desc limit 10) post
      join public.profiles profile on profile.id=post.author_id) end,
    'insight',case when p_place_id is not null then (select jsonb_build_object(
      'summary',i.summary,'criteria',i.criteria,'postCount',i.post_count)
      from public.place_insights i where i.place_id=p.id) end
  )), '[]'::jsonb) into result from candidates p
  left join lateral (
    select post.photo_path,profile.display_name,
      case when post.client_request_id is null then 'post-media' else 'post-media-v2' end as bucket
    from public.posts post
    join public.profiles profile on profile.id=post.author_id
    where post.place_id=p.id and post.is_public and post.status='published' order by post.created_at desc,post.id desc limit 1
  ) photo on true;
  return jsonb_build_object('places',result,'catalogReady',exists(
    select 1 from public.places where is_published and not is_demo and not is_reference_only
      and external_provider in ('sbiz','pind')
  ));
end;
$$;
revoke all on function public.get_catalog_places(text,double precision,double precision,integer,bigint) from public,anon;
grant execute on function public.get_catalog_places(text,double precision,double precision,integer,bigint) to authenticated;

-- Invoker keeps RLS: only shared saves of people I follow are visible.
create or replace function public.get_nearby_ranking(
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
      and p.public_post_count>0
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
    'averages',coalesce((select jsonb_object_agg(s.criterion,s.average) from public.place_rating_stats s
      where s.place_id=n.id and s.rating_count>0),'{}'::jsonb),
    'reviewCount',n.public_post_count,
    'saveCount',n.save_count,
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

drop function public.place_save_count(bigint);

notify pgrst, 'reload schema';
