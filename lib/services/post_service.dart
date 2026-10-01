import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/post_model.dart';
import '../model/place_search_result.dart';
import 'data_revision.dart';

abstract class PostService {
  String? get userId;
  Future<PublishedPost> publish(
    PostDraft draft,
    String requestId,
    String? authorId,
  );

  /// Deletes my post and, best effort, its private photo files.
  Future<void> delete(int postId);
}

class UnavailablePostService implements PostService {
  @override
  String? get userId => null;
  @override
  Future<PublishedPost> publish(
    PostDraft draft,
    String requestId,
    String? authorId,
  ) async => throw const PlaceFailure('로그인 후 게시물을 작성해 주세요.');
  @override
  Future<void> delete(int postId) async =>
      throw const PlaceFailure('게시물 서버에 연결하지 못했어요.');
}

class SupabasePostService implements PostService {
  SupabasePostService(this.client);
  final SupabaseClient client;
  static const bucket = 'post-media-v2';
  @override
  String? get userId => client.auth.currentUser?.id;

  @override
  Future<void> delete(int postId) async {
    final Object? result;
    try {
      result = await client.rpc('delete_post', params: {'p_post_id': postId});
    } on PostgrestException {
      throw const PlaceFailure('게시물을 삭제하지 못했어요. 다시 시도해 주세요.');
    }
    markDataChanged();
    final paths = [
      for (final p in (result as Map)['paths'] as List? ?? []) p as String,
    ];
    // The rows are gone; a leftover file is only storage, so never fail here.
    if (paths.isNotEmpty) {
      await client.storage
          .from(bucket)
          .remove(paths)
          .catchError((_) => <FileObject>[]);
    }
  }

  Future<PublishedPost?> _existing(String requestId, String authorId) async {
    final row = await client
        .from('posts')
        .select('id, place_id')
        .eq('author_id', authorId)
        .eq('client_request_id', requestId)
        .maybeSingle();
    return row == null
        ? null
        : PublishedPost(
            id: (row['id'] as num).toInt(),
            placeId: (row['place_id'] as num).toInt(),
          );
  }

  @override
  Future<PublishedPost> publish(
    PostDraft draft,
    String requestId,
    String? authorId,
  ) async {
    if (authorId == null ||
        userId != authorId ||
        client.auth.currentUser?.isAnonymous == true) {
      throw const PlaceFailure('로그인 후 게시물을 작성해 주세요.');
    }
    final uploaded = <String>[];
    var databaseAttempted = false;
    try {
      final previous = await _existing(requestId, authorId);
      if (previous != null) return previous;
      final attempt = const Uuid().v4();
      final media = <Map<String, dynamic>>[];
      for (var index = 0; index < draft.photos.length; index++) {
        final photo = draft.photos[index];
        final path = '$authorId/$requestId/$attempt/$index.${photo.extension}';
        await client.storage
            .from(bucket)
            .uploadBinary(
              path,
              photo.bytes,
              fileOptions: FileOptions(
                contentType: photo.mimeType,
                upsert: false,
              ),
            );
        uploaded.add(path);
        media.add({
          'path': path,
          'mime': photo.mimeType,
          'bytes': photo.bytes.length,
        });
      }
      if (userId != authorId) {
        throw const PlaceFailure('계정이 변경되었어요. 다시 로그인해 주세요.');
      }
      databaseAttempted = true;
      final result = await client.rpc(
        'publish_post_v3',
        params: {
          'p_client_request_id': requestId,
          'p_place_id': draft.place.id,
          'p_ratings': {
            for (final rating in draft.ratings.entries)
              rating.key.name: rating.value,
          },
          'p_body': draft.body.trim(),
          'p_media': media,
        },
      );
      markDataChanged();
      return PublishedPost.fromJson(Map<String, dynamic>.from(result as Map));
    } catch (error) {
      // A lost response can follow a committed transaction. Reconcile before
      // cleaning files, and retain them when the database cannot be reached.
      var safeToClean = !databaseAttempted;
      if (databaseAttempted && userId == authorId) {
        try {
          final saved = await _existing(requestId, authorId);
          if (saved != null) return saved;
          safeToClean = true;
        } catch (_) {
          /* Keep potentially published media for a safe retry. */
        }
      }
      if (safeToClean && uploaded.isNotEmpty && userId == authorId) {
        try {
          await client.storage.from(bucket).remove(uploaded);
        } catch (_) {
          /* RLS also prevents deletion of already attached media. */
        }
      }
      if (error is PlaceFailure) rethrow;
      throw const PlaceFailure('게시물을 등록하지 못했어요. 입력 내용을 유지했으니 다시 시도해 주세요.');
    }
  }
}
