import 'package:flutter/material.dart';

import '../design_system.dart';
import 'pind_glass.dart';

/// The app's bottom sheet (Figma 663:5621): surface fill, 28pt top corners,
/// a drag handle, content padded 20pt and kept above the keyboard.
Future<T?> showPindSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: PindColors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(PindRadius.sheet)),
  ),
  showDragHandle: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: builder(context),
      ),
    ),
  ),
);

enum PindSheetButtonTone { primary, danger, plain }

/// A sheet's full-width 44pt glass button.
class PindSheetButton extends StatelessWidget {
  const PindSheetButton(
    this.label, {
    super.key,
    required this.onTap,
    this.tone = PindSheetButtonTone.plain,
  });
  final String label;

  /// Null disables it (e.g. while saving).
  final VoidCallback? onTap;
  final PindSheetButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final (glass, fill, border, color) = switch (tone) {
      PindSheetButtonTone.primary => (
        PindGlassTone.purple,
        null,
        null,
        Colors.white,
      ),
      PindSheetButtonTone.danger => (
        PindGlassTone.light,
        PindColors.pink.withValues(alpha: .1),
        PindColors.pink.withValues(alpha: .8),
        PindColors.pink,
      ),
      PindSheetButtonTone.plain => (
        PindGlassTone.light,
        null,
        null,
        PindColors.ink,
      ),
    };
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: PindGlass(
          tone: glass,
          radius: PindRadius.field,
          fillColor: fill,
          borderColor: border,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  label,
                  style: PindText.button.copyWith(color: color),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled one-line glass field: label left, `8/40` count right, and a
/// 48pt box with the text centered in it.
class PindTextField extends StatelessWidget {
  const PindTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.maxLength,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int? maxLength;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: PindText.label)),
            if (maxLength case final max?)
              ValueListenableBuilder(
                valueListenable: controller,
                builder: (_, value, _) => Text(
                  '${value.text.characters.length}/$max',
                  style: const TextStyle(
                    fontSize: PindType.caption,
                    color: PindColors.subtle,
                  ),
                ),
              ),
          ],
        ),
      ),
      PindGlass(
        radius: PindRadius.field,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // 46 + the glass's 1pt rim each side = a 48pt box.
        child: SizedBox(
          height: 46,
          child: Center(
            child: TextField(
              controller: controller,
              maxLength: maxLength,
              maxLines: 1,
              style: PindText.body,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                // The count sits beside the label instead.
                counterText: '',
                hintText: hint,
                hintStyle: PindText.body.copyWith(
                  color: PindColors.placeholder,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
