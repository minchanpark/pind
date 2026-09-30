import 'package:flutter/material.dart';

import '../../controllers/profile_controller.dart';
import '../../services/post_photo_service.dart';
import '../theme.dart';
import 'profile_screen.dart';

Future<void> showProfileSettingsSheet(
  BuildContext context,
  ProfileController controller,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _SettingsSheet(controller),
);

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
      return Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatar(current?.avatarUrl, 96),
              TextButton(
                onPressed: model.saving
                    ? null
                    : () => widget.controller.pickAndUploadAvatar(
                        DevicePostPhotoService(),
                      ),
                child: const Text('사진 변경'),
              ),
              Text(
                current?.handle == null ? '아이디 없음' : '@${current!.handle}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PindTheme.ink,
                ),
              ),
              Text(
                '아이디는 변경할 수 없어요',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: name,
                maxLength: 40,
                decoration: const InputDecoration(labelText: '닉네임'),
              ),
              TextFormField(
                controller: bio,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: '상태 메시지',
                  hintText: '📍 서울 성수동 여행 중',
                ),
              ),
              if (model.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    model.error!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: model.saving ? null : save,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
