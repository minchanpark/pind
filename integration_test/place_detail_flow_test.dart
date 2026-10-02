import 'package:pind_flutter/model/detail_preview_model.dart';
import 'package:pind_flutter/controllers/place_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pind_flutter/view/design_system.dart';
import 'package:pind_flutter/services/preview/detail_fixture.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/view/explore/place_sheet.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'native glass detail and fixed actions with and without test friend',
    (tester) async {
      final local = LocalDetailContext();
      await tester.pumpWidget(
        MaterialApp(
          theme: PindTheme.data,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Builder(
              builder: (context) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE9EFE9), Color(0xFFE6DDF5)],
                  ),
                ),
                child: Center(
                  child: FilledButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      barrierColor: Colors.black.withValues(alpha: .04),
                      useSafeArea: true,
                      builder: (_) => PlaceSheet(
                        controller: PlaceDetailController(
                          place: detailPlace,
                          places: detailPlaces,
                          context: local,
                          preferences: detailPreferences,
                          position: (_) async =>
                              const MapViewport(37.5712, 126.905),
                          shareAction: (_, _) async {},
                          linkAction: (_) async {},
                        ),
                      ),
                    ),
                    child: const Text('로컬 QA 상세 열기'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('로컬 QA 상세 열기'));
      await tester.pumpAndSettle();
      expect(find.text('내 취향 94%'), findsOneWidget);
      expect(find.byKey(const ValueKey('friend-visits')), findsOneWidget);
      await binding.takeScreenshot('detail-qa-friend');
      final fixed = find.byKey(const ValueKey('detail-fixed-actions'));
      final bottom = tester.getBottomLeft(fixed).dy;
      await tester.tap(find.byKey(const ValueKey('detail-save')));
      await tester.pumpAndSettle();
      expect(local.saved, true);
      await tester.tap(find.byKey(const ValueKey('detail-expand')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(fixed).dy, bottom);
      await binding.takeScreenshot('detail-qa-expanded');
      await tester.drag(find.byType(ListView).first, const Offset(0, 400));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      local.relationship = TestFriendship.none;
      await tester.tap(find.text('로컬 QA 상세 열기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('friend-visits')), findsNothing);
      expect(find.text('저장됨'), findsOneWidget);
      await binding.takeScreenshot('detail-qa-no-friends');
      expect(tester.takeException(), isNull);
    },
  );
}
