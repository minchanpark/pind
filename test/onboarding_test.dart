import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/design_system.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/view/onboarding/onboarding_screen.dart';

void main() {
  testWidgets(
    'selection gates progress, back preserves selection and finish returns valid preferences',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      TastePreferences? completed;
      await tester.pumpWidget(
        MaterialApp(
          theme: PindTheme.data,
          home: OnboardingScreen(onComplete: (p) async => completed = p),
        ),
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        null,
      );
      await tester.tap(find.text('맛'));
      await tester.tap(find.text('분위기·공간'));
      await tester.tap(find.text('가성비'));
      await tester.pump();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('이전'));
      await tester.pumpAndSettle();
      expect(find.text('1순위'), findsOneWidget);
      expect(find.text('2순위'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        null,
      );
      for (final text in ['한식·백반', '고기구이', '국물·탕']) {
        await tester.tap(find.text(text));
        await tester.pump();
      }
      await tester.tap(find.text('내 취향 지도 만들기'));
      await tester.pumpAndSettle();
      expect(completed!.isComplete, true);
      expect(completed!.occasions, isEmpty);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'small screen and 200 percent text remain scrollable with no overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: PindTheme.data,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: OnboardingScreen(onComplete: (_) async {}),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('주차'), 150);
      expect(find.text('주차').hitTestable(), findsOneWidget);
      expect(tester.takeException(), null);
    },
  );
}
