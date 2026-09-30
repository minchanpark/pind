import 'package:flutter/foundation.dart';

import 'profile_model.dart';

/// A user on the find-friends page. [match] is the taste overlap 0–100, or
/// null when it can't be computed (no taste profile or no consent).
class FriendCandidate {
  const FriendCandidate({
    required this.profile,
    this.match,
    this.following = false,
  });
  final UserProfile profile;
  final int? match;
  final bool following;

  factory FriendCandidate.fromJson(Map<String, dynamic> json) =>
      FriendCandidate(
        profile: UserProfile.fromJson(json),
        match: (json['match'] as num?)?.toInt(),
        following: json['following'] == true,
      );

  FriendCandidate withFollowing(bool value) =>
      FriendCandidate(profile: profile, match: match, following: value);
}

class FriendsModel extends ChangeNotifier {
  List<FriendCandidate> matches = const [], results = const [];
  String query = '';
  bool loading = false, loadingMore = false, searching = false;
  bool hasMore = false;
  String? error;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
