import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pind_flutter/controllers/app_controller.dart';
import 'package:pind_flutter/model/registration_model.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/services/registration_service.dart';
import 'package:pind_flutter/view/app.dart';
import 'package:pind_flutter/view/explore/explore_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/support/registration_fakes.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('local QA follows login through all eight onboarding screens', (
    tester,
  ) async {
    // Fake auth and device drafts. No OAuth account or remote profile writes.
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();
    final profiles = RegistrationService(storage);
    await profiles.save(
      'onboarding-qa',
      RegistrationDraft(
        name: '뉴던',
        gender: ProfileGender.male,
        birthDate: DateTime(2000, 3, 14),
        handle: 'newdawn',
      ),
    );
    final auth = FakeAuthService();
    auth.onSignIn = (_) async => auth.emit(const AuthIdentity('onboarding-qa'));
    final app = AppController(
      PreferenceService(storage),
      auth: auth,
      registrationService: profiles,
    );
    Future<void> capture(String name) async {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    await tester.pumpWidget(PindApp(controller: app));
    await tester.pumpAndSettle();
    await capture('onboarding-qa-login');
    await tester.tap(find.byKey(const ValueKey('login-kakao')));
    await tester.pumpAndSettle();
    await capture('onboarding-qa-country');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('개인정보 수집·이용 동의 (필수)'));
    await tester.tap(find.text('만 14세 이상입니다 (필수)'));
    await tester.pumpAndSettle();
    await capture('onboarding-qa-basic');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await capture('onboarding-qa-handle');
    await tester.tap(find.text('Pind 시작하기'));
    await tester.pumpAndSettle();
    await capture('onboarding-qa-location');
    await tester.tap(find.byKey(const ValueKey('skip-location')));
    await tester.pumpAndSettle();
    for (final text in ['맛', '분위기·공간', '가성비']) {
      await tester.tap(find.text(text));
      await tester.pump();
    }
    await capture('onboarding-qa-priorities');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('친구들이랑'));
    await tester.pumpAndSettle();
    await capture('onboarding-qa-occasions');
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    for (final text in ['한식·백반', '고기구이', '국물·탕']) {
      await tester.tap(find.text(text));
      await tester.pump();
    }
    await capture('onboarding-qa-cuisines');
    await tester.tap(find.text('내 취향 지도 만들기'));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(profiles.load('onboarding-qa')!.completed, true);
    expect(PreferenceService(storage).load()!.isComplete, true);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox.shrink());
    await auth.close();
  });
}
