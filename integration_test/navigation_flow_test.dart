import 'package:pind_flutter/model/navigation_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pind_flutter/view/design_system.dart';
import 'package:pind_flutter/view/navigation/main_shell.dart';
import 'package:pind_flutter/view/navigation/pind_navigation_bar.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  // Isolate navigation from remote APIs. This does not validate Places or tiles.
  testWidgets('native navigation selection, compose, and return flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PindTheme.data,
        home: MainShell(
          controller: null,
          mapsEnabled: false,
          onEditPreferences: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<PindNavigationBar>(find.byType(PindNavigationBar)).selected,
      PindTab.map,
    );
    await binding.takeScreenshot('navigation-qa-map');

    await tester.tap(find.byKey(const ValueKey('nav-discover')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PindNavigationBar>(find.byType(PindNavigationBar)).selected,
      PindTab.discover,
    );
    await binding.takeScreenshot('navigation-qa-discover');

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PindNavigationBar>(find.byType(PindNavigationBar)).selected,
      PindTab.profile,
    );
    await binding.takeScreenshot('navigation-qa-profile');

    await tester.tap(find.byKey(const ValueKey('nav-compose')));
    await tester.pumpAndSettle();
    expect(find.byType(PindNavigationBar), findsNothing);
    await binding.takeScreenshot('navigation-qa-compose');
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PindNavigationBar>(find.byType(PindNavigationBar)).selected,
      PindTab.profile,
    );

    await tester.tap(find.byKey(const ValueKey('nav-map')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PindNavigationBar>(find.byType(PindNavigationBar)).selected,
      PindTab.map,
    );
    expect(tester.takeException(), isNull);
  });
}
