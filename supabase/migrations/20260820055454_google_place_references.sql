alter table public.places
  add column is_reference_only boolean not null default false,
  alter column name_en drop not null,
  alter column name_ko drop not null,
  alter column category drop not null,
  alter column address_en drop not null,
  alter column address_ko drop not null,
  alter column latitude drop not null,
  alter column longitude drop not null,
  alter column hero_image_url drop not null,
  alter column short_description_en drop not null,
  alter column short_description_ko drop not null;

alter table public.places
  add constraint places_content_shape_check
  check (
    (
      is_reference_only = false
      and name_en is not null
      and name_ko is not null
      and category is not null
      and address_en is not null
      and address_ko is not null
      and latitude is not null
      and longitude is not null
      and hero_image_url is not null
      and short_description_en is not null
      and short_description_ko is not null
    )
    or
    (
      is_reference_only = true
      and external_provider = 'google_places'
      and external_place_id is not null
      and length(external_place_id) between 8 and 255
      and name_en is null
      and name_ko is null
      and category is null
      and address_en is null
      and address_ko is null
      and latitude is null
      and longitude is null
      and hero_image_url is null
      and short_description_en is null
      and short_description_ko is null
      and is_demo = false
    )
  );

create index places_google_reference_idx
  on public.places (external_place_id)
  where external_provider = 'google_places' and is_reference_only = true;

comment on column public.places.is_reference_only is
  'True for durable external identifiers. Provider content is fetched fresh and is never persisted here.';

comment on column public.places.external_place_id is
  'Provider identifier only. Google Place IDs may be stored; Google place content and photo references are not cached.';
;
