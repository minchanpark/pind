-- The map shows only restaurants with posts, so it loads them all once instead of
-- querying the public catalog on every camera move. No arguments = all posted places.
create or replace function public.get_catalog_places(
  p_query text default null, p_lat double precision default null,
  p_lng double precision default null, p_radius integer default 5000,
  p_place_id bigint default null
) returns jsonb language plpgsql stable security invoker set search_path = '' as $$
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
      and ((p_query is not null or p_place_id is not null) or exists(select 1 from public.posts map_post
        where map_post.place_id=p.id and map_post.is_public and map_post.status='published'))
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
    'pindPostCount',(select count(*) from public.posts post where post.place_id=p.id and post.is_public and post.status='published'),
    'pindPhotos',case when p_place_id is not null then (select coalesce(jsonb_agg(jsonb_build_object(
      'path',m.path,'bucket',m.bucket,'author',m.author) order by m.created_at desc,m.post_id desc,m.position),'[]'::jsonb)
      from (select post.created_at,post.id as post_id,coalesce(media.position,0) as position,
        coalesce(media.path,post.photo_path) as path,profile.display_name as author,
        case when post.client_request_id is null then 'post-media' else 'post-media-v2' end as bucket
        from public.posts post
        join public.profiles profile on profile.id=post.author_id
        left join public.post_media media on media.post_id=post.id
        where post.place_id=p.id and post.is_public and post.status='published'
          and coalesce(media.path,post.photo_path) is not null
        order by post.created_at desc,post.id desc,media.position limit 5) m) end,
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


notify pgrst, 'reload schema';
