import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pind_flutter/controllers/app_controller.dart';
import 'package:pind_flutter/controllers/discover_controller.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:pind_flutter/model/discover_model.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/registration_model.dart';
import 'package:pind_flutter/services/data_revision.dart';
import 'package:pind_flutter/services/friends_service.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/services/registration_service.dart';
import 'package:pind_flutter/view/components/post_card.dart';
import 'package:pind_flutter/view/discover/discover_screen.dart';
import 'package:pind_flutter/view/explore/agent_search_page.dart';
import 'package:pind_flutter/model/nearby_ranking.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/place_search_result.dart';

import 'support/registration_fakes.dart';
import 'discover_controller_test.dart' as fixtures;
import 'profile_test.dart' as profile_fixtures;

import 'package:pind_flutter/controllers/profile_controller.dart';
import 'package:pind_flutter/services/profile_service.dart';

class TasteSpy extends UnavailableFriendsService {
  final sent = <TastePreferences>[];
  @override
  Future<void> saveTaste(
    TastePreferences p, {
    bool discoverable = false,
  }) async {
    sent.add(p);
  }
}

TastePreferences taste(PreferenceCriterion first) => TastePreferences(
  priorities: [
    first,
    PreferenceCriterion.portion,
    PreferenceCriterion.ambience,
  ],
  cuisines: [Cuisine.korean, Cuisine.soup, Cuisine.noodles],
);

