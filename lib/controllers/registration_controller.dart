import 'dart:async';

import '../model/place_search_result.dart';
import '../model/preferences.dart';
import '../model/registration_model.dart';
import '../services/auth_service.dart';
import '../services/registration_service.dart';
import '../services/location_service.dart';
import '../services/post_photo_service.dart';
import '../services/profile_service.dart';

class RegistrationController {
  RegistrationController({
    required this.auth,
    required this.storage,
    required this.onComplete,
    this.allowPreview = false,
    this.requestPermission = LocationService.requestPermission,
    this.openSettings = LocationService.openSettings,
    this.profile,
    this.photos,
  }) {
    final identity = auth.identity;
    if (identity != null &&
        (!identity.development ||
            (allowPreview && storage.load(identity.id)?.completed == true))) {
      _accept(identity);
      // A restored social session is an existing account: skip profile setup.
      if (!identity.development) {
        model.draft = model.draft.copyWith(completed: true);
      }
    }
    _subscription = auth.changes.listen((identity) {
      if (_disposed) return;
      if (identity == null) {
        model.update(() {
          model.identity = null;
          model.tasteDraft = null;
          model.draft = const RegistrationDraft();
          model.step = RegistrationStep.login;
        });
      } else if (!identity.development || _previewRequested) {
        if (identity.id != model.identity?.id ||
            model.step == RegistrationStep.login) {
          _accept(identity);
        }
      }
    });
  }
  final AuthService auth;
  final RegistrationService storage;
  final Future<void> Function(TastePreferences) onComplete;
  final bool allowPreview;
  final Future<RegistrationPermission> Function() requestPermission;
  final Future<bool> Function() openSettings;
  final ProfileService? profile;
  final PostPhotoService? photos;
  final model = RegistrationModel();
  late final StreamSubscription<AuthIdentity?> _subscription;
  bool _disposed = false, _previewRequested = false;

  void _accept(AuthIdentity identity) => model.update(() {
    model.identity = identity;
    model.tasteDraft = null;
    model.draft = storage.load(identity.id) ?? const RegistrationDraft();
    model.step = model.draft.step;
    model.countryQuery = '';
    model.error = null;
  });

