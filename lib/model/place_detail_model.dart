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

  /// Posts I deleted from this sheet; hidden until the next detail load.
  final deleted = <int>{};

  /// [Place.posts] minus the ones I deleted here, likes applied.
  List<PlacePost> get posts => [
    for (final p in place.posts)
      if (!deleted.contains(p.id)) shown(p),
  ];

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
