import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../../controllers/registration_controller.dart';
import '../../model/registration_model.dart';
import '../design_system.dart';
import 'registration_components.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.controller});
  final RegistrationController controller;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Scaffold(
      backgroundColor: PindColors.lime,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scale = MediaQuery.textScalerOf(context).scale(15) / 15;
          final sheetHeight =
              354 +
              math.max(0.0, scale - 1) * 140 +
              (controller.allowPreview ? 40 : 0) +
              (controller.model.error == null ? 0 : 45);
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    SizedBox(
                      height: math.max(
                        180,
                        constraints.maxHeight - sheetHeight,
                      ),
                      width: double.infinity,
                      child: const FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        child: _LoginArtwork(),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(minHeight: sheetHeight),
                          decoration: BoxDecoration(
                            color: const Color(0xB3FFFFFF),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                            border: Border.all(color: const Color(0xF2FFFFFF)),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            24,
                            34,
                            24,
                            math.max(
                              30,
                              MediaQuery.viewPaddingOf(context).bottom,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pind',
                                style: TextStyle(
                                  fontSize: PindType.hero,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.02,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '내 취향에 맞는 맛집만, 지도 위에서',
                                style: TextStyle(
                                  fontSize: PindType.bodyLarge,
                                  color: PindColors.muted,
                                ),
                              ),
                              const SizedBox(height: 26),
                              _loginButton(
                                '카카오로 3초 만에 시작하기',
                                LoginProvider.kakao,
                                PindColors.kakao,
                                PindColors.ink,
                              ),
                              const SizedBox(height: 10),
                              _loginButton(
                                'Apple로 계속하기',
                                LoginProvider.apple,
                                const Color(0xB3141418),
                                Colors.white,
                              ),
                              const SizedBox(height: 10),
                              _loginButton(
                                'Google로 계속하기',
                                LoginProvider.google,
                                const Color(0xB8FBFBFD),
                                PindColors.ink,
                              ),
                              if (controller.model.error != null) ...[
                                const SizedBox(height: 12),
                                SetupError(controller.model.error),
                              ],
                              if (controller.allowPreview)
                                Center(
                                  child: TextButton(
                                    key: const ValueKey('onboarding-preview'),
                                    onPressed: controller.model.busy
                                        ? null
                                        : controller.preview,
                                    child: const Text(
                                      '로그인 없이 화면 체험',
                                      style: TextStyle(
                                        fontSize: PindType.label,
                                        color: PindColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  Widget _loginButton(
    String label,
    LoginProvider provider,
    Color background,
    Color foreground,
  ) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      key: ValueKey('login-${provider.name}'),
      onPressed: controller.model.busy
          ? null
          : () => controller.signIn(provider),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: PindType.bodyLarge, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(
          color: provider == LoginProvider.apple
              ? const Color(0xB3000000)
              : provider == LoginProvider.google
              ? PindColors.line
              : Colors.transparent,
        ),
      ),
      child: controller.model.signingIn == provider
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foreground,
              ),
            )
          : Text(label),
    ),
  );
}

class _LoginArtwork extends StatelessWidget {
  const _LoginArtwork();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 402,
    height: 520,
    child: ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6.856,
            top: 76.784,
            // Original Figma export of the individual path node. Its SVG export
            // produces different dash spacing from the design in Flutter.
            child: Image.asset(
              'assets/login/route_path.png',
              width: 393,
              height: 281,
            ),
          ),
          const Positioned(
            left: 27,
            top: 121,
            child: Text(
              'P',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: 'BraahOne',
                fontSize: 212.679,
                height: 1,
                color: Colors.black,
              ),
            ),
          ),
          const Positioned(
            left: 91,
            top: 242,
            child: Text(
              'IND',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: 'BraahOne',
                fontSize: 159.509,
                height: 1,
                color: Colors.black,
              ),
            ),
          ),
          Positioned(
            left: 321,
            top: 210,
            child: SvgPicture.asset(
              'assets/login/pin.svg',
              width: 58,
              height: 78.1015,
            ),
          ),
          const Positioned(
            left: 6,
            right: 0,
            top: 411,
            child: Text(
              'Find it. Pin it.',
              textAlign: TextAlign.center,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: 'Bayon',
                fontSize: 50.944,
                height: 1,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
