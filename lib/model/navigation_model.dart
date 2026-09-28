import 'package:flutter/foundation.dart';

enum PindTab { discover, map, profile }

class NavigationModel extends ChangeNotifier {
  PindTab selected = PindTab.map;
  bool composing = false;

  void select(PindTab tab) {
    if (selected == tab) return;
    selected = tab;
    notifyListeners();
  }
}
