import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controllers/discover_controller.dart';
import '../../controllers/explore_controller.dart';
import '../../model/discover_model.dart';
import '../../model/preferences.dart';
import '../components/pind_glass.dart';
import '../components/post_card.dart';
import '../explore/place_sheet.dart';
import '../profile/profile_screen.dart' show mutedNote;
import '../theme.dart';

/// Figma 611:23904: public feed of everyone's posts, newest first.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.controller,
    this.explore,
    this.preferences,
    this.bottomClearance = 0,
    this.onFindFriends,
  });
  final DiscoverController controller;
  final ExploreController? explore;
  final TastePreferences? preferences;
  final double bottomClearance;

  /// Opens the find-friends page (friend-add icon and the invite card).
  final VoidCallback? onFindFriends;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  static const inset = EdgeInsets.symmetric(horizontal: 18.5);
  DiscoverController get controller => widget.controller;
  DiscoverModel get model => controller.model;
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    model.addListener(changed);
    scroll.addListener(nearEnd);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  void nearEnd() {
    if (scroll.position.extentAfter < 600 &&
        model.hasMore &&
        !model.loading &&
        !model.loadingMore) {
      controller.loadMore();
    }
  }

  Future<void> openPlace(FeedPost p) async {
    final explore = widget.explore;
    if (explore == null) return;
    await showPlaceSheet(
      context,
      explore.details(p.post.place, widget.preferences),
    );
  }

  @override
  void dispose() {
    model.removeListener(changed);
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = model.posts;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: CustomScrollView(
            controller: scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: header()),
              if (posts.isEmpty)
                SliverPadding(
                  padding: inset.copyWith(top: 40),
                  sliver: SliverToBoxAdapter(child: status()),
                )
              else
                SliverList.builder(
                  itemCount: posts.length,
                  itemBuilder: (_, i) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: PindTheme.border,
                        ),
                      Padding(
                        padding: inset.copyWith(top: 18, bottom: 18),
                        child: card(posts[i]),
                      ),
                    ],
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.only(bottom: widget.bottomClearance + 24),
                sliver: SliverToBoxAdapter(
                  child: model.loadingMore
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget header() => Padding(
    padding: inset.copyWith(top: 20.5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pind Your Taste!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF090909),
                  letterSpacing: -.51,
                  height: 33.85 / 24,
                ),
              ),
            ),
            roundButton(
              'assets/feed/Icon/person-add.svg',
              '친구 추가',
              widget.onFindFriends,
            ),
            const SizedBox(width: 8),
            // ponytail: no notification screen yet; wire onTap when it exists.
            roundButton(
              'assets/feed/Icon/bell.svg',
              model.hasNewAlerts ? '새 알림' : '알림',
              null,
              badge: model.hasNewAlerts,
            ),
          ],
        ),
        const SizedBox(height: 24.6),
        const Text(
          '친구들 취향 탐색하기',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: .82,
          ),
        ),
        // Only for an empty feed; not while loading or after an error.
        if (model.posts.isEmpty && !model.loading && model.error == null) ...[
          const SizedBox(height: 12),
          inviteCard(),
        ],
        const SizedBox(height: 6),
      ],
    ),
  );

  Widget roundButton(
    String icon,
    String label,
    VoidCallback? onTap, {
    bool badge = false,
  }) => Semantics(
    button: true,
    label: label,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        PindGlass(
          radius: 20,
          child: InkWell(
            onTap: onTap,
            child: SizedBox.square(
              dimension: 38,
              child: Center(
                child: SvgPicture.asset(icon, width: 22, height: 22),
              ),
            ),
          ),
        ),
        if (badge)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFD63E6A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    ),
  );

  /// Figma 617:24624.
  Widget inviteCard() => PindGlass(
    radius: 18.465,
    padding: const EdgeInsets.fromLTRB(16.4, 16.4, 16.4, 18.5),
    child: Column(
      children: [
        const Text('👫', style: TextStyle(fontSize: 28.7, height: 1.5)),
        const SizedBox(height: 8.2),
        const Text(
          '친구 초대하기',
          style: TextStyle(
            fontSize: 14.4,
            fontWeight: FontWeight.w700,
            color: Color(0xFF090909),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4.1),
        const Text(
          '친구들의 음식 취향을 공유하세요',
          style: TextStyle(
            fontSize: 12.3,
            color: Color(0xFF777771),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14.4),
        PindGlass(
          tone: PindGlassTone.dark,
          radius: 20,
          child: SizedBox(
            width: 129.3,
            height: 39,
            child: TextButton(
              onPressed: widget.onFindFriends,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
              ),
              child: const Text(
                '초대하기',
                style: TextStyle(fontSize: 13.3, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget status() {
    if (model.loading) return const Center(child: CircularProgressIndicator());
    if (model.error != null) {
      return Column(
        children: [
          Text(
            model.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PindTheme.muted),
          ),
          TextButton(onPressed: controller.load, child: const Text('다시 시도')),
        ],
      );
    }
    return mutedNote('아직 게시물이 없어요.');
  }

  Widget card(FeedPost p) => PostCard(
    post: p.post,
    author: p.author,
    preferences: widget.preferences,
    onPlace: widget.explore == null ? null : () => openPlace(p),
    action: PostCardButton(
      label: p.liked ? '좋아요 취소' : '좋아요',
      selected: p.liked,
      leading: p.likeCount > 0
          ? Text(
              '${p.likeCount}',
              style: const TextStyle(fontSize: 10, color: PindTheme.muted),
            )
          : null,
      icon: Icon(
        p.liked ? Icons.favorite : Icons.favorite_border,
        size: 12,
        color: p.liked ? PindTheme.purple : null,
      ),
      onTap: (_) => controller.toggleLike(p),
    ),
  );
}
