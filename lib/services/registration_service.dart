import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/registration_model.dart';

/// Device drafts only. These records do not represent server registration,
/// handle uniqueness or a server-verified consent receipt.
class RegistrationService {
  RegistrationService(this.storage);
  final SharedPreferences storage;
  String _key(String userId) => 'pind.registration-draft.v1.$userId';

  RegistrationDraft? load(String userId) {
    try {
      final raw = storage.getString(_key(userId));
      if (raw == null) return null;
      return RegistrationDraft.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String userId, RegistrationDraft draft) async {
    if (!await storage.setString(_key(userId), jsonEncode(draft.toJson()))) {
      throw StateError('입력 내용을 저장하지 못했어요. 다시 시도해 주세요.');
    }
  }
}
