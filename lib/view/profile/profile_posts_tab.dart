import 'package:flutter/material.dart';

import '../../model/preferences.dart';
import '../../model/profile_model.dart';
import '../components/post_card.dart';
import '../design_system.dart';
import 'profile_screen.dart';

class ProfilePostsTab extends StatelessWidget {
  const ProfilePostsTab({
    super.key,
    required this.overview,
    this.preferences,
    required this.onShare,
  });
  final ProfileOverview overview;
  final TastePreferences? preferences;
  final void Function(MyPost post, Rect origin) onShare;

  @override
  Widget build(BuildContext context) {
    final posts = overview.posts;
    if (posts.isEmpty) {
      return Padding(
        padding: profileInset,
        child: mutedNote('아직 작성한 게시물이 없어요.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < posts.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: PindColors.border),
          Padding(
            padding: profileInset.copyWith(top: i == 0 ? 0 : 18, bottom: 18),
            child: PostCard(
              post: posts[i],
              author: overview.profile,
              preferences: preferences,
              action: PostCardButton(
                label: '공유',
                icon: const Icon(Icons.ios_share, size: 12),
                onTap: (button) {
                  final box = button.findRenderObject() as RenderBox;
                  onShare(posts[i], box.localToGlobal(Offset.zero) & box.size);
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
