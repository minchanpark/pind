import '../model/app_model.dart';
import '../model/preferences.dart';
import '../services/place_context_service.dart';
import '../services/place_service.dart';
import '../services/preference_service.dart';
import 'explore_controller.dart';

class AppController {
  AppController(
    this.preferences, {
    PlaceService? places,
    PlaceContextService? placeContext,
  }) : model = AppModel(preferences.load()),
       explore = places == null
           ? null
           : ExploreController(places, placeContext: placeContext);

  final PreferenceService preferences;
  final AppModel model;
  final ExploreController? explore;
  bool _disposed = false;

  Future<void> savePreferences(TastePreferences value) async {
    await preferences.save(value);
    if (!_disposed) model.setPreferences(value);
  }

  void dispose() {
    _disposed = true;
    explore?.dispose();
    model.dispose();
  }
}
