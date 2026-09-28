import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../model/preferences.dart';
import 'theme.dart';
import 'navigation/main_shell.dart';
import 'onboarding/onboarding_screen.dart';
import 'onboarding/registration_screen.dart';

class PindApp extends StatefulWidget {
  const PindApp({
    super.key,
    required this.controller,
    this.mapsEnabled = false,
  });
  final AppController controller;
  final bool mapsEnabled;

  @override
  State<PindApp> createState() => _PindAppState();
}

class _PindAppState extends State<PindApp> {
  TastePreferences? get preferences => widget.controller.model.preferences;
  final navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.controller.model.addListener(changed);
    widget.controller.registration?.model.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant PindApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.model.removeListener(changed);
      oldWidget.controller.registration?.model.removeListener(changed);
      oldWidget.controller.dispose();
      widget.controller.model.addListener(changed);
      widget.controller.registration?.model.addListener(changed);
    }
  }

  @override
  void dispose() {
    widget.controller.model.removeListener(changed);
    widget.controller.registration?.model.removeListener(changed);
    widget.controller.dispose();
    super.dispose();
  }

  Future<void> editPreferences() async {
    await navigator.currentState!.push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (routeContext) => OnboardingScreen(
          initial: preferences,
          onCancel: () => Navigator.pop(routeContext),
          onComplete: (value) async {
            await widget.controller.savePreferences(value);
            if (!mounted || !routeContext.mounted) return;
            Navigator.pop(routeContext);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pind',
    navigatorKey: navigator,
    debugShowCheckedModeBanner: false,
    theme: PindTheme.data,
    home:
        widget.controller.registration != null &&
            !widget.controller.registration!.model.completed
        ? RegistrationScreen(
            controller: widget.controller.registration!,
            preferences: preferences,
          )
        : widget.controller.registration == null &&
              preferences?.isComplete != true
        ? OnboardingScreen(
            initial: preferences,
            onComplete: widget.controller.savePreferences,
          )
        : MainShell(
            controller: widget.controller.explore,
            posts: widget.controller.posts,
            preferences: preferences,
            mapsEnabled: widget.mapsEnabled,
            onEditPreferences: editPreferences,
          ),
  );
}
