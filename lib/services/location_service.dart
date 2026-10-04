import 'package:geolocator/geolocator.dart';

import '../model/place_search_result.dart';
import '../model/places.dart';
import '../model/registration_model.dart';
import '../l10n/l10n.dart';

class LocationService {
  static Future<RegistrationPermission> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => RegistrationPermission.allowed,
      LocationPermission.deniedForever => RegistrationPermission.blocked,
      _ => RegistrationPermission.denied,
    };
  }

  static Future<bool> openSettings() => Geolocator.openAppSettings();

  static Future<MapViewport?> position(bool request) async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (request && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return MapViewport(position.latitude, position.longitude);
  }

  static Future<MapViewport> mapPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw PlaceFailure(l10n.errLocationServicesOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw PlaceFailure(l10n.errLocationDenied);
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 15),
      ),
    );
    final viewport = MapViewport(position.latitude, position.longitude);
    if (!viewport.inKorea) {
      throw PlaceFailure(l10n.errOutsideKorea);
    }
    return viewport;
  }

  /// Live position while walking a route; permission is already granted.
  static Stream<MapViewport> track() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3,
    ),
  ).map((p) => MapViewport(p.latitude, p.longitude));

  static double distance(MapViewport position, Place place) =>
      Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.latitude,
        place.longitude,
      );
}
