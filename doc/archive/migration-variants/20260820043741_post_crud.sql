create table public.posts (
  id bigint generated always as identity primary key,
  author_id uuid not null references auth.users(id) on delete cascade,
  place_id bigint not null references public.places(id) on delete restrict,
  menu_name text not null check (char_length(menu_name) between 1 and 80),
  photo_path text not null check (char_length(photo_path) between 1 and 512),
  emoji text not null check (char_length(emoji) between 1 and 16),
  body text not null check (char_length(body) between 1 and 2000),
  is_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.post_taste_tags (
  post_id bigint not null references public.posts(id) on delete cascade,
  taste_tag_code text not null references public.taste_tags(code) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (post_id, taste_tag_code)
);

create table public.visits (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  place_id bigint not null references public.places(id) on delete restrict,
  post_id bigint unique references public.posts(id) on delete set null,
  visited_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create index posts_public_created_at_idx
  on public.posts (created_at desc)
  where is_public = true;
create index posts_author_created_at_idx
  on public.posts (author_id, created_at desc);
create index posts_place_created_at_idx
  on public.posts (place_id, created_at desc);
create index post_taste_tags_taste_tag_code_idx
  on public.post_taste_tags (taste_tag_code);
create index visits_user_visited_at_idx
  on public.visits (user_id, visited_at desc);
create index visits_place_id_idx
  on public.visits (place_id);

create or replace function public.protect_post_identity_and_touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.id <> old.id or new.author_id <> old.author_id or new.created_at <> old.created_at then
    raise exception 'Post identity fields cannot be changed';
  end if;

  new.updated_at = now();
  return new;
end;
$$;

create trigger protect_post_identity_and_touch_updated_at
before update on public.posts
for each row execute function public.protect_post_identity_and_touch_updated_at();

create or replace function public.record_post_visit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.visits (user_id, place_id, post_id, visited_at)
  values (new.author_id, new.place_id, new.id, new.created_at);
  return new;
end;
$$;

create trigger record_post_visit
after insert on public.posts
for each row execute function public.record_post_visit();

alter table public.posts enable row level security;
alter table public.post_taste_tags enable row level security;
alter table public.visits enable row level security;

grant select on public.posts, public.post_taste_tags to anon, authenticated;
grant insert, update, delete on public.posts to authenticated;
grant insert, delete on public.post_taste_tags to authenticated;
grant select on public.visits to authenticated;
grant usage, select on sequence public.posts_id_seq, public.visits_id_seq to authenticated;

create policy posts_public_or_owner_read
  on public.posts
  for select
  to anon, authenticated
  using (is_public = true or author_id = (select auth.uid()));

create policy posts_owner_insert
  on public.posts
  for insert
  to authenticated
  with check (author_id = (select auth.uid()));

create policy posts_owner_update
  on public.posts
  for update
  to authenticated
  using (author_id = (select auth.uid()))
  with check (author_id = (select auth.uid()));

create policy posts_owner_delete
  on public.posts
  for delete
  to authenticated
  using (author_id = (select auth.uid()));

create policy post_taste_tags_public_or_owner_read
  on public.post_taste_tags
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.posts
      where posts.id = post_taste_tags.post_id
        and (posts.is_public = true or posts.author_id = (select auth.uid()))
    )
  );

create policy post_taste_tags_owner_insert
  on public.post_taste_tags
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.posts
      where posts.id = post_taste_tags.post_id
        and posts.author_id = (select auth.uid())
    )
  );

create policy post_taste_tags_owner_delete
  on public.post_taste_tags
  for delete
  to authenticated
  using (
    exists (
      select 1
      from public.posts
      where posts.id = post_taste_tags.post_id
        and posts.author_id = (select auth.uid())
    )
  );

create policy visits_owner_read
  on public.visits
  for select
  to authenticated
  using (user_id = (select auth.uid()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'post-media',
  'post-media',
  true,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy post_media_owner_insert
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'post-media'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy post_media_owner_read
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'post-media'
    and owner_id = (select auth.uid())::text
  );

create policy post_media_owner_delete
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'post-media'
    and owner_id = (select auth.uid())::text
  );
