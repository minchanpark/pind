-- Agent search tells the kind of place from what it should be like: p_kinds
-- ("치킨","통닭") must match a place's name, category or posts, while p_terms
-- ("사진","인테리어") only rank. Before, "사진 잘 나오는 치킨집" returned cafes
-- whose posts said 사진. Old calls (no p_kinds) behave as before.
drop function public.agent_search_places(text[],text,double precision,double precision,integer);
create function public.agent_search_places(
  p_terms text[], p_area text default null,
  p_lat double precision default null, p_lng double precision default null,
  p_radius integer default null, p_kinds text[] default null
) returns jsonb language plpgsql stable security invoker set search_path=''
set plan_cache_mode = force_custom_plan as $$
declare result jsonb; patterns text[]; kinds text[]; here extensions.geography;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  select coalesce(array_agg('%' || replace(replace(replace(t,chr(92),chr(92)||chr(92)),'%',chr(92)||'%'),'_',chr(92)||'_') || '%'),'{}')
    into patterns from unnest(p_terms[1:6]) t where length(trim(t)) between 1 and 40;
  select coalesce(array_agg('%' || replace(replace(replace(t,chr(92),chr(92)||chr(92)),'%',chr(92)||'%'),'_',chr(92)||'_') || '%'),'{}')
    into kinds from unnest((coalesce(p_kinds,'{}'))[1:4]) t where length(trim(t)) between 1 and 40;
  if cardinality(patterns)+cardinality(kinds)=0 then raise exception 'Invalid terms'; end if;
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
      select count(*) from unnest(patterns) pat where
        coalesce(p.name_ko,'') ilike pat or coalesce(p.category,'') ilike pat
        or exists(select 1 from public.posts post where post.place_id=p.id
          and post.is_public and post.status='published' and post.body ilike pat)
        or exists(select 1 from public.place_insights i where i.place_id=p.id
          and (i.summary ilike pat or i.criteria::text ilike pat))
    ) as hits,
    -- The kind of place ("치킨") must match its name, category or posts.
    cardinality(kinds)=0 or exists(select 1 from unnest(kinds) k where
      coalesce(p.name_ko,'') ilike k or coalesce(p.category,'') ilike k
      or exists(select 1 from public.posts post where post.place_id=p.id
        and post.is_public and post.status='published' and post.body ilike k)) as is_kind
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
    where c.is_kind and (c.hits>0 or cardinality(kinds)>0)
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'provider',s.external_provider,'internalId',s.id,'externalPlaceId',s.external_place_id,
    'name',s.name_ko,'category',s.category,'address',s.address_ko,
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
  ) order by s.hits desc, s.match desc nulls last, s.meters nulls last, s.id),'[]'::jsonb)
  into result
  from (select * from scored order by hits desc, match desc nulls last, meters nulls last, id limit 30) s
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

revoke all on function public.agent_search_places(text[],text,double precision,double precision,integer,text[]) from public,anon;
grant execute on function public.agent_search_places(text[],text,double precision,double precision,integer,text[]) to authenticated;

notify pgrst, 'reload schema';
