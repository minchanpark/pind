import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/post_model.dart';
import '../model/place_search_result.dart';
import 'data_revision.dart';
import 'request_client.dart';
import '../l10n/l10n.dart';

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

abstract interface class ProgressPostService implements PostService {
  Future<PublishedPost> publishWithProgress(
    PostDraft draft,
    String requestId,
    String? authorId,
    void Function(double) progress,
  );
}

class UnavailablePostService implements PostService {
  @override
  String? get userId => null;
  @override
  Future<PublishedPost> publish(
    PostDraft draft,
    String requestId,
    String? authorId,
  ) async => throw PlaceFailure(l10n.errPostSignIn);
  @override
  Future<void> delete(int postId) async =>
      throw PlaceFailure(l10n.errPostServer);
}

class SupabasePostService implements ProgressPostService {
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
      throw PlaceFailure(l10n.errPostDeleteRetry);
    }
    markDataChanged();
    postDeletions.add(postId);
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
  ) => publishWithProgress(draft, requestId, authorId, (_) {});

  @override
  Future<PublishedPost> publishWithProgress(
    PostDraft draft,
    String requestId,
    String? authorId,
    void Function(double) progress,
  ) async {
    if (draft.photos.fold<int>(0, (sum, photo) => sum + photo.bytes.length) >
        maxPostPhotoBytes) {
      throw PlaceFailure(l10n.errPhotosTotalSize);
    }
    if (authorId == null ||
        userId != authorId ||
        client.auth.currentUser?.isAnonymous == true) {
      throw PlaceFailure(l10n.errPostSignIn);
    }
    final uploaded = <String>[];
    var databaseAttempted = false;
    try {
      final previous = await _existing(requestId, authorId);
      if (previous != null) return previous;
      final attempt = const Uuid().v4();
      final media = List<Map<String, dynamic>?>.filled(
        draft.photos.length,
        null,
      );
      final totalBytes = draft.photos.fold<int>(
        0,
        (sum, p) => sum + p.bytes.length,
      );
      var completedBytes = 0;
      // Three uploads per batch; wait for all to settle before cleanup or commit.
      for (var first = 0; first < draft.photos.length; first += 3) {
        await Future.wait([
          for (
            var index = first;
            index < draft.photos.length && index < first + 3;
            index++
          )
            () async {
              if (userId != authorId) {
                throw PlaceFailure(l10n.errAccountChanged);
              }
              final photo = draft.photos[index];
              final path =
                  '$authorId/$requestId/$attempt/$index.${photo.extension}';
              await client.storage
                  .from(bucket)
                  .uploadBinary(
                    path,
                    photo.bytes,
                    retryAttempts: 0,
                    fileOptions: FileOptions(
                      contentType: photo.mimeType,
                      upsert: false,
                    ),
                  );
              uploaded.add(path);
              media[index] = {
                'path': path,
                'mime': photo.mimeType,
                'bytes': photo.bytes.length,
              };
              completedBytes += photo.bytes.length;
              progress(totalBytes == 0 ? 1 : completedBytes / totalBytes);
            }(),
        ]);
      }
      if (userId != authorId) {
        throw PlaceFailure(l10n.errAccountChanged);
      }
      databaseAttempted = true;
      final result = await withRequestCancellation(
        null,
        () => client.rpc(
          'publish_post_v3',
          params: {
            'p_client_request_id': requestId,
            'p_place_id': draft.place.id,
            'p_ratings': {
              for (final rating in draft.ratings.entries)
                rating.key.name: rating.value,
            },
            'p_body': draft.body.trim(),
            'p_media': media.cast<Map<String, dynamic>>(),
            'p_is_public': draft.isPublic,
          },
        ),
      );
      markDataChanged();
      return PublishedPost.fromJson(Map<String, dynamic>.from(result as Map));
    } catch (error) {
      // A lost response can follow a committed transaction. Reconcile before
      // cleaning files, and retain them when the database cannot be reached.
      var safeToClean = !databaseAttempted;
      if (databaseAttempted && userId == authorId) {
        try {
          final saved = await withRequestCancellation(
            null,
            () => _existing(requestId, authorId),
          );
          if (saved != null) return saved;
          safeToClean = true;
        } catch (_) {
          /* Keep potentially published media for a safe retry. */
        }
      }
      if (safeToClean && uploaded.isNotEmpty && userId == authorId) {
        try {
          await withRequestCancellation(
            null,
            () => client.storage.from(bucket).remove(uploaded),
          );
        } catch (_) {
          /* RLS also prevents deletion of already attached media. */
        }
      }
      if (error is PlaceFailure) rethrow;
      throw PlaceFailure(l10n.errPostPublishKept);
    }
  }
}
