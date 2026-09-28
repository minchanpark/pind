import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/places.dart';
import '../model/place_search_result.dart';

typedef PlacesInvoker = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> body,
);

class PlaceService {
  PlaceService(this.invoke);
  final PlacesInvoker invoke;

  Future<List<Place>> nearby(MapViewport viewport) async {
    if (!viewport.inKorea) throw const PlaceFailure('대한민국 안에서 지도를 이동해 주세요.');
    return _list(
      await invoke({
        'action': 'nearby',
        'latitude': viewport.latitude,
        'longitude': viewport.longitude,
        'radiusMeters': viewport.radiusMeters,
        'languageCode': 'ko',
      }),
    );
  }

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
      throw const PlaceFailure('검색어를 2~120자로 입력해 주세요.');
    }
    final data = await invoke({
      'action': supplemental ? 'google_search' : 'search',
      'query': trimmed,
      'languageCode': 'ko',
      if (supplemental) 'userInitiated': true,
    });
    return PlaceSearchResult(
      _list(data),
      notice: data['notice'] as String?,
      googleSearchEnabled: data['googleSearchEnabled'] == true,
    );
  }

  Future<Place> details(Place place) async {
    if (place.isCatalog) {
      final data = await invoke({
        'action': 'catalog_detail',
        'internalPlaceId': place.id,
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
    if (resolved.id == null) throw const PlaceFailure('장소를 확인하지 못했어요.');
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
    if (!allowAnonymous) throw const PlaceFailure('장소를 탐색하려면 로그인이 필요해요.');
    final result = await client.auth.signInAnonymously();
    if (result.session == null) throw const PlaceFailure('세션을 시작하지 못했어요.');
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
      if (data['error'] != null) {
        throw PlaceFailure(
          data['error']['message'] as String? ?? '장소를 불러오지 못했어요.',
        );
      }
      return data;
    } on FunctionException catch (error) {
      final details = error.details;
      final remoteError = details is Map ? details['error'] : null;
      final message = remoteError is Map ? remoteError['message'] : null;
      throw PlaceFailure(message is String ? message : '장소 서버에 연결하지 못했어요.');
    }
  }
}
