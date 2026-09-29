import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pind_flutter/services/config.dart';
import 'package:pind_flutter/services/place_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('deployed catalog keeps unposted search results off the map', (
    _,
  ) async {
    expect(AppConfig.hasBackend, true, reason: 'Run with config/local.json');
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.publishableKey,
    );
    addTearDown(Supabase.instance.dispose);
    final client = Supabase.instance.client;
    expect(
      client.auth.currentSession,
      isNotNull,
      reason: 'Requires an existing local signed-in session; creates no test account',
    );
    // Read only: use the existing session and never publish or create users.
    final places = PlaceService((body) async {
      final result = await client.functions.invoke('places', body: body);
      return Map<String, dynamic>.from(result.data as Map);
    });
    final nearby = await places.posted();
    expect(
      nearby.every(
        (place) => (place.pindPostCount ?? 0) > 0 && place.canShowOnMap,
      ),
      true,
    );
    final search = await places.search('포항');
    expect(search, isNotEmpty);
    final unposted = search.where((place) => place.pindPostCount == 0);
    expect(unposted, isNotEmpty);
    expect(unposted.every((place) => !place.canShowOnMap), true);
  });
}
