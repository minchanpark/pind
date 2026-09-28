import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/place_context.dart';

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
  test('50/30/20 score and equal personal/aggregate blend', () {
    const average = {
      PreferenceCriterion.taste: 5.0,
      PreferenceCriterion.portion: 4.0,
      PreferenceCriterion.ambience: 5.0,
    };
    expect(tasteMatch(p, const PlaceContext(averages: average)), 94);
    expect(
      tasteMatch(
        p,
        const PlaceContext(
          averages: average,
          mine: {PreferenceCriterion.taste: 1},
        ),
      ),
      74,
    );
    final reordered = TastePreferences(
      priorities: [
        PreferenceCriterion.portion,
        PreferenceCriterion.taste,
        PreferenceCriterion.ambience,
      ],
    );
    expect(tasteMatch(reordered, const PlaceContext(averages: average)), 90);
  });
  test(
    'missing one chosen axis remains unknown, personal cannot invent aggregate',
    () {
      expect(tasteMatch(p, const PlaceContext()), null);
      expect(
        tasteMatch(
          p,
          const PlaceContext(
            averages: {PreferenceCriterion.taste: 5},
            mine: {PreferenceCriterion.portion: 5},
          ),
        ),
        null,
      );
      expect(
        () => tasteMatch(
          p,
          const PlaceContext(averages: {PreferenceCriterion.taste: 6}),
        ),
        throwsFormatException,
      );
      expect(tasteMatch(null, const PlaceContext()), null);
    },
  );
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
