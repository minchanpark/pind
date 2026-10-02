import 'package:flutter/material.dart';

import '../../model/nearby_ranking.dart';
import '../../model/place_context.dart';
import '../../model/place_search_result.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';
import '../../model/profile_model.dart';
import '../../model/search_suggestions.dart';
import '../components/pind_glass.dart';
import '../profile/profile_screen.dart';
import '../profile/saved_places_page.dart';
import '../design_system.dart';

/// One question and its answer on the search page.
class AgentTurn {
  AgentTurn(this.question, this.result);
  final String question;

  final Future<AgentAnswer> result;
  AgentAnswer? answer;
  String? failure;

  /// Progress lines shown so far.
  int steps = 1;
  bool open = true;
  bool get done => answer != null || failure != null;
}

/// Figma 617:23469 지도 검색. Answers in place, like a chat: each question,
/// progress lines while [search] runs, then a fold-down list of the places.
/// Earlier questions stay above the newest until the page closes.
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

  @override
  State<AgentSearchPage> createState() => _AgentSearchPageState();
}

class _AgentSearchPageState extends State<AgentSearchPage> {
  final query = TextEditingController();
  final scroll = ScrollController();

  final turns = <AgentTurn>[];

  /// Built from my taste once per visit.
  late final suggestions = suggestionsFor(widget.preferences);

  /// One question at a time.
  bool get busy => turns.isNotEmpty && !turns.last.done;

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

  /// Adds a turn below the earlier ones, folding their lists away.
  Future<void> submit(String text) async {
    final q = text.trim();
    if (q.isEmpty || busy) return;
    FocusScope.of(context).unfocus();
    query.clear();
    final turn = AgentTurn(q, widget.search(q));
    setState(() {
      for (final t in turns) {
        t.open = false;
      }
      turns.add(turn);
    });
    follow();
    Future<void> narrate() async {
      while (turn.steps < AgentSearchPage.steps.length) {
        await Future<void>.delayed(widget.stepDelay);
        turn.steps++;
        if (!mounted) return;
        setState(() {});
        follow();
      }
    }

    await Future.wait([settle(turn), narrate()]);
    if (!mounted) return;
    // Every line shows before the answer does.
    setState(() {});
    follow();
  }

  /// Records [turn]'s answer; shown once its last line is.
  Future<void> settle(AgentTurn turn) async {
    try {
      turn.answer = await turn.result;
    } catch (error) {
      turn.failure = error is PlaceFailure
          ? error.message
          : '검색하지 못했어요. 잠시 후 다시 시도해 주세요.';
    }
    if (mounted && turn.steps == AgentSearchPage.steps.length) {
      setState(() {});
      follow();
    }
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

  /// Marks [id] saved or not in every turn that lists it.
  void markSaved(int id, bool saved) => setState(() {
    for (final t in turns) {
      if (t.answer case final a?) {
        t.answer = (
          notice: a.notice,
          places: [
            for (final p in a.places)
              p.place.id == id && p.saved != saved
                  ? p.copyWith(
                      saved: saved,
                      saveCount: p.saveCount + (saved ? 1 : -1),
                    )
                  : p,
          ],
        );
      }
    }
  });

  Future<void> toggleSave(RankedPlace p) async {
    final id = p.place.id!, save = !p.saved;
    markSaved(id, save);
    try {
      await widget.onSetSaved!(id, save);
    } catch (_) {
      if (!mounted) return;
      markSaved(id, !save);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 상태를 바꾸지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PindColors.surface,
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
                      child: Icon(Icons.close, size: 16, color: PindColors.ink),
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
                    fontSize: PindType.display,
                    height: 36 / 28,
                    fontWeight: FontWeight.w700,
                    color: PindColors.ink,
                  ),
                ),
                Text(
                  '원하는 취향을 자세히 알려주면 추천 내용이 더 정확해집니다.',
                  style: TextStyle(
                    fontSize: PindType.bodySmall,
                    height: 20 / 13,
                    color: PindColors.subtle,
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
                  itemCount: suggestions.length,
                  itemBuilder: (_, i) {
                    final (emoji, text) = suggestions[i];
                    return suggestion(emoji, text);
                  },
                ),
                for (final t in turns) ...chat(t),
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

  List<Widget> chat(AgentTurn t) => [
    const SizedBox(height: 24),
    Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: PindColors.purple,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          t.question,
          style: const TextStyle(fontSize: PindType.bodySmall, color: Colors.white),
        ),
      ),
    ),
    const SizedBox(height: 12),
    for (var i = 0; i < t.steps; i++)
      agentLine(
        AgentSearchPage.steps[i],
        working:
            i == t.steps - 1 &&
            (!t.done || t.steps < AgentSearchPage.steps.length),
      ),
    // The answer waits for the last line.
    if (t.steps == AgentSearchPage.steps.length) ...[
      if (t.failure case final message?)
        agentLine(message, icon: Icons.error_outline),
      if (t.answer case final a?) ...[
        if (a.notice case final notice?) agentLine(notice),
        const SizedBox(height: 4),
        results(t, a.places),
      ],
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
                      color: PindColors.purple,
                    )
                  : Icon(icon, size: 14, color: PindColors.purple),
            ),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: PindType.bodySmall, color: PindColors.ink),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  /// The fold-down bar and, while open, the place cards under it.
  Widget results(AgentTurn t, List<RankedPlace> places) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Semantics(
        button: true,
        expanded: t.open,
        child: GestureDetector(
          key: ValueKey('agent-results-toggle-${turns.indexOf(t)}'),
          onTap: () => setState(() => t.open = !t.open),
          child: PindGlass(
            radius: 16,
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '추천 장소 ${places.length}곳',
                    style: const TextStyle(
                      fontSize: PindType.body,
                      fontWeight: FontWeight.w700,
                      color: PindColors.ink,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: t.open ? .5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: PindColors.muted,
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
        child: !t.open
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
      saved: p.saved,
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
                    color: PindColors.ink,
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
            style: const TextStyle(fontSize: PindType.body, color: PindColors.ink),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '무엇이든 물어보세요...',
              hintStyle: TextStyle(fontSize: PindType.body, color: Color(0x73000000)),
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
