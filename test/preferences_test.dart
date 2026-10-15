import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/place_context.dart';
import 'package:pind_flutter/model/taste_profile.dart';

void main() {
  final p = TastePreferences(
    priorities: [
      PreferenceCriterion.taste,
      PreferenceCriterion.portion,
      PreferenceCriterion.ambience,
    ],
    cuisines: [Cuisine.korean, Cuisine.soup, Cuisine.noodles],
  );
  test('three ordered priorities cap, remove and compact', () {
    expect(
      p.togglePriority(PreferenceCriterion.value).priorities,
      p.priorities,
    );
    expect(
      p
          .togglePriority(PreferenceCriterion.taste)
          .togglePriority(PreferenceCriterion.value)
          .priorities,
      [
        PreferenceCriterion.portion,
        PreferenceCriterion.ambience,
        PreferenceCriterion.value,
      ],
    );
    expect(p.isComplete, true);
    expect(p.togglePriority(PreferenceCriterion.taste).isComplete, false);
  });
  test('occasions cap at three; cuisines require three', () {
    var next = p;
    for (final o in DiningOccasion.values) {
      next = next.toggleOccasion(o);
    }
    expect(next.occasions.length, 3);
    expect(p.toggleCuisine(Cuisine.korean).isComplete, false);
  });
  // Golden numbers shared with supabase/tests/follows_taste.sql. Start
  // state: priorities 맛·양·분위기, Pind averages 4.3·4.0·3.9.
  const start = TasteProfile(
    priorities: [
      PreferenceCriterion.taste,
      PreferenceCriterion.portion,
      PreferenceCriterion.ambience,
    ],
    stars: {
      PreferenceCriterion.taste: 5,
      PreferenceCriterion.portion: 4.2,
      PreferenceCriterion.ambience: 3.8,
      PreferenceCriterion.value: 3,
    },
    weights: {
      PreferenceCriterion.taste: 50,
      PreferenceCriterion.portion: 30,
      PreferenceCriterion.ambience: 20,
      PreferenceCriterion.value: 0,
    },
    averages: {
      PreferenceCriterion.taste: 4.3,
      PreferenceCriterion.portion: 4.0,
      PreferenceCriterion.ambience: 3.9,
    },
  );
  int? place(TasteProfile taste, double t, double p, [double? a]) =>
      taste.match({
        PreferenceCriterion.taste: t,
        PreferenceCriterion.portion: p,
        PreferenceCriterion.ambience: ?a,
      });

  test('ratings read relative to the Pind average', () {
    expect(relativeStar(4.3, 4.3), 3);
    expect(relativeStar(5, 4.3), 5);
    expect(relativeStar(1, 4.3), 1);
    expect(relativeStar(4.7, 4.3), closeTo(4.14, .005));
    expect(relativeStar(4, 4.3), closeTo(2.82, .005));
    expect(relativeStar(4, null), 3);
  });
  test('place % only counts shortfalls, weighted by my stars', () {
    expect(place(start, 5, 5, 5), 100);
    expect(place(start, 4.8, 4.0, 3.9), 76);
    expect(place(start, 4, 4, 4), 57);
    expect(place(start, 4, 3, 2), 40);
    expect(place(start, 5, 5), null, reason: 'unrated 20% stays unknown');
    expect(() => place(start, double.nan, 3, 2), throwsFormatException);
    expect(() => place(start, 0, 3, 2), throwsFormatException);
    expect(() => place(start, 6, 3, 2), throwsFormatException);
    final moved = TasteProfile.fromJson({
      'priorities': ['taste', 'value', 'ambience'],
      'stars': {'taste': 5, 'value': 4, 'ambience': 3.9091, 'quiet': 3.1818},
      'weights': {
        'taste': 48.8889,
        'value': 24.4444,
        'ambience': 22.2222,
        'quiet': 4.4444,
        'parking': 0,
        'unknown': 9,
      },
      'averages': {'taste': 4, 'value': 3, 'ambience': 4, 'quiet': 3},
      'evidence': 2,
    });
    expect(
      moved.match({
        PreferenceCriterion.taste: 5,
        PreferenceCriterion.value: 5,
        PreferenceCriterion.ambience: 5,
      }),
      100,
      reason: 'unrated under 20% is left out',
    );
    expect(
      [for (final e in moved.ranked) e.key],
      [
        PreferenceCriterion.taste,
        PreferenceCriterion.value,
        PreferenceCriterion.ambience,
        PreferenceCriterion.quiet,
      ],
    );
    expect(moved.evidence, 2);
  });
  test('tasteMatch waits for my taste for these priorities', () {
    const averages = PlaceContext(
      averages: {
        PreferenceCriterion.taste: 4,
        PreferenceCriterion.portion: 3,
        PreferenceCriterion.ambience: 2,
      },
    );
    addTearDown(() => myTaste.value = null);
    myTaste.value = null;
    expect(tasteMatch(p, averages), null);
    myTaste.value = start;
    expect(tasteMatch(p, averages), 40);
    expect(tasteMatch(null, averages), null);
    final reordered = TastePreferences(
      priorities: [
        PreferenceCriterion.portion,
        PreferenceCriterion.taste,
        PreferenceCriterion.ambience,
      ],
    );
    expect(tasteMatch(reordered, averages), null, reason: 'stale profile');
  });
  test(
    'device draft persists; v1 retains choices but needs third selection',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await SharedPreferences.getInstance();
      final store = PreferenceService(storage);
      await store.save(p);
      expect(store.load()!.toJson(), p.toJson());
      final legacy = TastePreferences.fromJson({
        ...p.toJson(),
        'version': 1,
        'priorities': ['taste', 'portion'],
      });
      expect(legacy.priorities.length, 2);
      expect(legacy.isComplete, false);
      await storage.setString(PreferenceService.key, '{broken');
      expect(store.load(), null);
      await storage.setString(PreferenceService.key, '{"version":42}');
      expect(store.load(), null);
    },
  );
}
