import 'package:flutter/foundation.dart';

import 'place_context.dart';
import 'places.dart';

class PlaceDetailModel extends ChangeNotifier {
  PlaceDetailModel(this.place);

  Place place;
  PlaceContext? social;
  bool loading = true;
  bool detailError = false;
  bool contextError = false;
  bool saving = false;
  bool saved = false;
  bool locating = false;
  bool searchingGoogle = false;
  double? distance;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
