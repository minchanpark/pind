import 'package:flutter/material.dart';

/// Pind design system: every color, type size and corner radius the app
/// draws with. Screens take their values from here instead of hex literals.
///
/// Colors were consolidated from the Figma exports: near-identical grays and
/// accents map to one token each (e.g. #6B6B70, #717178, #68686E → [muted]).

abstract final class PindColors {
  // Brand.
  static const purple = Color(0xFF6300DB);
  static const purpleLight = Color(0xFF8D40DA);
  static const lime = Color(0xFFF4FF5A);
  static const limeDeep = Color(0xFFCBEF4B);
  static const pink = Color(0xFFE8336E);
  static const kakao = Color(0xFFFEE500);

  // Rating criteria (profile, place detail, post cards).
  static const taste = Color(0xFFA8154A);
  static const portion = Color(0xFFB85600);
  static const ambience = Color(0xFF1C3FC4);

  // The composer's three rating slots, and success marks.
  static const ratingOrange = Color(0xFFFF8A1F);
  static const ratingBlue = Color(0xFF3563FF);
  static const success = Color(0xFF129E5B);

  // Neutrals, dark to light.
  static const ink = Color(0xFF111111);
  static const body = Color(0xFF4A4A52);
  static const muted = Color(0xFF7A7A80);
  static const subtle = Color(0xFF9B9B9B);
  static const placeholder = Color(0xFFABABAB);
  static const imageFill = Color(0xFFD9D9D9);
  static const fill = Color(0xFFE2E2E7);
  static const border = Color(0xFFE3E4EA);
  static const line = Color(0xFFE8E8EC);
  static const chip = Color(0xFFEDEDF1);
  static const surface = Color(0xFFF6F6F8);

  // Illustration tints (onboarding, previews).
  static const pastelGreen = Color(0xFFD4E7C8);
  static const pastelSage = Color(0xFFE9EFE9);
  static const pastelLavender = Color(0xFFE6DDF5);
  static const pastelBlue = Color(0xFFDCE8F4);
}

/// Type sizes. Text in odd Figma measurements (e.g. the map search bar's
/// 14.4667) keeps its exact value where the layout depends on it.
abstract final class PindType {
  static const double tiny = 9;
  static const double micro = 10;
  static const double caption = 11;
  static const double label = 12;
  static const double bodySmall = 13;
  static const double body = 14;
  static const double bodyLarge = 15;
  static const double title = 16;
  static const double subtitle = 18;
  static const double titleLarge = 20;
  static const double headline = 24;
  static const double display = 28;
  static const double hero = 34;
}

/// Ready-made text styles for new screens.
abstract final class PindText {
  static const display = TextStyle(
    fontSize: PindType.display,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    color: PindColors.ink,
  );
  static const headline = TextStyle(
    fontSize: PindType.headline,
    fontWeight: FontWeight.w700,
    color: PindColors.ink,
  );
  static const title = TextStyle(
    fontSize: PindType.title,
    fontWeight: FontWeight.w700,
    color: PindColors.ink,
  );
  static const button = TextStyle(
    fontSize: PindType.bodyLarge,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(fontSize: PindType.body, color: PindColors.ink);
  static const label = TextStyle(
    fontSize: PindType.label,
    fontWeight: FontWeight.w700,
    color: PindColors.body,
  );
  static const caption = TextStyle(
    fontSize: PindType.label,
    color: PindColors.muted,
  );
}

abstract final class PindRadius {
  static const double sheet = 28;
  static const double card = 20;
  static const double field = 16;
  static const double chip = 14;
}

abstract final class PindTheme {
  static ThemeData get data => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PindColors.purple,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    // iOS feel: no Material ripple; a faint dim while pressed instead.
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x0F000000),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: PindColors.ink,
        height: 1.3,
      ),
      titleMedium: PindText.title,
      bodyMedium: PindText.body,
      bodySmall: PindText.caption,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PindColors.purpleLight,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        textStyle: const TextStyle(
          fontSize: PindType.title,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PindRadius.sheet),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
