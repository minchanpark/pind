import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_system.dart';
import 'pind_pressable.dart';

enum PindGlassTone { light, dark, purple, lime }

/// Shared glass surfaces from the post composer and map filter chips.
class PindGlass extends StatelessWidget {
  const PindGlass({
    super.key,
    required this.child,
    this.tone = PindGlassTone.light,
    this.radius = 20,
    this.padding = EdgeInsets.zero,
    this.borderColor,
    this.borderWidth = 1,
    this.fillColor,
  });
  final Widget child;
  final PindGlassTone tone;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double borderWidth;

  /// Replaces the tone's fill; rim, sheen and shadow stay the tone's.
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final (color, border, highlight, rim) = switch (tone) {
      PindGlassTone.light => (
        const Color.fromRGBO(251, 251, 253, .72),
        PindColors.border,
        .9,
        .95,
      ),
      PindGlassTone.dark => (
        const Color.fromRGBO(20, 20, 24, .7),
        const Color.fromRGBO(0, 0, 0, .7),
        .28,
        .2,
      ),
      PindGlassTone.purple => (
        const Color.fromRGBO(99, 0, 219, .7),
        const Color.fromRGBO(58, 0, 136, .7),
        .45,
        .35,
      ),
      PindGlassTone.lime => (
        const Color.fromRGBO(244, 255, 90, .94),
        const Color.fromRGBO(163, 173, 0, .75),
        .9,
        .9,
      ),
    };
    final corners = BorderRadius.circular(radius);
    final glass = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: [
          const BoxShadow(
            color: Color.fromRGBO(0, 0, 0, .05),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color.fromRGBO(
              0,
              0,
              0,
              tone == PindGlassTone.light ? .05 : .08,
            ),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: corners,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: CustomPaint(
            foregroundPainter: _GlassHighlights(radius, highlight, rim),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fillColor ?? color,
                borderRadius: corners,
                border: Border.all(
                  color: borderColor ?? border,
                  width: borderWidth,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: Padding(padding: padding, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // A glass around a live tap target is a button: it gives under the finger.
    final target = child;
    return target is InkWell && target.onTap != null
        ? PindPressable(child: glass)
        : glass;
  }
}

class _GlassHighlights extends CustomPainter {
  const _GlassHighlights(this.radius, this.highlight, this.rim);
  final double radius, highlight, rim;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(1);
    final shape = RRect.fromRectAndRadius(bounds, Radius.circular(radius));
    canvas.save();
    canvas.clipRRect(shape);
    for (final shadow in [
      const BoxShadow(
        color: Color.fromRGBO(138, 140, 150, .03),
        offset: Offset(0, -1),
        blurRadius: 2.5,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: highlight),
        offset: const Offset(0, 2),
        blurRadius: 2,
      ),
      BoxShadow(color: Colors.white.withValues(alpha: rim), blurRadius: 1.5),
    ]) {
      final outside = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(bounds.inflate(16))
        ..addRRect(shape.shift(shadow.offset));
      canvas.drawPath(
        outside,
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            shadow.blurRadius / 2,
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlassHighlights old) =>
      radius != old.radius || highlight != old.highlight || rim != old.rim;
}
