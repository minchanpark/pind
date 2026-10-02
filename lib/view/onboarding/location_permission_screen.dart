import 'package:flutter/material.dart';

import '../../controllers/registration_controller.dart';
import '../components/pind_glass.dart';
import '../design_system.dart';
import 'registration_components.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key, required this.controller});
  final RegistrationController controller;

  @override
  Widget build(BuildContext context) => SetupPage(
    background: PindColors.surface,
    footer: Column(
      children: [
        SetupError(controller.model.error),
        if (controller.model.permissionBlocked)
          TextButton(
            onPressed: controller.model.busy
                ? null
                : controller.showLocationSettings,
            child: const Text('설정에서 위치 권한 확인'),
          ),
        SetupButton(
          '위치 허용하고 시작하기',
          busy: controller.model.busy,
          onPressed: controller.allowLocation,
        ),
        const SizedBox(height: 6),
        TextButton(
          key: const ValueKey('skip-location'),
          onPressed: controller.model.busy ? null : controller.skipLocation,
          child: const Text(
            '나중에 할게요',
            style: TextStyle(fontSize: PindType.bodySmall, color: PindColors.muted),
          ),
        ),
      ],
    ),
    children: [
      const _LocationIllustration(),
      const SizedBox(height: 30),
      const SetupTitle(
        '지금 있는 곳 주변부터\n보여드릴게요',
        '위치를 허용하면 내 주변 맛집과 취향을 탐색할 수 있어요.',
        large: true,
      ),
      const SizedBox(height: 24),
      _benefit('🍜', '내 주변 맛집', '반경 안에서만 추천해요'),
      _benefit('👫', '친구들 맛집', '친구들이 간 맛집을 볼 수 있어요'),
      _benefit('🏡', '동네 랭킹', '#1 in 성수동 같은 지역 순위'),
    ],
  );

  Widget _benefit(String emoji, String title, String subtitle) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const SetupCircle(40, borderColor: Colors.transparent),
              Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: PindType.headline, height: 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: PindType.body,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: PindType.label, color: PindColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LocationIllustration extends StatelessWidget {
  const _LocationIllustration();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 354 / 230,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: 354,
            height: 230,
            child: ColoredBox(
              color: PindColors.pastelSage,
              child: ExcludeSemantics(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      left: -31,
                      top: 119,
                      width: 170,
                      height: 140,
                      child: _Park(),
                    ),
                    const Positioned(
                      left: 249,
                      top: -31,
                      width: 150,
                      height: 120,
                      child: _Park(),
                    ),
                    const Positioned(
                      left: -11,
                      top: 109,
                      width: 400,
                      height: 5,
                      child: ColoredBox(color: Colors.white),
                    ),
                    const Positioned(
                      left: 129,
                      top: -11,
                      width: 5,
                      height: 260,
                      child: ColoredBox(color: Colors.white),
                    ),
                    const Positioned(
                      left: 269,
                      top: -11,
                      width: 5,
                      height: 260,
                      child: ColoredBox(color: Colors.white),
                    ),
                    const Positioned(
                      left: 165,
                      top: 103,
                      child: SetupCircle(22, tone: PindGlassTone.purple),
                    ),
                    const Positioned(
                      left: 116,
                      top: 57,
                      width: 120,
                      height: 120,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.fromRGBO(99, 0, 219, .1),
                          border: Border.fromBorderSide(
                            BorderSide(color: Color.fromRGBO(99, 0, 219, .25)),
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 148,
                      top: 89,
                      child: SetupCircle(56),
                    ),
                    const Positioned(
                      left: 156,
                      top: 106,
                      width: 40,
                      child: Text(
                        '☕',
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontSize: 30, height: 1),
                      ),
                    ),
                    const Positioned(left: 59, top: 39, child: SetupCircle(40)),
                    const Positioned(
                      left: 59,
                      top: 47.8,
                      width: 40,
                      child: Text(
                        '🍜',
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontSize: PindType.titleLarge, height: 1),
                      ),
                    ),
                    const Positioned(
                      left: 249,
                      top: 139,
                      child: SetupCircle(40),
                    ),
                    const Positioned(
                      left: 249,
                      top: 147.8,
                      width: 40,
                      child: Text(
                        '🥩',
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontSize: PindType.titleLarge, height: 1),
                      ),
                    ),
                    const Positioned(
                      left: 279,
                      top: 49,
                      child: SetupCircle(36),
                    ),
                    const Positioned(
                      left: 279,
                      top: 56.92,
                      width: 36,
                      child: Text(
                        '🍰',
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontSize: PindType.subtitle, height: 1),
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

/// Green park patch on the location illustration's map.
class _Park extends StatelessWidget {
  const _Park();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: ShapeDecoration(shape: OvalBorder(), color: PindColors.pastelGreen),
  );
}
