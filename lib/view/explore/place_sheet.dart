import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';
import '../../model/place_context.dart';
import '../../controllers/place_detail_controller.dart';

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
  List<PlacePhoto> get photos => !place.hasRichContent
      ? []
      : place.gallery.isNotEmpty
      ? place.gallery
      : place.imageUrl == null
      ? []
      : [PlacePhoto(place.imageUrl!, place.photoSourceUri, place.authors)];

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
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
            child: ListView(
              controller: scroll,
              padding: EdgeInsets.zero,
              children: [
                header(),
                if (loading) const LinearProgressIndicator(minHeight: 2),
                if (detailError) errorRow('상세 정보를 불러오지 못했어요.'),
                if (contextError) errorRow('취향·친구 정보를 불러오지 못했어요.'),
                if (photos.isNotEmpty) gallery(),
                TextButton(
                  key: const ValueKey('detail-expand'),
                  onPressed: () => sheet.animateTo(
                    .96,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  ),
                  child: const Text(
                    '⌃  위로 올려서 소개 · 게시물 보기',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7A7A80)),
                  ),
                ),
                description(),
              ],
            ),
          ),
          footer(),
        ],
      ),
    ),
  );
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

  Widget ratingChip(PreferenceCriterion axis, int index) {
    const colors = [Color(0xFFA8154A), Color(0xFFB65B00), Color(0xFF3155D9)];
    final color = colors[index % 3], value = social?.averages[axis];
    final text = value == null
        ? '—'
        : value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
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
                        : photo(visitors[i].avatar!, BoxFit.cover),
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

  Widget photo(String uri, BoxFit fit) => uri.startsWith('assets/')
      ? Image.asset(uri, fit: fit)
      : Image.network(
          uri,
          fit: fit,
          errorBuilder: (_, error, stack) =>
              const Center(child: Icon(Icons.image_not_supported_outlined)),
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
  Widget gallery() => Padding(
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
                key: ValueKey('detail-photo-$index'),
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
                          child: photo(photos[index].uri, BoxFit.cover),
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

  Widget description() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (place.hasRichContent) tabs(),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (place.hasRichContent)
              if (tab == 0)
                Text(
                  place.summary?.trim().isNotEmpty == true
                      ? place.summary!
                      : '제공된 소개가 없어요.',
                )
              else
                const Text('게시물 목록은 다음 단계에서 연결합니다.'),
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
