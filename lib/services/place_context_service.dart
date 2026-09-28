import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/place_context.dart';

abstract interface class PlaceContextService {
  Future<PlaceContext> load(int placeId);
  Future<void> setSaved(int placeId, bool saved);
}

class SupabasePlaceContextService implements PlaceContextService {
  SupabasePlaceContextService(this.client);
  final SupabaseClient client;
  @override
  Future<PlaceContext> load(int placeId) async => PlaceContext.fromJson(
    Map<String, dynamic>.from(
      await client.rpc(
        'get_place_detail_context',
        params: {'p_place_id': placeId},
      ) as Map,
    ),
  );
  @override
  Future<void> setSaved(int placeId, bool saved) async {
    final user = client.auth.currentUser;
    if (user == null) throw StateError('로그인이 필요해요.');
    if (saved) {
      await client.from('saved_places').upsert({
        'user_id': user.id,
        'place_id': placeId,
      }, onConflict: 'user_id,place_id');
    } else {
      await client
          .from('saved_places')
          .delete()
          .eq('user_id', user.id)
          .eq('place_id', placeId);
    }
  }
}
