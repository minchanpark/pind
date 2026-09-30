import 'package:flutter/material.dart';

import '../theme.dart';
import 'pind_glass.dart';

/// Figma 653:25649 / 671:35766: glass search bar; typed text turns bold and
/// the rim purple.
class PindSearchField extends StatelessWidget {
  const PindSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.fontSize = 16,
    this.verticalPadding = 12,
  });
  final TextEditingController controller;
  final String hint;

  /// Also called with '' when the clear button empties the field.
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final double fontSize, verticalPadding;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final empty = controller.text.isEmpty;
      return PindGlass(
        radius: 18,
        borderColor: empty ? null : PindTheme.purple.withValues(alpha: .55),
        borderWidth: empty ? 1 : 1.5,
        padding: const EdgeInsets.only(left: 15),
        child: Row(
          children: [
            // Apple Color Emoji draws 🔍 ~1.2pt above the hint's center;
            // nudge the paint only, layout stays put.
            Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: const Text('🔍', style: TextStyle(fontSize: 14,
                  ),
                ),
            ),  
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: autofocus,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: PindTheme.ink,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9B9B9B),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: verticalPadding,
                  ),
                ),
              ),
            ),
            if (!empty)
              IconButton(
                tooltip: '지우기',
                padding: const EdgeInsets.symmetric(horizontal: 13),
                constraints: const BoxConstraints(minHeight: 40),
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Text(
                  '✕',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9B9B9B),
                  ),
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            else
              const SizedBox(width: 13),
          ],
        ),
      );
    },
  );
}
