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
}
