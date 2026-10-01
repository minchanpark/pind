import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/discover_model.dart';
import '../model/place_search_result.dart';
import '../model/profile_model.dart';
import 'post_media_urls.dart';
import 'data_revision.dart';

/// Public posts from every user, newest first (`get_discover_feed`), and
/// per-user likes (`toggle_post_like`).
abstract interface class DiscoverService {
  /// Pass the last post of the previous page as [after] to get the next page.
  /// [query] matches place name, category and post body.
  Future<FeedPage> feed({FeedPost? after, String query = '', int limit = 20});

  /// Returns the server's liked state after toggling.
  Future<bool> setLiked(int postId, bool liked);
}

class UnavailableDiscoverService implements DiscoverService {
  @override
  Future<FeedPage> feed({FeedPost? after, String query = '', int limit = 20}) =>
      throw const PlaceFailure('피드 서버에 연결하지 못했어요.');
  @override
  Future<bool> setLiked(int postId, bool liked) =>
      throw const PlaceFailure('피드 서버에 연결하지 못했어요.');
}

class SupabaseDiscoverService implements DiscoverService {
  SupabaseDiscoverService(this.client);
  final SupabaseClient client;

  @override
  Future<FeedPage> feed({
    FeedPost? after,
    String query = '',
    int limit = 20,
  }) async {
    try {
      final result = await client.rpc(
        'get_discover_feed',
        params: {
          'p_query': query.trim().isEmpty ? null : query.trim(),
          'p_before_created': after?.post.createdAt.toUtc().toIso8601String(),
          'p_before_id': after?.post.id,
          'p_limit': limit + 1,
        },
      );
      final rows = (result as List?) ?? const [];
      final hasMore = rows.length > limit;
      final page = rows.take(limit).cast<Map>().toList();
      final signed = await signPostPhotoPaths(
        client,
        collectPostPhotoPaths(page),
      );
      FeedPost? parse(Map r) {
        try {
          return FeedPost(
            post: parseMyPost(
              r,
              photoUrl: (p) => resolvePostPhotoUrl(
                client,
                signed,
                r['bucket'] as String?,
                p,
              ),
            ),
            author: UserProfile.fromJson(
              Map<String, dynamic>.from(r['author'] as Map),
            ),
            likeCount: (r['likeCount'] as num?)?.toInt() ?? 0,
            liked: r['liked'] == true,
          );
        } catch (_) {
          // One malformed row must not blank the whole feed.
          return null;
        }
      }

      return FeedPage([for (final r in page) ?parse(r)], hasMore: hasMore);
    } on PostgrestException {
      throw const PlaceFailure('피드를 불러오지 못했어요.');
    }
  }

  @override
  Future<bool> setLiked(int postId, bool liked) async {
    try {
      final result = await client.rpc(
        'toggle_post_like',
        params: {'p_post_id': postId, 'p_liked': liked},
      );
      markDataChanged();
      return result == true;
    } on PostgrestException {
      throw const PlaceFailure('로그인 후 좋아요를 누를 수 있어요.');
    }
  }
}
