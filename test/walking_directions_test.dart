import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:pind_flutter/model/place_search_result.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/view/explore/explore_screen.dart';

const place = Place(
  id: 7,
  provider: PlaceProvider.sbiz,
  externalId: 'p7',
  name: '화담면옥',
  category: '냉면/밀면',
  address: '경북 포항시 북구',
  latitude: 37.5010,
  longitude: 127.0010,
  mapsUri: 'https://example.com',
);

void main() {
  testWidgets(
    '길찾기 draws the walk, counts down as I move, and ends on arrival',
    (tester) async {
      final bodies = <Map<String, dynamic>>[];
      final moves = StreamController<MapViewport>();
      addTearDown(moves.close);
      final explore = ExploreController(
        PlaceService((body) async {
          bodies.add(body);
          if (body['action'] != 'walking_route') return {'places': <dynamic>[]};
          // An L: ~111m north, ~88m east; TMAP says 200m in 150s.
          return {
            'points': [
              [37.5000, 127.0000],
              [37.5010, 127.0000],
              [37.5010, 127.0010],
            ],
            'meters': 200,
            'seconds': 150,
          };
        }),
        position: (_) async => const MapViewport(37.5000, 127.0000),
        track: () => moves.stream,
      );
      addTearDown(explore.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(
            controller: explore,
            mapsEnabled: false,
            onEditPreferences: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('map-search-button')), findsOneWidget);

      explore.walkTo(place);
      await tester.pump();
      expect(find.text('화담면옥까지 도보'), findsOneWidget);
      expect(find.byKey(const ValueKey('map-search-button')), findsNothing);
      await tester.pumpAndSettle();
      expect(bodies.last, {
        'action': 'walking_route',
        'fromLatitude': 37.5,
        'fromLongitude': 127.0,
        'toLatitude': 37.501,
        'toLongitude': 127.001,
      });
      expect(find.text('199m · 약 2분'), findsOneWidget);

      // Halfway up the first leg: the walked half no longer counts.
      moves.add(const MapViewport(37.5005, 127.0000));
      await tester.pump();
      await tester.pump();
      expect(find.text('144m · 약 2분'), findsOneWidget);

      moves.add(const MapViewport(37.5010, 127.00095));
      await tester.pump();
      await tester.pump();
      expect(find.text('도착했어요'), findsOneWidget);
      await tester.tap(find.text('닫기'));
      await tester.pump();
      expect(explore.model.walkingTo, isNull);
      expect(find.byKey(const ValueKey('map-search-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a failed route says why and gives the search bar back', (
    tester,
  ) async {
    final explore = ExploreController(
      PlaceService((body) async {
        if (body['action'] == 'walking_route') {
          throw const PlaceFailure('걸어가기엔 너무 멀어요.');
        }
        return {'places': <dynamic>[]};
      }),
      position: (_) async => const MapViewport(37.5, 127.0),
      track: () => const Stream.empty(),
    );
    addTearDown(explore.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ExploreScreen(
          controller: explore,
          mapsEnabled: false,
          onEditPreferences: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    explore.walkTo(place);
    await tester.pumpAndSettle();
    expect(find.text('걸어가기엔 너무 멀어요.'), findsOneWidget);
    expect(explore.model.walkingTo, isNull);
    expect(find.byKey(const ValueKey('walk-banner')), findsNothing);
    expect(find.byKey(const ValueKey('map-search-button')), findsOneWidget);
  });
}
