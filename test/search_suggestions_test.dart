import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/search_suggestions.dart';

void main() {
  test('no taste yet: the design set', () {
    expect(suggestionsFor(null), defaultSuggestions);
    expect(suggestionsFor(TastePreferences()), defaultSuggestions);
    // Priorities alone say nothing about what to eat.
    expect(
      suggestionsFor(
        TastePreferences(priorities: [PreferenceCriterion.ambience]),
      ),
      defaultSuggestions,
    );
  });

  test('occasions first, each with a cuisine I like that suits it', () {
    final s = suggestionsFor(
      TastePreferences(
        priorities: [
          PreferenceCriterion.ambience,
          PreferenceCriterion.value,
          PreferenceCriterion.photogenic,
        ],
        occasions: [DiningOccasion.work, DiningOccasion.date],
        cuisines: [Cuisine.dessert, Cuisine.western, Cuisine.barbecue],
      ),
    );
    expect(s.map((e) => e.$2), [
      // Enum order: date before work.
      '데이트하기 좋은 파스타집',
      '카공하기 좋은 디저트 카페',
      // Priority i with cuisine i, then shifted by one each round.
      '분위기 좋은 고깃집',
      '가성비 좋은 파스타집',
      '사진 잘 나오는 디저트 카페',
      '분위기 좋은 파스타집',
      '가성비 좋은 디저트 카페',
      '사진 잘 나오는 고깃집',
      '분위기 좋은 디저트 카페',
      '가성비 좋은 고깃집',
    ]);
    expect(s.first.$1, '🍝');
  });

  test('an occasion with no matching cuisine names a plain place', () {
    final s = suggestionsFor(
      TastePreferences(
        occasions: [DiningOccasion.work, DiningOccasion.drinks],
        cuisines: [Cuisine.korean],
      ),
    );
    expect(s.take(3).map((e) => e.$2), [
      '카공하기 좋은 카페',
      '한잔하기 좋은 술집',
      '맛있는 백반집',
    ]);
    // Few pairs: topped up from the design set, ten in all, no repeats.
    expect(s, hasLength(10));
    expect(s.map((e) => e.$2).toSet(), hasLength(10));
    expect(s.last, defaultSuggestions[6]);
  });

  test('every cuisine and occasion has words', () {
    for (final c in Cuisine.values) {
      final s = suggestionsFor(TastePreferences(cuisines: [c]));
      expect(s.first.$2, isNot(contains('null')), reason: c.name);
    }
    for (final o in DiningOccasion.values) {
      final s = suggestionsFor(TastePreferences(occasions: [o]));
      expect(s.first.$2, isNot(contains('null')), reason: o.name);
    }
  });
}
