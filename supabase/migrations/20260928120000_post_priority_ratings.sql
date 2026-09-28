-- Post ratings follow the author's three onboarding priorities.
alter table public.posts
  add column ratings jsonb,
  drop constraint posts_v2_shape_check,
  add constraint posts_v2_shape_check check (client_request_id is null or
    (char_length(body) <= 200 and (ratings is not null or
      (taste_score is not null and portion_score is not null and ambience_score is not null))));

create function public.publish_post_v3(
  p_client_request_id uuid, p_place_id bigint, p_ratings jsonb,
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
  values(caller,p_place_id,'',p_media->0->>'path','🍽️',trim(coalesce(p_body,'')),true,
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
revoke all on function public.publish_post_v3(uuid,bigint,jsonb,text,jsonb) from public,anon;
grant execute on function public.publish_post_v3(uuid,bigint,jsonb,text,jsonb) to authenticated;

-- Older builds keep publishing through the fixed taste/portion/ambience axes.
create or replace function public.publish_post_v2(
  p_client_request_id uuid, p_place_id bigint,
  p_taste_score integer, p_portion_score integer, p_ambience_score integer,
  p_body text, p_media jsonb
) returns jsonb language sql security invoker set search_path='' as $$
  select public.publish_post_v3(p_client_request_id, p_place_id,
    jsonb_build_object('taste',p_taste_score,'portion',p_portion_score,'ambience',p_ambience_score),
    p_body, p_media);
$$;
