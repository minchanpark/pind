import 'dart:async';

import '../services/request_client.dart';

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
import '../l10n/l10n.dart';

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
  Completer<void>? _publishAbort;
  bool get canCancelPublish =>
      model.publishing &&
      model.uploadProgress < 1 &&
      posts is ProgressPostService;
  void cancelPublish() {
    if (canCancelPublish && _publishAbort?.isCompleted == false) {
      _publishAbort!.complete();
    }
  }

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

  void setPublic(bool value) {
    if (_disposed || model.publishing) return;
    model.update(() => model.isPublic = value);
  }

  void removePhoto(int index) {
    if (_disposed || model.publishing || model.pickingPhotos) return;
    model.update(() => model.photos.removeAt(index));
  }

  /// A shot from the in-app camera.
  void addPhoto(PostPhoto photo) {
    if (_disposed ||
        model.publishing ||
        model.pickingPhotos ||
        model.photos.length >= 10) {
      return;
    }
    if (model.photos.fold<int>(0, (sum, p) => sum + p.bytes.length) +
            photo.bytes.length >
        maxPostPhotoBytes) {
      model.update(() => model.error = l10n.errPhotosTotalSize);
      return;
    }
    model.update(() {
      model.photos.add(photo);
      model.error = null;
    });
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
      final next = selected.take(10 - model.photos.length).toList();
      if ([
            ...model.photos,
            ...next,
          ].fold<int>(0, (sum, p) => sum + p.bytes.length) >
          maxPostPhotoBytes) {
        model.error = l10n.errPhotosTotalSize;
      } else {
        model.photos.addAll(next);
      }
    } catch (error) {
      if (!_disposed) {
        model.error = error is PlaceFailure ? error.message : l10n.errPhotoLoad;
      }
    } finally {
      if (!_disposed) model.update(() => model.pickingPhotos = false);
    }
  }

  Future<List<Place>> searchPlaces(String query, {MapViewport? near}) async {
    if (places == null) throw PlaceFailure(l10n.errPlaceSearchSignIn);
    return (await places!.search(
      query,
      near: near,
    )).where((p) => p.isCatalog && p.id != null).toList();
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
      model.uploadProgress = 0;
      model.error = null;
    });
    try {
      _publishAbort = Completer<void>();
      final service = posts;
      final saved = await withRequestCancellation(
        _publishAbort!.future,
        () => service is ProgressPostService
            ? service.publishWithProgress(draft, requestId, authorId, (
                progress,
              ) {
                if (!_disposed) {
                  model.update(() => model.uploadProgress = progress);
                }
              })
            : service.publish(draft, requestId, authorId),
      );
      return _disposed ? null : saved;
    } catch (error) {
      if (!_disposed) {
        model.error = error is PlaceFailure
            ? error.message
            : l10n.errPostPublish;
      }
      return null;
    } finally {
      _publishAbort = null;
      if (!_disposed) model.update(() => model.publishing = false);
    }
  }

  void dispose() {
    cancelPublish();
    _disposed = true;
    model.dispose();
  }
}
