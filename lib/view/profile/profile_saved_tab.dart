import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../model/place_context.dart';
import '../../model/preferences.dart';
import '../../model/profile_model.dart';
import '../components/pind_glass.dart';
import '../design_system.dart';
import 'profile_screen.dart';
import 'saved_places_page.dart';

class ProfileSavedTab extends StatelessWidget {
  const ProfileSavedTab({
    super.key,
    required this.overview,
    this.mine = true,
    this.preferences,
    this.onOpen,
    this.onSetSaved,
  });
  final ProfileOverview overview;

  /// False on someone else's page: their recent views are private, and only
  /// saves they share with followers come back.
  final bool mine;
  final TastePreferences? preferences;
  final ValueChanged<ProfilePlaceCard>? onOpen;
  final Future<void> Function(ProfilePlaceCard card, bool saved)? onSetSaved;

  @override
  Widget build(BuildContext context) {
    final recent = overview.recentViews, saved = overview.savedPlaces;
    return Padding(
      padding: profileInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 22,
        children: [
          if (mine)
            profileSection(
              '최근에 본 장소',
              recent.isEmpty
                  ? mutedNote('최근 24시간 안에 본 장소가 여기에 표시돼요.')
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Expanded(
                            child: i < recent.length
                                ? RecentPlaceCard(recent[i], onTap: onOpen)
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
              trailing: '더보기 ›',
              onTrailing: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfilePlacesPage(
                    title: '최근에 본 장소',
                    cards: recent,
                    onOpen: onOpen,
                  ),
                ),
              ),
            ),
          profileSection(
            '저장한 장소',
            saved.isEmpty
                ? mutedNote(mine ? '저장한 장소가 아직 없어요.' : '공유한 저장 장소가 없어요.')
                : SizedBox(
                    height: 120 + MediaQuery.textScalerOf(context).scale(80),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: saved.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      // Cards hug their content instead of stretching.
                      itemBuilder: (_, i) => Align(
                        alignment: Alignment.topCenter,
                        child: _SavedCard(saved[i], preferences, onOpen),
                      ),
                    ),
                  ),
            trailing: '더보기 ›',
            onTrailing: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SavedPlacesPage(
                  cards: saved,
                  total: overview.counts.saved,
                  preferences: preferences,
                  onOpen: onOpen,
                  onSetSaved: onSetSaved,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentPlaceCard extends StatelessWidget {
  const RecentPlaceCard(this.card, {super.key, this.onTap});
  final ProfilePlaceCard card;
  final ValueChanged<ProfilePlaceCard>? onTap;

  /// 117×100 on the 402pt design phone; scales with the column width.
  static const imageAspect = 117 / 100;

  /// Stops growing past the widest phone (430pt), so tablets keep phone-sized
  /// images instead of stretching to the column.
  static const maxImageWidth = 117 * 430 / 402;

  @override
  Widget build(BuildContext context) {
    final image = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: placeImage(card.imageUrl),
    );
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed box: without a width the network image's own size set the
          // card width, so every card came out a different size.
          LayoutBuilder(
            builder: (_, bounds) {
              final width = math.min(bounds.maxWidth, maxImageWidth);
              return SizedBox(
                width: width,
                height: width / imageAspect,
                child: image,
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            '📍 ${placeArea(card.place.address)}',
            style: const TextStyle(fontSize: PindType.micro, color: PindColors.muted),
          ),
          Text(
            card.place.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: PindType.label,
              fontWeight: FontWeight.w700,
              color: PindColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCard extends StatelessWidget {
  const _SavedCard(this.card, this.preferences, this.onTap);
  final ProfilePlaceCard card;
  final TastePreferences? preferences;
  final ValueChanged<ProfilePlaceCard>? onTap;

  @override
  Widget build(BuildContext context) {
    final match = tasteMatch(
      preferences,
      PlaceContext(averages: card.averages),
    );
    final criteria = preferences?.priorities ?? card.averages.keys.take(3);
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(card),
      child: SizedBox(
        width: 150,
        child: PindGlass(
          radius: 18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
                width: double.infinity,
                child: placeImage(card.imageUrl),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      '📍 ${placeArea(card.place.address)}',
                      style: const TextStyle(
                        fontSize: PindType.micro,
                        color: PindColors.muted,
                      ),
                    ),
                    Text(
                      card.place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: PindType.label,
                        fontWeight: FontWeight.w700,
                        color: PindColors.ink,
                      ),
                    ),
                    // One line always: shrinks rather than wraps on large text.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        spacing: 5,
                        children: [
                          if (match != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: PindColors.purple.withValues(alpha: .7),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                '$match%',
                                style: const TextStyle(
                                  fontSize: PindType.tiny,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          for (final c in criteria)
                            if (card.averages[c] case final avg?)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 1,
                                children: [
                                  Text(
                                    c.emoji,
                                    style: const TextStyle(fontSize: 8),
                                  ),
                                  Text(
                                    avg.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: PindType.tiny,
                                      fontWeight: FontWeight.w700,
                                      color: criterionColor(c),
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full list behind `더보기 ›`: the same cards in a 3-column grid.
class ProfilePlacesPage extends StatelessWidget {
  const ProfilePlacesPage({
    super.key,
    required this.title,
    required this.cards,
    this.onOpen,
  });
  final String title;
  final List<ProfilePlaceCard> cards;
  final ValueChanged<ProfilePlaceCard>? onOpen;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: cards.isEmpty
        ? Center(child: mutedNote('표시할 장소가 없어요.'))
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 16,
              mainAxisExtent: 150,
            ),
            itemCount: cards.length,
            itemBuilder: (_, i) => RecentPlaceCard(cards[i], onTap: onOpen),
          ),
  );
}
