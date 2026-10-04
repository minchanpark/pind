import 'package:flutter/material.dart';

import '../components/pind_image.dart';
import '../design_system.dart';
import '../../l10n/l10n.dart';

/// Asset URIs are local QA fixtures; everything else is a signed network URL.
Widget placePhoto(String uri, BoxFit fit) => uri.startsWith('assets/')
    ? Image.asset(uri, fit: fit)
    : Image(
        image: PindImage(uri),
        fit: fit,
        frameBuilder: fadeInFrame,
        errorBuilder: (_, error, stack) =>
            const Center(child: Icon(Icons.image_not_supported_outlined)),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

/// Photo [index] of a post; a tap grows it into the full-screen viewer and
/// closing shrinks it back.
class PostPhotoOpener extends StatelessWidget {
  const PostPhotoOpener({
    super.key,
    required this.photos,
    required this.index,
    required this.child,
  });
  final List<String> photos;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: l10n.postPhotoOpen(index + 1),
    child: GestureDetector(
      onTap: () => Navigator.of(context).push(
        // A fade, so the photo's flight is the only thing that moves.
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => PostPhotoViewer(
            photos: photos,
            initial: index,
            // This element: unique even when one post shows on two tabs.
            heroTag: context,
          ),
          transitionsBuilder: (_, animation, _, page) =>
              FadeTransition(opacity: animation, child: page),
        ),
      ),
      child: Hero(tag: context, child: child),
    ),
  );
}

/// Full-screen pager for one post's photos; the next photo peeks at the edge.
class PostPhotoViewer extends StatelessWidget {
  const PostPhotoViewer({
    super.key,
    required this.photos,
    this.initial = 0,
    this.heroTag,
  });
  final List<String> photos;
  final int initial;

  /// The opening photo's [Hero] tag on the page it came from.
  final Object? heroTag;

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
              tooltip: l10n.back,
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
                      label: l10n.postPhotoOf(index + 1, photos.length),
                      child: HeroMode(
                        enabled: heroTag != null && index == initial,
                        child: Hero(
                          tag: heroTag ?? index,
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
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    ),
  );
}
