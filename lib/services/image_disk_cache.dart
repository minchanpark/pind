import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'request_client.dart';

class ImageDiskCache {
  ImageDiskCache({
    Directory? directory,
    this._client,
    this.maxBytes = 100 * 1024 * 1024,
    this.maxAge = const Duration(days: 7),
  }) : directory =
           directory ?? Directory('${Directory.systemTemp.path}/pind_images');
  static final shared = ImageDiskCache();
  final Directory directory;
  http.Client? _client;
  http.Client get client =>
      _client ??= RequestClient(timeout: const Duration(seconds: 15));
  final int maxBytes;
  final Duration maxAge;
  final _pending = <String, Future<Uint8List>>{};
  Future<void>? _sweeping;
  int _generation = 0;
  String scope = '';

  Future<void> switchAccount(String userId) async {
    if (scope == userId) return;
    final oldPrefix = '${_hash(scope)}-';
    scope = userId;
    _generation++;
    _pending.clear();
    try {
      if (!await directory.exists()) return;
      await for (final entry in directory.list()) {
        if ('${_hash(scope)}-' == oldPrefix) return;
        if (entry is File &&
            entry.uri.pathSegments.last.startsWith(oldPrefix)) {
          await entry.delete();
        }
      }
    } on FileSystemException {
      /* Concurrent OS purge. */
    }
  }

  static String key(String url) {
    final uri = Uri.parse(url);
    final query = Map<String, String>.of(uri.queryParameters)..remove('token');
    return uri
        .replace(
          query: query.isEmpty ? '' : null,
          queryParameters: query.isEmpty ? null : query,
        )
        .toString();
  }

  static String _hash(String value) {
    var hash = 0xcbf29ce484222325;
    for (final unit in value.codeUnits) {
      hash = (hash ^ unit) * 0x100000001b3;
    }
    return hash.toUnsigned(64).toRadixString(16);
  }

  File fileFor(String url) =>
      File('${directory.path}/${_hash(scope)}-${_hash(key(url))}');
  Future<Uint8List> read(String url, {bool refresh = false}) async {
    final file = fileFor(url);
    if (!refresh) {
      try {
        final stat = await file.stat();
        if (stat.type == FileSystemEntityType.file &&
            stat.size > 0 &&
            DateTime.now().difference(stat.modified) < maxAge) {
          final bytes = await file.readAsBytes();
          await file.setLastModified(DateTime.now());
          return bytes;
        }
      } on FileSystemException {
        /* A purge is a cache miss. */
      }
    }
    final cacheKey = key(url);
    final existing = _pending[cacheKey];
    if (existing != null) return existing;
    final task = _download(url, file, _generation);
    _pending[cacheKey] = task;
    try {
      return await task;
    } finally {
      if (identical(_pending[cacheKey], task)) _pending.remove(cacheKey);
    }
  }

  Future<Uint8List> _download(String url, File file, int generation) async {
    final response = await client.send(http.Request('GET', Uri.parse(url)));
    if (response.statusCode != 200) {
      await response.stream.drain<void>();
      throw HttpException('${response.statusCode}', uri: Uri.parse(key(url)));
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      bytes.add(chunk);
      if (bytes.length > 10 * 1024 * 1024) {
        throw const HttpException('Image exceeds size limit');
      }
    }
    final data = bytes.takeBytes();
    if (data.isEmpty) throw const HttpException('Empty image');
    try {
      if (generation != _generation) return data;
      await directory.create(recursive: true);
      final part = File('${file.path}.${identityHashCode(data)}.part');
      await part.writeAsBytes(data);
      if (generation == _generation) {
        await part.rename(file.path);
      } else {
        await part.delete();
      }
      await sweep();
    } on FileSystemException {
      /* Disk caching is best effort. */
    }
    return data;
  }

  Future<void> remove(String url) async {
    try {
      await fileFor(url).delete();
    } on FileSystemException {
      /* Already purged. */
    }
  }

  Future<void> sweep() async {
    while (_sweeping != null) {
      await _sweeping;
    }
    final task = _sweep();
    _sweeping = task;
    try {
      await task;
    } finally {
      if (identical(_sweeping, task)) _sweeping = null;
    }
  }

  Future<void> _sweep() async {
    if (!await directory.exists()) return;
    final files = <(File, FileStat)>[];
    await for (final entry in directory.list()) {
      if (entry is! File) continue;
      final stat = await entry.stat();
      if (entry.path.endsWith('.part')) {
        if (DateTime.now().difference(stat.modified) >
            const Duration(hours: 1)) {
          await entry.delete();
        }
      } else {
        files.add((entry, stat));
      }
    }
    files.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    var total = files.fold<int>(0, (sum, item) => sum + item.$2.size);
    for (final (file, stat) in files) {
      if (total <= maxBytes &&
          DateTime.now().difference(stat.modified) < maxAge) {
        continue;
      }
      try {
        await file.delete();
        total -= stat.size;
      } on FileSystemException {
        /* Concurrent purge. */
      }
    }
  }

  Future<void> clear() async {
    _generation++;
    _pending.clear();
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      /* OS may already have removed it. */
    }
  }
}
