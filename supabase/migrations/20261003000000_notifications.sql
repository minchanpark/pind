-- Feed 알림 (Figma 788:23179), built from what already happens instead of a
-- separate table: likes on my posts, posts by people I follow ("다녀갔어요"),
-- and new followers. The last 30 days, newest first. notifications_seen_at
-- marks everything up to then as read ("모두 읽음"), on every device.
alter table public.profiles add column notifications_seen_at timestamptz;

create function public.get_notifications(p_limit integer default 50)
returns jsonb language sql stable security invoker set search_path='' as $$
  with me as (select (select auth.uid()) as id),
  events as (
    -- Someone liked one of my posts.
    select 'like' as kind, l.created_at as at, l.user_id as actor, p.id as post_id, p.place_id
    from public.post_likes l join public.posts p on p.id=l.post_id, me
    where p.author_id=me.id and l.user_id<>me.id and p.status='published'
      and l.created_at > now()-interval '30 days'
    union all
    -- Someone I follow posted a visit.
    select 'visit', p.created_at, p.author_id, p.id, p.place_id
    from public.posts p join public.follows f on f.followee_id=p.author_id, me
    where f.follower_id=me.id and p.author_id<>me.id and p.is_public and p.status='published'
      and p.created_at > now()-interval '30 days'
    union all
    -- Someone followed me.
    select 'follow', f.created_at, f.follower_id, null, null
    from public.follows f, me
    where f.followee_id=me.id and f.created_at > now()-interval '30 days'
  ), recent as (
    select * from events order by at desc limit least(greatest(coalesce(p_limit,50),1),100)
  )
  select jsonb_build_object(
    'seenAt',(select notifications_seen_at from public.profiles where id=(select id from me)),
    'items',coalesce(jsonb_agg(jsonb_build_object(
      'kind',r.kind,'at',r.at,'postId',r.post_id,
      'actor',jsonb_build_object('id',a.id,'handle',a.handle,'displayName',a.display_name,
        'avatarUrl',a.avatar_url),
      'place',case when pl.id is null then null else jsonb_build_object(
        'provider',pl.external_provider,'internalId',pl.id,'externalPlaceId',pl.external_place_id,
        'name',pl.name_ko,'category',pl.category,'address',pl.address_ko,
        'latitude',pl.latitude,'longitude',pl.longitude,
        'sourceUri','https://www.google.com/maps/search/?api=1&query=' || pl.latitude || ',' || pl.longitude,
        'pindPostCount',pl.public_post_count) end,
      'photoPath',post.photo_path,
      'photoBucket',case when post.id is null then null
        when post.client_request_id is null then 'post-media' else 'post-media-v2' end
    ) order by r.at desc),'[]'::jsonb))
  from recent r
  join public.profiles a on a.id=r.actor
  left join public.posts post on post.id=r.post_id
  left join public.places pl on pl.id=r.place_id
$$;
revoke all on function public.get_notifications(integer) from public,anon;
grant execute on function public.get_notifications(integer) to authenticated;

-- "모두 읽음": everything up to now is read.
create function public.mark_notifications_read()
returns timestamptz language sql security invoker set search_path='' as $$
  update public.profiles set notifications_seen_at=now()
  where id=(select auth.uid()) returning notifications_seen_at
$$;
grant update (notifications_seen_at) on public.profiles to authenticated;
revoke all on function public.mark_notifications_read() from public,anon;
grant execute on function public.mark_notifications_read() to authenticated;

notify pgrst, 'reload schema';
