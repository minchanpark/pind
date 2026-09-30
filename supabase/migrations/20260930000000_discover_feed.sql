-- Discover feed: public posts from every user, newest first, with per-user likes.
create table public.post_likes (
  user_id uuid not null references auth.users(id) on delete cascade,
  post_id bigint not null references public.posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);
create index post_likes_post_idx on public.post_likes(post_id);
alter table public.post_likes enable row level security;
revoke all on public.post_likes from public,anon;
grant select, insert, delete on public.post_likes to authenticated;
-- Likes on visible posts are public social proof; own rows stay readable after a post is hidden.
create policy post_likes_read on public.post_likes for select to authenticated
using (user_id=(select auth.uid()) or
  exists(select 1 from public.posts p where p.id=post_id and p.is_public and p.status='published'));
create policy post_likes_insert on public.post_likes for insert to authenticated
with check (user_id=(select auth.uid())
  and not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false)
  and exists(select 1 from public.posts p where p.id=post_id and p.is_public and p.status='published'));
create policy post_likes_delete on public.post_likes for delete to authenticated
using (user_id=(select auth.uid()));

create index posts_visible_feed_idx on public.posts(created_at desc,id desc)
  where is_public and status='published';

create function public.toggle_post_like(p_post_id bigint, p_liked boolean)
returns boolean language sql volatile security invoker set search_path='' as $$
  insert into public.post_likes(user_id,post_id) select (select auth.uid()),p_post_id where p_liked
  on conflict(user_id,post_id) do nothing;
  delete from public.post_likes where not p_liked and user_id=(select auth.uid()) and post_id=p_post_id;
  select exists(select 1 from public.post_likes where user_id=(select auth.uid()) and post_id=p_post_id);
$$;
revoke all on function public.toggle_post_like(bigint,boolean) from public,anon;
grant execute on function public.toggle_post_like(bigint,boolean) to authenticated;

-- Invoker keeps RLS: published places only; keyset cursor is the last (createdAt,id) of the previous page.
create function public.get_discover_feed(
  p_query text default null, p_before_created timestamptz default null,
  p_before_id bigint default null, p_limit integer default 20
) returns jsonb language sql stable security invoker set search_path='' as $$
  with q as (
    select '%' || replace(replace(replace(nullif(trim(p_query),''),chr(92),chr(92)||chr(92)),
      '%',chr(92)||'%'),'_',chr(92)||'_') || '%' as pattern
  ), feed as (
    select post.* from q,public.posts post
    join public.places p on p.id=post.place_id
    where post.is_public and post.status='published'
      and (p_before_created is null or (post.created_at,post.id) < (p_before_created,p_before_id))
      and (q.pattern is null or p.name_ko ilike q.pattern or p.category ilike q.pattern
        or post.body ilike q.pattern)
    order by post.created_at desc,post.id desc
    limit least(greatest(coalesce(p_limit,20),1),50)
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',post.id,
    'author',jsonb_build_object('id',post.author_id,'handle',author.handle,
      'displayName',author.display_name,'avatarUrl',author.avatar_url),
    'place',jsonb_build_object(
      'provider',p.external_provider,'internalId',p.id,'externalPlaceId',p.external_place_id,
      'name',p.name_ko,'category',p.category,'address',p.address_ko,
      'latitude',p.latitude,'longitude',p.longitude,
      'sourceUri','https://www.google.com/maps/search/?api=1&query=' || p.latitude || ',' || p.longitude,
      'heroImageUrl',p.hero_image_url,'pindPhotoPath',photo.photo_path,'pindPhotoBucket',photo.bucket),
    'body',post.body,
    'ratings',coalesce(post.ratings,jsonb_strip_nulls(jsonb_build_object('taste',post.taste_score,
      'portion',post.portion_score,'ambience',post.ambience_score))),
    'bucket',case when post.client_request_id is null then 'post-media' else 'post-media-v2' end,
    'photos',coalesce((select jsonb_agg(media.path order by media.position) from public.post_media media
      where media.post_id=post.id),jsonb_build_array(post.photo_path)),
    'createdAt',post.created_at,
    'likeCount',(select count(*) from public.post_likes l where l.post_id=post.id),
    'liked',exists(select 1 from public.post_likes l where l.post_id=post.id and l.user_id=(select auth.uid()))
  ) order by post.created_at desc,post.id desc),'[]'::jsonb)
  from feed post
  join public.places p on p.id=post.place_id
  left join public.profiles author on author.id=post.author_id
  left join lateral (
    select latest.photo_path,
      case when latest.client_request_id is null then 'post-media' else 'post-media-v2' end as bucket
    from public.posts latest
    where latest.place_id=p.id and latest.is_public and latest.status='published'
    order by latest.created_at desc,latest.id desc limit 1
  ) photo on true
  having (select auth.uid()) is not null;
$$;
revoke all on function public.get_discover_feed(text,timestamptz,bigint,integer) from public,anon;
grant execute on function public.get_discover_feed(text,timestamptz,bigint,integer) to authenticated;


notify pgrst, 'reload schema';
