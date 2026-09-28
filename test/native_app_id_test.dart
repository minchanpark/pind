import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS and Android ship the same com.pind.app application identity', () {
    final ios = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = com\.pind\.app;').allMatches(ios),
      hasLength(3),
    );
    expect(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = com\.pind\.app\.RunnerTests;')
          .allMatches(ios),
      hasLength(3),
    );
    final android = File('android/app/build.gradle.kts').readAsStringSync();
    expect(android, contains('namespace = "com.pind.app"'));
    expect(android, contains('applicationId = "com.pind.app"'));
    final activity = File(
      'android/app/src/main/kotlin/com/pind/app/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, startsWith('package com.pind.app'));
    expect(
      File('android/app/src/main/kotlin/com/pind/pind_flutter/MainActivity.kt')
          .existsSync(),
      isFalse,
    );
  });
}
