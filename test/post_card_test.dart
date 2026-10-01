import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/model/places.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/view/components/pind_glass.dart';
import 'package:pind_flutter/view/components/post_card.dart';
import 'package:pind_flutter/view/theme.dart';

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

  testWidgets('one large, two fanned and centered, three as before', (
    tester,
  ) async {
    final one = await frames(tester, 1);
    expect(one.single.size, const Size(214, 262));
    // The place pill overlaps the photo's top edge by about half its height.
    final pill = tester.getRect(
      find
          .ancestor(of: find.text('📍가게'), matching: find.byType(PindGlass))
          .first,
    );
    expect(pill.bottom - one.single.top, 15);

    await frames(tester, 2);
    // A fanned pair: tilted opposite ways, the first photo in front and purple.
    double angle(int i) {
      final image = find.byWidgetPredicate(
        (w) =>
            w is Image && (w.image as NetworkImage).url == 'https://x/$i.jpg',
      );
      final m = tester
          .widget<Transform>(
            find.ancestor(of: image, matching: find.byType(Transform)).first,
          )
          .transform;
      return math.atan2(m.entry(1, 0), m.entry(0, 0)) * 180 / math.pi;
    }

    expect(angle(0), closeTo(-5, .01));
    expect(angle(1), closeTo(7, .01));
    // The pair's own stack, not the one inside each card.
    final stack = find.ancestor(
      of: find.byType(Image).first,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Stack && w.clipBehavior == Clip.none && w.children.length == 2,
      ),
    );
    final cards = tester.widget<Stack>(stack).children;
    expect(cards, hasLength(2));
    final front = find.descendant(
      of: find.byWidget(cards.last),
      matching: find.byType(Container),
    );
    final border =
        (tester.widget<Container>(front.first).foregroundDecoration!
                as BoxDecoration)
            .border!
            .top
            .color;
    expect(border, PindTheme.purple);
    expect(find.byType(Image).evaluate().length, 2);
    final box = tester.getRect(stack);
    expect(box.size, const Size(260, 180));
    expect(
      box.center.dx,
      closeTo(tester.getRect(find.byType(PostCard)).center.dx, .01),
    );

    final three = await frames(tester, 3);
    // Unchanged trio: an upright center card between two tilted ones.
    expect(three, hasLength(3));
    expect(three.where((r) => r.size == const Size(109, 165)), hasLength(1));
  });
}
