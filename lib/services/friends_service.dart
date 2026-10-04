import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/friends_model.dart';
import '../model/place_search_result.dart';
import '../model/preferences.dart';
import '../model/profile_model.dart';
import 'data_revision.dart';
import '../l10n/l10n.dart';

/// Follows (`public.follows`), taste recommendations (`get_taste_matches`),
/// user search (`search_profiles`) and the server copy of the onboarding
/// priorities (`public.taste_profiles`).
abstract interface class FriendsService {
  /// Best taste matches first, excluding people already followed.
  Future<List<FriendCandidate>> matches({int offset = 0, int limit = 5});

  /// Handle or display name.
  Future<List<FriendCandidate>> search(String query);

  Future<void> setFollowing(String userId, bool following);

  /// Who follows [userId] ([followers]) or whom they follow, newest first,
  /// each marked with whether I follow them. Null [userId] is me.
  Future<List<FriendCandidate>> follows({
    String? userId,
    required bool followers,
  });

  /// [discoverable]: whether others may be recommended this user.
  Future<void> saveTaste(TastePreferences preferences, {bool discoverable});
}

class UnavailableFriendsService implements FriendsService {
  static final _failure = PlaceFailure(l10n.errFriendsServer);
  @override
  Future<List<FriendCandidate>> matches({int offset = 0, int limit = 5}) =>
      throw _failure;
  @override
  Future<List<FriendCandidate>> search(String query) => throw _failure;
  @override
  Future<void> setFollowing(String userId, bool following) => throw _failure;
  @override
  Future<List<FriendCandidate>> follows({
    String? userId,
    required bool followers,
  }) => throw _failure;
  @override
  Future<void> saveTaste(
    TastePreferences preferences, {
    bool discoverable = false,
  }) async {}
}

class SupabaseFriendsService implements FriendsService {
  SupabaseFriendsService(this.client);
  final SupabaseClient client;

  String get _uid {
    final user = client.auth.currentUser;
    if (user == null) throw PlaceFailure(l10n.errSignInRequired);
    return user.id;
  }

  List<FriendCandidate> _parse(Object? rows) => [
    for (final r in (rows as List?) ?? const [])
      FriendCandidate.fromJson(Map<String, dynamic>.from(r as Map)),
  ];

  @override
  Future<List<FriendCandidate>> matches({int offset = 0, int limit = 5}) async {
    try {
      return _parse(
        await client.rpc(
          'get_taste_matches',
          params: {'p_limit': limit, 'p_offset': offset},
        ),
      );
    } on PostgrestException {
      throw PlaceFailure(l10n.errSuggestionsLoad);
    }
  }

  @override
  Future<List<FriendCandidate>> search(String query) async {
    try {
      return _parse(
        await client.rpc('search_profiles', params: {'p_query': query}),
      );
    } on PostgrestException {
      throw PlaceFailure(l10n.errSearchFailed);
    }
  }

  @override
  Future<List<FriendCandidate>> follows({
    String? userId,
    required bool followers,
  }) async {
    final me = _uid, of = userId ?? me;
    // The other end of each follow, through its own foreign key.
    final (match, person) = followers
        ? ('followee_id', 'follows_follower_id_fkey')
        : ('follower_id', 'follows_followee_id_fkey');
    try {
      final rows = await client
          .from('follows')
          .select(
            'p:profiles!$person(id, handle, display_name, avatar_url, bio)',
          )
          .eq(match, of)
          .order('created_at', ascending: false);
      final people = [
        for (final r in rows)
          if (r['p'] case final Map p) Map<String, dynamic>.from(p),
      ];
      final ids = [for (final p in people) p['id'] as String];
      final mine = ids.isEmpty
          ? <String>{}
          : {
              for (final r
                  in await client
                      .from('follows')
                      .select('followee_id')
                      .eq('follower_id', me)
                      .inFilter('followee_id', ids))
                r['followee_id'] as String,
            };
      return [
        for (final p in people)
          FriendCandidate(
            profile: UserProfile(
              id: p['id'] as String,
              handle: p['handle'] as String?,
              displayName: p['display_name'] as String? ?? '',
              avatarUrl: p['avatar_url'] as String?,
              bio: p['bio'] as String?,
            ),
            following: mine.contains(p['id']),
          ),
      ];
    } on PostgrestException {
      throw PlaceFailure(
        followers ? l10n.errFollowersLoad : l10n.errFollowingLoad,
      );
    }
  }

  @override
  Future<void> setFollowing(String userId, bool following) async {
    final me = _uid;
    try {
      if (following) {
        await client.from('follows').insert({
          'follower_id': me,
          'followee_id': userId,
        });
      } else {
        await client.from('follows').delete().match({
          'follower_id': me,
          'followee_id': userId,
        });
      }
      markDataChanged();
    } on PostgrestException catch (e) {
      if (e.code == '23505') return; // already following
      throw PlaceFailure(following ? l10n.errFollow : l10n.errUnfollow);
    }
  }

  @override
  Future<void> saveTaste(
    TastePreferences preferences, {
    bool discoverable = false,
  }) async {
    final user = client.auth.currentUser;
    if (user == null || !preferences.isComplete) return;
    await client.from('taste_profiles').upsert({
      'user_id': user.id,
      'priorities': [for (final p in preferences.priorities) p.name],
      'discoverable': discoverable,
    });
    markDataChanged();
  }
}
