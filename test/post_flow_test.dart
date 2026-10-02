import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/post_controller.dart';
import 'package:pind_flutter/model/post_model.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/place_search_result.dart';
import 'package:pind_flutter/services/post_service.dart';
import 'package:pind_flutter/services/post_photo_service.dart';
import 'package:pind_flutter/view/posts/post_composer.dart';
import 'package:pind_flutter/view/design_system.dart';
import 'package:pind_flutter/controllers/explore_controller.dart';
import 'package:pind_flutter/services/place_service.dart';

const restaurant = Place(
  id: 42,
  provider: PlaceProvider.sbiz,
  externalId: 'post-test',
  name: '을지로 숯불갈비',
  category: '고기구이',
  address: '중구 을지로3가',
  latitude: 37.56,
  longitude: 126.97,
  mapsUri: 'https://example.com/place',
  pindPostCount: 0,
);

class TestPosts implements PostService {
  @override
  String? get userId => 'test-user';
  final requests = <String>[];
  final drafts = <PostDraft>[];
  Completer<PublishedPost>? pending;
  bool fail = false;
  @override
  Future<void> delete(int postId) => throw UnimplementedError();
  @override
  Future<PublishedPost> publish(
    PostDraft draft,
    String requestId,
    String? authorId,
  ) async {
    requests.add(requestId);
    drafts.add(draft);
    if (fail) throw const PlaceFailure('등록 실패');
    return pending == null
        ? const PublishedPost(id: 7, placeId: 42)
        : pending!.future;
  }
}

class TestPhotos implements PostPhotoService {
  Completer<List<PostPhoto>>? pending;
  @override
  Future<List<PostPhoto>> pick(int remaining) async => pending == null
      ? [
          PostPhoto(
            bytes: File('assets/preview/post_photo_1.png').readAsBytesSync(),
            mimeType: 'image/png',
          ),
          PostPhoto(
            bytes: File('assets/preview/post_photo_2.png').readAsBytesSync(),
            mimeType: 'image/png',
          ),
        ]
      : pending!.future;
}

PostController make(TestPosts posts, {TestPhotos? photos}) => PostController(
  posts: posts,
  photos: photos ?? TestPhotos(),
  place: restaurant,
);
Future<void> ready(PostController controller) async {
  await controller.addPhotos();
  controller.rate(PreferenceCriterion.taste, 5);
  controller.rate(PreferenceCriterion.portion, 4);
  controller.rate(PreferenceCriterion.ambience, 4);
}

