import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/preferences.dart';
import '../l10n/l10n.dart';

/// P0 device draft only. Server onboarding completion is a separate P1 contract.
class PreferenceService {
  PreferenceService(this.storage, {this.userId});
  final SharedPreferences storage;
  final String? userId;
  static const key = 'pind.taste-draft.v1';
  String get storageKey => userId == null ? key : '$key.$userId';
  PreferenceService forUser(String userId) =>
      PreferenceService(storage, userId: userId);

  TastePreferences? load() {
    final raw = storage.getString(storageKey);
    if (raw == null) return null;
    try {
      return TastePreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Corrupt/old local drafts must not prevent launching the app.
      return null;
    }
  }

  Future<void> save(TastePreferences preferences) async {
    if (!preferences.isComplete) {
      throw StateError('Incomplete taste preferences');
    }
    if (!await storage.setString(
      storageKey,
      jsonEncode(preferences.toJson()),
    )) {
      throw StateError(l10n.errTasteSave);
    }
  }
}
