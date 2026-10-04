import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';

import '../../controllers/registration_controller.dart';
import '../../model/registration_model.dart';
import '../design_system.dart';
import 'registration_components.dart';
import '../../l10n/l10n.dart';

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
                              Text(
                                l10n.loginTagline,
                                style: TextStyle(
                                  fontSize: PindType.bodyLarge,
                                  color: PindColors.muted,
                                ),
                              ),
                              const SizedBox(height: 26),
                              _loginButton(
                                l10n.loginKakao,
                                LoginProvider.kakao,
                                PindColors.kakao,
                                PindColors.ink,
                              ),
                              const SizedBox(height: 10),
                              _loginButton(
                                l10n.loginApple,
                                LoginProvider.apple,
                                const Color(0xB3141418),
                                Colors.white,
                              ),
                              const SizedBox(height: 10),
                              _loginButton(
                                l10n.loginGoogle,
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
                                    child: Text(
                                      l10n.loginPreview,
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
        textStyle: const TextStyle(
          fontSize: PindType.bodyLarge,
          fontWeight: FontWeight.w700,
        ),
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

/// The PIND intro (assets/app/PIND_intro.lottie.json, 402×508, 3.6s): road,
/// letters, pin and "Find it. Pin it." play once and stay. With reduce motion
/// on, the finished frame shows at once.
class _LoginArtwork extends StatefulWidget {
  const _LoginArtwork();
  @override
  State<_LoginArtwork> createState() => _LoginArtworkState();
}

class _LoginArtworkState extends State<_LoginArtwork>
    with SingleTickerProviderStateMixin {
  late final intro = AnimationController(vsync: this);

  @override
  void dispose() {
    intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 402,
    height: 508,
    child: ExcludeSemantics(
      child: Lottie.asset(
        'assets/app/PIND_intro.lottie.json',
        controller: intro,
        width: 402,
        height: 508,
        fit: BoxFit.contain,
        onLoaded: (composition) {
          intro.duration = composition.duration;
          if (MediaQuery.disableAnimationsOf(context)) {
            intro.value = 1;
          } else {
            intro.forward();
          }
        },
      ),
    ),
  );
}
