import 'dart:async';

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
import '../l10n/l10n.dart';
import '../services/data_revision.dart';
import '../services/request_client.dart';

class ExploreController {
  ExploreController(
    this.repository, {
    this.placeContext,
    this.profile,
    this.nearby,
    this.position = LocationService.position,
    this.track = LocationService.track,
    this.setLiked,
    this.deletePost,
  }) {
    _deletions = postDeletions.stream.listen((_) {
      _posted = null;
      if (!_disposed && _searchQuery == null) {
        unawaited(load(force: true, bounds: _postedBounds));
      }
    });
  }
  late final StreamSubscription<int> _deletions;
  final PlaceService repository;
  final PlaceContextService? placeContext;
  final ProfileService? profile;

  /// Category list source; null hides the list.
  final NearbyRanking? nearby;
  final Future<MapViewport?> Function(bool request) position;

  /// Live position for walking directions.
  final Stream<MapViewport> Function() track;

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
        directions: walkTo,
      );

  /// Place ids behind a map chip; empty without a backend.
  Future<Set<int>> scopePlaces(MapScope scope) async =>
      await placeContext?.scopePlaces(scope) ?? {};

  /// 길찾기: the map draws the walk to [place] (the shell shows the map).
  void walkTo(Place place) => model.update(() => model.walkingTo = place);
  void endWalk() => model.update(() => model.walkingTo = null);

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
  Completer<void>? _abort;

  void _cancelRequest() {
    if (_abort != null && !_abort!.isCompleted) _abort!.complete();
  }

  MapViewport _viewport = MapViewport.seoul;
  MapViewport get viewport => _viewport;
  int publishedRevision = 0;
  bool _disposed = false;
  List<Place>? _posted;
  int _postedRevision = -1;
  MapBounds? _postedBounds;

  void resetForAccount() {
    _cancelRequest();
    _posted = null;
    _request++;
    model.update(() {
      model.places = [];
      model.walkingTo = null;
      model.loading = false;
      model.error = null;
    });
  }

  /// Reuse pins for the same visible bounds until published data changes.
  Future<void> load({bool force = false, MapBounds? bounds}) async {
    _searchQuery = null;
    final cached = _posted;
    if (!force &&
        cached != null &&
        _postedRevision == dataRevision &&
        bounds == _postedBounds) {
      _cancelRequest();
      _request++;
      model.update(() {
        model.places = cached;
        model.error = null;
        model.notice = null;
        model.loading = false;
      });
      return;
    }
    final request = _request + 1;
    await _run(() async {
      final revision = dataRevision;
      final places = await repository.posted(bounds: bounds);
      if (!_disposed && request == _request) {
        _posted = places;
        _postedRevision = revision;
        _postedBounds = bounds;
      }
      return PlaceSearchResult(places);
    }, preservePlaces: bounds != null);
  }

  Future<void> search(String query) async {
    _searchQuery = query.trim();
    await _run(() => repository.searchResults(query));
  }

  /// The agent page's sentence, ranked for me around [near]. Answers on the
  /// page itself; the map is left as it was.
  Future<AgentAnswer> agentSearch(
    String query,
    MapViewport near, {
    TastePreferences? taste,
  }) => repository.agentSearch(query, near: near, taste: taste);

  Future<void> showPublishedPlace(int placeId) async {
    _searchQuery = null;
    final request = _request + 1;
    await _run(() async {
      final data = await repository.invoke({
        'action': 'catalog_detail',
        'internalPlaceId': placeId,
      });
      if (_disposed || request != _request) return const PlaceSearchResult([]);
      final place = Place.fromJson(
        Map<String, dynamic>.from(data['place'] as Map),
      );
      _viewport = MapViewport(place.latitude, place.longitude);
      final bounds = MapBounds(
        place.latitude - .03,
        place.longitude - .03,
        place.latitude + .03,
        place.longitude + .03,
      );
      final places = await repository.posted(bounds: bounds);
      if (_disposed || request != _request) return const PlaceSearchResult([]);
      _posted = places;
      _postedBounds = bounds;
      _postedRevision = dataRevision;
      publishedRevision++;
      return PlaceSearchResult(places);
    }, preservePlaces: true);
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
    _cancelRequest();
    final abort = _abort = Completer<void>();
    final request = ++_request;
    model.update(() {
      model.loading = true;
      model.error = null;
      model.notice = null;
      if (!preservePlaces) model.places = [];
    });
    try {
      final result = await withRequestCancellation(abort.future, action);
      if (_disposed || request != _request) return;
      model.places = result.places;
      model.notice = result.notice;
      model.googleSearchEnabled = result.googleSearchEnabled;
    } catch (caught) {
      if (_disposed || request != _request) return;
      model.error = caught is PlaceFailure
          ? caught.message
          : l10n.errConnectionRetry;
    } finally {
      if (!_disposed && request == _request) {
        model.update(() => model.loading = false);
      }
    }
  }

  void dispose() {
    _disposed = true;
    _cancelRequest();
    _deletions.cancel();
    _request++;
    model.dispose();
  }
}
