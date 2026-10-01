import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/nearby_ranking.dart';
import '../model/places.dart';
import 'post_media_urls.dart';

/// Posted places within [radius] meters of [here], nearest first.
typedef NearbyRanking = Future<List<RankedPlace>> Function(
  MapViewport here, {
  int radius,
});

/// `get_nearby_ranking`, with private post photos signed in one round-trip.
NearbyRanking supabaseNearbyRanking(SupabaseClient client) =>
    (here, {radius = 10000}) async {
      final rows = [
        for (final r in await client.rpc(
          'get_nearby_ranking',
          params: {
            'p_lat': here.latitude,
            'p_lng': here.longitude,
            'p_radius': radius,
          },
        ) as List)
          Map<String, dynamic>.from(r as Map),
      ];
      final signed = await signPostPhotoPaths(client, [
        for (final r in rows)
          if (r['pindPhotoBucket'] == postMediaV2Bucket &&
              r['pindPhotoPath'] is String)
            r['pindPhotoPath'] as String,
      ]);
      return [
        for (final r in rows)
          RankedPlace.fromJson(
            r,
            imageUrl: resolvePostPhotoUrl(
              client,
              signed,
              r['pindPhotoBucket'] as String?,
              r['pindPhotoPath'] as String?,
            ),
          ),
      ];
    };
