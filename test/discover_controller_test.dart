import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/discover_controller.dart';
import 'package:pind_flutter/model/discover_model.dart';
import 'package:pind_flutter/model/place_search_result.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/services/data_revision.dart';
import 'package:pind_flutter/services/discover_service.dart';
import 'package:pind_flutter/services/post_media_urls.dart';

Place place(int id) => Place(
  id: id,
  provider: PlaceProvider.sbiz,
  externalId: 'p$id',
  name: '가게 $id',
  category: '카페',
  address: '서울',
  latitude: 37.5,
  longitude: 127.0,
  mapsUri: 'https://example.com/$id',
);

FeedPost post(int id, {bool liked = false, int likeCount = 0}) => FeedPost(
  post: MyPost(id: id, place: place(id), createdAt: DateTime(2026, 1, id)),
  author: UserProfile(id: 'u$id', displayName: '작성자 $id'),
  liked: liked,
  likeCount: likeCount,
);

/// Returns queued pages/errors in call order, unless [gate] is set, in
/// which case the next call waits on it instead.
class FakeDiscoverService implements DiscoverService {
  final feedQueue = <Object>[]; // FeedPage or Object (error)
  final likeCalls = <(int, bool)>[];
  Object? likeError;
  Completer<FeedPage>? gate;

  @override
  Future<FeedPage> feed({FeedPost? after, String query = '', int limit = 20}) {
    if (gate case final g?) return g.future;
    final next = feedQueue.removeAt(0);
    if (next is FeedPage) return Future.value(next);
    return Future.error(next);
  }

  @override
  Future<bool> setLiked(int postId, bool liked) async {
    likeCalls.add((postId, liked));
    if (likeError case final e?) throw e;
    return liked;
  }
}

