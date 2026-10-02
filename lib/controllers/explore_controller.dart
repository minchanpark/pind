import '../model/place_search_result.dart';
import '../model/explore_model.dart';
import '../model/nearby_ranking.dart';
import '../model/preferences.dart';
import '../services/place_context_service.dart';
import '../services/location_service.dart';
import '../services/nearby_ranking_service.dart';
import '../services/profile_service.dart';
import 'place_detail_controller.dart';

import '../services/place_service.dart';
import '../model/places.dart';

class ExploreController {
  ExploreController(
    this.repository, {
    this.placeContext,
    this.profile,
    this.nearby,
    this.position = LocationService.position,
    this.setLiked,
    this.deletePost,
  });
  final PlaceService repository;
  final PlaceContextService? placeContext;
  final ProfileService? profile;

  /// Category list source; null hides the list.
  final NearbyRanking? nearby;
  final Future<MapViewport?> Function(bool request) position;

  /// Post likes, shared with the feed.
  final Future<bool> Function(int postId, bool liked)? setLiked;
  final Future<void> Function(int postId)? deletePost;
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
        profile: profile,
        setLiked: setLiked,
        deletePost: deletePost,
      );

  Future<MapViewport> locate() async {
    model.update(() => model.locating = true);
    try {
      return await LocationService.mapPosition();
    } finally {
      if (!_disposed) model.update(() => model.locating = false);
    }
  }

  /// Places within 10km of me, or of [fallback] (the map center) when my
  /// location is off; `nearMe` says which. Never prompts for permission.
  Future<({List<RankedPlace> places, bool nearMe})> nearbyRanking(
    MapViewport fallback,
  ) async {
    MapViewport? here;
    try {
      here = await position(false);
    } catch (_) {}
    return (places: await nearby!(here ?? fallback), nearMe: here != null);
  }

  String? _searchQuery;
  int _request = 0;
  MapViewport _viewport = MapViewport.seoul;
  MapViewport get viewport => _viewport;
  int publishedRevision = 0;
  bool _disposed = false;
  List<Place>? _posted;

  /// Posted places are fetched once; camera moves never hit the catalog.
  Future<void> load({bool force = false}) async {
    _searchQuery = null;
    final cached = _posted;
    if (!force && cached != null) {
      _request++;
      model.update(() {
        model.places = cached;
        model.error = null;
        model.notice = null;
        model.loading = false;
      });
      return;
    }
    await _run(
      () async => PlaceSearchResult(_posted = await repository.posted()),
    );
  }

  Future<void> search(String query) async {
    _searchQuery = query.trim();
    await _run(() => repository.searchResults(query));
  }

  /// The agent page's sentence, ranked for me around [near]. Answers on the
  /// page itself; the map is left as it was.
  Future<AgentAnswer> agentSearch(String query, MapViewport near) =>
      repository.agentSearch(query, near: near);

  Future<void> showPublishedPlace(int placeId) async {
    _searchQuery = null;
    await _run(() async {
      final data = await repository.invoke({
        'action': 'catalog_detail',
        'internalPlaceId': placeId,
      });
      if (_disposed) return const PlaceSearchResult([]);
      final place = Place.fromJson(
        Map<String, dynamic>.from(data['place'] as Map),
      );
      _viewport = MapViewport(place.latitude, place.longitude);
      final places = _posted = await repository.posted();
      publishedRevision++;
      return PlaceSearchResult(places);
    });
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
