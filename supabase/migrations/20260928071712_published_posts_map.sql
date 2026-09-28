-- Keep legacy reviews and their public media intact; new uploads use a private bucket.
alter table public.posts
  drop constraint posts_menu_name_check,
  drop constraint posts_body_check,
  add constraint posts_menu_name_check check (char_length(menu_name) between 0 and 80),
  add constraint posts_body_check check (char_length(body) between 0 and 2000),
  add column taste_score smallint check (taste_score between 1 and 5),
  add column portion_score smallint check (portion_score between 1 and 5),
  add column ambience_score smallint check (ambience_score between 1 and 5),
  add column client_request_id uuid,
  add column status text not null default 'published' check (status in ('published','hidden')),
  add constraint posts_v2_shape_check check (client_request_id is null or
    (taste_score is not null and portion_score is not null and ambience_score is not null
      and char_length(body) <= 200));
create unique index posts_author_request_idx on public.posts(author_id,client_request_id)
  where client_request_id is not null;
create index posts_visible_place_idx on public.posts(place_id,created_at desc,id desc)
  where is_public and status='published';
alter policy posts_public_or_owner_read on public.posts using
  ((is_public and status='published') or author_id=(select auth.uid()));

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('post-media-v2','post-media-v2',false,10485760,
  array['image/jpeg','image/png','image/webp','image/heic','image/heif'])
on conflict(id) do nothing;

create table public.post_media (
  id bigint generated always as identity primary key,
  post_id bigint not null references public.posts(id) on delete cascade,
  position smallint not null check (position between 0 and 9),
  bucket text not null default 'post-media-v2' check (bucket='post-media-v2'),
  path text not null check (char_length(path) between 1 and 512),
  mime text not null check (mime in ('image/jpeg','image/png','image/webp','image/heic','image/heif')),
  bytes integer not null check (bytes between 1 and 10485760),
  unique(post_id,position), unique(bucket,path)
);
alter table public.post_media enable row level security;
revoke all on public.post_media from public,anon;
revoke all on sequence public.post_media_id_seq from public,anon;
grant select,insert,delete on public.post_media to authenticated;
grant usage,select on sequence public.post_media_id_seq to authenticated;
create policy post_media_read on public.post_media for select to authenticated
using (exists(select 1 from public.posts p where p.id=post_id));
create policy post_media_insert on public.post_media for insert to authenticated
with check (
  split_part(path,'/',1)=(select auth.uid())::text and
  exists(select 1 from public.posts p where p.id=post_id and p.author_id=(select auth.uid()))
);
create policy post_media_delete on public.post_media for delete to authenticated
using (exists(select 1 from public.posts p where p.id=post_id and p.author_id=(select auth.uid())));

create policy post_media_v2_upload on storage.objects for insert to authenticated
with check (bucket_id='post-media-v2' and (storage.foldername(name))[1]=(select auth.uid())::text
  and not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false));
create policy post_media_v2_read on storage.objects for select to authenticated
using (bucket_id='post-media-v2' and (
  (storage.foldername(name))[1]=(select auth.uid())::text or exists(
    select 1 from public.post_media m join public.posts p on p.id=m.post_id
    where m.bucket=bucket_id and m.path=name and p.is_public and p.status='published'
  )
));
create policy post_media_v2_remove_unattached on storage.objects for delete to authenticated
using (bucket_id='post-media-v2' and (storage.foldername(name))[1]=(select auth.uid())::text
  and not exists(select 1 from public.post_media m where m.bucket=bucket_id and m.path=name));

create function public.publish_post_v2(
  p_client_request_id uuid, p_place_id bigint,
  p_taste_score integer, p_portion_score integer, p_ambience_score integer,
  p_body text, p_media jsonb
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
  if p_taste_score is null or p_taste_score not between 1 and 5 or
    p_portion_score is null or p_portion_score not between 1 and 5 or
    p_ambience_score is null or p_ambience_score not between 1 and 5 then
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
    taste_score,portion_score,ambience_score,client_request_id,status)
  values(caller,p_place_id,'',p_media->0->>'path','🍽️',trim(coalesce(p_body,'')),true,
    p_taste_score,p_portion_score,p_ambience_score,p_client_request_id,'published')
  returning * into created;
  for item in select value from jsonb_array_elements(p_media) loop
    insert into public.post_media(post_id,position,path,mime,bytes)
      values(created.id,position,item->>'path',item->>'mime',(item->>'bytes')::integer);
    position:=position+1;
  end loop;
  insert into public.place_ratings(user_id,place_id,criterion,rating,is_public) values
    (caller,p_place_id,'taste',p_taste_score,true),
    (caller,p_place_id,'portion',p_portion_score,true),
    (caller,p_place_id,'ambience',p_ambience_score,true)
  on conflict(user_id,place_id,criterion) do update set rating=excluded.rating,is_public=excluded.is_public;
  return jsonb_build_object('id',created.id,'placeId',created.place_id);
end;
$$;
revoke all on function public.publish_post_v2(uuid,bigint,integer,integer,integer,text,jsonb) from public,anon;
grant execute on function public.publish_post_v2(uuid,bigint,integer,integer,integer,text,jsonb) to authenticated;

-- Filter posted restaurants before the nearby result limit; search still finds unposted places.
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
  if p_query is null and p_lat is null and p_place_id is null then
    raise exception 'Query, viewport or place ID required';
  end if;
  pattern := '%' || replace(replace(replace(trim(p_query),chr(92),chr(92)||chr(92)),
    '%',chr(92)||'%'),'_',chr(92)||'_') || '%';
  with candidates as (
    select p.* from public.places p
    where p.is_published and not p.is_demo and not p.is_reference_only
      and p.external_provider in ('sbiz','pind')
      and (p_lat is null or exists(select 1 from public.posts map_post
        where map_post.place_id=p.id and map_post.is_public and map_post.status='published'))
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
    'pindPhotoPath',photo.photo_path,'pindPhotoAuthor',photo.display_name,'pindPhotoBucket',photo.bucket,
    'pindPostCount',(select count(*) from public.posts post where post.place_id=p.id and post.is_public and post.status='published')
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
