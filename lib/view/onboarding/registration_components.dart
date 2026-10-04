import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../components/pind_glass.dart';
import '../design_system.dart';
import '../../l10n/l10n.dart';

class SetupPage extends StatelessWidget {
  const SetupPage({
    super.key,
    required this.children,
    required this.footer,
    this.progress,
    this.onBack,
    this.background = Colors.white,
  });
  final List<Widget> children;
  final Widget footer;
  final int? progress;
  final VoidCallback? onBack;
  final Color background;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background,
    body: SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    progress == null ? 40 : 0,
                    24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (progress != null) ...[
                        SizedBox(
                          height: 24,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: -14,
                                top: -7,
                                child: IconButton(
                                  tooltip: l10n.previous,
                                  onPressed: onBack,
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    size: 24,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 21,
                                right: 0,
                                top: 12,
                                child: Row(
                                  children: [
                                    for (var i = 1; i <= 3; i++)
                                      Expanded(
                                        child: Container(
                                          height: 4,
                                          margin: const EdgeInsets.only(
                                            right: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: i <= progress!
                                                ? PindColors.purple
                                                : PindColors.border,
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$progress/3',
                                      style: const TextStyle(
                                        fontSize: PindType.label,
                                        fontWeight: FontWeight.w700,
                                        color: PindColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      ...children,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  12,
                  24,
                  MediaQuery.viewInsetsOf(context).bottom > 0
                      ? 16
                      : math.max(28, MediaQuery.viewPaddingOf(context).bottom),
                ),
                child: footer,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class SetupTitle extends StatelessWidget {
  const SetupTitle(this.title, this.subtitle, {super.key, this.large = false});
  final String title, subtitle;
  final bool large;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: large ? 28 : 25,
          height: 1.36,
          letterSpacing: -.5,
          fontWeight: FontWeight.w700,
          color: PindColors.ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: PindType.bodySmall,
          height: 1.46,
          color: PindColors.muted,
        ),
      ),
    ],
  );
}

class SetupButton extends StatelessWidget {
  const SetupButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: PindColors.purpleLight,
        minimumSize: const Size.fromHeight(54),
        padding: const EdgeInsets.symmetric(vertical: 17),
        side: BorderSide(
          color: onPressed == null
              ? Colors.transparent
              : const Color(0xB33A0088),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      child: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    ),
  );
}

class SetupGlass extends StatelessWidget {
  const SetupGlass({
    super.key,
    required this.child,
    this.selected = false,
    this.radius = 16,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });
  final Widget child;
  final bool selected;
  final double radius;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: selected ? const Color(0xCCF4FF5A) : const Color(0xB8FBFBFD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(
              color: selected ? PindColors.ink : PindColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    ),
  );
}

class SetupError extends StatelessWidget {
  const SetupError(this.error, {super.key});
  final String? error;
  @override
  Widget build(BuildContext context) => error == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: TextStyle(
                fontSize: PindType.bodySmall,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        );
}

/// Setup-screen circles (map bubbles, check marks, avatar add button) drawn
/// in the app's glass tones.
class SetupCircle extends StatelessWidget {
  const SetupCircle(
    this.diameter, {
    super.key,
    this.tone = PindGlassTone.light,
    this.fillColor,
    this.borderColor,
  });

  /// Yellow selection mark (country, cuisine, avatar add button).
  const SetupCircle.check(this.diameter, {super.key})
    : tone = PindGlassTone.lime,
      fillColor = const Color.fromRGBO(244, 255, 90, .8),
      borderColor = null;

  final double diameter;
  final PindGlassTone tone;
  final Color? fillColor, borderColor;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: diameter,
    child: PindGlass(
      tone: tone,
      radius: diameter / 2,
      fillColor: fillColor,
      borderColor: borderColor,
      child: const SizedBox.expand(),
    ),
  );
}
