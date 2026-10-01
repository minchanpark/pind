import 'package:flutter/foundation.dart';

import 'profile_model.dart';

/// A public post in the Discover feed: the author's post plus its likes.
class FeedPost {
  const FeedPost({
    required this.post,
    required this.author,
    this.likeCount = 0,
    this.liked = false,
  });
  final MyPost post;
  final UserProfile author;
  final int likeCount;
  final bool liked;

  FeedPost withAuthor(UserProfile value) =>
      FeedPost(post: post, author: value, likeCount: likeCount, liked: liked);

  FeedPost withLike(bool value) => FeedPost(
    post: post,
    author: author,
    liked: value,
    likeCount: likeCount + (value == liked ? 0 : (value ? 1 : -1)),
  );
}

/// One page of the feed, newest first. [hasMore] is false on the last page.
class FeedPage {
  const FeedPage(this.posts, {required this.hasMore});
  final List<FeedPost> posts;
  final bool hasMore;
}

class DiscoverModel extends ChangeNotifier {
  List<FeedPost> posts = const [];
  // ponytail: nothing sets this until a notifications backend exists.
  bool hasNewAlerts = false;
  bool loading = false, loadingMore = false, hasMore = true;
  String? error;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
