import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controllers/post_controller.dart';
import '../../model/post_model.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';
import '../components/pind_glass.dart';
import '../explore/explore_screen.dart';
import '../design_system.dart';
import 'post_place_picker.dart';

class PostComposer extends StatefulWidget {
  const PostComposer({super.key, required this.controller});
  final PostController controller;
  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  PostController get controller => widget.controller;
  PostModel get model => controller.model;
  late final body = TextEditingController(text: model.body);
  @override
  void initState() {
    super.initState();
    model.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    model.removeListener(changed);
    body.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> selectPlace() async {
    if (model.publishing) return;
    final selected = await showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => PostPlacePicker(controller: controller),
    );
    if (mounted && selected != null) controller.selectPlace(selected);
  }

  Future<void> publish() async {
    FocusScope.of(context).unfocus();
    final post = await controller.publish();
    if (mounted && post != null) Navigator.pop(context, post);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !model.publishing,
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 49.7,
        leading: IconButton(
          tooltip: '닫기',
          onPressed: model.publishing ? null : () => Navigator.pop(context),
          icon: SvgPicture.asset(
            'assets/post_composer/close_icon.svg',
            width: 20.6096,
            height: 20.6096,
          ),
        ),
        title: const Text(
          '게시물 작성',
          style: TextStyle(
            fontSize: 15.462,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(.7),
          child: Divider(height: .7, thickness: .7, color: PindColors.pastelSage),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 32),
            sliver: SliverList.list(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '사진 추가',
                    style: TextStyle(
                      fontSize: PindType.body,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                photos(),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      section('방문한 식당'),
                      const SizedBox(height: 10),
                      place(),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          section('평점'),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '맛 · 양 · 분위기 (필수)',
                              style: TextStyle(
                                fontSize: PindType.caption,
                                color: PindColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 186),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: PindGlass(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                for (
                                  var i = 0;
                                  i < model.criteria.length;
                                  i++
                                ) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: PindColors.border,
                                    ),
                                  rating(model.criteria[i], i),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      PindGlass(
                        tone: PindGlassTone.purple,
                        radius: 14,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '내 평균 별점',
                                style: TextStyle(
                                  fontSize: PindType.label,
                                  height: 1.2,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            PindGlass(
                              tone: PindGlassTone.lime,
                              radius: 12,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              child: Text(
                                model.average == null
                                    ? '★'
                                    : '★ ${model.average}',
                                style: const TextStyle(
                                  fontSize: PindType.bodySmall,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: PindColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          section('글 작성하기'),
                          const SizedBox(width: 8),
                          const Text(
                            '선택',
                            style: TextStyle(
                              fontSize: PindType.caption,
                              color: PindColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      PindGlass(
                        radius: 16,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TextField(
                              controller: body,
                              onChanged: controller.setBody,
                              enabled: !model.publishing,
                              maxLength: 200,
                              minLines: 3,
                              maxLines: 5,
                              style: TextStyle(
                                fontSize: model.body.isEmpty ? 12.536 : 13,
                                height: model.body.isEmpty
                                    ? 23.767 / 12.536
                                    : 20 / 13,
                                fontWeight: model.body.isEmpty
                                    ? FontWeight.w400
                                    : FontWeight.w500,
                                color: PindColors.ink,
                                letterSpacing: 0,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                counterText: '',
                                hintText: '이 음식을 고향 음식에 비유하면? 처음 먹어본 외국인으로서 솔직한 후기를 남겨주세요.',
                                hintStyle: TextStyle(
                                  fontSize: 12.536,
                                  height: 23.767 / 12.536,
                                  color: PindColors.placeholder,
                                  letterSpacing: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${model.bodyLength} / 200',
                              style: TextStyle(
                                fontSize: PindType.micro,
                                height: 1.2,
                                color: model.bodyLength > 200
                                    ? Colors.red
                                    : PindColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (model.error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          model.error!,
                          style: const TextStyle(
                            fontSize: PindType.label,
                            color: Colors.red,
                          ),
                          semanticsLabel: '오류: ${model.error}',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Ends the page instead of floating: after the content on long pages,
          // at the bottom of the screen on short ones.
          SliverFillRemaining(
            hasScrollBody: false,
            child: SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 32, 18, 20),
                  child: PindGlass(
                    // Figma 531:18203 / 531:18277: one dark-rimmed pill whose
                    // fill turns solid purple once the post can be published.
                    tone: PindGlassTone.dark,
                    fillColor: model.canPublish
                        ? PindColors.purpleLight
                        : null,
                    radius: 22,
                    child: SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: TextButton(
                        key: const ValueKey('publish-post'),
                        onPressed: model.canPublish ? publish : null,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                        ),
                        child: model.publishing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '게시하기',
                                style: TextStyle(
                                  fontSize: PindType.body,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget section(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: PindType.body,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: PindColors.ink,
      letterSpacing: 0,
    ),
  );
  Widget photos() => SizedBox(
    height: 159,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      separatorBuilder: (_, index) => const SizedBox(width: 8),
      itemCount: model.photos.length + (model.photos.length < 10 ? 1 : 0),
      itemBuilder: (_, index) {
        if (index == model.photos.length) {
          return SizedBox(
            width: 112,
            child: Semantics(
              label: '사진 추가',
              button: true,
              child: InkWell(
                onTap: model.publishing || model.pickingPhotos
                    ? null
                    : controller.addPhotos,
                child: PindGlass(
                  radius: model.photos.isEmpty ? 18 : 12,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (model.pickingPhotos)
                          const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          SvgPicture.asset(
                            model.photos.isEmpty
                                ? 'assets/post_composer/camera_icon.svg'
                                : 'assets/post_composer/add_photo_icon.svg',
                            width: model.photos.isEmpty ? 22.9817 : 20,
                            height: model.photos.isEmpty ? 22.9817 : 17.8653,
                          ),
                        if (model.photos.isEmpty) ...[
                          const SizedBox(height: 4),
                          const Text(
                            '0/10',
                            style: TextStyle(
                              fontSize: PindType.micro,
                              color: PindColors.placeholder,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return SizedBox(
          width: 112,
          child: Semantics(
            label: '사진 ${index + 1}, 길게 눌러 삭제',
            child: GestureDetector(
              onLongPress: model.publishing
                  ? null
                  : () => controller.removePhoto(index),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: index == 0
                        ? PindColors.limeDeep
                        : PindColors.purple,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    model.photos[index].bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stack) =>
                        const Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
  Widget place() {
    final selected = model.place;
    return PindGlass(
      radius: 18,
      borderColor: selected == null ? null : PindColors.purple,
      child: InkWell(
        onTap: model.publishing ? null : selectPlace,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PindColors.fill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  selected == null ? '🍽️' : markerEmoji(selected),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected?.name ?? '방문한 식당을 선택해 주세요',
                      style: const TextStyle(
                        fontSize: PindType.bodyLarge,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${selected.category} · ${selected.address}',
                        style: const TextStyle(
                          fontSize: PindType.caption,
                          color: PindColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                selected == null ? '선택' : '변경',
                style: const TextStyle(
                  fontSize: PindType.label,
                  fontWeight: FontWeight.w700,
                  color: PindColors.purple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget rating(PreferenceCriterion axis, int slot) {
    final score = model.ratings[axis] ?? 0;
    final color = PostStar.colors[slot];
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(axis.emoji, style: const TextStyle(fontSize: 17)),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            axis.label,
            style: const TextStyle(
              fontSize: PindType.body,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var n = 1; n <= 5; n++)
          Semantics(
            label: '${axis.label} $n점',
            button: true,
            selected: score == n,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: model.publishing ? null : () => controller.rate(axis, n),
              child: SizedBox(
                width: 30,
                height: 58,
                child: Center(
                  child: PostStar(
                    slot: slot,
                    filled: n <= score,
                    unrated: score == 0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    final badge = score == 0
        ? const SizedBox.shrink()
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              border: Border.all(color: color.withValues(alpha: .35)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              scoreLabel(axis, score),
              style: TextStyle(
                fontSize: PindType.tiny,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0,
              ),
            ),
          );
    return LayoutBuilder(
      builder: (_, bounds) {
        if (bounds.maxWidth < 310 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(children: [title, const Spacer(), badge]),
              stars,
            ],
          );
        }
        return Row(
          children: [
            title,
            const SizedBox(width: 7),
            stars,
            const Spacer(),
            badge,
          ],
        );
      },
    );
  }

  String scoreLabel(PreferenceCriterion axis, int score) => switch (axis) {
    PreferenceCriterion.taste => switch (score) {
      5 => '최고예요',
      4 => '맛있어요',
      3 => '괜찮아요',
      2 => '아쉬워요',
      _ => '별로예요',
    },
    PreferenceCriterion.portion => switch (score) {
      5 => '아주 많아요',
      4 => '넉넉해요',
      3 => '적당해요',
      2 => '적어요',
      _ => '아주 적어요',
    },
    _ => switch (score) {
      5 => '최고예요',
      4 => '좋아요',
      3 => '괜찮아요',
      2 => '아쉬워요',
      _ => '별로예요',
    },
  };
}

class PostStar extends StatelessWidget {
  const PostStar({
    super.key,
    required this.slot,
    required this.filled,
    this.unrated = false,
  });

  /// Priority position (0-2); each position keeps one Figma star style.
  final int slot;
  final bool filled, unrated;
  static const colors = [
    PindColors.pink,
    PindColors.ratingOrange,
    PindColors.ratingBlue,
  ];
  static const _assets = ['taste', 'portion', 'ambience'];
  @override
  Widget build(BuildContext context) {
    if (unrated || (!filled && slot == 0)) {
      return SizedBox(
        width: 24,
        height: 23,
        child: Center(
          child: Text(
            '☆',
            style: TextStyle(
              fontSize: 25,
              height: 1,
              color: unrated ? PindColors.border : colors[0],
            ),
          ),
        ),
      );
    }
    final name = 'star_${_assets[slot]}${filled ? '' : '_empty'}.svg';
    return SizedBox(
      width: 24,
      height: 23,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: filled ? -0.8162 : 2.184,
            top: filled ? 0.0461 : 1.5459,
            child: SvgPicture.asset(
              'assets/post_composer/$name',
              width: filled ? 25.6324 : 19.6324,
              height: filled ? 24.1341 : 18.1341,
            ),
          ),
        ],
      ),
    );
  }
}
