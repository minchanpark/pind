import 'package:flutter/material.dart';

import '../../model/profile_model.dart';
import '../components/pind_glass.dart';
import '../theme.dart';
import 'profile_screen.dart' show ProfileAvatar;

const _pink = Color(0xFFE8336E);

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
      onToggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final following = overview.following;
    final label = following
        ? '팔로잉'
        : overview.followsMe
        ? '맞팔로우'
        : '팔로우';
    final color = following ? PindTheme.ink : Colors.white;
    return Semantics(
      button: true,
      label: following ? '$label, 팔로우 취소' : label,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (following)
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: PindTheme.muted,
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
    await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFFF7F7F9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: ProfileAvatar(p.avatarUrl, 64)),
              const SizedBox(height: 12),
              Text(
                '${p.handle == null ? p.displayName : '@${p.handle}'} 님을 팔로우 취소할까요?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: PindTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '취소해도 언제든 다시 팔로우할 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: PindTheme.muted),
              ),
              const SizedBox(height: 18),
              _SheetButton(
                '팔로우 취소',
                color: _pink,
                fill: _pink.withValues(alpha: .1),
                border: _pink.withValues(alpha: .8),
                onTap: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 10),
              _SheetButton(
                '닫기',
                color: PindTheme.ink,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    ) ??
    false;

class _SheetButton extends StatelessWidget {
  const _SheetButton(
    this.label, {
    required this.color,
    required this.onTap,
    this.fill,
    this.border,
  });
  final String label;
  final Color color;
  final Color? fill, border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PindGlass(
    radius: 16,
    fillColor: fill,
    borderColor: border,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    ),
  );
}
