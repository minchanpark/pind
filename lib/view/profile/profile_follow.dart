import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../model/friends_model.dart';
import '../../model/place_search_result.dart';
import '../../model/profile_model.dart';
import '../components/pind_back_header.dart';
import '../components/pind_glass.dart';
import '../components/pind_skeleton.dart';
import '../components/pind_sheet.dart';
import '../design_system.dart';
import '../../l10n/l10n.dart';
import 'profile_screen.dart' show ProfileAvatar, mutedNote;

/// Figma 663:5336. 팔로우 / 맞팔로우 (they follow me) are purple; 팔로잉 is
/// glass and asks before unfollowing.
class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    required this.overview,
    required this.onToggle,
  });
  final ProfileOverview overview;
  final VoidCallback onToggle;

  Future<void> tap(BuildContext context) async {
    if (!overview.following ||
        await confirmUnfollow(context, overview.profile)) {
      HapticFeedback.lightImpact();
      onToggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final following = overview.following;
    final label = following
        ? l10n.following
        : overview.followsMe
        ? l10n.followBack
        : l10n.follow;
    final color = following ? PindColors.ink : Colors.white;
    return Semantics(
      button: true,
      label: following ? l10n.unfollowLabel(label) : label,
      child: PindGlass(
        tone: following ? PindGlassTone.light : PindGlassTone.purple,
        radius: 14,
        child: InkWell(
          onTap: () => tap(context),
          child: ExcludeSemantics(
            child: SizedBox(
              height: 43,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 6,
                children: [
                  Icon(
                    following ? Icons.check : Icons.add,
                    size: 16,
                    color: color,
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: PindType.bodyLarge,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (following)
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: PindColors.muted,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma 663:5621. True when the user chose 팔로우 취소.
Future<bool> confirmUnfollow(BuildContext context, UserProfile p) async =>
    await showPindSheet<bool>(
      context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: ProfileAvatar(p.avatarUrl, 64)),
          const SizedBox(height: 12),
          Text(
            l10n.unfollowTitle(
              p.handle == null ? p.displayName : '@${p.handle}',
            ),
            textAlign: TextAlign.center,
            style: PindText.title,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.unfollowBody,
            textAlign: TextAlign.center,
            style: PindText.caption,
          ),
          const SizedBox(height: 18),
          PindSheetButton(
            l10n.unfollow,
            tone: PindSheetButtonTone.danger,
            onTap: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 10),
          PindSheetButton(
            l10n.close,
            onTap: () => Navigator.pop(context, false),
          ),
        ],
      ),
    ) ??
    false;

/// A person in a list: photo, name, handle (and taste match), then 팔로우.
/// Shared by 친구 찾기 and the 팔로워/팔로잉 lists.
class PersonRow extends StatelessWidget {
  const PersonRow({
    super.key,
    required this.candidate,
    this.onOpen,
    this.onToggleFollow,
  });
  final FriendCandidate candidate;
  final VoidCallback? onOpen;

  /// Null hides the button (e.g. on my own row).
  final VoidCallback? onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final UserProfile p = c.profile;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Row(
                spacing: 12,
                children: [
                  ProfileAvatar(p.avatarUrl, 44),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          p.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: PindType.body,
                            fontWeight: FontWeight.w700,
                            color: PindColors.ink,
                          ),
                        ),
                        if (p.handle != null)
                          Text(
                            '@${p.handle}',
                            style: const TextStyle(
                              fontSize: PindType.caption,
                              color: PindColors.muted,
                            ),
                          ),
                        if (c.match != null)
                          Text(
                            l10n.tasteMatchPercent(c.match!),
                            style: const TextStyle(
                              fontSize: PindType.micro,
                              fontWeight: FontWeight.w500,
                              color: PindColors.subtle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (onToggleFollow != null) followButton(c),
        ],
      ),
    );
  }

  Widget followButton(FriendCandidate c) => Semantics(
    button: true,
    label: c.following
        ? l10n.unfollowName(c.profile.displayName)
        : l10n.followName(c.profile.displayName),
    child: PindGlass(
      tone: c.following ? PindGlassTone.light : PindGlassTone.purple,
      radius: 14,
      child: InkWell(
        onTap: onToggleFollow == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onToggleFollow!();
              },
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              c.following ? l10n.unfollow : l10n.follow,
              style: TextStyle(
                fontSize: PindType.caption,
                fontWeight: FontWeight.w700,
                color: c.following ? PindColors.subtle : Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// 팔로워 / 팔로잉 behind the profile counts: [load] the people, follow or
/// unfollow them in place, tap one to open their page.
class FollowListPage extends StatefulWidget {
  const FollowListPage({
    super.key,
    required this.title,
    required this.load,
    required this.setFollowing,
    this.myId,
    this.onOpen,
  });
  final String title;
  final Future<List<FriendCandidate>> Function() load;
  final Future<void> Function(String userId, bool following) setFollowing;

  /// My own row gets no button and doesn't open.
  final String? myId;
  final void Function(UserProfile person)? onOpen;

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  List<FriendCandidate>? people;
  String? error;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => error = null);
    try {
      final loaded = await widget.load();
      if (mounted) setState(() => people = loaded);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is PlaceFailure ? e.message : l10n.errListLoad,
        );
      }
    }
  }

  /// At once, then back if the server says no.
  Future<void> toggle(FriendCandidate c) async {
    final target = !c.following;
    void mark(bool value) => setState(
      () => people = [
        for (final p in people!)
          p.profile.id == c.profile.id ? p.withFollowing(value) : p,
      ],
    );
    mark(target);
    try {
      await widget.setFollowing(c.profile.id, target);
    } catch (e) {
      if (!mounted) return;
      mark(!target);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is PlaceFailure ? e.message : l10n.tryAgainPlease),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = people;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 40),
          children: [
            Row(
              children: [
                Expanded(child: PindBackHeader(widget.title)),
                if (list != null)
                  Text(
                    l10n.peopleCount(list.length),
                    style: const TextStyle(
                      fontSize: PindType.label,
                      fontWeight: FontWeight.w700,
                      color: PindColors.muted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (error != null)
              Column(
                children: [
                  mutedNote(error!),
                  TextButton(onPressed: fetch, child: Text(l10n.retry)),
                ],
              )
            else if (list == null)
              peopleSkeleton()
            else if (list.isEmpty)
              mutedNote(
                widget.title == l10n.followers
                    ? l10n.noFollowers
                    : l10n.noFollowing,
              )
            else
              for (final c in list)
                PersonRow(
                  key: ValueKey('follow-${c.profile.id}'),
                  candidate: c,
                  onOpen: widget.onOpen == null || c.profile.id == widget.myId
                      ? null
                      : () => widget.onOpen!(c.profile),
                  onToggleFollow: c.profile.id == widget.myId
                      ? null
                      : () => toggle(c),
                ),
          ],
        ),
      ),
    );
  }
}
