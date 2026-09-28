-- Web-verified first batch near Pohang City Hall (36.019, 129.343).
-- Each source was opened and checked against the same branch/address and the
-- factual menu or brand claim. Paraphrases are original; prices/hours omitted.
-- Idempotent: only updates SBIZ rows whose two descriptions are still NULL.
-- Sources are retained here for editorial review, not copied into source_url
-- (which tracks the public-data origin of the place itself).
with incoming(id, address_ko, description_ko, description_en, evidence_url) as (
  values
    (148127, '경상북도 포항시 남구 시청로 1',
     '포항시청 2층에 있는 히즈빈스 카페로, 장애인 바리스타의 일자리를 만드는 브랜드의 직영점입니다.',
     'This Hisbeans cafe on the second floor of Pohang City Hall is part of a brand that creates jobs for baristas with disabilities.',
     'https://www.hisbeans.com/blogPost/newsletter2026March'),
    (152294, '경상북도 포항시 남구 대이로 39',
     '포항시청 앞에서 마제소바, 돈카츠, 소바를 내는 일식당입니다.',
     'This Japanese-style restaurant near Pohang City Hall serves mazesoba, tonkatsu, and soba.',
     'https://www.diningcode.com/profile.php?rid=0wRyP2A2dJzV'),
    (151510, '경상북도 포항시 남구 대이로 39',
     '포항시청 앞 푸라닭 매장으로 블랙투움바와 블랙마불로 등 치킨 메뉴를 선보입니다.',
     'This Puradak branch near Pohang City Hall serves chicken dishes such as Black Toowoomba and Black Mabulo.',
     'https://www.diningcode.com/profile.php?rid=vvODjjFdZX9Z'),
    (153923, '경상북도 포항시 남구 대이로 25',
     '김치찌개정식과 뚝배기 제육정식 등을 내는 한식당입니다.',
     'This Korean restaurant serves set meals such as kimchi stew and sizzling spicy pork.',
     'https://www.diningcode.com/profile.php?rid=HX6oNII1tGy6'),
    (151752, '경상북도 포항시 북구 새천년대로 486',
     '포항죽도DT점은 드라이브스루를 이용할 수 있는 스타벅스 커피 매장입니다.',
     'Starbucks Pohang Jukdo DT is a drive-through coffee shop on Saecheonnyeon-daero.',
     'https://www.tabling.co.kr/place/677cd0b566de5f0698869291'),
    (149568, '경상북도 포항시 북구 상대로 10-1',
     '전주식 콩나물국밥과 전통비빔밥을 내는 포항의 한식당입니다.',
     'This Pohang restaurant serves Jeonju-style bean sprout soup and bibimbap.',
     'https://www.siksinhot.com/P/391748'),
    (152242, '경상북도 포항시 북구 양학로17번길 32-1',
     '포항 철길숲 인근에서 모듬전 등 전 요리를 내는 전집입니다.',
     'Near Pohang Cheolgil Forest, this spot serves assorted jeon, Korean savory pancakes.',
     'https://www.diningcode.com/profile.php?rid=V2MVBFo36xfO'),
    (150915, '경상북도 포항시 북구 상대로 31',
     '순두부 돌솥밥을 비롯한 순두부 요리를 내는 포항 죽도동의 한식당입니다.',
     'This Jukdo-dong restaurant serves soft tofu dishes with stone-pot rice.',
     'https://www.diningcode.com/profile.php?rid=aQDfyEbo9aUc'),
    (146472, '경상북도 포항시 북구 양학로9번길 26',
     '포항 철길숲 인근에서 초밥과 점심 특선 세트를 내는 식당입니다.',
     'Near Pohang Cheolgil Forest, this sushi restaurant offers lunch sets.',
     'https://www.diningcode.com/profile.php?rid=J7iABx7gkAuK'),
    (151949, '경상북도 포항시 북구 중흥로113번길 12',
     '죽도동에서 커피와 푸딩, 스콘 등의 디저트를 내는 카페입니다.',
     'Greenus in Jukdo-dong serves coffee and desserts such as pudding and scones.',
     'https://www.diningcode.com/profile.php?rid=BHLP5fmDPSom'),
    (148583, '경상북도 포항시 북구 새천년대로 526',
     '포항남부DT점에서 샌드위치와 샐러드를 골라 주문할 수 있습니다.',
     'The Pohang Nambu DT branch offers a choice of sandwiches and salads.',
     'https://www.diningcode.com/profile.php?rid=9FxMHEdzmYSr')
), eligible as (
  select p.id
  from public.places p
  join incoming i on i.id = p.id and i.address_ko = p.address_ko
  where p.external_provider = 'sbiz'
    and p.is_published and not p.is_demo and not p.is_reference_only
    and p.short_description_ko is null and p.short_description_en is null
), updated as (
  update public.places p
  set short_description_ko = i.description_ko,
      short_description_en = i.description_en,
      updated_at = now()
  from incoming i
  where p.id = i.id
    and p.id in (select id from eligible)
    and (select count(*) from eligible) = (select count(*) from incoming)
  returning p.id
)
select count(*) as updated_count, array_agg(id order by id) as updated_ids from updated;
