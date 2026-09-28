import 'package:flutter/foundation.dart';

import 'places.dart';

class ExploreModel extends ChangeNotifier {
  List<Place> places = [];
  bool loading = false;
  bool locating = false;
  String? error;
  String? notice;
  bool googleSearchEnabled = false;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
