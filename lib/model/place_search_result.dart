import 'places.dart';

class PlaceFailure implements Exception {
  const PlaceFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class PlaceSearchResult {
  const PlaceSearchResult(
    this.places, {
    this.notice,
    this.googleSearchEnabled = false,
  });
  final List<Place> places;
  final String? notice;
  final bool googleSearchEnabled;
}
