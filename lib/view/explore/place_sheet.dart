import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design_system.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';
import '../../model/place_context.dart';
import '../../controllers/place_detail_controller.dart';
import '../components/pind_skeleton.dart';
import '../components/post_card.dart';
import 'post_photo_viewer.dart';
import '../../l10n/l10n.dart';

/// Flutter rendering of Figma glass, not an iOS-only native control.
class DetailGlass extends StatelessWidget {
  const DetailGlass({
    super.key,
    required this.child,
    this.radius = 28,
    this.purple = false,
    this.topOnly = false,
  });
  final Widget child;
  final double radius;
  final bool purple, topOnly;
  @override
  Widget build(BuildContext context) {
    final border = topOnly
        ? BorderRadius.vertical(top: Radius.circular(radius))
        : BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: border,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: border,
              border: Border.all(
                color: purple
                    ? const Color(0xB33A0088)
                    : const Color(0xF2FFFFFF),
              ),
              color: topOnly ? const Color(0x99FAFAFC) : null,
              gradient: topOnly
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: purple
                          ? [const Color(0xCCA05CEE), const Color(0xB36300DB)]
                          : [const Color(0xADFDFDFF), const Color(0x99FAFAFC)],
                    ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Opens [PlaceSheet] over the current route; resolves when it closes.
Future<void> showPlaceSheet(
  BuildContext context,
  PlaceDetailController detail,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: .04),
  builder: (_) => PlaceSheet(controller: detail),
);

class PlaceSheet extends StatefulWidget {
  const PlaceSheet({super.key, required this.controller});

  /// Each sheet owns and disposes its detail controller.
  final PlaceDetailController controller;
  @override
  State<PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<PlaceSheet> {
  final sheet = DraggableScrollableController();
  PlaceDetailController get controller => widget.controller;
  Place get place => controller.model.place;
  PlaceContext? get social => controller.model.social;
  bool get loading => controller.model.loading;
  bool get hasIntro => [
    place.insightSummary,
    place.summary,
  ].any((text) => text?.trim().isNotEmpty == true);
  bool get detailError => controller.model.detailError;
  bool get contextError => controller.model.contextError;
  bool get saving => controller.model.saving;
  bool get saved => controller.model.saved;
  bool get locating => controller.model.locating;
  double? get distance => controller.model.distance;
  int tab = 0;

  /// Sheet fraction that shows everything down to the "위로 올려서" hint (all
  /// of it for Kakao/Naver places, which have no tabs); measured after
  /// layout because the header grows as detail loads.
  double peek = .5;
  static const fullSize = .96;
  final topKey = GlobalKey(), footerKey = GlobalKey(), bodyKey = GlobalKey();

  /// 0 at the peek, 1 fully expanded; the hint fades and folds away with it.
  final expansion = ValueNotifier<double>(0);

  double height(GlobalKey key) =>
      (key.currentContext?.findRenderObject() as RenderBox?)?.size.height ?? 0;

  void measure(double available) {
    if (!mounted || available <= 0 || topKey.currentContext == null) return;
    // Measure only at rest at the peek: once raised, the hint is folded away
    // and the top is shorter than the peek it defines.
    final resting = !sheet.isAttached || (sheet.size - peek).abs() < .01;
    if (!resting) return;
    final pixels =
        height(topKey) +
        (place.hasRichContent ? 0 : height(bodyKey)) +
        height(footerKey);
    final next = (pixels / available).clamp(.2, fullSize - .06);
    if ((next - peek).abs() * available < 1) return;
    setState(() => peek = next);
    // After the rebuild applies the new min size; jumping first can land on
    // the old minimum, which closes the modal sheet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && sheet.isAttached) sheet.jumpTo(peek);
    });
  }

  bool onExtent(DraggableScrollableNotification n) {
    expansion.value = ((n.extent - peek) / (fullSize - peek)).clamp(0.0, 1.0);
    return false;
  }

