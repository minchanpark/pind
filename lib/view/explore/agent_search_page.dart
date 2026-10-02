import 'package:flutter/material.dart';

import '../../model/nearby_ranking.dart';
import '../../model/place_context.dart';
import '../../model/place_search_result.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';
import '../../model/profile_model.dart';
import '../components/pind_glass.dart';
import '../profile/profile_screen.dart';
import '../profile/saved_places_page.dart';
import '../theme.dart';

/// Figma 617:23469 지도 검색. Answers in place, like a chat: the question,
/// progress lines while [search] runs, then a fold-down list of the places.
class AgentSearchPage extends StatefulWidget {
  const AgentSearchPage({
    super.key,
    required this.search,
    this.preferences,
    this.onOpen,
    this.onSetSaved,
    this.stepDelay = const Duration(milliseconds: 700),
  });
  final Future<AgentAnswer> Function(String query) search;
  final TastePreferences? preferences;

  /// A result card was tapped; [context] is this page's, so a sheet opened
  /// there returns to the results.
  final void Function(BuildContext context, Place place)? onOpen;

  /// Bookmark toggle; null hides it.
  final Future<void> Function(int placeId, bool saved)? onSetSaved;

  /// Between progress lines. Every line shows before the answer does.
  final Duration stepDelay;

  /// Progress lines while the server reads the sentence and searches.
  static const steps = [
    '입력한 문장을 분석하고 있어요',
    '게시물이 작성된 장소를 살펴보고 있어요',
    '당신의 취향에 맞는 장소를 검색하고 있어요',
  ];

  /// (emoji, prompt), row by row as in the design.
  static const suggestions = [
    ('🌶️', '매움 단계를 선택할 수 있는 식당'),
    ('🥩', '한국 BBQ를 즐기면서 분위기 좋은 고깃집'),
    ('🇳🇵', '네팔 사람들이 많이 방문한 식당'),
    ('🌿', 'Vegetarian 음식'),
    ('🍜', '한국식 베트남 음식'),
    ('🪑', '혼술 하기 좋은 식당'),
    ('🍜', '느낌 좋은 쌀국수집'),
    ('📍', '서울 성수동에 분위기 좋은 바'),
    ('🍚', '한국 집밥 느낌의 식당'),
    ('🔁', '관광객들이 가장 많이 방문한 식당'),
  ];

  @override
  State<AgentSearchPage> createState() => _AgentSearchPageState();
}

class _AgentSearchPageState extends State<AgentSearchPage> {
  final query = TextEditingController();
  final scroll = ScrollController();

  /// The question being answered; null before the first one.
  String? asked;
  int shownSteps = 0;
  AgentAnswer? answer;
  String? failure;
  bool open = true;

  /// Bookmark changes made here, by place id.
  final saved = <int, bool>{};

  bool get busy => asked != null && answer == null && failure == null;

  List<PreferenceCriterion> get criteria =>
      widget.preferences?.priorities.length == 3
      ? widget.preferences!.priorities
      : const [
          PreferenceCriterion.taste,
          PreferenceCriterion.portion,
          PreferenceCriterion.ambience,
        ];

  @override
  void dispose() {
    query.dispose();
    scroll.dispose();
    super.dispose();
  }

