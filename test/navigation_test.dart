import 'package:pind_flutter/model/navigation_model.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/theme.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/view/explore/explore_screen.dart';
import 'package:pind_flutter/view/navigation/main_shell.dart';
import 'package:pind_flutter/view/navigation/pind_navigation_bar.dart';

const roots = <String, Size>{
  'map_active': Size(22.5344, 22.5344),
  'map_inactive': Size(22.5344, 22.5344),
  'discover_active_ring': Size(25.0344, 25.0344),
  'discover_inactive_ring': Size(25.0344, 25.0344),
  'discover_active_needle': Size(10.0115, 10.0115),
  'discover_inactive_needle': Size(10.0115, 10.0115),
  'profile_active_body': Size(23.1603, 10.6412),
  'profile_inactive_body': Size(23.1603, 10.6412),
  'profile_active_head': Size(10.6412, 10.6412),
  'profile_inactive_head': Size(10.6412, 10.6412),
  'compose_outline': Size(23.7863, 23.7863),
  'compose_lines': Size(10.0153, 10.0153),
};

Future<void> shell(WidgetTester tester, {PlaceService? repository}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PindTheme.data,
      home: MainShell(
        controller: repository == null ? null : ExploreController(repository),
        mapsEnabled: false,
        onEditPreferences: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('all twelve original SVGs exist and retain root dimensions', (
    tester,
  ) async {
    for (final asset in roots.entries) {
      final svg = await rootBundle.loadString(
        'assets/figma/nav_${asset.key}.svg',
      );
      final root = RegExp(r'<svg\b[^>]*>').firstMatch(svg)!.group(0)!;
      final width = double.parse(
        RegExp(r'\bwidth="([\d.]+)"').firstMatch(root)!.group(1)!,
      );
      final height = double.parse(
        RegExp(r'\bheight="([\d.]+)"').firstMatch(root)!.group(1)!,
      );
      expect(Size(width, height), asset.value);
      expect(svg.length, greaterThan(root.length));
    }
  });

  for (final tab in PindTab.values) {
    testWidgets('navigation ${tab.name} matches original assets and geometry', (
      tester,
    ) async {
      final shadowsWereDisabled = debugDisableShadows;
      debugDisableShadows = false;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: const ValueKey('nav-capture'),
                  child: SizedBox(
                    width: 309,
                    height: 94,
                    child: ColoredBox(
                      color: Colors.white,
                      child: Center(
                        child: PindNavigationBar(
                          selected: tab,
                          onSelect: (_) {},
                          onCompose: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(const ValueKey('navigation-bar-bounds'))),
          const Size(273, 58),
        );
        final bar = tester.getTopLeft(
          find.byKey(const ValueKey('navigation-bar-bounds')),
        );
        final slots = {
          'discover': 35.0,
          'map': 87.0457992553711,
          'compose': 145.9541015625,
          'profile': 209.0,
        };
        for (final slot in slots.entries) {
          final target = find.byKey(ValueKey('nav-${slot.key}'));
          expect(tester.getSize(target), const Size(44, 44));
          final center = tester.getCenter(target) - bar;
          expect(
            center.dx,
            closeTo(slot.value + PindNavigationBar.iconFrame / 2, .01),
          );
          expect(center.dy, closeTo(14 + PindNavigationBar.iconFrame / 2, .01));
        }
        for (final element in find.byType(SvgPicture).evaluate()) {
          final svg = element.widget as SvgPicture;
          final asset = (svg.bytesLoader as SvgAssetLoader).assetName;
          final name = asset.split('/nav_').last.replaceAll('.svg', '');
          expect(Size(svg.width!, svg.height!), roots[name]);
          final rendered = tester.getSize(find.byWidget(svg));
          expect(rendered.width, closeTo(roots[name]!.width, .001));
          expect(rendered.height, closeTo(roots[name]!.height, .001));
          expect(svg.colorFilter, isNull);
        }
        await expectLater(
          find.byKey(const ValueKey('nav-capture')),
          matchesGoldenFile('goldens/navigation-${tab.name}.png'),
        );
        expect(tester.takeException(), isNull);
      } finally {
        debugDisableShadows = shadowsWereDisabled;
      }
    });
  }

  testWidgets(
    'tab changes and repeated selection preserve map state without refetch',
    (tester) async {
      final calls = <String>[];
      await shell(
        tester,
        repository: PlaceService((body) async {
          calls.add(body['action'] as String);
          return {'places': <dynamic>[]};
        }),
      );
      expect(
        tester
            .widget<PindNavigationBar>(find.byType(PindNavigationBar))
            .selected,
        PindTab.map,
      );
      final mapState = tester.state(find.byType(ExploreScreen));
      await tester.enterText(find.byType(TextField), '서울 카페');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      for (final name in ['discover', 'profile', 'map', 'map']) {
        await tester.tap(find.byKey(ValueKey('nav-$name')));
        await tester.pumpAndSettle();
      }
      expect(tester.state(find.byType(ExploreScreen)), same(mapState));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '서울 카페',
      );
      expect(calls, ['nearby', 'search']);
    },
  );

  testWidgets(
    'compose opens once, hides bar, and returns to the previous tab',
    (tester) async {
      await shell(tester);
      await tester.tap(find.byKey(const ValueKey('nav-discover')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-compose')));
      await tester.tap(
        find.byKey(const ValueKey('nav-compose')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('장소 선택과 사진·평가 작성은 다음 단계에서 구현합니다.'), findsOneWidget);
      expect(find.byType(PindNavigationBar), findsNothing);
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PindNavigationBar>(find.byType(PindNavigationBar))
            .selected,
        PindTab.discover,
      );
    },
  );

  testWidgets('system back from a non-map tab returns to map', (tester) async {
    await shell(tester);
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<PindNavigationBar>(find.byType(PindNavigationBar)).selected,
      PindTab.map,
    );
  });

  testWidgets('safe area and keyboard do not overlap the floating bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);
    await shell(tester);
    final bar = tester.getRect(
      find.byKey(const ValueKey('navigation-bar-bounds')),
    );
    expect(bar.left, 64.5);
    expect(bar.bottom, 840);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byType(PindNavigationBar), findsNothing);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();
    expect(find.byType(PindNavigationBar), findsOneWidget);
  });

  testWidgets('320px and 200 percent text retain touch targets and semantics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: Center(
                child: PindNavigationBar(
                  selected: PindTab.map,
                  onSelect: (_) {},
                  onCompose: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final name in ['Discover', '지도', '작성', '마이페이지']) {
        expect(find.byTooltip(name), findsOneWidget);
        expect(find.bySemanticsLabel(name), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
