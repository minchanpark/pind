import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Korean (the base), English (US), Japanese and Chinese in both scripts.
const pindLocales = [
  Locale('ko'),
  Locale('en'),
  Locale('ja'),
  Locale('zh'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
];

/// The phone's languages, in its order of preference, → ours. Chinese picks
/// its script from the script tag, or from the region when there is none
/// (Taiwan, Hong Kong and Macau write Traditional). Any other language gets
/// English.
Locale resolvePindLocale(List<Locale>? device) {
  for (final l in device ?? const <Locale>[]) {
    switch (l.languageCode) {
      case 'zh':
        final traditional =
            l.scriptCode == 'Hant' ||
            (l.scriptCode == null &&
                const {'TW', 'HK', 'MO'}.contains(l.countryCode));
        return traditional ? pindLocales[4] : pindLocales[3];
      case 'ko' || 'en' || 'ja':
        return Locale(l.languageCode);
    }
  }
  return const Locale('en');
}

AppLocalizations _current = lookupAppLocalizations(const Locale('ko'));

/// Strings in the app's language, for widgets and for code without a
/// BuildContext (controllers, services). PindApp sets it from the phone's
/// languages; until then (and in widget tests) it is Korean.
AppLocalizations get l10n => _current;

/// The language [l10n] speaks, e.g. `zh-Hant`, for the server.
String get l10nTag => _tag;
String _tag = 'ko';

void setL10nLocale(Locale locale) {
  _current = lookupAppLocalizations(locale);
  _tag = locale.toLanguageTag();
}
