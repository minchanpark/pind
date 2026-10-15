import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pind_flutter/model/post_model.dart';
import 'package:pind_flutter/services/post_service.dart';
import 'package:pind_flutter/services/request_client.dart';

import 'post_flow_test.dart' as fixtures;

class FixtureUploads extends SupabasePostService {
  FixtureUploads(super.client);
  @override
  String get userId => 'user-a';
}

class AbortUploadClient extends http.BaseClient {
  final started = Completer<void>();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await request.finalize().drain<void>();
    started.complete();
    await (request as http.Abortable).abortTrigger;
    throw http.RequestAbortedException(request.url);
  }
}

class CancelableUploads extends fixtures.TestPosts
    implements ProgressPostService {
  CancelableUploads(this.client);
  final RequestClient client;
  @override
  Future<PublishedPost> publishWithProgress(
    PostDraft draft,
    String requestId,
    String? authorId,
    void Function(double) progress,
  ) async {
    progress(.4);
    await client.post(
      Uri.parse('https://test/storage/v1/object/post-media-v2/a'),
    );
    return const PublishedPost(id: 7, placeId: 42);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('uploads use at most three transfers, preserve photo order and report bytes', () async {
    var active = 0, peak = 0;
    Map<String, dynamic>? payload;
    final progress = <double>[];
    final client = SupabaseClient(
      'https://test.supabase.co',
      'fixture-key',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/rest/v1/posts')) {
          return http.Response(
            '[]',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        if (request.url.path.contains('/storage/v1/object/')) {
          active++;
          if (active > peak) peak = active;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          active--;
          return http.Response(
            '{"Key":"uploaded"}',
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        payload = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          '{"id":7,"placeId":42}',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(client.dispose);
    final service = FixtureUploads(client);
    final result = await service.publishWithProgress(
      PostDraft(
        place: fixtures.restaurant,
        photos: [
          for (var n = 1; n <= 5; n++)
            PostPhoto(bytes: Uint8List(n), mimeType: 'image/jpeg'),
        ],
        ratings: const {},
        body: '',
      ),
      'request-1',
      'user-a',
      progress.add,
    );
    expect(result.id, 7);
    expect(peak, 3);
    expect(progress, hasLength(5));
    expect(progress.last, 1);
    expect(progress, orderedEquals([...progress]..sort()));
    final media = payload!['p_media'] as List;
    expect(media.map((p) => p['bytes']), [1, 2, 3, 4, 5]);
    expect(media.map((p) => p['path'].split('/').last), [
      '0.jpg',
      '1.jpg',
      '2.jpg',
      '3.jpg',
      '4.jpg',
    ]);
  });

  test(
    'cancel upload unlocks composer and keeps the draft and request identity',
    () async {
      final inner = AbortUploadClient();
      final client = RequestClient(inner: inner);
      final service = CancelableUploads(client);
      final controller = fixtures.make(service);
      addTearDown(controller.dispose);
      addTearDown(client.close);
      await fixtures.ready(controller);
      final requestId = controller.requestId;
      final pending = controller.publish();
      await inner.started.future;
      expect(controller.model.uploadProgress, .4);
      expect(controller.canCancelPublish, isTrue);
      controller.cancelPublish();
      expect(await pending, isNull);
      expect(controller.model.publishing, isFalse);
      expect(controller.model.photos, hasLength(2));
      expect(controller.model.canPublish, isTrue);
      expect(controller.requestId, requestId);
    },
  );

  test('photo total limit preserves existing photos and blocks oversized service drafts', () async {
    final controller = fixtures.make(fixtures.TestPosts());
    addTearDown(controller.dispose);
    controller.addPhoto(
      PostPhoto(bytes: Uint8List(8 * 1024 * 1024), mimeType: 'image/jpeg'),
    );
    controller.addPhoto(
      PostPhoto(bytes: Uint8List(8 * 1024 * 1024), mimeType: 'image/jpeg'),
    );
    controller.addPhoto(
      PostPhoto(bytes: Uint8List(8 * 1024 * 1024), mimeType: 'image/jpeg'),
    );
    expect(controller.model.photos, hasLength(2));
    expect(controller.model.error, isNotNull);
    final client = SupabaseClient(
      'https://test.supabase.co',
      'fixture-key',
      httpClient: MockClient((_) async => throw StateError('must not upload')),
    );
    addTearDown(client.dispose);
    await expectLater(
      FixtureUploads(client).publishWithProgress(
        PostDraft(
          place: fixtures.restaurant,
          photos: [
            PostPhoto(
              bytes: Uint8List(maxPostPhotoBytes + 1),
              mimeType: 'image/jpeg',
            ),
          ],
          ratings: const {},
          body: '',
        ),
        'request',
        'user-a',
        (_) {},
      ),
      throwsException,
    );
  });
}
