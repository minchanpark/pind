-- Taste stars (doc/taste-calculation.md): my taste is one 1–5 star per
-- criterion, where 3 is Pind's average. It starts from the onboarding
-- priorities and moves with my own ratings and my saved places' ratings.
-- Place % and friend % both read these stars, so they move with it.

-- Pind-wide public average per criterion. Ratings cluster in the 4s, so
-- stars are read relative to these; raw stars would make every place and
-- every friend look alike.
create function private.criterion_averages()
returns table(criterion text, average numeric)
language sql stable security definer set search_path = '' as $$
  select criterion, sum(rating_sum) / sum(rating_count)
  from public.place_rating_stats
  group by criterion having sum(rating_count) > 0;
$$;

-- [r] on the scale where Pind's average [g] is 3: g → 3, 5 → 5, 1 → 1,
-- linear on each side. No average yet reads as 3.
create function public.taste_star(r numeric, g numeric)
returns numeric language sql immutable set search_path = '' as $$
  select case when r > g then 3 + 2 * (r - g) / (5 - g)
              when r < g then 3 - 2 * (g - r) / (g - 1)
              else 3 end;
$$;

-- [p_user]'s star, weight and evidence count per criterion.
--   start  = 5.0 / 4.2 / 3.8 on the 1st/2nd/3rd priority, 3.0 elsewhere
--   star   = start + min(n / (10 + n), 1/2) × (mean evidence − start)
--   weight = share of (star − 3), so the start is exactly 50/30/20
-- Evidence, one per place and criterion, on the relative scale: my own
-- rating (private ones too: only my taste reads them), else my saved
-- place's public average.
create function private.taste_stars(p_user uuid)
returns table(criterion text, star numeric, weight numeric, evidence bigint)
language sql stable security definer set search_path = '' as $$
  with prio as (
    select priorities from public.taste_profiles where user_id = p_user
  ), start as (
    select c, coalesce((array[5.0, 4.2, 3.8])[array_position(prio.priorities, c)], 3.0) as s
    from prio, unnest(array['taste','ambience','value','portion','service','photogenic','quiet','parking']) c
  ), mine as (
    select place_id, criterion, rating::numeric as r
    from public.place_ratings where user_id = p_user
  ), saved as (
    select v.place_id, st.criterion, st.average as r
    from public.saved_places v
    join public.place_rating_stats st on st.place_id = v.place_id and st.rating_count > 0
    where v.user_id = p_user
      and not exists (select 1 from mine m where m.place_id = v.place_id and m.criterion = st.criterion)
  ), ev as (
    select e.criterion, count(*) as n, avg(public.taste_star(e.r, g.average)) as mean
    from (select * from mine union all select * from saved) e
    left join private.criterion_averages() g on g.criterion = e.criterion
    group by e.criterion
  ), stars as (
    select st.c as criterion, coalesce(ev.n, 0) as n,
      st.s + least(coalesce(ev.n, 0) / (10.0 + coalesce(ev.n, 0)), 0.5) * (coalesce(ev.mean, st.s) - st.s) as star
    from start st left join ev on ev.criterion = st.c
  )
  select criterion, star,
    100 * greatest(star - 3, 0) / nullif(sum(greatest(star - 3, 0)) over (), 0), n
  from stars;
$$;
revoke all on function private.criterion_averages(), private.taste_stars(uuid) from public, anon, authenticated;

-- My taste for the app and for place %: null until I have priorities.
-- Rounded once here so the app and agent search compute from equal numbers.
create function public.get_my_taste()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare me uuid := (select auth.uid()); chosen text[];
begin
  select priorities into chosen from public.taste_profiles where user_id = me;
  if chosen is null then return null; end if;
  return (
    select jsonb_build_object(
      'priorities', to_jsonb(chosen),
      'stars', jsonb_object_agg(s.criterion, round(s.star, 4)),
      'weights', jsonb_object_agg(s.criterion, round(coalesce(s.weight, 0), 4)),
      'averages', (select coalesce(jsonb_object_agg(g.criterion, round(g.average, 4)), '{}'::jsonb)
        from private.criterion_averages() g),
      'evidence', (select count(distinct e.place_id) from (
        select place_id from public.place_ratings where user_id = me
        union
        select v.place_id from public.saved_places v where v.user_id = me
          and exists (select 1 from public.place_rating_stats st
            where st.place_id = v.place_id and st.rating_count > 0)) e))
    from private.taste_stars(me) s);
end;
$$;

-- Place %, mirrored by TasteProfile.match in lib/model/taste_profile.dart:
-- each weighted criterion loses only the share by which the place, read on
-- the relative scale, falls short of my star; beating it costs nothing.
-- Unrated criteria holding 20% or more of the weight leave it unknown.
create function public.taste_place_match(p_taste jsonb, p_averages jsonb)
returns integer language sql immutable set search_path = '' as $$
  with w as (
    select x.key as criterion, x.value::numeric as weight,
      (p_taste -> 'stars' ->> x.key)::numeric as star,
      (p_averages ->> x.key)::numeric as r,
      (p_taste -> 'averages' ->> x.key)::numeric as g
    from jsonb_each_text(p_taste -> 'weights') x
    where x.value::numeric > 0
  )
  select case
    when coalesce(sum(weight) filter (where r is null), 0) >= 20
      or sum(weight) filter (where r is not null) is null then null
    else round(100 * sum(weight * (1 - greatest(0, star - public.taste_star(r, g)) / (star - 1)))
      filter (where r is not null) / sum(weight) filter (where r is not null))::integer
  end
  from w;
$$;
revoke all on function public.taste_star(numeric, numeric), public.get_my_taste(),
  public.taste_place_match(jsonb, jsonb) from public, anon;
grant execute on function public.taste_star(numeric, numeric), public.get_my_taste(),
  public.taste_place_match(jsonb, jsonb) to authenticated;

-- Friend %: each criterion's star gap counts by the pair's mean weight, and
-- a gap of 2 stars counts as wholly different. Callers ensure both profiles.
create or replace function private.taste_match(a uuid, b uuid)
returns integer language sql stable set search_path = '' as $$
  select round(100 - sum((coalesce(x.weight, 0) + coalesce(y.weight, 0)) / 2
    * least(1, abs(x.star - y.star) / 2)))::integer
  from private.taste_stars(a) x join private.taste_stars(b) y using (criterion);
$$;
drop function private.taste_weights(uuid);

-- Agent search ranks by the same place % as the app.
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
    select public.get_my_taste() as profile
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
        and post.is_public and post.status='published' and public.agent_text_hit(post.body,k))) as is_kind,
    coalesce((select jsonb_object_agg(r.criterion,r.average) from public.place_rating_stats r
      where r.place_id=p.id and r.rating_count>0),'{}'::jsonb) as averages
    from public.places p
    where p.public_post_count>0 and p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
      and (p_radius is null or extensions.st_dwithin(p.location,here,p_radius))
  ), scored as (
    select c.*,
      public.taste_place_match(t.profile, c.averages) as match,
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
    'averages',s.averages,
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
