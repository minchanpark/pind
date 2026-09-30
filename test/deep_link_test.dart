import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/app_controller.dart';
import 'package:pind_flutter/model/navigation_model.dart';
import 'package:pind_flutter/model/post_model.dart';
import 'package:pind_flutter/model/profile_model.dart';
import 'package:pind_flutter/services/post_service.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/view/app.dart';
import 'package:pind_flutter/view/navigation/pind_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_test.dart' show FakeProfileService, canned, prefs;

final other = ProfileOverview(
  profile: const UserProfile(id: 'u2', handle: 'haram', displayName: '하람'),
);

/// Signed in as `canned` (u1).
class _Me implements PostService {
  @override
  String? get userId => canned.profile.id;
  @override
  Future<PublishedPost> publish(PostDraft d, String r, String? a) =>
      throw UnimplementedError();
}

void main() {
  late StreamController<Uri> links;
  late AppController controller;
  late FakeProfileService profile;
  // Other people's pages that were opened.
  List<String> opened() => profile.requested.whereType<String>().toList();

  Future<void> app(
    WidgetTester tester, {
    bool onboarded = true,
    Uri? initial,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final store = PreferenceService(await SharedPreferences.getInstance());
    if (onboarded) await store.save(prefs);
    links = StreamController<Uri>();
    controller = AppController(
      store,
      posts: _Me(),
      profile: profile = FakeProfileService(other: other),
      links: links.stream,
      initialLink: Future.value(initial),
    );
    await tester.pumpWidget(PindApp(controller: controller));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester, String url) async {
    links.add(Uri.parse(url));
    await tester.pumpAndSettle();
  }

  PindTab tab(WidgetTester tester) =>
      tester.widget<PindNavigationBar>(find.byType(PindNavigationBar)).selected;

  testWidgets('a handle link opens that profile', (tester) async {
    await app(tester);
    await send(tester, 'https://pind-profile-links.vercel.app/@haram');
    expect(opened(), ['u2']);
    expect(find.text('@haram'), findsOneWidget);
  });

  testWidgets('my own link switches to My Page', (tester) async {
    await app(tester);
    expect(tab(tester), PindTab.map);
    await send(tester, 'com.pind.app://profile/@minchan');
    expect(tab(tester), PindTab.profile);
    expect(opened(), isEmpty);
  });

  testWidgets('an unknown handle shows a message', (tester) async {
    await app(tester);
    await send(tester, 'https://pind-profile-links.vercel.app/@nobody');
    expect(find.text('프로필을 찾을 수 없어요.'), findsOneWidget);
  });

  testWidgets('a link during onboarding opens once it completes', (
    tester,
  ) async {
    const id = '0f8fad5b-d9cb-469f-a165-70867728950e';
    await app(tester, onboarded: false);
    await send(tester, 'https://pind-profile-links.vercel.app/u/$id');
    expect(find.byType(PindNavigationBar), findsNothing);
    expect(controller.link.value, isNotNull);
    await controller.savePreferences(prefs);
    await tester.pumpAndSettle();
    expect(controller.link.value, isNull);
    expect(opened(), [id]);
  });

  testWidgets('the cold-start link opens once', (tester) async {
    await app(tester, initial: Uri.parse('https://pind-profile-links.vercel.app/@haram'));
    await send(tester, 'https://pind-profile-links.vercel.app/@haram');
    expect(opened(), ['u2']);
  });

  testWidgets('auth callbacks and other links are ignored', (tester) async {
    await app(tester);
    for (final url in [
      'com.pind.app://login-callback?code=abc',
      'https://example.com/@haram',
      'https://pind-profile-links.vercel.app/about',
    ]) {
      await send(tester, url);
    }
    expect(controller.link.value, isNull);
    expect(opened(), isEmpty);
    expect(find.byType(SnackBar), findsNothing);
  });
}
