import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// iOS-style press feedback in place of a ripple: the child dips under the
/// finger and springs back when it lifts. A quick tap still gets the full
/// dip; a touch that turns into a scroll lets go at once.
class PindPressable extends StatefulWidget {
  const PindPressable({super.key, required this.child, this.scale = .95});
  final Widget child;

  /// How far it shrinks; small targets need more to be seen.
  final double scale;

  @override
  State<PindPressable> createState() => _PindPressableState();
}

class _PindPressableState extends State<PindPressable>
    with SingleTickerProviderStateMixin {
  /// The pointer the innermost pressable took, so the rows and cards around
  /// a button stay still while it dips.
  static int? claimed;

  late final press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final scale = Tween(begin: 1.0, end: widget.scale).animate(
    // easeInBack run backwards overshoots past full size, then settles.
    CurvedAnimation(
      parent: press,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeInBack,
    ),
  );
  Offset? down;
  TickerFuture? dip;

  void lift({bool finishDip = true}) {
    if (down == null) return;
    down = null;
    if (finishDip && press.status == AnimationStatus.forward) {
      dip!.then((_) {
        if (mounted && down == null) press.reverse();
      });
    } else {
      press.reverse();
    }
  }

  @override
  void dispose() {
    press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (e) {
      if (claimed == e.pointer) return;
      claimed = e.pointer;
      down = e.position;
      dip = press.forward();
    },
    onPointerMove: (e) {
      if (down != null && (e.position - down!).distance > kTouchSlop) {
        lift(finishDip: false);
      }
    },
    onPointerUp: (_) => lift(),
    onPointerCancel: (_) => lift(finishDip: false),
    child: ScaleTransition(scale: scale, child: widget.child),
  );
}
