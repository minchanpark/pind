import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;

import '../../controllers/explore_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../model/preferences.dart';
import '../../model/profile_model.dart';
import '../components/pind_glass.dart';
import '../components/pind_skeleton.dart';
import '../explore/place_sheet.dart';
import '../design_system.dart';
import 'profile_follow.dart';
import 'profile_map_tab.dart';
import 'profile_posts_tab.dart';
import 'profile_saved_tab.dart';
import 'profile_settings_sheet.dart';
import '../components/pind_image.dart';
import '../../l10n/l10n.dart';

/// Figma 531:19957 / 531:20051 / 531:20229; another user's page is 663:5337.
/// Tabs pad themselves so the post dividers can run edge to edge.
const profileInset = EdgeInsets.symmetric(horizontal: 16);
const profileBody = PindColors.body;

/// Figma accent per criterion; anything outside the three is neutral.
Color criterionColor(PreferenceCriterion c) => switch (c) {
  PreferenceCriterion.taste => PindColors.taste,
  PreferenceCriterion.ambience => PindColors.ambience,
  PreferenceCriterion.portion => PindColors.portion,
  _ => profileBody,
};

/// `서울특별시 성동구 성수동 123` → `성수동`; road addresses fall back to the 구.
String placeArea(String address) {
  final tokens = address.split(' ').where((t) => t.isNotEmpty).toList();
  // ponytail: suffix scan; `성수동1가`-style tokens fall through to the 구.
  for (final suffix in const ['동', '읍', '면', '리', '구']) {
    for (final t in tokens) {
      if (t.length > 1 && t.endsWith(suffix) && !t.startsWith(RegExp(r'\d'))) {
        return t;
      }
    }
  }
  return tokens.length > 1 ? tokens[1] : address;
}

Widget placeImage(String? url) => url == null
    ? const ColoredBox(color: PindColors.imageFill)
    : Image(
        image: PindImage(url),
        fit: BoxFit.cover,
        frameBuilder: fadeInFrame,
        errorBuilder: (_, _, _) =>
            const ColoredBox(color: PindColors.imageFill),
      );

Widget mutedNote(String text) => Text(
  text,
  style: const TextStyle(fontSize: PindType.label, color: PindColors.muted),
);

