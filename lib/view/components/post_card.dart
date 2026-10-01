import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../model/preferences.dart';
import '../../model/profile_model.dart';
import '../profile/profile_screen.dart';
import '../theme.dart';
import 'pind_glass.dart';

/// Figma 599:23885 post card shared by the profile posts tab and the
/// Discover feed. [action] is the trailing 44×44 button (share, like...).
/// Rating chips follow the viewer's [preferences] priorities first.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.author,
    this.preferences,
    required this.action,
    this.onPlace,
  });
  final MyPost post;
  final UserProfile author;
  final TastePreferences? preferences;
  final Widget action;
  final VoidCallback? onPlace;
  static const yellow = Color(0xFFF4FF5A);

  @override
  Widget build(BuildContext context) {
    final priorities = preferences?.priorities ?? const <PreferenceCriterion>[];
    final order = [
      ...priorities.where(post.ratings.containsKey),
      ...post.ratings.keys.where((c) => !priorities.contains(c)),
    ];
    final pill = PindGlass(
      radius: 44,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: 26,
        child: Center(
          child: Text(
            '📍${post.place.name}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Row(
          spacing: 8,
          children: [
            ProfileAvatar(author.avatarUrl, 32),
            Expanded(
              child: Text(
                author.handle == null
                    ? author.displayName
                    : '@${author.handle}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PindTheme.ink,
                ),
              ),
            ),
            action,
          ],
        ),
        if (post.body.isNotEmpty)
          Text(
            post.body,
            style: const TextStyle(
              fontSize: 12,
              height: 16.9 / 12,
              color: Colors.black,
            ),
          ),
        // Figma 599:23885: the place pill straddles the photos' top edge and
        // the rating chips their bottom edge.
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 23, bottom: 19),
              child: photos(post.photos),
            ),
            Positioned(
              top: 0,
              child: onPlace == null
                  ? pill
                  : Semantics(
                      button: true,
                      child: GestureDetector(onTap: onPlace, child: pill),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [for (final c in order) chip(c, post.ratings[c]!)],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget photos(List<String> urls) {
    switch (urls.length) {
      case 0:
        return const SizedBox(height: 24);
      case 1:
        return frame(urls[0], 214, 262, radius: 17, border: yellow, width: 4.5);
      case 2:
        // Medium cards side by side: between the single card and the trio.
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            for (final url in urls)
              frame(url, 140, 190, radius: 14, border: yellow, width: 3),
          ],
        );
      default:
        // Card-center offsets from the upright center card, Figma 599:23885.
        const left = Offset(-92.8, -6.6), right = Offset(95.1, -8.4);
        final more = urls.length - 3;
        Widget side(String url, Offset at, double degrees, {Widget? overlay}) =>
            Transform.translate(
              offset: at,
              child: Transform.rotate(
                angle: degrees * math.pi / 180,
                child: frame(
                  url,
                  109,
                  165,
                  radius: 12,
                  border: yellow,
                  width: 2,
                  overlay: overlay,
                ),
              ),
            );
        return SizedBox(
          width: 318,
          height: 165,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              side(
                urls[2],
                right,
                6.51,
                overlay: more > 0
                    ? const ColoredBox(color: Color.fromRGBO(0, 0, 0, .2))
                    : null,
              ),
              side(urls[1], left, -8.21),
              frame(
                urls[0],
                109,
                165,
                radius: 12,
                border: PindTheme.purple,
                width: 2,
              ),
              // Upright, above the tilted card, as in the design.
              if (more > 0)
                Transform.translate(
                  offset: right,
                  child: Text(
                    '+ $more',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
    }
  }

  Widget frame(
    String url,
    double w,
    double h, {
    required double radius,
    required Color border,
    required double width,
    Widget? overlay,
  }) => Container(
    width: w,
    height: h,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius)),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: width),
    ),
    child: Stack(fit: StackFit.expand, children: [placeImage(url), ?overlay]),
  );

  Widget chip(PreferenceCriterion c, int value) {
    final color = criterionColor(c);
    return Semantics(
      label: '${c.label} $value점',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 10, 8),
        decoration: BoxDecoration(
          color: const Color(0xF0FFFFFF),
          border: Border.all(color: color.withValues(alpha: .4)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, .1),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Text.rich(
          TextSpan(
            text: '${c.emoji} ',
            children: [
              TextSpan(
                text: '★ $value',
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 10, color: PindTheme.ink),
        ),
      ),
    );
  }
}

/// The 23px glass circle used as a [PostCard.action].
class PostCardButton extends StatelessWidget {
  const PostCardButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.selected,
    this.leading,
  });
  final String label;
  final Widget icon;
  final void Function(BuildContext button)? onTap;
  final bool? selected;

  /// Sits just left of the circle (e.g. a like count).
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: label,
    selected: selected,
    excludeSemantics: true,
    child: Builder(
      builder: (button) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap!(button),
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ?leading,
              SizedBox(
                width: 44,
                child: Center(
                  child: PindGlass(
                    radius: 11.5,
                    child: SizedBox(width: 21, height: 21, child: icon),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
