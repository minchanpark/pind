import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../model/navigation_model.dart';

/// Figma 531:17799 / 531:19123 / 531:20050. Compose is an action, not a tab.
class PindNavigationBar extends StatelessWidget {
  const PindNavigationBar({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onCompose,
  });

  static const double barWidth = 273;
  static const double barHeight = 58;
  static const double iconFrame = 30.045801162719727;
  static const double touchSize = 44;
  final PindTab selected;
  final ValueChanged<PindTab> onSelect;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('navigation-bar-bounds'),
    width: barWidth,
    height: barHeight,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(29),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, 4),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(244, 245, 248, .62),
              borderRadius: BorderRadius.circular(29),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, .95),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  _button('discover', 'Discover', 35, PindTab.discover),
                  _button('map', '지도', 87.0457992553711, PindTab.map),
                  _button('compose', '작성', 145.9541015625, null),
                  _button('profile', '마이페이지', 209, PindTab.profile),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _button(String name, String label, double left, PindTab? tab) {
    final active = tab != null && selected == tab;
    final action = tab == null ? onCompose : () => onSelect(tab);
    const outset = (touchSize - iconFrame) / 2;
    return Positioned(
      left: left - outset,
      top: 14 - outset,
      width: touchSize,
      height: touchSize,
      child: Semantics(
        container: true,
        label: label,
        button: true,
        onTap: action,
        selected: tab == null ? null : active,
        child: ExcludeSemantics(
          child: IconButton(
            key: ValueKey('nav-$name'),
            tooltip: label,
            padding: EdgeInsets.zero,
            iconSize: iconFrame,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(touchSize),
              maximumSize: const Size.square(touchSize),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: action,
            icon: _FigmaIcon(name: name, active: active),
          ),
        ),
      ),
    );
  }
}

/// `assets/navigation/` glyphs at their SVG root size, centered in the slot.
/// The files ship in inactive grey; the selected tab is tinted black.
class _FigmaIcon extends StatelessWidget {
  const _FigmaIcon({required this.name, required this.active});
  final String name;
  final bool active;

  /// Slot name → (file, SVG root size).
  static const files = {
    'discover': ('discover_icon', 26.0),
    'map': ('map_icon', 23.0),
    'compose': ('compose_icon', 31.0),
    'profile': ('profile_icon', 24.0),
  };

  @override
  Widget build(BuildContext context) {
    final (file, root) = files[name]!;
    return SizedBox.square(
      dimension: PindNavigationBar.iconFrame,
      // The 31pt compose glyph is wider than the frame; keep its root size.
      child: OverflowBox(
        minWidth: 0,
        minHeight: 0,
        maxWidth: root,
        maxHeight: root,
        child: SvgPicture.asset(
          'assets/navigation/$file.svg',
          width: root,
          height: root,
          excludeFromSemantics: true,
          colorFilter: active
              ? const ColorFilter.mode(Colors.black, BlendMode.srcIn)
              : null,
        ),
      ),
    );
  }
}
