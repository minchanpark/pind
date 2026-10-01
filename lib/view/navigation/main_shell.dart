import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../controllers/discover_controller.dart';
import '../../controllers/friends_controller.dart';
import '../../controllers/explore_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../model/navigation_model.dart';
import '../../model/profile_link.dart';
import '../../model/preferences.dart';
import '../explore/explore_screen.dart';
import 'pind_navigation_bar.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../model/post_model.dart';
import '../../services/discover_service.dart';
import '../../services/friends_service.dart';
import '../../services/post_service.dart';
import '../../services/post_photo_service.dart';
import '../../services/profile_service.dart';
import '../discover/discover_screen.dart';
import '../friends/friends_screen.dart';
import '../posts/post_composer.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.controller,
    this.posts,
    this.profile,
    this.discover,
    this.friends,
    required this.mapsEnabled,
    required this.onEditPreferences,
    this.preferences,
    this.pendingLink,
  });
  final ExploreController? controller;
  final PostService? posts;
  final ProfileService? profile;
  final DiscoverService? discover;
  final FriendsService? friends;
  final TastePreferences? preferences;
  final bool mapsEnabled;
  final VoidCallback onEditPreferences;

  /// Shared profile link to open; taken (set to null) once handled.
  final ValueNotifier<ProfileLink?>? pendingLink;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final navigation = NavigationController();
  late final profile = ProfileController(profile: widget.profile);
  late final discover = DiscoverController(
    service: widget.discover,
    deletePost: widget.posts?.delete,
  );
  PindTab get selected => navigation.model.selected;

  @override
  void initState() {
    super.initState();
    navigation.model.addListener(changed);
    discover.load();
    widget.pendingLink?.addListener(takeLink);
    // A link that arrived during login/onboarding.
    WidgetsBinding.instance.addPostFrameCallback((_) => takeLink());
  }

  void changed() => setState(() {});

  @override
  void dispose() {
    navigation.model.removeListener(changed);
    widget.pendingLink?.removeListener(takeLink);
    navigation.dispose();
    profile.dispose();
    discover.dispose();
    super.dispose();
  }

  void select(PindTab tab) {
    if (selected == tab) return;
    FocusManager.instance.primaryFocus?.unfocus();
    navigation.select(tab);
    // Saves, views and likes change on other tabs; the page keeps showing the
    // old overview while this refreshes in the background, only after a write.
    if (tab == PindTab.profile) profile.refresh();
  }

  void takeLink() {
    final link = widget.pendingLink?.value;
    if (link == null || !mounted) return;
    widget.pendingLink!.value = null;
    openLink(link);
  }

  /// Opens a shared profile link (deep link or scanned code).
  Future<void> openLink(ProfileLink link) async {
    final messenger = ScaffoldMessenger.of(context);
    final String? id;
    try {
      id = link.userId ?? await widget.profile?.findUserId(link.handle!);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 열지 못했어요.')));
      return;
    }
    if (!mounted) return;
    if (id == null) {
      messenger.showSnackBar(const SnackBar(content: Text('프로필을 찾을 수 없어요.')));
    } else if (id == widget.posts?.userId) {
      // My own link: back to the shell, on My Page.
      Navigator.of(context).popUntil((route) => route.isFirst);
      select(PindTab.profile);
    } else {
      await openProfile(id);
    }
  }

  Future<void> openFriends() async {
    final friends = FriendsController(
      service: widget.friends,
      profile: widget.profile,
    );
    friends.load();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => FriendsScreen(
            controller: friends,
            onOpenLink: openLink,
            onOpenProfile: (c) async {
              final following = await openProfile(c.profile.id);
              if (following != null) {
                friends.markFollowing(c.profile.id, following);
              }
            },
          ),
        ),
      );
    } finally {
      friends.dispose();
    }
    // Follower/following counts live on My Page.
    if (mounted) profile.refresh();
  }

  /// Someone else's page; returns whether I follow them when it closes.
  Future<bool?> openProfile(String userId) async {
    final other = ProfileController(
      profile: widget.profile,
      friends: widget.friends,
      userId: userId,
    );
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            controller: other,
            explore: widget.controller,
            preferences: widget.preferences,
            mapsEnabled: widget.mapsEnabled,
          ),
        ),
      );
      return other.model.overview?.following;
    } finally {
      other.dispose();
    }
  }

  Future<void> compose() async {
    if (!navigation.beginCompose()) return;
    // Places viewed or saved since My Page last loaded feed the place picker.
    profile.refresh();
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final saved = await Navigator.of(context).push<PublishedPost>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PostComposer(
            controller: PostController(
              posts: widget.posts ?? UnavailablePostService(),
              photos: DevicePostPhotoService(),
              places: widget.controller?.repository,
              mine: () => profile.model.overview,
              criteria: widget.preferences?.priorities,
            ),
          ),
        ),
      );
      if (saved != null && mounted) {
        // The new post belongs on My Page and at the top of Discover.
        profile.load();
        discover.load();
        navigation.select(PindTab.map);
        await widget.controller?.showPublishedPlace(saved.placeId);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('게시물을 등록했어요.')));
        }
      }
    } finally {
      navigation.endCompose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = math.max(23.0, MediaQuery.viewPaddingOf(context).bottom);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final clearance = bottom + PindNavigationBar.barHeight + 12;
    return PopScope(
      canPop: selected == PindTab.map,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) select(PindTab.map);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            IndexedStack(
              index: selected.index,
              children: [
                TickerMode(
                  enabled: selected == PindTab.discover,
                  child: DiscoverScreen(
                    controller: discover,
                    myId: widget.posts?.userId,
                    explore: widget.controller,
                    preferences: widget.preferences,
                    bottomClearance: clearance,
                    onFindFriends: openFriends,
                  ),
                ),
                TickerMode(
                  enabled: selected == PindTab.map,
                  child: ExploreScreen(
                    controller: widget.controller,
                    preferences: widget.preferences,
                    mapsEnabled: widget.mapsEnabled,
                    onEditPreferences: widget.onEditPreferences,
                    isActive: selected == PindTab.map,
                    bottomClearance: clearance,
                  ),
                ),
                TickerMode(
                  enabled: selected == PindTab.profile,
                  child: ProfileScreen(
                    controller: profile,
                    explore: widget.controller,
                    preferences: widget.preferences,
                    mapsEnabled: widget.mapsEnabled,
                    onEditPreferences: widget.onEditPreferences,
                    onShowMap: (placeId) {
                      select(PindTab.map);
                      // Same focus path as a freshly published post.
                      if (placeId != null) {
                        widget.controller?.showPublishedPlace(placeId);
                      }
                    },
                    bottomClearance: clearance,
                  ),
                ),
              ],
            ),
            if (!keyboardOpen)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottom,
                child: Center(
                  child: PindNavigationBar(
                    selected: selected,
                    onSelect: select,
                    onCompose: compose,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
