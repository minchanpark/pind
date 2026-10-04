import 'dart:ui';

import '../model/place_search_result.dart';
import '../model/profile_model.dart';
import '../model/friends_model.dart';
import '../services/friends_service.dart';
import '../services/place_action_service.dart';
import '../services/post_photo_service.dart';
import '../services/profile_service.dart';
import '../services/data_revision.dart';
import '../l10n/l10n.dart';

class ProfileController {
  ProfileController({required this.profile, this.userId, this.friends});
  final ProfileService? profile;

  /// Someone else's page when set; null is My Page.
  final String? userId;
  final FriendsService? friends;
  bool get isMe => userId == null;
  final model = ProfileModel();
  bool _disposed = false;
  int _request = 0;

  ProfileService get _service => profile ?? UnavailableProfileService();

  int? _loadedRevision;

  /// [load] only if a write happened since the last successful load.
  Future<void> refresh() async {
    if (_loadedRevision != dataRevision || model.overview == null) await load();
  }

  Future<void> load() async {
    final request = ++_request;
    final revision = dataRevision;
    model.update(() {
      model.loading = true;
      model.error = null;
    });
    try {
      final overview = await _service.overview(userId: userId);
      if (_disposed || request != _request) return;
      _loadedRevision = revision;
      model.update(() {
        model.overview = overview;
        model.loading = false;
      });
    } catch (caught) {
      if (_disposed || request != _request) return;
      model.update(() {
        model.loading = false;
        model.error = _message(caught, l10n.errProfileLoadRetry);
      });
    }
  }

  /// Optimistic, followers count included. False (and [ProfileModel.error]
  /// set) when the server refused and the page was reverted.
  /// This page's 팔로워 ([followers]) or 팔로잉.
  Future<List<FriendCandidate>> followList(bool followers) =>
      (friends ?? UnavailableFriendsService()).follows(
        userId: userId,
        followers: followers,
      );

  Future<void> setFollowing(String id, bool following) =>
      (friends ?? UnavailableFriendsService()).setFollowing(id, following);

  Future<bool> toggleFollow() async {
    final o = model.overview, id = userId;
    if (o == null || id == null || model.saving) return true;
    final target = !o.following;
    void apply(bool following) => model.update(() {
      final now = model.overview!;
      final c = now.counts;
      model.overview = now.copyWith(
        following: following,
        counts: ProfileCounts(
          followers: c.followers + (following ? 1 : -1),
          following: c.following,
          posts: c.posts,
          saved: c.saved,
        ),
      );
    });
    model.saving = true;
    apply(target);
    try {
      await (friends ?? UnavailableFriendsService()).setFollowing(id, target);
      return true;
    } catch (caught) {
      if (_disposed) return false;
      model.error = _message(
        caught,
        target ? l10n.errFollow : l10n.errUnfollow,
      );
      apply(!target);
      return false;
    } finally {
      if (!_disposed) model.saving = false;
    }
  }

  void selectTab(ProfileTab tab) => model.update(() => model.tab = tab);

  Future<void> pickAndUploadAvatar(PostPhotoService photos) async {
    if (model.saving) return;
    model.update(() {
      model.saving = true;
      model.error = null;
    });
    try {
      final picked = await photos.pick(1);
      if (_disposed || picked.isEmpty) return;
      final url = await _service.uploadAvatar(picked.first);
      await _service.save(avatarUrl: url);
      if (!_disposed) _patch((p) => p.copyWith(avatarUrl: url));
    } catch (caught) {
      if (!_disposed) {
        model.error = _message(caught, l10n.errPhotoUpload);
      }
    } finally {
      if (!_disposed) model.update(() => model.saving = false);
    }
  }

  /// True on success; the failure text is left in [ProfileModel.error].
  Future<bool> saveProfile({String? displayName, String? bio}) async {
    if (model.saving) return false;
    model.update(() {
      model.saving = true;
      model.error = null;
    });
    try {
      await _service.save(displayName: displayName, bio: bio);
      if (_disposed) return false;
      _patch((p) => p.copyWith(displayName: displayName, bio: bio));
      return true;
    } catch (caught) {
      if (!_disposed) {
        model.error = _message(caught, l10n.errProfileSave);
      }
      return false;
    } finally {
      if (!_disposed) model.update(() => model.saving = false);
    }
  }

  Future<void> share(MyPost post, Rect origin) async {
    try {
      await PlaceActionService.share(
        '${post.place.name} · Pind',
        post.place.name,
        origin,
      );
    } catch (_) {}
  }

  void _patch(UserProfile Function(UserProfile) change) {
    final o = model.overview;
    if (o == null) return;
    final profile = change(o.profile);
    model.overview = o.copyWith(profile: profile);
    if (isMe) myProfileEdits.add(profile);
  }

  String _message(Object caught, String fallback) =>
      caught is PlaceFailure ? caught.message : fallback;

  void dispose() {
    _disposed = true;
    _request++;
    model.dispose();
  }
}
