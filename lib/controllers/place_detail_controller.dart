import 'dart:ui';

import '../model/place_detail_model.dart';
import '../model/place_search_result.dart';
import '../model/places.dart';
import '../model/preferences.dart';
import '../services/location_service.dart';
import '../services/place_action_service.dart';
import '../services/place_context_service.dart';
import '../services/place_service.dart';

class PlaceDetailController {
  PlaceDetailController({
    required Place place,
    required this.places,
    this.context,
    this.preferences,
    this.position = LocationService.position,
    this.shareAction,
    this.linkAction,
  }) : initialPlace = place,
       model = PlaceDetailModel(place);

  final Place initialPlace;
  final PlaceService places;
  final PlaceContextService? context;
  final TastePreferences? preferences;
  final Future<MapViewport?> Function(bool request) position;
  final Future<void> Function(String text, Rect origin)? shareAction;
  final Future<void> Function(String uri)? linkAction;
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

  Future<String?> searchGoogle({
    required Future<void> Function(List<Place>) onResults,
  }) async {
    if (model.searchingGoogle) return null;
    model.update(() => model.searchingGoogle = true);
    try {
      final raw = '${model.place.name} ${model.place.address}';
      final result = await places.searchResults(
        raw.length > 120 ? raw.substring(0, 120) : raw,
        supplemental: true,
      );
      if (_disposed) return null;
      if (result.places.isEmpty) return 'Google에서도 추가 정보를 찾지 못했어요.';
      await onResults(result.places);
    } on PlaceFailure catch (error) {
      if (!_disposed) return error.message;
    } catch (_) {
      if (!_disposed) {
        return 'Google 추가 검색을 불러오지 못했어요. 기본 정보는 계속 사용할 수 있어요.';
      }
    } finally {
      if (!_disposed) model.update(() => model.searchingGoogle = false);
    }
    return null;
  }

  PlaceDetailController forPlace(Place place) => PlaceDetailController(
    place: place,
    places: places,
    context: context,
    preferences: preferences,
    position: position,
    shareAction: shareAction,
    linkAction: linkAction,
  );

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
