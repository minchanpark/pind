import '../l10n/l10n.dart';
import 'preferences.dart';

/// (emoji, prompt) for the search page, row by row; Figma 617:23469's set
/// when there's no taste to go on.
List<(String, String)> get defaultSuggestions => [
  ('🌶️', l10n.suggestSpicyLevels),
  ('🥩', l10n.suggestKoreanBbq),
  ('🇳🇵', l10n.suggestNepali),
  ('🌿', l10n.suggestVegetarian),
  ('🍜', l10n.suggestKoreanVietnamese),
  ('🪑', l10n.suggestSoloDrinks),
  ('🍜', l10n.suggestPho),
  ('📍', l10n.suggestSeongsuBar),
  ('🍚', l10n.suggestHomeStyle),
  ('🔁', l10n.suggestTouristFavorite),
];

const _emoji = <Cuisine, String>{
  Cuisine.korean: '🍚',
  Cuisine.barbecue: '🥩',
  Cuisine.soup: '🍲',
  Cuisine.noodles: '🍜',
  Cuisine.street: '🍢',
  Cuisine.japanese: '🍱',
  Cuisine.sushi: '🍣',
  Cuisine.chinese: '🥟',
  Cuisine.western: '🍝',
  Cuisine.asian: '🍜',
  Cuisine.chicken: '🍗',
  Cuisine.dessert: '🍰',
  Cuisine.bakery: '🥐',
  Cuisine.bar: '🍺',
};

String _noun(Cuisine c) => switch (c) {
  Cuisine.korean => l10n.placeKorean,
  Cuisine.barbecue => l10n.placeBarbecue,
  Cuisine.soup => l10n.placeSoup,
  Cuisine.noodles => l10n.placeNoodles,
  Cuisine.street => l10n.placeStreet,
  Cuisine.japanese => l10n.placeJapanese,
  Cuisine.sushi => l10n.placeSushi,
  Cuisine.chinese => l10n.placeChinese,
  Cuisine.western => l10n.placeWestern,
  Cuisine.asian => l10n.placeAsian,
  Cuisine.chicken => l10n.placeChicken,
  Cuisine.dessert => l10n.placeDessert,
  Cuisine.bakery => l10n.placeBakery,
  Cuisine.bar => l10n.placeBar,
};

String _quality(PreferenceCriterion c) => switch (c) {
  PreferenceCriterion.taste => l10n.qualityTaste,
  PreferenceCriterion.ambience => l10n.qualityAmbience,
  PreferenceCriterion.value => l10n.qualityValue,
  PreferenceCriterion.portion => l10n.qualityPortion,
  PreferenceCriterion.service => l10n.qualityService,
  PreferenceCriterion.photogenic => l10n.qualityPhotogenic,
  PreferenceCriterion.quiet => l10n.qualityQuiet,
  PreferenceCriterion.parking => l10n.qualityParking,
};

/// Emoji, phrase, the cuisines it suits (first one I like wins), and the
/// place to name when I like none of them.
Map<DiningOccasion, (String, String, List<Cuisine>, _Generic)> get _occasion =>
    {
      DiningOccasion.solo: (
        '🪑',
        l10n.occasionPhraseSolo,
        [Cuisine.noodles, Cuisine.soup, Cuisine.korean, Cuisine.street],
        _Generic.restaurant,
      ),
      DiningOccasion.friends: (
        '🧑‍🤝‍🧑',
        l10n.occasionPhraseFriends,
        [Cuisine.barbecue, Cuisine.chicken, Cuisine.bar],
        _Generic.restaurant,
      ),
      DiningOccasion.date: (
        '💑',
        l10n.occasionPhraseDate,
        [Cuisine.western, Cuisine.sushi, Cuisine.japanese, Cuisine.dessert],
        _Generic.dining,
      ),
      DiningOccasion.family: (
        '👨‍👩‍👧',
        l10n.occasionPhraseFamily,
        [Cuisine.korean, Cuisine.barbecue, Cuisine.chinese],
        _Generic.restaurant,
      ),
      DiningOccasion.group: (
        '🍻',
        l10n.occasionPhraseGroup,
        [Cuisine.barbecue, Cuisine.chinese, Cuisine.bar],
        _Generic.restaurant,
      ),
      DiningOccasion.work: (
        '💻',
        l10n.occasionPhraseWork,
        [Cuisine.dessert, Cuisine.bakery],
        _Generic.cafe,
      ),
      DiningOccasion.drinks: (
        '🍺',
        l10n.occasionPhraseDrinks,
        [Cuisine.bar, Cuisine.barbecue, Cuisine.chicken],
        _Generic.bar,
      ),
      DiningOccasion.quick: (
        '⏱️',
        l10n.occasionPhraseQuick,
        [Cuisine.street, Cuisine.noodles, Cuisine.korean],
        _Generic.restaurant,
      ),
    };

enum _Generic { restaurant, dining, cafe, bar }

String _genericNoun(_Generic g) => switch (g) {
  _Generic.restaurant => l10n.genericRestaurant,
  _Generic.dining => l10n.genericDining,
  _Generic.cafe => l10n.genericCafe,
  _Generic.bar => l10n.genericBar,
};

/// Asks the search to pick from my taste alone.
(String, String) get forMeSuggestion => ('✨', l10n.suggestForMe);

/// Ten prompts from my onboarding answers: "pick for me" first, each
/// occasion with a cuisine I like that suits it, then my priorities paired
/// with my cuisines in turn, topped up from [defaultSuggestions]. No
/// cuisines or occasions → defaults.
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
    // English may start with a noun ("noodle places for…"): capitalize it.
    final text = s.$2.isEmpty
        ? s.$2
        : s.$2[0].toUpperCase() + s.$2.substring(1);
    if (out.length < count && !out.any((o) => o.$2 == text)) {
      out.add((s.$1, text));
    }
  }

  add(forMeSuggestion);
  for (final o in DiningOccasion.values.where(taste.occasions.contains)) {
    final (emoji, phrase, suits, fallback) = _occasion[o]!;
    final cuisine = suits.where(cuisines.contains).firstOrNull;
    add(
      cuisine == null
          ? (emoji, l10n.suggestOccasion(phrase, _genericNoun(fallback)))
          : (_emoji[cuisine]!, l10n.suggestOccasion(phrase, _noun(cuisine))),
    );
  }
  // Priority i with cuisine i, i+1, …: each row a different pair.
  final priorities = taste.priorities.isEmpty
      ? const [PreferenceCriterion.taste]
      : taste.priorities;
  for (var round = 0; round < cuisines.length; round++) {
    for (var p = 0; p < priorities.length; p++) {
      final cuisine = cuisines[(p + round) % cuisines.length];
      add((
        _emoji[cuisine]!,
        l10n.suggestQuality(_quality(priorities[p]), _noun(cuisine)),
      ));
    }
  }
  for (final s in defaultSuggestions) {
    add(s);
  }
  return out;
}
