import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/l10n/categories.dart';
import 'package:pind_flutter/l10n/l10n.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/model/search_suggestions.dart';
import 'package:pind_flutter/view/explore/agent_search_page.dart';

void main() {
  tearDown(() => setL10nLocale(const Locale('ko')));

  test('the phone language picks ours; Chinese by script, then region', () {
    Locale pick(List<Locale>? l) => resolvePindLocale(l);
    expect(pick(const [Locale('ko', 'KR')]), const Locale('ko'));
    expect(pick(const [Locale('en', 'US')]), const Locale('en'));
    expect(pick(const [Locale('ja', 'JP')]), const Locale('ja'));
    expect(
      pick(const [
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        ),
      ]),
      const Locale('zh'),
    );
    expect(
      pick(const [
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      ]),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    // No script tag: Taiwan, Hong Kong and Macau write Traditional.
    for (final region in ['TW', 'HK', 'MO']) {
      expect(pick([Locale('zh', region)]).scriptCode, 'Hant', reason: region);
    }
    expect(pick(const [Locale('zh', 'SG')]), const Locale('zh'));
    // The first language we speak wins; anything else falls to English.
    expect(pick(const [Locale('fr'), Locale('ja')]), const Locale('ja'));
    expect(pick(const [Locale('fr')]), const Locale('en'));
    expect(pick(null), const Locale('en'));
  });

  test('every language has every string, and none is left in Korean', () {
    final korean = RegExp('[가-힣]');
    for (final locale in pindLocales) {
      setL10nLocale(locale);
      expect(l10n.navMap, isNotEmpty);
      if (locale.languageCode != 'ko') {
        for (final s in [
          l10n.navMap,
          l10n.agentTitle,
          l10n.criterionTaste,
          l10n.cuisineDessert,
          l10n.notifLikeRest,
          l10n.signOutTitle,
          l10n.cat00,
        ]) {
          expect(korean.hasMatch(s), isFalse, reason: '$locale: $s');
        }
      }
    }
  });

  test('Simplified and Traditional Chinese really differ', () {
    setL10nLocale(const Locale('zh'));
    final simplified = l10n.navMap;
    setL10nLocale(
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    expect(l10n.navMap, isNot(simplified));
    expect(l10n.navMap, '地圖');
    expect(simplified, '地图');
    expect(l10nTag, 'zh-Hant');
  });

  test('plurals, categories and suggestions read naturally per language', () {
    setL10nLocale(const Locale('en'));
    expect(l10n.reviewsCount(1), '1 review');
    expect(l10n.reviewsCount(3), '3 reviews');
    expect(l10n.friendsVisited('Haram', 0), 'Haram visited');
    expect(l10n.friendsVisited('Haram', 2), 'Haram and 2 others visited');
    expect(categoryLabel('백반/한정식'), 'Korean set meals');
    expect(categoryLabel('Some Google type'), 'Some Google type');
    final taste = TastePreferences(
      priorities: [
        PreferenceCriterion.ambience,
        PreferenceCriterion.value,
        PreferenceCriterion.photogenic,
      ],
      occasions: [DiningOccasion.solo],
      cuisines: [Cuisine.noodles],
    );
    final english = suggestionsFor(taste).map((s) => s.$2).toList();
    expect(english.first, "Recommend places I'd like");
    expect(english, contains('Noodle places for eating solo'));
    expect(english, contains('Cozy noodle places'));

    setL10nLocale(const Locale('ja'));
    expect(suggestionsFor(taste).map((s) => s.$2), contains('雰囲気のいい麺のお店'));
    setL10nLocale(const Locale('zh'));
    expect(suggestionsFor(taste).map((s) => s.$2), contains('氛围好的面馆'));
    setL10nLocale(const Locale('ko'));
    expect(suggestionsFor(taste).map((s) => s.$2), contains('분위기 좋은 국수집'));
  });

  for (final (locale, title) in [
    (const Locale('en'), 'Food search made for you'),
    (const Locale('ja'), 'あなた好みのグルメ検索'),
    (const Locale('zh'), '专属美食搜索'),
    (
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      '專屬美食搜尋',
    ),
  ]) {
    testWidgets('the search page renders in $locale', (tester) async {
      setL10nLocale(locale);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: pindLocales,
          home: AgentSearchPage(search: (_) => throw UnimplementedError()),
        ),
      );
      expect(find.text(title), findsOneWidget);
      expect(find.textContaining(RegExp('[가-힣]')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
