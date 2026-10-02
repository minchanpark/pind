import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/post_controller.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/view/explore/explore_screen.dart';
import 'package:pind_flutter/view/posts/post_place_picker.dart';
import 'package:pind_flutter/view/design_system.dart';

import 'post_flow_test.dart' show TestPhotos, TestPosts;

/// Current position: 을지로3가역.
const here = MapViewport(37.5663, 126.9910);

/// [meters] north of [here] (1° latitude ≈ 111.2km).
Map<String, dynamic> row(int id, String name, double meters) => {
  'provider': 'sbiz',
  'internalId': id,
  'externalPlaceId': 'p$id',
  'name': name,
  'category': '고기구이',
  'address': '서울 중구 을지로3가 $id',
  'latitude': here.latitude + meters / 111200,
  'longitude': here.longitude,
  'sourceUri': 'https://example.com/$id',
};

Place place(int id, String name, [String address = '서울 중구 을지로3가 1']) =>
    Place.fromJson({...row(id, name, 0), 'address': address});

Future<PostController> pump(
  WidgetTester tester, {
  MapViewport? position = here,
  ProfileOverview? mine,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 1200);
  addTearDown(tester.view.reset);
  final asked = <bool>[];
  final controller = PostController(
    posts: TestPosts(),
    photos: TestPhotos(),
    // Nearest last, so sorting is visible; 먼곳 is 12km away.
    places: PlaceService(
      (_) async => {
        'places': [
          row(4, '을지로 평양냉면', 9000),
          row(3, '먼곳 을지로 냉면', 12000),
          row(2, '을지로 골뱅이', 400),
          row(1, '을지로 숯불갈비', 200),
        ],
      },
    ),
    mine: () => mine,
    position: (request) async {
      asked.add(request);
      return position;
    },
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: PindTheme.data,
      home: Scaffold(body: PostPlacePicker(controller: controller)),
    ),
  );
  await tester.pump();
  expect(asked, [false], reason: 'opening never prompts for location');
  return controller;
}

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

List<String> names(WidgetTester tester) => [
  for (final t in tester.widgetList<RichText>(find.byType(RichText)))
    if (t.text.toPlainText().contains('을지로') &&
        !t.text.toPlainText().contains('·'))
      t.text.toPlainText(),
]..removeWhere((n) => n == '을지로');

void main() {
  test('highlight marks the first case-insensitive match', () {
    final span = highlight('Pind Cafe', 'cafe');
    expect(span.children!.map((c) => (c as TextSpan).text), [
      'Pind ',
      'Cafe',
      '',
    ]);
    expect((span.children![1] as TextSpan).style!.color, PindColors.purple);
    expect(highlight('을지면옥', '을지로').children, isNull);
  });

  test('shortAddress keeps 구 and 동, drops city and lot', () {
    expect(shortAddress('서울 중구 을지로3가 12-1'), '중구 을지로3가');
    expect(shortAddress('서울특별시 성동구 성수이로 7'), '성동구 성수이로');
  });

  testWidgets('results go nearest first with distance and purple keyword', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, '을지로');
    expect(names(tester), ['을지로 숯불갈비', '을지로 골뱅이', '을지로 평양냉면', '먼곳 을지로 냉면']);
    expect(find.text('고기구이 · 중구 을지로3가 · 200m'), findsOneWidget);
    expect(find.text('고기구이 · 중구 을지로3가 · 12.0km'), findsOneWidget);
    final title = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((t) => t.text.toPlainText() == '을지로 숯불갈비');
    final purple = <String>[];
    title.text.visitChildren((span) {
      if (span is TextSpan && span.style?.color == PindColors.purple) {
        purple.add(span.text!);
      }
      return true;
    });
    expect(purple, ['을지로']);
  });

  testWidgets('each result leads with the map pin for its category', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, '을지로');
    expect(find.byType(PlacePin), findsNWidgets(4));
    // 고기구이 → the map's 🥩 고기 chip.
    expect(find.text('🥩'), findsNWidgets(4));
    expect(markerEmoji(place(9, '연남 커피')), '☕');
    expect(markerEmoji(place(9, '이름만 있는 곳').copyWithCategory('한식')), '🍽️');
  });

  testWidgets('현재 위치 주변 keeps places within 10km', (tester) async {
    await pump(tester);
    await type(tester, '을지로');
    await tester.tap(find.text('📍 현재 위치 주변'));
    await tester.pumpAndSettle();
    expect(names(tester), ['을지로 숯불갈비', '을지로 골뱅이', '을지로 평양냉면']);
    await tester.tap(find.text('📍 현재 위치 주변'));
    await tester.pumpAndSettle();
    expect(names(tester), hasLength(4), reason: 'tapping again clears it');
  });

  testWidgets('현재 위치 주변 asks for location and explains a refusal', (
    tester,
  ) async {
    await pump(tester, position: null);
    await type(tester, '을지로');
    expect(find.textContaining('·  m'), findsNothing);
    await tester.tap(find.text('📍 현재 위치 주변'));
    await tester.pumpAndSettle();
    expect(find.text('현재 위치를 확인할 수 없어요. 위치 권한을 확인해 주세요.'), findsOneWidget);
    expect(names(tester), isEmpty);
  });

  testWidgets('최근 방문 and 저장한 곳 filter my lists by the keyword', (tester) async {
    await pump(
      tester,
      mine: ProfileOverview(
        profile: const UserProfile(id: 'me', displayName: '나'),
        recentViews: [
          ProfilePlaceCard(place: place(5, '을지로 커피한약방')),
          ProfilePlaceCard(place: place(6, '성수 비빔밥', '서울 성동구 성수동1가 1')),
        ],
        savedPlaces: [ProfilePlaceCard(place: place(7, '을지면옥', '서울 중구 충무로 1'))],
      ),
    );
    await tester.tap(find.text('최근 방문'));
    await tester.pumpAndSettle();
    expect(find.text('성수 비빔밥'), findsOneWidget, reason: 'no keyword: all');
    await tester.enterText(find.byType(TextField), '을지로');
    await tester.pump();
    expect(names(tester), ['을지로 커피한약방'], reason: 'filters as you type');
    expect(find.text('성수 비빔밥'), findsNothing);

    await tester.tap(find.text('저장한 곳'));
    await tester.pumpAndSettle();
    expect(find.text('저장한 곳 중에 없어요.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '을지');
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == '을지면옥',
      ),
      findsOneWidget,
    );
  });

  testWidgets('선택 returns the place', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = await pump(tester);
    Place? picked;
    final context = tester.element(find.byType(PostPlacePicker));
    showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PostPlacePicker(controller: controller),
    ).then((p) => picked = p);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '을지로');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('을지로 골뱅이 선택'));
    await tester.pumpAndSettle();
    expect(picked?.id, 2);
    semantics.dispose();
  });
}

extension on Place {
  Place copyWithCategory(String category) =>
      Place.fromJson({...row(id!, name, 0), 'category': category});
}
