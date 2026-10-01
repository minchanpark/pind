import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Map search now opens the agent page; type there and submit. Fixed pumps,
/// not pumpAndSettle: a previous search's spinner may still be running.
Future<void> mapSearch(WidgetTester tester, String text) async {
  await tester.tap(find.byKey(const ValueKey('map-search-button')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}
