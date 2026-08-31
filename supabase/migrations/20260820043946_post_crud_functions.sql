create or replace function public.create_post(
  p_place_id bigint,
  p_menu_name text,
  p_photo_path text,
  p_emoji text,
  p_body text,
  p_taste_tag_codes text[],
  p_is_public boolean default true
)
returns public.posts
language plpgsql
set search_path = ''
as $$
declare
  created_post public.posts;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication is required';
  end if;

  if coalesce(cardinality(p_taste_tag_codes), 0) < 1 then
    raise exception 'Choose at least one taste tag';
  end if;

  insert into public.posts (
    author_id, place_id, menu_name, photo_path, emoji, body, is_public
  )
  values (
    (select auth.uid()), p_place_id, trim(p_menu_name), p_photo_path,
    p_emoji, trim(p_body), p_is_public
  )
  returning * into created_post;

  insert into public.post_taste_tags (post_id, taste_tag_code)
  select created_post.id, tag_code
  from unnest(p_taste_tag_codes) as tag_code;

  return created_post;
end;
$$;

create or replace function public.update_post(
  p_post_id bigint,
  p_place_id bigint,
  p_menu_name text,
  p_photo_path text,
  p_emoji text,
  p_body text,
  p_taste_tag_codes text[],
  p_is_public boolean default true
)
returns public.posts
language plpgsql
set search_path = ''
as $$
declare
  updated_post public.posts;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication is required';
  end if;

  if coalesce(cardinality(p_taste_tag_codes), 0) < 1 then
    raise exception 'Choose at least one taste tag';
  end if;

  update public.posts
  set
    place_id = p_place_id,
    menu_name = trim(p_menu_name),
    photo_path = p_photo_path,
    emoji = p_emoji,
    body = trim(p_body),
    is_public = p_is_public
  where id = p_post_id
    and author_id = (select auth.uid())
  returning * into updated_post;

  if updated_post.id is null then
    raise exception 'Post not found or not owned by the current user';
  end if;

  delete from public.post_taste_tags
  where post_id = updated_post.id;

  insert into public.post_taste_tags (post_id, taste_tag_code)
  select updated_post.id, tag_code
  from unnest(p_taste_tag_codes) as tag_code;

  return updated_post;
end;
$$;

revoke all on function public.create_post(bigint, text, text, text, text, text[], boolean) from public;
revoke all on function public.update_post(bigint, bigint, text, text, text, text, text[], boolean) from public;
grant execute on function public.create_post(bigint, text, text, text, text, text[], boolean) to authenticated;
grant execute on function public.update_post(bigint, bigint, text, text, text, text, text[], boolean) to authenticated;
