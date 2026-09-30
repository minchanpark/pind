import 'package:flutter/material.dart';

import '../theme.dart';

/// `‹ Title` page header that pops the route.
class PindBackHeader extends StatelessWidget {
  const PindBackHeader(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Semantics(
        button: true,
        label: '뒤로',
        child: InkWell(
          onTap: () => Navigator.maybePop(context),
          // An icon, not a '‹' glyph: glyphs sit off-center in system fonts.
          // The box is trimmed to the stroke so it lines up with the 24pt
          // inset and keeps the design's 10pt gap to the title.
          child: const ExcludeSemantics(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 8, 10, 8),
              child: SizedBox(
                width: 14,
                height: 30,
                child: OverflowBox(
                  maxWidth: 30,
                  child: Icon(
                    Icons.chevron_left,
                    size: 30,
                    color: PindTheme.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PindTheme.ink,
          ),
        ),
      ),
    ],
  );
}
