import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pind_flutter/controllers/app_controller.dart';
import 'package:pind_flutter/controllers/onboarding_controller.dart';
import 'package:pind_flutter/controllers/place_detail_controller.dart';
import 'package:pind_flutter/model/place_context.dart';
import 'package:pind_flutter/model/preferences.dart';
import 'package:pind_flutter/services/place_context_service.dart';
import 'package:pind_flutter/services/place_service.dart';
import 'package:pind_flutter/services/preference_service.dart';
import 'package:pind_flutter/services/preview/detail_fixture.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Context implements PlaceContextService {
  _Context({required this.read, this.write});

  final Future<PlaceContext> Function() read;
  final Future<void> Function(bool)? write;
  int reads = 0;
  int writes = 0;

  @override
  Future<PlaceContext> load(int placeId) {
    reads++;
    return read();
  }

  @override
  Future<void> setSaved(int placeId, bool saved) async {
    writes++;
    await write?.call(saved);
  }
}

class _Preferences extends PreferenceService {
  _Preferences(super.storage, this.pending);
  final Future<void> pending;

  @override
  Future<void> save(TastePreferences preferences) => pending;
}

PlaceDetailController detail({
  PlaceService? places,
  PlaceContextService? context,
}) => PlaceDetailController(
  place: detailPlace,
  places: places ?? detailPlaces,
  context: context,
  position: (_) async => null,
);

void main() {
  test('older detail context cannot overwrite a newer reload', () async {
    final first = Completer<PlaceContext>();
    final second = Completer<PlaceContext>();
    var contextReads = 0;
    final context = _Context(
      read: () => contextReads++ == 0 ? first.future : second.future,
    );
    final controller = detail(context: context);
    addTearDown(controller.dispose);

    final oldRequest = controller.load();
    await Future<void>.delayed(Duration.zero);
    final newRequest = controller.load();
    await Future<void>.delayed(Duration.zero);
    second.complete(const PlaceContext(saved: false));
    await newRequest;
    first.complete(const PlaceContext(saved: true));
    await oldRequest;

    expect(context.reads, 2);
    expect(controller.model.saved, false);
    expect(controller.model.social!.saved, false);
  });

  test(
    'closing detail during lookup skips context and state updates',
    () async {
      final pending = Completer<Map<String, dynamic>>();
      final context = _Context(
        read: () async => const PlaceContext(saved: true),
      );
      final controller = detail(
        places: PlaceService((_) => pending.future),
        context: context,
      );
      var changes = 0;
      controller.model.addListener(() => changes++);
      final request = controller.load();
      expect(changes, 1);
      controller.dispose();
      pending.complete({'place': detailPayload});
      await request;

      expect(context.reads, 0);
      expect(changes, 1);
    },
  );

  test(
    'save prevents duplicate writes and rolls back a failed write',
    () async {
      final pending = Completer<void>();
      final context = _Context(
        read: () async => const PlaceContext(saved: false),
        write: (_) => pending.future,
      );
      final controller = detail(context: context);
      addTearDown(controller.dispose);
      await controller.load();

      final save = controller.save();
      expect(controller.model.saved, true);
      expect(controller.model.saving, true);
      await controller.save();
      expect(context.writes, 1);
      pending.completeError(StateError('offline'));
      expect(await save, '저장하지 못했어요. 다시 시도해 주세요.');
      expect(controller.model.saved, false);
      expect(controller.model.saving, false);
    },
  );

  test('social failure keeps successfully loaded place details', () async {
    final controller = detail(
      context: _Context(read: () async => throw StateError('offline')),
    );
    addTearDown(controller.dispose);
    await controller.load();

    expect(controller.model.place.name, detailPlace.name);
    expect(controller.model.loading, false);
    expect(controller.model.detailError, false);
    expect(controller.model.contextError, true);
    expect(await controller.save(), contains('상세 정보를 다시 불러와 주세요'));
  });

  test(
    'app state remains unchanged when preferences fail to persist',
    () async {
      SharedPreferences.setMockInitialValues({});
      final pending = Completer<void>();
      final controller = AppController(
        _Preferences(await SharedPreferences.getInstance(), pending.future),
      );
      addTearDown(controller.dispose);
      final save = controller.savePreferences(detailPreferences);
      pending.completeError(StateError('disk full'));
      await expectLater(save, throwsStateError);
      expect(controller.model.preferences, null);
    },
  );

  test('disposed app ignores a pending preference completion', () async {
    SharedPreferences.setMockInitialValues({});
    final pending = Completer<void>();
    final controller = AppController(
      _Preferences(await SharedPreferences.getInstance(), pending.future),
    );
    var changes = 0;
    controller.model.addListener(() => changes++);
    final save = controller.savePreferences(detailPreferences);
    controller.dispose();
    pending.complete();
    await save;
    expect(changes, 0);
  });

  test(
    'onboarding prevents duplicate submission and handles disposal',
    () async {
      final pending = Completer<void>();
      var saves = 0;
      final controller = OnboardingController(
        initial: detailPreferences,
        onComplete: (_) {
          saves++;
          return pending.future;
        },
      );
      await controller.next();
      await controller.next();
      final save = controller.next();
      await controller.next();
      expect(saves, 1);
      expect(controller.model.saving, true);
      controller.dispose();
      pending.complete();
      await save;
    },
  );
}
