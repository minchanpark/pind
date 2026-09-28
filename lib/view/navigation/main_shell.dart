import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../../controllers/explore_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../model/navigation_model.dart';
import '../../model/preferences.dart';
import '../explore/explore_screen.dart';
import 'pind_navigation_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.controller,
    required this.mapsEnabled,
    required this.onEditPreferences,
    this.preferences,
  });
  final ExploreController? controller;
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
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const _NextStepScreen(
            title: '작성',
            message: '장소 선택과 사진·평가 작성은 다음 단계에서 구현합니다.',
            isDialog: true,
          ),
        ),
      );
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
    this.isDialog = false,
  });
  final String title, message;
  final Widget? action;
  final double bottomClearance;
  final bool isDialog;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      leading: isDialog
          ? CloseButton(onPressed: () => Navigator.pop(context))
          : null,
      automaticallyImplyLeading: false,
    ),
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
