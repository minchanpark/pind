import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/services/place_service.dart';

void main() {
  test(
    'agent search sends the sentence and map center, shows the reading',
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
              },
            ],
            'notice': '혼술 · 포차 기준으로 찾았어요.',
          };
        }),
      );
      addTearDown(controller.dispose);
      await controller.agentSearch(
        ' 혼술 하기 좋은 식당 ',
        const MapViewport(37.54, 127.05),
      );
      expect(bodies.single, {
        'action': 'agent_search',
        'query': '혼술 하기 좋은 식당',
        'latitude': 37.54,
        'longitude': 127.05,
      });
      expect(controller.places.single.name, '성수 포차');
      expect(controller.notice, '혼술 · 포차 기준으로 찾았어요.');
      // Too short never reaches the server.
      await controller.agentSearch('a', MapViewport.seoul);
      expect(bodies, hasLength(1));
      expect(controller.error, isNotNull);
      },
  );
}
