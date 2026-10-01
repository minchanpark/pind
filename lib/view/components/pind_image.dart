import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A network image cached by its storage path rather than its URL.
///
/// Signed URLs change on every fetch and expire, but the bytes behind
/// `…/object/sign/<bucket>/<path>?token=…` do not. Keying by the URL without
/// its query keeps one cache entry per photo: in memory through [ImageCache]
/// (provider equality) and on disk across restarts and expired tokens.
// ponytail: unbounded files in the OS temp dir, which iOS/Android purge under
// pressure; add an LRU sweep if the cache grows noticeably.
class PindImage extends ImageProvider<PindImage> {
  PindImage(this.url) : key = url.split('?').first;
  final String url;

  /// Stable identity: the URL minus its (signed) query.
  final String key;

  static final _http = HttpClient();
  static final _dir = Directory('${Directory.systemTemp.path}/pind_images');

  File get _file => File('${_dir.path}/${_fnv64(key)}');

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
    final file = _file;
    final bytes = file.existsSync()
        ? await file.readAsBytes()
        : await _download(file);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  Future<Uint8List> _download(File file) async {
    final response = await (await _http.getUrl(Uri.parse(url))).close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('${response.statusCode}', uri: Uri.parse(key));
    }
    final bytes = await consolidateHttpClientResponseBytes(response);
    // Write aside then rename, so a reader never sees a half-written file.
    try {
      await _dir.create(recursive: true);
      final part = File('${file.path}.${identityHashCode(bytes)}.part');
      await part.writeAsBytes(bytes, flush: true);
      await part.rename(file.path);
    } on FileSystemException {
      // A full or missing disk only costs the next launch a download.
    }
    return bytes;
  }

  @override
  bool operator ==(Object other) => other is PindImage && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'PindImage($key)';
}

/// FNV-1a 64-bit, hex: a short stable file name for a long cache key.
String _fnv64(String s) {
  var h = 0xcbf29ce484222325;
  for (final unit in s.codeUnits) {
    h ^= unit;
    h *= 0x100000001b3;
  }
  return h.toUnsigned(64).toRadixString(16);
}
