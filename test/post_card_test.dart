import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/view/components/post_card.dart';

void main() {
  Future<List<Rect>> frames(WidgetTester tester, int count) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: PostCard(
                post: MyPost(
                  id: 1,
                  place: const Place(
                    provider: PlaceProvider.sbiz,
                    externalId: 'p1',
                    name: '가게',
                    category: '한식',
                    address: '서울',
                    latitude: 37.5,
                    longitude: 127,
                    mapsUri: 'https://example.com',
                  ),
                  photos: [for (var i = 0; i < count; i++) 'https://x/$i.jpg'],
                  createdAt: DateTime(2026, 10, 1),
                ),
                author: const UserProfile(id: 'u', displayName: '나'),
                action: const SizedBox(),
              ),
            ),
          ),
        ),
      ),
    );
    // Photo frames are the containers that clip a network image.
    return [
      for (final e in find.byType(Image).evaluate())
        tester.getRect(
          find
              .ancestor(
                of: find.byWidget(e.widget),
                matching: find.byType(Container),
              )
              .first,
        ),
    ];
  }

  testWidgets(
    'one large, two medium side by side and centered, three as before',
    (tester) async {
      final one = await frames(tester, 1);
      expect(one.single.size, const Size(214, 262));

      final two = await frames(tester, 2);
      expect(two.map((r) => r.size), everyElement(const Size(140, 190)));
      expect(two[0].top, two[1].top); // same row
      expect(two[1].left - two[0].right, 10);
      final screen = tester.getRect(find.byType(PostCard)).center.dx;
      expect((two[0].left + two[1].right) / 2, closeTo(screen, .01));

      final three = await frames(tester, 3);
      // Unchanged trio: an upright center card between two tilted ones.
      expect(three, hasLength(3));
      expect(three.where((r) => r.size == const Size(109, 165)), hasLength(1));
    },
  );
}
