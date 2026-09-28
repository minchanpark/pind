import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/app_controller.dart';
import 'package:pind_flutter/controllers/registration_controller.dart';
import 'package:pind_flutter/model/registration_model.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/services/registration_service.dart';
import 'package:pind_flutter/view/app.dart';
import 'package:pind_flutter/view/explore/explore_screen.dart';
import 'package:pind_flutter/view/onboarding/login_screen.dart';
import 'package:pind_flutter/view/onboarding/registration_screen.dart';
import 'package:pind_flutter/view/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/registration_fakes.dart';

final validDraft = RegistrationDraft(
  name: '뉴던',
  birthDate: DateTime(2000, 3, 14),
  handle: 'newdawn',
  privacyConsent: true,
  ageConsent: true,
);

void main() {
  late SharedPreferences storage;
  late FakeAuthService auth;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await SharedPreferences.getInstance();
    auth = FakeAuthService();
  });
  tearDown(() => auth.close());

  RegistrationController create({
    bool preview = false,
    Future<RegistrationPermission> Function()? permission,
  }) => RegistrationController(
    auth: auth,
    storage: RegistrationService(storage),
    allowPreview: preview,
    requestPermission: permission ?? () async => RegistrationPermission.allowed,
    onComplete: (_) async {},
  );

  test(
    'OAuth launch does not advance until authenticated session arrives',
    () async {
      final controller = create();
      addTearDown(controller.dispose);
      await controller.signIn(LoginProvider.google);
      expect(controller.model.step, RegistrationStep.login);
      auth.emit(const AuthIdentity('user-a'));
      expect(controller.model.step, RegistrationStep.country);
      expect(controller.model.identity!.id, 'user-a');
    },
  );

  test('restored social session skips registration', () async {
    auth = FakeAuthService(initial: const AuthIdentity('user-a'));
    final controller = create();
    addTearDown(controller.dispose);
    expect(controller.model.completed, true);
    auth.emit(const AuthIdentity('user-a'));
    expect(controller.model.completed, true);
  });

  test('anonymous session is not accepted as a social login', () async {
    auth.emit(const AuthIdentity('anonymous', development: true));
    final controller = create();
    addTearDown(controller.dispose);
    expect(controller.model.step, RegistrationStep.login);
    await controller.preview();
    expect(controller.model.identity, null);
  });

  test('country search and per-user draft restoration', () async {
    final service = RegistrationService(storage);
    await service.save(
      'user-a',
      validDraft.copyWith(step: RegistrationStep.handle),
    );
    final controller = create();
    addTearDown(controller.dispose);
    auth.emit(const AuthIdentity('user-a'));
    expect(controller.model.step, RegistrationStep.handle);
    expect(controller.model.draft.handle, 'newdawn');
    controller.searchCountries('US');
    expect(controller.countries, [OnboardingCountry.usa]);
    auth.emit(const AuthIdentity('user-b'));
    expect(controller.model.draft.name, '');
    expect(controller.model.step, RegistrationStep.country);
  });

  test('age, mandatory consent and handle format validation', () {
    final now = DateTime(2026, 9, 28);
    expect(validDraft.basicValid(now), true);
    expect(
      validDraft.copyWith(birthDate: DateTime(2012, 9, 29)).basicValid(now),
      false,
    );
    expect(
      validDraft.copyWith(birthDate: DateTime(2012, 9, 28)).basicValid(now),
      true,
    );
    expect(validDraft.copyWith(ageConsent: false).basicValid(now), false);
    expect(validDraft.copyWith(privacyConsent: false).basicValid(now), false);
    expect(
      validDraft.copyWith(recommendationConsent: false).basicValid(now),
      true,
    );
    expect(validDraft.copyWith(handle: 'ab').handleValid, false);
    expect(validDraft.copyWith(handle: 'a b').handleValid, false);
    expect(validDraft.copyWith(handle: 'name_42').handleValid, true);
  });

  test(
    'denied permission stays recoverable and skip advances to taste',
    () async {
      final controller = create(
        permission: () async => RegistrationPermission.blocked,
      );
      addTearDown(controller.dispose);
      auth.emit(const AuthIdentity('user-a'));
      controller.model.update(() {
        controller.model.draft = validDraft;
        controller.model.step = RegistrationStep.location;
      });
      await controller.allowLocation();
      expect(controller.model.step, RegistrationStep.location);
      expect(controller.model.permissionBlocked, true);
      await controller.skipLocation();
      expect(controller.model.step, RegistrationStep.taste);
      expect(controller.model.draft.locationAllowed, false);
    },
  );

  test(
    'permission completion after disposal has no late state notification',
    () async {
      final pending = Completer<RegistrationPermission>();
      final controller = create(permission: () => pending.future);
      auth.emit(const AuthIdentity('user-a'));
      final request = controller.allowLocation();
      controller.dispose();
      pending.complete(RegistrationPermission.allowed);
      await request;
    },
  );

  test('permission response cannot advance a different account', () async {
    final pending = Completer<RegistrationPermission>();
    final controller = create(permission: () => pending.future);
    addTearDown(controller.dispose);
    auth.emit(const AuthIdentity('user-a'));
    final request = controller.allowLocation();
    auth.emit(const AuthIdentity('user-b'));
    pending.complete(RegistrationPermission.allowed);
    await request;
    expect(controller.model.step, RegistrationStep.country);
    expect(controller.model.draft.locationAllowed, false);
  });

  test('settings errors leave the permission screen recoverable', () async {
    final controller = RegistrationController(
      auth: auth,
      storage: RegistrationService(storage),
      onComplete: (_) async {},
      openSettings: () async => throw StateError('settings unavailable'),
    );
    addTearDown(controller.dispose);
    await controller.showLocationSettings();
    expect(controller.model.error, contains('설정을 열지 못했어요'));
  });

  test('completion saves once and stops after the account changes', () async {
    final pending = Completer<void>();
    var saves = 0;
    final service = RegistrationService(storage);
    final controller = RegistrationController(
      auth: auth,
      storage: service,
      onComplete: (_) {
        saves++;
        return pending.future;
      },
    );
    addTearDown(controller.dispose);
    auth.emit(const AuthIdentity('user-a'));
    controller.model.update(() => controller.model.draft = validDraft);
    final tastes = TastePreferences(
      priorities: [
        PreferenceCriterion.taste,
        PreferenceCriterion.value,
        PreferenceCriterion.ambience,
      ],
      cuisines: {Cuisine.korean, Cuisine.barbecue, Cuisine.soup},
    );
    final request = controller.complete(tastes);
    await controller.complete(tastes);
    expect(saves, 1);
    auth.emit(const AuthIdentity('user-b'));
    pending.complete();
    await request;
    expect(controller.model.completed, false);
    expect(service.load('user-a'), null);
  });

  testWidgets(
    'all eight steps complete, restore, and preserve back navigation',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = RegistrationService(storage);
      await service.save(
        'user-a',
        validDraft.copyWith(privacyConsent: false, ageConsent: false),
      );
      final app = AppController(
        PreferenceService(storage),
        auth: auth,
        registrationService: service,
      );
      await tester.pumpWidget(PindApp(controller: app));
      expect(find.byType(LoginScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('login-kakao')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      auth.emit(const AuthIdentity('user-a'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('country-screen')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('country-search')),
        'US',
      );
      await tester.pump();
      await tester.tap(find.text('United States'));
      await tester.pump();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('basic-screen')), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        null,
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-name')),
        '테스트 이름',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('개인정보 수집·이용 동의 (필수)'));
      await tester.tap(find.text('개인정보 수집·이용 동의 (필수)'));
      await tester.tap(find.text('만 14세 이상입니다 (필수)'));
      await tester.pump();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('handle-screen')), findsOneWidget);
      await tester.tap(find.byTooltip('이전'));
      await tester.pumpAndSettle();
      expect(find.text('테스트 이름'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pind 시작하기'));
      await tester.pumpAndSettle();
      expect(find.text('지금 있는 곳 주변부터\n보여드릴게요'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('skip-location')));
      await tester.pumpAndSettle();
      for (final text in ['맛', '분위기·공간', '가성비']) {
        await tester.tap(find.text(text));
      }
      await tester.pump();
      expect(find.text('1/3'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('지금 있는 곳 주변부터\n보여드릴게요'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('skip-location')));
      await tester.pumpAndSettle();
      expect(find.text('1순위'), findsOneWidget);
      expect(app.registration!.model.tasteDraft!.priorities.length, 3);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('외식 선호도를 선택해주세요.'), findsOneWidget);
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      for (final text in ['한식·백반', '고기구이', '국물·탕']) {
        await tester.tap(find.text(text));
      }
      await tester.pump();
      await tester.tap(find.text('내 취향 지도 만들기'));
      await tester.pumpAndSettle();
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(service.load('user-a')!.completed, true);
      expect(service.load('user-a')!.country, OnboardingCountry.usa);
      expect(service.load('user-a')!.recommendationConsent, false);
      expect(PreferenceService(storage).load()!.isComplete, true);
      final restored = AppController(
        PreferenceService(storage),
        auth: auth,
        registrationService: service,
      );
      await tester.pumpWidget(PindApp(controller: restored));
      await tester.pumpAndSettle();
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(tester.takeException(), null);
    },
  );

  testWidgets('leap-day year change clamps day and large text stays usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await RegistrationService(storage).save(
      'user-a',
      validDraft.copyWith(
        step: RegistrationStep.basic,
        birthDate: DateTime(2000, 2, 29),
      ),
    );
    auth.emit(const AuthIdentity('user-a'));
    final controller = create();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: PindTheme.data,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: RegistrationScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<DropdownButton<int>>(find.byKey(const ValueKey('birth-년')))
        .onChanged!(2025);
    await tester.pumpAndSettle();
    expect(controller.model.draft.birthDate, DateTime(2025, 2, 28));
    await tester.ensureVisible(find.text('맞춤 추천을 위한 정보 활용 (선택)'));
    expect(find.text('맞춤 추천을 위한 정보 활용 (선택)').hitTestable(), findsOneWidget);
    expect(tester.takeException(), null);
  });
}
