import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/registration_model.dart';
import '../l10n/l10n.dart';

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
      throw StateError(l10n.errDraftSave);
    }
  }
}
