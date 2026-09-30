import '../model/friends_model.dart';
import '../model/place_search_result.dart';
import '../model/profile_link.dart';
import '../model/profile_model.dart';
import '../services/friends_service.dart';
import '../services/profile_service.dart';

class FriendsController {
  FriendsController({required FriendsService? service, this.profile})
    : _service = service ?? UnavailableFriendsService();
  final FriendsService _service;
  final ProfileService? profile;
  final model = FriendsModel();
  static const firstPage = 5, morePage = 10;
  bool _disposed = false;
  int _search = 0;
  final _toggling = <String>{};

  Future<void> load() async {
    model.update(() {
      model.loading = true;
      model.error = null;
    });
    try {
      final page = await _service.matches(limit: firstPage + 1);
      if (_disposed) return;
      model.update(() {
        model.matches = page.take(firstPage).toList();
        model.hasMore = page.length > firstPage;
        model.loading = false;
      });
    } catch (caught) {
      if (_disposed) return;
      model.update(() {
        model.loading = false;
        model.error = _message(caught, '추천 목록을 불러오지 못했어요.');
      });
    }
  }

  Future<void> loadMore() async {
    if (model.loading || model.loadingMore || !model.hasMore) return;
    model.update(() => model.loadingMore = true);
    try {
      // The server drops people followed since the last page, so only the
      // still-unfollowed rows count toward the offset.
      final page = await _service.matches(
        offset: model.matches.where((m) => !m.following).length,
        limit: morePage + 1,
      );
      if (_disposed) return;
      final seen = {for (final m in model.matches) m.profile.id};
      model.update(() {
        model.matches = [
          ...model.matches,
          for (final m in page.take(morePage))
            if (seen.add(m.profile.id)) m,
        ];
        model.hasMore = page.length > morePage;
        model.loadingMore = false;
      });
    } catch (caught) {
      if (_disposed) return;
      model.update(() {
        model.loadingMore = false;
        model.error = _message(caught, '추천 목록을 불러오지 못했어요.');
      });
    }
  }

  Future<void> search(String query) async {
    final request = ++_search;
    final text = query.trim();
    if (text.isEmpty) {
      return model.update(() {
        model.query = '';
        model.results = const [];
        model.searching = false;
      });
    }
    model.update(() {
      model.query = text;
      model.searching = true;
      model.error = null;
    });
    try {
      final results = await _service.search(text);
      if (_disposed || request != _search) return;
      model.update(() {
        model.results = results;
        model.searching = false;
      });
    } catch (caught) {
      if (_disposed || request != _search) return;
      model.update(() {
        model.results = const [];
        model.searching = false;
        model.error = _message(caught, '검색하지 못했어요.');
      });
    }
  }

  /// Optimistic in both lists; reverts if the server refuses.
  Future<void> toggleFollow(FriendCandidate candidate) async {
    final id = candidate.profile.id;
    if (_disposed || !_toggling.add(id)) return;
    final target = !candidate.following;
    markFollowing(id, target);
    try {
      await _service.setFollowing(id, target);
    } catch (caught) {
      if (!_disposed) {
        markFollowing(id, !target);
        model.update(
          () => model.error = _message(
            caught,
            target ? '팔로우하지 못했어요.' : '팔로우를 취소하지 못했어요.',
          ),
        );
      }
    } finally {
      _toggling.remove(id);
    }
  }

  /// Also used after a follow change on that user's profile page.
  void markFollowing(String id, bool value) => model.update(() {
    List<FriendCandidate> apply(List<FriendCandidate> list) => [
      for (final c in list) c.profile.id == id ? c.withFollowing(value) : c,
    ];
    model.matches = apply(model.matches);
    model.results = apply(model.results);
  });

  /// Text for the share sheet: my profile link, which opens the app on my
  /// page (or the store when it isn't installed).
  Future<String> inviteText() async => inviteFor(await me());

  static String inviteFor(UserProfile? me) {
    if (me == null) return 'Pind에서 서로의 음식 취향을 팔로우해요!';
    final who = me.handle == null ? me.displayName : '@${me.handle}';
    return 'Pind에서 $who 님을 팔로우하고 음식 취향을 나눠요!\n${ProfileLink.of(me).uri}';
  }

  /// My profile; null when signed out or it failed to load.
  Future<UserProfile?> me() async {
    try {
      return await profile?.load();
    } catch (_) {
      return null;
    }
  }

  String _message(Object caught, String fallback) =>
      caught is PlaceFailure ? caught.message : fallback;

  void dispose() {
    _disposed = true;
    _search++;
    model.dispose();
  }
}
