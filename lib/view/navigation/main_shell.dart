import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../../controllers/explore_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../model/navigation_model.dart';
import '../../model/preferences.dart';
import '../explore/explore_screen.dart';
import 'pind_navigation_bar.dart';
import '../../controllers/post_controller.dart';
import '../../model/post_model.dart';
import '../../services/post_service.dart';
import '../../services/post_photo_service.dart';
import '../posts/post_composer.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.controller,
    this.posts,
    required this.mapsEnabled,
    required this.onEditPreferences,
    this.preferences,
  });
  final ExploreController? controller;
  final PostService? posts;
  final TastePreferences? preferences;
  final bool mapsEnabled;
  final VoidCallback onEditPreferences;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final navigation = NavigationController();
  PindTab get selected => navigation.model.selected;

  @override
  void initState() {
    super.initState();
    navigation.model.addListener(changed);
  }

  void changed() => setState(() {});

  @override
  void dispose() {
    navigation.model.removeListener(changed);
    navigation.dispose();
    super.dispose();
  }

  void select(PindTab tab) {
    if (selected == tab) return;
    FocusManager.instance.primaryFocus?.unfocus();
    navigation.select(tab);
  }

  Future<void> compose() async {
    if (!navigation.beginCompose()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final saved = await Navigator.of(context).push<PublishedPost>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PostComposer(
            controller: PostController(
              posts: widget.posts ?? UnavailablePostService(),
              photos: DevicePostPhotoService(),
              places: widget.controller?.repository,
              criteria: widget.preferences?.priorities,
            ),
          ),
        ),
      );
      if (saved != null && mounted) {
        navigation.select(PindTab.map);
        await widget.controller?.showPublishedPlace(saved.placeId);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('게시물을 등록했어요.')));
        }
      }
    } finally {
      navigation.endCompose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = math.max(23.0, MediaQuery.viewPaddingOf(context).bottom);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final clearance = bottom + PindNavigationBar.barHeight + 12;
    return PopScope(
      canPop: selected == PindTab.map,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) select(PindTab.map);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            IndexedStack(
              index: selected.index,
              children: [
                TickerMode(
                  enabled: selected == PindTab.discover,
                  child: _NextStepScreen(
                    title: 'Discover',
                    message: '커뮤니티와 친구 피드는 다음 단계에서 구현합니다.',
                    bottomClearance: clearance,
                  ),
                ),
                TickerMode(
                  enabled: selected == PindTab.map,
                  child: ExploreScreen(
                    controller: widget.controller,
                    preferences: widget.preferences,
                    mapsEnabled: widget.mapsEnabled,
                    onEditPreferences: widget.onEditPreferences,
                    isActive: selected == PindTab.map,
                    bottomClearance: clearance,
                  ),
                ),
                TickerMode(
                  enabled: selected == PindTab.profile,
                  child: _NextStepScreen(
                    title: '마이페이지',
                    message: '내 지도·저장·게시물은 다음 단계에서 구현합니다.',
                    bottomClearance: clearance,
                    action: TextButton(
                      onPressed: widget.onEditPreferences,
                      child: const Text('취향 수정'),
                    ),
                  ),
                ),
              ],
            ),
            if (!keyboardOpen)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottom,
                child: Center(
                  child: PindNavigationBar(
                    selected: selected,
                    onSelect: select,
                    onCompose: compose,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Honest route boundaries for the next implementation units, not demo content.
class _NextStepScreen extends StatelessWidget {
  const _NextStepScreen({
    required this.title,
    required this.message,
    this.action,
    this.bottomClearance = 0,
  });
  final String title, message;
  final Widget? action;
  final double bottomClearance;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
    body: SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomClearance + 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '화면 구현 예정',
                  style: TextStyle(color: PindTheme.muted),
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                if (action != null) ...[const SizedBox(height: 16), action!],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
