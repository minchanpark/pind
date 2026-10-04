import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/place_search_result.dart';
import '../model/places.dart';
import '../model/post_model.dart';
import '../model/preferences.dart';
import '../model/profile_model.dart';
import 'post_media_urls.dart';
import 'data_revision.dart';
import '../l10n/l10n.dart';

/// Server profile: `public.profiles` row, `avatars` bucket, and the
/// `get_my_profile_overview` / `get_profile_overview` / `record_place_view`
/// RPCs.
abstract interface class ProfileService {
  /// Own profile row, or null when signed out.
  Future<UserProfile?> load();

  /// Partial update. Throws [PlaceFailure] with a user message on a taken
  /// handle; the server rejects changing a handle once set.
  Future<void> save({
    String? handle,
    String? displayName,
    String? bio,
    String? avatarUrl,
  });

  /// Uploads to `avatars/{uid}/…` and returns the public URL.
  Future<String> uploadAvatar(PostPhoto photo);

  /// My page, or [userId]'s as I'm allowed to see it.
  Future<ProfileOverview> overview({String? userId});

  /// Upserts a 24h "recently viewed" row. Safe to fire and forget.
  Future<void> recordView(int placeId);

  /// Id behind a shared `@handle` link, or null when nobody has it.
  Future<String?> findUserId(String handle);
}

class UnavailableProfileService implements ProfileService {
  @override
  Future<UserProfile?> load() async => null;
  @override
  Future<void> save({
    String? handle,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async => throw PlaceFailure(l10n.errProfileServer);
  @override
  Future<String> uploadAvatar(PostPhoto photo) async =>
      throw PlaceFailure(l10n.errProfileServer);
  @override
  Future<ProfileOverview> overview({String? userId}) async =>
      throw PlaceFailure(l10n.errProfileServer);
  @override
  Future<void> recordView(int placeId) async {}
  @override
  Future<String?> findUserId(String handle) async => null;
}

class SupabaseProfileService implements ProfileService {
  SupabaseProfileService(this.client);
  final SupabaseClient client;
  static const avatarBucket = 'avatars';

  String get _uid {
    final user = client.auth.currentUser;
    if (user == null) throw PlaceFailure(l10n.errSignInRequired);
    return user.id;
  }

  @override
  Future<UserProfile?> load() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('profiles')
        .select('id, handle, display_name, avatar_url, bio')
        .eq('id', user.id)
        .maybeSingle();
    return row == null ? null : _profile(row);
  }

  UserProfile _profile(Map row) => UserProfile(
    id: row['id'] as String,
    handle: row['handle'] as String?,
    displayName: row['display_name'] as String? ?? '',
    avatarUrl: row['avatar_url'] as String?,
    bio: row['bio'] as String?,
  );

  @override
  Future<void> save({
    String? handle,
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final patch = {
      'handle': ?handle,
      'display_name': ?displayName,
      'bio': ?bio,
      'avatar_url': ?avatarUrl,
    };
    if (patch.isEmpty) return;
    try {
      await client.from('profiles').update(patch).eq('id', _uid);
      markDataChanged();
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw PlaceFailure(l10n.errHandleTaken);
      if (e.message.contains('handle is immutable')) {
        throw PlaceFailure(l10n.errHandleImmutable);
      }
      throw PlaceFailure(l10n.errProfileSave);
    }
  }

  @override
  Future<String> uploadAvatar(PostPhoto photo) async {
    final path = '$_uid/${const Uuid().v4()}.${photo.extension}';
    await client.storage
        .from(avatarBucket)
        .uploadBinary(
          path,
          photo.bytes,
          fileOptions: FileOptions(contentType: photo.mimeType, upsert: false),
        );
    return client.storage.from(avatarBucket).getPublicUrl(path);
  }

  @override
  Future<void> recordView(int placeId) async {
    await client.rpc('record_place_view', params: {'p_place_id': placeId});
    markDataChanged();
  }

  @override
  Future<String?> findUserId(String handle) async {
    final row = await client
        .from('profiles')
        .select('id')
        .eq('handle', handle.toLowerCase())
        .maybeSingle();
    return row?['id'] as String?;
  }

  @override
  Future<ProfileOverview> overview({String? userId}) async {
    final Object? response = userId == null
        ? await client.rpc('get_my_profile_overview')
        : await client.rpc('get_profile_overview', params: {'p_user': userId});
    if (response is! Map) throw PlaceFailure(l10n.errProfileNotFound);
    final raw = Map<String, dynamic>.from(response);
    // One signing round-trip for every private photo on the page.
    final posts = raw['posts'] as List? ?? [];
    final signed = await signPostPhotoPaths(client, [
      ..._cardPaths(raw),
      ...collectPostPhotoPaths(posts),
    ]);
    String? url(String? bucket, String? path) =>
        resolvePostPhotoUrl(client, signed, bucket, path);
    // One malformed row must not blank the whole page.
    T? skipBad<T>(T Function() parse) {
      try {
        return parse();
      } catch (_) {
        return null;
      }
    }

    ProfilePlaceCard card(Map raw) {
      final json = Map<String, dynamic>.from(raw);
      return ProfilePlaceCard(
        place: Place.fromJson(json),
        imageUrl:
            json['heroImageUrl'] as String? ??
            url(
              json['pindPhotoBucket'] as String?,
              json['pindPhotoPath'] as String?,
            ),
        averages: parseCriteria(json['averages'], (n) => n.toDouble()),
        ratingCounts: parseCriteria(json['ratingCounts'], (n) => n.toInt()),
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? ''),
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        savers: [for (final a in json['savers'] as List? ?? []) a as String?],
      );
    }

    return ProfileOverview(
      profile: UserProfile.fromJson(Map<String, dynamic>.from(raw['profile'])),
      counts: ProfileCounts.fromJson(
        Map<String, dynamic>.from(raw['counts'] as Map? ?? {}),
      ),
      recentViews: [
        for (final r in raw['recentViews'] as List? ?? [])
          ?skipBad(() => card(r)),
      ],
      savedPlaces: [
        for (final r in raw['savedPlaces'] as List? ?? [])
          ?skipBad(() => card(r)),
      ],
      posts: [
        for (final r in posts)
          ?skipBad(
            () => parseMyPost(
              Map<String, dynamic>.from(r as Map),
              photoUrl: (p) => url(r['bucket'] as String?, p),
            ),
          ),
      ],
      following: raw['following'] == true,
      followsMe: raw['followsMe'] == true,
      taste: switch (raw['taste']) {
        final List names => [
          for (final n in names) ?PreferenceCriterion.values.asNameMap()[n],
        ],
        _ => null,
      },
    );
  }

  List<String> _cardPaths(Map<String, dynamic> raw) => [
    for (final key in ['recentViews', 'savedPlaces'])
      for (final r in raw[key] as List? ?? [])
        if (r['pindPhotoBucket'] == postMediaV2Bucket &&
            r['pindPhotoPath'] is String)
          r['pindPhotoPath'] as String,
  ];
}
