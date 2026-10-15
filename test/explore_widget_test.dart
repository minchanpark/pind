import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:pind_flutter/controllers/app_controller.dart';
import 'package:pind_flutter/model/place_search_result.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/app.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/explore_model.dart';
import 'package:pind_flutter/model/place_context.dart';
import 'package:pind_flutter/services/place_context_service.dart';
import 'package:pind_flutter/view/explore/explore_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Scopes implements PlaceContextService {
  final asked = <MapScope>[];
  @override
  Future<PlaceContext> load(int placeId) => throw UnimplementedError();
  @override
  Future<void> setSaved(int placeId, bool saved) async {}
  @override
  Future<Set<int>> scopePlaces(MapScope scope) async {
    asked.add(scope);
    return scope == MapScope.friends ? {2} : {1};
  }
}

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

  test('pin size steps at 2 and 10 posts', () {
    int tier(int? posts) => pinTier(
      Place(
        externalId: 'p',
        name: '가게',
        category: '',
        address: '',
        latitude: 37,
        longitude: 127,
        mapsUri: '',
        pindPostCount: posts,
      ),
    );
    expect([null, 1, 2, 9, 10, 50].map(tier), [0, 0, 1, 1, 2, 2]);
  });

  testWidgets('unconfigured backend: search button is inert, no crash', (
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
    // No backend: the search button is inert rather than opening a page.
    await tester.tap(find.byKey(const ValueKey('map-search-button')));
    await tester.pumpAndSettle();
    expect(find.text('개인 맞춤형 음식 검색'), findsNothing);
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
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('테스트 연결 오류'), findsNothing);
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

  testWidgets('top chips narrow pins to friends or saved places', (
    tester,
  ) async {
    Map<String, dynamic> pin(int id) => {
      'provider': 'sbiz',
      'internalId': id,
      'externalPlaceId': 'p$id',
      'sourceUri': '',
      'name': '가게$id',
      'category': '한식',
      'address': '',
      'latitude': 37.5,
      'longitude': 127.0,
      'pindPostCount': 1,
    };
    final scopes = _Scopes();
    final controller = ExploreController(
      PlaceService(
        (_) async => {
          'places': [pin(1), pin(2)],
        },
      ),
      placeContext: scopes,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ExploreScreen(
          controller: controller,
          mapsEnabled: false,
          onEditPreferences: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    List<int?> pins() => [
      for (final p
          in (tester.state(find.byType(ExploreScreen)) as dynamic).visiblePlaces
              as List<Place>)
        p.id,
    ];
    expect(pins(), [1, 2]);
    await tester.tap(find.byKey(const ValueKey('map-scope-friends')));
    await tester.pumpAndSettle();
    expect(pins(), [2]);
    await tester.tap(find.byKey(const ValueKey('map-scope-saved')));
    await tester.pumpAndSettle();
    expect(pins(), [1]);
    await tester.tap(find.byKey(const ValueKey('map-scope-all')));
    await tester.pumpAndSettle();
    expect(pins(), [1, 2]);
    expect(scopes.asked, [MapScope.friends, MapScope.saved]);
  });
}
