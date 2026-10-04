import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/view/components/pind_pressable.dart';

void main() {
  double scaleOf(WidgetTester tester, Key key) => tester
      .widget<ScaleTransition>(
        find
            .descendant(
              of: find.byKey(key),
              matching: find.byType(ScaleTransition),
            )
            .first,
      )
      .scale
      .value;

  testWidgets('a quick tap dips all the way, then springs back', (
    tester,
  ) async {
    const outer = Key('outer'), inner = Key('inner');
    await tester.pumpWidget(
      const Center(
        child: PindPressable(
          key: outer,
          child: ColoredBox(
            color: Color(0xFFFFFFFF),
            child: SizedBox(
              width: 200,
              height: 80,
              child: Center(
                child: PindPressable(
                  key: inner,
                  scale: .85,
                  child: ColoredBox(
                    color: Color(0xFF000000),
                    child: SizedBox.square(dimension: 30),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Lifted before the dip finished: it still reaches the bottom.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(inner)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 79));
    expect(scaleOf(tester, inner), closeTo(.85, .02));
    // Only the innermost one moves.
    expect(scaleOf(tester, outer), 1);
    await tester.pumpAndSettle();
    expect(scaleOf(tester, inner), 1);
  });
}
