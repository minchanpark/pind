import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:pind_flutter/model/place_search_result.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/services/place_service.dart';

void main() {
  test(
    'agent search sends the sentence and map center, returns cards and reading',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final controller = ExploreController(
        PlaceService((body) async {
          bodies.add(body);
          return {
            'places': [
              {
                'provider': 'sbiz',
                'internalId': 1,
                'externalPlaceId': 'p1',
                'name': '성수 포차',
                'category': '요리 주점',
                'address': '서울 성동구 성수동 1',
                'latitude': 37.544,
                'longitude': 127.055,
                'sourceUri': 'https://example.com',
                'pindPostCount': 2,
                'meters': 302,
                'averages': {'taste': 4.5},
                'reviewCount': 2,
                'saved': true,
              },
            ],
            'notice': '혼술 · 포차 기준으로 찾았어요.',
          };
        }),
      );
      addTearDown(controller.dispose);
      final answer = await controller.agentSearch(
        ' 혼술 하기 좋은 식당 ',
        const MapViewport(37.54, 127.05),
      );
      expect(bodies.single, {
        'action': 'agent_search',
        'query': '혼술 하기 좋은 식당',
        'latitude': 37.54,
        'longitude': 127.05,
        'lang': 'ko',
      });
      final place = answer.places.single;
      expect(place.place.name, '성수 포차');
      expect(place.meters, 302);
      expect(place.averages, {PreferenceCriterion.taste: 4.5});
      expect(place.reviewCount, 2);
      expect(place.saved, isTrue);
      expect(answer.notice, '혼술 · 포차 기준으로 찾았어요.');
      // The map is left alone.
      expect(controller.places, isEmpty);
      // Too short never reaches the server.
      await expectLater(
        controller.agentSearch('a', MapViewport.seoul),
        throwsA(isA<PlaceFailure>()),
      );
      expect(bodies, hasLength(1));
    },
  );

  test('my onboarding foods and occasions go with the sentence', () async {
    final bodies = <Map<String, dynamic>>[];
    final controller = ExploreController(
      PlaceService((body) async {
        bodies.add(body);
        return {'places': <dynamic>[], 'notice': '내 취향 · 카페 기준으로 찾았어요.'};
      }),
    );
    addTearDown(controller.dispose);
    final answer = await controller.agentSearch(
      '내가 좋아할만한 곳 추천해줘',
      const MapViewport(37.54, 127.05),
      taste: TastePreferences(
        priorities: [
          PreferenceCriterion.ambience,
          PreferenceCriterion.value,
          PreferenceCriterion.photogenic,
        ],
        occasions: [DiningOccasion.date],
        cuisines: [Cuisine.dessert, Cuisine.barbecue],
      ),
    );
    expect(bodies.single['cuisines'], ['dessert', 'barbecue']);
    expect(bodies.single['occasions'], ['date']);
    expect(answer.notice, '내 취향 · 카페 기준으로 찾았어요.');
    // No taste: nothing extra is sent.
    await controller.agentSearch('카페', MapViewport.seoul);
    expect(bodies.last.containsKey('cuisines'), isFalse);
  });

  test('the reading comes back as a label and is worded here', () async {
    final controller = ExploreController(
      PlaceService(
        (body) async => {
          'places': <dynamic>[],
          'label': '혼술 · 포차',
          'notice': 'ignored when a label is given',
        },
      ),
    );
    addTearDown(controller.dispose);
    final answer = await controller.agentSearch('혼술', MapViewport.seoul);
    expect(answer.notice, '혼술 · 포차 기준으로 찾았어요.');
    // "Pick for me": the foods I sent name the notice.
    final mine = ExploreController(
      PlaceService(
        (body) async => {
          'places': <dynamic>[],
          'personal': true,
          'label': '내 취향',
        },
      ),
    );
    addTearDown(mine.dispose);
    final picked = await mine.agentSearch(
      '추천해줘',
      MapViewport.seoul,
      taste: TastePreferences(
        priorities: [
          PreferenceCriterion.taste,
          PreferenceCriterion.value,
          PreferenceCriterion.quiet,
        ],
        cuisines: [Cuisine.dessert, Cuisine.barbecue],
      ),
    );
    expect(picked.notice, '내 취향 · 고기구이 · 카페·디저트 기준으로 찾았어요.');
  });

  test('server error codes read in the app language', () {
    expect(serverErrorMessage('ROUTE_TOO_FAR', 'x'), '걸어가기엔 너무 멀어요.');
    expect(serverErrorMessage('QUERY_NOT_UNDERSTOOD', 'x'), contains('이해하지'));
    expect(serverErrorMessage('SOMETHING_NEW', 'fallback'), 'fallback');
    expect(googleLanguage('zh-Hant'), 'zh-TW');
    expect(googleLanguage('zh'), 'zh-CN');
    expect(googleLanguage('ja'), 'ja');
  });
}