void main() {
  test(
    'published place reloads server counts around its coordinates',
    () async {
      var published = false;
      final requests = <Map<String, dynamic>>[];
      final payload = <String, dynamic>{
        'provider': 'sbiz',
        'internalId': 42,
        'externalPlaceId': 'post-test',
        'name': restaurant.name,
        'category': restaurant.category,
        'address': restaurant.address,
        'latitude': restaurant.latitude,
        'longitude': restaurant.longitude,
        'sourceUri': restaurant.mapsUri,
        'pindPostCount': 1,
      };
      final controller = ExploreController(
        PlaceService((body) async {
          requests.add(Map<String, dynamic>.from(body));
          return body['action'] == 'catalog_detail'
              ? {'place': payload}
              : {
                  'places': published ? [payload] : <dynamic>[],
                };
        }),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.places, isEmpty);
      published = true;
      await controller.showPublishedPlace(42);
      expect(requests[1]['internalPlaceId'], 42);
      expect(controller.viewport.latitude, restaurant.latitude);
      expect(controller.viewport.longitude, restaurant.longitude);
      expect(controller.places.single.pindPostCount, 1);
      expect(controller.places.single.canShowOnMap, true);
      expect(controller.publishedRevision, 1);
    },
  );
  test(
    'publish waits for a photo and all ratings; body remains optional',
    () async {
      final service = TestPosts();
      final controller = make(service);
      addTearDown(controller.dispose);
      controller.rate(PreferenceCriterion.taste, 5);
      expect(await controller.publish(), isNull);
      expect(service.requests, isEmpty);
      await ready(controller);
      final saved = await controller.publish();
      expect(saved!.placeId, 42);
      expect(service.drafts.single.body, isEmpty);
      expect(service.drafts.single.photos.length, 2);
    },
  );
  test('ratings follow the author onboarding priorities', () async {
    final service = TestPosts();
    final controller = PostController(
      posts: service,
      photos: TestPhotos(),
      place: restaurant,
      criteria: const [
        PreferenceCriterion.value,
        PreferenceCriterion.quiet,
        PreferenceCriterion.parking,
      ],
    );
    addTearDown(controller.dispose);
    await controller.addPhotos();
    controller.rate(PreferenceCriterion.taste, 5);
    controller.rate(PreferenceCriterion.value, 4);
    controller.rate(PreferenceCriterion.quiet, 2);
    expect(controller.model.canPublish, false);
    controller.rate(PreferenceCriterion.parking, 3);
    expect(controller.model.average, 3);
    await controller.publish();
    expect(service.drafts.single.ratings, {
      PreferenceCriterion.value: 4,
      PreferenceCriterion.quiet: 2,
      PreferenceCriterion.parking: 3,
    });
  });
  test('pending publication blocks duplicate submit and draft edits', () async {
    final service = TestPosts()..pending = Completer();
    final controller = make(service);
    addTearDown(controller.dispose);
    await ready(controller);
    controller.setBody('좋아요');
    final saving = controller.publish();
    expect(await controller.publish(), isNull);
    controller.rate(PreferenceCriterion.taste, 1);
    controller.setBody('수정');
    controller.removePhoto(0);
    expect(controller.model.body, '좋아요');
    expect(controller.model.photos.length, 2);
    expect(controller.model.ratings[PreferenceCriterion.taste], 5);
    expect(service.requests.length, 1);
    service.pending!.complete(const PublishedPost(id: 7, placeId: 42));
    await saving;
  });
  test('failure retains draft and retry request ID', () async {
    final service = TestPosts()..fail = true;
    final controller = make(service);
    addTearDown(controller.dispose);
    await ready(controller);
    controller.setBody('실패해도 유지');
    expect(await controller.publish(), isNull);
    expect(controller.model.error, '등록 실패');
    expect(controller.model.photos.length, 2);
    expect(controller.model.body, '실패해도 유지');
    service.fail = false;
    expect((await controller.publish())!.id, 7);
    expect(service.requests[0], service.requests[1]);
  });
  test('late photo picker completion after close is ignored', () async {
    final photos = TestPhotos()..pending = Completer();
    final controller = make(TestPosts(), photos: photos);
    final picking = controller.addPhotos();
    controller.dispose();
    photos.pending!.complete([]);
    await picking;
  });
  testWidgets(
    'composer empty and completed state use real photos and ratings',
    (tester) async {
      tester.view.physicalSize = const Size(402, 1079);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = make(TestPosts());
      await tester.pumpWidget(
        MaterialApp(
          theme: PindTheme.data,
          home: PostComposer(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('publish-post')))
            .onPressed,
        isNull,
      );
      await ready(controller);
      controller.setBody('연탄 향이 제대로예요. 양념갈비보다 생갈비를 추천합니다.');
      await tester.pumpAndSettle();
      expect(find.text('최고예요'), findsOneWidget);
      expect(find.text('넉넉해요'), findsOneWidget);
      expect(find.text('좋아요'), findsOneWidget);
      expect(find.text('★ 4'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('publish-post')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('publish button ends the page instead of floating', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: PindTheme.data,
        home: PostComposer(controller: make(TestPosts())),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('publish-post'));
    final scroll = find.byType(Scrollable).first;
    // Scrolls with the content: out of reach until the page is scrolled.
    expect(button.hitTestable(), findsNothing);
    await tester.drag(scroll, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(button.hitTestable(), findsOneWidget);
    expect(tester.getRect(button).bottom, lessThanOrEqualTo(600));
    // Full width between the 18pt side margins.
    expect(tester.getSize(button).width, 402 - 36 - 2);
  });
  testWidgets('composer scrolls at 320px with large text and keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = make(TestPosts());
    await ready(controller);
    await tester.pumpWidget(
      MaterialApp(
        theme: PindTheme.data,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
            viewInsets: EdgeInsets.only(bottom: 220),
          ),
          child: PostComposer(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
