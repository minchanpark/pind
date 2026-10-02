import 'package:flutter/material.dart';

import '../../controllers/profile_controller.dart';
import '../../services/post_photo_service.dart';
import '../components/pind_glass.dart';
import '../components/pind_sheet.dart';
import '../design_system.dart';
import 'profile_screen.dart';

/// Behind My Page's ⚙︎: photo, nickname and status message, in the app's
/// standard sheet.
Future<void> showProfileSettingsSheet(
  BuildContext context,
  ProfileController controller,
) => showPindSheet<void>(context, builder: (_) => _SettingsSheet(controller));

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet(this.controller);
  final ProfileController controller;
  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late final profile = widget.controller.model.overview?.profile;
  late final name = TextEditingController(text: profile?.displayName);
  late final bio = TextEditingController(text: profile?.bio);

  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final ok = await widget.controller.saveProfile(
      displayName: name.text.trim(),
      bio: bio.text.trim(),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller.model,
    builder: (context, _) {
      final model = widget.controller.model;
      final current = model.overview?.profile ?? profile;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '프로필 설정',
            textAlign: TextAlign.center,
            style: PindText.title,
          ),
          const SizedBox(height: 18),
          Center(
            child: Semantics(
              button: true,
              label: '사진 변경',
              child: GestureDetector(
                onTap: model.saving
                    ? null
                    : () => widget.controller.pickAndUploadAvatar(
                        DevicePostPhotoService(),
                      ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatar(current?.avatarUrl, 88),
                    // Camera badge on the photo's lower right.
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: PindGlass(
                        tone: PindGlassTone.purple,
                        radius: 15,
                        child: SizedBox.square(
                          dimension: 30,
                          child: Icon(
                            Icons.photo_camera_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            current?.handle == null ? '아이디 없음' : '@${current!.handle}',
            textAlign: TextAlign.center,
            style: PindText.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          const Text(
            '아이디는 변경할 수 없어요',
            textAlign: TextAlign.center,
            style: PindText.caption,
          ),
          const SizedBox(height: 22),
          PindTextField(label: '닉네임', controller: name, maxLength: 40),
          const SizedBox(height: 4),
          PindTextField(
            label: '상태 메시지',
            controller: bio,
            maxLength: 80,
            hint: '오늘의 상태를 남겨 보세요',
          ),
          if (model.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                model.error!,
                textAlign: TextAlign.center,
                style: PindText.caption.copyWith(color: PindColors.pink),
              ),
            ),
          const SizedBox(height: 14),
          PindSheetButton(
            '저장',
            tone: PindSheetButtonTone.primary,
            onTap: model.saving ? null : save,
          ),
          const SizedBox(height: 10),
          PindSheetButton('닫기', onTap: () => Navigator.of(context).pop()),
        ],
      );
    },
  );
}
