import 'package:flutter/material.dart';

import '../../model/place_context.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';
import '../../model/profile_model.dart';
import '../../services/location_service.dart';
import '../components/pind_back_header.dart';
import '../components/pind_glass.dart';
import '../theme.dart';
import 'profile_screen.dart';

/// `2일 전 저장`: under an hour is 방금, then hours, days, weeks, months, years.
String savedAgo(DateTime at, DateTime now) {
  final d = now.difference(at);
  final ago = switch (d.inDays) {
    >= 365 => '${d.inDays ~/ 365}년 전',
    >= 30 => '${d.inDays ~/ 30}개월 전',
    >= 7 => '${d.inDays ~/ 7}주 전',
    >= 1 => '${d.inDays}일 전',
    _ when d.inHours >= 1 => '${d.inHours}시간 전',
    _ => '방금',
  };
  return '$ago 저장';
}

/// Highest [score] first; unscored places last; ties keep saved order.
List<ProfilePlaceCard> rankSaved(
  List<ProfilePlaceCard> cards,
  num? Function(ProfilePlaceCard) score,
) {
  final rows = [for (var i = 0; i < cards.length; i++) (i, score(cards[i]))];
  rows.sort(
    (a, b) => switch ((a.$2, b.$2)) {
      (final x?, final y?) when x != y => y.compareTo(x),
      (null, _?) => 1,
      (_?, null) => -1,
      _ => a.$1 - b.$1,
    },
  );
  return [for (final (i, _) in rows) cards[i]];
}

/// Behind 저장한 장소 `더보기 ›`: every save, sortable by recency, my taste,
/// or one of my priority criteria.
class SavedPlacesPage extends StatefulWidget {
  const SavedPlacesPage({
    super.key,
    required this.cards,
    required this.total,
    this.preferences,
    this.onOpen,
    this.onSetSaved,
    this.position = LocationService.position,
  });

  /// Newest save first, as the server sends them.
  final List<ProfilePlaceCard> cards;
  final int total;
  final TastePreferences? preferences;
  final ValueChanged<ProfilePlaceCard>? onOpen;

  /// Bookmark toggle; null hides it (someone else's saves).
  final Future<void> Function(ProfilePlaceCard card, bool saved)? onSetSaved;

  /// Current location for the distance line. Never prompts: no permission
  /// (or an error) just leaves the distance out.
  final Future<MapViewport?> Function(bool request) position;

  @override
  State<SavedPlacesPage> createState() => _SavedPlacesPageState();
}

class _SavedPlacesPageState extends State<SavedPlacesPage> {
  String sort = '최근 저장순';

  /// null = 최근 저장순 (server order).
  num? Function(ProfilePlaceCard)? score;
  final unsaved = <int>{};
  MapViewport? here;

  @override
  void initState() {
    super.initState();
    widget.position(false).then((p) {
      if (mounted && p != null) setState(() => here = p);
    }, onError: (_) {});
  }

  bool get hasTaste => widget.preferences?.priorities.length == 3;

  List<PreferenceCriterion> get criteria => hasTaste
      ? widget.preferences!.priorities
      : const [
          PreferenceCriterion.taste,
          PreferenceCriterion.portion,
          PreferenceCriterion.ambience,
        ];

  int? match(ProfilePlaceCard card) =>
      tasteMatch(widget.preferences, PlaceContext(averages: card.averages));

