import '../model/detail_preview_model.dart';
import '../model/places.dart';
import '../services/preview/detail_fixture.dart';
import 'place_detail_controller.dart';

/// Local QA data only; production main.dart does not create this controller.
class DetailPreviewController {
  final _context = LocalDetailContext();

  TestFriendship get relationship => _context.relationship;
  set relationship(TestFriendship value) => _context.relationship = value;

  PlaceDetailController details() => PlaceDetailController(
    place: detailPlace,
    places: detailPlaces,
    context: _context,
    preferences: detailPreferences,
    position: (_) async => const MapViewport(37.5712, 126.905),
  );
}
