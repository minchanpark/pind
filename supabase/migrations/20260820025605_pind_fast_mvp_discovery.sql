
create table public.taste_tags (
  code text primary key,
  axis text not null check (axis in ('taste', 'texture', 'vibe', 'for')),
  label_en text not null,
  label_ko text not null,
  emoji text not null,
  sort_order smallint not null check (sort_order >= 0),
  created_at timestamptz not null default now()
);

create table public.places (
  id bigint generated always as identity primary key,
  slug text not null unique,
  external_provider text not null,
  external_place_id text,
  name_en text not null,
  name_ko text not null,
  category text not null,
  address_en text not null,
  address_ko text not null,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  hero_image_url text not null,
  short_description_en text not null,
  short_description_ko text not null,
  is_demo boolean not null default true,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique nulls not distinct (external_provider, external_place_id)
);

create table public.place_taste_tags (
  place_id bigint not null references public.places(id) on delete cascade,
  taste_tag_code text not null references public.taste_tags(code) on delete restrict,
  strength smallint not null check (strength between 1 and 5),
  created_at timestamptz not null default now(),
  primary key (place_id, taste_tag_code)
);

create index places_published_coordinates_idx
  on public.places (is_published, latitude, longitude);
create index place_taste_tags_taste_tag_code_idx
  on public.place_taste_tags (taste_tag_code);

alter table public.taste_tags enable row level security;
alter table public.places enable row level security;
alter table public.place_taste_tags enable row level security;

grant select on public.taste_tags, public.places, public.place_taste_tags to anon, authenticated;

create policy taste_tags_public_read
  on public.taste_tags for select to anon, authenticated using (true);
create policy places_public_read
  on public.places for select to anon, authenticated using (is_published = true);
create policy place_taste_tags_public_read
  on public.place_taste_tags
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.places
      where places.id = place_taste_tags.place_id
        and places.is_published = true
    )
  );

insert into public.taste_tags (code, axis, label_en, label_ko, emoji, sort_order)
values
  ('spicy', 'taste', 'Spicy', '매콤', '🌶️', 10),
  ('sweet', 'taste', 'Sweet', '달콤', '🍯', 20),
  ('savory', 'taste', 'Savory', '짭짤', '🧂', 30),
  ('light', 'taste', 'Light', '담백', '🍃', 40),
  ('crispy', 'texture', 'Crispy', '바삭', '✨', 10),
  ('chewy', 'texture', 'Chewy', '쫄깃', '🥯', 20),
  ('soft', 'texture', 'Soft', '부드러운', '☁️', 30),
  ('creamy', 'texture', 'Creamy', '꾸덕', '🥛', 40),
  ('solo', 'vibe', 'Solo-friendly', '혼자가기 좋은', '🎧', 10),
  ('social', 'vibe', 'Good with friends', '친구와 가기 좋은', '🫶', 20),
  ('quiet', 'vibe', 'Quiet', '조용', '🌙', 30),
  ('local', 'vibe', 'Local mood', '현지 분위기', '🏘️', 40),
  ('korean_first', 'for', 'First Korean meal', '한식 처음 먹는 사람', '🇰🇷', 10),
  ('spice_lover', 'for', 'Spice lovers', '매운 음식 좋아하는 사람', '🔥', 20),
  ('budget', 'for', 'Good value', '저렴한 식사 선호인', '🪙', 30),
  ('date', 'for', 'A casual date', '가벼운 데이트', '💌', 40);

