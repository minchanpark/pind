import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/registration_controller.dart';
import 'package:pind_flutter/model/registration_model.dart';
import 'package:pind_flutter/services/registration_service.dart';
import 'package:pind_flutter/view/onboarding/registration_screen.dart';
import 'package:pind_flutter/view/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/registration_fakes.dart';

void main() {
  testWidgets('Figma SVGs keep source roots, screen slots and rendered sizes', (
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
    const rootsByScreen = {
      RegistrationStep.login: {'a0e89.svg': Size(58, 78.1015)},
      RegistrationStep.country: {'808cb.svg': Size(34, 34)},
      RegistrationStep.handle: {
        '22e3f.svg': Size(96, 96),
        '37ea8.svg': Size(64, 64),
      },
      RegistrationStep.location: {
        'd43d2.svg': Size(170, 140),
        '9d337.svg': Size(150, 120),
        'ae7d9.svg': Size(32, 32),
        '33c00.svg': Size(120, 120),
        'e7fea.svg': Size(88, 88),
        'f61aa.svg': Size(72, 72),
        'fe8cf.svg': Size(68, 68),
        'dce83.svg': Size(72, 72),
        '457fb.svg': Size(72, 72),
      },
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
        const path = 'assets/figma/login_path.png';
        final bytes = File(path).readAsBytesSync();
        final header = ByteData.sublistView(bytes);
        expect(header.getUint32(16), 393);
        expect(header.getUint32(20), 281);
        final finder = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == path,
        );
        expect(finder, findsOneWidget);
        expect(tester.getSize(finder), const Size(393, 281));
      }
      for (final asset in screen.value.entries) {
        final path = 'assets/figma/${asset.key}';
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
