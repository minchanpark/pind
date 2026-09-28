import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pind_flutter/services/config.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> capture(String name) async {
    await binding.takeScreenshot(name);
  }

  testWidgets('device onboarding and authenticated live Places contract', (
    tester,
  ) async {
    expect(AppConfig.hasBackend, isTrue, reason: 'Supply config/local.json');
    await app.main();
    await tester.pumpAndSettle();
    if (find.byTooltip('취향 수정').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('취향 수정'));
      await tester.pumpAndSettle();
    }
    if (find.text('맛').evaluate().isNotEmpty) {
      await capture('priorities');
      if (find.text('1순위').evaluate().isEmpty) {
        await tester.tap(find.text('맛'));
        await tester.tap(find.text('분위기·공간'));
        await tester.tap(find.text('가성비'));
      }
      await tester.pump();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await capture('occasions');
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      if (tester.widget<FilledButton>(find.byType(FilledButton)).onPressed ==
          null) {
        for (final label in ['한식·백반', '고기구이', '국물·탕']) {
          await tester.tap(find.text(label));
          await tester.pump();
        }
      }
      await tester.pumpAndSettle();
      await capture('cuisines');
      await tester.tap(find.text('내 취향 지도 만들기'));
      await tester.pumpAndSettle();
    }
    expect(find.byType(TextField), findsOneWidget);
    await capture('map-initial');
    final client = Supabase.instance.client;
    final gateway = SupabasePlacesGateway(
      client,
      allowAnonymous: AppConfig.allowAnonymous,
    );
    final repository = PlaceService(gateway.call);
    final nearby = await repository.nearby(MapViewport.seoul);
    expect(nearby, isNotEmpty);
    expect(nearby.every((place) => place.id != null), isTrue);
    final sessionId = client.auth.currentSession!.user.id;
    final results = await repository.search('명동교자');
    expect(results, isNotEmpty);
    final details = await repository.details(results.first);
    expect(details.id, isNotNull);
    expect(details.externalId, results.first.externalId);
    expect(details.name, isNotEmpty);
    expect(details.address, isNotEmpty);
    expect(client.auth.currentSession!.user.id, sessionId);
    await tester.pump(const Duration(seconds: 8));
    if (const bool.fromEnvironment('VISUAL_QA_HOLD')) {
      debugPrint('PIND_NATIVE_MAP_READY');
      await Future<void>.delayed(const Duration(seconds: 20));
    }
    await capture('map');
    await tester.enterText(find.byType(TextField), '명동교자');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 8));
    expect(find.textContaining('명동교자'), findsWidgets);
    await capture('place-detail');
    expect(tester.takeException(), isNull);
  });
}
