import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/components/pind_image.dart';

/// 1×1 transparent PNG.
final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('one cache key per storage path, whatever the signed token', () {
    expect(
      PindImage('https://s/a.png?token=1'),
      PindImage('https://s/a.png?token=2'),
    );
    expect(
      PindImage('https://s/a.png?token=1'),
      isNot(PindImage('https://s/b.png?token=1')),
    );
  });

  testWidgets('a new token for a cached photo loads from disk, not the network', (
    tester,
  ) async {
    await tester.runAsync(() async {
      HttpOverrides.global = null; // the test binding stubs every request
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var hits = 0;
      server.listen((request) {
        hits++;
        request.response
          ..headers.contentType = ContentType('image', 'png')
          ..add(png)
          ..close();
      });
      // A path no earlier run cached.
      final path =
          'http://127.0.0.1:${server.port}/sign/b/${DateTime.now().microsecondsSinceEpoch}.png';
      Future<ImageInfo> load(String url) {
        final done = Completer<ImageInfo>();
        PindImage(url)
            .resolve(ImageConfiguration.empty)
            .addListener(
              ImageStreamListener(
                (info, _) => done.isCompleted ? null : done.complete(info),
                onError: (e, _) =>
                    done.isCompleted ? null : done.completeError(e),
              ),
            );
        return done.future;
      }

      expect((await load('$path?token=old')).image.width, 1);
      expect(hits, 1);
      // Drop the in-memory copy: only the disk can serve the next load.
      PaintingBinding.instance.imageCache.clear();
      expect((await load('$path?token=new')).image.width, 1);
      expect(hits, 1);
      await server.close(force: true);
    });
  });
}
