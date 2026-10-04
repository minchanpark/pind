import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Tests assert the Korean strings: run every app in Korean, as a Korean
/// phone would. Localized runs set their own locale.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized()
      .platformDispatcher
      .localesTestValue = const [
    Locale('ko', 'KR'),
  ];
  await testMain();
}
