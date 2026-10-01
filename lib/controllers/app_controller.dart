import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/app_model.dart';
import '../model/profile_link.dart';
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
  }) : model = AppModel(preferences.load()),
       explore = places == null
           ? null
           : ExploreController(
               places,
               placeContext: placeContext,
               profile: profile,
               nearby: nearby,
               setLiked: discover?.setLiked,
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
    _syncTaste();
    if (links != null) _listen(links, initialLink);
  }

  final PreferenceService preferences;
  final AppModel model;
  final ExploreController? explore;
  final PostService? posts;
  final ProfileService? profile;
  final DiscoverService? discover;
  final FriendsService? friends;
  RegistrationController? registration;
  bool _disposed = false;

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
    await preferences.save(value);
    if (!_disposed) model.setPreferences(value);
    _syncTaste();
  }

  /// Best effort: the device copy stays the source of truth, and the next
  /// launch or edit retries.
  void _syncTaste() {
    final value = model.preferences;
    if (friends == null || value == null || !value.isComplete) return;
    unawaited(
      friends!
          .saveTaste(
            value,
            discoverable:
                registration?.model.draft.recommendationConsent ?? false,
          )
          .catchError((_) {}),
    );
  }

  void dispose() {
    _disposed = true;
    _links?.cancel();
    link.dispose();
    registration?.dispose();
    explore?.dispose();
    model.dispose();
  }
}