class PagedProfile extends profile_fixtures.FakeProfileService
    implements ProfilePostPages {
  Completer<ProfilePostPage>? gate;
  @override
  Future<ProfileOverview> overview({String? userId}) async => profile_fixtures
      .canned
      .copyWith(posts: [profile_fixtures.canned.posts.first]);
  @override
  Future<ProfilePostPage> postPage({String? userId, MyPost? after}) async =>
      gate == null
      ? ProfilePostPage(profile_fixtures.canned.posts, false)
      : gate!.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'profile pages append without duplicates and refresh ignores a stale page',
    () async {
      final service = PagedProfile();
      final controller = ProfileController(profile: service);
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.model.hasMorePosts, isTrue);
      service.gate = Completer<ProfilePostPage>();
      final pending = controller.loadMorePosts();
      await controller.load();
      service.gate!.complete(
        ProfilePostPage(profile_fixtures.canned.posts, false),
      );
      await pending;
      expect(controller.model.overview!.posts, hasLength(1));
      expect(controller.model.loadingPosts, isFalse);
      service.gate = null;
      await controller.loadMorePosts();
      expect(controller.model.overview!.posts, hasLength(2));
      expect(controller.model.hasMorePosts, isFalse);
    },
  );

  test(
    'visible map bounds reach every page and repeated cursors fail safely',
    () async {
      const bounds = MapBounds(37.4, 126.9, 37.6, 127.1);
      final service = PlaceService((body) async {
        expect(body['bounds'], bounds.json);
        return {
          'places': [
            {
              'provider': 'sbiz',
              'internalId': 1,
              'externalPlaceId': 'fixture',
              'name': 'cafe',
              'category': 'cafe',
              'address': 'Seoul',
              'latitude': 37.5,
              'longitude': 127.0,
              'sourceUri': 'https://example.com',
              'pindPostCount': 1,
            },
          ],
          'hasMore': true,
        };
      });
      await expectLater(
        service.posted(bounds: bounds),
        throwsA(isA<PlaceFailure>()),
      );
    },
  );

  test('refreshing during pagination unlocks the next page and discards the old page', () async {
    final s = fixtures.FakeDiscoverService()
      ..feedQueue.add(FeedPage([fixtures.post(1)], hasMore: true));
    final c = DiscoverController(service: s);
    addTearDown(c.dispose);
    await c.load();
    final old = Completer<FeedPage>();
    s.gate = old;
    final pending = c.loadMore();
    s.gate = null;
    s.feedQueue.add(FeedPage([fixtures.post(2)], hasMore: true));
    await c.load();
    old.complete(FeedPage([fixtures.post(9)], hasMore: false));
    await pending;
    expect(c.model.loadingMore, false);
    s.feedQueue.add(FeedPage([fixtures.post(3)], hasMore: false));
    await c.loadMore();
    expect(c.model.posts.map((p) => p.post.id), [2, 3]);
  });
  test('page failure keeps existing feed and can be retried', () async {
    final s = fixtures.FakeDiscoverService()
      ..feedQueue.add(FeedPage([fixtures.post(1)], hasMore: true));
    final c = DiscoverController(service: s);
    addTearDown(c.dispose);
    await c.load();
    s.feedQueue.add(StateError('offline'));
    await c.loadMore();
    expect(c.model.posts.length, 1);
    expect(c.model.moreError, isNotNull);
    s.feedQueue.add(FeedPage([fixtures.post(2)], hasMore: false));
    await c.loadMore();
    expect(c.model.moreError, isNull);
    expect(c.model.posts.length, 2);
  });
  test(
    'account changes load only that account taste and clear taste on logout',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await SharedPreferences.getInstance();
      final p = PreferenceService(storage),
          a = taste(PreferenceCriterion.taste),
          b = taste(PreferenceCriterion.value);
      await p.forUser('a').save(a);
      await p.forUser('b').save(b);
      final drafts = RegistrationService(storage);
      await drafts.save('a', const RegistrationDraft(completed: true));
      await drafts.save('b', const RegistrationDraft(completed: true));
      final auth = FakeAuthService(initial: const AuthIdentity('a'));
      addTearDown(auth.close);
      final spy = TasteSpy();
      final c = AppController(
        p,
        auth: auth,
        registrationService: drafts,
        friends: spy,
      );
      addTearDown(c.dispose);
      expect(c.model.preferences!.priorities, a.priorities);
      auth.emit(const AuthIdentity('b'));
      expect(c.model.preferences!.priorities, b.priorities);
      expect(spy.sent.map((p) => p.priorities.first), [
        PreferenceCriterion.taste,
        PreferenceCriterion.value,
      ]);
      auth.emit(null);
      expect(c.model.preferences, isNull);
    },
  );
  test(
    'unowned legacy device taste is never synced into a signed-in account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await SharedPreferences.getInstance();
      final p = PreferenceService(storage);
      await p.save(taste(PreferenceCriterion.taste));
      final auth = FakeAuthService(initial: const AuthIdentity('b'));
      addTearDown(auth.close);
      final drafts = RegistrationService(storage);
      await drafts.save('b', const RegistrationDraft(completed: true));
      final spy = TasteSpy();
      final c = AppController(
        p,
        auth: auth,
        registrationService: drafts,
        friends: spy,
      );
      addTearDown(c.dispose);
      expect(c.model.preferences, isNull);
      expect(spy.sent, isEmpty);
    },
  );
  test(
    'map cache reloads after a write, while unchanged data reuses its cache',
    () async {
      var reads = 0;
      final c = ExploreController(
        PlaceService((_) async {
          reads++;
          return {'places': []};
        }),
      );
      addTearDown(c.dispose);
      await c.load();
      await c.load();
      expect(reads, 1);
      markDataChanged();
      await c.load();
      expect(reads, 2);
    },
  );
  test(
    'posted pagination reads past the first page and rejects a stuck cursor',
    () async {
      final cursors = <int?>[];
      final service = PlaceService((body) async {
        cursors.add(body['afterId'] as int?);
        final id = body['afterId'] == null ? 1 : 2;
        return {
          'hasMore': id == 1,
          'places': [
            {
              'provider': 'sbiz',
              'internalId': id,
              'externalPlaceId': 'p$id',
              'name': '식당',
              'category': '한식',
              'address': '서울',
              'latitude': 37.5,
              'longitude': 127.0,
              'sourceUri': 'https://example.com',
              'pindPostCount': 1,
            },
          ],
        };
      });
      expect((await service.posted()).map((p) => p.id), [1, 2]);
      expect(cursors, [null, 1]);
    },
  );
  testWidgets(
    'failed like gives a visible explanation and preserves the post',
    (tester) async {
      final s = fixtures.FakeDiscoverService()
        ..feedQueue.add(FeedPage([fixtures.post(1)], hasMore: false))
        ..likeError = StateError('offline');
      final c = DiscoverController(service: s);
      await c.load();
      await tester.pumpWidget(MaterialApp(home: DiscoverScreen(controller: c)));
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(c.model.posts.single.liked, false);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets('long restaurant label stays inside a small viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const name = '아주 긴 음식점 이름과 서울특별시 성수동 본점의 지점 이름';
    const place = Place(
      id: 1,
      provider: PlaceProvider.sbiz,
      externalId: 'long',
      name: name,
      category: '한식',
      address: '서울',
      latitude: 37.5,
      longitude: 127,
      mapsUri: 'https://example.com',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(18.5),
            child: PostCard(
              post: MyPost(
                id: 1,
                place: place,
                createdAt: DateTime(2026),
                body: name,
              ),
              author: const UserProfile(id: 'u', displayName: '작성자'),
              action: const SizedBox.square(dimension: 44),
            ),
          ),
        ),
      ),
    );
    final label = tester.getRect(find.text('📍${place.name}'));
    expect(label.left, greaterThanOrEqualTo(0));
    expect(label.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });
  testWidgets('instant search results are shown before progress narration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AgentSearchPage(
          search: (_) async => (notice: 'ready-now', places: <RankedPlace>[]),
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText).first, '성수 카페');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('ready-now'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