DiscoverController controller(FakeDiscoverService service) {
  final c = DiscoverController(service: service);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('load populates posts in server order', () async {
    final service = FakeDiscoverService()
      ..feedQueue.add(FeedPage([post(1), post(2)], hasMore: false));
    final c = controller(service);
    await c.load();
    expect(c.model.posts.map((p) => p.post.id), [1, 2]);
    expect(c.model.hasMore, isFalse);
    expect(c.model.loading, isFalse);
  });

  test('loadMore appends, dedupes, and stops once hasMore is false', () async {
    final service = FakeDiscoverService()
      ..feedQueue.add(FeedPage([post(1), post(2)], hasMore: true))
      ..feedQueue.add(FeedPage([post(2), post(3)], hasMore: false));
    final c = controller(service);
    await c.load();
    await c.loadMore();
    expect(c.model.posts.map((p) => p.post.id), [1, 2, 3]);
    expect(c.model.hasMore, isFalse);

    // No more pages queued; a no-op loadMore must not call the service.
    await c.loadMore();
    expect(c.model.posts.map((p) => p.post.id), [1, 2, 3]);
  });

  test('a stale in-flight page is discarded by a later load', () async {
    final service = FakeDiscoverService();
    final c = controller(service);
    final stale = Completer<FeedPage>();
    service.gate = stale;
    final firstLoad = c.load(); // hangs on `stale`

    service.gate = null;
    service.feedQueue.add(FeedPage([post(9)], hasMore: false));
    await c.load();

    expect(c.model.posts.map((p) => p.post.id), [9]);

    stale.complete(FeedPage([post(1)], hasMore: false));
    await firstLoad;
    // The stale page must not have overwritten the newer load's result.
    expect(c.model.posts.map((p) => p.post.id), [9]);
  });

  test(
    'toggleLike is optimistic, reverts on failure, and fixes the count',
    () async {
      final service = FakeDiscoverService()
        ..feedQueue.add(
          FeedPage([post(1, liked: false, likeCount: 3)], hasMore: false),
        )
        ..likeError = const PlaceFailure('로그인 후 좋아요를 누를 수 있어요.');
      final c = controller(service);
      await c.load();

      final future = c.toggleLike(c.model.posts.first);
      // Synchronous portion of toggleLike runs before the first await.
      expect(c.model.posts.first.liked, isTrue);
      expect(c.model.posts.first.likeCount, 4);

      await future;
      expect(c.model.posts.first.liked, isFalse);
      expect(c.model.posts.first.likeCount, 3);
      expect(c.model.error, '로그인 후 좋아요를 누를 수 있어요.');
    },
  );

  test('a double tap while a like is in flight is ignored', () async {
    final service = FakeDiscoverService()
      ..feedQueue.add(FeedPage([post(1, likeCount: 0)], hasMore: false));
    final c = controller(service);
    await c.load();

    final a = c.toggleLike(c.model.posts.first);
    final b = c.toggleLike(c.model.posts.first);
    await Future.wait([a, b]);
    expect(service.likeCalls.length, 1);
    expect(c.model.posts.first.liked, isTrue);
    expect(c.model.posts.first.likeCount, 1);
  });

  test('dispose stops further model updates', () async {
    final service = FakeDiscoverService();
    final c = DiscoverController(service: service);
    final gate = Completer<FeedPage>();
    service.gate = gate;
    final pending = c.load();
    c.dispose();
    gate.complete(FeedPage([post(1)], hasMore: false));
    await pending;
    expect(c.model.posts, isEmpty);
  });

  group('parseMyPost', () {
    Map<String, dynamic> row({required String bucket, required List photos}) =>
        {
          'id': 1,
          'place': {
            'provider': 'sbiz',
            'externalPlaceId': 'p1',
            'name': '가게',
            'category': '카페',
            'address': '서울',
            'latitude': 37.5,
            'longitude': 127.0,
            'sourceUri': 'https://example.com',
          },
          'body': '맛있어요',
          'ratings': {'taste': 5},
          'bucket': bucket,
          'photos': photos,
          'createdAt': '2026-01-01T00:00:00.000Z',
        };

    test('resolves a legacy-bucket photo via its resolver', () {
      // Mirrors what resolvePostPhotoUrl does for postMediaLegacyBucket,
      // without needing a live Supabase client in a unit test.
      final parsed = parseMyPost(
        row(bucket: postMediaLegacyBucket, photos: ['a.jpg']),
        photoUrl: (p) => 'https://legacy-public/$p',
      );
      expect(parsed.photos, ['https://legacy-public/a.jpg']);
    });

    test('omits a v2 photo the server failed to sign', () {
      final signed = {'signed.jpg': 'https://signed/signed.jpg'};
      final parsed = parseMyPost(
        row(bucket: postMediaV2Bucket, photos: ['signed.jpg', 'unsigned.jpg']),
        photoUrl: (p) => signed[p],
      );
      expect(parsed.photos, ['https://signed/signed.jpg']);
    });
  });

  test(
    'my profile edit swaps my posts\' author in place, no refetch',
    () async {
      final service = FakeDiscoverService()
        ..feedQueue.add(FeedPage([post(1), post(2), post(3)], hasMore: false));
      final c = DiscoverController(service: service);
      await c.load();
      final me = c.model.posts[1].author.copyWith(
        displayName: '새 이름',
        avatarUrl: 'https://x/new.png',
      );
      var notified = 0;
      c.model.addListener(() => notified++);
      myProfileEdits.add(me);
      await Future<void>.delayed(Duration.zero); // broadcast delivery
      expect(
        [for (final p in c.model.posts) p.author.avatarUrl],
        [null, 'https://x/new.png', null],
      );
      expect(c.model.posts[1].author.displayName, '새 이름');
      expect(c.model.posts[1].post.id, 2); // same post, likes kept
      expect(notified, 1);
      expect(service.feedQueue, isEmpty); // no second feed request was needed
      // After dispose the subscription is gone; an edit must not touch it.
      c.dispose();
      myProfileEdits.add(me);
      await Future<void>.delayed(Duration.zero);
    },
  );
}
