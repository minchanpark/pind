import 'dart:math' as math;

class MapViewport {
  const MapViewport(
    this.latitude,
    this.longitude, {
    this.latitudeDelta = .08,
    this.longitudeDelta = .08,
  });
  final double latitude, longitude, latitudeDelta, longitudeDelta;
  static const seoul = MapViewport(37.5665, 126.978);
  bool get inKorea =>
      latitude >= 33 &&
      latitude <= 38.8 &&
      longitude >= 124.5 &&
      longitude <= 132;
  int get radiusMeters {
    final y = latitudeDelta.abs() * 111320 / 2;
    final x =
        longitudeDelta.abs() * 111320 * math.cos(latitude * math.pi / 180) / 2;
    return math.sqrt(x * x + y * y).clamp(500, 50000).round();
  }

  String get queryKey =>
      '${latitude.toStringAsFixed(3)}:${longitude.toStringAsFixed(3)}:${(radiusMeters / 500).round()}';
}

class PhotoAttribution {
  const PhotoAttribution(this.name, this.uri);
  final String name;
  final String? uri;
}

class PlacePhoto {
  const PlacePhoto(this.uri, this.sourceUri, this.authors);
  final String uri;
  final String? sourceUri;
  final List<PhotoAttribution> authors;

  factory PlacePhoto.fromJson(Map<String, dynamic> json) => PlacePhoto(
    json['uri'] as String,
    json['googleMapsUri'] as String?,
    _authors(json['attributions']),
  );
}

List<PhotoAttribution> _authors(dynamic raw) => (raw as List? ?? [])
    .map(
      (a) => PhotoAttribution(
        a['displayName'] as String? ?? '사진 제공자',
        a['uri'] as String?,
      ),
    )
    .toList();

enum PlaceProvider {
  sbiz('sbiz', '소상공인시장진흥공단'),
  pind('pind', 'Pind'),
  googlePlaces('google_places', 'Google Maps'),
  kakaoLocal('kakao_local', '카카오맵'),
  naverLocal('naver_local', '네이버 지도');

  const PlaceProvider(this.wireName, this.label);
  final String wireName, label;

  static PlaceProvider parse(String? value) => value == null
      ? googlePlaces
      : values.firstWhere(
          (p) => p.wireName == value,
          orElse: () => throw const FormatException('지원하지 않는 장소 출처입니다.'),
        );
}

class Place {
  const Place({
    this.id,
    this.provider = PlaceProvider.googlePlaces,
    required this.externalId,
    required this.name,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.mapsUri,
    this.imageUrl,
    this.photoSourceUri,
    this.authors = const [],
    this.gallery = const [],
    this.isOpen,
    this.hours = const [],
    this.summary,
    this.website,
    this.phone,
    this.reviewCount,
    this.utcOffsetMinutes,
    this.dataSourceUri,
    this.sourceDate,
    this.pindPostCount,
    this.googleSearchEnabled = false,
  });
  final int? id;
  final PlaceProvider provider;
  bool get isGoogle => provider == PlaceProvider.googlePlaces;
  bool get isCatalog =>
      provider == PlaceProvider.sbiz || provider == PlaceProvider.pind;
  bool get hasRichContent => isGoogle || isCatalog;
  bool get canShowOnMap => isGoogle || isCatalog;
  String get key => '${provider.wireName}:$externalId';
  String get sourceLabel => provider.label;
  String get sourceAction => switch (provider) {
    PlaceProvider.sbiz => '공공데이터 원본',
    PlaceProvider.pind => '지도에서 확인',
    PlaceProvider.googlePlaces => 'Google Maps에서 길찾기',
    PlaceProvider.kakaoLocal => '카카오맵에서 확인',
    PlaceProvider.naverLocal => '네이버 지도에서 검색',
  };
  final String externalId, name, category, address, mapsUri;
  final double latitude, longitude;
  final String? imageUrl, photoSourceUri, summary, website, phone;
  final bool? isOpen;
  final List<String> hours;
  final List<PhotoAttribution> authors;
  final List<PlacePhoto> gallery;
  final int? reviewCount, utcOffsetMinutes, pindPostCount;
  final String? dataSourceUri, sourceDate;
  final bool googleSearchEnabled;

  factory Place.fromJson(Map<String, dynamic> json) {
    final provider = PlaceProvider.parse(json['provider'] as String?);
    final rich =
        provider == PlaceProvider.googlePlaces ||
        provider == PlaceProvider.sbiz ||
        provider == PlaceProvider.pind;
    return Place(
      provider: provider,
      dataSourceUri: json['dataSourceUri'] as String?,
      sourceDate: json['sourceDate'] as String?,
      pindPostCount: json['pindPostCount'] as int?,
      googleSearchEnabled: json['googleSearchEnabled'] == true,
      id: rich ? (json['internalId'] as num?)?.toInt() : null,
      externalId: json['externalPlaceId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      mapsUri: (json['sourceUri'] ?? json['googleMapsUri']) as String,
      imageUrl: rich ? json['heroImageUrl'] as String? : null,
      photoSourceUri: rich ? json['photoGoogleMapsUri'] as String? : null,
      authors: rich ? _authors(json['photoAttributions']) : const [],
      gallery: (rich ? json['gallery'] as List? ?? [] : const [])
          .map((p) => PlacePhoto.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList(),
      isOpen: rich ? json['isOpenNow'] as bool? : null,
      hours: rich
          ? List<String>.from(json['weekdayDescriptions'] as List? ?? [])
          : const [],
      summary: rich ? json['editorialSummary'] as String? : null,
      website: rich ? json['websiteUri'] as String? : null,
      phone: rich ? json['phoneNumber'] as String? : null,
      reviewCount: rich ? (json['userRatingCount'] as num?)?.toInt() : null,
      utcOffsetMinutes: rich
          ? (json['utcOffsetMinutes'] as num?)?.toInt()
          : null,
    );
  }
}
