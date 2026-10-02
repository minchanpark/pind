import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pind_flutter/controllers/post_controller.dart';
import 'package:pind_flutter/model/post_model.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/services/post_photo_service.dart';
import 'package:pind_flutter/services/post_service.dart';
import 'package:pind_flutter/view/explore/map_filter_chip.dart';
import 'package:pind_flutter/view/posts/post_composer.dart';
import 'package:pind_flutter/view/design_system.dart';

// Original Figma imagery is used only in this native QA fixture.
class FixturePhotos implements PostPhotoService {
  @override
  Future<List<PostPhoto>> pick(int remaining) async {
    final photos = <PostPhoto>[];
    for (final n in [1, 2]) {
      final data = await rootBundle.load('assets/preview/post_photo_$n.png');
      photos.add(
        PostPhoto(bytes: data.buffer.asUint8List(), mimeType: 'image/png'),
      );
    }
    return photos;
  }
}

class FixturePosts implements PostService {
  @override
  String get userId => 'native-post-qa';
  final drafts = <PostDraft>[];
  @override
  Future<PublishedPost> publish(
    PostDraft draft,
    String requestId,
    String? authorId,
  ) async {
    drafts.add(draft);
    return const PublishedPost(id: 7, placeId: 42);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'native composer, photo slots, ratings, publish and glass chips',
    (tester) async {
      final posts = FixturePosts();
      final controller = PostController(
        posts: posts,
        photos: FixturePhotos(),
        place: const Place(
          id: 42,
          provider: PlaceProvider.sbiz,
          externalId: 'native-qa',
          name: '을지로 숯불갈비',
          category: '고기구이',
          address: '중구 을지로3가',
          latitude: 37.57,
          longitude: 126.98,
          mapsUri: 'https://example.com/place',
          pindPostCount: 0,
        ),
      );
      PublishedPost? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: PindTheme.data,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Builder(
              builder: (context) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE9EFE9), Color(0xFFE6DDF5)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MapFilterChip(
                            label: '전체',
                            selected: true,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          MapFilterChip(
                            label: '☕ 카페',
                            selected: false,
                            onTap: () {},
                          ),
                        ],
                      ),
                      FilledButton(
                        onPressed: () async {
                          saved = await Navigator.push<PublishedPost>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PostComposer(controller: controller),
                            ),
                          );
                        },
                        child: const Text('작성 열기'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot('map-filter-chips');
      await tester.tap(find.text('작성 열기'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('publish-post')))
            .onPressed,
        isNull,
      );
      await binding.takeScreenshot('post-composer-empty');
      await controller.addPhotos();
      controller.rate(PreferenceCriterion.taste, 5);
      controller.rate(PreferenceCriterion.portion, 4);
      controller.rate(PreferenceCriterion.ambience, 4);
      await tester.pumpAndSettle();
      final body = find.byType(TextField);
      await tester.ensureVisible(body);
      await tester.enterText(body, '연탄 향이 제대로예요. 양념갈비보다 생갈비를 추천합니다.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(controller.model.body, contains('생갈비'));
      expect(find.text('연탄 향이 제대로예요. 양념갈비보다 생갈비를 추천합니다.'), findsOneWidget);
      await binding.takeScreenshot('post-composer-filled-bottom');
      await tester.drag(find.byType(ListView).first, const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.text('최고예요'), findsOneWidget);
      expect(find.text('★ 4'), findsOneWidget);
      await binding.takeScreenshot('post-composer-filled');
      // The button ends the page rather than floating over it.
      await tester.ensureVisible(find.byKey(const ValueKey('publish-post')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('publish-post')));
      await tester.pumpAndSettle();
      expect(saved?.placeId, 42);
      expect(posts.drafts.single.photos.length, 2);
      expect(posts.drafts.single.body, contains('생갈비'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
