import 'places.dart';
import 'preferences.dart';

/// Only Pind's criterion-level ratings are used, never Google's overall rating.
class PlaceContext {
  const PlaceContext({
    this.averages = const {},
    this.mine = const {},
    this.visitors = const [],
    this.friendSaveCount = 0,
    this.saved = false,
  });
  final Map<PreferenceCriterion, double> averages, mine;
  final List<FriendVisit> visitors;
  final int friendSaveCount;
  final bool saved;

  factory PlaceContext.fromJson(Map<String, dynamic> json) {
    Map<PreferenceCriterion, double> ratings(dynamic raw) => {
      for (final entry in (raw as Map? ?? {}).entries)
        PreferenceCriterion.values.byName(entry.key as String):
            (entry.value as num).toDouble(),
    };
    return PlaceContext(
      averages: ratings(json['averages']),
      mine: ratings(json['mine']),
      visitors: [
        for (final v in json['visitors'] as List? ?? [])
          FriendVisit(
            v['id'] as String,
            v['name'] as String,
            v['avatar'] as String?,
          ),
      ],
      friendSaveCount: (json['friendSaveCount'] as num?)?.toInt() ?? 0,
      saved: json['saved'] == true,
    );
  }
}

class FriendVisit {
  const FriendVisit(this.id, this.name, this.avatar);
  final String id, name;
  final String? avatar;
}

/// Priority weights shared by [tasteMatch] and the profile taste card.
const tasteWeights = [.5, .3, .2];

/// All three selected axes must have an aggregate. No partial-score inflation.
int? tasteMatch(TastePreferences? preferences, PlaceContext data) {
  if (preferences == null || preferences.priorities.length != 3) return null;
  double result = 0;
  for (var i = 0; i < 3; i++) {
    final axis = preferences.priorities[i];
    final average = data.averages[axis], mine = data.mine[axis];
    for (final rating in [average, mine]) {
      if (rating != null && (!rating.isFinite || rating < 1 || rating > 5)) {
        throw const FormatException('Rating outside 1–5');
      }
    }
    if (average == null) return null;
    final score = mine == null ? average : (average + mine) / 2;
    result += score / 5 * tasteWeights[i];
  }
  return (result * 100).round().clamp(0, 100);
}

extension CriterionPresentation on PreferenceCriterion {
  String get emoji => switch (this) {
    PreferenceCriterion.taste => '😋',
    PreferenceCriterion.portion => '🍚',
    PreferenceCriterion.ambience => '🕯️',
    PreferenceCriterion.value => '💰',
    PreferenceCriterion.service => '✨',
    PreferenceCriterion.photogenic => '📷',
    PreferenceCriterion.quiet => '🤫',
    PreferenceCriterion.parking => '🚗',
  };
}

String? todayHours(Place place, DateTime now) {
  // Product region is Korea; UTC+9 fallback is explicit, not device timezone.
  final local = now.toUtc().add(
    Duration(minutes: place.utcOffsetMinutes ?? 540),
  );
  if (place.hours.length != 7) return null;
  final text = place.hours[local.weekday - 1];
  final separator = text.indexOf(':');
  return separator < 0 ? text : text.substring(separator + 1).trim();
}

String formatDistance(double meters) => meters < 1000
    ? '${meters.round()}m'
    : '${(meters / 1000).toStringAsFixed(1)}km';

Uri directionsUri(Place place) => (place.isGoogle || place.isCatalog)
    ? Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': '${place.latitude},${place.longitude}',
        if (place.isGoogle) 'destination_place_id': place.externalId,
      })
    : Uri.parse(place.mapsUri);
