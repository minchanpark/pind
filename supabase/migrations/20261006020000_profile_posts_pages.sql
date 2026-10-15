create function public.get_profile_posts_page(
  p_user uuid default null,p_before_created timestamptz default null,
  p_before_id bigint default null,p_limit integer default 20
) returns jsonb language plpgsql stable security invoker set search_path='' as $$
declare result jsonb;cap integer:=least(greatest(coalesce(p_limit,20),1),50);
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if (p_before_created is null) <> (p_before_id is null) then raise exception 'Invalid cursor'; end if;
  with matches as (
    select post.* from public.posts post join public.places p on p.id=post.place_id
    where post.author_id=coalesce(p_user,(select auth.uid())) and post.status='published'
      and p.is_published and not p.is_demo and not p.is_reference_only and p.external_provider in ('sbiz','pind')
      and (p_before_created is null or (post.created_at,post.id)<(p_before_created,p_before_id))
    order by post.created_at desc,post.id desc limit cap+1
  ), page as (select * from matches order by created_at desc,id desc limit cap)
  select jsonb_build_object('posts',coalesce((select jsonb_agg(jsonb_build_object(
    'id',post.id,'body',post.body,'createdAt',post.created_at,
    'ratings',coalesce(post.ratings,jsonb_strip_nulls(jsonb_build_object('taste',post.taste_score,'portion',post.portion_score,'ambience',post.ambience_score))),
    'bucket',case when post.client_request_id is null then 'post-media' else 'post-media-v2' end,
    'photos',coalesce((select jsonb_agg(media.path order by media.position) from public.post_media media where media.post_id=post.id),jsonb_build_array(post.photo_path)),
    'place',jsonb_build_object('provider',p.external_provider,'internalId',p.id,'externalPlaceId',p.external_place_id,
      'name',p.name_ko,'category',p.category,'address',p.address_ko,'addressEn',nullif(p.address_en,p.address_ko),
      'latitude',p.latitude,'longitude',p.longitude,
      'sourceUri','https://www.google.com/maps/search/?api=1&query='||p.latitude||','||p.longitude)
  ) order by post.created_at desc,post.id desc) from page post join public.places p on p.id=post.place_id),'[]'::jsonb),
    'hasMore',(select count(*)>cap from matches)) into result;
  return result;
end; $$;
revoke all on function public.get_profile_posts_page(uuid,timestamptz,bigint,integer) from public,anon;
grant execute on function public.get_profile_posts_page(uuid,timestamptz,bigint,integer) to authenticated;
create index if not exists posts_author_page_idx on public.posts(author_id,created_at desc,id desc) where status='published';
