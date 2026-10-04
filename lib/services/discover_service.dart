import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/discover_model.dart';
import '../model/notification_model.dart';
import '../model/place_search_result.dart';
import '../model/profile_model.dart';
import 'post_media_urls.dart';
import 'data_revision.dart';
import '../l10n/l10n.dart';

/// Public posts from every user, newest first (`get_discover_feed`), and
/// per-user likes (`toggle_post_like`).
abstract interface class DiscoverService {
  /// Pass the last post of the previous page as [after] to get the next page.
  /// [query] matches place name, category and post body.
  Future<FeedPage> feed({FeedPost? after, String query = '', int limit = 20});

  /// Returns the server's liked state after toggling.
  Future<bool> setLiked(int postId, bool liked);

  /// 알림: likes on my posts, visits by people I follow, new followers.
  Future<NotificationInbox> notifications();

  /// 모두 읽음; returns the server's read time.
  Future<DateTime> markNotificationsRead();
}

class UnavailableDiscoverService implements DiscoverService {
  @override
  Future<FeedPage> feed({FeedPost? after, String query = '', int limit = 20}) =>
      throw PlaceFailure(l10n.errFeedServer);
  @override
  Future<bool> setLiked(int postId, bool liked) =>
      throw PlaceFailure(l10n.errFeedServer);
  @override
  Future<NotificationInbox> notifications() =>
      throw PlaceFailure(l10n.errNotificationsLoad);
  @override
  Future<DateTime> markNotificationsRead() =>
      throw PlaceFailure(l10n.errNotificationsRead);
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
      throw PlaceFailure(l10n.errFeedLoad);
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
      throw PlaceFailure(l10n.errLikeSignIn);
    }
  }

  @override
  Future<NotificationInbox> notifications() async {
    try {
      final result = Map<String, dynamic>.from(
        await client.rpc('get_notifications') as Map,
      );
      final rows = [
        for (final r in result['items'] as List? ?? [])
          Map<String, dynamic>.from(r as Map),
      ];
      final signed = await signPostPhotoPaths(client, [
        for (final r in rows)
          if (r['photoBucket'] == postMediaV2Bucket && r['photoPath'] is String)
            r['photoPath'] as String,
      ]);
      final items = <PindNotification>[];
      for (final r in rows) {
        try {
          items.add(
            PindNotification.fromJson(
              r,
              photoUrl: resolvePostPhotoUrl(
                client,
                signed,
                r['photoBucket'] as String?,
                r['photoPath'] as String?,
              ),
            ),
          );
        } catch (_) {
          // One malformed row must not blank the page.
        }
      }
      return NotificationInbox(
        items,
        seenAt: DateTime.tryParse(result['seenAt'] as String? ?? ''),
      );
    } on PostgrestException {
      throw PlaceFailure(l10n.errNotificationsLoad);
    }
  }

  @override
  Future<DateTime> markNotificationsRead() async {
    try {
      return DateTime.parse(
        await client.rpc('mark_notifications_read') as String,
      );
    } on PostgrestException {
      throw PlaceFailure(l10n.errNotificationsRead);
    }
  }
}
