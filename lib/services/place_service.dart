import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/nearby_ranking.dart';
import '../model/places.dart';
import '../model/preferences.dart';
import '../model/walking_route.dart';
import '../model/place_search_result.dart';
import '../l10n/l10n.dart';

typedef PlacesInvoker = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> body,
);

class PlaceService {
  PlaceService(this.invoke);
  final PlacesInvoker invoke;

  /// Every restaurant with a published post; the map needs nothing else.
  Future<List<Place>> posted() async =>
      _list(await invoke({'action': 'posted'}));

  Future<List<Place>> search(String query) async {
    return (await searchResults(query)).places;
  }

  Future<PlaceSearchResult> searchResults(
    String query, {
    bool supplemental = false,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const PlaceSearchResult([]);
    if (trimmed.length < 2 || trimmed.length > 120) {
      throw PlaceFailure(l10n.errQueryLength);
    }
    final data = await invoke({
      'action': supplemental ? 'google_search' : 'search',
      'query': trimmed,
      'languageCode': googleLanguage(l10nTag),
      if (supplemental) 'userInitiated': true,
    });
    return PlaceSearchResult(
      _list(data),
      notice: data['notice'] as String?,
      googleSearchEnabled: data['googleSearchEnabled'] == true,
    );
  }

  /// Taste-based agent search: the server reads the sentence with Gemini and
  /// ranks posted places by matched terms, my taste, then distance from
  /// [near]. [notice] is how it read the sentence.
  /// [taste]'s foods and occasions let "내가 좋아할만한 곳" pick for me; the
  /// server already knows my priorities.
  Future<AgentAnswer> agentSearch(
    String query, {
    MapViewport? near,
    TastePreferences? taste,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2 || trimmed.length > 120) {
      throw PlaceFailure(l10n.errQueryLength);
    }
    final data = await invoke({
      'action': 'agent_search',
      'query': trimmed,
      'latitude': ?near?.latitude,
      'longitude': ?near?.longitude,
      if (taste != null) ...{
        'cuisines': [for (final c in taste.cuisines) c.name],
        'occasions': [for (final o in taste.occasions) o.name],
      },
      // The AI's reading comes back in the app's language.
      'lang': l10nTag,
    });
    final label = data['label'] as String?;
    final foods = [
      for (final c in Cuisine.values)
        if (taste?.cuisines.contains(c) ?? false) c.label,
    ];
    return (
      notice: data['personal'] == true
          ? (foods.isEmpty
                ? l10n.agentNoticeTaste
                : l10n.agentNoticeTasteFoods(foods.join(' · ')))
          : label != null && label.isNotEmpty
          ? l10n.agentNotice(label)
          : data['notice'] as String?,
      places: [
        for (final p in data['places'] as List? ?? [])
          RankedPlace.fromJson(Map<String, dynamic>.from(p as Map)),
      ],
    );
  }

  /// TMAP walking directions from [from] to [to].
  Future<WalkingRoute> walkingRoute(MapViewport from, Place to) async =>
      WalkingRoute.fromJson(
        await invoke({
          'action': 'walking_route',
          'fromLatitude': from.latitude,
          'fromLongitude': from.longitude,
          'toLatitude': to.latitude,
          'toLongitude': to.longitude,
        }),
      );

  Future<Place> details(Place place) async {
    if (place.isCatalog) {
      final data = await invoke({
        'action': 'catalog_detail',
        'internalPlaceId': place.id,
        // The AI summary comes back in the app's language.
        'lang': l10nTag == 'zh' ? 'zh-Hans' : l10nTag,
      });
      return Place.fromJson(Map<String, dynamic>.from(data['place'] as Map));
    }
    if (!place.isGoogle) return place;
    final resolved = place.id == null
        ? Place.fromJson(
            Map<String, dynamic>.from(
              (await invoke({
                    'action': 'resolve',
                    'userInitiated': true,
                    'externalPlaceId': place.externalId,
                  }))['place']
                  as Map,
            ),
          )
        : place;
    if (resolved.id == null) throw PlaceFailure(l10n.errPlaceCheck);
    return Place.fromJson(
      Map<String, dynamic>.from(
        (await invoke({
              'action': 'detail',
              'userInitiated': true,
              'internalPlaceId': resolved.id,
            }))['place']
            as Map,
      ),
    );
  }

  List<Place> _list(Map<String, dynamic> data) =>
      (data['places'] as List? ?? [])
          .map((p) => Place.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
}

class SupabasePlacesGateway {
  SupabasePlacesGateway(this.client, {required this.allowAnonymous});
  final SupabaseClient client;
  final bool allowAnonymous;
  Future<void>? _sessionInFlight;

  Future<void> _authenticate() async {
    if (client.auth.currentSession != null) return;
    if (!allowAnonymous) throw PlaceFailure(l10n.errPlaceSignIn);
    final result = await client.auth.signInAnonymously();
    if (result.session == null) throw PlaceFailure(l10n.errSessionStart);
  }

  Future<Map<String, dynamic>> call(Map<String, dynamic> body) async {
    _sessionInFlight ??= _authenticate();
    try {
      await _sessionInFlight;
    } finally {
      _sessionInFlight = null;
    }
    try {
      final response = await client.functions.invoke(
        ['google_search', 'resolve', 'detail'].contains(body['action'])
            ? 'google-places'
            : 'places',
        body: body,
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['error'] case final Map error) {
        throw PlaceFailure(
          serverErrorMessage(error['code'], l10n.errPlaceLoad),
        );
      }
      return data;
    } on FunctionException catch (error) {
      final details = error.details;
      final remoteError = details is Map ? details['error'] : null;
      throw PlaceFailure(
        serverErrorMessage(
          remoteError is Map ? remoteError['code'] : null,
          l10n.errPlaceServer,
        ),
      );
    }
  }
}

/// The places functions answer errors with a code and a Korean message; the
/// user sees the code's message in the app's language instead.
String serverErrorMessage(Object? code, String fallback) => switch (code) {
  'UNAUTHORIZED' => l10n.errSignInRequired,
  'INVALID_QUERY' => l10n.errQueryLength,
  'QUERY_NOT_UNDERSTOOD' => l10n.errQueryNotUnderstood,
  'INVALID_VIEWPORT' => l10n.errOutsideKoreaMap,
  'INVALID_PLACE' || 'PLACE_NOT_FOUND' => l10n.errPlaceNotFound,
  'CATALOG_UNAVAILABLE' => l10n.errPlaceServerRetry,
  'INVALID_ROUTE' => l10n.errRouteKoreaOnly,
  'ROUTE_TOO_FAR' => l10n.errRouteTooFar,
  'ROUTE_UNAVAILABLE' => l10n.errRouteUnavailable,
  'ROUTE_FAILED' => l10n.errWalkRoute,
  'GOOGLE_RATE_LIMITED' => l10n.errGoogleBusy,
  _ => fallback,
};

/// Google Places' code for the app's language.
String googleLanguage(String tag) => switch (tag) {
  'zh' || 'zh-Hans' => 'zh-CN',
  'zh-Hant' => 'zh-TW',
  _ => tag,
};
