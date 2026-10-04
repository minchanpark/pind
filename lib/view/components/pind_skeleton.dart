import 'package:flutter/material.dart';

import '../design_system.dart';

/// Grey stand-ins in the shape of content still loading, breathing gently.
class PindSkeleton extends StatefulWidget {
  const PindSkeleton({super.key, required this.child});
  final Widget child;

  @override
  State<PindSkeleton> createState() => _PindSkeletonState();
}

class _PindSkeletonState extends State<PindSkeleton>
    with SingleTickerProviderStateMixin {
  late final pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final opacity = Tween(begin: .45, end: 1.0).animate(pulse);

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: FadeTransition(opacity: opacity, child: widget.child),
  );
}

/// One grey block of a [PindSkeleton].
Widget bone(double? width, double height, {double radius = 8}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(
    color: PindColors.chip,
    borderRadius: BorderRadius.circular(radius),
  ),
);

/// [count] stand-ins of one [row], breathing as one; every list's loading
/// state is built from this.
Widget skeletonList(Widget row, {required int count, double spacing = 0}) =>
    PindSkeleton(
      child: Column(
        spacing: spacing,
        children: [for (var i = 0; i < count; i++) row],
      ),
    );

/// Post cards still loading, shaped like PostCard: avatar beside name and
/// body, then the photos.
Widget postsSkeleton({int count = 3}) => skeletonList(
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 10,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          spacing: 7,
          children: [
            bone(32, 32, radius: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [bone(110, 14), bone(200, 12)],
            ),
          ],
        ),
      ),
      bone(double.infinity, 179, radius: PindRadius.card),
    ],
  ),
  count: count,
  spacing: 36,
);

/// People still loading, shaped like PersonRow: photo, name, handle.
Widget peopleSkeleton({int count = 6}) => skeletonList(
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      spacing: 12,
      children: [
        bone(44, 44, radius: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [bone(110, 14), bone(70, 12)],
        ),
      ],
    ),
  ),
  count: count,
);

/// Places still loading, shaped like a ranking row: photo, rank and name,
/// details and taste chips, then the save circle.
Widget placesSkeleton({int count = 5}) => skeletonList(
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 14,
      children: [
        bone(76, 76, radius: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              bone(140, 16),
              bone(100, 12),
              Row(
                spacing: 6,
                children: [bone(54, 22, radius: 11), bone(54, 22, radius: 11)],
              ),
            ],
          ),
        ),
        bone(28, 28, radius: 14),
      ],
    ),
  ),
  count: count,
);
