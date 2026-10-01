import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/explore/agent_search_page.dart';

void main() {
  Future<List<String?>> open(WidgetTester tester) async {
    final results = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const AgentSearchPage()),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
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

  testWidgets('a suggestion returns its text', (tester) async {
    final results = await open(tester);
    await tester.tap(find.text('혼술 하기 좋은 식당'));
    await tester.pumpAndSettle();
    expect(results, ['혼술 하기 좋은 식당']);
  });

  testWidgets('typed text returns via keyboard or the send button', (
    tester,
  ) async {
    final results = await open(tester);
    // Empty: the mic only explains it is coming.
    await tester.tap(find.bySemanticsLabel('음성 검색'));
    await tester.pump();
    expect(find.text('음성 검색은 준비 중이에요.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  매운 국밥  ');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('검색'));
    await tester.pumpAndSettle();
    expect(results, ['매운 국밥']);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '성수 카페');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(results, ['매운 국밥', '성수 카페']);
  });

  testWidgets('close returns nothing', (tester) async {
    final results = await open(tester);
    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });
}
