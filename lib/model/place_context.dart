import 'package:flutter/foundation.dart';

import 'places.dart';
import 'preferences.dart';
import 'taste_profile.dart';

/// Only Pind's criterion-level ratings are used, never Google's overall rating.
class PlaceContext {
  const PlaceContext({
    this.averages = const {},
    this.mine = const {},
    this.ratingCounts = const {},
    this.visitors = const [],
    this.friendSaveCount = 0,
    this.saved = false,
  });
  final Map<PreferenceCriterion, double> averages, mine;
  final Map<PreferenceCriterion, int> ratingCounts;
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
      ratingCounts: {
        for (final entry in (json['ratingCounts'] as Map? ?? {}).entries)
          PreferenceCriterion.values.byName(entry.key as String):
              (entry.value as num).toInt(),
      },
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

/// My taste % for a place from its shared averages, or null until my taste
/// profile for these [preferences] has loaded (see [TasteProfile.match]).
int? tasteMatch(TastePreferences? preferences, PlaceContext data) {
  final taste = myTaste.value;
  if (preferences == null ||
      taste == null ||
      !listEquals(taste.priorities, preferences.priorities)) {
    return null;
  }
  return taste.match(data.averages);
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
