import 'places.dart';
import 'profile_model.dart';

enum NotificationKind { like, visit, follow }

/// One row of the 알림 page (Figma 788:23179).
class PindNotification {
  const PindNotification({
    required this.kind,
    required this.at,
    required this.actor,
    this.place,
    this.photoUrl,
  });
  final NotificationKind kind;
  final DateTime at;

  /// Who liked, visited or followed.
  final UserProfile actor;

  /// The liked post's or the visit's place; null for a follow.
  final Place? place;
  final String? photoUrl;

  /// [photoUrl] resolves the row's post photo (signed or public).
  factory PindNotification.fromJson(
    Map<String, dynamic> json, {
    String? photoUrl,
  }) {
    final place = json['place'];
    return PindNotification(
      kind: NotificationKind.values.byName(json['kind'] as String),
      at: DateTime.parse(json['at'] as String),
      actor: UserProfile.fromJson(Map<String, dynamic>.from(json['actor'])),
      place: place is Map
          ? Place.fromJson(Map<String, dynamic>.from(place))
          : null,
      photoUrl: photoUrl,
    );
  }
}

/// The notifications and when I last read them all.
class NotificationInbox {
  const NotificationInbox(this.items, {this.seenAt});
  final List<PindNotification> items;
  final DateTime? seenAt;

  bool isUnread(PindNotification n) => seenAt == null || n.at.isAfter(seenAt!);
  int get unread => items.where(isUnread).length;

  NotificationInbox readAll(DateTime at) =>
      NotificationInbox(items, seenAt: at);
}
