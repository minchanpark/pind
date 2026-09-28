import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';
import '../../model/preferences.dart';
import '../../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.initial,
    required this.onComplete,
    this.onCancel,
  });
  final TastePreferences? initial;
  final Future<void> Function(TastePreferences) onComplete;
  final VoidCallback? onCancel;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final controller = OnboardingController(
    initial: widget.initial,
    onComplete: widget.onComplete,
  );
  TastePreferences get preferences => controller.model.preferences;
  int get step => controller.model.step;
  bool get saving => controller.model.saving;
  String? get error => controller.model.error;
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.model.addListener(changed);
  }

  void changed() => setState(() {});

  @override
  void dispose() {
    controller.model.removeListener(changed);
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void move(int value) {
    controller.move(value);
    if (scrollController.hasClients) scrollController.jumpTo(0);
  }

  Future<void> next() async {
    final before = step;
    await controller.next();
    if (mounted && step != before && scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = controller.model.canContinue;
    final titles = ['가게 고를 때\n뭘 제일 봐요?', '외식 선호도를 선택해주세요.', '좋아하는걸 선택해주세요.'];
    final subtitles = [
      '딱 3개만. 순서대로 50% · 30% · 20%를 반영해요.',
      '최대 3개. 상황에 맞는 리스트를 만들어 드려요.',
      '3개 이상 골라주세요. 고를수록 추천이 정확해집니다.',
    ];
    final summary = step == 0
        ? (preferences.priorities.isEmpty
              ? '중요한 기준 3개를 골라주세요.'
              : '${preferences.priorities.map((p) => p.label).join(' › ')} 순으로 반영됩니다')
        : '${step == 1 ? preferences.occasions.length : preferences.cuisines.length}개 선택됨';
    return PopScope(
      canPop: step == 0 && !saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && step > 0 && !saving) move(step - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 24, 8),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '이전',
                          onPressed: saving
                              ? null
                              : step > 0
                              ? () => move(step - 1)
                              : widget.onCancel,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Semantics(
                            label: '취향 설정 ${step + 2} / 4 단계',
                            child: Row(
                              children: [
                                for (var i = 0; i < 4; i++)
                                  Expanded(
                                    child: Container(
                                      height: 4,
                                      margin: EdgeInsets.only(
                                        right: i == 3 ? 0 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: i <= step + 1
                                            ? PindTheme.purple
                                            : PindTheme.border,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${step + 2}/4',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: PindTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Text(
                            titles[step],
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            subtitles[step],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final scale =
                                  MediaQuery.textScalerOf(context).scale(14) /
                                  14;
                              final single =
                                  constraints.maxWidth < 300 || scale > 1.5;
                              final width = single
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 10) / 2;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (step == 0)
                                    for (final value
                                        in PreferenceCriterion.values)
                                      SizedBox(
                                        width: width,
                                        child: SelectionCard(
                                          label: value.label,
                                          description: value.description,
                                          selected: preferences.priorities
                                              .contains(value),
                                          rank:
                                              preferences.priorities.contains(
                                                value,
                                              )
                                              ? preferences.priorities.indexOf(
                                                      value,
                                                    ) +
                                                    1
                                              : null,
                                          onTap: () =>
                                              controller.togglePriority(value),
                                        ),
                                      ),
                                  if (step == 1)
                                    for (final value in DiningOccasion.values)
                                      SizedBox(
                                        width: width,
                                        child: SelectionCard(
                                          label: value.label,
                                          description: value.description,
                                          selected: preferences.occasions
                                              .contains(value),
                                          onTap: () =>
                                              controller.toggleOccasion(value),
                                        ),
                                      ),
                                  if (step == 2)
                                    for (final value in Cuisine.values)
                                      SizedBox(
                                        width: width,
                                        child: PhotoChoice(
                                          cuisine: value,
                                          selected: preferences.cuisines
                                              .contains(value),
                                          onTap: () =>
                                              controller.toggleCuisine(value),
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                    child: Column(
                      children: [
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            summary,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: PindTheme.muted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: canContinue && !saving ? next : null,
                          child: Text(
                            saving
                                ? '저장 중…'
                                : step == 2
                                ? '내 취향 지도 만들기'
                                : '다음',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    this.rank,
  });
  final String label, description;
  final bool selected;
  final int? rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label, $description${rank == null ? '' : ', $rank순위'}',
    child: Material(
      color: selected ? PindTheme.selected : PindTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? PindTheme.ink : PindTheme.border,
              width: rank == 1 ? 2 : 1,
            ),
          ),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rank != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: PindTheme.ink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$rank순위',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? PindTheme.ink : PindTheme.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PhotoChoice extends StatelessWidget {
  const PhotoChoice({
    super.key,
    required this.cuisine,
    required this.selected,
    required this.onTap,
  });
  final Cuisine cuisine;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: cuisine.label,
    child: Material(
      color: PindTheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: MediaQuery.textScalerOf(context).scale(84).clamp(84, 148),
          child: ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cuisine.asset != null)
                  Image.asset(
                    'assets/figma/${cuisine.asset}',
                    fit: BoxFit.cover,
                  ),
                if (cuisine.asset != null)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x55000000)],
                      ),
                    ),
                  ),
                if (selected)
                  Positioned(
                    right: 10,
                    top: 8,
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.asset('assets/figma/808cb.svg'),
                          const Text(
                            '✓',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  right: 8,
                  child: Text(
                    cuisine.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cuisine.asset == null
                          ? PindTheme.ink
                          : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
