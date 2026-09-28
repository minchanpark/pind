import '../../model/detail_preview_model.dart';
// Explicit local QA data. Never imported by main.dart or a production service.
import '../place_context_service.dart';
import '../place_service.dart';
import '../../model/place_context.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';

final detailPreferences = TastePreferences(
  priorities: [
    PreferenceCriterion.taste,
    PreferenceCriterion.portion,
    PreferenceCriterion.ambience,
  ],
  cuisines: [Cuisine.korean, Cuisine.soup, Cuisine.noodles],
);
final detailPayload = <String, dynamic>{
  'provider': 'google_places',
  'internalId': 900001,
  'externalPlaceId': 'local-qa-only',
  'name': '네임이즈마빈',
  'category': '카페 · 로컬 테스트 데이터',
  'address': '서울 마포구 망원동 405-3',
  'latitude': 37.555,
  'longitude': 126.905,
  'googleMapsUri': 'https://www.google.com/maps/search/?api=1&query=네임이즈마빈',
  'isOpenNow': true,
  'userRatingCount': 87,
  'utcOffsetMinutes': 540,
  'weekdayDescriptions': [
    for (final d in ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'])
      '$d: 11:30 – 21:00',
  ],
  'editorialSummary': '로컬 검증용 소개입니다. 실제 운영시간·평점·친구 방문 정보가 아닙니다.',
  'gallery': [
    for (var i = 1; i <= 3; i++)
      {'uri': 'assets/figma/detail_fixture_photo_$i.png', 'attributions': []},
  ],
};
Place get detailPlace => Place.fromJson(detailPayload);
PlaceService get detailPlaces =>
    PlaceService((_) async => {'place': detailPayload});

class LocalDetailContext implements PlaceContextService {
  TestFriendship relationship = TestFriendship.accepted;
  bool publicVisit = true, hasVisit = true, saved = false, failSave = false;
  bool hasRatings = true;
  int saveCalls = 0;
  @override
  Future<PlaceContext> load(int placeId) async {
    if (placeId != 900001) throw StateError('Not a QA place');
    final canSee =
        relationship == TestFriendship.accepted && publicVisit && hasVisit;
    return PlaceContext(
      averages: hasRatings
          ? {
              PreferenceCriterion.taste: 5,
              PreferenceCriterion.portion: 4,
              PreferenceCriterion.ambience: 5,
            }
          : {},
      mine: hasRatings
          ? {
              PreferenceCriterion.taste: 5,
              PreferenceCriterion.portion: 4,
              PreferenceCriterion.ambience: 5,
            }
          : {},
      visitors: canSee
          ? [
              const FriendVisit(
                'local-test-friend',
                'pind_test_friend',
                'assets/figma/detail_fixture_avatar_1.png',
              ),
            ]
          : [],
      friendSaveCount: canSee ? 1 : 0,
      saved: saved,
    );
  }

  @override
  Future<void> setSaved(int placeId, bool value) async {
    saveCalls++;
    if (failSave) throw StateError('QA save failure');
    saved = value;
  }
}
