import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:pind_flutter/model/nearby_ranking.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/view/explore/nearby_ranking_sheet.dart';
import 'package:pind_flutter/view/design_system.dart';

Map<String, dynamic> row(
  int id,
  String name,
  int meters, {
  String category = '카페',
  Map<String, num> averages = const {},
  Map<String, dynamic>? visitedBy,
  Map<String, dynamic>? savedBy,
  int saveCount = 0,
  bool saved = false,
}) => {
  'provider': 'sbiz',
  'internalId': id,
  'externalPlaceId': 'p$id',
  'name': name,
  'category': category,
  'address': '서울 성동구 성수동 1',
  'latitude': 37.54,
  'longitude': 127.05,
  'sourceUri': 'https://example.com/$id',
  'meters': meters,
  'averages': averages,
  'reviewCount': 3,
  'saveCount': saveCount,
  'saved': saved,
  'visitedBy': ?visitedBy,
  'savedBy': ?savedBy,
};

Map<String, dynamic> people(int count, List<String> names) => {
  'count': count,
  'people': [
    for (final n in names) {'name': n, 'avatar': null},
  ],
};

final prefs = TastePreferences(
  priorities: [
    PreferenceCriterion.taste,
    PreferenceCriterion.portion,
    PreferenceCriterion.ambience,
  ],
  cuisines: Cuisine.values.take(3),
);

/// Nearest first, as the server sends them.
final rows = [
  RankedPlace.fromJson(
    row(1, '가까운집', 300, averages: {'taste': 3, 'portion': 5, 'ambience': 3}),
  ),
  RankedPlace.fromJson(
    row(
      2,
      '맛집',
      800,
      averages: {'taste': 5, 'portion': 3, 'ambience': 5},
      saveCount: 1411,
    ),
  ),
  RankedPlace.fromJson(row(3, '평가없음', 900)),
  RankedPlace.fromJson(
    row(4, '술집', 1000, category: '호프', averages: {'taste': 5}),
  ),
];

void main() {
  test('friend line prefers visits, then saves', () {
    String? line(Map<String, dynamic> json) =>
        RankedPlace.fromJson(json).friendLine;
    expect(line(row(1, 'a', 1, visitedBy: people(1, ['하람']))), '하람님이 다녀감');
    expect(
      line(
        row(
          1,
          'a',
          1,
          visitedBy: people(2, ['하람', '민']),
          savedBy: people(1, ['조']),
        ),
      ),
      '하람 외 1명이 다녀감',
    );
    expect(
      line(row(1, 'a', 1, visitedBy: people(0, []), savedBy: people(1, ['조']))),
      '조님이 저장함',
    );
    expect(line(row(1, 'a', 1)), isNull);
  });

  test('rankPlaces: taste match, then one criterion; unscored last', () {
    List<String> names(PreferenceCriterion? by) => [
      for (final p in rankPlaces(rows, prefs, by)) p.place.name,
    ];
    // 맛집 scores higher on the 50% axis; the others lack an axis.
    expect(names(null), ['맛집', '가까운집', '평가없음', '술집']);
    expect(names(PreferenceCriterion.portion), ['가까운집', '맛집', '평가없음', '술집']);
    // Tie on 5: nearer first.
    expect(names(PreferenceCriterion.taste), ['맛집', '술집', '가까운집', '평가없음']);
  });

  test('nearbyRanking falls back to the map center without location', () async {
    final asked = <MapViewport>[];
    ExploreController controller(Future<MapViewport?> Function(bool) at) =>
        ExploreController(
          PlaceService((_) async => {}),
          nearby: (here, {radius = 10000}) async {
            asked.add(here);
            return rows;
          },
          position: at,
        );
    const center = MapViewport(37.5, 127.0), me = MapViewport(37.6, 127.1);
    var r = await controller((_) async => me).nearbyRanking(center);
    expect((r.nearMe, asked.last), (true, me));
    r = await controller((_) async => null).nearbyRanking(center);
    expect((r.nearMe, asked.last), (false, center));
    r = await controller((_) async => throw Exception()).nearbyRanking(center);
    expect((r.nearMe, asked.last), (false, center));
  });

  Future<List<(int, bool)>> pump(
    WidgetTester tester, {
    bool nearMe = true,
    bool fail = false,
    List<String>? opened,
  }) async {
    final saves = <(int, bool)>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: PindTheme.data,
        home: Scaffold(
          body: NearbyRankingSheet(
            key: UniqueKey(),
            title: '☕ 카페',
            load: () async =>
                fail ? throw Exception() : (places: rows, nearMe: nearMe),
            include: (p) => p.category == '카페',
            preferences: prefs,
            onOpen: (p) => opened?.add(p.name),
            onSetSaved: (id, saved) async => saves.add((id, saved)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return saves;
  }

  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  testWidgets('sheet ranks the category by taste, then by a criterion', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('☕ 카페'), findsOneWidget);
    expect(find.text('술집'), findsNothing); // filtered by category
    expect(top(tester, '맛집'), lessThan(top(tester, '가까운집')));
    expect(find.text('취향'), findsNWidgets(2));
    expect(find.text('카페 · 300m · 리뷰 3'), findsOneWidget);
    await tester.tap(find.text('양'));
    await tester.pumpAndSettle();
    expect(top(tester, '가까운집'), lessThan(top(tester, '맛집')));
    expect(find.text('취향'), findsNothing);
    // Only 양 chips: the selected sort chip plus both cafes; no 맛 or 분위기.
    expect(find.text('🍚'), findsNWidgets(3));
    expect(find.text('😋'), findsNothing);
    expect(find.text('현재 위치를 확인하지 못해 지도 중심 10km 기준이에요.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bookmark saves with an updated count', (tester) async {
    final saves = await pump(tester);
    await tester.tap(find.bySemanticsLabel('저장').first);
    await tester.pumpAndSettle();
    expect(saves, [(2, true)]);
    expect(find.text('1,412'), findsOneWidget);
    expect(find.bySemanticsLabel('저장 취소'), findsOneWidget);
  });

  testWidgets('tapping a place closes the sheet and reports it', (
    tester,
  ) async {
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showNearbyRanking(
              context,
              title: '☕ 카페',
              load: () async => (places: rows, nearMe: true),
              include: (p) => p.category == '카페',
              preferences: prefs,
              onOpen: (p) => opened.add(p.name),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('가까운집'));
    await tester.pumpAndSettle();
    expect(opened, ['가까운집']);
    expect(find.byType(NearbyRankingSheet), findsNothing);
  });

  testWidgets('map-center fallback note and retry on failure', (tester) async {
    await pump(tester, nearMe: false);
    expect(find.text('현재 위치를 확인하지 못해 지도 중심 10km 기준이에요.'), findsOneWidget);
    await pump(tester, fail: true);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  test('thousands separators', () {
    expect(
      [thousands(640), thousands(1412), thousands(1234567)],
      ['640', '1,412', '1,234,567'],
    );
  });
}
