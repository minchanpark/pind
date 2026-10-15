import 'package:flutter/foundation.dart';

import 'places.dart';

/// The map's top chips: every pin, places people I follow posted at, or
/// places I saved.
enum MapScope { all, friends, saved }

class ExploreModel extends ChangeNotifier {
  List<Place> places = [];
  bool loading = false;
  bool locating = false;
  String? error;
  String? notice;
  bool googleSearchEnabled = false;

  /// Where 길찾기 is walking me; null when not guiding.
  Place? walkingTo;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
