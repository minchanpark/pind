import 'dart:async';
import 'dart:ui' as ui;

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:pind_flutter/l10n/l10n.dart';
import 'package:pind_flutter/model/post_model.dart';
import 'package:pind_flutter/services/post_photo_service.dart';
import 'package:pind_flutter/view/design_system.dart';
import 'package:pind_flutter/view/posts/post_camera_screen.dart';

/// A camera that "shoots" a small PNG, so the screen runs without hardware.
class FakeCamera extends CameraPlatform {
  FakeCamera(this.png);
  final Uint8List png;
  final inits = StreamController<CameraInitializedEvent>.broadcast();
  var next = 0;

  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(
      name: 'back',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    ),
    CameraDescription(
      name: 'front',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 270,
    ),
  ];
  @override
  Future<int> createCameraWithSettings(
    CameraDescription description,
    MediaSettings settings,
  ) async => ++next;
  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      inits.stream.where((e) => e.cameraId == cameraId);
  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      StreamController<CameraErrorEvent>().stream;
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();
  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async => scheduleMicrotask(
    () => inits.add(
      CameraInitializedEvent(
        cameraId,
        400,
        300,
        ExposureMode.auto,
        false,
        FocusMode.auto,
        false,
      ),
    ),
  );
  @override
  Future<void> lockCaptureOrientation(int cameraId, orientation) async {}
  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {}
  @override
  Future<XFile> takePicture(int cameraId) async =>
      XFile.fromData(png, mimeType: 'image/png');
  @override
  Widget buildPreview(int cameraId) => const ColoredBox(color: Colors.grey);
  @override
  Future<void> dispose(int cameraId) async {}
}

/// A 3:4 shot: [left] on its left half, [right] on its right.
Future<ui.Image> shot(Color left, [Color? right]) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder)
    ..drawRect(const Rect.fromLTWH(0, 0, 150, 400), Paint()..color = left)
    ..drawRect(
      const Rect.fromLTWH(150, 0, 150, 400),
      Paint()..color = right ?? left,
    );
  return recorder.endRecording().toImage(300, 400);
}

void expectColor(img.Image image, int x, int y, Color color) {
  final p = image.getPixel(x, y);
  for (final (got, want) in [(p.r, color.r), (p.g, color.g), (p.b, color.b)]) {
    expect((got - want * 255).abs(), lessThan(24), reason: '($x, $y)');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  controlsAfterTwoShots(CameraLayout.pip);
  controlsAfterTwoShots(CameraLayout.split);

  test('PiP box stays inside the frame', () {
    expect(clampInset(const Offset(-1, 2)), const Offset(0, .7));
    expect(clampInset(const Offset(.3, .4)), const Offset(.3, .4));
  });

  test('PiP puts the second shot in the box over the first', () async {
    final photo = await composeCameraShot(CameraLayout.pip, Offset.zero, [
      (await shot(Colors.red), false),
      (await shot(Colors.blue), false),
    ]);
    expect(photo.mimeType, 'image/jpeg');
    final out = img.decodeJpg(photo.bytes)!;
    expect((out.width, out.height), (1365, 2048));
    expectColor(out, 100, 100, Colors.blue);
    expectColor(out, 1300, 2000, Colors.red);
  });

  test('split stacks the shots and mirrors front captures', () async {
    final photo = await composeCameraShot(CameraLayout.split, Offset.zero, [
      (await shot(Colors.green, Colors.red), true),
      (await shot(Colors.blue), false),
    ]);
    final out = img.decodeJpg(photo.bytes)!;
    expectColor(out, 100, 500, Colors.red);
    expectColor(out, 1265, 500, Colors.green);
    expectColor(out, 680, 1600, Colors.blue);
  });
}

void controlsAfterTwoShots(CameraLayout layout) => testWidgets(
  '${layout.name}: two shots, then 사용하기 returns the composed JPEG',
  (tester) async {
    final png = await tester.runAsync(() async {
      final image = await shot(Colors.red);
      return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List();
    });
    CameraPlatform.instance = FakeCamera(png!);
    PostPhoto? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: PindTheme.data,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await Navigator.push<PostPhoto>(
              context,
              MaterialPageRoute(
                builder: (_) => PostCameraScreen(layout: layout),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    // Real time lets the fake camera open and each shot decode.
    Future<void> settle() async {
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('open'));
    for (var i = 0; i < 2; i++) {
      await settle();
      await tester.tap(find.bySemanticsLabel(l10n.cameraShutter));
      await settle();
    }
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.cameraRetake), findsOneWidget);
    expect(find.text(l10n.cameraUse), findsOneWidget);
    expect(tester.getSize(find.text(l10n.cameraUse)).width, greaterThan(0));
    await tester.tap(find.text(l10n.cameraUse));
    for (var i = 0; i < 20 && result == null; i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(result?.mimeType, 'image/jpeg');
  },
);
