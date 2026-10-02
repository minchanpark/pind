import 'package:flutter/material.dart';

import '../../model/nearby_ranking.dart';
import '../../model/place_context.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';
import '../components/pind_glass.dart';
import '../profile/profile_screen.dart';
import '../design_system.dart';
import 'explore_screen.dart';
import 'place_sheet.dart';

typedef NearbyLoad = Future<({List<RankedPlace> places, bool nearMe})>;

/// Figma 671:33852 (내 취향순) and 671:34142/34308/34474 (one criterion).
Future<void> showNearbyRanking(
  BuildContext context, {
  required String title,
  required NearbyLoad Function() load,
  required bool Function(Place) include,
  TastePreferences? preferences,
  required ValueChanged<Place> onOpen,
  Future<void> Function(int placeId, bool saved)? onSetSaved,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: .04),
  builder: (_) => NearbyRankingSheet(
    title: title,
    load: load,
    include: include,
    preferences: preferences,
    onOpen: onOpen,
    onSetSaved: onSetSaved,
  ),
);

class NearbyRankingSheet extends StatefulWidget {
  const NearbyRankingSheet({
    super.key,
    required this.title,
    required this.load,
    required this.include,
    this.preferences,
    required this.onOpen,
    this.onSetSaved,
  });
  final String title;
  final NearbyLoad Function() load;
  final bool Function(Place) include;
  final TastePreferences? preferences;

  /// Called after the sheet closes, with the tapped place.
  final ValueChanged<Place> onOpen;
  final Future<void> Function(int placeId, bool saved)? onSetSaved;

  @override
  State<NearbyRankingSheet> createState() => _NearbyRankingSheetState();
}

class _NearbyRankingSheetState extends State<NearbyRankingSheet> {
  List<RankedPlace>? places;
  bool nearMe = true, failed = false;

  /// null = 내 취향순.
  PreferenceCriterion? by;

