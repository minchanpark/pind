import 'package:pind_flutter/model/place_search_result.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:pind_flutter/l10n/l10n.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';

Map<String, dynamic> payload(String name, {int? id}) => {
  'internalId': id,
  'externalPlaceId': 'external-$name',
  'name': name,
  'category': '카페',
  'address': '서울',
  'latitude': 37.5,
  'longitude': 127,
  'googleMapsUri': 'https://maps.google.com/',
};

void main() {
  test('English address outside Korean, Korean kept beside', () {
    final json = {
      'provider': 'sbiz',
      'internalId': 1,
      'externalPlaceId': 'a',
      'name': '란칼국수',
      'category': '한식',
      'address': '서울특별시 성동구 성수일로8길 42',
      'addressEn': '42 Seongsuil-ro 8-gil, Seongdong-gu, Seoul',
      'latitude': 37.5,
      'longitude': 127.0,
      'sourceUri': 'https://example.com',
    };
    final ko = Place.fromJson(json);
    expect((ko.address, ko.nativeAddress), ('서울특별시 성동구 성수일로8길 42', null));
    setL10nLocale(const Locale('en'));
    addTearDown(() => setL10nLocale(const Locale('ko')));
    final en = Place.fromJson(json);
    expect(en.name, '란칼국수');
    expect(en.address, '42 Seongsuil-ro 8-gil, Seongdong-gu, Seoul');
    expect(en.nativeAddress, '서울특별시 성동구 성수일로8길 42');
    // No juso match: Korean only, nothing repeated underneath.
    final plain = Place.fromJson({...json, 'addressEn': null});
    expect((plain.address, plain.nativeAddress), ('서울특별시 성동구 성수일로8길 42', null));
  });

  test('Korea bounds', () {
    expect(MapViewport.seoul.inKorea, true);
    expect(const MapViewport(33.3, 126.5).inKorea, true);
    expect(const MapViewport(35, 139).inKorea, false);
  });

  test(
    'search candidate resolves before details, internal ID is preserved',
    () async {
      final calls = <Map<String, dynamic>>[];
      final repo = PlaceService((body) async {
        calls.add(body);
        return {'place': payload('선택한 카페', id: 27)};
      });
      final result = await repo.details(Place.fromJson(payload('검색 카페')));
      expect(calls[0], {
        'action': 'resolve',
        'externalPlaceId': 'external-검색 카페',
        'userInitiated': true,
      });
      expect(calls[1], {
        'action': 'detail',
        'internalPlaceId': 27,
        'userInitiated': true,
      });
      expect(result.id, 27);
    },
  );

  test('late viewport response cannot replace a newer search', () async {
    final old = Completer<Map<String, dynamic>>();
    final repo = PlaceService(
      (body) => body['action'] == 'posted'
          ? old.future
          : Future.value({
              'places': [payload('new')],
            }),
    );
    final controller = ExploreController(repo);
    final first = controller.load();
    await controller.search('new');
    old.complete({
      'places': [payload('old')],
    });
    await first;
    expect(controller.places.single.name, 'new');
    expect(controller.loading, false);
    controller.dispose();
  });

  test('failed request is retryable and posted places load once', () async {
    var calls = 0;
    final controller = ExploreController(
      PlaceService((body) async {
        if (++calls == 1) throw const PlaceFailure('failed');
        return {'places': []};
      }),
    );
    await controller.load();
    expect(controller.error, 'failed');
    await controller.load();
    await controller.load();
    expect(calls, 2);
    expect(controller.error, null);
    controller.dispose();
  });

  test('disposed controller ignores in-flight completion', () async {
    final pending = Completer<Map<String, dynamic>>();
    final controller = ExploreController(
      PlaceService((body) => pending.future),
    );
    final request = controller.load();
    controller.dispose();
    pending.complete({'places': []});
    await request;
  });
}
