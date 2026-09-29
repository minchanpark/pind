import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:pind_flutter/controllers/app_controller.dart';
import 'package:pind_flutter/model/place_search_result.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/app.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/view/explore/explore_screen.dart';
import 'package:pind_flutter/view/explore/place_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'map pins use the category emoji from public-data and Google categories',
    () {
      String emoji(String category, [String name = '가게']) => markerEmoji(
        Place(
          externalId: category,
          name: name,
          category: category,
          address: '',
          latitude: 37,
          longitude: 127,
          mapsUri: '',
        ),
      );
      expect(emoji('카페'), '☕');
      expect(emoji('Cafe'), '☕');
      expect(emoji('요리 주점'), '🍺');
      expect(emoji('생맥주 전문'), '🍺');
      expect(emoji('돼지고기 구이/찜'), '🥩');
      expect(emoji('곱창 전골/구이'), '🥩');
      expect(emoji('barbecue_restaurant'), '🥩');
      expect(emoji('냉면/밀면', '화담면옥'), '🍜');
      expect(emoji('국수/칼국수'), '🍜');
      expect(emoji('빵/도넛'), '🍰');
      expect(emoji('Bakery'), '🍰');
      expect(emoji('아이스크림/빙수'), '🍰');
      expect(emoji('해산물 구이/찜'), '🍽️');
      expect(emoji('치킨'), '🍽️');
    },
  );

  testWidgets(
    'only latest search opens results; supplemental places remain selectable',
    (tester) async {
      final pending = <String, Completer<Map<String, dynamic>>>{};
      final repository = PlaceService((body) async {
        if (body['action'] == 'posted') return {'places': <dynamic>[]};
        final request = Completer<Map<String, dynamic>>();
        pending[body['query'] as String] = request;
        return request.future;
      });
      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(
            controller: ExploreController(repository),
            mapsEnabled: false,
            onEditPreferences: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('곳 보기'), findsNothing);
      await tester.enterText(find.byType(TextField), '먼저 검색');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '나중 검색');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      pending['나중 검색']!.complete({
        'places': [
          {
            'provider': 'kakao_local',
            'externalPlaceId': 'kakao-test',
            'name': '보완 가게',
            'category': '카페',
            'address': '서울',
            'latitude': 37.56,
            'longitude': 126.97,
            'sourceUri': 'https://place.map.kakao.com/kakao-test',
          },
        ],
      });
      await tester.pumpAndSettle();
      pending['먼저 검색']!.complete({'places': <dynamic>[]});
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet, skipOffstage: false), findsOneWidget);
      expect(find.text('보완 가게'), findsOneWidget);
      await tester.tap(find.text('보완 가게'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceSheet), findsOneWidget);
      expect(find.text('운영시간 확인 필요'), findsOneWidget);
      expect(find.text('카카오맵에서 확인'), findsOneWidget);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('unconfigured backend handles keyboard search without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExploreScreen(
          controller: null,
          mapsEnabled: false,
          onEditPreferences: () {},
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '서울');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed posted places request shows error and retries successfully',
    (tester) async {
      var attempts = 0;
      final repository = PlaceService((body) async {
        attempts++;
        if (attempts == 1) throw const PlaceFailure('테스트 연결 오류');
        return {'places': <dynamic>[]};
      });
      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(
            controller: ExploreController(repository),
            mapsEnabled: false,
            onEditPreferences: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('테스트 연결 오류'), findsOneWidget);
      await tester.tap(find.text('재시도'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('테스트 연결 오류'), findsNothing);
      expect(find.text('게시물이 있는 식당이 지도에 표시돼요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'complete local draft restores map and edit cancellation keeps it',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = PreferenceService(await SharedPreferences.getInstance());
      var preferences = TastePreferences();
      for (final value in PreferenceCriterion.values.take(3)) {
        preferences = preferences.togglePriority(value);
      }
      for (final value in Cuisine.values.take(3)) {
        preferences = preferences.toggleCuisine(value);
      }
      await store.save(preferences);
      await tester.pumpWidget(PindApp(controller: AppController(store)));
      expect(find.byType(ExploreScreen), findsOneWidget);
      await tester.tap(find.byTooltip('취향 수정'));
      await tester.pumpAndSettle();
      expect(find.text('1순위'), findsOneWidget);
      await tester.tap(find.byTooltip('이전'));
      await tester.pumpAndSettle();
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(store.load()!.priorities, preferences.priorities);
      expect(tester.takeException(), isNull);
    },
  );
}
