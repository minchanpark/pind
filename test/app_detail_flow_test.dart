import 'package:pind_flutter/controllers/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pind_flutter/view/app.dart';
import 'package:pind_flutter/services/place_context_service.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/model/place_context.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/view/explore/place_sheet.dart';
import 'package:pind_flutter/view/navigation/pind_navigation_bar.dart';

import 'support/map_search.dart';

class _Context implements PlaceContextService {
  int? requestedId;
  @override
  Future<PlaceContext> load(int placeId) async {
    requestedId = placeId;
    return const PlaceContext(
      averages: {
        PreferenceCriterion.taste: 5,
        PreferenceCriterion.portion: 4,
        PreferenceCriterion.ambience: 5,
      },
    );
  }

  @override
  Future<void> setSaved(int placeId, bool saved) async {}
}

void main() {
  for (final provider in ['google_places', 'sbiz']) {
    testWidgets(
      '$provider normal app map result opens connected glass detail and returns to map',
      (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final store = PreferenceService(await SharedPreferences.getInstance());
        await store.save(
          TastePreferences(
            priorities: [
              PreferenceCriterion.taste,
              PreferenceCriterion.portion,
              PreferenceCriterion.ambience,
            ],
            cuisines: Cuisine.values.take(3),
          ),
        );
        final actions = <String>[];
        final contexts = _Context();
        final payload = <String, dynamic>{
          'provider': provider,
          'internalId': 71,
          'externalPlaceId': 'unit-test-place',
          'name': '연결 검증 가게',
          'category': 'cafe',
          'address': '서울',
          'latitude': 37.56,
          'longitude': 126.97,
          'googleMapsUri':
              'https://www.google.com/maps/search/?api=1&query=test',
          'isOpenNow': true,
          'userRatingCount': 12,
          'pindPostCount': 3,
          'googleSearchEnabled': provider == 'sbiz',
          'sourceDate': '2026-06-30',
        };
        await tester.pumpWidget(
          PindApp(
            controller: AppController(
              store,
              places: PlaceService((body) async {
                actions.add(body['action'] as String);
                return body['action'] == 'detail' ||
                        body['action'] == 'catalog_detail'
                    ? {'place': payload}
                    : {
                        'places': [payload],
                      };
              }),
              placeContext: contexts,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PindNavigationBar), findsOneWidget);
        expect(find.text('가게 상세 · 로컬 QA'), findsNothing);
        expect(find.textContaining('곳 보기'), findsNothing);
        await mapSearch(tester, '연결 검증 가게');
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();
        expect(find.byType(PlaceSheet), findsOneWidget);
        final detail = tester
            .widget<PlaceSheet>(find.byType(PlaceSheet))
            .controller;
        final requestsBeforeResize = actions.length;
        tester.view.physicalSize = const Size(402, 900);
        await tester.pumpAndSettle();
        expect(
          tester.widget<PlaceSheet>(find.byType(PlaceSheet)).controller,
          same(detail),
        );
        expect(actions, hasLength(requestsBeforeResize));
        expect(
          find.descendant(
            of: find.byType(PlaceSheet),
            matching: find.text('연결 검증 가게'),
          ),
          findsOneWidget,
        );
        expect(find.text('내 취향 93%'), findsOneWidget);
        expect(
          find.text(provider == 'sbiz' ? 'Pind 게시물 3개' : '리뷰 12개'),
          findsOneWidget,
        );
        expect(contexts.requestedId, 71);
        expect(actions, [
          'posted',
          'search',
          provider == 'sbiz' ? 'catalog_detail' : 'detail',
        ]);
        if (provider == 'sbiz') {
          expect(
            actions.where(
              (a) => ['google_search', 'resolve', 'detail'].contains(a),
            ),
            isEmpty,
          );
        }
        // Catalog places drop the Google button and source lines; Google
        // places keep the attribution their terms require.
        await tester.tap(find.byKey(const ValueKey('detail-expand')));
        await tester.pumpAndSettle();
        expect(find.text('Google에서 추가 정보 찾기'), findsNothing);
        expect(find.textContaining('공공데이터 기준일'), findsNothing);
        expect(
          find.text('정보 제공: Google Maps'),
          provider == 'sbiz' ? findsNothing : findsOneWidget,
        );
        expect(find.textContaining('정보 제공: 소상공인'), findsNothing);
        for (final action in ['save', 'share', 'directions']) {
          expect(
            find.byKey(ValueKey('detail-$action')).hitTestable(),
            findsOneWidget,
          );
        }
        await tester.tap(find.byTooltip('닫기'));
        await tester.pumpAndSettle();
        expect(find.byType(PlaceSheet), findsNothing);
        expect(find.byType(PindNavigationBar), findsOneWidget);
        expect(actions, [
          'posted',
          'search',
          provider == 'sbiz' ? 'catalog_detail' : 'detail',
        ]);
        if (provider == 'sbiz') {
          expect(
            actions.where(
              (a) => ['google_search', 'resolve', 'detail'].contains(a),
            ),
            isEmpty,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
