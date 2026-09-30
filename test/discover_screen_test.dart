import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/discover_controller.dart';
import 'package:pind_flutter/model/discover_model.dart';
import 'package:pind_flutter/model/place_search_result.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/services/discover_service.dart';
import 'package:pind_flutter/view/components/post_card.dart';
import 'package:pind_flutter/view/discover/discover_screen.dart';
import 'package:pind_flutter/view/theme.dart';

FeedPost post(int id, String handle, {int likes = 0, bool liked = false}) =>
    FeedPost(
      post: MyPost(
        id: id,
        place: Place(
          id: id,
          provider: PlaceProvider.sbiz,
          externalId: 'p$id',
          name: '가게 $id',
          category: '카페',
          address: '서울 성동구 성수동 $id',
          latitude: 37.5,
          longitude: 127,
          mapsUri: 'https://example.com/$id',
        ),
        body: '게시물 $id',
        ratings: const {PreferenceCriterion.taste: 5},
        photos: ['https://example.com/$id.jpg'],
        createdAt: DateTime(2026, 9, id),
      ),
      author: UserProfile(id: 'u$id', handle: handle, displayName: handle),
      likeCount: likes,
      liked: liked,
    );

class FakeDiscoverService implements DiscoverService {
  FakeDiscoverService({this.fail = false, this.first = const [], this.second});
  bool fail;
  List<FeedPost> first;
  List<FeedPost>? second;
  final afters = <int?>[];
  final likes = <(int, bool)>[];

  @override
  Future<FeedPage> feed({
    FeedPost? after,
    String query = '',
    int limit = 20,
  }) async {
    afters.add(after?.post.id);
    if (fail) throw const PlaceFailure('서버 오류');
    if (after != null) return FeedPage(second ?? const [], hasMore: false);
    return FeedPage(first, hasMore: second != null);
  }

  @override
  Future<bool> setLiked(int postId, bool liked) async {
    likes.add((postId, liked));
    return liked;
  }
}

/// Tall by default so every lazily built card is on screen.
Future<DiscoverController> pump(
  WidgetTester tester,
  FakeDiscoverService service, {
  double height = 2400,
  VoidCallback? onFindFriends,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(402, height);
  addTearDown(tester.view.reset);
  final controller = DiscoverController(service: service);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: PindTheme.data,
      home: DiscoverScreen(
        controller: controller,
        onFindFriends: onFindFriends,
      ),
    ),
  );
  controller.load();
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  final three = [
    post(3, 'c', likes: 2, liked: true),
    post(2, 'b'),
    post(1, 'a'),
  ];

  testWidgets('header buttons, alert badge and invite card render', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    final controller = await pump(
      tester,
      FakeDiscoverService(first: three),
      onFindFriends: () => opened++,
    );
    expect(find.text('Pind Your Taste!'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('친구들 취향 탐색하기'), findsOneWidget);
    expect(find.text('친구 초대하기'), findsNothing, reason: 'feed has posts');
    await tester.tap(find.bySemanticsLabel('친구 추가'));
    expect(opened, 1);
    expect(find.bySemanticsLabel('알림'), findsOneWidget);

    controller.model.update(() => controller.model.hasNewAlerts = true);
    await tester.pump();
    expect(find.bySemanticsLabel('새 알림'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('invite card shows only for a loaded, empty feed', (
    tester,
  ) async {
    var opened = 0;
    final controller = await pump(
      tester,
      FakeDiscoverService(first: const []),
      onFindFriends: () => opened++,
    );
    expect(find.text('친구 초대하기'), findsOneWidget);
    await tester.tap(find.text('초대하기'));
    expect(opened, 1, reason: 'opens the find-friends page');

    controller.model.update(() => controller.model.loading = true);
    await tester.pump();
    expect(find.text('친구 초대하기'), findsNothing, reason: 'not while loading');
    controller.model.update(() {
      controller.model.loading = false;
      controller.model.error = '피드를 불러오지 못했어요.';
    });
    await tester.pump();
    expect(find.text('친구 초대하기'), findsNothing, reason: 'not on an error');
  });

  testWidgets('posts render newest first with dividers between', (
    tester,
  ) async {
    await pump(tester, FakeDiscoverService(first: three));
    final cards = find.byType(PostCard).evaluate().toList();
    expect(cards, hasLength(3));
    expect(
      [for (final c in cards) (c.widget as PostCard).author.handle],
      ['c', 'b', 'a'],
    );
    expect(find.byType(Divider), findsNWidgets(2));
    expect(find.text('📍가게 3'), findsOneWidget);
  });

  testWidgets('heart toggles icon, count and semantics', (tester) async {
    final semantics = tester.ensureSemantics();
    final service = FakeDiscoverService(first: three);
    await pump(tester, service);
    // Post 3 arrives liked with two likes; the others unliked with none.
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget);
    expect(find.bySemanticsLabel('좋아요 취소'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('좋아요').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsNWidgets(2));
    expect(find.text('1'), findsOneWidget);
    expect(service.likes, [(2, true)]);

    await tester.tap(find.bySemanticsLabel('좋아요 취소').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2)); // posts 2 and 3 each
    expect(find.text('2'), findsNothing);
    expect(service.likes.last, (3, false));
    semantics.dispose();
  });

  testWidgets('scrolling near the end loads the next page', (tester) async {
    final service = FakeDiscoverService(first: three, second: [post(0, 'z')]);
    await pump(tester, service, height: 874);
    expect(service.afters, [null]);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(service.afters, [null, 1]);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('📍가게 0'), findsOneWidget);
    expect(service.afters, [null, 1]); // last page: no further fetch
  });

  testWidgets('error shows retry which reloads', (tester) async {
    final service = FakeDiscoverService(fail: true, first: three);
    await pump(tester, service);
    expect(find.text('서버 오류'), findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byType(PostCard), findsNWidgets(3));
  });

  testWidgets('no posts shows the empty note', (tester) async {
    await pump(tester, FakeDiscoverService());
    expect(find.text('아직 게시물이 없어요.'), findsOneWidget);
  });
}
