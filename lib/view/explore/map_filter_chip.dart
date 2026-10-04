import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../components/pind_glass.dart';
import '../components/pind_pressable.dart';
import '../design_system.dart';
import '../../l10n/l10n.dart';

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
            child: PindPressable(
              scale: .9,
              child: PindGlass(
                tone: all ? PindGlassTone.dark : PindGlassTone.light,
                radius: 20,
                borderColor: !all && selected ? PindColors.purple : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!all) ...[
                        Text(
                          parts.first,
                          style: const TextStyle(
                            fontSize: PindType.bodyLarge,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        all
                            ? l10n.categoryAll
                            : mapCategoryName(parts.skip(1).join(' ')),
                        style: TextStyle(
                          fontSize: PindType.bodySmall,
                          height: 1.2,
                          letterSpacing: 0,
                          fontWeight: all ? FontWeight.w700 : FontWeight.w500,
                          color: all ? Colors.white : PindColors.ink,
                        ),
                      ),
                      if (all) ...[
                        const SizedBox(width: 5),
                        const Text(
                          '▾',
                          style: TextStyle(
                            fontSize: PindType.bodySmall,
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
      ),
    );
  }
}

/// The map's category keys are Korean ('☕ 카페'); this is how they read in
/// the app's language.
String mapCategoryName(String korean) => switch (korean) {
  '카페' => l10n.categoryCafe,
  '술집' => l10n.categoryBar,
  '고기' => l10n.categoryMeat,
  '면' => l10n.categoryNoodles,
  '디저트' => l10n.categoryDessert,
  '전체' => l10n.categoryAll,
  _ => korean,
};

/// A whole key, emoji kept: '☕ 카페' → '☕ Cafés'.
String mapCategoryLabel(String key) {
  final parts = key.split(' ');
  return parts.length < 2
      ? mapCategoryName(key)
      : '${parts.first} ${mapCategoryName(parts.skip(1).join(' '))}';
}
