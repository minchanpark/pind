-- Authors can delete their own posts from the place detail.
-- delete_post removes the post (media rows and likes cascade; counters,
-- rating stats and the insight refresh follow through their triggers), drops
-- my rating of the place when no other post of mine is left there, and returns
-- the private photo paths so the app can delete the now-unattached files.
create function public.delete_post(p_post_id bigint)
returns jsonb language plpgsql volatile security invoker set search_path='' as $$
declare gone public.posts; paths jsonb;
begin
  select coalesce(jsonb_agg(m.path),'[]'::jsonb) into paths from public.post_media m
  where m.post_id=p_post_id and m.bucket='post-media-v2';
  -- RLS (posts_owner_delete) limits this to my own post.
  delete from public.posts where id=p_post_id and author_id=(select auth.uid()) returning * into gone;
  if gone.id is null then raise exception 'Post not found' using errcode='P0002'; end if;
  if not exists(select 1 from public.posts where author_id=gone.author_id and place_id=gone.place_id
    and status='published') then
    delete from public.place_ratings where user_id=gone.author_id and place_id=gone.place_id;
  end if;
  return jsonb_build_object('placeId',gone.place_id,'paths',paths);
end;
$$;
revoke all on function public.delete_post(bigint) from public,anon;
grant execute on function public.delete_post(bigint) to authenticated;

-- Same function as 20261001060000 with 'mine' on each pindPosts row.
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
        where media.post_id=post.id),jsonb_build_array(post.photo_path)),
      'likeCount',(select count(*) from public.post_likes l where l.post_id=post.id),
      'liked',exists(select 1 from public.post_likes l where l.post_id=post.id and l.user_id=(select auth.uid())),
      'mine',post.author_id=(select auth.uid())
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

notify pgrst, 'reload schema';
