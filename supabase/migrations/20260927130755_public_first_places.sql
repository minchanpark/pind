-- Public/Pind content is durable; Google rows remain identifier-only.
create schema if not exists extensions;
create extension if not exists postgis with schema extensions;
create extension if not exists pg_trgm with schema extensions;
grant usage on schema extensions to authenticated, service_role;

alter table public.places drop constraint places_content_shape_check;
alter table public.places add constraint places_content_shape_check check (
  (not is_reference_only and external_provider <> 'google_places'
    and name_ko is not null and category is not null and address_ko is not null
    and latitude is not null and longitude is not null)
  or (is_reference_only and external_provider = 'google_places'
    and external_place_id is not null and length(external_place_id) between 8 and 255
    and name_en is null and name_ko is null and category is null
    and address_en is null and address_ko is null and latitude is null and longitude is null
    and hero_image_url is null and short_description_en is null and short_description_ko is null
    and not is_demo)
);
alter table public.places
  add column source_url text check (source_url is null or source_url ~ '^https://'),
  add column source_date date,
  add column imported_at timestamptz,
  add column location extensions.geography(point,4326) generated always as (
    case when not is_reference_only then
      extensions.st_setsrid(extensions.st_makepoint(longitude,latitude),4326)::extensions.geography
    end
  ) stored;
create index places_catalog_location_idx on public.places using gist(location)
  where is_published and not is_demo and not is_reference_only;
create index places_catalog_search_idx on public.places using gin
  ((coalesce(name_ko,'') || ' ' || coalesce(address_ko,'')) extensions.gin_trgm_ops)
  where is_published and not is_demo and not is_reference_only;

-- Caller JWT/RLS is retained. No service-role read of users' private posts.
create function public.get_catalog_places(
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
  if p_query is null and p_lat is null and p_place_id is null then
    raise exception 'Query, viewport or place ID required';
  end if;
  pattern := '%' || replace(replace(replace(trim(p_query),chr(92),chr(92)||chr(92)),
    '%',chr(92)||'%'),'_',chr(92)||'_') || '%';
  with candidates as (
    select p.* from public.places p
    where p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
      and (p_place_id is null or p.id = p_place_id)
      and (p_query is null or (coalesce(p.name_ko,'') || ' ' || coalesce(p.address_ko,'')) ilike pattern)
      and (p_lat is null or extensions.st_dwithin(p.location,
        extensions.st_setsrid(extensions.st_makepoint(p_lng,p_lat),4326)::extensions.geography,p_radius))
    order by case when p_lat is not null then p.location operator(extensions.<->)
      extensions.st_setsrid(extensions.st_makepoint(p_lng,p_lat),4326)::extensions.geography end,
      p.name_ko,p.id
    limit 30
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'provider',p.external_provider,'internalId',p.id,'externalPlaceId',p.external_place_id,
    'name',p.name_ko,'category',p.category,'address',p.address_ko,
    'latitude',p.latitude,'longitude',p.longitude,
    'sourceUri','https://www.google.com/maps/search/?api=1&query=' || p.latitude || ',' || p.longitude,
    'dataSourceUri',p.source_url,'sourceDate',p.source_date,
    'heroImageUrl',p.hero_image_url,'editorialSummary',p.short_description_ko,
    'pindPhotoPath',photo.photo_path,'pindPhotoAuthor',photo.display_name,
    'pindPostCount',(select count(*) from public.posts post where post.place_id=p.id and post.is_public)
  )), '[]'::jsonb) into result from candidates p
  left join lateral (
    select post.photo_path,profile.display_name from public.posts post
    join public.profiles profile on profile.id=post.author_id
    where post.place_id=p.id and post.is_public order by post.created_at desc,post.id desc limit 1
  ) photo on true;
  return jsonb_build_object('places',result,'catalogReady',exists(
    select 1 from public.places where is_published and not is_demo and not is_reference_only
      and external_provider in ('sbiz','pind')
  ));
end;
$$;
revoke all on function public.get_catalog_places(text,double precision,double precision,integer,bigint) from public,anon;
grant execute on function public.get_catalog_places(text,double precision,double precision,integer,bigint) to authenticated;

