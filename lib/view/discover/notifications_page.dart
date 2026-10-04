import 'package:flutter/material.dart';

import '../../controllers/discover_controller.dart';
import '../../model/notification_model.dart';
import '../../model/places.dart';
import '../../model/profile_model.dart';
import '../components/pind_back_header.dart';
import '../design_system.dart';
import '../../l10n/l10n.dart';
import '../profile/profile_screen.dart'
    show ProfileAvatar, mutedNote, placeImage;

/// `1시간 전`, `어제`, `3일 전`: how long ago, for a notification.
String notificationAgo(DateTime at, DateTime now) {
  final d = now.difference(at);
  return switch (d.inDays) {
    >= 7 => l10n.agoWeeks(d.inDays ~/ 7),
    >= 2 => l10n.agoDays(d.inDays),
    1 => l10n.yesterday,
    _ when d.inHours >= 1 => l10n.agoHours(d.inHours),
    _ when d.inMinutes >= 1 => l10n.agoMinutes(d.inMinutes),
    _ => l10n.justNow,
  };
}

/// Figma 788:23179 알림: likes on my posts, visits by people I follow and new
/// followers, newest first. Unread rows are tinted until 모두 읽음.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.controller,
    this.onOpenPlace,
    this.onOpenProfile,
  });
  final DiscoverController controller;
  final void Function(Place place)? onOpenPlace;
  final void Function(UserProfile person)? onOpenProfile;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool failed = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => failed = false);
    try {
      await widget.controller.loadNotifications();
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> readAll() async {
    try {
      await widget.controller.markNotificationsRead();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errNotificationsRead)));
    }
  }

  void open(PindNotification n) => switch (n) {
    PindNotification(kind: NotificationKind.follow) =>
      widget.onOpenProfile?.call(n.actor),
    PindNotification(place: final place?) => widget.onOpenPlace?.call(place),
    _ => null,
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller.model,
    builder: (context, _) {
      final inbox = widget.controller.model.inbox;
      final now = DateTime.now();
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 40),
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Expanded(child: PindBackHeader(l10n.notifications)),
                    if (inbox != null && inbox.unread > 0) ...[
                      Container(
                        padding: const EdgeInsets.fromLTRB(10, 5, 11, 5),
                        decoration: BoxDecoration(
                          color: PindColors.purple.withValues(alpha: .1),
                          border: Border.all(
                            color: PindColors.purple.withValues(alpha: .25),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.unreadCount(inbox.unread),
                          style: const TextStyle(
                            fontSize: PindType.micro,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4A1E8A),
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: const ValueKey('notifications-read-all'),
                        behavior: HitTestBehavior.opaque,
                        onTap: readAll,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            l10n.markAllRead,
                            style: TextStyle(
                              fontSize: PindType.caption,
                              fontWeight: FontWeight.w500,
                              color: PindColors.subtle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 26),
                if (inbox == null && failed)
                  Column(
                    children: [
                      mutedNote(l10n.errNotificationsLoad),
                      TextButton(onPressed: refresh, child: Text(l10n.retry)),
                    ],
                  )
                else if (inbox == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (inbox.items.isEmpty)
                  mutedNote(l10n.noNotifications)
                else
                  Column(
                    spacing: 4,
                    children: [
                      for (final n in inbox.items)
                        row(n, unread: inbox.isUnread(n), now: now),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget row(
    PindNotification n, {
    required bool unread,
    required DateTime now,
  }) {
    const bold = TextStyle(fontWeight: FontWeight.w700, color: PindColors.ink);
    final name = n.actor.displayName.isNotEmpty
        ? n.actor.displayName
        : '@${n.actor.handle ?? ''}';
    final (badge, message) = switch (n.kind) {
      NotificationKind.like => (
        '♥',
        [TextSpan(text: name, style: bold), TextSpan(text: l10n.notifLikeRest)],
      ),
      NotificationKind.visit => (
        '📍',
        [
          TextSpan(text: name, style: bold),
          TextSpan(text: l10n.notifVisitMid),
          TextSpan(text: n.place?.name ?? l10n.restaurant, style: bold),
          TextSpan(text: l10n.notifVisitEnd),
        ],
      ),
      NotificationKind.follow => (
        '＋',
        [
          TextSpan(text: name, style: bold),
          TextSpan(text: l10n.notifFollowRest),
        ],
      ),
    };
    final ago = notificationAgo(n.at, now);
    return Semantics(
      button: true,
      child: GestureDetector(
        key: ValueKey(
          'notification-${n.kind.name}-${n.actor.id}-${n.at.millisecondsSinceEpoch}',
        ),
        behavior: HitTestBehavior.opaque,
        onTap: () => open(n),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
          decoration: unread
              ? BoxDecoration(
                  color: PindColors.purple.withValues(alpha: .06),
                  border: Border.all(
                    color: PindColors.purple.withValues(alpha: .16),
                  ),
                  borderRadius: BorderRadius.circular(PindRadius.field),
                )
              : null,
          child: Row(
            spacing: 11,
            children: [
              SizedBox.square(
                dimension: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatar(n.actor.avatarUrl, 44),
                    Positioned(
                      left: 27,
                      top: 27,
                      child: Container(
                        width: 19,
                        height: 19,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: PindColors.purple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: PindType.tiny,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text.rich(
                      TextSpan(children: message),
                      style: const TextStyle(
                        fontSize: PindType.bodySmall,
                        height: 18 / 13,
                        fontWeight: FontWeight.w500,
                        color: PindColors.body,
                      ),
                    ),
                    unread
                        ? Row(
                            spacing: 6,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: PindColors.purple,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                ago,
                                style: const TextStyle(
                                  fontSize: PindType.micro,
                                  fontWeight: FontWeight.w700,
                                  color: PindColors.purple,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            ago,
                            style: const TextStyle(
                              fontSize: PindType.micro,
                              color: PindColors.subtle,
                            ),
                          ),
                  ],
                ),
              ),
              if (n.photoUrl != null)
                Container(
                  width: 44,
                  height: 44,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: placeImage(n.photoUrl),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
