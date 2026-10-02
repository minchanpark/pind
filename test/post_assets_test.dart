import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/posts/post_composer.dart';
import 'package:pind_flutter/view/design_system.dart';

import 'post_flow_test.dart' as fixtures;

void main() {
  testWidgets('original post SVG roots, slots and rendered geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 1079);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = fixtures.make(fixtures.TestPosts());
    await tester.pumpWidget(
      MaterialApp(
        theme: PindTheme.data,
        home: PostComposer(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    const roots = {
      'close_icon.svg': Size(20.6096, 20.6096),
      'camera_icon.svg': Size(22.9817, 22.9817),
      'add_photo_icon.svg': Size(20, 17.8653),
      'star_taste.svg': Size(25.6324, 24.1341),
      'star_portion.svg': Size(25.6324, 24.1341),
      'star_portion_empty.svg': Size(19.6324, 18.1341),
      'star_ambience.svg': Size(25.6324, 24.1341),
      'star_ambience_empty.svg': Size(19.6324, 18.1341),
    };
    Finder svg(String name) => find.byWidgetPredicate(
      (widget) =>
          widget is SvgPicture &&
          widget.bytesLoader is SvgAssetLoader &&
          (widget.bytesLoader as SvgAssetLoader).assetName ==
              'assets/post_composer/$name',
    );
    void verify(String name) {
      final expected = roots[name]!;
      final file = File('assets/post_composer/$name');
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
      expect(Size(width, height), expected);
      final finder = svg(name);
      expect(finder, findsWidgets, reason: name);
      for (var n = 0; n < finder.evaluate().length; n++) {
        expect(
          tester.getSize(finder.at(n)).width,
          closeTo(expected.width, .001),
        );
        expect(
          tester.getSize(finder.at(n)).height,
          closeTo(expected.height, .001),
        );
      }
    }

    verify('close_icon.svg');
    verify('camera_icon.svg');
    await fixtures.ready(controller);
    await tester.pumpAndSettle();
    for (final name in roots.keys.where((name) => name != 'camera_icon.svg')) {
      verify(name);
    }
    for (final star in find.byType(PostStar).evaluate()) {
      expect(tester.getSize(find.byWidget(star.widget)), const Size(24, 23));
    }
    expect(tester.takeException(), isNull);
  });
}