  Future<void> signIn(LoginProvider provider) async {
    if (model.busy) return;
    model.update(() {
      model.busy = true;
      model.signingIn = provider;
      model.error = null;
    });
    try {
      // Opening OAuth is not authentication. Only the auth-state event advances.
      await auth.signIn(provider);
    } catch (_) {
      if (!_disposed) {
        model.update(() => model.error = '로그인을 완료하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (!_disposed) {
        model.update(() {
          model.busy = false;
          model.signingIn = null;
        });
      }
    }
  }

  Future<void> preview() async {
    if (!allowPreview || model.busy) return;
    _previewRequested = true;
    model.update(() {
      model.busy = true;
      model.error = null;
    });
    try {
      final identity = await auth.preview();
      if (!_disposed) _accept(identity);
    } catch (_) {
      if (!_disposed) {
        model.update(() => model.error = '체험을 시작하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (!_disposed) model.update(() => model.busy = false);
    }
  }

  Future<void> pickAvatar() async {
    if (model.busy || _disposed) return;
    final profile = this.profile, photos = this.photos;
    if (profile == null || photos == null) {
      model.update(() => model.error = '프로필 서버에 연결하지 못했어요.');
      return;
    }
    model.update(() {
      model.busy = true;
      model.error = null;
    });
    try {
      final selected = await photos.pick(1);
      if (selected.isEmpty || _disposed) return;
      final url = await profile.uploadAvatar(selected.first);
      if (!_disposed) model.draft = model.draft.copyWith(avatarUrl: url);
    } catch (error) {
      if (!_disposed) {
        model.error = error is PlaceFailure
            ? error.message
            : '사진을 올리지 못했어요. 다시 시도해 주세요.';
      }
    } finally {
      if (!_disposed) model.update(() => model.busy = false);
    }
  }

  void edit(RegistrationDraft draft) {
    if (model.busy) return;
    model.update(() {
      model.draft = draft;
      model.error = null;
    });
  }

  void searchCountries(String query) =>
      model.update(() => model.countryQuery = query);

  void editTastes(TastePreferences value) {
    if (_disposed || model.busy) return;
    model.update(() => model.tasteDraft = value);
  }

  List<OnboardingCountry> get countries => OnboardingCountry.values
      .where(
        (c) => '${c.label} ${c.subtitle} ${c.name}'.toLowerCase().contains(
          model.countryQuery.trim().toLowerCase(),
        ),
      )
      .toList();

  void back() {
    if (model.busy || model.step == RegistrationStep.login) return;
    model.update(() {
      model.step = RegistrationStep.values[model.step.index - 1];
      model.error = null;
    });
  }

  Future<void> next() async {
    if (model.busy || !model.canContinue) return;
    await _advance(RegistrationStep.values[model.step.index + 1]);
  }

  Future<void> _advance(RegistrationStep step) async {
    final identity = model.identity;
    if (identity == null) return;
    model.update(() {
      model.busy = true;
      model.error = null;
    });
    final draft = model.draft.copyWith(step: step);
    try {
      if (model.step == RegistrationStep.handle &&
          profile != null &&
          !identity.development) {
        await profile!.save(
          handle: draft.handle,
          displayName: draft.name.trim(),
          avatarUrl: draft.avatarUrl,
        );
      }
      await storage.save(identity.id, draft);
      if (!_disposed && model.identity?.id == identity.id) {
        model.update(() {
          model.draft = draft;
          model.step = step;
        });
      }
    } on PlaceFailure catch (e) {
      if (!_disposed) model.update(() => model.error = e.message);
    } catch (_) {
      if (!_disposed) {
        model.update(() => model.error = '입력 내용을 저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (!_disposed) model.update(() => model.busy = false);
    }
  }

  Future<void> allowLocation() async {
    if (model.busy) return;
    final userId = model.identity?.id;
    model.update(() {
      model.busy = true;
      model.error = null;
    });
    var allowed = false;
    try {
      final permission = await requestPermission();
      if (_disposed || model.identity?.id != userId) return;
      allowed = permission == RegistrationPermission.allowed;
      model.update(() {
        model.permissionBlocked = permission == RegistrationPermission.blocked;
        if (!allowed) model.error = '위치를 허용하지 않아도 검색으로 시작할 수 있어요.';
        model.draft = model.draft.copyWith(locationAllowed: allowed);
      });
    } catch (_) {
      if (!_disposed) {
        model.update(() => model.error = '위치 권한을 확인하지 못했어요. 나중에 설정할 수 있어요.');
      }
    } finally {
      if (!_disposed) model.update(() => model.busy = false);
    }
    if (!_disposed && model.identity?.id == userId && allowed) {
      await _advance(RegistrationStep.taste);
    }
  }

  Future<void> showLocationSettings() async {
    try {
      final opened = await openSettings();
      if (!_disposed && !opened) {
        model.update(() => model.error = '설정을 열지 못했어요. 기기 설정에서 위치를 허용해 주세요.');
      }
    } catch (_) {
      if (!_disposed) {
        model.update(() => model.error = '설정을 열지 못했어요. 기기 설정에서 위치를 허용해 주세요.');
      }
    }
  }

  Future<void> skipLocation() async {
    if (model.busy) return;
    edit(model.draft.copyWith(locationAllowed: false));
    await _advance(RegistrationStep.taste);
  }

  Future<void> complete(TastePreferences preferences) async {
    if (model.busy || _disposed) return;
    final identity = model.identity;
    if (identity == null ||
        !model.draft.basicValid(DateTime.now()) ||
        !model.draft.handleValid ||
        !preferences.isComplete) {
      throw StateError('입력 내용을 확인해 주세요.');
    }
    final draft = model.draft.copyWith(completed: true);
    model.update(() => model.busy = true);
    try {
      await onComplete(preferences);
      if (_disposed || model.identity?.id != identity.id) return;
      await storage.save(identity.id, draft);
      if (!_disposed && model.identity?.id == identity.id) {
        model.update(() => model.draft = draft);
      }
    } finally {
      if (!_disposed) model.update(() => model.busy = false);
    }
  }

  void dispose() {
    _disposed = true;
    _subscription.cancel();
    model.dispose();
  }
}
