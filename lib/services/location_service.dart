import 'package:geolocator/geolocator.dart';

import '../model/place_search_result.dart';
import '../model/places.dart';
import '../model/registration_model.dart';

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
      throw const PlaceFailure('기기의 위치 서비스를 켜 주세요.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PlaceFailure('위치 권한 없이도 지도를 직접 이동하거나 검색할 수 있어요.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 15),
      ),
    );
    final viewport = MapViewport(position.latitude, position.longitude);
    if (!viewport.inKorea) {
      throw const PlaceFailure('현재 위치가 한국 밖이에요. 한국의 장소를 검색해 주세요.');
    }
    return viewport;
  }

  static double distance(MapViewport position, Place place) =>
      Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.latitude,
        place.longitude,
      );
}
