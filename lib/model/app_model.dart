import 'package:flutter/foundation.dart';

import 'preferences.dart';

class AppModel extends ChangeNotifier {
  AppModel(this.preferences);

  TastePreferences? preferences;

  void setPreferences(TastePreferences value) {
    preferences = value;
    notifyListeners();
  }
}
