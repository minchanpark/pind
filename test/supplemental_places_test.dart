import 'package:pind_flutter/controllers/place_detail_controller.dart';
import 'package:pind_flutter/model/place_search_result.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:pind_flutter/view/explore/place_sheet.dart';

Map<String, dynamic> fixture(String provider, {String name = '검증용 카페'}) => {
  'provider': provider,
  'externalPlaceId': '123',
  'name': name,
  'category': '카페',
  'address': '서울 테스트로 1',
  'latitude': 37.51,
  'longitude': 127.01,
  'sourceUri': 'https://place.map.kakao.com/123',
};

void main() {
  test('provider IDs cannot collide and unknown providers are rejected', () {
    expect(
      Place.fromJson(fixture('kakao_local')).key,
      isNot(Place.fromJson(fixture('google_places')).key),
    );
    expect(() => Place.fromJson(fixture('unknown')), throwsFormatException);
  });
  test('supplemental payload cannot acquire Google content or internal ID', () {
    final place = Place.fromJson({
      ...fixture('kakao_local'),
      'internalId': 42,
      'heroImageUrl': 'https://example.com/photo',
      'editorialSummary': 'untrusted',
      'isOpenNow': true,
      'weekdayDescriptions': ['11:00–21:00'],
    });
    expect(place.id, isNull);
    expect(place.imageUrl, isNull);
    expect(place.summary, isNull);
    expect(place.isOpen, isNull);
    expect(place.hours, isEmpty);
  });
  test('basic detail never invokes Google resolve/detail', () async {
    final repository = PlaceService(
      (_) async => throw StateError('unexpected API'),
    );
    for (final provider in ['kakao_local', 'naver_local']) {
      final place = Place.fromJson(fixture(provider));
      expect(await repository.details(place), same(place));
    }
  });
  test('explicit Google search preserves catalog results and deduplicates provider IDs', () async {
    final actions = <String>[];
    final controller = ExploreController(
      PlaceService((body) async {
        actions.add(body['action'] as String);
        if (body['action'] == 'search') {
          expect(body['userInitiated'], isNull);
          return {
            'places': [fixture('sbiz')],
            'googleSearchEnabled': true,
          };
        }
        return {
          'places': [fixture('google_places')],
          'notice': '보완 결과',
          'googleSearchEnabled': true,
        };
      }),
    );
    await controller.search('서울 카페');
    await controller.searchGoogle();
    await controller.searchGoogle();
    expect(controller.places, hasLength(2));
    expect(controller.places.first.isCatalog, true);
    expect(controller.notice, '보완 결과');
    expect(actions, ['search', 'google_search', 'google_search']);
    controller.dispose();
  });
  test('Google failure preserves primary results', () async {
    final controller = ExploreController(
      PlaceService((body) async {
        if (body['action'] == 'google_search') throw const PlaceFailure('429');
        return {
          'places': [fixture('google_places')],
          'googleSearchEnabled': true,
        };
      }),
    );
    await controller.search('서울 카페');
    await controller.searchGoogle();
    expect(controller.places.single.isGoogle, true);
    expect(controller.error, '429');
    controller.dispose();
  });
  test('late Google response cannot overwrite a newer query', () async {
    final pending = Completer<Map<String, dynamic>>();
    final controller = ExploreController(
      PlaceService((body) async {
        if (body['action'] == 'google_search') return pending.future;
        return {
          'places': [fixture('google_places', name: body['query'] as String)],
          'googleSearchEnabled': true,
        };
      }),
    );
    await controller.search('이전 검색');
    final stale = controller.searchGoogle();
    await controller.search('새로운 검색');
    pending.complete({
      'places': [fixture('kakao_local')],
    });
    await stale;
    expect(controller.places.single.name, '새로운 검색');
    controller.dispose();
  });
  test(
    'old or disabled server does not enable supplemental API requests',
    () async {
      var calls = 0;
      final controller = ExploreController(
        PlaceService((body) async {
          calls++;
          return {
            'places': [fixture('google_places')],
          };
        }),
      );
      await controller.search('서울 카페');
      await controller.searchGoogle();
      expect(calls, 1);
      expect(controller.googleSearchEnabled, false);
      controller.dispose();
    },
  );

  for (final provider in ['kakao_local', 'naver_local']) {
    testWidgets('$provider detail has no introduction or photos at 320px', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceSheet(
              controller: PlaceDetailController(
                place: Place.fromJson(fixture(provider)),
                places: PlaceService(
                  (_) async => throw StateError('unexpected API'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('운영시간 확인 필요'), findsOneWidget);
      expect(find.text('소개'), findsNothing);
      expect(find.byType(Image), findsNothing);
      expect(
        find.text(provider == 'kakao_local' ? '카카오맵에서 확인' : '네이버 지도에서 검색'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
