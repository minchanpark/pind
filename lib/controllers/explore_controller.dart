import '../model/place_search_result.dart';
import '../model/explore_model.dart';
import '../model/preferences.dart';
import '../services/place_context_service.dart';
import '../services/location_service.dart';
import 'place_detail_controller.dart';

import '../services/place_service.dart';
import '../model/places.dart';

class ExploreController {
  ExploreController(this.repository, {this.placeContext});
  final PlaceService repository;
  final PlaceContextService? placeContext;
  final model = ExploreModel();
  List<Place> get places => model.places;
  bool get loading => model.loading;
  String? get error => model.error;
  String? get notice => model.notice;
  bool get googleSearchEnabled => model.googleSearchEnabled;

  PlaceDetailController details(Place place, TastePreferences? preferences) =>
      PlaceDetailController(
        place: place,
        places: repository,
        context: placeContext,
        preferences: preferences,
      );

  Future<MapViewport> locate() async {
    model.update(() => model.locating = true);
    try {
      return await LocationService.mapPosition();
    } finally {
      if (!_disposed) model.update(() => model.locating = false);
    }
  }

  String? _searchQuery;
  int _request = 0;
  bool _disposed = false;
  String? _lastKey;

  Future<void> load(MapViewport viewport, {bool force = false}) async {
    if (!force && viewport.queryKey == _lastKey) return;
    _lastKey = viewport.queryKey;
    _searchQuery = null;
    await _run(
      () async => PlaceSearchResult(await repository.nearby(viewport)),
    );
  }

  Future<void> search(String query) async {
    _lastKey = null;
    _searchQuery = query.trim();
    await _run(() => repository.searchResults(query));
  }

  Future<void> searchGoogle() async {
    final query = _searchQuery;
    if (query == null || query.isEmpty || loading || !googleSearchEnabled) {
      return;
    }
    final previous = List<Place>.of(places);
    await _run(() async {
      final result = await repository.searchResults(query, supplemental: true);
      final merged = {for (final p in previous) p.key: p};
      for (final p in result.places) {
        merged[p.key] = p;
      }
      return PlaceSearchResult(
        merged.values.toList(),
        notice: result.notice,
        googleSearchEnabled: result.googleSearchEnabled,
      );
    }, preservePlaces: true);
  }

  Future<void> _run(
    Future<PlaceSearchResult> Function() action, {
    bool preservePlaces = false,
  }) async {
    final request = ++_request;
    model.update(() {
      model.loading = true;
      model.error = null;
      model.notice = null;
      if (!preservePlaces) model.places = [];
    });
    try {
      final result = await action();
      if (_disposed || request != _request) return;
      model.places = result.places;
      model.notice = result.notice;
      model.googleSearchEnabled = result.googleSearchEnabled;
    } catch (caught) {
      if (_disposed || request != _request) return;
      _lastKey = null;
      model.error = caught is PlaceFailure
          ? caught.message
          : '연결을 확인하고 다시 시도해 주세요.';
    } finally {
      if (!_disposed && request == _request) {
        model.update(() => model.loading = false);
      }
    }
  }

  void dispose() {
    _disposed = true;
    _request++;
    model.dispose();
  }
}
