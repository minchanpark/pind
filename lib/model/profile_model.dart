import 'package:flutter/foundation.dart';

import 'places.dart';
import 'preferences.dart';

enum ProfileTab { map, saved, posts }

class UserProfile {
  const UserProfile({
    required this.id,
    this.handle,
    required this.displayName,
    this.avatarUrl,
    this.bio,
  });
  final String id, displayName;
  final String? handle, avatarUrl, bio;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    handle: json['handle'] as String?,
    displayName: json['displayName'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String?,
    bio: json['bio'] as String?,
  );

  UserProfile copyWith({
    String? handle,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) => UserProfile(
    id: id,
    handle: handle ?? this.handle,
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    bio: bio ?? this.bio,
  );
}

class ProfileCounts {
  const ProfileCounts({
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.saved = 0,
  });
  final int followers, following, posts, saved;
  factory ProfileCounts.fromJson(Map<String, dynamic> json) => ProfileCounts(
    followers: (json['followers'] as num?)?.toInt() ?? 0,
    following: (json['following'] as num?)?.toInt() ?? 0,
    posts: (json['posts'] as num?)?.toInt() ?? 0,
    saved: (json['saved'] as num?)?.toInt() ?? 0,
  );
}

/// A place card on the profile (recently viewed / saved). [imageUrl] is
/// already resolved by the service (signed or public).
class ProfilePlaceCard {
  const ProfilePlaceCard({
    required this.place,
    this.imageUrl,
    this.averages = const {},
    this.ratingCounts = const {},
    this.savedAt,
    this.reviewCount = 0,
    this.savers = const [],
  });
  final Place place;
  final String? imageUrl;
  final Map<PreferenceCriterion, double> averages;
  final Map<PreferenceCriterion, int> ratingCounts;

  /// Saved cards only: when it was saved, public posts there, and avatars
  /// (null = no photo) of up to 3 people I follow who saved it too.
  final DateTime? savedAt;
  final int reviewCount;
  final List<String?> savers;
}

class MyPost {
  const MyPost({
    required this.id,
    required this.place,
    this.body = '',
    this.ratings = const {},
    this.photos = const [],
    required this.createdAt,
  });
  final int id;
  final Place place;
  final String body;
  final Map<PreferenceCriterion, int> ratings;

  /// Resolved photo URLs in position order.
  final List<String> photos;
  final DateTime createdAt;
}

class ProfileOverview {
  const ProfileOverview({
    required this.profile,
    this.counts = const ProfileCounts(),
    this.recentViews = const [],
    this.savedPlaces = const [],
    this.posts = const [],
    this.following = false,
    this.followsMe = false,
    this.taste,
  });
  final UserProfile profile;
  final ProfileCounts counts;
  final List<ProfilePlaceCard> recentViews, savedPlaces;
  final List<MyPost> posts;

  /// Whether I follow this user / they follow me. Always false on my own page.
  final bool following, followsMe;

  /// Another user's priorities, only when they consented to recommendations.
  final List<PreferenceCriterion>? taste;

  ProfileOverview copyWith({
    UserProfile? profile,
    ProfileCounts? counts,
    bool? following,
  }) => ProfileOverview(
    profile: profile ?? this.profile,
    counts: counts ?? this.counts,
    recentViews: recentViews,
    savedPlaces: savedPlaces,
    posts: posts,
    following: following ?? this.following,
    followsMe: followsMe,
    taste: taste,
  );

  /// Distinct places of my posts, newest post first (the map centers on it).
  List<Place> get mapPlaces {
    final seen = <int>{};
    return [
      for (final p in posts)
        if (p.place.id != null && seen.add(p.place.id!)) p.place,
    ];
  }
}

Map<PreferenceCriterion, T> parseCriteria<T extends num>(
  dynamic raw,
  T Function(num) convert,
) => {
  for (final e in (raw as Map? ?? {}).entries)
    if (PreferenceCriterion.values.any((c) => c.name == e.key))
      PreferenceCriterion.values.byName(e.key as String): convert(
        e.value as num,
      ),
};

class ProfileModel extends ChangeNotifier {
  ProfileOverview? overview;
  ProfileTab tab = ProfileTab.map;
  bool loading = false, saving = false;
  String? error;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
