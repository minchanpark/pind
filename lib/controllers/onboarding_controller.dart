import '../model/onboarding_model.dart';
import '../model/preferences.dart';

class OnboardingController {
  OnboardingController({TastePreferences? initial, required this.onComplete})
    : model = OnboardingModel(initial);

  final OnboardingModel model;
  final Future<void> Function(TastePreferences) onComplete;
  bool _disposed = false;

  void move(int step) {
    if (model.saving || step < 0 || step > 2) return;
    model.update(() {
      model.step = step;
      model.error = null;
    });
  }

  void togglePriority(PreferenceCriterion value) => model.update(
    () => model.preferences = model.preferences.togglePriority(value),
  );

  void toggleOccasion(DiningOccasion value) => model.update(
    () => model.preferences = model.preferences.toggleOccasion(value),
  );

  void toggleCuisine(Cuisine value) => model.update(
    () => model.preferences = model.preferences.toggleCuisine(value),
  );

  Future<void> next() async {
    if (model.saving || !model.canContinue) return;
    if (model.step < 2) {
      move(model.step + 1);
      return;
    }
    model.update(() {
      model.saving = true;
      model.error = null;
    });
    try {
      await onComplete(model.preferences);
    } catch (_) {
      if (!_disposed) {
        model.update(() => model.error = '저장하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (!_disposed) model.update(() => model.saving = false);
    }
  }

  void dispose() {
    _disposed = true;
    model.dispose();
  }
}
