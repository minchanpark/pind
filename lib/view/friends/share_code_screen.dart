import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../controllers/friends_controller.dart';
import '../../model/profile_link.dart';
import '../../model/profile_model.dart';
import '../../services/profile_share_service.dart';
import '../components/pind_back_header.dart';
import '../components/pind_glass.dart';
import '../profile/profile_screen.dart' show ProfileAvatar, mutedNote;
import '../design_system.dart';
import 'qr_scan_screen.dart';
import '../../l10n/l10n.dart';

/// Figma 671:35498: my QR code and link, share targets, and the scanner.
class ShareCodeScreen extends StatefulWidget {
  const ShareCodeScreen({
    super.key,
    required this.controller,
    this.onOpenLink,
    this.shares = const ProfileShareService(),
  });
  final FriendsController controller;
  final Future<void> Function(ProfileLink link)? onOpenLink;
  final ProfileShareService shares;

  @override
  State<ShareCodeScreen> createState() => _ShareCodeScreenState();
}

class _ShareCodeScreenState extends State<ShareCodeScreen> {
  late Future<UserProfile?> me = widget.controller.me();
  final card = GlobalKey();

  static Rect origin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? Rect.zero : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> copy(ProfileLink link) async {
    await Clipboard.setData(ClipboardData(text: '${link.uri}'));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.linkCopied)));
  }

  Future<void> instagram(ProfileLink link, Rect at) async {
    final boundary =
        card.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return;
    await ProfileShareService.image(
      data.buffer.asUint8List(),
      '${link.uri}',
      at,
    );
  }

  Future<void> scan() async {
    final link = await Navigator.of(context).push<ProfileLink>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const QrScanScreen(),
      ),
    );
    if (link != null) await widget.onOpenLink?.call(link);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 2, 24, 32),
        children: [
          PindBackHeader(l10n.shareMyCode),
          const SizedBox(height: 20),
          FutureBuilder(
            future: me,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final p = snap.data;
              if (p == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    children: [
                      mutedNote(l10n.profileLoadFailed),
                      TextButton(
                        onPressed: () =>
                            setState(() => me = widget.controller.me()),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }
              return body(p);
            },
          ),
        ],
      ),
    ),
  );

  Widget body(UserProfile p) {
    final link = ProfileLink.of(p);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // White behind the glass so the Instagram image isn't see-through.
        RepaintBoundary(
          key: card,
          child: ColoredBox(color: Colors.white, child: codeCard(p, link)),
        ),
        const SizedBox(height: 18),
        Row(
          spacing: 10,
          children: [
            tile(
              l10n.kakaoTalk,
              SvgPicture.asset(
                'assets/share/kakaotalk_icon.svg',
                width: 38,
                height: 38,
              ),
              (at) =>
                  widget.shares.kakao(p, FriendsController.inviteFor(p), at),
            ),
            tile(
              l10n.instagram,
              SvgPicture.asset(
                'assets/share/insta_icon.svg',
                width: 38,
                height: 38,
              ),
              (at) => instagram(link, at),
            ),
            tile(
              l10n.copyLink,
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: PindColors.chip,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link, size: 18, color: PindColors.ink),
              ),
              (_) => copy(link),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Semantics(
          button: true,
          label: l10n.scanFriendCode,
          child: PindGlass(
            tone: PindGlassTone.purple,
            radius: 18,
            child: InkWell(
              onTap: scan,
              child: ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.scanFriendCode,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: PindType.bodyLarge,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget codeCard(UserProfile p, ProfileLink link) => PindGlass(
    radius: 24,
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
    child: Column(
      spacing: 16,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(99, 0, 219, .2),
                offset: Offset(0, 6),
                blurRadius: 16,
              ),
            ],
          ),
          child: ProfileAvatar(p.avatarUrl, 66),
        ),
        Column(
          spacing: 3,
          children: [
            Text(
              p.displayName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: PindColors.ink,
              ),
            ),
            if (p.handle != null)
              Text(
                '@${p.handle}',
                style: const TextStyle(
                  fontSize: PindType.label,
                  color: PindColors.muted,
                ),
              ),
          ],
        ),
        Container(
          width: 180,
          height: 180,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PindColors.border),
          ),
          child: Semantics(
            container: true,
            image: true,
            label: l10n.myQrCode,
            child: ExcludeSemantics(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  QrImageView(
                    // Tests find the QR by its data.
                    key: ValueKey('${link.uri}'),
                    data: '${link.uri}',
                    // H survives the logo covering the middle.
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    padding: EdgeInsets.zero,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: PindColors.ink,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: PindColors.ink,
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: PindColors.purple,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Text(
                      'P',
                      style: TextStyle(
                        fontSize: PindType.titleLarge,
                        fontWeight: FontWeight.w700,
                        color: PindColors.lime,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: l10n.copyLinkLabel(link.display),
          child: Material(
            color: const Color.fromRGBO(244, 245, 248, .9),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => copy(link),
              child: ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Flexible(
                        child: Text(
                          link.display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: PindType.label,
                            fontWeight: FontWeight.w500,
                            color: PindColors.body,
                          ),
                        ),
                      ),
                      // '⧉' in Figma; system fonts lack the glyph.
                      const Icon(
                        Icons.content_copy_rounded,
                        size: 12,
                        color: PindColors.purple,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  /// A share target; [onTap] gets the tile's rect for the iPad popover.
  /// [icon] is 38×38: the app's own logo, or a tinted circle.
  Widget tile(String label, Widget icon, void Function(Rect at) onTap) =>
      Expanded(
        child: Semantics(
          button: true,
          label: label,
          child: PindGlass(
            radius: 16,
            child: Builder(
              builder: (ctx) => InkWell(
                onTap: () => onTap(origin(ctx)),
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 12),
                    child: Column(
                      spacing: 7,
                      children: [
                        icon,
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: PindType.caption,
                            fontWeight: FontWeight.w500,
                            color: PindColors.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
