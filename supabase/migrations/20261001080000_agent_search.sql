-- Taste-based agent search: the places function turns a sentence into a few
-- terms (and maybe an area) with Gemini, then this ranks places for me.
-- Posted places match on name, category, address, post text and the AI
-- intro/one-liners; unposted catalog places only by name/category within 3km
-- (the 150k catalog is never scanned whole). Ranking: matched terms, then my
-- taste match (same 50/30/20 weights as the app), then distance.
create function public.agent_search_places(
  p_terms text[], p_area text default null,
  p_lat double precision default null, p_lng double precision default null
) returns jsonb language plpgsql stable security invoker set search_path=''
set plan_cache_mode = force_custom_plan as $$
declare result jsonb; patterns text[]; area text; here extensions.geography;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  select coalesce(array_agg('%' || replace(replace(replace(t,chr(92),chr(92)||chr(92)),'%',chr(92)||'%'),'_',chr(92)||'_') || '%'),'{}')
    into patterns from unnest(p_terms[1:6]) t where length(trim(t)) between 1 and 40;
  if cardinality(patterns)=0 then raise exception 'Invalid terms'; end if;
  area := case when length(trim(coalesce(p_area,''))) between 2 and 20 then
    '%' || replace(replace(trim(p_area),'%',''),'_','') || '%' end;
  if (p_lat is null) <> (p_lng is null) or
     (p_lat is not null and not (p_lat between 33 and 38.8 and p_lng between 124.5 and 132)) then
    raise exception 'Invalid viewport';
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
    ) as hits
    from public.places p
    where p.public_post_count>0 and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
      and (area is null or coalesce(p.address_ko,'') ilike area)
  ), unposted as (
    select p.*, (
      select count(*) from unnest(patterns) pat
      where coalesce(p.name_ko,'') ilike pat or coalesce(p.category,'') ilike pat
    ) as hits
    from public.places p
    where here is not null and p.public_post_count=0
      and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
      and extensions.st_dwithin(p.location,here,3000)
      and (area is null or coalesce(p.address_ko,'') ilike area)
  ), candidates as (
    select * from posted where hits>0
    union all
    select * from (select * from unposted where hits>0 limit 200) u
  ), scored as (
    select c.*,
      case when cardinality(t.priorities)=3 and (select count(*) from public.place_rating_stats s
          where s.place_id=c.id and s.criterion=any(t.priorities) and s.rating_count>0)=3
        then round(100*(select sum(case s.criterion when t.priorities[1] then .5
            when t.priorities[2] then .3 else .2 end*(s.average-1)/4)
          from public.place_rating_stats s where s.place_id=c.id and s.criterion=any(t.priorities)))
      end as match,
      case when here is null then null else extensions.st_distance(c.location,here) end as meters
    from candidates c, taste t
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'provider',s.external_provider,'internalId',s.id,'externalPlaceId',s.external_place_id,
    'name',s.name_ko,'category',s.category,'address',s.address_ko,
    'latitude',s.latitude,'longitude',s.longitude,
    'sourceUri','https://www.google.com/maps/search/?api=1&query=' || s.latitude || ',' || s.longitude,
    'dataSourceUri',s.source_url,'sourceDate',s.source_date,
    'heroImageUrl',s.hero_image_url,'editorialSummary',s.short_description_ko,
    'pindPhotoPath',photo.photo_path,'pindPhotoAuthor',photo.display_name,'pindPhotoBucket',photo.bucket,
    'pindPostCount',s.public_post_count,'tasteMatch',s.match
  ) order by s.public_post_count>0 desc, s.hits desc, s.match desc nulls last, s.meters nulls last, s.id),'[]'::jsonb)
  into result
  from (select * from scored order by public_post_count>0 desc, hits desc, match desc nulls last,
    meters nulls last, id limit 30) s
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
revoke all on function public.agent_search_places(text[],text,double precision,double precision) from public,anon;
grant execute on function public.agent_search_places(text[],text,double precision,double precision) to authenticated;

notify pgrst, 'reload schema';
