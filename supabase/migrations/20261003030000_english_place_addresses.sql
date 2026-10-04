-- Official English road addresses, filled ahead of time from juso
-- (scripts/backfill_sbiz_address_en.mjs --batch). Every place card carries
-- addressEn next to the Korean; null means juso had no exact match.
-- Non-Korean app languages show it with the Korean underneath.

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
      'name',p.name_ko,'category',p.category,'address',p.address_ko,'addressEn',nullif(p.address_en,p.address_ko),
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
      'name',p.name_ko,'category',p.category,'address',p.address_ko,'addressEn',nullif(p.address_en,p.address_ko),
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
    'name',p.name_ko,'category',p.category,'address',p.address_ko,'addressEn',nullif(p.address_en,p.address_ko),
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
        'name',pl.name_ko,'category',pl.category,'address',pl.address_ko,'addressEn',nullif(pl.address_en,pl.address_ko),
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
    'name',n.name_ko,'category',n.category,'address',n.address_ko,'addressEn',nullif(n.address_en,n.address_ko),
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

create or replace function public.agent_search_places(
  p_terms text[], p_area text default null,
  p_lat double precision default null, p_lng double precision default null,
  p_radius integer default null, p_kinds text[] default null,
  p_by_taste boolean default false
) returns jsonb language plpgsql stable security invoker set search_path=''
set plan_cache_mode = force_custom_plan as $$
declare result jsonb; terms text[]; kinds text[]; here extensions.geography;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  select coalesce(array_agg(trim(t)),'{}') into terms
    from unnest(p_terms[1:6]) t where length(trim(t)) between 1 and 40;
  select coalesce(array_agg(trim(t)),'{}') into kinds
    from unnest((coalesce(p_kinds,'{}'))[1:16]) t where length(trim(t)) between 1 and 40;
  if cardinality(terms)+cardinality(kinds)=0 and not p_by_taste then raise exception 'Invalid terms'; end if;
  if (p_lat is null) <> (p_lng is null) or
     (p_lat is not null and not (p_lat between 33 and 38.8 and p_lng between 124.5 and 132)) then
    raise exception 'Invalid viewport';
  end if;
  if p_radius is not null and (p_lat is null or p_radius not between 100 and 50000) then
    raise exception 'Invalid radius';
  end if;
  if p_lat is not null then
    here := extensions.st_setsrid(extensions.st_makepoint(p_lng,p_lat),4326)::extensions.geography;
  end if;
  with taste as (
    select public.get_profile_taste((select auth.uid())) as priorities
  ), posted as (
    select p.*, (
      select count(*) from unnest(terms) t where
        public.agent_text_hit(p.name_ko,t) or public.agent_text_hit(p.category,t,true)
        or exists(select 1 from public.posts post where post.place_id=p.id
          and post.is_public and post.status='published' and public.agent_text_hit(post.body,t))
        or exists(select 1 from public.place_insights i where i.place_id=p.id
          and (public.agent_text_hit(i.summary,t) or public.agent_text_hit(i.criteria::text,t)))
    ) as hits,
    -- The kind of place ("치킨") must match its name, category or posts.
    cardinality(kinds)=0 or exists(select 1 from unnest(kinds) k where
      public.agent_text_hit(p.name_ko,k) or public.agent_text_hit(p.category,k,true)
      or exists(select 1 from public.posts post where post.place_id=p.id
        and post.is_public and post.status='published' and public.agent_text_hit(post.body,k))) as is_kind
    from public.places p
    where p.public_post_count>0 and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
      and (p_radius is null or extensions.st_dwithin(p.location,here,p_radius))
  ), scored as (
    select c.*,
      case when cardinality(t.priorities)=3 and (select count(*) from public.place_rating_stats s
          where s.place_id=c.id and s.criterion=any(t.priorities) and s.rating_count>0)=3
        then round(100*(select sum(case s.criterion when t.priorities[1] then .5
            when t.priorities[2] then .3 else .2 end*(s.average-1)/4)
          from public.place_rating_stats s where s.place_id=c.id and s.criterion=any(t.priorities)))
      end as match,
      case when here is null then null else extensions.st_distance(c.location,here) end as meters
    from posted c, taste t
    -- A named kind keeps every place of that kind; mood words only rank them.
    -- "Pick for me" keeps every place of my foods (or every place at all).
    where c.is_kind and (c.hits>0 or cardinality(kinds)>0 or p_by_taste)
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'provider',s.external_provider,'internalId',s.id,'externalPlaceId',s.external_place_id,
    'name',s.name_ko,'category',s.category,'address',s.address_ko,'addressEn',nullif(s.address_en,s.address_ko),
    'latitude',s.latitude,'longitude',s.longitude,
    'sourceUri','https://www.google.com/maps/search/?api=1&query=' || s.latitude || ',' || s.longitude,
    'dataSourceUri',s.source_url,'sourceDate',s.source_date,
    'heroImageUrl',s.hero_image_url,'editorialSummary',s.short_description_ko,
    'pindPhotoPath',photo.photo_path,'pindPhotoAuthor',photo.display_name,'pindPhotoBucket',photo.bucket,
    'pindPostCount',s.public_post_count,'tasteMatch',s.match,
    'meters',round(s.meters),
    'averages',coalesce((select jsonb_object_agg(r.criterion,r.average) from public.place_rating_stats r
      where r.place_id=s.id and r.rating_count>0),'{}'::jsonb),
    'reviewCount',s.public_post_count,
    'saved',exists(select 1 from public.saved_places v where v.place_id=s.id and v.user_id=(select auth.uid()))
  ) order by case when p_by_taste then s.match end desc nulls last,
    s.hits desc, s.match desc nulls last, s.meters nulls last, s.id),'[]'::jsonb)
  into result
  from (select * from scored order by case when p_by_taste then match end desc nulls last,
    hits desc, match desc nulls last, meters nulls last, id limit 30) s
  left join lateral (
    select post.photo_path,profile.display_name,
      case when post.client_request_id is null then 'post-media' else 'post-media-v2' end as bucket
    from public.posts post join public.profiles profile on profile.id=post.author_id
    where post.place_id=s.id and post.is_public and post.status='published'
    order by post.created_at desc,post.id desc limit 1
  ) photo on true;
  return jsonb_build_object('places',result);
end;
$$;

notify pgrst, 'reload schema';
