import 'package:pind_flutter/model/detail_preview_model.dart';
import 'package:pind_flutter/controllers/place_detail_controller.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/theme.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/services/preview/detail_fixture.dart';
import 'package:pind_flutter/model/place_context.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/view/explore/place_sheet.dart';
import 'package:pind_flutter/view/explore/post_photo_viewer.dart';

Future<void> mount(
  WidgetTester tester,
  LocalDetailContext data, {
  Size size = const Size(402, 874),
  double scale = 1,
  Map<String, dynamic>? payload,
  Future<MapViewport?> Function(bool)? position,
  Future<void> Function(String, Rect)? share,
  Future<void> Function(String)? link,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: PindTheme.data,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: PlaceSheet(
            controller: PlaceDetailController(
              place: payload == null ? detailPlace : Place.fromJson(payload),
              places: payload == null
                  ? detailPlaces
                  : PlaceService((_) async => {'place': payload}),
              context: data,
              preferences: detailPreferences,
              position:
                  position ?? (_) async => const MapViewport(37.5712, 126.905),
              shareAction: share,
              linkAction: link,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('friend relationship and visit visibility matrix', () async {
    final repo = LocalDetailContext();
    for (final r in TestFriendship.values) {
      repo.relationship = r;
      expect(
        (await repo.load(900001)).visitors.length,
        r == TestFriendship.accepted ? 1 : 0,
      );
    }
    repo.relationship = TestFriendship.accepted;
    repo.publicVisit = false;
    expect((await repo.load(900001)).visitors, isEmpty);
    repo.publicVisit = true;
    repo.hasVisit = false;
    expect((await repo.load(900001)).visitors, isEmpty);
  });
  test(
    'today hours follow Korean date, review count stays unknown when omitted',
    () {
      final p = Place.fromJson({
        ...detailPayload,
        'weekdayDescriptions': [
          'Mon: 11:00–21:00',
          'Tue: closed',
          'Wed: closed',
          'Thu: closed',
          'Fri: closed',
          'Sat: closed',
          'Sun: 24 hours',
        ],
      });
      expect(todayHours(p, DateTime.utc(2026, 9, 27, 16)), '11:00–21:00');
      expect(todayHours(p, DateTime.utc(2026, 9, 27, 2)), '24 hours');
      expect(formatDistance(1800), '1.8km');
      expect(formatDistance(350), '350m');
      expect(
        directionsUri(p).queryParameters['destination_place_id'],
        'local-qa-only',
      );
      expect(
        Place.fromJson({...detailPayload, 'userRatingCount': null}).reviewCount,
        null,
      );
    },
  );
  testWidgets('glass header assets, real formula and friend row', (
    tester,
  ) async {
    await mount(tester, LocalDetailContext());
    expect(find.text('내 취향 94%'), findsOneWidget);
    expect(find.textContaining('11:30 – 21:00'), findsWidgets);
    expect(find.text('1.8km'), findsOneWidget);
    expect(find.text('리뷰 87개'), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-visits')), findsOneWidget);
    expect(find.byType(BackdropFilter), findsWidgets);
    const roots = {
      'close': 38.0,
      'location': 13.3989,
      'save': 13.4603,
      'share': 13.542,
      'directions': 15.4546,
    };
    for (final e in roots.entries) {
      final path = 'assets/place_detail/${e.key}_icon.svg';
      expect(File(path).lengthSync(), greaterThan(0));
      final finder = find.byWidgetPredicate(
        (w) =>
            w is SvgPicture &&
            w.bytesLoader is SvgAssetLoader &&
            (w.bytesLoader as SvgAssetLoader).assetName == path,
      );
      expect(finder, findsOneWidget);
      expect(tester.getSize(finder).width, closeTo(e.value, .001));
      expect(tester.getSize(finder).height, closeTo(e.value, .001));
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'no friends and no ratings do not fabricate social proof or score',
    (tester) async {
      await mount(
        tester,
        LocalDetailContext()
          ..relationship = TestFriendship.none
          ..hasRatings = false,
      );
      expect(find.byKey(const ValueKey('friend-visits')), findsNothing);
      expect(find.text('내 취향 평가 부족'), findsOneWidget);
    },
  );
  testWidgets(
    'actions stay fixed when expanded and scrolling; save persists, failure rolls back',
    (tester) async {
      final repo = LocalDetailContext();
      await mount(tester, repo);
      final actions = find.byKey(const ValueKey('detail-fixed-actions'));
      final bottom = tester.getBottomLeft(actions).dy;
      await tester.tap(find.byKey(const ValueKey('detail-save')));
      await tester.pumpAndSettle();
      expect(repo.saved, true);
      expect(find.text('저장됨'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('detail-expand')));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(actions).dy, bottom);
      repo.failSave = true;
      await tester.tap(find.byKey(const ValueKey('detail-save')));
      await tester.pumpAndSettle();
      expect(find.text('저장됨'), findsOneWidget);
      expect(repo.saved, true);
      expect(find.textContaining('저장하지 못했어요'), findsOneWidget);
    },
  );
  testWidgets(
    'share gets source URL and origin; directions uses navigation URL',
    (tester) async {
      String? shared, opened;
      Rect? rect;
      await mount(
        tester,
        LocalDetailContext(),
        share: (t, r) async {
          shared = t;
          rect = r;
        },
        link: (u) async => opened = u,
      );
      await tester.tap(find.byKey(const ValueKey('detail-share')));
      await tester.pump();
      expect(shared, contains(detailPlace.mapsUri));
      expect(rect!.width, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('detail-directions')));
      await tester.pump();
      expect(opened, contains('/maps/dir/'));
    },
  );
  testWidgets(
    '320px 200 percent text fixed actions remain usable without location',
    (tester) async {
      await mount(
        tester,
        LocalDetailContext(),
        size: const Size(320, 568),
        scale: 2,
        position: (_) async => null,
      );
      expect(find.text('거리 확인'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('detail-save')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('detail-directions')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('detail keeps only today hours and one directions action', (
    tester,
  ) async {
    await mount(
      tester,
      LocalDetailContext(),
      payload: {
        ...detailPayload,
        'phoneNumber': '02-1234-5678',
        'websiteUri': 'https://example.com/shop',
      },
    );
    await tester.tap(find.byKey(const ValueKey('detail-expand')));
    await tester.pumpAndSettle();
    expect(find.textContaining('11:30 – 21:00'), findsOneWidget);
    expect(find.bySemanticsLabel('전체 영업시간'), findsNothing);
    for (final day in ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일']) {
      expect(find.textContaining('$day:'), findsNothing);
    }
    expect(find.text('02-1234-5678'), findsNothing);
    expect(find.text('웹사이트'), findsNothing);
    expect(find.text('Google Maps에서 길찾기'), findsNothing);
    expect(find.text('정보 제공: Google Maps'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('detail-directions')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('intro tab shows AI summary and one-liners for priorities', (
    tester,
  ) async {
    final photo = {'uri': 'assets/preview/place_detail_photo_1.png'};
    await mount(
      tester,
      LocalDetailContext(),
      payload: {
        ...detailPayload,
        'gallery': List.filled(7, photo),
        'insight': {
          'summary': '무화과 타르트로 알려진 디저트 카페예요.',
          'criteria': {'taste': '달지 않고 깔끔해요', 'quiet': '조용해요'},
        },
      },
    );
    // Photos live in the intro tab only, not under the taste ratings.
    expect(find.byKey(const ValueKey('detail-photo-0')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('detail-expand')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('detail-intro-photo-4'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('detail-intro-photo-5'), skipOffstage: false),
      findsNothing,
    );
    expect(find.text('무화과 타르트로 알려진 디저트 카페예요.'), findsOneWidget);
    expect(find.text('맛 · 양 · 분위기·공간 한 줄 요약'), findsOneWidget);
    expect(find.text('달지 않고 깔끔해요'), findsOneWidget);
    expect(find.text('조용해요'), findsNothing);
    expect(find.text('아직 한 줄 평이 없어요.'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('posts tab shows author, text, fanned photos and ratings', (
    tester,
  ) async {
    const a = 'assets/preview/place_detail_photo_1.png';
    const b = 'assets/preview/place_detail_photo_2.png';
    await mount(
      tester,
      LocalDetailContext(),
      payload: {
        ...detailPayload,
        'posts': [
          {
            'author': '유하람',
            'handle': 'haramsyoo',
            'body': '분위기도 좋고 음식도 맛있어요.',
            'ratings': {'ambience': 3, 'taste': 4, 'portion': 4},
            'photos': [a, b, a, b, a, b],
          },
          {
            'author': 'itisnewdawn',
            'photos': [b],
            'ratings': {'quiet': 5},
          },
          ...List.filled(3, {
            'author': 'more',
            'photos': [b],
          }),
        ],
      },
    );
    await tester.tap(find.byKey(const ValueKey('detail-expand')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('detail-tab-1')));
    await tester.pumpAndSettle();
    final first = find.byKey(const ValueKey('detail-post-0'));
    Finder inFirst(Finder f) => find.descendant(of: first, matching: f);
    Finder chip(String label) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == label,
      skipOffstage: false,
    );
    expect(inFirst(find.text('@haramsyoo')), findsOneWidget);
    expect(inFirst(find.textContaining('유하람')), findsNothing);
    // No handle yet: the display name, without '@'.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('detail-post-1'), skipOffstage: false),
        matching: find.text('itisnewdawn', skipOffstage: false),
      ),
      findsOneWidget,
    );
    expect(inFirst(find.text('분위기도 좋고 음식도 맛있어요.')), findsOneWidget);
    expect(inFirst(find.byType(Image)), findsNWidgets(3));
    expect(inFirst(find.text('+ 3')), findsOneWidget);
    for (final label in ['맛 4점', '양 4점', '분위기·공간 3점']) {
      expect(chip(label), findsOneWidget);
    }
    // Tapping a post photo opens the pager at that photo.
    await tester.tap(find.bySemanticsLabel('게시물 사진 2 크게 보기').first);
    await tester.pumpAndSettle();
    expect(find.byType(PostPhotoViewer), findsOneWidget);
    expect(find.bySemanticsLabel('게시물 사진 2/6'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('게시물 사진 3/6'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('photo-viewer-back')));
    await tester.pumpAndSettle();
    expect(find.byType(PostPhotoViewer), findsNothing);
    expect(find.text('@haramsyoo'), findsOneWidget);
    final second = find.byKey(
      const ValueKey('detail-post-1'),
      skipOffstage: false,
    );
    await tester.ensureVisible(second);
    await tester.pumpAndSettle();
    expect(find.text('itisnewdawn'), findsOneWidget);
    expect(
      find.descendant(of: second, matching: find.byType(Image)),
      findsOneWidget,
    );
    expect(chip('조용함 5점'), findsOneWidget);
    expect(find.text('아직 게시물이 없어요.'), findsNothing);

    // Fully expanded: the body scrolls under tabs that stay pinned on top.
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    final tabs = find.byKey(const ValueKey('detail-tabs'));
    final sheetTop = tester.getTopLeft(find.byType(PlaceSheet)).dy;
    expect(tester.getTopLeft(tabs).dy, closeTo(sheetTop, 1));
    expect(
      find.byKey(const ValueKey('detail-post-0')).hitTestable(),
      findsNothing,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Figma tabs fill equal halves and switch underline and content', (
    tester,
  ) async {
    await mount(tester, LocalDetailContext());
    await tester.tap(find.byKey(const ValueKey('detail-expand')));
    await tester.pumpAndSettle();
    final intro = find.byKey(const ValueKey('detail-tab-0'));
    final posts = find.byKey(const ValueKey('detail-tab-1'));
    final tabs = find.byKey(const ValueKey('detail-tabs'));
    final introLine = find.byKey(const ValueKey('detail-tab-line-0'));
    final postsLine = find.byKey(const ValueKey('detail-tab-line-1'));
    expect(tester.getSize(tabs).width, 402);
    expect(tester.getSize(intro).width, 201);
    expect(tester.getSize(posts).width, 201);
    expect(tester.getSize(introLine).height, 3);
    expect(tester.getSize(postsLine).height, 1);
    expect(
      tester.widget<Text>(find.text('소개')).style!.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text('게시물')).style!.color,
      const Color(0xFF9B9B9B),
    );
    expect(find.text(detailPlace.summary!), findsOneWidget);

    await tester.tap(posts);
    await tester.pumpAndSettle();
    expect(tester.getSize(introLine).height, 1);
    expect(tester.getSize(postsLine).height, 3);
    expect(
      tester.widget<Text>(find.text('게시물')).style!.fontWeight,
      FontWeight.w700,
    );
    expect(find.text(detailPlace.summary!), findsNothing);
    expect(find.text('아직 게시물이 없어요.'), findsOneWidget);

    await tester.tap(intro);
    await tester.pumpAndSettle();
    expect(find.text(detailPlace.summary!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens down to the hint; raising folds it away and expands', (
    tester,
  ) async {
    await mount(tester, LocalDetailContext());
    final hint = find.byKey(const ValueKey('detail-expand'));
    final footer = find.byKey(const ValueKey('detail-fixed-actions'));
    // The hint sits right on top of the action bar; the tabs are below it.
    expect(hint.hitTestable(), findsOneWidget);
    expect(
      tester.getBottomLeft(hint).dy,
      moreOrLessEquals(tester.getTopLeft(footer).dy, epsilon: 1),
    );
    expect(
      find.byKey(const ValueKey('detail-tabs')).hitTestable(),
      findsNothing,
    );

    // Halfway up the hint is fading out.
    final sheet = find.byType(DraggableScrollableSheet);
    final gesture = await tester.startGesture(tester.getCenter(hint));
    await gesture.moveBy(const Offset(0, -20)); // past the drag slop
    await gesture.moveBy(const Offset(0, -150));
    await tester.pump();
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: hint, matching: find.byType(Opacity)),
    );
    expect(opacity.opacity, inExclusiveRange(0, 1));
    await gesture.moveBy(const Offset(0, -600));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.getSize(sheet).height,
      moreOrLessEquals(874 * .96, epsilon: 1),
    );
    expect(hint, findsNothing);
    expect(
      find.byKey(const ValueKey('detail-tabs')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('detail-intro')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pind post photos carry no 사진: credit', (tester) async {
    await mount(
      tester,
      LocalDetailContext(),
      payload: {
        ...detailPayload,
        'provider': 'sbiz',
        'gallery': [
          {
            'uri': 'assets/preview/place_detail_photo_1.png',
            'attributions': [
              {'displayName': '하람'},
            ],
          },
        ],
      },
    );
    await tester.tap(find.byKey(const ValueKey('detail-expand')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('detail-intro-photo-0'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('사진: 하람', skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'photo credits stay beneath their own photo at text scale $scale',
      (tester) async {
        String? opened;
        const author = '아주 긴 이름의 사진 제공자 Alice';
        const authorUri = 'https://example.com/author/alice';
        const sourceUri = 'https://www.google.com/maps/photo/first';
        await mount(
          tester,
          LocalDetailContext(),
          scale: scale,
          payload: {
            ...detailPayload,
            'gallery': [
              {
                'uri': 'assets/preview/place_detail_photo_1.png',
                'googleMapsUri': sourceUri,
                'attributions': [
                  {'displayName': author, 'uri': authorUri},
                ],
              },
              {
                'uri': 'assets/preview/place_detail_photo_2.png',
                'attributions': [
                  {'displayName': 'Bob'},
                ],
              },
            ],
          },
          link: (uri) async => opened = uri,
        );
        await tester.tap(find.byKey(const ValueKey('detail-expand')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('사진: $author').first,
          200,
          scrollable: find
              .descendant(
                of: find.byType(CustomScrollView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pumpAndSettle();
        final first = find.byKey(const ValueKey('detail-intro-photo-0'));
        final firstImage = find.descendant(
          of: first,
          matching: find.byType(Image),
        );
        final credit = find.descendant(
          of: first,
          matching: find.text('사진: $author'),
        );
        expect(credit, findsOneWidget);
        expect(
          find.descendant(of: first, matching: find.text('사진: Bob')),
          findsNothing,
        );
        expect(
          tester.getTopLeft(credit).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(firstImage).dy),
        );
        expect(tester.widget<Text>(credit).style!.fontSize, 9);
        await tester.ensureVisible(credit);
        await tester.pumpAndSettle();
        await tester.tap(credit);
        await tester.pump();
        expect(opened, authorUri);
        final source = find.descendant(of: first, matching: find.text('사진 출처'));
        await tester.ensureVisible(source);
        await tester.pumpAndSettle();
        await tester.tap(source);
        await tester.pump();
        expect(opened, sourceUri);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
