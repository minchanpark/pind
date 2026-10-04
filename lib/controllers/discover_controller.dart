import 'dart:async';

import '../model/discover_model.dart';
import '../model/place_search_result.dart';
import '../model/profile_model.dart';
import '../services/data_revision.dart';
import '../services/discover_service.dart';
import '../l10n/l10n.dart';

class DiscoverController {
  DiscoverController({required DiscoverService? service, this.deletePost})
    : _service = service ?? UnavailableDiscoverService() {
    _edits = myProfileEdits.stream.listen(_authorChanged);
    _deletions = postDeletions.stream.listen(_drop);
  }
  late final StreamSubscription<UserProfile> _edits;
  late final StreamSubscription<int> _deletions;

  /// Deletes one of my posts; null hides 삭제.
  final Future<void> Function(int postId)? deletePost;

  /// Drops a post deleted here or anywhere else (place detail).
  void _drop(int postId) {
    if (_disposed || !model.posts.any((p) => p.post.id == postId)) return;
    model.update(
      () => model.posts = [
        for (final p in model.posts)
          if (p.post.id != postId) p,
      ],
    );
  }

  /// Null on success; otherwise the message to show.
  Future<String?> delete(FeedPost post) async {
    if (deletePost == null) return null;
    try {
      await deletePost!(post.post.id);
    } catch (caught) {
      return caught is PlaceFailure ? caught.message : l10n.errPostDelete;
    }
    _drop(post.post.id);
    return null;
  }

  /// My new photo/name on my posts already in the feed, without a refetch.
  void _authorChanged(UserProfile me) {
    if (!model.posts.any((p) => p.author.id == me.id)) return;
    model.update(() {
      model.posts = [
        for (final p in model.posts)
          p.author.id == me.id ? p.withAuthor(me) : p,
      ];
    });
  }

  final DiscoverService _service;
  final model = DiscoverModel();
  bool _disposed = false;
  int _request = 0;
  final _liking = <int>{};

  /// The bell's badge and the 알림 page. A failure keeps what was there;
  /// the page shows its own error.
  Future<void> loadNotifications() async {
    try {
      final inbox = await _service.notifications();
      if (!_disposed) model.update(() => model.inbox = inbox);
    } catch (_) {
      if (!_disposed && model.inbox == null) rethrow;
    }
  }

  /// 모두 읽음: at once here, then on the server.
  Future<void> markNotificationsRead() async {
    final inbox = model.inbox;
    if (inbox == null || inbox.unread == 0) return;
    model.update(() => model.inbox = inbox.readAll(DateTime.now()));
    try {
      final at = await _service.markNotificationsRead();
      if (!_disposed) model.update(() => model.inbox = inbox.readAll(at));
    } catch (_) {
      if (!_disposed) model.update(() => model.inbox = inbox);
      rethrow;
    }
  }

  Future<void> load() async {
    // The badge follows the feed; its errors stay on the 알림 page.
    loadNotifications().catchError((_) {});
    final request = ++_request;
    model.update(() {
      model.loading = true;
      model.error = null;
      model.posts = const [];
      model.hasMore = true;
    });
    try {
      final page = await _service.feed();
      if (_disposed || request != _request) return;
      model.update(() {
        model.posts = page.posts;
        model.hasMore = page.hasMore;
        model.loading = false;
      });
    } catch (caught) {
      if (_disposed || request != _request) return;
      model.update(() {
        model.loading = false;
        model.error = _message(caught);
      });
    }
  }

  Future<void> loadMore() async {
    if (model.loading ||
        model.loadingMore ||
        !model.hasMore ||
        model.posts.isEmpty) {
      return;
    }
    final request = ++_request;
    model.update(() => model.loadingMore = true);
    try {
      final page = await _service.feed(after: model.posts.last);
      if (_disposed || request != _request) return;
      final seen = {for (final p in model.posts) p.post.id};
      model.update(() {
        model.posts = [
          ...model.posts,
          for (final p in page.posts)
            if (seen.add(p.post.id)) p,
        ];
        model.hasMore = page.hasMore;
        model.loadingMore = false;
      });
    } catch (caught) {
      if (_disposed || request != _request) return;
      model.update(() {
        model.loadingMore = false;
        model.error = _message(caught);
      });
    }
  }

  Future<void> toggleLike(FeedPost post) async {
    if (_disposed || !_liking.add(post.post.id)) return;
    final target = !post.liked;
    model.update(() {
      model.posts = [
        for (final p in model.posts)
          if (p.post.id == post.post.id) p.withLike(target) else p,
      ];
    });
    try {
      await _service.setLiked(post.post.id, target);
    } catch (caught) {
      if (!_disposed) {
        model.update(() {
          model.posts = [
            for (final p in model.posts)
              if (p.post.id == post.post.id) p.withLike(post.liked) else p,
          ];
          model.error = _message(caught);
        });
      }
    } finally {
      _liking.remove(post.post.id);
    }
  }

  String _message(Object caught) =>
      caught is PlaceFailure ? caught.message : l10n.errFeedLoad;

  void dispose() {
    _edits.cancel();
    _deletions.cancel();
    _disposed = true;
    _request++;
    model.dispose();
  }
}