insert into public.places (
  slug, external_provider, external_place_id, name_en, name_ko, category,
  address_en, address_ko, latitude, longitude, hero_image_url,
  short_description_en, short_description_ko, is_demo, is_published
)
values
  ('seoul-table-jongno', 'pind_demo', 'seoul-table-jongno', 'Seoul Table Jongno', '서울 테이블 종로', 'Korean',
   'Jongno-gu, Seoul', '서울 종로구', 37.5725, 126.9850,
   'https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=900&q=80',
   'A friendly first stop for balanced Korean comfort food.', '담백한 한식을 편하게 경험하는 데모 장소입니다.', true, true),
  ('dough-hanok-anguk', 'pind_demo', 'dough-hanok-anguk', 'Dough & Hanok', '도우 앤 한옥', 'Bakery',
   'Anguk, Jongno-gu, Seoul', '서울 종로구 안국동', 37.5796, 126.9865,
   'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=900&q=80',
   'Chewy bread and a calm hanok courtyard.', '쫄깃한 빵과 조용한 한옥 분위기의 데모 장소입니다.', true, true),
  ('mapo-fire-bowl', 'pind_demo', 'mapo-fire-bowl', 'Mapo Fire Bowl', '마포 파이어 볼', 'Korean',
   'Mapo-gu, Seoul', '서울 마포구', 37.5525, 126.9234,
   'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=900&q=80',
   'Bold, spicy bowls made for sharing.', '친구와 함께 즐기는 매콤한 한 그릇 데모 장소입니다.', true, true),
  ('ikseon-sweet-lab', 'pind_demo', 'ikseon-sweet-lab', 'Ikseon Sweet Lab', '익선 스위트 랩', 'Dessert',
   'Ikseon-dong, Jongno-gu, Seoul', '서울 종로구 익선동', 37.5743, 126.9897,
   'https://images.unsplash.com/photo-1551024506-0bccd828d307?auto=format&fit=crop&w=900&q=80',
   'Playful sweets in a lively alley.', '활기찬 골목에서 달콤한 디저트를 즐기는 데모 장소입니다.', true, true),
  ('namsan-noodle-room', 'pind_demo', 'namsan-noodle-room', 'Namsan Noodle Room', '남산 누들 룸', 'Noodles',
   'Jung-gu, Seoul', '서울 중구', 37.5580, 126.9860,
   'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=900&q=80',
   'Soft noodles with a light, savory broth.', '부드러운 면과 담백한 국물을 내는 데모 장소입니다.', true, true),
  ('seongsu-crunch-club', 'pind_demo', 'seongsu-crunch-club', 'Seongsu Crunch Club', '성수 크런치 클럽', 'Snack',
   'Seongsu-dong, Seongdong-gu, Seoul', '서울 성동구 성수동', 37.5445, 127.0560,
   'https://images.unsplash.com/photo-1562967914-608f82629710?auto=format&fit=crop&w=900&q=80',
   'Crispy Korean bites with an energetic crowd.', '바삭한 한국식 스낵을 즐기는 활기찬 데모 장소입니다.', true, true),
  ('quiet-cup-yeonnam', 'pind_demo', 'quiet-cup-yeonnam', 'Quiet Cup Yeonnam', '콰이어트 컵 연남', 'Cafe',
   'Yeonnam-dong, Mapo-gu, Seoul', '서울 마포구 연남동', 37.5627, 126.9252,
   'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?auto=format&fit=crop&w=900&q=80',
   'A calm solo coffee break with creamy desserts.', '혼자 쉬기 좋은 조용한 카페 데모 장소입니다.', true, true),
  ('seoul-green-table', 'pind_demo', 'seoul-green-table', 'Seoul Green Table', '서울 그린 테이블', 'Plant-based',
   'Itaewon, Yongsan-gu, Seoul', '서울 용산구 이태원동', 37.5342, 126.9940,
   'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=900&q=80',
   'Fresh, light plates with easy English guidance.', '영어 안내와 담백한 메뉴를 제공하는 데모 장소입니다.', true, true);

insert into public.place_taste_tags (place_id, taste_tag_code, strength)
select p.id, x.tag_code, x.strength
from (
  values
    ('seoul-table-jongno', 'light', 5), ('seoul-table-jongno', 'soft', 4), ('seoul-table-jongno', 'local', 4), ('seoul-table-jongno', 'korean_first', 5),
    ('dough-hanok-anguk', 'sweet', 4), ('dough-hanok-anguk', 'chewy', 5), ('dough-hanok-anguk', 'quiet', 5), ('dough-hanok-anguk', 'date', 4),
    ('mapo-fire-bowl', 'spicy', 5), ('mapo-fire-bowl', 'chewy', 3), ('mapo-fire-bowl', 'social', 5), ('mapo-fire-bowl', 'spice_lover', 5),
    ('ikseon-sweet-lab', 'sweet', 5), ('ikseon-sweet-lab', 'creamy', 5), ('ikseon-sweet-lab', 'social', 4), ('ikseon-sweet-lab', 'date', 5),
    ('namsan-noodle-room', 'savory', 4), ('namsan-noodle-room', 'soft', 5), ('namsan-noodle-room', 'solo', 4), ('namsan-noodle-room', 'budget', 4),
    ('seongsu-crunch-club', 'savory', 5), ('seongsu-crunch-club', 'crispy', 5), ('seongsu-crunch-club', 'social', 5), ('seongsu-crunch-club', 'budget', 3),
    ('quiet-cup-yeonnam', 'sweet', 4), ('quiet-cup-yeonnam', 'creamy', 4), ('quiet-cup-yeonnam', 'quiet', 5), ('quiet-cup-yeonnam', 'solo', 5),
    ('seoul-green-table', 'light', 5), ('seoul-green-table', 'crispy', 3), ('seoul-green-table', 'solo', 4), ('seoul-green-table', 'korean_first', 4)
) as x(place_slug, tag_code, strength)
join public.places p on p.slug = x.place_slug;
;
