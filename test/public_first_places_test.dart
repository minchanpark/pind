import 'package:pind_flutter/model/place_search_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/model/places.dart';

Map<String, dynamic> catalog(String provider) => {
  'provider': provider,
  'internalId': 93,
  'externalPlaceId': 'public-id',
  'name': '공공 카페',
  'category': '카페',
  'address': '서울',
  'latitude': 37.56,
  'longitude': 126.97,
  'sourceUri': 'https://www.google.com/maps/search/?api=1&query=37.56,126.97',
  'sourceDate': '2026-06-30',
};

void main() {
  for (final provider in ['sbiz', 'pind']) {
    test(
      '$provider keeps internal ID and never invents unknown content',
      () async {
        final place = Place.fromJson(catalog(provider));
        expect(place.id, 93);
        expect(place.isCatalog, isTrue);
        expect(place.canShowOnMap, isTrue);
        expect(place.imageUrl, isNull);
        expect(place.summary, isNull);
        expect(place.hours, isEmpty);
        expect(place.isOpen, isNull);
        final calls = <Map<String, dynamic>>[];
        final repo = PlaceService((body) async {
          calls.add(body);
          return {'place': catalog(provider)};
        });
        expect((await repo.details(place)).id, 93);
        expect(calls, [
          {'action': 'catalog_detail', 'internalPlaceId': 93},
        ]);
      },
    );
  }
  test(
    'empty and failed catalog results never automatically request Google',
    () async {
      for (final fail in [false, true]) {
        final calls = <String>[];
        final repo = PlaceService((body) async {
          calls.add(body['action'] as String);
          if (fail) throw const PlaceFailure('catalog unavailable');
          return {'places': [], 'googleSearchEnabled': true};
        });
        if (fail) {
          await expectLater(repo.search('없는 장소'), throwsA(isA<PlaceFailure>()));
        } else {
          expect(await repo.search('없는 장소'), isEmpty);
        }
        expect(calls, ['search']);
      }
    },
  );
  test('explicit Google search carries user intent without automatic photo request', () async {
    final calls = <Map<String, dynamic>>[];
    final repo = PlaceService((body) async {
      calls.add(body);
      return {'places': [], 'googleSearchEnabled': true};
    });
    await repo.searchResults('추가 장소', supplemental: true);
    expect(calls.single['action'], 'google_search');
    expect(calls.single['userInitiated'], isTrue);
    expect(calls, hasLength(1));
  });
}