  @override
  void initState() {
    super.initState();
    controller.model.addListener(changed);
    load();
    locate(false);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant PlaceSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.model.removeListener(changed);
      oldWidget.controller.dispose();
      controller.model.addListener(changed);
      load();
      locate(false);
    }
  }

  @override
  void dispose() {
    controller.model.removeListener(changed);
    controller.dispose();
    sheet.dispose();
    expansion.dispose();
    super.dispose();
  }

  Future<void> load() => controller.load();

  Future<void> locate(bool request) async {
    final error = await controller.locate(request);
    if (mounted && error != null) message(error);
  }

  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> link(String raw) async {
    final error = await controller.openLink(raw);
    if (mounted && error != null) message(error);
  }

  Future<void> save() async {
    HapticFeedback.lightImpact();
    final error = await controller.save();
    if (mounted && error != null) message(error);
  }

  Future<void> share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    final error = await controller.share(origin);
    if (mounted && error != null) message(error);
  }

  Widget asset(String name, double width) => SvgPicture.asset(
    'assets/place_detail/${name}_icon.svg',
    width: width,
    height: width,
  );

  /// Up to five photos gathered from the place's posts.
  List<PlacePhoto> get photos => !place.hasRichContent
      ? []
      : place.gallery.isNotEmpty
      ? place.gallery.take(5).toList()
      : place.imageUrl == null
      ? []
      : [PlacePhoto(place.imageUrl!, place.photoSourceUri, place.authors)];

  @override
  Widget build(BuildContext context) {
    // Built once per build so per-frame clip updates don't rebuild the tab body.
    final body = KeyedSubtree(key: bodyKey, child: description());
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => measure(constraints.maxHeight),
        );
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: onExtent,
          child: sheetBody(body),
        );
      },
    );
  }

  Widget sheetBody(Widget body) => DraggableScrollableSheet(
    controller: sheet,
    initialChildSize: peek,
    // Below the peek a fling closes the sheet.
    minChildSize: math.min(.4, peek - .05),
    maxChildSize: fullSize,
    expand: false,
    snap: true,
    snapSizes: [peek],
    builder: (context, scroll) => DetailGlass(
      topOnly: true,
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    key: topKey,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header(),
                      // Rich places show placeholders in the body instead.
                      if (loading && !place.hasRichContent)
                        const LinearProgressIndicator(minHeight: 2),
                      if (detailError) errorRow(l10n.errDetailLoad),
                      if (contextError) errorRow(l10n.errContextLoad),
                      if (place.hasRichContent) expandHint(),
                    ],
                  ),
                ),
                // Once the sheet is fully up, tabs stay put and only the tab body
                // scrolls. The body is clipped under the transparent tabs instead of
                // giving them a fill (a blur can't hide Flutter content over the iOS map).
                if (place.hasRichContent) PinnedHeaderSliver(child: tabs()),
                SliverLayoutBuilder(
                  builder: (_, constraints) => SliverToBoxAdapter(
                    child: ClipRect(
                      clipper: _ClipTop(
                        constraints.scrollOffset + constraints.overlap,
                      ),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
          KeyedSubtree(key: footerKey, child: footer()),
        ],
      ),
    ),
  );

  /// "위로 올려서" hint; folds away as the sheet is raised.
  Widget expandHint() => ValueListenableBuilder(
    valueListenable: expansion,
    builder: (_, t, child) => t == 1
        ? const SizedBox.shrink()
        : ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: 1 - t,
              child: Opacity(opacity: 1 - t, child: child),
            ),
          ),
    child: TextButton(
      key: const ValueKey('detail-expand'),
      onPressed: () => sheet.animateTo(
        fullSize,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      ),
      child: Text(
        l10n.detailSwipeHint,
        style: TextStyle(fontSize: PindType.caption, color: PindColors.muted),
      ),
    ),
  );

  Widget errorRow(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: const TextStyle(fontSize: PindType.label)),
        TextButton(onPressed: loading ? null : load, child: Text(l10n.retry)),
      ],
    ),
  );
  Widget header() {
    final hours = todayHours(place, DateTime.now());
    final status = place.isOpen == null
        ? l10n.hoursUnknown
        : place.isOpen!
        ? l10n.openNow
        : l10n.closedNow;
    final score = social == null
        ? null
        : tasteMatch(controller.preferences, social!);
    return Container(
      padding: const EdgeInsets.fromLTRB(16.493, 12, 16.493, 12.37),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x99FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 22.677,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: PindColors.ink,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.close,
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                icon: asset('close', 38),
              ),
            ],
          ),
          Wrap(
            spacing: 8.246,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: DetailGlass(
                  radius: 20,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Text(
                      '$status${hours == null ? '' : ' · $hours'}',
                      style: const TextStyle(
                        fontSize: PindType.caption,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: locating ? null : () => locate(true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    distance == null
                        ? (locating ? l10n.locating : l10n.checkDistance)
                        : formatDistance(distance!),
                    style: const TextStyle(
                      fontSize: PindType.caption,
                      color: PindColors.muted,
                    ),
                  ),
                ),
              ),
              Text(
                place.isCatalog
                    ? l10n.pindPostCount(place.pindPostCount ?? 0)
                    : place.reviewCount == null
                    ? l10n.reviewCountUnknown
                    : l10n.reviewCountLong(place.reviewCount!),
                style: const TextStyle(
                  fontSize: PindType.caption,
                  color: PindColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: asset('location', 13.3989),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  [place.address, ?place.nativeAddress].join('\n'),
                  style: const TextStyle(
                    fontSize: PindType.label,
                    color: PindColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Tooltip(
                message: l10n.tasteMatchHelp,
                child: DetailGlass(
                  radius: 16,
                  purple: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      score == null
                          ? l10n.tasteMatchUnrated
                          : l10n.tasteMatchMine(score),
                      key: const ValueKey('taste-match'),
                      style: const TextStyle(
                        fontSize: PindType.caption,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              for (
                var i = 0;
                i < (controller.preferences?.priorities.length ?? 0);
                i++
              )
                ratingChip(controller.preferences!.priorities[i], i),
            ],
          ),
          if (social?.visitors.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            friendLine(),
          ],
        ],
      ),
    );
  }

  static const axisColors = [
    PindColors.taste,
    PindColors.portion,
    PindColors.ambience,
  ];
  String average(PreferenceCriterion axis) {
    final value = social?.averages[axis];
    return value == null ? '—' : value.toStringAsFixed(1);
  }

  Widget ratingChip(PreferenceCriterion axis, int index) {
    final color = axisColors[index % 3], text = average(axis);
    return Tooltip(
      message: text == '—'
          ? l10n.axisNoRatingsDot(axis.label)
          : l10n.axisAverageDot(axis.label, text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          border: Border.all(color: color.withValues(alpha: .22)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Semantics(
          label: text == '—'
              ? l10n.axisNoRatings(axis.label)
              : l10n.axisAverage(axis.label, text),
          child: Text(
            '${axis.emoji} ★ $text',
            style: TextStyle(
              fontSize: PindType.caption,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget friendLine() {
    final visitors = social!.visitors;
    final names = visitors.take(2).map((f) => f.name).join(', ');
    return Row(
      key: const ValueKey('friend-visits'),
      children: [
        SizedBox(
          width: visitors.length > 1 ? 38 : 22,
          height: 24,
          child: Stack(
            children: [
              for (var i = 0; i < visitors.take(2).length; i++)
                Positioned(
                  left: i * 16.0,
                  child: Container(
                    width: 22,
                    height: 22,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white),
                    ),
                    child: visitors[i].avatar == null
                        ? const Icon(Icons.person, size: 18)
                        : placePhoto(visitors[i].avatar!, BoxFit.cover),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            [
              l10n.friendsVisitedPlace(
                names,
                visitors.length > 2 ? visitors.length - 2 : 0,
              ),
              if (social!.friendSaveCount > 0)
                l10n.followingSaved(social!.friendSaveCount),
            ].join(' · '),
            style: const TextStyle(
              fontSize: PindType.label,
              color: PindColors.body,
            ),
          ),
        ),
      ],
    );
  }

  Widget gallery(
    List<PlacePhoto> photos, [
    String key = 'detail-photo',
  ]) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < photos.length; index++)
            Padding(
              padding: EdgeInsets.only(
                right: index == photos.length - 1 ? 0 : 8,
              ),
              child: SizedBox(
                key: ValueKey('$key-$index'),
                width: index == 0 ? 140 : 210,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      label: l10n.placePhotoLabel(place.name, index + 1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: double.infinity,
                          height: 182,
                          child: placePhoto(photos[index].uri, BoxFit.cover),
                        ),
                      ),
                    ),
                    // Google requires photo credits; Pind post photos
                    // show their author in the posts tab instead.
                    if (place.isGoogle) ...[
                      for (final author in photos[index].authors)
                        photoCredit(l10n.photoBy(author.name), author.uri),
                      if (photos[index].sourceUri != null)
                        photoCredit(l10n.photoSource, photos[index].sourceUri),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget photoCredit(String label, String? uri) => Semantics(
    link: uri != null,
    child: InkWell(
      onTap: uri == null ? null : () => link(uri),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 3, 2, 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: PindType.tiny,
            height: 1.35,
            color: PindColors.muted,
          ),
        ),
      ),
    ),
  );

  Widget tabs() => Row(
    key: const ValueKey('detail-tabs'),
    children: [
      for (var i = 0; i < 2; i++)
        Expanded(
          child: Semantics(
            button: true,
            selected: tab == i,
            child: InkWell(
              key: ValueKey('detail-tab-$i'),
              onTap: () => setState(() => tab = i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      [l10n.intro, l10n.posts][i],
                      style: TextStyle(
                        fontSize: PindType.body,
                        height: 17 / 14,
                        fontWeight: tab == i
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: tab == i ? PindColors.ink : PindColors.subtle,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 3,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        key: ValueKey('detail-tab-line-$i'),
                        height: tab == i ? 3 : 1,
                        color: tab == i ? PindColors.ink : PindColors.chip,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  /// Figma 586:23828: author row, text, fanned photos and the author's ratings.
  Widget postCard(PlacePost post, int index) {
    // Posts don't store the author's priority order; Figma leads with 맛·양·분위기.
    const order = [
      PreferenceCriterion.taste,
      PreferenceCriterion.portion,
      PreferenceCriterion.ambience,
      PreferenceCriterion.value,
      PreferenceCriterion.service,
      PreferenceCriterion.photogenic,
      PreferenceCriterion.quiet,
      PreferenceCriterion.parking,
    ];
    final ratings = [
      for (final axis in order)
        if (post.ratings[axis.name] != null) (axis, post.ratings[axis.name]!),
    ];
    return Padding(
      key: ValueKey('detail-post-$index'),
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox.square(
                  dimension: 32,
                  child: post.avatar == null
                      ? const ColoredBox(
                          color: PindColors.chip,
                          child: Icon(Icons.person, size: 22),
                        )
                      : placePhoto(post.avatar!, BoxFit.cover),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  // Before a handle is set, the display name without '@'.
                  post.handle == null ? post.author : '@${post.handle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: PindType.body,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -.07,
                    color: Colors.black,
                  ),
                ),
              ),
              if (post.id != null && controller.setLiked != null)
                postActions(
                  likeHasCount: post.likeCount > 0,
                  delete: post.mine && controller.deletePost != null
                      ? PostDeleteButton(
                          onConfirmed: () async {
                            final error = await controller.delete(post);
                            if (mounted) message(error ?? l10n.postDeleted);
                          },
                        )
                      : null,
                  like: likeButton(post),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 39),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (post.body.trim().isNotEmpty)
                  Text(
                    post.body.trim(),
                    style: const TextStyle(
                      fontSize: PindType.label,
                      height: 16.869 / 12,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 12),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: ratings.isEmpty ? 0 : 15,
                      ),
                      child: postPhotos(post),
                    ),
                    if (ratings.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        child: Row(
                          children: [
                            for (var i = 0; i < ratings.length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              postRatingChip(ratings[i].$1, ratings[i].$2, i),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The feed's heart, same look and count.
  Widget likeButton(PlacePost post) => PostCardButton(
    label: post.liked ? l10n.unlike : l10n.like,
    selected: post.liked,
    leading: post.likeCount > 0
        ? Text(
            '${post.likeCount}',
            style: const TextStyle(
              fontSize: PindType.micro,
              color: PindColors.muted,
            ),
          )
        : null,
    icon: Icon(
      post.liked ? Icons.favorite : Icons.favorite_border,
      size: 12,
      color: post.liked ? PindColors.purple : null,
    ),
    onTap: (_) async {
      HapticFeedback.lightImpact();
      final error = await controller.toggleLike(post);
      if (mounted && error != null) message(error);
    },
  );

  Widget postPhotos(PlacePost post) {
    const yellow = PindColors.lime;
    if (post.photos.length < 2) {
      return post.photos.isEmpty
          ? const SizedBox(height: 30)
          : openable(
              post,
              0,
              Container(
                height: 217.32,
                foregroundDecoration: BoxDecoration(
                  border: Border.all(color: yellow, width: 5.21),
                  borderRadius: BorderRadius.circular(14.238),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.238),
                  child: SizedBox.expand(
                    child: placePhoto(post.photos.first, BoxFit.cover),
                  ),
                ),
              ),
            );
    }
    final extra = post.photos.length - 3;
    Widget card(
      int index,
      Color border, {
      int more = 0,
      double w = 109.01,
      double h = 164.912,
    }) => Container(
      width: w,
      height: h,
      foregroundDecoration: BoxDecoration(
        // As in PostCard: a pair gets 4, three or more 2.
        border: Border.all(
          color: border,
          width: post.photos.length == 2 ? 4 : 2,
        ),
        borderRadius: BorderRadius.circular(12.086),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.086),
        child: Stack(
          fit: StackFit.expand,
          children: [
            placePhoto(post.photos[index], BoxFit.cover),
            if (more > 0) ...[
              const ColoredBox(color: Color(0x33000000)),
              Center(
                child: Text(
                  '+ $more',
                  style: const TextStyle(
                    fontSize: PindType.titleLarge,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    // Offsets and tilts are measured from the Figma cards around the center one.
    Widget side(Widget child, double dx, double dy, double degrees) =>
        Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(angle: degrees * math.pi / 180, child: child),
        );
    const purple = PindColors.purple;
    if (post.photos.length == 2) {
      // A fanned pair, as in PostCard: the first photo in front.
      return SizedBox(
        width: double.infinity,
        height: 190,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            side(openable(post, 1, card(1, yellow, w: 126, h: 180)), 52, -4, 7),
            side(
              openable(post, 0, card(0, purple, w: 126, h: 180)),
              -52,
              2,
              -5,
            ),
          ],
        ),
      );
    }
    // Full width, so the fanned side cards stay inside the Stack and receive taps.
    return SizedBox(
      width: double.infinity,
      height: 179,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: const Alignment(0, 1),
        children: [
          if (post.photos.length > 2)
            side(openable(post, 2, card(2, yellow, more: extra)), 95, -8, 6.51),
          side(openable(post, 1, card(1, yellow)), -93, -7, -8.21),
          openable(post, 0, card(0, purple)),
        ],
      ),
    );
  }

  Widget openable(PlacePost post, int index, Widget child) => PostPhotoOpener(
    key: ValueKey('post-photo-${post.hashCode}-$index'),
    photos: post.photos,
    index: index,
    child: child,
  );

  Widget postRatingChip(PreferenceCriterion axis, int score, int index) {
    const borders = [Color(0x66E8336E), Color(0x66FF8A1F), Color(0x663563FF)];
    const colors = [PindColors.taste, PindColors.portion, PindColors.ambience];
    return Semantics(
      label: l10n.ratingScore(axis.label, score),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 10, 8),
        decoration: BoxDecoration(
          color: const Color(0xF0FFFFFF),
          border: Border.all(color: borders[index % 3]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${axis.emoji} ',
                style: const TextStyle(color: PindColors.ink),
              ),
              TextSpan(
                text: '★ $score',
                style: TextStyle(
                  color: colors[index % 3],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: PindType.micro),
        ),
      ),
    );
  }

  /// Store averages beside AI one-liners for the viewer's three priorities.
  Widget reviewSummary() {
    final axes = controller.preferences?.priorities.length == 3
        ? controller.preferences!.priorities
        : const [
            PreferenceCriterion.taste,
            PreferenceCriterion.portion,
            PreferenceCriterion.ambience,
          ];
    return Column(
      key: const ValueKey('detail-review-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.oneLineSummaryTitle(axes.map((a) => a.label).join(' · ')),
          style: const TextStyle(
            fontSize: PindType.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        DetailGlass(
          radius: 20,
          child: Column(
            children: [
              for (var i = 0; i < axes.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    indent: 14,
                    endIndent: 14,
                    color: Color(0x14000000),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        axes[i].emoji,
                        style: const TextStyle(fontSize: PindType.body),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${axes[i].label}  ★ ${average(axes[i])}',
                              style: TextStyle(
                                fontSize: PindType.label,
                                fontWeight: FontWeight.w700,
                                color: axisColors[i % 3],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              place.insightLines[axes[i].name] ??
                                  l10n.noOneLiners,
                              style: const TextStyle(
                                fontSize: PindType.caption,
                                color: PindColors.body,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget description() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (place.hasRichContent && tab == 0 && photos.isNotEmpty)
        gallery(photos, 'detail-intro-photo'),
      if (place.hasRichContent && tab == 1)
        for (final (i, post) in controller.model.posts.indexed)
          postCard(post, i),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.hasRichContent)
              if (tab == 0) ...[
                if (loading && !hasIntro)
                  PindSkeleton(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        bone(double.infinity, 12),
                        bone(double.infinity, 12),
                        bone(180, 12),
                      ],
                    ),
                  )
                else
                  Text(
                    [place.insightSummary, place.summary].firstWhere(
                          (text) => text?.trim().isNotEmpty == true,
                          orElse: () => null,
                        ) ??
                        l10n.noIntro,
                    key: const ValueKey('detail-intro'),
                    style: const TextStyle(
                      fontSize: PindType.label,
                      height: 1.5,
                      color: PindColors.muted,
                    ),
                  ),
                const SizedBox(height: 20),
                reviewSummary(),
              ] else if (controller.model.posts.isEmpty)
                loading ? postsSkeleton(count: 1) : Text(l10n.noPostsYet),
            // Google, Kakao and Naver terms require naming the source.
            if (!place.isCatalog) ...[
              const SizedBox(height: 12),
              Text(
                l10n.dataBy(place.sourceLabel),
                style: const TextStyle(
                  fontSize: PindType.label,
                  color: PindColors.muted,
                ),
              ),
            ],
            if (!place.hasRichContent)
              TextButton(
                onPressed: () => link(place.mapsUri),
                child: Text(place.sourceAction),
              ),
          ],
        ),
      ),
    ],
  );
  Widget footer() => Container(
    key: const ValueKey('detail-fixed-actions'),
    decoration: const BoxDecoration(
      color: Color(0x88E4E6EB),
      border: Border(top: BorderSide(color: Color(0xB3FFFFFF))),
    ),
    padding: const EdgeInsets.fromLTRB(16.493, 10, 16.493, 8),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          action(
            saved ? l10n.saved : l10n.save,
            saved ? 'saved' : 'save',
            13.4603,
            saving ? null : save,
            key: const ValueKey('detail-save'),
            selected: saved,
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (ctx) => action(
              l10n.share,
              'share',
              13.542,
              () => share(ctx),
              key: const ValueKey('detail-share'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: action(
              l10n.directions,
              'directions',
              15.4546,
              () {
                final walk = controller.directions;
                if (walk == null) {
                  link(directionsUri(place).toString());
                  return;
                }
                // Back to the shell, where the map draws the route.
                Navigator.of(context).popUntil((route) => route.isFirst);
                walk(place);
              },
              purple: true,
              key: const ValueKey('detail-directions'),
            ),
          ),
        ],
      ),
    ),
  );
  Widget action(
    String label,
    String icon,
    double size,
    VoidCallback? onTap, {
    Key? key,
    bool purple = false,
    bool selected = false,
  }) => Semantics(
    button: true,
    selected: selected,
    child: DetailGlass(
      radius: 30,
      purple: purple,
      child: TextButton(
        key: key,
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: purple ? Colors.white : Colors.black,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            asset(icon, size),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                // Saved reads at a glance: purple and bold, as bookmarks are
                // elsewhere in the app.
                style: TextStyle(
                  fontSize: 12.426,
                  fontWeight: selected ? FontWeight.w700 : null,
                  color: selected ? PindColors.purple : null,
                ),
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Hides the part of the tab body that has scrolled under the pinned tabs.
class _ClipTop extends CustomClipper<Rect> {
  const _ClipTop(this.top);
  final double top;
  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, top, size.width, size.height);
  @override
  bool shouldReclip(_ClipTop old) => old.top != top;
}
