import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'view/app.dart';
import 'controllers/app_controller.dart';
import 'services/config.dart';
import 'services/discover_service.dart';
import 'services/friends_service.dart';
import 'services/place_service.dart';
import 'services/place_context_service.dart';
import 'services/preference_service.dart';
import 'services/auth_service.dart';
import 'services/registration_service.dart';
import 'services/post_service.dart';
import 'services/profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await SharedPreferences.getInstance();
  final preferences = PreferenceService(storage);
  AuthService auth = UnavailableAuthService();
  PlaceService? places;
  PlaceContextService? placeContext;
  PostService? posts;
  ProfileService? profile;
  DiscoverService? discover;
  FriendsService? friends;
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
    posts = SupabasePostService(Supabase.instance.client);
    profile = SupabaseProfileService(Supabase.instance.client);
    discover = SupabaseDiscoverService(Supabase.instance.client);
    friends = SupabaseFriendsService(Supabase.instance.client);
    auth = SupabaseAuthService(
      Supabase.instance.client,
      redirectTo: AppConfig.authRedirectUrl,
      allowAnonymous: AppConfig.allowAnonymous,
    );
  }
  runApp(
    PindApp(
      controller: AppController(
        preferences,
        places: places,
        placeContext: placeContext,
        posts: posts,
        profile: profile,
        discover: discover,
        friends: friends,
        auth: auth,
        registrationService: RegistrationService(storage),
        allowPreview:
            kDebugMode && (!AppConfig.hasBackend || AppConfig.allowAnonymous),
        links: AppLinks().uriLinkStream,
        initialLink: AppLinks().getInitialLink(),
      ),
      mapsEnabled: AppConfig.hasMap,
    ),
  );
}