  Future<void> toggle(ProfilePlaceCard card) async {
    final id = card.place.id!, save = unsaved.contains(id);
    void apply(bool saved) =>
        setState(() => saved ? unsaved.remove(id) : unsaved.add(id));
    apply(save);
    try {
      await widget.onSetSaved!(card, save);
    } catch (_) {
      if (!mounted) return;
      apply(!save);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 상태를 바꾸지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorts = <(String, num? Function(ProfilePlaceCard)?)>[
      ('최근 저장순', null),
      if (hasTaste) ('내 취향순', match),
      for (final c in criteria) (c.label, (card) => card.averages[c]),
    ];
    final cards = score == null
        ? widget.cards
        : rankSaved(widget.cards, score!);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
          children: [
            Row(
              children: [
                const Expanded(child: PindBackHeader('저장한 장소')),
                Text(
                  '${widget.total}곳',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PindTheme.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 6,
                children: [
                  for (final (label, by) in sorts)
                    chip(
                      label,
                      () => setState(() {
                        sort = label;
                        score = by;
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (cards.isEmpty) mutedNote('저장한 장소가 아직 없어요.'),
            for (final card in cards)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SavedRow(
                  card: card,
                  match: match(card),
                  meters: here == null
                      ? null
                      : LocationService.distance(here!, card.place),
                  criteria: criteria,
                  saved: !unsaved.contains(card.place.id),
                  onTap: widget.onOpen == null
                      ? null
                      : () => widget.onOpen!(card),
                  onToggle: widget.onSetSaved == null || card.place.id == null
                      ? null
                      : () => toggle(card),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget chip(String label, VoidCallback onTap) {
    final on = sort == label;
    return Semantics(
      button: true,
      selected: on,
      child: PindGlass(
        tone: on ? PindGlassTone.purple : PindGlassTone.light,
        radius: 16,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : PindTheme.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedRow extends StatelessWidget {
  const _SavedRow({
    required this.card,
    required this.match,
    this.meters,
    required this.criteria,
    required this.saved,
    this.onTap,
    this.onToggle,
  });
  final ProfilePlaceCard card;
  final int? match;
  final double? meters;
  final List<PreferenceCriterion> criteria;
  final bool saved;
  final VoidCallback? onTap, onToggle;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: PindGlass(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          Container(
            width: 84,
            height: 84,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: placeImage(card.imageUrl),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  card.place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: PindTheme.ink,
                  ),
                ),
                Text(
                  [
                    placeArea(card.place.address),
                    if (meters != null) formatDistance(meters!),
                    '리뷰 ${card.reviewCount}',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12, color: PindTheme.muted),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (match != null)
                      PindGlass(
                        tone: PindGlassTone.purple,
                        radius: 11,
                        padding: const EdgeInsets.fromLTRB(6, 3, 7, 3),
                        child: Text(
                          '$match%',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    for (final c in criteria)
                      if (card.averages[c] case final avg?) rating(c, avg),
                  ],
                ),
                if (card.savedAt case final at?)
                  Row(
                    spacing: 7,
                    children: [
                      if (card.savers.isNotEmpty)
                        SizedBox(
                          width: 16 + (card.savers.length - 1) * 10,
                          height: 16,
                          child: Stack(
                            children: [
                              for (var i = 0; i < card.savers.length; i++)
                                Positioned(
                                  left: i * 10,
                                  child: ProfileAvatar(card.savers[i], 16),
                                ),
                            ],
                          ),
                        ),
                      Text(
                        savedAgo(at, DateTime.now()),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: profileBody,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (onToggle != null)
            Semantics(
              button: true,
              selected: saved,
              label: saved ? '저장 취소' : '저장',
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: saved
                        ? PindTheme.purple.withValues(alpha: .12)
                        : Colors.white,
                    border: Border.all(
                      color: saved
                          ? PindTheme.purple.withValues(alpha: .4)
                          : PindTheme.border,
                    ),
                  ),
                  child: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    size: 16,
                    color: saved ? PindTheme.purple : PindTheme.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget rating(PreferenceCriterion c, double avg) {
    final color = criterionColor(c);
    return Semantics(
      label: '${c.label} ${avg.round()}점',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 4, 7, 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          border: Border.all(color: color.withValues(alpha: .22)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text.rich(
          TextSpan(
            text: '${c.emoji} ',
            children: [
              TextSpan(
                text: '★ ${avg.round()}',
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 10.5, color: PindTheme.ink),
        ),
      ),
    );
  }
}
