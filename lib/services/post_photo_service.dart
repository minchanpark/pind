import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../model/post_model.dart';
import '../model/place_search_result.dart';
import '../l10n/l10n.dart';

abstract class PostPhotoService {
  Future<List<PostPhoto>> pick(int remaining);
}

class DevicePostPhotoService implements PostPhotoService {
  DevicePostPhotoService({ImagePicker? picker})
    : picker = picker ?? ImagePicker();
  final ImagePicker picker;

  @override
  Future<List<PostPhoto>> pick(int remaining) async {
    if (remaining <= 0) return [];
    final files = await picker.pickMultiImage(
      limit: remaining,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    final photos = <PostPhoto>[];
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw PlaceFailure(l10n.errPhotoTooLarge);
      }
      final extension = file.name.split('.').last.toLowerCase();
      final mime =
          file.mimeType ??
          switch (extension) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            'heic' => 'image/heic',
            'heif' => 'image/heif',
            _ => 'image/jpeg',
          };
      if (!const [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'image/heif',
      ].contains(mime)) {
        throw PlaceFailure(l10n.errPhotoFormat);
      }
      photos.add(PostPhoto(bytes: bytes, mimeType: mime));
    }
    return photos;
  }
}

/// The in-app camera's two-shot layouts: PiP (back, then front in a movable
/// box) and split (top, then bottom).
enum CameraLayout { pip, split }

/// A camera post's size: the viewer's 2:3 at the picker's 2048 cap.
const cameraShotSize = Size(1365, 2048);

/// The PiP box as a fraction of the frame.
const pipInset = Size(.6, .3);

/// Keeps the PiP box's top-left (a fraction of the frame) inside the frame.
Offset clampInset(Offset inset) => Offset(
  inset.dx.clamp(0, 1 - pipInset.width),
  inset.dy.clamp(0, 1 - pipInset.height),
);

/// Where the first and second shots land in a [frame].
(Rect, Rect) cameraRects(CameraLayout layout, Size frame, Offset inset) =>
    switch (layout) {
      CameraLayout.pip => (
        Offset.zero & frame,
        Offset(inset.dx * frame.width, inset.dy * frame.height) &
            Size(pipInset.width * frame.width, pipInset.height * frame.height),
      ),
      CameraLayout.split => (
        Offset.zero & Size(frame.width, frame.height / 2),
        Offset(0, frame.height / 2) & Size(frame.width, frame.height / 2),
      ),
    };

/// Draws both shots cover-cropped into [cameraRects] and encodes one JPEG.
/// A shot's `mirror` flips it to match the front camera's preview.
Future<PostPhoto> composeCameraShot(
  CameraLayout layout,
  Offset inset,
  List<(ui.Image, bool mirror)> shots,
) async {
  final width = cameraShotSize.width.toInt();
  final height = cameraShotSize.height.toInt();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final (first, second) = cameraRects(layout, cameraShotSize, inset);
  for (final ((image, mirror), dst) in [
    (shots[0], first),
    (shots[1], second),
  ]) {
    final src = applyBoxFit(
      BoxFit.cover,
      Size(image.width.toDouble(), image.height.toDouble()),
      dst.size,
    ).source;
    canvas.save();
    if (mirror) {
      canvas.translate(dst.center.dx * 2, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      image,
      Alignment.center.inscribe(
        src,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      ),
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }
  final picture = recorder.endRecording();
  final frame = await picture.toImage(width, height);
  picture.dispose();
  final rgba = (await frame.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  frame.dispose();
  // 4:4:4 chroma at q90 keeps food texture and text sharp near ~1–2MB.
  final jpeg = await Isolate.run(
    () => img.encodeJpg(
      img.Image.fromBytes(
        width: width,
        height: height,
        bytes: rgba.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      ),
      quality: 90,
    ),
  );
  return PostPhoto(bytes: jpeg, mimeType: 'image/jpeg');
}
