import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'view/app.dart';
import 'controllers/app_controller.dart';
import 'services/config.dart';
import 'services/place_service.dart';
import 'services/place_context_service.dart';
import 'services/preference_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = PreferenceService(await SharedPreferences.getInstance());
  PlaceService? places;
  PlaceContextService? placeContext;
  if (AppConfig.hasBackend) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.publishableKey,
    );
    final gateway = SupabasePlacesGateway(
      Supabase.instance.client,
      allowAnonymous: AppConfig.allowAnonymous,
    );
    places = PlaceService(gateway.call);
    placeContext = SupabasePlaceContextService(Supabase.instance.client);
  }
  runApp(
    PindApp(
      controller: AppController(
        preferences,
        places: places,
        placeContext: placeContext,
      ),
      mapsEnabled: AppConfig.hasMap,
    ),
  );
}
