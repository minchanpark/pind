import 'package:flutter/material.dart';

import '../components/pind_image.dart';
import '../design_system.dart';

/// Asset URIs are local QA fixtures; everything else is a signed network URL.
Widget placePhoto(String uri, BoxFit fit) => uri.startsWith('assets/')
    ? Image.asset(uri, fit: fit)
    : Image(
        image: PindImage(uri),
        fit: fit,
        errorBuilder: (_, error, stack) =>
            const Center(child: Icon(Icons.image_not_supported_outlined)),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

/// Full-screen pager for one post's photos; the next photo peeks at the edge.
class PostPhotoViewer extends StatelessWidget {
  const PostPhotoViewer({super.key, required this.photos, this.initial = 0});
  final List<String> photos;
  final int initial;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: PindColors.chip,
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: IconButton(
              key: const ValueKey('photo-viewer-back'),
              tooltip: '뒤로',
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                fixedSize: const Size(32, 32),
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: PageController(
                viewportFraction: .9,
                initialPage: initial,
              ),
              padEnds: false,
              itemCount: photos.length,
              itemBuilder: (_, index) => Padding(
                padding: const EdgeInsets.only(left: 13),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Semantics(
                      image: true,
                      label: '게시물 사진 ${index + 1}/${photos.length}',
                      child: ClipRRect(
                        key: ValueKey('photo-viewer-$index'),
                        borderRadius: BorderRadius.circular(28),
                        child: placePhoto(photos[index], BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    ),
  );
}
