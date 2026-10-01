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
  double? distance;

  /// Posts whose heart I toggled here, by post id; they win over [place].
  final likes = <int, PlacePost>{};

  /// [post] with any like toggled in this sheet.
  PlacePost shown(PlacePost post) => likes[post.id] ?? post;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
