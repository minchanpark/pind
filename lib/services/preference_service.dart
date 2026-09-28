import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/preferences.dart';

/// P0 device draft only. Server onboarding completion is a separate P1 contract.
class PreferenceService {
  PreferenceService(this.storage);
  final SharedPreferences storage;
  static const key = 'pind.taste-draft.v1';

  TastePreferences? load() {
    final raw = storage.getString(key);
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
    if (!await storage.setString(key, jsonEncode(preferences.toJson()))) {
      throw StateError('취향을 저장하지 못했어요. 다시 시도해 주세요.');
    }
  }
}