  List<PreferenceCriterion> get criteria =>
      widget.preferences?.priorities.length == 3
      ? widget.preferences!.priorities
      : const [
          PreferenceCriterion.taste,
          PreferenceCriterion.portion,
          PreferenceCriterion.ambience,
        ];

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => failed = false);
    try {
      final result = await widget.load();
      if (!mounted) return;
      setState(() {
        places = [
          for (final p in result.places)
            if (widget.include(p.place)) p,
        ];
        nearMe = result.nearMe;
      });
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> toggleSave(RankedPlace p) async {
    final save = !p.saved, id = p.place.id!;
    void apply(bool saved) => setState(() {
      places = [
        for (final q in places!)
          if (q.place.id == id)
            q.copyWith(
              saved: saved,
              saveCount:
                  q.saveCount +
                  (saved == q.saved
                      ? 0
                      : saved
                      ? 1
                      : -1),
            )
          else
            q,
      ];
    });
    apply(save);
    try {
      await widget.onSetSaved!(id, save);
    } catch (_) {
      if (!mounted) return;
      apply(!save);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 상태를 바꾸지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .9,
    child: Stack(
      children: [
        Positioned.fill(
          child: DetailGlass(
            topOnly: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 13),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: PindColors.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: PindType.headline,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.48,
                      color: PindColors.ink,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Row(
                    spacing: 8,
                    children: [
                      sortChip(null),
                      for (final c in criteria) sortChip(c),
                    ],
                  ),
                ),
                if (!nearMe)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: mutedNote('현재 위치를 확인하지 못해 지도 중심 10km 기준이에요.'),
                  ),
                Expanded(child: body()),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
          child: Center(child: backToMap()),
        ),
      ],
    ),
  );

  Widget body() {
    final all = places;
    if (failed) {
      return Center(
        child: TextButton(onPressed: fetch, child: const Text('다시 시도')),
      );
    }
    if (all == null) return const Center(child: CircularProgressIndicator());
    if (all.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: mutedNote('10km 안에 게시물이 있는 곳이 아직 없어요.'),
      );
    }
    final ranked = rankPlaces(all, widget.preferences, by);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
      children: [
        PindGlass(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < ranked.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: PindColors.line,
                  ),
                row(ranked[i], i + 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget sortChip(PreferenceCriterion? c) {
    final on = by == c;
    final label = Text(
      c == null ? '내 취향순' : c.label,
      style: TextStyle(
        fontSize: PindType.label,
        fontWeight: FontWeight.w700,
        color: !on
            ? PindColors.muted
            : c == null
            ? Colors.white
            : criterionColor(c),
      ),
    );
    final color = c == null ? null : criterionColor(c);
    return Semantics(
      button: true,
      selected: on,
      child: PindGlass(
        tone: on && c == null ? PindGlassTone.purple : PindGlassTone.light,
        fillColor: on && color != null ? color.withValues(alpha: .12) : null,
        borderColor: on && color != null ? color.withValues(alpha: .4) : null,
        radius: 16,
        child: InkWell(
          onTap: () => setState(() => by = c),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: on && c != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 4,
                    children: [
                      Text(c.emoji, style: const TextStyle(fontSize: PindType.caption)),
                      label,
                    ],
                  )
                : label,
          ),
        ),
      ),
    );
  }

  Widget row(RankedPlace p, int rank) {
    final match = tasteMatch(
      widget.preferences,
      PlaceContext(averages: p.averages),
    );
    final shown = by == null ? criteria : [by!];
    return InkWell(
      onTap: () {
        Navigator.maybePop(context);
        widget.onOpen(p.place);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Container(
              width: 76,
              height: 76,
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PindColors.fill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: p.imageUrl == null
                  ? Text(
                      markerEmoji(p.place),
                      style: const TextStyle(fontSize: PindType.display),
                    )
                  : SizedBox.expand(child: placeImage(p.imageUrl)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: PindType.title,
                          fontWeight: FontWeight.w700,
                          color: by == null
                              ? PindColors.purple
                              : criterionColor(by!),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          p.place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: PindType.bodyLarge,
                            fontWeight: FontWeight.w700,
                            color: PindColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    [
                      if (p.place.category.isNotEmpty) p.place.category,
                      if (p.meters case final m?) formatDistance(m),
                      '리뷰 ${p.reviewCount}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: PindType.caption,
                      color: PindColors.muted,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      spacing: 4,
                      children: [
                        if (by == null && match != null) matchChip(match),
                        for (final c in shown)
                          if (p.averages[c] case final avg?) rating(c, avg),
                      ],
                    ),
                  ),
                  if (p.friendLine case final line?)
                    Row(
                      spacing: 7,
                      children: [
                        SizedBox(
                          width: 16 + (p.friendAvatars.length - 1) * 10,
                          height: 16,
                          child: Stack(
                            children: [
                              for (var i = 0; i < p.friendAvatars.length; i++)
                                Positioned(
                                  left: i * 10,
                                  child: ProfileAvatar(p.friendAvatars[i], 16),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: PindType.micro,
                              fontWeight: FontWeight.w500,
                              color: profileBody,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              spacing: 4,
              children: [
                Semantics(
                  button: true,
                  selected: p.saved,
                  label: p.saved ? '저장 취소' : '저장',
                  child: GestureDetector(
                    onTap: widget.onSetSaved == null || p.place.id == null
                        ? null
                        : () => toggleSave(p),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.saved
                            ? PindColors.purple.withValues(alpha: .12)
                            : Colors.white,
                        border: Border.all(
                          color: p.saved
                              ? PindColors.purple.withValues(alpha: .4)
                              : PindColors.border,
                        ),
                      ),
                      child: Icon(
                        p.saved ? Icons.bookmark : Icons.bookmark_border,
                        size: 16,
                        color: p.saved ? PindColors.purple : PindColors.ink,
                      ),
                    ),
                  ),
                ),
                Text(
                  thousands(p.saveCount),
                  style: const TextStyle(
                    fontSize: PindType.tiny,
                    fontWeight: FontWeight.w700,
                    color: PindColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget matchChip(int match) => PindGlass(
    tone: PindGlassTone.purple,
    radius: 11,
    padding: const EdgeInsets.fromLTRB(6, 3, 7, 3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        const Text(
          '취향',
          style: TextStyle(
            fontSize: PindType.tiny,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Text(
          '$match%',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget rating(PreferenceCriterion c, double avg) {
    final color = criterionColor(c);
    final value = avg == avg.roundToDouble()
        ? '${avg.round()}'
        : avg.toStringAsFixed(1);
    return Semantics(
      label: '${c.label} $value점',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 7, 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          border: Border.all(color: color.withValues(alpha: .22)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(c.emoji, style: const TextStyle(fontSize: 10.5)),
            Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget backToMap() => Semantics(
    button: true,
    child: GestureDetector(
      onTap: () => Navigator.maybePop(context),
      child: const PindGlass(
        tone: PindGlassTone.dark,
        radius: 26,
        padding: EdgeInsets.fromLTRB(22, 13, 24, 13),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(
              '▲',
              style: TextStyle(
                fontSize: PindType.label,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              '지도로 돌아가기',
              style: TextStyle(
                fontSize: PindType.body,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// `1412` → `1,412`.
String thousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
