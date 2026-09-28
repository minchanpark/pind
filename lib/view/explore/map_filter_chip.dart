import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/pind_glass.dart';
import '../theme.dart';

/// Figma 542:22927 (all) / 542:22930 (category).
class MapFilterChip extends StatelessWidget {
  const MapFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final all = label == '전체';
    final parts = label.split(' ');
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: math.max(
            44,
            MediaQuery.textScalerOf(context).scale(13) * 1.2 + 22,
          ),
          child: Center(
            child: PindGlass(
              tone: all ? PindGlassTone.dark : PindGlassTone.light,
              radius: 20,
              borderColor: !all && selected ? PindTheme.purple : null,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!all) ...[
                      Text(
                        parts.first,
                        style: const TextStyle(fontSize: 15, height: 1),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      all ? '전체' : parts.skip(1).join(' '),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        letterSpacing: 0,
                        fontWeight: all ? FontWeight.w700 : FontWeight.w500,
                        color: all ? Colors.white : PindTheme.ink,
                      ),
                    ),
                    if (all) ...[
                      const SizedBox(width: 5),
                      const Text(
                        '▾',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
