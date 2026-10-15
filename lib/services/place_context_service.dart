import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/explore_model.dart';
import '../model/place_context.dart';
import 'data_revision.dart';
import '../l10n/l10n.dart';

abstract interface class PlaceContextService {
  Future<PlaceContext> load(int placeId);
  Future<void> setSaved(int placeId, bool saved);

  /// Place ids for a narrowed map: where people I follow posted (posts I
  /// can see, friends-only included), or what I saved.
  Future<Set<int>> scopePlaces(MapScope scope);
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
    if (user == null) throw StateError(l10n.errSignInRequired);
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
    markDataChanged();
  }

  @override
  Future<Set<int>> scopePlaces(MapScope scope) async {
    final me = client.auth.currentUser?.id;
    if (me == null || scope == MapScope.all) return {};
    // ponytail: every matching row comes back; page or aggregate server-side
    // once follows or saves reach the thousands.
    final List rows;
    if (scope == MapScope.saved) {
      rows = await client
          .from('saved_places')
          .select('place_id')
          .eq('user_id', me);
    } else {
      final follows = await client
          .from('follows')
          .select('followee_id')
          .eq('follower_id', me);
      if (follows.isEmpty) return {};
      rows = await client
          .from('posts')
          .select('place_id')
          .inFilter('author_id', [for (final f in follows) f['followee_id']])
          .eq('status', 'published');
    }
    return {for (final r in rows) (r['place_id'] as num).toInt()};
  }
}
