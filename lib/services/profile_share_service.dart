import 'dart:typed_data';
import 'dart:ui';

import 'package:kakao_flutter_sdk_share/kakao_flutter_sdk_share.dart';
import 'package:share_plus/share_plus.dart';

import '../model/profile_link.dart';
import '../model/profile_model.dart';
import 'config.dart';
import 'place_action_service.dart';
import '../l10n/l10n.dart';

/// Sends my profile out: a KakaoTalk card, or the system share sheet.
class ProfileShareService {
  const ProfileShareService({
    this.kakaoKey = AppConfig.kakaoNativeAppKey,
    this.share = PlaceActionService.share,
  });
  final String kakaoKey;

  /// `(text, title, origin)`: the system share sheet.
  final Future<void> Function(String, String, Rect) share;
  static String? _kakaoReady;

  /// A KakaoTalk feed card; the share sheet with [invite] when there is no
  /// key, KakaoTalk isn't installed, or anything fails.
  Future<void> kakao(UserProfile me, String invite, Rect origin) async {
    if (kakaoKey.isNotEmpty) {
      try {
        if (_kakaoReady != kakaoKey) {
          await KakaoSdk.init(nativeAppKey: kakaoKey);
          _kakaoReady = kakaoKey;
        }
        if (await ShareClient.instance.isKakaoTalkSharingAvailable()) {
          final link = Link(
            webUrl: ProfileLink.of(me).uri,
            mobileWebUrl: ProfileLink.of(me).uri,
          );
          final avatar = me.avatarUrl;
          // shareDefault also launches KakaoTalk.
          return await ShareClient.instance.shareDefault(
            template: FeedTemplate(
              content: Content(
                title: l10n.shareTitle(me.displayName),
                description: l10n.shareBody,
                imageUrl: avatar == null ? null : Uri.tryParse(avatar),
                link: link,
              ),
              buttons: [Button(title: l10n.viewProfile, link: link)],
            ),
          );
        }
      } catch (_) {}
    }
    await share(invite, l10n.inviteToPind, origin);
  }

  /// The code card as an image, so the user can pick Instagram.
  // ponytail: plain share sheet; Stories direct share needs a Meta App ID.
  static Future<void> image(Uint8List png, String link, Rect origin) =>
      SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(png, mimeType: 'image/png', name: 'pind-code.png'),
          ],
          text: link,
          sharePositionOrigin: origin,
        ),
      );
}
