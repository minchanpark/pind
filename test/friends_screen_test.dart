import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/friends_controller.dart';
import 'package:pind_flutter/model/friends_model.dart';
import 'package:pind_flutter/model/place_search_result.dart';
import 'package:pind_flutter/model/profile_link.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/services/friends_service.dart';
import 'package:pind_flutter/services/profile_service.dart';
import 'package:pind_flutter/view/friends/friends_screen.dart';
import 'package:pind_flutter/view/friends/share_code_screen.dart';
import 'package:pind_flutter/view/theme.dart';

FriendCandidate person(int n, {int? match, bool following = false}) =>
    FriendCandidate(
      profile: UserProfile(id: 'u$n', handle: 'user$n', displayName: '사람$n'),
      match: match,
      following: following,
    );

/// Serves [ranked] minus whatever is followed, like `get_taste_matches`.
class FakeFriendsService implements FriendsService {
  FakeFriendsService(this.ranked);
  final List<FriendCandidate> ranked;
  final followed = <String>{};
  final offsets = <int>[];
  final queries = <String>[];
  bool failFollow = false;

  @override
  Future<List<FriendCandidate>> matches({int offset = 0, int limit = 5}) async {
    offsets.add(offset);
    return ranked
        .where((c) => !followed.contains(c.profile.id))
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<FriendCandidate>> search(String query) async {
    queries.add(query);
    return [
      for (final c in ranked)
        if (c.profile.handle!.contains(query))
          c.withFollowing(followed.contains(c.profile.id)),
    ];
  }

  @override
  Future<void> setFollowing(String userId, bool following) async {
    if (failFollow) throw const PlaceFailure('팔로우하지 못했어요.');
    following ? followed.add(userId) : followed.remove(userId);
  }

  @override
  Future<void> saveTaste(
    TastePreferences preferences, {
    bool discoverable = false,
  }) async {}
}

Future<(FriendsController, FakeFriendsService)> pump(
  WidgetTester tester,
  List<FriendCandidate> ranked, {
  ValueChanged<FriendCandidate>? onOpenProfile,
  Future<void> Function(ProfileLink)? onOpenLink,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 2400);
  addTearDown(tester.view.reset);
  final service = FakeFriendsService(ranked);
  final controller = FriendsController(service: service);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: PindTheme.data,
      home: FriendsScreen(
        controller: controller,
        onOpenProfile: onOpenProfile,
        onOpenLink: onOpenLink,
      ),
    ),
  );
  controller.load();
  await tester.pumpAndSettle();
  return (controller, service);
}

