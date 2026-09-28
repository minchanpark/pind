import 'package:flutter/foundation.dart';

import 'places.dart';
import 'preferences.dart';

class PostPhoto {
  const PostPhoto({required this.bytes, required this.mimeType});
  final Uint8List bytes;
  final String mimeType;
  String get extension => switch (mimeType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/heic' => 'heic',
    'image/heif' => 'heif',
    _ => 'jpg',
  };
}

class PostDraft {
  PostDraft({
    required this.place,
    required List<PostPhoto> photos,
    required Map<PreferenceCriterion, int> ratings,
    required this.body,
  }) : photos = List.unmodifiable(photos),
       ratings = Map.unmodifiable(ratings);
  final Place place;
  final List<PostPhoto> photos;
  final Map<PreferenceCriterion, int> ratings;
  final String body;
}

class PublishedPost {
  const PublishedPost({required this.id, required this.placeId});
  final int id, placeId;
  factory PublishedPost.fromJson(Map<String, dynamic> json) => PublishedPost(
    id: (json['id'] as num).toInt(),
    placeId: (json['placeId'] as num).toInt(),
  );
}

class PostModel extends ChangeNotifier {
  PostModel(this.criteria);

  /// The author's three onboarding priorities, rated in this order.
  final List<PreferenceCriterion> criteria;
  Place? place;
  final List<PostPhoto> photos = [];
  final Map<PreferenceCriterion, int> ratings = {};
  String body = '';
  bool pickingPhotos = false, publishing = false;
  String? error;

  int get bodyLength => body.runes.length;
  bool get canPublish =>
      !pickingPhotos &&
      !publishing &&
      place?.isCatalog == true &&
      place?.id != null &&
      photos.isNotEmpty &&
      photos.length <= 10 &&
      criteria.every(
        (axis) => (ratings[axis] ?? 0) >= 1 && (ratings[axis] ?? 0) <= 5,
      ) &&
      bodyLength <= 200;
  int? get average => criteria.every(ratings.containsKey)
      ? (criteria.map((c) => ratings[c]!).reduce((a, b) => a + b) /
                criteria.length)
            .round()
      : null;
  PostDraft get draft => PostDraft(
    place: place!,
    photos: photos,
    ratings: {for (final c in criteria) c: ratings[c]!},
    body: body,
  );
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
