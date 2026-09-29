import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';
import '../../model/place_context.dart';
import '../../controllers/place_detail_controller.dart';
import 'post_photo_viewer.dart';

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
  bool get detailError => controller.model.detailError;
  bool get contextError => controller.model.contextError;
  bool get saving => controller.model.saving;
  bool get saved => controller.model.saved;
  bool get locating => controller.model.locating;
  bool get searchingGoogle => controller.model.searchingGoogle;
  double? get distance => controller.model.distance;
  int tab = 0;

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
    'assets/figma/detail_$name.svg',
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
    final body = description();
    return DraggableScrollableSheet(
      controller: sheet,
      initialChildSize: .70,
      minChildSize: .4,
      maxChildSize: .96,
      expand: false,
      snap: true,
      snapSizes: const [.70],
      builder: (context, scroll) => DetailGlass(
        topOnly: true,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: scroll,
                slivers: [
                  SliverList.list(
                    children: [
                      header(),
                      if (loading) const LinearProgressIndicator(minHeight: 2),
                      if (detailError) errorRow('상세 정보를 불러오지 못했어요.'),
                      if (contextError) errorRow('취향·친구 정보를 불러오지 못했어요.'),
                      if (photos.isNotEmpty) gallery(photos),
                      TextButton(
                        key: const ValueKey('detail-expand'),
                        onPressed: () => sheet.animateTo(
                          .96,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        ),
                        child: const Text(
                          '⌃  위로 올려서 소개 · 게시물 보기',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7A7A80),
                          ),
                        ),
                      ),
                    ],
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
            footer(),
          ],
        ),
      ),
    );
  }

  Widget errorRow(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text, style: const TextStyle(fontSize: 12)),
        TextButton(
          onPressed: loading ? null : load,
          child: const Text('다시 시도'),
        ),
      ],
    ),
  );
  Widget header() {
    final hours = todayHours(place, DateTime.now());
    final status = place.isOpen == null
        ? '운영시간 확인 필요'
        : place.isOpen!
        ? '영업 중'
        : '영업 종료';
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
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: '닫기',
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
                      style: const TextStyle(fontSize: 11, color: Colors.black),
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
                        ? (locating ? '위치 확인 중' : '거리 확인')
                        : formatDistance(distance!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B6B70),
                    ),
                  ),
                ),
              ),
              Text(
                place.isCatalog
                    ? 'Pind 게시물 ${place.pindPostCount ?? 0}개'
                    : place.reviewCount == null
                    ? '리뷰 수 확인 필요'
                    : '리뷰 ${place.reviewCount}개',
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B6B70)),
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
                  place.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF717178),
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
                message: '1·2·3순위 50·30·20%. 내 평가가 있으면 가게 평균과 절반씩 반영해요.',
                child: DetailGlass(
                  radius: 16,
                  purple: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      '내 취향 ${score == null ? '평가 부족' : '$score%'}',
                      key: const ValueKey('taste-match'),
                      style: const TextStyle(
                        fontSize: 11,
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
    Color(0xFFA8154A),
    Color(0xFFB65B00),
    Color(0xFF3155D9),
  ];
  String average(PreferenceCriterion axis) {
    final value = social?.averages[axis];
    return value == null
        ? '—'
        : value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }

  Widget ratingChip(PreferenceCriterion axis, int index) {
    final color = axisColors[index % 3], text = average(axis);
    return Tooltip(
      message: '${axis.label} · 가게 평균 $text / 5',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          border: Border.all(color: color.withValues(alpha: .22)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Semantics(
          label: '${axis.label} 가게 평균 $text점',
          child: Text(
            '${axis.emoji} ★ $text',
            style: TextStyle(
              fontSize: 11,
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
            '$names${visitors.length > 2 ? ' 외 ${visitors.length - 2}명' : ''}님이 다녀갔어요'
            '${social!.friendSaveCount > 0 ? ' · 친구 ${social!.friendSaveCount}명 저장' : ''}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF454550)),
          ),
        ),
      ],
    );
  }

  Widget gallery(List<PlacePhoto> photos, [String key = 'detail-photo']) =>
      Padding(
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
                          label: '${place.name} 장소 사진 ${index + 1}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: double.infinity,
                              height: 182,
                              child: placePhoto(
                                photos[index].uri,
                                BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        for (final author in photos[index].authors)
                          photoCredit('사진: ${author.name}', author.uri),
                        if (photos[index].sourceUri != null)
                          photoCredit('사진 출처', photos[index].sourceUri),
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
            fontSize: 9,
            height: 1.35,
            color: Color(0xFF68686E),
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
                      ['소개', '게시물'][i],
                      style: TextStyle(
                        fontSize: 14,
                        height: 17 / 14,
                        fontWeight: tab == i
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: tab == i
                            ? PindTheme.ink
                            : const Color(0xFF9B9B9B),
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
                        color: tab == i
                            ? PindTheme.ink
                            : const Color(0xFFEDEDF1),
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
                          color: Color(0xFFEDEDF1),
                          child: Icon(Icons.person, size: 22),
                        )
                      : placePhoto(post.avatar!, BoxFit.cover),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '@${post.author}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -.07,
                    color: Colors.black,
                  ),
                ),
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
                      fontSize: 12,
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

  Widget postPhotos(PlacePost post) {
    const yellow = Color(0xFFF4FF5A);
    if (post.photos.length < 2) {
      return post.photos.isEmpty
          ? const SizedBox(height: 30)
          : openable(
              post,
              0,
              Container(
                height: 217.32,
                foregroundDecoration: BoxDecoration(
                  border: Border.all(color: yellow, width: 3.747),
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
    Widget card(int index, Color border, [int more = 0]) => Container(
      width: 109.01,
      height: 164.912,
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: border, width: 2),
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
                    fontSize: 20,
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
    // Full width, so the fanned side cards stay inside the Stack and receive taps.
    return SizedBox(
      width: double.infinity,
      height: 179,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: const Alignment(0, 1),
        children: [
          if (post.photos.length > 2)
            side(openable(post, 2, card(2, yellow, extra)), 95, -8, 6.51),
          side(openable(post, 1, card(1, yellow)), -93, -7, -8.21),
          openable(post, 0, card(0, const Color(0xFF6300DB))),
        ],
      ),
    );
  }

  Widget openable(PlacePost post, int index, Widget child) => Semantics(
    button: true,
    label: '게시물 사진 ${index + 1} 크게 보기',
    child: GestureDetector(
      key: ValueKey('post-photo-${post.hashCode}-$index'),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PostPhotoViewer(photos: post.photos, initial: index),
        ),
      ),
      child: child,
    ),
  );

  Widget postRatingChip(PreferenceCriterion axis, int score, int index) {
    const borders = [Color(0x66E8336E), Color(0x66FF8A1F), Color(0x663563FF)];
    const colors = [Color(0xFFA8154A), Color(0xFFB85600), Color(0xFF1C3FC4)];
    return Semantics(
      label: '${axis.label} $score점',
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
                style: const TextStyle(color: Color(0xFF111111)),
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
          style: const TextStyle(fontSize: 10),
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
          '${axes.map((a) => a.label).join(' · ')} 한 줄 요약',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
                      Text(axes[i].emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${axes[i].label}  ★ ${average(axes[i])}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: axisColors[i % 3],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              place.insightLines[axes[i].name] ??
                                  '아직 한 줄 평이 없어요.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF454550),
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
        for (var i = 0; i < place.posts.length; i++)
          postCard(place.posts[i], i),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.hasRichContent)
              if (tab == 0) ...[
                Text(
                  [place.insightSummary, place.summary].firstWhere(
                        (text) => text?.trim().isNotEmpty == true,
                        orElse: () => null,
                      ) ??
                      '제공된 소개가 없어요.',
                  key: const ValueKey('detail-intro'),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Color(0xFF6B6B70),
                  ),
                ),
                const SizedBox(height: 20),
                reviewSummary(),
              ] else if (place.posts.isEmpty)
                const Text('아직 게시물이 없어요.'),
            if (place.isCatalog && place.googleSearchEnabled)
              TextButton(
                key: const ValueKey('detail-google-search'),
                onPressed: searchingGoogle ? null : searchGoogle,
                child: Text(
                  searchingGoogle ? 'Google에서 찾는 중…' : 'Google에서 추가 정보 찾기',
                ),
              ),
            const SizedBox(height: 12),
            if (place.sourceDate != null)
              Text(
                '공공데이터 기준일: ${place.sourceDate}',
                style: const TextStyle(fontSize: 10, color: PindTheme.muted),
              ),
            Text(
              '정보 제공: ${place.sourceLabel}',
              style: const TextStyle(fontSize: 12, color: PindTheme.muted),
            ),
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
  Future<void> searchGoogle() async {
    final error = await controller.searchGoogle(
      onResults: (candidates) async {
        if (!mounted) return;
        final selected = await showModalBottomSheet<Place>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          builder: (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: .55,
            builder: (_, scroll) => ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Google 검색 결과 · 같은 가게인지 확인해 주세요.'),
                for (final candidate in candidates)
                  ListTile(
                    title: Text(candidate.name),
                    subtitle: Text(candidate.address),
                    onTap: () => Navigator.pop(ctx, candidate),
                  ),
              ],
            ),
          ),
        );
        if (!mounted || selected == null) return;
        final detail = controller.forPlace(selected);
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => PlaceSheet(controller: detail),
        );
      },
    );
    if (mounted && error != null) message(error);
  }

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
            saved ? '저장됨' : '저장',
            'save',
            13.4603,
            saving ? null : save,
            key: const ValueKey('detail-save'),
            selected: saved,
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (ctx) => action(
              '공유',
              'share',
              13.542,
              () => share(ctx),
              key: const ValueKey('detail-share'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: action(
              '길찾기',
              'directions',
              15.4546,
              () => link(directionsUri(place).toString()),
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
                style: const TextStyle(fontSize: 12.426),
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
