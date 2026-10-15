import 'package:flutter/foundation.dart';

import 'preferences.dart';

/// My taste from `get_my_taste` (doc/taste-calculation.md): one 1–5 star
/// per criterion where 3 is Pind's average, each star's share above 3 as
/// its weight, and Pind's average rating per criterion so a place reads on
/// the same scale.
class TasteProfile {
  const TasteProfile({
    required this.priorities,
    required this.stars,
    required this.weights,
    required this.averages,
    this.evidence = 0,
  });

  factory TasteProfile.fromJson(Map<String, dynamic> json) {
    final names = PreferenceCriterion.values.asNameMap();
    Map<PreferenceCriterion, double> byCriterion(Object? map) => {
      for (final MapEntry(:key, :value) in (map as Map? ?? {}).entries)
        ?names[key]: (value as num).toDouble(),
    };
    return TasteProfile(
      priorities: [
        for (final p in json['priorities'] as List? ?? []) ?names[p],
      ],
      stars: byCriterion(json['stars']),
      weights: byCriterion(json['weights']),
      averages: byCriterion(json['averages']),
      evidence: (json['evidence'] as num?)?.toInt() ?? 0,
    );
  }

  /// The onboarding choice the stars started from.
  final List<PreferenceCriterion> priorities;
  final Map<PreferenceCriterion, double> stars, weights, averages;

  /// Places whose ratings moved the stars.
  final int evidence;

  /// Weighted criteria, heaviest first.
  List<MapEntry<PreferenceCriterion, double>> get ranked => [
    for (final e in weights.entries)
      if (e.value > 0) e,
  ]..sort((a, b) => b.value.compareTo(a.value));

  /// Place %, mirroring `public.taste_place_match`: each weighted criterion
  /// loses only the share by which the place, read relative to Pind's
  /// average, falls short of my star. Unrated criteria holding 20% or more
  /// of the weight leave it unknown.
  int? match(Map<PreferenceCriterion, double> place) {
    var missing = 0.0, rated = 0.0, score = 0.0;
    for (final MapEntry(key: c, value: weight) in weights.entries) {
      if (weight <= 0) continue;
      final r = place[c];
      if (r == null) {
        missing += weight;
        continue;
      }
      if (!r.isFinite || r < 1 || r > 5) {
        throw const FormatException('Rating outside 1–5');
      }
      final star = stars[c]!;
      final shortfall = star - relativeStar(r, averages[c]);
      rated += weight;
      score += weight * (1 - (shortfall > 0 ? shortfall : 0) / (star - 1));
    }
    // Weights arrive rounded; 20 must not slip under by float noise.
    if (missing >= 20 - 1e-9 || rated == 0) return null;
    return (100 * score / rated).round().clamp(0, 100);
  }
}

/// [r] on the scale where Pind's average [g] is 3: g → 3, 5 → 5, 1 → 1,
/// linear on each side (`public.taste_star`).
double relativeStar(double r, double? g) {
  if (g == null || r == g) return 3;
  return r > g ? 3 + 2 * (r - g) / (5 - g) : 3 - 2 * (g - r) / (g - 1);
}

/// My taste as last loaded; null before the first load or when signed out.
/// Place % stays unknown until it arrives.
final myTaste = ValueNotifier<TasteProfile?>(null);
