import 'package:flutter/foundation.dart';

import 'preferences.dart';

class OnboardingModel extends ChangeNotifier {
  OnboardingModel(TastePreferences? initial)
    : preferences = initial ?? TastePreferences();

  TastePreferences preferences;
  int step = 0;
  bool saving = false;
  String? error;

  bool get canContinue => step == 0
      ? preferences.priorities.length == 3
      : step == 1 || preferences.isComplete;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