-- Admin batch import. Existing internal IDs, moderation, Pind media and descriptions survive.
create function public.import_sbiz_places(p_rows jsonb,p_source_date date)
returns integer language plpgsql security invoker set search_path = '' as $$
declare affected integer;
begin
  if p_source_date is null or p_source_date > current_date or jsonb_typeof(p_rows) <> 'array'
    or jsonb_array_length(p_rows) not between 1 and 1000 then raise exception 'Invalid import'; end if;
  if exists(select 1 from jsonb_array_elements(p_rows) r where
    coalesce(length(trim(r->>'id')),0) not between 1 and 100 or
    coalesce(length(trim(r->>'name')),0) not between 1 and 200 or
    coalesce(length(trim(r->>'category')),0) not between 1 and 200 or
    coalesce(length(trim(r->>'address')),0) not between 1 and 500 or
    r->>'latitude' is null or r->>'longitude' is null or
    not ((r->>'latitude')::float8 between 33 and 38.8 and (r->>'longitude')::float8 between 124.5 and 132)
  ) then raise exception 'Invalid public place'; end if;
  insert into public.places(slug,external_provider,external_place_id,name_en,name_ko,category,
    address_en,address_ko,latitude,longitude,is_demo,is_published,source_url,source_date,imported_at)
  select 'sbiz-'||(r->>'id'),'sbiz',r->>'id',r->>'name',r->>'name',r->>'category',
    r->>'address',r->>'address',(r->>'latitude')::float8,(r->>'longitude')::float8,false,true,
    'https://www.data.go.kr/data/15083033/fileData.do',p_source_date,now()
  from jsonb_array_elements(p_rows) r
  on conflict (external_provider,external_place_id) do update set
    name_en=excluded.name_en,name_ko=excluded.name_ko,category=excluded.category,
    address_en=excluded.address_en,address_ko=excluded.address_ko,
    latitude=excluded.latitude,longitude=excluded.longitude,source_url=excluded.source_url,
    source_date=excluded.source_date,imported_at=excluded.imported_at,updated_at=now()
  where public.places.source_date is null or excluded.source_date >= public.places.source_date;
  get diagnostics affected = row_count;
  return affected;
end;
$$;
revoke all on function public.import_sbiz_places(jsonb,date) from public,anon,authenticated;
grant execute on function public.import_sbiz_places(jsonb,date) to service_role;
grant select,insert,update on public.places to service_role;
grant usage,select on sequence public.places_id_seq to service_role;

create schema if not exists private;
create table private.place_api_daily_total(day date primary key,requests integer not null default 0);
create table private.place_api_daily_user(
  day date not null,user_id uuid not null,requests integer not null default 0,primary key(day,user_id)
);
alter table private.place_api_daily_total enable row level security;
alter table private.place_api_daily_user enable row level security;
revoke all on private.place_api_daily_total,private.place_api_daily_user from public,anon,authenticated;
grant usage on schema private to service_role;
grant select,insert,update on private.place_api_daily_total,private.place_api_daily_user to service_role;
-- Each outgoing Google request reserves one unit. Both counters roll back on any rejection.
create function public.take_place_google_budget(p_user_id uuid,p_user_limit integer default 20,p_total_limit integer default 1000)
returns void language plpgsql security invoker set search_path = '' as $$
declare d date := (now() at time zone 'Asia/Seoul')::date; affected integer;
begin
  if p_user_id is null or p_user_limit is null or p_total_limit is null or
    p_user_limit < 1 or p_total_limit < 1 then raise exception 'GOOGLE_BUDGET_DISABLED'; end if;
  insert into private.place_api_daily_total(day) values(d) on conflict do nothing;
  update private.place_api_daily_total set requests=requests+1 where day=d and requests<p_total_limit;
  get diagnostics affected = row_count;
  if affected=0 then raise exception 'GOOGLE_DAILY_LIMIT'; end if;
  insert into private.place_api_daily_user(day,user_id) values(d,p_user_id) on conflict do nothing;
  update private.place_api_daily_user set requests=requests+1 where day=d and user_id=p_user_id and requests<p_user_limit;
  get diagnostics affected = row_count;
  if affected=0 then raise exception 'GOOGLE_USER_LIMIT'; end if;
end;
$$;
revoke all on function public.take_place_google_budget(uuid,integer,integer) from public,anon,authenticated;
grant execute on function public.take_place_google_budget(uuid,integer,integer) to service_role;
