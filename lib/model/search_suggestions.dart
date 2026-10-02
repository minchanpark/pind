import 'preferences.dart';

/// (emoji, prompt) for the search page, row by row; Figma 617:23469's set
/// when there's no taste to go on.
const defaultSuggestions = [
  ('🌶️', '매움 단계를 선택할 수 있는 식당'),
  ('🥩', '한국 BBQ를 즐기면서 분위기 좋은 고깃집'),
  ('🇳🇵', '네팔 사람들이 많이 방문한 식당'),
  ('🌿', 'Vegetarian 음식'),
  ('🍜', '한국식 베트남 음식'),
  ('🪑', '혼술 하기 좋은 식당'),
  ('🍜', '느낌 좋은 쌀국수집'),
  ('📍', '서울 성수동에 분위기 좋은 바'),
  ('🍚', '한국 집밥 느낌의 식당'),
  ('🔁', '관광객들이 가장 많이 방문한 식당'),
];

const _place = <Cuisine, (String, String)>{
  Cuisine.korean: ('🍚', '백반집'),
  Cuisine.barbecue: ('🥩', '고깃집'),
  Cuisine.soup: ('🍲', '국밥집'),
  Cuisine.noodles: ('🍜', '국수집'),
  Cuisine.street: ('🍢', '분식집'),
  Cuisine.japanese: ('🍱', '일식집'),
  Cuisine.sushi: ('🍣', '초밥집'),
  Cuisine.chinese: ('🥟', '중국집'),
  Cuisine.western: ('🍝', '파스타집'),
  Cuisine.asian: ('🍜', '쌀국수집'),
  Cuisine.chicken: ('🍗', '치킨집'),
  Cuisine.dessert: ('🍰', '디저트 카페'),
  Cuisine.bakery: ('🥐', '빵집'),
  Cuisine.bar: ('🍺', '술집'),
};

const _quality = <PreferenceCriterion, String>{
  PreferenceCriterion.taste: '맛있는',
  PreferenceCriterion.ambience: '분위기 좋은',
  PreferenceCriterion.value: '가성비 좋은',
  PreferenceCriterion.portion: '양 많은',
  PreferenceCriterion.service: '깔끔하고 친절한',
  PreferenceCriterion.photogenic: '사진 잘 나오는',
  PreferenceCriterion.quiet: '조용한',
  PreferenceCriterion.parking: '주차 편한',
};

/// Phrase, emoji, the cuisines it suits (first one I like wins), and the
/// place to name when I like none of them.
const _occasion = <DiningOccasion, (String, String, List<Cuisine>, String)>{
  DiningOccasion.solo: (
    '🪑',
    '혼밥하기 좋은',
    [Cuisine.noodles, Cuisine.soup, Cuisine.korean, Cuisine.street],
    '식당',
  ),
  DiningOccasion.friends: (
    '🧑‍🤝‍🧑',
    '친구들이랑 가기 좋은',
    [Cuisine.barbecue, Cuisine.chicken, Cuisine.bar],
    '식당',
  ),
  DiningOccasion.date: (
    '💑',
    '데이트하기 좋은',
    [Cuisine.western, Cuisine.sushi, Cuisine.japanese, Cuisine.dessert],
    '레스토랑',
  ),
  DiningOccasion.family: (
    '👨‍👩‍👧',
    '가족이랑 가기 좋은',
    [Cuisine.korean, Cuisine.barbecue, Cuisine.chinese],
    '식당',
  ),
  DiningOccasion.group: (
    '🍻',
    '회식하기 좋은',
    [Cuisine.barbecue, Cuisine.chinese, Cuisine.bar],
    '식당',
  ),
  DiningOccasion.work: (
    '💻',
    '카공하기 좋은',
    [Cuisine.dessert, Cuisine.bakery],
    '카페',
  ),
  DiningOccasion.drinks: (
    '🍺',
    '한잔하기 좋은',
    [Cuisine.bar, Cuisine.barbecue, Cuisine.chicken],
    '술집',
  ),
  DiningOccasion.quick: (
    '⏱️',
    '빨리 먹을 수 있는',
    [Cuisine.street, Cuisine.noodles, Cuisine.korean],
    '식당',
  ),
};

/// Ten prompts from my onboarding answers: each occasion with a cuisine I
/// like that suits it, then my priorities paired with my cuisines in turn,
/// topped up from [defaultSuggestions]. No cuisines or occasions → defaults.
List<(String, String)> suggestionsFor(
  TastePreferences? taste, {
  int count = 10,
}) {
  if (taste == null || (taste.cuisines.isEmpty && taste.occasions.isEmpty)) {
    return defaultSuggestions.take(count).toList();
  }
  // Enum order, so the same answers always read the same.
  final cuisines = Cuisine.values.where(taste.cuisines.contains).toList();
  final out = <(String, String)>[];
  void add((String, String) s) {
    if (out.length < count && !out.any((o) => o.$2 == s.$2)) out.add(s);
  }

  for (final o in DiningOccasion.values.where(taste.occasions.contains)) {
    final (emoji, phrase, suits, fallback) = _occasion[o]!;
    final cuisine = suits.where(cuisines.contains).firstOrNull;
    add(
      cuisine == null
          ? (emoji, '$phrase $fallback')
          : (_place[cuisine]!.$1, '$phrase ${_place[cuisine]!.$2}'),
    );
  }
  // Priority i with cuisine i, i+1, …: each row a different pair.
  final priorities = taste.priorities.isEmpty
      ? const [PreferenceCriterion.taste]
      : taste.priorities;
  for (var round = 0; round < cuisines.length; round++) {
    for (var p = 0; p < priorities.length; p++) {
      final (emoji, noun) = _place[cuisines[(p + round) % cuisines.length]]!;
      add((emoji, '${_quality[priorities[p]]} $noun'));
    }
  }
  for (final s in defaultSuggestions) {
    add(s);
  }
  return out;
}
