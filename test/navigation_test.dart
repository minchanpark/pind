import 'package:pind_flutter/model/navigation_model.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/theme.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/services/profile_service.dart';

import 'profile_test.dart' show FakeProfileService;

import 'package:pind_flutter/view/explore/explore_screen.dart';
import 'package:pind_flutter/view/navigation/main_shell.dart';
import 'package:pind_flutter/view/navigation/pind_navigation_bar.dart';
import 'package:pind_flutter/services/data_revision.dart';

import 'support/map_search.dart';

const roots = <String, Size>{
  'discover_icon': Size(26, 26),
  'map_icon': Size(23, 23),
  'compose_icon': Size(31, 31),
  'profile_icon': Size(24, 24),
};

Future<void> shell(
  WidgetTester tester, {
  PlaceService? repository,
  ProfileService? profile,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PindTheme.data,
      home: MainShell(
        controller: repository == null ? null : ExploreController(repository),
        profile: profile,
        mapsEnabled: false,
        onEditPreferences: () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('all four nav icon SVGs exist and retain root dimensions', (
    tester,
  ) async {
    for (final asset in roots.entries) {
      final svg = await rootBundle.loadString(
        'assets/navigation/${asset.key}.svg',
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
          final name = asset.split('/').last.replaceAll('.svg', '');
          expect(Size(svg.width!, svg.height!), roots[name]);
          final rendered = tester.getSize(find.byWidget(svg));
          expect(rendered.width, closeTo(roots[name]!.width, .001));
          expect(rendered.height, closeTo(roots[name]!.height, .001));
          // Only the selected tab is tinted; compose is an action, never selected.
          expect(svg.colorFilter != null, name == '${tab.name}_icon');
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
      await mapSearch(tester, '서울 카페');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('닫기'));
      await tester.pumpAndSettle();
      for (final name in ['discover', 'profile', 'map', 'map']) {
        await tester.tap(find.byKey(ValueKey('nav-$name')));
        await tester.pumpAndSettle();
      }
      expect(tester.state(find.byType(ExploreScreen)), same(mapState));
      expect(calls, ['posted', 'agent_search']);
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
      expect(find.text('게시물 작성'), findsOneWidget);
      expect(find.text('사진 추가'), findsOneWidget);
      expect(find.byType(PindNavigationBar), findsNothing);
      await tester.tap(find.byTooltip('닫기'));
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

  testWidgets('returning to My Page refetches only after a write', (
    tester,
  ) async {
    final profile = FakeProfileService();
    await shell(tester, profile: profile);
    Future<void> visit() async {
      await tester.tap(find.byKey(const ValueKey('nav-map')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-profile')));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    final first = profile.overviewCalls;
    expect(first, greaterThan(0));
    await visit();
    expect(profile.overviewCalls, first); // nothing changed: no request
    markDataChanged(); // e.g. a save on the map tab
    await visit();
    expect(profile.overviewCalls, first + 1);
  });
}
