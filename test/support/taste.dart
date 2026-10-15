import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/taste_profile.dart';

/// My taste right after onboarding (stars 5 / 4.2 / 3.8, weights 50/30/20)
/// for [priorities]. Every Pind average is 3, so place ratings read as they
/// are. Cleared after the test.
void useStartTaste(List<PreferenceCriterion> priorities) {
  myTaste.value = TasteProfile(
    priorities: priorities,
    stars: {
      for (final c in PreferenceCriterion.values) c: 3,
      for (final (i, c) in priorities.indexed) c: const [5.0, 4.2, 3.8][i],
    },
    weights: {
      for (final (i, c) in priorities.indexed) c: const [50.0, 30.0, 20.0][i],
    },
    averages: {for (final c in PreferenceCriterion.values) c: 3},
  );
  addTearDown(() => myTaste.value = null);
}
