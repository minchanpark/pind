import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../services/image_disk_cache.dart';

import '../model/app_model.dart';
import '../model/profile_link.dart';
import '../model/taste_profile.dart';
import '../model/preferences.dart';
import '../services/nearby_ranking_service.dart';
import '../services/discover_service.dart';
import '../services/friends_service.dart';
import '../services/place_context_service.dart';
import '../services/place_service.dart';
import '../services/preference_service.dart';
import 'explore_controller.dart';
import 'registration_controller.dart';
import '../services/auth_service.dart';
import '../services/registration_service.dart';
import '../services/post_service.dart';
import '../services/post_photo_service.dart';
import '../services/profile_service.dart';
import '../services/post_media_urls.dart';
import '../services/data_revision.dart';

class AppController {
  AppController(
    this.preferences, {
    PlaceService? places,
    PlaceContextService? placeContext,
    NearbyRanking? nearby,
    this.posts,
    this.profile,
    this.discover,
    this.friends,
    AuthService? auth,
    RegistrationService? registrationService,
    bool allowPreview = false,
    Stream<Uri>? links,
    Future<Uri?>? initialLink,
  }) : model = AppModel(
         registrationService == null
             ? preferences.load()
             : auth?.identity == null
             ? null
             : preferences.forUser(auth!.identity!.id).load(),
       ),
       explore = places == null
           ? null
           : ExploreController(
               places,
               placeContext: placeContext,
               profile: profile,
               nearby: nearby,
               setLiked: discover?.setLiked,
               deletePost: posts?.delete,
             ) {
    if (registrationService != null) {
      registration = RegistrationController(
        auth: auth ?? UnavailableAuthService(),
        storage: registrationService,
        allowPreview: allowPreview,
        onComplete: savePreferences,
        profile: profile,
        photos: DevicePostPhotoService(),
      );
    }
    // Existing installs only have the priorities on the device.
    _userId = auth?.identity?.id;
    unawaited(ImageDiskCache.shared.switchAccount(_userId ?? 'signed-out'));
    registration?.model.addListener(_registrationChanged);
    _syncTaste();
    _changes = dataChanges.stream.listen((_) => _loadTaste());
    _loadTaste();
    if (links != null) _listen(links, initialLink);
  }

  final PreferenceService preferences;
  final AppModel model;

  /// Logs out; the login screen follows from the auth change. Uses the
  /// registration's auth, the one session the app tracks.
  Future<void> signOut() async => registration?.auth.signOut();
  final ExploreController? explore;
  final PostService? posts;
  final ProfileService? profile;
  final DiscoverService? discover;
  final FriendsService? friends;
  RegistrationController? registration;
  bool _disposed = false;
  String? _userId;
  bool _tasteSynced = false;
  StreamSubscription<void>? _changes;
  int _tasteRequest = 0;

  void _registrationChanged() {
    final id = registration?.auth.identity?.id;
    if (id != _userId) {
      _userId = id;
      _tasteSynced = false;
      clearSignedPhotoUrls();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      unawaited(ImageDiskCache.shared.switchAccount(id ?? 'signed-out'));
      explore?.resetForAccount();
      model.setPreferences(id == null ? null : preferences.forUser(id).load());
      myTaste.value = null;
      _loadTaste();
    }
    _syncTaste();
  }

  /// My taste stars for place %. My ratings and saves move them, so every
  /// data change reloads; a failure keeps the last copy.
  // ponytail: one RPC per data change (place views included); debounce if
  // get_my_taste shows up in load.
  Future<void> _loadTaste() async {
    final id = _userId, friends = this.friends;
    if (friends == null || (registration != null && id == null)) return;
    final request = ++_tasteRequest;
    try {
      final taste = await friends.myTaste();
      if (!_disposed && request == _tasteRequest && id == _userId) {
        myTaste.value = taste;
      }
    } catch (_) {
      /* Place % stays as it was; the next change retries. */
    }
  }

  /// Profile link waiting for MainShell, which takes it (sets null) once
  /// the user is past login/onboarding.
  final link = ValueNotifier<ProfileLink?>(null);
  StreamSubscription<Uri>? _links;

  void _listen(Stream<Uri> links, Future<Uri?>? initialLink) {
    // Auth callbacks and anything else stay with supabase_flutter.
    void receive(Uri uri) {
      final parsed = ProfileLink.parse(uri.toString());
      if (parsed != null && !_disposed) link.value = parsed;
    }

    // The cold-start link can reach both the stream and getInitialLink, or
    // only one when supabase subscribed first; open it once.
    Uri? initial, firstStreamed;
    var streamed = false;
    _links = links.listen((uri) {
      if (!streamed) {
        streamed = true;
        firstStreamed = uri;
        if (uri == initial) return;
      }
      receive(uri);
    }, onError: (_) {});
    initialLink?.then((uri) {
      if (uri == null || uri == firstStreamed) return;
      initial = uri;
      receive(uri);
    }, onError: (_) {});
  }

  Future<void> savePreferences(TastePreferences value) async {
    final id = _userId;
    if (registration != null && id == null) return;
    await (registration == null ? preferences : preferences.forUser(id!)).save(
      value,
    );
    if (_disposed || id != _userId) return;
    model.setPreferences(value);
    _tasteSynced = false;
    _syncTaste();
  }

  /// Best effort: the device copy stays the source of truth, and the next
  /// launch or edit retries.
  void _syncTaste() {
    final value = model.preferences;
    if (_tasteSynced ||
        friends == null ||
        value == null ||
        !value.isComplete ||
        (registration != null &&
            (!registration!.model.completed ||
                registration!.model.identity?.id != _userId))) {
      return;
    }
    _tasteSynced = true;
    final id = _userId;
    unawaited(
      friends!
          .saveTaste(
            value,
            discoverable:
                registration?.model.draft.recommendationConsent ?? false,
          )
          .catchError((_) {
            if (!_disposed && id == _userId) _tasteSynced = false;
          }),
    );
  }

  void dispose() {
    _disposed = true;
    _links?.cancel();
    _changes?.cancel();
    myTaste.value = null;
    link.dispose();
    registration?.model.removeListener(_registrationChanged);
    registration?.dispose();
    explore?.dispose();
    model.dispose();
  }
}
