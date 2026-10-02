import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/friends_controller.dart';
import 'package:pind_flutter/model/profile_link.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/services/profile_service.dart';
import 'package:pind_flutter/services/profile_share_service.dart';
import 'package:pind_flutter/view/friends/qr_scan_screen.dart';
import 'package:pind_flutter/view/friends/share_code_screen.dart';
import 'package:pind_flutter/view/design_system.dart';
import 'package:qr_flutter/qr_flutter.dart';

const id = '9f1c2d3e-4b5a-6c7d-8e9f-0a1b2c3d4e5f';
const minchan = UserProfile(id: id, handle: 'minchan', displayName: '민찬');

Future<void> pump(
  WidgetTester tester,
  UserProfile? me, {
  Future<void> Function(ProfileLink)? onOpenLink,
  ProfileShareService shares = const ProfileShareService(),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(402, 1200);
  addTearDown(tester.view.reset);
  final controller = FriendsController(service: null, profile: _Me(me));
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: PindTheme.data,
      home: ShareCodeScreen(
        controller: controller,
        onOpenLink: onOpenLink,
        shares: shares,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows my name, handle, link and QR', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, minchan);
    expect(find.text('내 코드 공유'), findsOneWidget);
    expect(find.text('민찬'), findsOneWidget);
    expect(find.text('@minchan'), findsOneWidget);
    expect(find.text('pind-profile-links.vercel.app/@minchan'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('https://pind-profile-links.vercel.app/@minchan'),
      ),
      findsOne,
    );
    expect(find.bySemanticsLabel('내 Pind QR 코드'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('KakaoTalk and Instagram show their own logos', (tester) async {
    await pump(tester, minchan);
    for (final (label, name) in [
      ('카카오톡', 'kakaotalk_icon.svg'),
      ('인스타', 'insta_icon.svg'),
    ]) {
      final logo = find.descendant(
        of: find.bySemanticsLabel(label),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SvgPicture &&
              (w.bytesLoader as SvgAssetLoader).assetName ==
                  'assets/share/$name',
        ),
      );
      expect(logo, findsOneWidget, reason: name);
      expect(tester.getSize(logo).height, 38);
    }
    // flutter_svg silently draws nothing for Figma's image-in-<pattern>
    // fills; the logos must actually paint.
    for (final name in ['kakaotalk_icon.svg', 'insta_icon.svg']) {
      final drawn = await tester.runAsync(() async {
        final info = await vg.loadPicture(
          SvgAssetLoader('assets/share/$name'),
          null,
        );
        final image = await info.picture.toImage(
          info.size.width.ceil(),
          info.size.height.ceil(),
        );
        final rgba = (await image.toByteData())!;
        var opaque = 0;
        for (var i = 3; i < rgba.lengthInBytes; i += 4) {
          if (rgba.getUint8(i) > 0) opaque++;
        }
        return opaque / (image.width * image.height);
      });
      expect(drawn, greaterThan(.9), reason: name);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('no handle links by id', (tester) async {
    await pump(tester, const UserProfile(id: id, displayName: '민찬'));
    expect(find.textContaining('@'), findsNothing);
    expect(find.text('pind-profile-links.vercel.app/u/$id'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('https://pind-profile-links.vercel.app/u/$id')),
      findsOne,
    );
  });

  testWidgets('no profile offers a retry', (tester) async {
    await pump(tester, null);
    expect(find.text('프로필을 불러오지 못했어요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('copy puts the link on the clipboard', (tester) async {
    final copied = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') copied.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pump(tester, minchan);
    await tester.tap(find.text('pind-profile-links.vercel.app/@minchan'));
    await tester.pump();
    expect(copied, [
      {'text': 'https://pind-profile-links.vercel.app/@minchan'},
    ]);
    expect(find.text('링크를 복사했어요.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('링크 복사'));
    await tester.pump();
    expect(copied, hasLength(2));
  });

  testWidgets('KakaoTalk tile falls back to the share sheet without a key', (
    tester,
  ) async {
    final shared = <String>[];
    await pump(
      tester,
      minchan,
      shares: ProfileShareService(
        kakaoKey: '',
        share: (text, title, origin) async => shared.add(text),
      ),
    );
    await tester.tap(find.text('카카오톡'));
    await tester.pump();
    expect(shared, [
      'Pind에서 @minchan 님을 팔로우하고 음식 취향을 나눠요!\nhttps://pind-profile-links.vercel.app/@minchan',
    ]);
  });

  testWidgets('a scanned code opens that profile', (tester) async {
    final opened = <ProfileLink>[];
    await pump(tester, minchan, onOpenLink: (link) async => opened.add(link));
    await tester.tap(find.text('친구 코드 스캔하기'));
    await tester.pumpAndSettle();
    expect(find.text('친구 코드 스캔'), findsOneWidget);
    Navigator.of(tester.element(find.byType(QrScanScreen)))
        .pop(const ProfileLink.handle('friend'));
    await tester.pumpAndSettle();
    expect(opened, [const ProfileLink.handle('friend')]);
    expect(find.byType(ShareCodeScreen), findsOneWidget);
  });

  test('the scanner takes the first Pind link', () {
    expect(firstProfileLink(const []), isNull);
    expect(
      firstProfileLink(const [null, 'https://example.com/@a_b', 'hello']),
      isNull,
    );
    expect(
      firstProfileLink(const [
        'https://example.com/@nope',
        null,
        'https://pind-profile-links.vercel.app/@first',
        'https://pind-profile-links.vercel.app/u/$id',
      ]),
      const ProfileLink.handle('first'),
    );
  });

  test('Kakao without a key uses the injected share', () async {
    final shared = <(String, String)>[];
    await ProfileShareService(
      kakaoKey: '',
      share: (text, title, origin) async => shared.add((text, title)),
    ).kakao(minchan, 'invite', Rect.zero);
    expect(shared, [('invite', 'Pind 친구 초대')]);
  });
}

class _Me implements ProfileService {
  const _Me(this.me);
  final UserProfile? me;
  @override
  Future<UserProfile?> load() async => me;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
