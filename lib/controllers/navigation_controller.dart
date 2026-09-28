import '../model/navigation_model.dart';

class NavigationController {
  final model = NavigationModel();

  void select(PindTab tab) => model.select(tab);

  bool beginCompose() {
    if (model.composing) return false;
    model.composing = true;
    return true;
  }

  void endCompose() => model.composing = false;

  void dispose() => model.dispose();
}
