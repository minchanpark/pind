import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/places.dart';
import '../model/profile_model.dart';

/// Storage buckets for post photos: the legacy public bucket and the
/// current private bucket, whose paths need a signed URL.
const postMediaV2Bucket = 'post-media-v2';
const postMediaLegacyBucket = 'post-media';

/// Collects the `post-media-v2` paths referenced by a batch of raw post
/// rows (each with `bucket` + `photos`), for one batched signing call.
List<String> collectPostPhotoPaths(Iterable<dynamic> rows) => [
  for (final r in rows.cast<Map>())
    if (r['bucket'] == postMediaV2Bucket)
      for (final p in r['photos'] as List? ?? []) p as String,
];

/// Signed URLs live a day; images are cached by path (see `PindImage`), so
/// this only has to outlast a session. A hidden post's photo stays reachable
/// through an already-issued URL at most this long.
const signedUrlLifetime = Duration(hours: 24);

/// path → (url, reuse until). Kept an hour short of expiry so a URL handed to
/// a screen never dies while it is shown.
final _signed = <String, (String, DateTime)>{};

/// Signs the [paths] in `post-media-v2` that this session hasn't signed
/// recently, in one round-trip; the rest reuse their URL. A path the server
/// failed to sign is simply absent from the result.
Future<Map<String, String>> signPostPhotoPaths(
  SupabaseClient client,
  List<String> paths,
) async {
  final at = DateTime.now();
  final result = <String, String>{};
  final missing = <String>[];
  for (final path in paths.toSet()) {
    if (_signed[path] case (final url, final until) when until.isAfter(at)) {
      result[path] = url;
    } else {
      missing.add(path);
    }
  }
  if (missing.isEmpty) return result;
  final urls = await client.storage
      .from(postMediaV2Bucket)
      .createSignedUrlsResult(missing, signedUrlLifetime.inSeconds);
  final until = at.add(signedUrlLifetime - const Duration(hours: 1));
  for (final u in urls) {
    if (u case SignedUrlSuccess(:final path, :final signedUrl)) {
      _signed[path] = (signedUrl, until);
      result[path] = signedUrl;
    }
  }
  return result;
}

/// Resolves a stored photo path to a usable URL: public for the legacy
/// bucket, pre-signed (from [signed]) for `post-media-v2`.
String? resolvePostPhotoUrl(
  SupabaseClient client,
  Map<String, String> signed,
  String? bucket,
  String? path,
) => path == null
    ? null
    : bucket == postMediaLegacyBucket
    ? client.storage.from(postMediaLegacyBucket).getPublicUrl(path)
    : signed[path];

/// Parses one post row (`id`, `place`, `body`, `ratings`, `photos`,
/// `createdAt`) into a [MyPost]. [photoUrl] resolves each path in `photos`;
/// a path it can't resolve (unsigned v2 photo) is omitted.
MyPost parseMyPost(
  Map row, {
  required String? Function(String path) photoUrl,
}) => MyPost(
  id: (row['id'] as num).toInt(),
  place: Place.fromJson(Map<String, dynamic>.from(row['place'] as Map)),
  body: row['body'] as String? ?? '',
  ratings: parseCriteria(row['ratings'], (n) => n.round()),
  photos: [
    for (final p in row['photos'] as List? ?? []) ?photoUrl(p as String),
  ],
  createdAt: DateTime.parse(row['createdAt'] as String),
);
