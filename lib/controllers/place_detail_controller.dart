import 'dart:async';
import 'dart:ui';

import '../model/place_detail_model.dart';
import '../model/place_search_result.dart';
import '../model/places.dart';
import '../model/preferences.dart';
import '../services/location_service.dart';
import '../services/place_action_service.dart';
import '../services/place_context_service.dart';
import '../services/place_service.dart';
import '../services/profile_service.dart';

class PlaceDetailController {
  PlaceDetailController({
    required Place place,
    required this.places,
    this.context,
    this.preferences,
    this.profile,
    this.position = LocationService.position,
    this.shareAction,
    this.linkAction,
    this.setLiked,
    this.deletePost,
  }) : initialPlace = place,
       model = PlaceDetailModel(place);

  final Place initialPlace;
  final PlaceService places;
  final PlaceContextService? context;
  final TastePreferences? preferences;
  final ProfileService? profile;
  final Future<MapViewport?> Function(bool request) position;
  final Future<void> Function(String text, Rect origin)? shareAction;
  final Future<void> Function(String uri)? linkAction;

  /// The feed's like toggle; null hides the heart.
  final Future<bool> Function(int postId, bool liked)? setLiked;

  /// Deletes one of my posts; null hides 삭제.
  final Future<void> Function(int postId)? deletePost;
  final _liking = <int>{};
  final PlaceDetailModel model;
  MapViewport? _position;
  bool _disposed = false;
  int _request = 0;

  Future<void> load() async {
    final request = ++_request;
    model.update(() {
      model.loading = true;
      model.detailError = false;
      model.contextError = false;
    });
    try {
      final place = await places.details(initialPlace);
      if (_disposed || request != _request) return;
      // "Recently viewed" is best effort: never awaited, never surfaced.
      if (place.id != null) {
        unawaited(profile?.recordView(place.id!).catchError((_) {}));
      }
      model.update(() {
        model.place = place;
        model.loading = false;
        if (_position != null) {
          model.distance = LocationService.distance(_position!, place);
        }
      });
      if (place.id != null && context != null) {
        try {
          final social = await context!.load(place.id!);
          if (_disposed || request != _request) return;
          model.update(() {
            model.social = social;
            model.saved = social.saved;
          });
        } catch (_) {
          if (!_disposed && request == _request) {
            model.update(() => model.contextError = true);
          }
        }
      }
    } catch (_) {
      if (!_disposed && request == _request) {
        model.update(() {
          model.loading = false;
          model.detailError = true;
        });
      }
    }
  }

  Future<String?> locate(bool request) async {
    if (model.locating) return null;
    model.update(() => model.locating = true);
    try {
      final position = await this.position(request);
      if (_disposed) return null;
      if (position != null) {
        _position = position;
        model.update(() {
          model.distance = LocationService.distance(position, model.place);
        });
      } else if (request) {
        return '거리 표시는 위치 권한과 기기 위치 서비스가 필요해요.';
      }
    } catch (_) {
      if (!_disposed && request) return '현재 위치를 확인하지 못했어요.';
    } finally {
      if (!_disposed) model.update(() => model.locating = false);
    }
    return null;
  }

  Future<String?> save() async {
    if (model.saving) return null;
    final place = model.place;
    if (place.id == null || !place.hasRichContent) {
      return '이 출처의 장소 저장은 아직 지원하지 않아요. 원본 지도에서 확인해 주세요.';
    }
    if (model.social == null || context == null) {
      return '저장 기능을 연결하지 못했어요. 상세 정보를 다시 불러와 주세요.';
    }
    final before = model.saved;
    model.update(() {
      model.saving = true;
      model.saved = !before;
    });
    try {
      await context!.setSaved(place.id!, !before);
    } catch (_) {
      if (!_disposed) {
        model.update(() => model.saved = before);
        return '저장하지 못했어요. 다시 시도해 주세요.';
      }
    } finally {
      if (!_disposed) model.update(() => model.saving = false);
    }
    return null;
  }

  /// Optimistic; a refusal reverts it and returns a message.
  Future<String?> toggleLike(PlacePost post) async {
    final id = post.id;
    if (id == null || setLiked == null || !_liking.add(id)) return null;
    final before = model.shown(post);
    model.update(() => model.likes[id] = before.withLike(!before.liked));
    try {
      await setLiked!(id, !before.liked);
      return null;
    } catch (_) {
      if (_disposed) return null;
      model.update(() => model.likes[id] = before);
      return '좋아요를 반영하지 못했어요. 다시 시도해 주세요.';
    } finally {
      _liking.remove(id);
    }
  }

  /// Removes my post from the sheet once the server confirms.
  Future<String?> delete(PlacePost post) async {
    final id = post.id;
    if (id == null || deletePost == null || !post.mine) return null;
    try {
      await deletePost!(id);
    } catch (caught) {
      return caught is PlaceFailure ? caught.message : '게시물을 삭제하지 못했어요.';
    }
    if (!_disposed) model.update(() => model.deleted.add(id));
    return null;
  }

  Future<String?> openLink(String raw) async {
    try {
      if (linkAction != null) {
        await linkAction!(raw);
      } else if (!await PlaceActionService.openLink(raw)) {
        return '링크를 열지 못했어요. 다시 시도해 주세요.';
      }
    } catch (_) {
      return '링크를 열지 못했어요. 다시 시도해 주세요.';
    }
    return null;
  }

  Future<String?> share(Rect origin) async {
    final place = model.place;
    final text = '${place.name}\n${place.mapsUri}';
    try {
      if (shareAction != null) {
        await shareAction!(text, origin);
      } else {
        await PlaceActionService.share(text, place.name, origin);
      }
    } catch (_) {
      return '공유 창을 열지 못했어요.';
    }
    return null;
  }

  void dispose() {
    _disposed = true;
    _request++;
    model.dispose();
  }
}