  /// One question at a time; a new one replaces the last answer.
  Future<void> submit(String text) async {
    final q = text.trim();
    if (q.isEmpty || busy) return;
    FocusScope.of(context).unfocus();
    query.clear();
    setState(() {
      asked = q;
      shownSteps = 1;
      answer = null;
      failure = null;
      open = true;
      saved.clear();
    });
    follow();
    Future<void> narrate() async {
      for (var i = 2; i <= AgentSearchPage.steps.length; i++) {
        await Future<void>.delayed(widget.stepDelay);
        if (!mounted) return;
        setState(() => shownSteps = i);
        follow();
      }
    }

    try {
      final done = await Future.wait<Object?>([widget.search(q), narrate()]);
      if (mounted) setState(() => answer = done.first as AgentAnswer);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => failure = error is PlaceFailure
            ? error.message
            : '검색하지 못했어요. 잠시 후 다시 시도해 주세요.',
      );
    }
    follow();
  }

  /// Keeps the newest chat line in view.
  void follow() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!scroll.hasClients) return;
    scroll.animateTo(
      scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  });

  Future<void> toggleSave(RankedPlace p) async {
    final id = p.place.id!, save = !(saved[id] ?? p.saved);
    setState(() => saved[id] = save);
    try {
      await widget.onSetSaved!(id, save);
    } catch (_) {
      if (!mounted) return;
      setState(() => saved[id] = !save);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 상태를 바꾸지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F5FA),
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: const PindGlass(
                    radius: 17.4,
                    child: SizedBox.square(
                      dimension: 32.8,
                      child: Icon(Icons.close, size: 16, color: PindTheme.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(22.5, 18, 22.5, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  '개인 맞춤형 음식 검색',
                  style: TextStyle(
                    fontSize: 28,
                    height: 36 / 28,
                    fontWeight: FontWeight.w700,
                    color: PindTheme.ink,
                  ),
                ),
                Text(
                  '원하는 취향을 자세히 알려주면 추천 내용이 더 정확해집니다.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    color: Color(0xFF9A9AA2),
                  ),
                ),
              ],
            ),
          ),
          // The page stays as it was; the chat continues beneath it.
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(18.4, 20.5, 18.4, 16),
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 9.2,
                    crossAxisSpacing: 9.2,
                    mainAxisExtent: 59,
                  ),
                  itemCount: AgentSearchPage.suggestions.length,
                  itemBuilder: (_, i) {
                    final (emoji, text) = AgentSearchPage.suggestions[i];
                    return suggestion(emoji, text);
                  },
                ),
                if (asked case final q?) ...chat(q),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18.4, 16.4, 18.4, 12),
            child: input(),
          ),
        ],
      ),
    ),
  );

  List<Widget> chat(String q) => [
    const SizedBox(height: 24),
    Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: PindTheme.purple,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          q,
          style: const TextStyle(fontSize: 13, color: Colors.white),
        ),
      ),
    ),
    const SizedBox(height: 12),
    for (var i = 0; i < shownSteps; i++)
      agentLine(AgentSearchPage.steps[i], working: busy && i == shownSteps - 1),
    if (failure case final message?)
      agentLine(message, icon: Icons.error_outline),
    if (answer case final a?) ...[
      if (a.notice case final notice?) agentLine(notice),
      const SizedBox(height: 4),
      results(a.places),
    ],
  ];

  /// One agent chat line: a spinner while [working], else [icon].
  Widget agentLine(
    String text, {
    bool working = false,
    IconData icon = Icons.check_circle_rounded,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: PindGlass(
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SizedBox.square(
              dimension: 14,
              child: working
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PindTheme.purple,
                    )
                  : Icon(icon, size: 14, color: PindTheme.purple),
            ),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: PindTheme.ink),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// The fold-down bar and, while open, the place cards under it.
  Widget results(List<RankedPlace> places) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        button: true,
        expanded: open,
        child: GestureDetector(
          key: const ValueKey('agent-results-toggle'),
          onTap: () => setState(() => open = !open),
          child: PindGlass(
            radius: 16,
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '추천 장소 ${places.length}곳',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PindTheme.ink,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: open ? .5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: PindTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: !open
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: 12),
                child: places.isEmpty
                    ? mutedNote('게시물이 있는 장소 중에 맞는 곳을 찾지 못했어요. 다르게 말해 볼까요?')
                    : Column(
                        spacing: 12,
                        children: [for (final p in places) card(p)],
                      ),
              ),
      ),
    ],
  );

  /// 저장한 장소's card, minus when it was saved.
  Widget card(RankedPlace p) {
    final id = p.place.id;
    return SavedPlaceRow(
      card: ProfilePlaceCard(
        place: p.place,
        imageUrl: p.imageUrl,
        averages: p.averages,
        reviewCount: p.reviewCount,
      ),
      match: tasteMatch(widget.preferences, PlaceContext(averages: p.averages)),
      meters: p.meters,
      criteria: criteria,
      saved: id == null ? p.saved : saved[id] ?? p.saved,
      onTap: widget.onOpen == null
          ? null
          : () => widget.onOpen!(context, p.place),
      onToggle: widget.onSetSaved == null || id == null
          ? null
          : () => toggleSave(p),
    );
  }

  Widget suggestion(String emoji, String text) => Semantics(
    button: true,
    child: PindGlass(
      radius: 14.3,
      child: InkWell(
        onTap: () => submit(text),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13.3),
          child: Row(
            spacing: 9.2,
            children: [
              ExcludeSemantics(
                child: Text(emoji, style: const TextStyle(fontSize: 18.4)),
              ),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.8,
                    height: 17.3 / 12.8,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget input() => PindGlass(
    radius: 31,
    padding: const EdgeInsets.fromLTRB(20.5, 10.2, 10.2, 10.2),
    child: Row(
      spacing: 10.2,
      children: [
        Expanded(
          child: TextField(
            controller: query,
            onChanged: (_) => setState(() {}),
            onSubmitted: submit,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14, color: PindTheme.ink),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '무엇이든 물어보세요...',
              hintStyle: TextStyle(fontSize: 14, color: Color(0x73000000)),
            ),
          ),
        ),
        // Mic until there is text to send; voice input is not built yet.
        Semantics(
          button: true,
          label: query.text.trim().isEmpty ? '음성 검색' : '검색',
          child: GestureDetector(
            onTap: () => query.text.trim().isEmpty
                ? ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('음성 검색은 준비 중이에요.')),
                  )
                : submit(query.text),
            child: PindGlass(
              tone: PindGlassTone.purple,
              radius: 19.4,
              child: SizedBox.square(
                dimension: 36.9,
                child: Icon(
                  query.text.trim().isEmpty
                      ? Icons.mic_none_rounded
                      : Icons.arrow_upward_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