Widget profileSection(
  String title,
  Widget body, {
  String? trailing,
  VoidCallback? onTrailing,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: 10,
  children: [
    Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: PindType.body,
            fontWeight: FontWeight.w700,
            color: PindColors.ink,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailing,
            child: Text(
              trailing,
              style: const TextStyle(
                fontSize: PindType.label,
                color: PindColors.muted,
              ),
            ),
          ),
      ],
    ),
    body,
  ],
);

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(this.url, this.size, {super.key});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: PindColors.line,
      child: Icon(Icons.person, size: size / 2, color: PindColors.muted),
    );
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? fallback
            : Image(
                image: PindImage(url!),
                fit: BoxFit.cover,
                frameBuilder: fadeInFrame,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    this.explore,
    this.preferences,
    required this.mapsEnabled,
    this.onEditPreferences,
    this.onShowMap,
    this.bottomClearance = 0,
    this.myId,
    this.onOpenProfile,
    this.onSignOut,
  });
  final ProfileController controller;
  final ExploreController? explore;

  /// The viewer's, even on someone else's page (it scores places for me).
  final TastePreferences? preferences;
  final bool mapsEnabled;
  final VoidCallback? onEditPreferences;
  final void Function(int? placeId)? onShowMap;
  final double bottomClearance;

  /// Me, so 팔로워/팔로잉 lists don't offer to follow myself.
  final String? myId;

  /// Someone in a 팔로워/팔로잉 list was tapped.
  final void Function(String userId)? onOpenProfile;

  /// 로그아웃 in the settings sheet; only on My Page.
  final Future<void> Function()? onSignOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileController get controller => widget.controller;
  ProfileModel get model => controller.model;
  bool get isMe => controller.isMe;

  @override
  void initState() {
    super.initState();
    model.addListener(changed);
    if (model.overview == null && !model.loading) controller.load();
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    model.removeListener(changed);
    super.dispose();
  }

  Future<void> openPlace(ProfilePlaceCard card) async {
    final explore = widget.explore;
    if (explore == null) return;
    final detail = explore.details(card.place, widget.preferences);
    await showPlaceSheet(context, detail);
    // Saves and "recently viewed" may have changed inside the sheet.
    if (mounted) controller.refresh();
  }

  /// From the saved page's bookmark; reloads so counts and the tab follow.
  Future<void> setSaved(ProfilePlaceCard card, bool saved) async {
    await widget.explore!.placeContext!.setSaved(card.place.id!, saved);
    if (mounted) controller.load();
  }

  Future<void> toggleFollow() async {
    if (await controller.toggleFollow() || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(model.error ?? l10n.tryAgainPlease)));
  }

  Widget topBar() => isMe
      ? Align(
          alignment: Alignment.centerRight,
          child: Semantics(
            button: true,
            label: l10n.settings,
            child: GestureDetector(
              onTap: () => showProfileSettingsSheet(
                context,
                controller,
                onSignOut: widget.onSignOut,
              ),
              child: const PindGlass(
                radius: 20,
                padding: EdgeInsets.all(8),
                child: Icon(Icons.settings_outlined, size: 24),
              ),
            ),
          ),
        )
      : Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: l10n.back,
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.chevron_left,
              size: 28,
              color: PindColors.ink,
            ),
          ),
        );

  @override
  Widget build(BuildContext context) {
    final o = model.overview;
    // Someone else's taste comes from the server, and only with consent.
    final taste = isMe
        ? widget.preferences
        : o?.taste == null
        ? null
        : TastePreferences(priorities: o!.taste!);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: 8,
              bottom: widget.bottomClearance + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 22,
              children: [
                Padding(padding: profileInset, child: topBar()),
                if (o == null && model.loading)
                  PindSkeleton(
                    child: Column(
                      spacing: 10,
                      children: [
                        bone(105, 105, radius: 52.5),
                        bone(120, 16),
                        bone(180, 12),
                        const SizedBox(height: 12),
                        Padding(
                          padding: profileInset,
                          child: Row(
                            children: [
                              for (var i = 0; i < 4; i++)
                                Expanded(child: Center(child: bone(40, 34))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (o == null)
                  Column(
                    children: [
                      Text(
                        model.error ?? l10n.profileLoadFailed,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: PindColors.muted),
                      ),
                      TextButton(
                        onPressed: controller.load,
                        child: Text(l10n.retry),
                      ),
                    ],
                  )
                else
                  // The page fades in once, when it first arrives.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 250),
                    builder: (_, opacity, page) =>
                        Opacity(opacity: opacity, child: page),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 22,
                      children: [
                        header(o.profile),
                        stats(o.counts),
                        if (!isMe)
                          Padding(
                            padding: profileInset,
                            child: FollowButton(
                              overview: o,
                              onToggle: toggleFollow,
                            ),
                          ),
                        Padding(padding: profileInset, child: tabs(model.tab)),
                        switch (model.tab) {
                          ProfileTab.map => ProfileMapTab(
                            overview: o,
                            mine: isMe,
                            preferences: taste,
                            mapsEnabled: widget.mapsEnabled,
                            onEditPreferences: widget.onEditPreferences,
                            onShowMap: widget.onShowMap,
                            onOpenPlace: widget.explore == null
                                ? null
                                : (place) =>
                                      openPlace(ProfilePlaceCard(place: place)),
                          ),
                          ProfileTab.saved => ProfileSavedTab(
                            overview: o,
                            mine: isMe,
                            preferences: widget.preferences,
                            onOpen: widget.explore == null ? null : openPlace,
                            onSetSaved:
                                isMe && widget.explore?.placeContext != null
                                ? setSaved
                                : null,
                          ),
                          ProfileTab.posts => ProfilePostsTab(
                            overview: o,
                            preferences: widget.preferences,
                            onShare: controller.share,
                          ),
                        },
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Figma 671:34873: photo, handle, then the status message as written.
  Widget header(UserProfile p) {
    final status = p.bio?.trim();
    return Column(
      spacing: 6,
      children: [
        ProfileAvatar(p.avatarUrl, 105),
        Text(
          p.handle == null ? p.displayName : '@${p.handle}',
          style: const TextStyle(
            fontSize: PindType.body,
            fontWeight: FontWeight.w500,
            letterSpacing: -.4092,
            color: Colors.black,
          ),
        ),
        if (status?.isNotEmpty == true)
          Text(
            status!,
            key: const ValueKey('profile-status'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.338,
              height: 17.006 / 11.338,
              color: PindColors.subtle,
            ),
          ),
      ],
    );
  }

  /// 팔로워 / 팔로잉 list; counts may change while it's open.
  Future<void> openFollows(bool followers) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FollowListPage(
          title: followers ? l10n.followers : l10n.following,
          load: () => controller.followList(followers),
          setFollowing: controller.setFollowing,
          myId: widget.myId,
          onOpen: widget.onOpenProfile == null
              ? null
              : (person) => widget.onOpenProfile!(person.id),
        ),
      ),
    );
    if (mounted) controller.refresh();
  }

  Widget stats(ProfileCounts c) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 12),
    child: Row(
      children: [
        for (final (label, value, onTap) in [
          (l10n.followers, c.followers, () => openFollows(true)),
          (l10n.following, c.following, () => openFollows(false)),
          (l10n.posts, c.posts, null),
          if (isMe) (l10n.save, c.saved, null),
        ])
          Expanded(
            child: GestureDetector(
              key: ValueKey('profile-stat-$label'),
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Semantics(
                button: onTap != null,
                child: Column(
                  children: [
                    Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: PindType.title,
                        fontWeight: FontWeight.w700,
                        color: PindColors.ink,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: PindType.caption,
                        color: PindColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  /// Figma 617:25398: underline tabs; the selected one gets a 3pt ink bar.
  Widget tabs(ProfileTab current) => Semantics(
    role: SemanticsRole.tabBar,
    container: true,
    explicitChildNodes: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final tab in ProfileTab.values)
          Expanded(
            child: Semantics(
              role: SemanticsRole.tab,
              selected: tab == current,
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => controller.selectTab(tab),
                child: Column(
                  spacing: 10,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        switch (tab) {
                          ProfileTab.map => isMe ? l10n.myMap : l10n.navMap,
                          ProfileTab.saved => l10n.save,
                          ProfileTab.posts => l10n.posts,
                        },
                        style: TextStyle(
                          fontSize: PindType.body,
                          fontWeight: tab == current
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: tab == current
                              ? PindColors.ink
                              : PindColors.subtle,
                        ),
                      ),
                    ),
                    Container(
                      height: tab == current ? 3 : 1,
                      color: tab == current ? PindColors.ink : PindColors.chip,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
