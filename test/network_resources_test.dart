import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pind_flutter/services/request_client.dart';
import 'package:pind_flutter/services/image_disk_cache.dart';

void main() {
  test('multipart uploads keep their boundary content type', () async {
    String? sent;
    final client = RequestClient(
      inner: MockClient((r) async {
        sent = r.headers['content-type'];
        return http.Response('', 200);
      }),
    );
    addTearDown(client.close);
    await client.send(
      http.MultipartRequest(
        'POST',
        Uri.parse('https://x/storage/v1/object/b/p'),
      )..files.add(http.MultipartFile.fromBytes('', [1], filename: 'p')),
    );
    expect(sent, startsWith('multipart/form-data; boundary='));
  });

  test('request deadline aborts headers and body, and explicit cancellation aborts a socket', () async {
    final overrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final arrived = StreamController<void>.broadcast();
    server.listen((r) {
      arrived.add(null);
      if (r.uri.path == '/body') {
        r.response.bufferOutput = false;
        r.response.write('started');
        r.response.flush().catchError((_) {});
      }
    });
    final client = RequestClient(timeout: const Duration(milliseconds: 150));
    try {
      bool interruption(Object e) =>
          e is TimeoutException || e is http.RequestAbortedException;
      final root = 'http://127.0.0.1:${server.port}';
      await expectLater(
        client.get(Uri.parse('$root/headers')),
        throwsA(predicate(interruption)),
      );
      await expectLater(
        client.get(Uri.parse('$root/body')),
        throwsA(predicate(interruption)),
      );
      final abort = Completer<void>();
      final ready = arrived.stream.first;
      final pending = withRequestCancellation(
        abort.future,
        () => client.get(Uri.parse('$root/cancel')),
      );
      final assertion = expectLater(
        pending,
        throwsA(isA<http.RequestAbortedException>()),
      );
      await ready;
      abort.complete();
      await assertion;
    } finally {
      client.close();
      await server.close(force: true);
      await arrived.close();
      HttpOverrides.global = overrides;
    }
  });
  test(
    'disk cache deduplicates, expires, bounds storage and isolates accounts',
    () async {
      final dir = await Directory.systemTemp.createTemp('pind-cache-test-');
      var hits = 0;
      final cache = ImageDiskCache(
        directory: dir,
        maxBytes: 20,
        client: MockClient((_) async {
          hits++;
          return http.Response.bytes(Uint8List(10), 200);
        }),
      );
      try {
        await Future.wait([
          cache.read('https://s/a?token=1'),
          cache.read('https://s/a?token=2'),
        ]);
        expect(hits, 1);
        await Future.wait([
          cache.read('https://s/b'),
          cache.read('https://s/c'),
          cache.read('https://s/d'),
        ]);
        await cache.sweep();
        final files = await dir.list().where((f) => f is File).toList();
        expect(files.length, lessThanOrEqualTo(2));
        await cache.read('https://s/c');
        final beforeExpiry = hits;
        await cache.fileFor('https://s/c').setLastModified(DateTime(2000));
        await cache.read('https://s/c');
        expect(hits, beforeExpiry + 1);
        await cache.switchAccount('new-user');
        await cache.read('https://s/c');
        expect(hits, beforeExpiry + 2);
        expect(
          ImageDiskCache.key('https://s/a?width=20&token=a'),
          isNot(ImageDiskCache.key('https://s/a?width=40&token=b')),
        );
      } finally {
        cache.client.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
