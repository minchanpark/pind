import '../model/discover_model.dart';
import '../model/place_search_result.dart';
import '../services/discover_service.dart';

class DiscoverController {
  DiscoverController({required DiscoverService? service})
    : _service = service ?? UnavailableDiscoverService();
  final DiscoverService _service;
  final model = DiscoverModel();
  bool _disposed = false;
  int _request = 0;
  final _liking = <int>{};

  Future<void> load() async {
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
      caught is PlaceFailure ? caught.message : '피드를 불러오지 못했어요.';

  void dispose() {
    _disposed = true;
    _request++;
    model.dispose();
  }
}
