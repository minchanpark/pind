-- AI place summaries are written in Korean; other app languages read a
-- translation made on first view and kept until the place gets new posts
-- (post_count changes). Only the places function (service role) touches it.
create table public.place_insight_translations (
  place_id bigint not null references public.places(id) on delete cascade,
  lang text not null check (lang in ('en','ja','zh-Hans','zh-Hant')),
  post_count integer not null,
  summary text not null default '',
  criteria jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (place_id, lang)
);
alter table public.place_insight_translations enable row level security;
revoke all on public.place_insight_translations from public, anon, authenticated;
