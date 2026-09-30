import 'package:uuid/uuid.dart';

import '../model/post_model.dart';
import '../model/places.dart';
import '../model/preferences.dart';
import '../model/place_search_result.dart';
import '../model/profile_model.dart';
import '../services/location_service.dart';
import '../services/place_service.dart';
import '../services/post_service.dart';
import '../services/post_photo_service.dart';

class PostController {
  PostController({
    required this.posts,
    required this.photos,
    this.places,
    this.mine,
    this.position = LocationService.position,
    Place? place,
    List<PreferenceCriterion>? criteria,
  }) : authorId = posts.userId,
       model = PostModel(
         criteria?.length == 3 ? List.unmodifiable(criteria!) : defaultCriteria,
       ) {
    if (place?.isCatalog == true && place?.id != null) model.place = place;
  }
  final PostService posts;
  final PostPhotoService photos;
  final PlaceService? places;

  /// My Page's overview as last loaded: the picker's 최근 방문 / 저장한 곳.
  final ProfileOverview? Function()? mine;

  /// `request` asks for permission when it hasn't been decided yet.
  final Future<MapViewport?> Function(bool request) position;
  final String? authorId;
  final PostModel model;

  /// Used when the account has no saved onboarding priorities.
  static const defaultCriteria = [
    PreferenceCriterion.taste,
    PreferenceCriterion.portion,
    PreferenceCriterion.ambience,
  ];
  final String requestId = const Uuid().v4();
  bool _disposed = false;

  void selectPlace(Place value) {
    if (_disposed || model.publishing || !value.isCatalog || value.id == null) {
      return;
    }
    model.update(() {
      model.place = value;
      model.error = null;
    });
  }

  void rate(PreferenceCriterion axis, int score) {
    if (_disposed ||
        model.publishing ||
        !model.criteria.contains(axis) ||
        score < 1 ||
        score > 5) {
      return;
    }
    model.update(() {
      model.ratings[axis] = score;
      model.error = null;
    });
  }

  void setBody(String value) {
    if (_disposed || model.publishing) return;
    model.update(() {
      model.body = value;
      model.error = null;
    });
  }

  void removePhoto(int index) {
    if (_disposed || model.publishing || model.pickingPhotos) return;
    model.update(() => model.photos.removeAt(index));
  }

  Future<void> addPhotos() async {
    if (_disposed ||
        model.publishing ||
        model.pickingPhotos ||
        model.photos.length >= 10) {
      return;
    }
    model.update(() {
      model.pickingPhotos = true;
      model.error = null;
    });
    try {
      final selected = await photos.pick(10 - model.photos.length);
      if (_disposed) return;
      model.photos.addAll(selected.take(10 - model.photos.length));
    } catch (error) {
      if (!_disposed) {
        model.error = error is PlaceFailure ? error.message : '사진을 불러오지 못했어요.';
      }
    } finally {
      if (!_disposed) model.update(() => model.pickingPhotos = false);
    }
  }

  Future<List<Place>> searchPlaces(String query) async {
    if (places == null) throw const PlaceFailure('로그인 후 식당을 검색해 주세요.');
    return (await places!.search(query))
        .where((p) => p.isCatalog && p.id != null)
        .toList();
  }

  /// Null when location is off, denied or times out.
  Future<MapViewport?> currentPosition({bool request = false}) async {
    try {
      return await position(request);
    } catch (_) {
      return null;
    }
  }

  Future<PublishedPost?> publish() async {
    if (_disposed || !model.canPublish) return null;
    final draft = model.draft;
    model.update(() {
      model.publishing = true;
      model.error = null;
    });
    try {
      final saved = await posts.publish(draft, requestId, authorId);
      return _disposed ? null : saved;
    } catch (error) {
      if (!_disposed) {
        model.error = error is PlaceFailure ? error.message : '게시물을 등록하지 못했어요.';
      }
      return null;
    } finally {
      if (!_disposed) model.update(() => model.publishing = false);
    }
  }

  void dispose() {
    _disposed = true;
    model.dispose();
  }
}