void main() {
  final twelve = [for (var i = 1; i <= 12; i++) person(i, match: 100 - i)];

  testWidgets('shows the first five matches with percentages', (tester) async {
    await pump(tester, twelve);
    expect(find.text('친구 추가'), findsOneWidget);
    expect(find.text('취향이 비슷한 사람'), findsOneWidget);
    expect(find.text('사람1'), findsOneWidget);
    expect(find.text('@user1'), findsOneWidget);
    expect(find.text('취향 99% 일치'), findsOneWidget);
    expect(find.text('사람5'), findsOneWidget);
    expect(find.text('사람6'), findsNothing);
    expect(find.text('팔로우'), findsNWidgets(5));
    expect(find.text('더보기 ›'), findsOneWidget);
  });

  testWidgets('follow and unfollow flip the button and hit the service', (
    tester,
  ) async {
    final (_, service) = await pump(tester, twelve);
    await tester.tap(find.text('팔로우').first);
    await tester.pumpAndSettle();
    expect(service.followed, {'u1'});
    expect(find.text('팔로우 취소'), findsOneWidget);
    expect(find.text('사람1'), findsOneWidget, reason: 'stays until reload');

    await tester.tap(find.text('팔로우 취소'));
    await tester.pumpAndSettle();
    expect(service.followed, isEmpty);
    expect(find.text('팔로우'), findsNWidgets(5));
  });

  testWidgets('a failed follow reverts and explains', (tester) async {
    final (_, service) = await pump(tester, twelve);
    service.failFollow = true;
    await tester.tap(find.text('팔로우').first);
    await tester.pumpAndSettle();
    expect(find.text('팔로우 취소'), findsNothing);
    expect(find.text('팔로우하지 못했어요.'), findsOneWidget);
  });

  testWidgets('more skips people followed since the last page', (tester) async {
    final (controller, service) = await pump(tester, twelve);
    await tester.tap(find.text('팔로우').first); // 사람1 leaves the server set
    await tester.pumpAndSettle();
    await tester.tap(find.text('더보기 ›'));
    await tester.pumpAndSettle();
    expect(service.offsets.last, 4);
    expect(controller.model.matches.map((m) => m.profile.id), [
      for (var i = 1; i <= 12; i++) 'u$i',
    ], reason: 'no gap, no duplicate');
    expect(find.text('더보기 ›'), findsNothing);
  });

  testWidgets('search replaces the list and shows follow state', (
    tester,
  ) async {
    final (_, service) = await pump(tester, twelve);
    service.followed.add('u11');
    await tester.enterText(find.byType(TextField), 'user1');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(service.queries, ['user1']);
    expect(find.text('검색 결과 4명'), findsOneWidget);
    expect(find.text('내 코드 공유하기'), findsNothing);
    expect(find.text('링크로 초대하기'), findsOneWidget);
    // user1, user10, user11, user12
    expect(find.text('팔로우'), findsNWidgets(3));
    expect(find.text('팔로우 취소'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없어요.'), findsOneWidget);

    await tester.tap(find.byTooltip('지우기'));
    await tester.pumpAndSettle();
    expect(find.text('취향이 비슷한 사람'), findsOneWidget);
    expect(find.text('내 코드 공유하기'), findsOneWidget);
    expect(find.text('링크로 초대하기'), findsNothing);
  });

  test('invite text carries my profile link', () async {
    final none = FriendsController(service: FakeFriendsService(const []));
    final me = FriendsController(
      service: FakeFriendsService(const []),
      profile: _Me(
        const UserProfile(id: 'u0', handle: 'minchan', displayName: '민찬'),
      ),
    );
    addTearDown(none.dispose);
    addTearDown(me.dispose);
    expect(await none.inviteText(), isNot(contains('http')));
    expect(
      await me.inviteText(),
      'Pind에서 @minchan 님을 팔로우하고 음식 취향을 나눠요!\nhttps://pind-profile-links.vercel.app/@minchan',
    );
  });

  testWidgets('my code card opens the share screen', (tester) async {
    Future<void> open(ProfileLink link) async {}
    await pump(tester, const [], onOpenLink: open);
    await tester.tap(find.text('내 코드 공유하기'));
    await tester.pumpAndSettle();
    final screen = tester.widget<ShareCodeScreen>(find.byType(ShareCodeScreen));
    expect(screen.onOpenLink, open);
    expect(find.text('내 코드 공유'), findsOneWidget);
  });

  testWidgets('no matches shows the empty note', (tester) async {
    await pump(tester, const []);
    expect(find.text('아직 취향이 비슷한 사람이 없어요.'), findsOneWidget);
    expect(find.text('더보기 ›'), findsNothing);
  });

  testWidgets('tapping a person opens their profile', (tester) async {
    final opened = <String>[];
    final (controller, _) = await pump(
      tester,
      twelve,
      onOpenProfile: (c) => opened.add(c.profile.id),
    );
    await tester.tap(find.text('사람2'));
    expect(opened, ['u2']);
    controller.markFollowing('u2', true);
    await tester.pump();
    expect(find.text('팔로우 취소'), findsOneWidget, reason: 'synced back');
  });
}

class _Me implements ProfileService {
  const _Me(this.me);
  final UserProfile me;
  @override
  Future<UserProfile?> load() async => me;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
