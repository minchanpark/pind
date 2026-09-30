-- Profile page: editable handle/bio/avatar, 24h recently viewed places, one overview RPC.
alter table public.profiles
  add column handle text check (handle ~ '^[a-z0-9_]{3,20}$'),
  add column bio text check (char_length(bio) <= 80),
  add column updated_at timestamptz not null default now();
create unique index profiles_handle_idx on public.profiles(handle) where handle is not null;
grant update (handle, bio) on public.profiles to authenticated;

create function private.guard_profile_update() returns trigger
language plpgsql set search_path='' as $$
begin
  if old.handle is not null and new.handle is distinct from old.handle then
    raise exception 'handle is immutable';
  end if;
  new.updated_at := now();
  return new;
end;
$$;
revoke all on function private.guard_profile_update() from public,anon,authenticated;
create trigger guard_profile_update before update on public.profiles
for each row execute function private.guard_profile_update();

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('avatars','avatars',true,5242880,
  array['image/jpeg','image/png','image/webp','image/heic','image/heif'])
on conflict(id) do nothing;
create policy avatars_insert on storage.objects for insert to authenticated
with check (bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text
  and not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false));
create policy avatars_update on storage.objects for update to authenticated
using (bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text
  and not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false))
with check (bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy avatars_delete on storage.objects for delete to authenticated
using (bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text
  and not coalesce(((select auth.jwt())->>'is_anonymous')::boolean,false));

alter table public.saved_places add column saved_at timestamptz not null default now();

create table public.place_views (
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id bigint not null references public.places(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (user_id, place_id)
);
create index place_views_user_viewed_idx on public.place_views(user_id, viewed_at desc);
alter table public.place_views enable row level security;
grant select, insert, update, delete on public.place_views to authenticated;
create policy place_views_owner on public.place_views for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create function public.record_place_view(p_place_id bigint)
returns void language sql volatile security invoker set search_path='' as $$
  insert into public.place_views(user_id,place_id) values((select auth.uid()),p_place_id)
  on conflict(user_id,place_id) do update set viewed_at=now();
  delete from public.place_views
  where user_id=(select auth.uid()) and viewed_at < now() - interval '24 hours';
$$;
revoke all on function public.record_place_view(bigint) from public,anon;
grant execute on function public.record_place_view(bigint) to authenticated;

do $$ begin
  create extension if not exists pg_cron;
  perform cron.schedule('purge_place_views','15 * * * *',
    $job$delete from public.place_views where viewed_at < now() - interval '24 hours'$job$);
exception when others then raise notice 'pg_cron unavailable: %', sqlerrm; end $$;

-- Invoker keeps RLS: only the caller's views/saves/posts and published places.
create function public.get_my_profile_overview()
returns jsonb language sql stable security invoker set search_path='' as $$
  with recent as (
    select place_id,viewed_at from public.place_views
    where user_id=(select auth.uid()) and viewed_at >= now() - interval '24 hours'
    order by viewed_at desc limit 20
  ), saved as (
    select place_id,saved_at from public.saved_places
    where user_id=(select auth.uid()) order by saved_at desc limit 100
  ), mine as (
    select * from public.posts where author_id=(select auth.uid()) and is_public and status='published'
    order by created_at desc,id desc limit 50
  ), cards as (
    select p.id,jsonb_build_object(
      'provider',p.external_provider,'internalId',p.id,'externalPlaceId',p.external_place_id,
      'name',p.name_ko,'category',p.category,'address',p.address_ko,
      'latitude',p.latitude,'longitude',p.longitude,
      'sourceUri','https://www.google.com/maps/search/?api=1&query=' || p.latitude || ',' || p.longitude,
      'heroImageUrl',p.hero_image_url,'pindPhotoPath',photo.photo_path,'pindPhotoBucket',photo.bucket) as j
    from public.places p
    left join lateral (
      select post.photo_path,
        case when post.client_request_id is null then 'post-media' else 'post-media-v2' end as bucket
      from public.posts post
      where post.place_id=p.id and post.is_public and post.status='published' order by post.created_at desc,post.id desc limit 1
    ) photo on true
    where p.id in (select place_id from recent union select place_id from saved union select place_id from mine)
  )
  select jsonb_build_object(
    'profile',(select jsonb_build_object('id',id,'handle',handle,'displayName',display_name,
      'avatarUrl',avatar_url,'bio',bio) from public.profiles where id=(select auth.uid())),
    'counts',jsonb_build_object(
      'friends',(select count(*) from public.friendships where status='accepted'
        and (requester_id=(select auth.uid()) or addressee_id=(select auth.uid()))),
      'posts',(select count(*) from public.posts where author_id=(select auth.uid())
        and is_public and status='published'),
      'saved',(select count(*) from public.saved_places where user_id=(select auth.uid()))),
    'recentViews',coalesce((select jsonb_agg(c.j order by r.viewed_at desc)
      from recent r join cards c on c.id=r.place_id),'[]'::jsonb),
    'savedPlaces',coalesce((select jsonb_agg(c.j || jsonb_build_object('averages',coalesce((
        select jsonb_object_agg(criterion,value) from (select criterion,avg(rating) as value
          from public.place_ratings where place_id=s.place_id and is_public group by criterion) a),'{}'::jsonb))
      order by s.saved_at desc) from saved s join cards c on c.id=s.place_id),'[]'::jsonb),
    'posts',coalesce((select jsonb_agg(jsonb_build_object(
      'id',post.id,'place',c.j,'body',post.body,
      'ratings',coalesce(post.ratings,jsonb_strip_nulls(jsonb_build_object('taste',post.taste_score,
        'portion',post.portion_score,'ambience',post.ambience_score))),
      'bucket',case when post.client_request_id is null then 'post-media' else 'post-media-v2' end,
      'photos',coalesce((select jsonb_agg(media.path order by media.position) from public.post_media media
        where media.post_id=post.id),jsonb_build_array(post.photo_path)),
      'createdAt',post.created_at
    ) order by post.created_at desc,post.id desc) from mine post join cards c on c.id=post.place_id),'[]'::jsonb)
  ) where (select auth.uid()) is not null;
$$;
revoke all on function public.get_my_profile_overview() from public,anon;
grant execute on function public.get_my_profile_overview() to authenticated;


notify pgrst, 'reload schema';
