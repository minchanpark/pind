-- Lightweight pins, keyset pagination, and a visible rectangle. Detail photos
-- remain on get_catalog_places; map movements never sign or download photos.
create function public.get_posted_places_page(
  p_after_id bigint default null, p_limit integer default 250,
  p_south double precision default null,p_west double precision default null,
  p_north double precision default null,p_east double precision default null
) returns jsonb language plpgsql stable security invoker set search_path='' as $$
declare result jsonb; cap integer:=least(greatest(coalesce(p_limit,250),1),500);
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if p_after_id is not null and p_after_id<1 then raise exception 'Invalid cursor'; end if;
  if num_nonnulls(p_south,p_west,p_north,p_east) not in (0,4) or
      (p_south is not null and not(p_south<=p_north and p_west<=p_east and
        p_south>=-90 and p_north<=90 and p_west>=-180 and p_east<=180)) then
    raise exception 'Invalid bounds';
  end if;
  with matches as (
    select p.* from public.places p
    where p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind') and p.public_post_count>0
      and (p_after_id is null or p.id>p_after_id)
      and (p_south is null or (
        p.location operator(extensions.&&) extensions.st_makeenvelope(p_west,p_south,p_east,p_north,4326)::extensions.geography
        and p.latitude between p_south and p_north and p.longitude between p_west and p_east))
    order by p.id limit cap+1
  ), page as (select * from matches order by id limit cap)
  select jsonb_build_object('places',coalesce((select jsonb_agg(jsonb_build_object(
    'provider',p.external_provider,'internalId',p.id,'externalPlaceId',p.external_place_id,
    'name',p.name_ko,'category',p.category,'address',p.address_ko,'addressEn',nullif(p.address_en,p.address_ko),
    'latitude',p.latitude,'longitude',p.longitude,'pindPostCount',p.public_post_count,
    'sourceUri','https://www.google.com/maps/search/?api=1&query='||p.latitude||','||p.longitude
  ) order by p.id) from page p),'[]'::jsonb),'hasMore',(select count(*)>cap from matches)) into result;
  return result;
end; $$;
revoke all on function public.get_posted_places_page(bigint,integer,double precision,double precision,double precision,double precision) from public,anon;
grant execute on function public.get_posted_places_page(bigint,integer,double precision,double precision,double precision,double precision) to authenticated;
