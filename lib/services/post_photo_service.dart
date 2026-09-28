import 'package:image_picker/image_picker.dart';

import '../model/post_model.dart';
import '../model/place_search_result.dart';

abstract class PostPhotoService {
  Future<List<PostPhoto>> pick(int remaining);
}

class DevicePostPhotoService implements PostPhotoService {
  DevicePostPhotoService({ImagePicker? picker})
    : picker = picker ?? ImagePicker();
  final ImagePicker picker;

  @override
  Future<List<PostPhoto>> pick(int remaining) async {
    if (remaining <= 0) return [];
    final files = await picker.pickMultiImage(
      limit: remaining,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    final photos = <PostPhoto>[];
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        throw const PlaceFailure('사진은 한 장당 10MB 이하로 선택해 주세요.');
      }
      final extension = file.name.split('.').last.toLowerCase();
      final mime =
          file.mimeType ??
          switch (extension) {
            'png' => 'image/png',
            'webp' => 'image/webp',
            'heic' => 'image/heic',
            'heif' => 'image/heif',
            _ => 'image/jpeg',
          };
      if (!const [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'image/heif',
      ].contains(mime)) {
        throw const PlaceFailure('지원되는 사진 형식을 선택해 주세요.');
      }
      photos.add(PostPhoto(bytes: bytes, mimeType: mime));
    }
    return photos;
  }
}
