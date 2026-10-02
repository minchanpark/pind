import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/model/nearby_ranking.dart';
import 'package:pind_flutter/model/place_search_result.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/view/explore/agent_search_page.dart';
import 'package:pind_flutter/view/profile/saved_places_page.dart';

const step = Duration(milliseconds: 700);

/// Chat lines may sit just below the fold until the page scrolls to them.
Finder line(String text) => find.text(text, skipOffstage: false);

RankedPlace ranked(int id, String name, {bool saved = false}) => RankedPlace(
  place: Place(
    id: id,
    provider: PlaceProvider.sbiz,
    externalId: 'p$id',
    name: name,
    category: '한식',
    address: '경북 포항시 북구 양덕동 $id',
    latitude: 36.0,
    longitude: 129.3,
    mapsUri: 'https://example.com',
  ),
  meters: 302,
  averages: const {
    PreferenceCriterion.taste: 5,
    PreferenceCriterion.portion: 3,
    PreferenceCriterion.ambience: 4,
  },
  reviewCount: 1,
  saved: saved,
);

void main() {
  final asked = <String>[];
  final opened = <String>[];
  final saves = <(int, bool)>[];
  late Completer<AgentAnswer> answer;

  Future<void> open(WidgetTester tester) async {
    asked.clear();
    opened.clear();
    saves.clear();
    answer = Completer();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AgentSearchPage(
                  search: (q) {
                    asked.add(q);
                    return answer.future;
                  },
                  preferences: TastePreferences(
                    priorities: const [
                      PreferenceCriterion.taste,
                      PreferenceCriterion.portion,
                      PreferenceCriterion.ambience,
                    ],
                  ),
                  onOpen: (_, place) => opened.add(place.name),
                  onSetSaved: (id, saved) async => saves.add((id, saved)),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('title, ten suggestions in two columns, ask field', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('개인 맞춤형 음식 검색'), findsOneWidget);
    expect(find.text('원하는 취향을 자세히 알려주면 추천 내용이 더 정확해집니다.'), findsOneWidget);
    expect(find.text('무엇이든 물어보세요...'), findsOneWidget);
    for (final (_, text) in AgentSearchPage.suggestions) {
      expect(find.text(text), findsOneWidget);
    }
    // Two columns: the first two suggestions share a row.
    final a = tester.getRect(find.text('매움 단계를 선택할 수 있는 식당'));
    final b = tester.getRect(find.text('한국 BBQ를 즐기면서 분위기 좋은 고깃집'));
    expect(a.top, b.top);
    expect(a.left, lessThan(b.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress lines, then a fold-down list of saved-style cards', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('혼술 하기 좋은 식당'));
    await tester.pump();
    expect(asked, ['혼술 하기 좋은 식당']);
    // The page stays; the question and the first line appear beneath it.
    expect(find.text('개인 맞춤형 음식 검색'), findsOneWidget);
    expect(find.text('혼술 하기 좋은 식당'), findsNWidgets(2));
    expect(line(AgentSearchPage.steps[0]), findsOneWidget);
    expect(line(AgentSearchPage.steps[1]), findsNothing);
    // An early answer still waits for every line.
    answer.complete((
      notice: '혼술 · 포차 기준으로 찾았어요.',
      places: [ranked(1, '화담면옥'), ranked(2, '성수 포차', saved: true)],
    ));
    await tester.pump(step);
    expect(line(AgentSearchPage.steps[1]), findsOneWidget);
    expect(find.text('추천 장소 2곳'), findsNothing);
    await tester.pump(step);
    expect(line('당신의 취향에 맞는 장소를 검색하고 있어요'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('혼술 · 포차 기준으로 찾았어요.'), findsOneWidget);
    expect(find.text('추천 장소 2곳'), findsOneWidget);
    // Cards as on 저장한 장소: area · distance · reviews, match, ratings.
    expect(find.byType(SavedPlaceRow), findsNWidgets(2));
    expect(find.text('화담면옥'), findsOneWidget);
    expect(find.text('양덕동 · 302m · 리뷰 1'), findsNWidgets(2));
    expect(find.text('80%'), findsNWidgets(2));
    // No 방금 저장 line.
    expect(find.textContaining('저장', findRichText: true), findsNothing);

    await tester.tap(find.text('화담면옥'));
    expect(opened, ['화담면옥']);
    await tester.ensureVisible(find.bySemanticsLabel('저장').first);
    await tester.tap(find.bySemanticsLabel('저장').first);
    await tester.pump();
    expect(saves, [(1, true)]);
    expect(find.bySemanticsLabel('저장 취소'), findsNWidgets(2));

    // The bar folds the list away and back.
    await tester.ensureVisible(
      find.byKey(const ValueKey('agent-results-toggle')),
    );
    await tester.tap(find.byKey(const ValueKey('agent-results-toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(SavedPlaceRow), findsNothing);
    expect(find.text('추천 장소 2곳'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('agent-results-toggle')));
    await tester.pumpAndSettle();
    expect(find.byType(SavedPlaceRow), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('typed text asks via keyboard or the send button', (
    tester,
  ) async {
    await open(tester);
    // Empty: the mic only explains it is coming.
    await tester.tap(find.bySemanticsLabel('음성 검색'));
    await tester.pump();
    expect(find.text('음성 검색은 준비 중이에요.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  매운 국밥  ');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('검색'));
    await tester.pump();
    expect(asked, ['매운 국밥']);
    // One question at a time.
    await tester.enterText(find.byType(TextField), '성수 카페');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(asked, ['매운 국밥']);
    answer.complete((notice: null, places: <RankedPlace>[]));
    await tester.pump(step * 2);
    await tester.pumpAndSettle();
    expect(find.text('추천 장소 0곳'), findsOneWidget);
    expect(find.textContaining('맞는 곳을 찾지 못했어요'), findsOneWidget);
    answer = Completer();
    await tester.enterText(find.byType(TextField), '성수 카페');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(asked, ['매운 국밥', '성수 카페']);
    // A new question replaces the last answer.
    expect(find.text('추천 장소 0곳'), findsNothing);
    answer.completeError(const PlaceFailure('검색어를 2~120자로 입력해 주세요.'));
    await tester.pump(step * 2);
    await tester.pumpAndSettle();
    expect(find.text('검색어를 2~120자로 입력해 주세요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('close returns to the map', (tester) async {
    await open(tester);
    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(AgentSearchPage), findsNothing);
  });
}
