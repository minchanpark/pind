import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/friends_model.dart';
import '../model/place_search_result.dart';
import '../model/preferences.dart';
import 'data_revision.dart';

/// Follows (`public.follows`), taste recommendations (`get_taste_matches`),
/// user search (`search_profiles`) and the server copy of the onboarding
/// priorities (`public.taste_profiles`).
abstract interface class FriendsService {
  /// Best taste matches first, excluding people already followed.
  Future<List<FriendCandidate>> matches({int offset = 0, int limit = 5});

  /// Handle or display name.
  Future<List<FriendCandidate>> search(String query);

  Future<void> setFollowing(String userId, bool following);

  /// [discoverable]: whether others may be recommended this user.
  Future<void> saveTaste(TastePreferences preferences, {bool discoverable});
}

class UnavailableFriendsService implements FriendsService {
  static const _failure = PlaceFailure('친구 서버에 연결하지 못했어요.');
  @override
  Future<List<FriendCandidate>> matches({int offset = 0, int limit = 5}) =>
      throw _failure;
  @override
  Future<List<FriendCandidate>> search(String query) => throw _failure;
  @override
  Future<void> setFollowing(String userId, bool following) => throw _failure;
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
    if (user == null) throw const PlaceFailure('로그인이 필요해요.');
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
      throw const PlaceFailure('추천 목록을 불러오지 못했어요.');
    }
  }

  @override
  Future<List<FriendCandidate>> search(String query) async {
    try {
      return _parse(
        await client.rpc('search_profiles', params: {'p_query': query}),
      );
    } on PostgrestException {
      throw const PlaceFailure('검색하지 못했어요.');
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
      throw PlaceFailure(following ? '팔로우하지 못했어요.' : '팔로우를 취소하지 못했어요.');
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
