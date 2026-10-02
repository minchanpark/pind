import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/friends_controller.dart';
import '../../model/friends_model.dart';
import '../../model/profile_link.dart';
import '../../services/place_action_service.dart';
import '../components/pind_back_header.dart';
import '../components/pind_glass.dart';
import '../components/pind_search_field.dart';
import '../profile/profile_follow.dart' show PersonRow;
import '../profile/profile_screen.dart' show mutedNote;
import '../design_system.dart';
import 'share_code_screen.dart';

/// Figma 653:25641: search, share my code, and taste-matched people to follow.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    required this.controller,
    this.onOpenProfile,
    this.onOpenLink,
  });
  final FriendsController controller;
  final ValueChanged<FriendCandidate>? onOpenProfile;

  /// Opens a scanned profile link.
  final Future<void> Function(ProfileLink link)? onOpenLink;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  FriendsController get controller => widget.controller;
  FriendsModel get model => controller.model;
  final query = TextEditingController();
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    model.addListener(changed);
    query.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  void search(String text, {bool now = false}) {
    debounce?.cancel();
    if (now) return unawaited(controller.search(text));
    debounce = Timer(
      const Duration(milliseconds: 350),
      () => controller.search(text),
    );
  }

  void openShareCode(BuildContext _) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ShareCodeScreen(
        controller: controller,
        onOpenLink: widget.onOpenLink,
      ),
    ),
  );

  Future<void> shareInvite(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero) & box.size;
    final text = await controller.inviteText();
    await PlaceActionService.share(text, 'Pind 친구 초대', origin);
  }

  @override
  void dispose() {
    debounce?.cancel();
    model.removeListener(changed);
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searching = query.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 2, 24, 32),
          children: [
            const PindBackHeader('친구 추가'),
            const SizedBox(height: 14),
            searchBar(),
            if (searching) ...[
              const SizedBox(height: 16),
              Text(
                model.searching ? '검색 결과' : '검색 결과 ${model.results.length}명',
                style: const TextStyle(
                  fontSize: PindType.label,
                  fontWeight: FontWeight.w700,
                  color: PindColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              ...list(
                model.results,
                busy: model.searching,
                empty: '검색 결과가 없어요.',
              ),
              const SizedBox(height: 20),
              const Text(
                '찾는 사람이 없나요?',
                style: TextStyle(
                  fontSize: PindType.label,
                  fontWeight: FontWeight.w700,
                  color: PindColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              linkCard('링크로 초대하기', shareInvite, icon: '✉'),
            ] else ...[
              const SizedBox(height: 14),
              linkCard('내 코드 공유하기', openShareCode, subtitle: '링크로 친구를 초대해요'),
              const SizedBox(height: 22),
              sectionTitle(
                '취향이 비슷한 사람',
                more: model.hasMore && !model.loadingMore
                    ? controller.loadMore
                    : null,
              ),
              const SizedBox(height: 4),
              ...list(
                model.matches,
                busy: model.loading,
                empty: '아직 취향이 비슷한 사람이 없어요.',
              ),
              if (model.loadingMore)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
            if (model.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    Text(
                      model.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: PindColors.muted),
                    ),
                    if (!searching && model.matches.isEmpty)
                      TextButton(
                        onPressed: controller.load,
                        child: const Text('다시 시도'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget searchBar() => PindSearchField(
    controller: query,
    hint: '아이디 또는 이름 검색',
    onChanged: (text) => search(text, now: text.isEmpty),
    onSubmitted: (text) => search(text, now: true),
  );

  /// [onTap] gets the card's context, for the share sheet's anchor.
  Widget linkCard(
    String title,
    void Function(BuildContext) onTap, {
    String? icon,
    String? subtitle,
  }) => PindGlass(
    radius: 16,
    child: Builder(
      builder: (ctx) => InkWell(
        onTap: () => onTap(ctx),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: subtitle == null ? 14 : 13,
          ),
          child: Row(
            spacing: 10,
            children: [
              if (icon != null)
                Text(
                  icon,
                  style: const TextStyle(fontSize: PindType.body, color: PindColors.purple),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: PindType.bodySmall,
                        fontWeight: FontWeight.w700,
                        color: PindColors.ink,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: PindType.micro,
                          color: PindColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const Text(
                '›',
                style: TextStyle(
                  fontSize: PindType.body,
                  fontWeight: FontWeight.w700,
                  color: PindColors.placeholder,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget sectionTitle(String title, {VoidCallback? more}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: PindType.body,
            fontWeight: FontWeight.w700,
            color: PindColors.ink,
          ),
        ),
      ),
      if (more != null)
        InkWell(
          onTap: more,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '더보기 ›',
              style: TextStyle(fontSize: PindType.caption, color: PindColors.muted),
            ),
          ),
        ),
    ],
  );

  List<Widget> list(
    List<FriendCandidate> people, {
    required bool busy,
    required String empty,
  }) {
    if (people.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: busy
                ? const CircularProgressIndicator()
                : model.error == null
                ? mutedNote(empty)
                : null,
          ),
        ),
      ];
    }
    return [for (final p in people) row(p)];
  }

  Widget row(FriendCandidate c) => PersonRow(
    candidate: c,
    onOpen: widget.onOpenProfile == null
        ? null
        : () => widget.onOpenProfile!(c),
    onToggleFollow: () => controller.toggleFollow(c),
  );
}
