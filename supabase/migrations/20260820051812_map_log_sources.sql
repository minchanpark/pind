create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  avatar_url text,
  is_demo boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.friendships (
  id bigint generated always as identity primary key,
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'declined', 'removed')),
  requested_at timestamptz not null default now(),
  accepted_at timestamptz,
  check (requester_id <> addressee_id),
  check ((status = 'accepted' and accepted_at is not null) or (status <> 'accepted'))
);

create unique index friendships_pair_unique_idx
  on public.friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));
create index friendships_requester_status_idx
  on public.friendships (requester_id, status);
create index friendships_addressee_status_idx
  on public.friendships (addressee_id, status);

create table public.editorial_logs (
  id bigint generated always as identity primary key,
  place_id bigint not null references public.places(id) on delete cascade,
  author_name text not null default 'Pind Seoul',
  menu_name text not null check (char_length(menu_name) between 1 and 80),
  photo_url text not null,
  emoji text not null check (char_length(emoji) between 1 and 16),
  body text not null check (char_length(body) between 1 and 2000),
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.editorial_log_taste_tags (
  editorial_log_id bigint not null references public.editorial_logs(id) on delete cascade,
  taste_tag_code text not null references public.taste_tags(code) on delete restrict,
  primary key (editorial_log_id, taste_tag_code)
);

create index editorial_logs_place_created_at_idx
  on public.editorial_logs (place_id, created_at desc);
create index editorial_logs_published_created_at_idx
  on public.editorial_logs (created_at desc)
  where is_published = true;
create index editorial_log_taste_tags_code_idx
  on public.editorial_log_taste_tags (taste_tag_code);

create or replace function private.create_profile_for_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, 'Pind visitor')
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function private.create_profile_for_new_user() from public, anon, authenticated;

create trigger create_profile_after_auth_user
after insert on auth.users
for each row execute function private.create_profile_for_new_user();

insert into public.profiles (id, display_name)
select id, 'Pind visitor'
from auth.users
on conflict (id) do nothing;

alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.editorial_logs enable row level security;
alter table public.editorial_log_taste_tags enable row level security;

grant select on public.profiles to anon, authenticated;
grant update (display_name, avatar_url) on public.profiles to authenticated;
grant select on public.friendships to authenticated;
grant select on public.editorial_logs, public.editorial_log_taste_tags to anon, authenticated;

create policy profiles_public_read
  on public.profiles
  for select
  to anon, authenticated
  using (true);

create policy profiles_owner_update
  on public.profiles
  for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy friendships_participant_read
  on public.friendships
  for select
  to authenticated
  using (
    requester_id = (select auth.uid())
    or addressee_id = (select auth.uid())
  );

create policy editorial_logs_public_read
  on public.editorial_logs
  for select
  to anon, authenticated
  using (is_published = true);

create policy editorial_log_taste_tags_public_read
  on public.editorial_log_taste_tags
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.editorial_logs
      where editorial_logs.id = editorial_log_taste_tags.editorial_log_id
        and editorial_logs.is_published = true
    )
  );

insert into public.editorial_logs (
  place_id, menu_name, photo_url, emoji, body, is_published, created_at
)
select
  places.id,
  seed.menu_name,
  places.hero_image_url,
  seed.emoji,
  seed.body,
  true,
  seed.created_at
from (
  values
    ('seoul-table-jongno', 'First-timer comfort set', '😌', 'A calm introduction to Korean comfort food with balanced flavors.', now() - interval '8 days'),
    ('dough-hanok-anguk', 'Black sesame cream bun', '🥹', 'Chewy bread, nutty cream, and a quiet hanok pause.', now() - interval '7 days'),
    ('mapo-fire-bowl', 'Fire pork rice bowl', '🔥', 'Bold heat and smoky edges made for sharing with a hungry table.', now() - interval '6 days'),
    ('ikseon-sweet-lab', 'Cloud cream doughnut', '✨', 'Sweet, creamy, and playful enough to turn an alley walk into dessert time.', now() - interval '5 days'),
    ('namsan-noodle-room', 'Light broth noodles', '😌', 'Soft noodles in a savory broth that feels easy after a long walk.', now() - interval '4 days'),
    ('seongsu-crunch-club', 'Crispy street bites', '🤤', 'A loud crunch with salty seasoning and an energetic Seongsu mood.', now() - interval '3 days'),
    ('quiet-cup-yeonnam', 'Cream cake and coffee', '💜', 'A creamy solo break in a calm corner of Yeonnam.', now() - interval '2 days'),
    ('seoul-green-table', 'Seasonal green plate', '🍃', 'Fresh vegetables and gentle seasoning with easy English guidance.', now() - interval '1 day')
) as seed(place_slug, menu_name, emoji, body, created_at)
join public.places on places.slug = seed.place_slug;

insert into public.editorial_log_taste_tags (editorial_log_id, taste_tag_code)
select editorial_logs.id, seed.taste_tag_code
from (
  values
    ('First-timer comfort set', 'light'),
    ('First-timer comfort set', 'korean_first'),
    ('Black sesame cream bun', 'sweet'),
    ('Black sesame cream bun', 'chewy'),
    ('Fire pork rice bowl', 'spicy'),
    ('Fire pork rice bowl', 'social'),
    ('Cloud cream doughnut', 'sweet'),
    ('Cloud cream doughnut', 'creamy'),
    ('Light broth noodles', 'savory'),
    ('Light broth noodles', 'soft'),
    ('Crispy street bites', 'crispy'),
    ('Crispy street bites', 'social'),
    ('Cream cake and coffee', 'creamy'),
    ('Cream cake and coffee', 'solo'),
    ('Seasonal green plate', 'light'),
    ('Seasonal green plate', 'korean_first')
) as seed(menu_name, taste_tag_code)
join public.editorial_logs on editorial_logs.menu_name = seed.menu_name;;
