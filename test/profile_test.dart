import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/profile_controller.dart';
import 'package:pind_flutter/model/place_search_result.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/post_model.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/model/friends_model.dart';
import 'package:pind_flutter/services/friends_service.dart';
import 'package:pind_flutter/services/profile_service.dart';
import 'package:pind_flutter/view/profile/profile_follow.dart';
import 'package:pind_flutter/view/profile/profile_saved_tab.dart';
import 'package:pind_flutter/view/profile/profile_screen.dart';
import 'package:pind_flutter/view/theme.dart';

Place place(int id, String name, String address) => Place(
  id: id,
  provider: PlaceProvider.sbiz,
  externalId: 'p$id',
  name: name,
  category: '카페',
  address: address,
  latitude: 37.54 + id / 100,
  longitude: 126.92 + id / 100,
  mapsUri: 'https://example.com/$id',
);

const averages = {
  PreferenceCriterion.taste: 5.0,
  PreferenceCriterion.portion: 4.0,
  PreferenceCriterion.ambience: 5.0,
};

final canned = ProfileOverview(
  profile: const UserProfile(
    id: 'u1',
    handle: 'minchan',
    displayName: '민찬',
    bio: '서울 성수동 여행 중',
  ),
  counts: const ProfileCounts(followers: 4, following: 3, posts: 2, saved: 1),
  recentViews: [ProfilePlaceCard(place: place(1, '최근 카페', '서울 마포구 연남동 12'))],
  savedPlaces: [
    ProfilePlaceCard(
      place: place(2, '저장 식당', '서울특별시 성동구 성수동 1'),
      averages: averages,
    ),
    ProfilePlaceCard(
      place: place(3, '저장 카페', '서울 종로구 종로 1'),
      averages: const {PreferenceCriterion.taste: 4},
    ),
  ],
  posts: [
    MyPost(
      id: 10,
      place: place(2, '저장 식당', '서울특별시 성동구 성수동 1'),
      body: '한 장 게시물',
      ratings: const {PreferenceCriterion.taste: 5},
      photos: const ['https://example.com/a.jpg'],
      createdAt: DateTime(2026, 9, 1),
    ),
    MyPost(
      id: 11,
      place: place(4, '네 장 가게', '부산 해운대구 우동 1'),
      body: '네 장 게시물',
      ratings: const {
        PreferenceCriterion.ambience: 4,
        PreferenceCriterion.taste: 3,
      },
      photos: const [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
        'https://example.com/3.jpg',
        'https://example.com/4.jpg',
      ],
      createdAt: DateTime(2026, 9, 2),
    ),
  ],
);

class FakeProfileService implements ProfileService {
  FakeProfileService({this.fail = false, this.other});
  bool fail;
  final ProfileOverview? other;
  final requested = <String?>[];
  int overviewCalls = 0;
  final saves = <Map<String, String?>>[];
  @override
  Future<UserProfile?> load() async => canned.profile;
  @override
  Future<ProfileOverview> overview({String? userId}) async {
    overviewCalls++;
    requested.add(userId);
    if (fail) throw const PlaceFailure('서버 오류');
    return userId == null ? canned : other!;
  }

