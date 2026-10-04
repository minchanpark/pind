import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:pind_flutter/controllers/registration_controller.dart';
import 'package:pind_flutter/model/registration_model.dart';
import 'package:pind_flutter/services/registration_service.dart';
import 'package:pind_flutter/view/onboarding/registration_components.dart';
import 'package:pind_flutter/view/onboarding/registration_screen.dart';
import 'package:pind_flutter/view/design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/registration_fakes.dart';

void main() {
  testWidgets('setup assets keep source roots and circles render natively', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final auth = FakeAuthService();
    addTearDown(auth.close);
    final controller = RegistrationController(
      auth: auth,
      storage: RegistrationService(await SharedPreferences.getInstance()),
      onComplete: (_) async {},
    );
    addTearDown(controller.dispose);
    // The login artwork is a Lottie animation; circles are native
    // SetupCircles. No screen draws an SVG asset any more.
    const rootsByScreen = {
      RegistrationStep.login: <String, Size>{},
      RegistrationStep.country: <String, Size>{},
      RegistrationStep.handle: <String, Size>{},
      RegistrationStep.location: <String, Size>{},
    };
    const circles = {
      RegistrationStep.country: 1,
      RegistrationStep.handle: 1,
      RegistrationStep.location: 8, // 5 map bubbles + 3 benefits
    };
    await tester.pumpWidget(
      MaterialApp(
        theme: PindTheme.data,
        home: RegistrationScreen(controller: controller),
      ),
    );
    for (final screen in rootsByScreen.entries) {
      controller.model.update(() => controller.model.step = screen.key);
      await tester.pumpAndSettle();
      if (screen.key == RegistrationStep.login) {
        const path = 'assets/app/PIND_intro.lottie.json';
        final intro = jsonDecode(File(path).readAsStringSync()) as Map;
        // 402×508, 3.6s at 60fps, all shapes (no images or fonts to ship).
        expect([intro['w'], intro['h']], [402, 508]);
        expect((intro['op'] - intro['ip']) / intro['fr'], closeTo(3.6, .01));
        expect(intro['assets'], isEmpty);
        final lottie = find.byWidgetPredicate(
          (w) =>
              w is LottieBuilder &&
              w.lottie is AssetLottie &&
              (w.lottie as AssetLottie).assetName == path,
        );
        expect(lottie, findsOneWidget);
        // It played to the end and holds the finished frame.
        final player = tester.widget<LottieBuilder>(lottie);
        expect(player.controller!.value, 1);
        expect(tester.getSize(lottie).aspectRatio, closeTo(402 / 508, .001));
      }
      if (circles[screen.key] case final count?) {
        expect(find.byType(SetupCircle), findsNWidgets(count));
      }
      for (final asset in screen.value.entries) {
        final path = 'assets/${asset.key}';
        final file = File(path);
        expect(file.lengthSync(), greaterThan(0));
        final root = RegExp(r'<svg\b[^>]*>')
            .firstMatch(file.readAsStringSync())!
            .group(0)!;
        final width = double.parse(
          RegExp(r'\bwidth="([\d.]+)"').firstMatch(root)!.group(1)!,
        );
        final height = double.parse(
          RegExp(r'\bheight="([\d.]+)"').firstMatch(root)!.group(1)!,
        );
        expect(Size(width, height), asset.value);
        final finder = find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader is SvgAssetLoader &&
              (widget.bytesLoader as SvgAssetLoader).assetName == path,
        );
        expect(
          finder,
          findsWidgets,
          reason: '${screen.key.name} must use ${asset.key}',
        );
        for (var i = 0; i < finder.evaluate().length; i++) {
          final rendered = tester.getSize(finder.at(i));
          expect(rendered.width, closeTo(asset.value.width, 0.001));
          expect(rendered.height, closeTo(asset.value.height, 0.001));
        }
      }
    }
    expect(tester.takeException(), null);
  });
}
