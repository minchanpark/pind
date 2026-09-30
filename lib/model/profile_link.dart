import '../services/config.dart';
import 'profile_model.dart';

/// A shareable profile link: `https://pind-profile-links.vercel.app/@handle`, or
/// `https://pind-profile-links.vercel.app/u/<id>` for someone without a handle yet. QR codes and
/// deep links carry the same URL.
class ProfileLink {
  const ProfileLink.handle(String this.handle) : userId = null;
  const ProfileLink.user(String this.userId) : handle = null;
  final String? handle, userId;

  static final _handle = RegExp(r'^@([a-z0-9_]{3,20})$');
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  factory ProfileLink.of(UserProfile p) =>
      p.handle == null ? ProfileLink.user(p.id) : ProfileLink.handle(p.handle!);

  /// Null for anything that isn't a Pind profile link: other hosts, other
  /// paths, malformed handles. Also accepts the `com.pind.app://` scheme.
  static ProfileLink? parse(String raw, {String host = AppConfig.linkHost}) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return null;
    final web =
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host == host || uri.host == 'www.$host');
    final app = uri.scheme == 'com.pind.app' && uri.host == 'profile';
    if (!web && !app) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length == 1) {
      final m = _handle.firstMatch(segments.first.toLowerCase());
      return m == null ? null : ProfileLink.handle(m.group(1)!);
    }
    if (segments.length == 2 && segments.first == 'u') {
      final id = segments.last.toLowerCase();
      return _uuid.hasMatch(id) ? ProfileLink.user(id) : null;
    }
    return null;
  }

  Uri get uri => Uri.https(
    AppConfig.linkHost,
    handle == null ? '/u/$userId' : '/@$handle',
  );

  /// `pind-profile-links.vercel.app/@handle`, as the share card shows it.
  String get display => '${uri.host}${uri.path}';

  @override
  bool operator ==(Object other) =>
      other is ProfileLink && other.handle == handle && other.userId == userId;
  @override
  int get hashCode => Object.hash(handle, userId);
  @override
  String toString() => uri.toString();
}
