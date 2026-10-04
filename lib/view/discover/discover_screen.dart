import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controllers/discover_controller.dart';
import '../../controllers/explore_controller.dart';
import '../../model/discover_model.dart';
import '../../model/preferences.dart';
import '../components/pind_glass.dart';
import '../components/pind_pressable.dart';
import '../components/pind_skeleton.dart';
import '../components/post_card.dart';
import '../explore/place_sheet.dart';
import 'notifications_page.dart';
import '../profile/profile_screen.dart' show mutedNote;
import '../design_system.dart';
import '../../l10n/l10n.dart';

/// Figma 611:23904: public feed of everyone's posts, newest first.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.controller,
    this.explore,
    this.preferences,
    this.bottomClearance = 0,
    this.onFindFriends,
    this.myId,
    this.onOpenProfile,
  });
  final DiscoverController controller;

  /// Signed-in user; their own posts get 삭제 next to the heart.
  final String? myId;
  final ExploreController? explore;
  final TastePreferences? preferences;
  final double bottomClearance;

  /// Opens the find-friends page (friend-add icon and the invite card).
  final VoidCallback? onFindFriends;

  /// A 알림 row about someone (a follow) opens their page.
  final void Function(String userId)? onOpenProfile;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  static const inset = EdgeInsets.symmetric(horizontal: 18.5);
  DiscoverController get controller => widget.controller;
  DiscoverModel get model => controller.model;
  final scroll = ScrollController();

  /// A freshly loaded feed fades in over its placeholders.
  late final appear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    if (model.posts.isNotEmpty) appear.value = 1;
    model.addListener(changed);
    scroll.addListener(nearEnd);
  }

  void changed() {
    if (model.posts.isEmpty) {
      appear.value = 0;
    } else {
      appear.forward();
    }
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

  /// The bell: 알림, where a place opens its detail over the page.
  Future<void> openNotifications() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => NotificationsPage(
        controller: widget.controller,
        onOpenPlace: widget.explore == null
            ? null
            : (place) => showPlaceSheet(
                context,
                widget.explore!.details(place, widget.preferences),
              ),
        onOpenProfile: widget.onOpenProfile == null
            ? null
            : (person) => widget.onOpenProfile!(person.id),
      ),
    ),
  );

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
    appear.dispose();
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
                  padding: inset.copyWith(top: model.loading ? 18 : 40),
                  sliver: SliverToBoxAdapter(child: status()),
                )
              else
                SliverFadeTransition(
                  opacity: appear,
                  sliver: SliverList.builder(
                    itemCount: posts.length,
                    itemBuilder: (_, i) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (i > 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: PindColors.border,
                          ),
                        Padding(
                          padding: inset.copyWith(top: 18, bottom: 18),
                          child: card(posts[i]),
                        ),
                      ],
                    ),
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
                  fontSize: PindType.headline,
                  fontWeight: FontWeight.w800,
                  color: PindColors.ink,
                  letterSpacing: -.51,
                  height: 33.85 / 24,
                ),
              ),
            ),
            roundButton(
              'assets/feed/Icon/person-add.svg',
              l10n.addFriend,
              widget.onFindFriends,
            ),
            const SizedBox(width: 8),
            roundButton(
              'assets/feed/Icon/bell.svg',
              model.hasNewAlerts ? l10n.newNotifications : l10n.notifications,
              openNotifications,
              badge: model.hasNewAlerts,
            ),
          ],
        ),
        const SizedBox(height: 24.6),
        Text(
          l10n.exploreFriendsTaste,
          style: TextStyle(
            fontSize: PindType.body,
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
  }) {
    // The circle and its badge dip together, as the nav bar's icons do.
    final button = Stack(
      clipBehavior: Clip.none,
      children: [
        PindGlass(
          radius: 20,
          child: SizedBox.square(
            dimension: 38,
            child: Center(child: SvgPicture.asset(icon, width: 22, height: 22)),
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
                color: PindColors.pink,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: onTap == null
            ? button
            : PindPressable(scale: .85, child: button),
      ),
    );
  }

  /// Figma 617:24624.
  Widget inviteCard() => PindGlass(
    radius: 18.465,
    padding: const EdgeInsets.fromLTRB(16.4, 16.4, 16.4, 18.5),
    child: Column(
      children: [
        const Text('👫', style: TextStyle(fontSize: 28.7, height: 1.5)),
        const SizedBox(height: 8.2),
        Text(
          l10n.inviteFriends,
          style: TextStyle(
            fontSize: 14.4,
            fontWeight: FontWeight.w700,
            color: PindColors.ink,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4.1),
        Text(
          l10n.shareFriendsTaste,
          style: TextStyle(
            fontSize: 12.3,
            color: PindColors.muted,
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
              child: Text(
                l10n.invite,
                style: TextStyle(fontSize: 13.3, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget status() {
    if (model.loading) return postsSkeleton();
    if (model.error != null) {
      return Column(
        children: [
          Text(
            model.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PindColors.muted),
          ),
          TextButton(onPressed: controller.load, child: Text(l10n.retry)),
        ],
      );
    }
    return mutedNote(l10n.noPostsYet);
  }

  Widget card(FeedPost p) => PostCard(
    post: p.post,
    author: p.author,
    preferences: widget.preferences,
    onPlace: widget.explore == null ? null : () => openPlace(p),
    action: postActions(
      likeHasCount: p.likeCount > 0,
      delete:
          widget.myId != null &&
              p.author.id == widget.myId &&
              controller.deletePost != null
          ? PostDeleteButton(
              onConfirmed: () async {
                final error = await controller.delete(p);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? l10n.postDeleted)),
                );
              },
            )
          : null,
      like: PostCardButton(
        label: p.liked ? l10n.unlike : l10n.like,
        selected: p.liked,
        leading: p.likeCount > 0
            ? Text(
                '${p.likeCount}',
                style: const TextStyle(
                  fontSize: PindType.micro,
                  color: PindColors.muted,
                ),
              )
            : null,
        icon: Icon(
          p.liked ? Icons.favorite : Icons.favorite_border,
          size: 12,
          color: p.liked ? PindColors.purple : null,
        ),
        onTap: (_) {
          HapticFeedback.lightImpact();
          controller.toggleLike(p);
        },
      ),
    ),
  );
}