  @override
  Future<void> save({
    String? handle,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async => saves.add({'displayName': displayName, 'bio': bio});
  @override
  Future<String> uploadAvatar(PostPhoto photo) async => 'https://x/a.png';
  @override
  Future<void> recordView(int placeId) async {}
  @override
  Future<String?> findUserId(String handle) async => {
    canned.profile.handle: canned.profile.id,
    other?.profile.handle: other?.profile.id,
  }[handle];
}

final prefs = TastePreferences(
  priorities: [
    PreferenceCriterion.taste,
    PreferenceCriterion.portion,
    PreferenceCriterion.ambience,
  ],
  cuisines: Cuisine.values.take(3),
);

Future<ProfileController> pump(
  WidgetTester tester, {
  FakeProfileService? service,
  void Function(int? placeId)? onShowMap,
}) async {
  final controller = ProfileController(
    profile: service ?? FakeProfileService(),
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: PindTheme.data,
      home: ProfileScreen(
        controller: controller,
        preferences: prefs,
        mapsEnabled: false,
        onEditPreferences: () {},
        onShowMap: onShowMap ?? (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  test('placeArea prefers 동, then 구, then the second token', () {
    expect(placeArea('서울특별시 성동구 성수동 123-4'), '성수동');
    expect(placeArea('서울 성동구 성수이로 12'), '성동구');
    expect(placeArea('경기도 양평군 양평읍 창대리 1'), '양평읍');
    expect(placeArea('서울 강남구 101동 202호'), '강남구');
    expect(placeArea('Tokyo Shibuya 1-2'), 'Shibuya');
    expect(placeArea('서울'), '서울');
  });

  testWidgets('header shows handle, bio, counts and the taste card', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('@minchan'), findsOneWidget);
    expect(find.text('📍 서울 성수동 여행 중'), findsOneWidget);
    for (final n in ['4', '3', '2', '1']) {
      expect(find.text(n), findsOneWidget);
    }
    expect(find.text('팔로워'), findsOneWidget);
    expect(find.text('팔로잉'), findsOneWidget);
    expect(find.text('맛 중시형'), findsOneWidget);
    expect(find.text('맛 먼저, 그다음 양·분위기·공간을 봐요.'), findsOneWidget);
    expect(find.text('2곳'), findsOneWidget); // posted places only
    // The map centers on the newest post; saved-only places stay off it.
    expect(canned.mapPlaces.first.id, canned.posts.first.place.id);
    expect(
      canned.mapPlaces.map((p) => p.id),
      isNot(contains(canned.savedPlaces.last.place.id)),
    );
    expect(find.text('지도를 사용할 수 없어요'), findsOneWidget);
  });

  testWidgets('맵 보기 focuses the map on the newest post', (tester) async {
    int? focused;
    await pump(tester, onShowMap: (id) => focused = id);
    await tester.ensureVisible(find.text('맵 보기 ›'));
    await tester.tap(find.text('맵 보기 ›'));
    expect(focused, canned.posts.first.place.id);
  });

  testWidgets('badges dim until earned', (tester) async {
    await pump(tester);
    double opacity(String label) => tester
        .widget<Opacity>(
          find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
        )
        .opacity;
    expect(opacity('맛잘알'), 1);
    expect(opacity('게시물왕'), .5);
    expect(opacity('맛집 판별가'), .5);
    expect(opacity('???'), .5);
  });

  for (final (width, expected) in [
    (402.0, const Size(116.67, 99.72)), // design phone: ~117×100
    (320.0, const Size(89.33, 76.35)), // small phone scales down
    (430.0, const Size(125.15, 106.97)), // widest phone
    (820.0, const Size(125.15, 106.97)), // tablet stays phone-sized
  ]) {
    testWidgets('recent place image is ${expected.width}pt wide at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester);
      await tester.tap(find.text('저장').last);
      await tester.pumpAndSettle();
      final image = find.descendant(
        of: find.byType(RecentPlaceCard).first,
        matching: find.byType(SizedBox),
      );
      final size = tester.getSize(
        image
            .evaluate()
            .map((e) => find.byWidget(e.widget))
            .firstWhere((f) => (tester.widget<SizedBox>(f).height ?? 0) > 50),
      );
      expect(size.width, closeTo(expected.width, .01));
      expect(size.height, closeTo(expected.height, .01));
    });
  }

  testWidgets('saved tab lists recent views and saved cards with match', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();
    expect(find.text('최근 카페'), findsOneWidget);
    expect(find.text('📍 연남동'), findsOneWidget);
    expect(find.text('저장 식당'), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);
    expect(find.text('나의 취향'), findsNothing);
    await tester.tap(find.text('더보기 ›'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('최근 카페'), findsOneWidget);
  });

  testWidgets('posts tab shows posts, dividers, and a +1 overlay', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('게시물').last);
    await tester.pumpAndSettle();
    expect(find.text('한 장 게시물'), findsOneWidget);
    expect(find.text('네 장 게시물'), findsOneWidget);
    expect(find.text('+ 1'), findsOneWidget);
    expect(find.text('📍네 장 가게'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(find.bySemanticsLabel('맛 3점'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings sheet saves display name and bio', (tester) async {
    final service = FakeProfileService();
    await pump(tester, service: service);
    await tester.tap(find.bySemanticsLabel('설정'));
    await tester.pumpAndSettle();
    expect(find.text('아이디는 변경할 수 없어요'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, '닉네임'), '새 이름');
    await tester.enterText(
      find.widgetWithText(TextFormField, '상태 메시지'),
      '부산 여행 중',
    );
    await tester.tap(find.text('저장').last);
    await tester.pumpAndSettle();
    expect(service.saves, [
      {'displayName': '새 이름', 'bio': '부산 여행 중'},
    ]);
    expect(find.text('아이디는 변경할 수 없어요'), findsNothing);
    expect(find.text('📍 부산 여행 중'), findsOneWidget);
  });

  testWidgets('load error offers retry', (tester) async {
    final service = FakeProfileService(fail: true);
    await pump(tester, service: service);
    expect(find.text('서버 오류'), findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('@minchan'), findsOneWidget);
  });

  group('someone else\'s page', () {
    ProfileOverview haram({bool following = false, bool followsMe = false}) =>
        ProfileOverview(
          profile: const UserProfile(
            id: 'u2',
            handle: 'haramsyoo',
            displayName: '하람',
          ),
          counts: const ProfileCounts(followers: 142, following: 98, posts: 37),
          following: following,
          followsMe: followsMe,
          taste: const [
            PreferenceCriterion.ambience,
            PreferenceCriterion.taste,
            PreferenceCriterion.value,
          ],
        );

    Finder button(String label) => find.descendant(
      of: find.byType(FollowButton),
      matching: find.text(label),
    );

    Future<(ProfileController, _Follows)> visit(
      WidgetTester tester,
      ProfileOverview other, {
      bool fail = false,
    }) async {
      final service = FakeProfileService(other: other);
      final follows = _Follows()..fail = fail;
      final controller = ProfileController(
        profile: service,
        friends: follows,
        userId: 'u2',
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: PindTheme.data,
          home: ProfileScreen(
            controller: controller,
            preferences: prefs,
            mapsEnabled: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.requested, ['u2']);
      return (controller, follows);
    }

    testWidgets('shows their profile without my-page controls', (tester) async {
      await visit(tester, haram());
      expect(find.text('@haramsyoo'), findsOneWidget);
      expect(find.byTooltip('뒤로'), findsOneWidget);
      expect(find.bySemanticsLabel('설정'), findsNothing);
      expect(find.text('저장'), findsOneWidget, reason: 'tab only, no stat');
      expect(find.text('지도'), findsNWidgets(2), reason: 'tab and section');
      expect(find.text('취향'), findsOneWidget);
      expect(find.text('분위기·공간 중시형'), findsOneWidget, reason: 'their taste');
      expect(find.text('✎ 수정'), findsNothing);
      expect(find.text('맵 보기 ›'), findsNothing);
      expect(button('팔로우'), findsOneWidget);
    });

    testWidgets('follow, then unfollow through the confirm sheet', (
      tester,
    ) async {
      final (controller, follows) = await visit(tester, haram());
      await tester.tap(button('팔로우'));
      await tester.pumpAndSettle();
      expect(follows.calls, [('u2', true)]);
      expect(button('팔로잉'), findsOneWidget);
      expect(find.text('143'), findsOneWidget);

      await tester.tap(button('팔로잉'));
      await tester.pumpAndSettle();
      expect(find.text('@haramsyoo 님을 팔로우 취소할까요?'), findsOneWidget);
      await tester.tap(find.text('닫기'));
      await tester.pumpAndSettle();
      expect(follows.calls, hasLength(1), reason: '닫기 keeps the follow');
      expect(button('팔로잉'), findsOneWidget);

      await tester.tap(button('팔로잉'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('팔로우 취소'));
      await tester.pumpAndSettle();
      expect(follows.calls.last, ('u2', false));
      expect(button('팔로우'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(controller.model.overview!.following, isFalse);
    });

    testWidgets('they follow me: 맞팔로우', (tester) async {
      await visit(tester, haram(followsMe: true));
      expect(button('맞팔로우'), findsOneWidget);
    });

    testWidgets('a refused follow reverts and explains', (tester) async {
      await visit(tester, haram(), fail: true);
      await tester.tap(button('팔로우'));
      await tester.pumpAndSettle();
      expect(button('팔로우'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(find.text('팔로우하지 못했어요.'), findsOneWidget);
    });

    testWidgets('hidden taste and private recent views', (tester) async {
      await visit(tester, haram().copyWithTaste(null));
      expect(find.text('공개한 취향이 없어요.'), findsOneWidget);
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();
      expect(find.text('최근에 본 장소'), findsNothing);
      expect(find.text('공유한 저장 장소가 없어요.'), findsOneWidget);
    });
  });
}

extension on ProfileOverview {
  ProfileOverview copyWithTaste(List<PreferenceCriterion>? taste) =>
      ProfileOverview(profile: profile, counts: counts, taste: taste);
}

class _Follows implements FriendsService {
  bool fail = false;
  final calls = <(String, bool)>[];
  @override
  Future<void> setFollowing(String userId, bool following) async {
    calls.add((userId, following));
    if (fail) throw const PlaceFailure('팔로우하지 못했어요.');
  }

  @override
  Future<List<FriendCandidate>> matches({
    int offset = 0,
    int limit = 5,
  }) async => const [];
  @override
  Future<List<FriendCandidate>> search(String query) async => const [];
  @override
  Future<void> saveTaste(
    TastePreferences preferences, {
    bool discoverable = false,
  }) async {}
}
