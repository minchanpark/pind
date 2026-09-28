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

/// Preserve the supplied SVG root dimensions; only their original slots move.
class _FigmaIcon extends StatelessWidget {
  const _FigmaIcon({required this.name, required this.active});
  final String name;
  final bool active;
  static const size = PindNavigationBar.iconFrame;

  Widget _asset(String file, double x, double y, double width, double height) =>
      Positioned(
        left: x,
        top: y,
        child: SvgPicture.asset(
          'assets/figma/nav_$file.svg',
          width: width,
          height: height,
          excludeFromSemantics: true,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state = active ? 'active' : 'inactive';
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: switch (name) {
          'discover' => [
            _asset(
              'discover_${state}_ring',
              (size - 25.0344) / 2,
              (size - 25.0344) / 2,
              25.0344,
              25.0344,
            ),
            _asset(
              'discover_${state}_needle',
              (size - 10.0115) / 2,
              (size - 10.0115) / 2,
              10.0115,
              10.0115,
            ),
          ],
          'map' => [_asset('map_$state', size / 8, size / 8, 22.5344, 22.5344)],
          'compose' => [
            _asset('compose_outline', size / 8, size / 12, 23.7863, 23.7863),
            _asset(
              'compose_lines',
              size * 7 / 24,
              size * 3 / 8,
              10.0153,
              10.0153,
            ),
          ],
          'profile' => [
            _asset(
              'profile_${state}_body',
              (size - 23.1603) / 2,
              size * 7 / 12 - (10.6412 - size / 4) / 2,
              23.1603,
              10.6412,
            ),
            _asset(
              'profile_${state}_head',
              (size - 10.6412) / 2,
              size / 6 - (10.6412 - size / 4) / 2,
              10.6412,
              10.6412,
            ),
          ],
          _ => const [],
        },
      ),
    );
  }
}
