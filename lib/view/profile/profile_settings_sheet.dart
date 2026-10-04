import 'package:flutter/material.dart';

import '../../controllers/profile_controller.dart';
import '../../services/post_photo_service.dart';
import '../components/pind_glass.dart';
import '../components/pind_sheet.dart';
import '../design_system.dart';
import 'profile_screen.dart';
import '../../l10n/l10n.dart';

/// Behind My Page's ⚙︎: photo, nickname and status message, in the app's
/// standard sheet.
Future<void> showProfileSettingsSheet(
  BuildContext context,
  ProfileController controller, {
  Future<void> Function()? onSignOut,
}) => showPindSheet<void>(
  context,
  builder: (_) => _SettingsSheet(controller, onSignOut),
);

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet(this.controller, this.onSignOut);
  final ProfileController controller;
  final Future<void> Function()? onSignOut;
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

  /// Asks first, then closes this sheet and signs out.
  Future<void> confirmSignOut(Future<void> Function() signOut) async {
    final sure =
        await showPindSheet<bool>(
          context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Text(
                l10n.signOutTitle,
                textAlign: TextAlign.center,
                style: PindText.title,
              ),
              Text(
                l10n.signOutBody,
                textAlign: TextAlign.center,
                style: PindText.caption,
              ),
              const SizedBox(height: 8),
              PindSheetButton(
                l10n.signOut,
                tone: PindSheetButtonTone.danger,
                onTap: () => Navigator.pop(context, true),
              ),
              PindSheetButton(
                l10n.close,
                onTap: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ) ??
        false;
    if (!sure || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    try {
      await signOut();
    } catch (error) {
      debugPrint('sign out failed: $error');
      messenger.showSnackBar(SnackBar(content: Text(l10n.errSignOut)));
    }
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
          Text(
            l10n.profileSettings,
            textAlign: TextAlign.center,
            style: PindText.title,
          ),
          const SizedBox(height: 18),
          Center(
            child: Semantics(
              button: true,
              label: l10n.changePhoto,
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
            current?.handle == null ? l10n.noHandle : '@${current!.handle}',
            textAlign: TextAlign.center,
            style: PindText.body.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.handleLocked,
            textAlign: TextAlign.center,
            style: PindText.caption,
          ),
          const SizedBox(height: 24),
          PindTextField(label: l10n.name, controller: name, maxLength: 40),
          const SizedBox(height: 16),
          PindTextField(
            label: l10n.statusMessage,
            controller: bio,
            maxLength: 80,
            hint: l10n.statusHint,
          ),
          if (model.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                model.error!,
                textAlign: TextAlign.center,
                style: PindText.caption.copyWith(color: PindColors.pink),
              ),
            ),
          const SizedBox(height: 24),
          PindSheetButton(
            l10n.save,
            tone: PindSheetButtonTone.primary,
            onTap: model.saving ? null : save,
          ),
          const SizedBox(height: 10),
          PindSheetButton(l10n.close, onTap: () => Navigator.of(context).pop()),
          if (widget.onSignOut case final signOut?) ...[
            const SizedBox(height: 18),
            Center(
              child: TextButton(
                key: const ValueKey('profile-sign-out'),
                onPressed: model.saving ? null : () => confirmSignOut(signOut),
                child: Text(
                  l10n.signOut,
                  style: PindText.caption.copyWith(
                    color: PindColors.subtle,
                    decoration: TextDecoration.underline,
                    decorationColor: PindColors.subtle,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
