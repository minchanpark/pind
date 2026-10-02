import 'place_context.dart';
import 'places.dart';
import 'preferences.dart';
import 'profile_model.dart';

/// The agent search page's answer: how the sentence was read, and the
/// posted places it found, best first.
typedef AgentAnswer = ({String? notice, List<RankedPlace> places});

/// One row of the map category list (`get_nearby_ranking`).
class RankedPlace {
  const RankedPlace({
    required this.place,
    this.imageUrl,
    this.meters,
    this.averages = const {},
    this.reviewCount = 0,
    this.saveCount = 0,
    this.saved = false,
    this.friendLine,
    this.friendAvatars = const [],
  });
  final Place place;
  final String? imageUrl;

  /// From the search origin; null when there was none.
  final double? meters;
  final Map<PreferenceCriterion, double> averages;
  final int reviewCount, saveCount;
  final bool saved;

  /// `하람 외 1명이 다녀감` / `하람님이 저장함`; visits win over saves.
  final String? friendLine;
  final List<String?> friendAvatars;

  /// [imageUrl] resolves the place's latest post photo (signed or public).
  factory RankedPlace.fromJson(Map<String, dynamic> json, {String? imageUrl}) {
    final visited = json['visitedBy'] as Map? ?? {};
    final saved = json['savedBy'] as Map? ?? {};
    final (by, verb) = ((visited['count'] as num?) ?? 0) > 0
        ? (visited, '다녀감')
        : (saved, '저장함');
    final count = (by['count'] as num?)?.toInt() ?? 0;
    final people = (by['people'] as List? ?? []).cast<Map>();
    final first = people.firstOrNull?['name'] as String?;
    return RankedPlace(
      place: Place.fromJson(json),
      imageUrl: json['heroImageUrl'] as String? ?? imageUrl,
      meters: (json['meters'] as num?)?.toDouble(),
      averages: parseCriteria(json['averages'], (n) => n.toDouble()),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      saved: json['saved'] == true,
      friendLine: count == 0 || first == null
          ? null
          : count == 1
          ? '$first님이 $verb'
          : '$first 외 ${count - 1}명이 $verb',
      friendAvatars: [for (final p in people) p['avatar'] as String?],
    );
  }

  RankedPlace copyWith({bool? saved, int? saveCount}) => RankedPlace(
    place: place,
    imageUrl: imageUrl,
    meters: meters,
    averages: averages,
    reviewCount: reviewCount,
    saveCount: saveCount ?? this.saveCount,
    saved: saved ?? this.saved,
    friendLine: friendLine,
    friendAvatars: friendAvatars,
  );
}

/// [places] arrive nearest first. [by] null ranks by taste match, else by
/// that criterion's average. Unscored places go last; ties stay nearest
/// first.
List<RankedPlace> rankPlaces(
  List<RankedPlace> places,
  TastePreferences? preferences,
  PreferenceCriterion? by,
) {
  num? score(RankedPlace p) => by == null
      ? tasteMatch(preferences, PlaceContext(averages: p.averages))
      : p.averages[by];
  final rows = [for (var i = 0; i < places.length; i++) (i, score(places[i]))];
  rows.sort(
    (a, b) => switch ((a.$2, b.$2)) {
      (final x?, final y?) when x != y => y.compareTo(x),
      (null, _?) => 1,
      (_?, null) => -1,
      _ => a.$1 - b.$1,
    },
  );
  return [for (final (i, _) in rows) places[i]];
}
