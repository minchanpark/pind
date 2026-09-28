import 'dart:ui';

import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceActionService {
  static Future<bool> openLink(String raw) async {
    final uri = Uri.tryParse(raw);
    if (uri == null || !['http', 'https'].contains(uri.scheme)) return true;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<void> share(String text, String title, Rect origin) async {
    await SharePlus.instance.share(
      ShareParams(text: text, title: title, sharePositionOrigin: origin),
    );
  }
}
