-- 공개/비공개 posts. Private (is_public=false) now means friends only: the
-- author and the people who follow them (the same audience as shared saves).
-- RLS decides who sees a post; the post lists below drop their explicit
-- is_public filter and let it. Shared aggregates (map pins, counts, rating
-- averages, insights, ranking, agent search) stay public-only.
create policy posts_follower_read on public.posts for select to authenticated
using (status='published' and exists(select 1 from public.follows f
  where f.follower_id=(select auth.uid()) and f.followee_id=author_id));
create index posts_published_feed_idx on public.posts(created_at desc,id desc)
  where status='published';

-- Likes and photos follow the post's visibility.
alter policy post_likes_read on public.post_likes using (user_id=(select auth.uid()) or
  exists(select 1 from public.posts p where p.id=post_id and p.status='published'));
alter policy post_likes_insert on public.post_likes with check (user_id=(select auth.uid())
  and not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false)
  and exists(select 1 from public.posts p where p.id=post_id and p.status='published'));
alter policy post_media_v2_read on storage.objects using (bucket_id='post-media-v2' and (
  (storage.foldername(name))[1]=(select auth.uid())::text or exists(
    select 1 from public.post_media m join public.posts p on p.id=m.post_id
    where m.bucket=bucket_id and m.path=name and p.status='published'
  )
));

-- Older builds call without p_is_public and keep publishing publicly.
drop function public.publish_post_v3(uuid,bigint,jsonb,text,jsonb);
create function public.publish_post_v3(
  p_client_request_id uuid, p_place_id bigint, p_ratings jsonb,
  p_body text, p_media jsonb, p_is_public boolean default true
) returns jsonb language plpgsql security invoker set search_path='' as $$
declare
  caller uuid := (select auth.uid());
  existing public.posts;
  created public.posts;
  item jsonb; object_metadata jsonb; position integer := 0; total integer;
begin
  if caller is null or coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false) then
    raise exception 'Login required' using errcode='42501';
  end if;
  if p_client_request_id is null then raise exception 'Request ID required'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(
    'pind:post:' || caller::text || ':' || p_client_request_id::text,0));
  select * into existing from public.posts
    where author_id=caller and client_request_id=p_client_request_id;
  if existing.id is not null then
    return jsonb_build_object('id',existing.id,'placeId',existing.place_id);
  end if;
  if not exists(select 1 from public.places where id=p_place_id and is_published
    and not is_demo and not is_reference_only and external_provider in ('sbiz','pind')) then
    raise exception 'Choose a catalog restaurant';
  end if;
  if jsonb_typeof(p_ratings) is distinct from 'object' or
    (select count(*) from jsonb_object_keys(p_ratings)) <> 3 or exists(
      select 1 from jsonb_each(p_ratings) r
      where r.key not in ('taste','ambience','value','portion','service','photogenic','quiet','parking')
        or jsonb_typeof(r.value) <> 'number' or r.value::numeric not in (1,2,3,4,5)) then
    raise exception 'Three ratings from 1 to 5 required';
  end if;
  if char_length(coalesce(p_body,'')) > 200 then raise exception 'Body exceeds 200 characters'; end if;
  if jsonb_typeof(p_media) is distinct from 'array' then raise exception 'Photo array required'; end if;
  total:=jsonb_array_length(p_media);
  if total not between 1 and 10 then raise exception 'Choose 1 to 10 photos'; end if;
  if (select count(distinct photo->>'path') from jsonb_array_elements(p_media) photo) <> total then
    raise exception 'Duplicate photos';
  end if;
  for item in select value from jsonb_array_elements(p_media) loop
    if coalesce(char_length(item->>'path'),0) not between 1 and 512 or
      split_part(item->>'path','/',1)<>caller::text or
      split_part(item->>'path','/',2)<>p_client_request_id::text or
      item->>'path' like '%..%' or
      coalesce(item->>'mime','') not in ('image/jpeg','image/png','image/webp','image/heic','image/heif') or
      coalesce((item->>'bytes')::bigint,0) not between 1 and 10485760 then
      raise exception 'Invalid photo metadata';
    end if;
    select metadata into object_metadata from storage.objects
      where bucket_id='post-media-v2' and name=item->>'path';
    if not found or (object_metadata->>'mimetype') is distinct from (item->>'mime') or
      (object_metadata->>'size')::bigint is distinct from (item->>'bytes')::bigint then
      raise exception 'Photo must be uploaded by the current user';
    end if;
  end loop;
  insert into public.posts(author_id,place_id,menu_name,photo_path,emoji,body,is_public,
    ratings,client_request_id,status)
  values(caller,p_place_id,'',p_media->0->>'path','🍽️',trim(coalesce(p_body,'')),coalesce(p_is_public,true),
    p_ratings,p_client_request_id,'published')
  returning * into created;
  for item in select value from jsonb_array_elements(p_media) loop
    insert into public.post_media(post_id,position,path,mime,bytes)
      values(created.id,position,item->>'path',item->>'mime',(item->>'bytes')::integer);
    position:=position+1;
  end loop;
  insert into public.place_ratings(user_id,place_id,criterion,rating,is_public)
    select caller,p_place_id,r.key,r.value::numeric,true from jsonb_each(p_ratings) r
  on conflict(user_id,place_id,criterion) do update set rating=excluded.rating,is_public=excluded.is_public;
  return jsonb_build_object('id',created.id,'placeId',created.place_id);
