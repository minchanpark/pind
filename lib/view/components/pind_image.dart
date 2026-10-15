import 'dart:async';
import 'dart:ui' as ui;

import '../../services/image_disk_cache.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// [Image.frameBuilder] that fades a photo in as it arrives; one already in
/// memory shows at once.
Widget fadeInFrame(BuildContext _, Widget child, int? frame, bool sync) => sync
    ? child
    : AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: child,
      );

/// A network image cached by its storage path rather than its URL.
///
/// Signed URL tokens change while image bytes remain the same. Transform
/// parameters stay in the key; account scope isolates memory and disk entries.
/// Disk entries expire after seven days and share a 100 MiB LRU budget.
class PindImage extends ImageProvider<PindImage> {
  PindImage(this.url)
    : key = ImageDiskCache.key(url),
      scope = ImageDiskCache.shared.scope;
  final String url;
  final String key;
  final String scope;
  @override
  Future<PindImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(PindImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
        codec: _load(decode),
        scale: 1,
        debugLabel: key.key,
      );
  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final cache = ImageDiskCache.shared;
    try {
      final bytes = await cache.read(url);
      try {
        return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
      } catch (_) {
        await cache.remove(url);
        final fresh = await cache.read(url, refresh: true);
        return await decode(await ui.ImmutableBuffer.fromUint8List(fresh));
      }
    } catch (_) {
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(this));
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PindImage && other.key == key && other.scope == scope;
  @override
  int get hashCode => Object.hash(key, scope);
  @override
  String toString() => 'PindImage($key)';
}

/// Decode thumbnails at their physical display size. Full-screen viewers keep
/// the original provider so their detail and aspect-ratio lookup stay accurate.
ImageProvider pindThumbnail(
  String url,
  double logicalSize,
  BuildContext context,
) => ResizeImage.resizeIfNeeded(
  null,
  (logicalSize * MediaQuery.devicePixelRatioOf(context)).ceil(),
  PindImage(url),
);
