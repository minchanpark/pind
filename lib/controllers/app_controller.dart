import '../model/app_model.dart';
import '../model/preferences.dart';
import '../services/place_context_service.dart';
import '../services/place_service.dart';
import '../services/preference_service.dart';
import 'explore_controller.dart';
import 'registration_controller.dart';
import '../services/auth_service.dart';
import '../services/registration_service.dart';
import '../services/post_service.dart';

class AppController {
  AppController(
    this.preferences, {
    PlaceService? places,
    PlaceContextService? placeContext,
    this.posts,
    AuthService? auth,
    RegistrationService? registrationService,
    bool allowPreview = false,
  }) : model = AppModel(preferences.load()),
       explore = places == null
           ? null
           : ExploreController(places, placeContext: placeContext) {
    if (registrationService != null) {
      registration = RegistrationController(
        auth: auth ?? UnavailableAuthService(),
        storage: registrationService,
        allowPreview: allowPreview,
        onComplete: savePreferences,
      );
    }
  }

  final PreferenceService preferences;
  final AppModel model;
  final ExploreController? explore;
  final PostService? posts;
  RegistrationController? registration;
  bool _disposed = false;

  Future<void> savePreferences(TastePreferences value) async {
    await preferences.save(value);
    if (!_disposed) model.setPreferences(value);
  }

  void dispose() {
    _disposed = true;
    registration?.dispose();
    explore?.dispose();
    model.dispose();
  }
}