end;
$$;
revoke all on function public.publish_post_v3(uuid,bigint,jsonb,text,jsonb,boolean) from public,anon;
grant execute on function public.publish_post_v3(uuid,bigint,jsonb,text,jsonb,boolean) to authenticated;

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
    where post.status='published'
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
    where post.author_id=target.id and post.status='published'
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
      from (select * from public.posts where place_id=p.id and status='published'
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

create or replace function public.get_notifications(p_limit integer default 50)
returns jsonb language sql stable security invoker set search_path='' as $$
  with me as (select (select auth.uid()) as id),
  events as (
    -- Someone liked one of my posts.
    select 'like' as kind, l.created_at as at, l.user_id as actor, p.id as post_id, p.place_id
    from public.post_likes l join public.posts p on p.id=l.post_id, me
    where p.author_id=me.id and l.user_id<>me.id and p.status='published'
      and l.created_at > now()-interval '30 days'
    union all
    -- Someone I follow posted a visit.
    select 'visit', p.created_at, p.author_id, p.id, p.place_id
    from public.posts p join public.follows f on f.followee_id=p.author_id, me
    where f.follower_id=me.id and p.author_id<>me.id and p.status='published'
      and p.created_at > now()-interval '30 days'
    union all
    -- Someone followed me.
    select 'follow', f.created_at, f.follower_id, null, null
    from public.follows f, me
    where f.followee_id=me.id and f.created_at > now()-interval '30 days'
  ), recent as (
    select * from events order by at desc limit least(greatest(coalesce(p_limit,50),1),100)
  )
  select jsonb_build_object(
    'seenAt',(select notifications_seen_at from public.profiles where id=(select id from me)),
    'items',coalesce(jsonb_agg(jsonb_build_object(
      'kind',r.kind,'at',r.at,'postId',r.post_id,
      'actor',jsonb_build_object('id',a.id,'handle',a.handle,'displayName',a.display_name,
        'avatarUrl',a.avatar_url),
      'place',case when pl.id is null then null else jsonb_build_object(
        'provider',pl.external_provider,'internalId',pl.id,'externalPlaceId',pl.external_place_id,
        'name',pl.name_ko,'category',pl.category,'address',pl.address_ko,
        'latitude',pl.latitude,'longitude',pl.longitude,
        'sourceUri','https://www.google.com/maps/search/?api=1&query=' || pl.latitude || ',' || pl.longitude,
        'pindPostCount',pl.public_post_count) end,
      'photoPath',post.photo_path,
      'photoBucket',case when post.id is null then null
        when post.client_request_id is null then 'post-media' else 'post-media-v2' end
    ) order by r.at desc),'[]'::jsonb))
  from recent r
  join public.profiles a on a.id=r.actor
  left join public.posts post on post.id=r.post_id
  left join public.places pl on pl.id=r.place_id
$$;
revoke all on function public.get_notifications(integer) from public,anon;
grant execute on function public.get_notifications(integer) to authenticated;

notify pgrst, 'reload schema';
