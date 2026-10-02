import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/explore/agent_search_page.dart';

/// Map search opens the agent page; type there and submit. The page stays
/// open with the answer. Fixed pumps: the progress spinner never settles.
Future<void> mapSearch(WidgetTester tester, String text) async {
  await tester.tap(find.byKey(const ValueKey('map-search-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  // Every progress line shows before the answer.
  for (var i = 0; i < AgentSearchPage.steps.length; i++) {
    await tester.pump(const Duration(milliseconds: 700));
  }
  await tester.pump(const Duration(milliseconds: 600));
}
