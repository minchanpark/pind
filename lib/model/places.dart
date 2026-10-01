class MapViewport {
  const MapViewport(this.latitude, this.longitude);
  final double latitude, longitude;
  static const seoul = MapViewport(37.5665, 126.978);
  bool get inKorea =>
      latitude >= 33 &&
      latitude <= 38.8 &&
      longitude >= 124.5 &&
      longitude <= 132;
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

/// A published post as shown in the place detail posts tab.
class PlacePost {
  const PlacePost({
    this.id,
    required this.author,
    this.handle,
    this.avatar,
    this.body = '',
    this.ratings = const {},
    this.photos = const [],
    this.likeCount = 0,
    this.liked = false,
    this.mine = false,
  });
  final int? id;
  final String author, body;
  final String? handle, avatar;
  final int likeCount;
  final bool liked;

  /// Written by me: the detail sheet offers 삭제.
  final bool mine;

  /// Criterion name to the author's 1–5 score.
  final Map<String, int> ratings;
  final List<String> photos;

  /// [liked] toggled, with the count following it.
  PlacePost withLike(bool value) => PlacePost(
    id: id,
    author: author,
    handle: handle,
    avatar: avatar,
    body: body,
    ratings: ratings,
    photos: photos,
    liked: value,
    likeCount: likeCount + (value == liked ? 0 : (value ? 1 : -1)),
    mine: mine,
  );

  factory PlacePost.fromJson(Map<String, dynamic> json) => PlacePost(
    id: (json['id'] as num?)?.toInt(),
    author: json['author'] as String? ?? 'Pind 사용자',
    handle: json['handle'] as String?,
    avatar: json['avatar'] as String?,
    body: json['body'] as String? ?? '',
    ratings: {
      for (final e in (json['ratings'] as Map? ?? {}).entries)
        e.key as String: (e.value as num).round(),
    },
    photos: List<String>.from(json['photos'] as List? ?? []),
    likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    liked: json['liked'] == true,
    mine: json['mine'] == true,
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
    this.insightSummary,
    this.insightLines = const {},
    this.posts = const [],
  });
  final int? id;
  final PlaceProvider provider;
  bool get isGoogle => provider == PlaceProvider.googlePlaces;
  bool get isCatalog =>
      provider == PlaceProvider.sbiz || provider == PlaceProvider.pind;
  bool get hasRichContent => isGoogle || isCatalog;
  bool get canShowOnMap => (isGoogle || isCatalog) && (pindPostCount ?? 0) > 0;
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

  /// AI digest of Pind posts; one-liners are keyed by criterion name.
  final String? insightSummary;
  final Map<String, String> insightLines;
  final List<PlacePost> posts;

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
      posts: [
        for (final p in json['posts'] as List? ?? [])
          PlacePost.fromJson(Map<String, dynamic>.from(p as Map)),
      ],
      insightSummary: (json['insight'] as Map?)?['summary'] as String?,
      insightLines: Map<String, String>.from(
        (json['insight'] as Map?)?['criteria'] as Map? ?? {},
      ),
      utcOffsetMinutes: rich
          ? (json['utcOffsetMinutes'] as num?)?.toInt()
          : null,
    );
  }
}
