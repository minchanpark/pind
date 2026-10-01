import '../../model/place_search_result.dart';

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../components/pind_glass.dart';
import '../theme.dart';
import '../../model/preferences.dart';
import '../../model/places.dart';
import '../../controllers/explore_controller.dart';
import 'place_sheet.dart';
import 'map_filter_chip.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    this.controller,
    required this.mapsEnabled,
    required this.onEditPreferences,
    this.isActive = true,
    this.bottomClearance = 0,
    this.preferences,
  });
  final ExploreController? controller;
  final TastePreferences? preferences;
  final bool mapsEnabled;
  final VoidCallback onEditPreferences;
  final bool isActive;
  final double bottomClearance;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  ExploreController? get controller => widget.controller;
  final query = TextEditingController();
  GoogleMapController? map;
  bool searchMode = false;

  /// On iOS, Flutter widgets above the map platform view are painted into a
  /// separate overlay, so the sheet's BackdropFilter blurs only the map
  /// natively. Controls under the sheet blur themselves instead.
  bool placeOpen = false;
  bool get locating => controller?.model.locating ?? false;
  String category = '전체';
  int markerGeneration = 0;
  int searchGeneration = 0;
  int seenPublishedRevision = 0;
  Set<Marker> markers = {};
  List<Place>? markerPlaces;
  // Patterns also cover public-data categories (요리 주점, 돼지고기 구이/찜, 빵/도넛...).
  static const categories = {
    '전체': '',
    '☕ 카페': 'cafe|coffee|카페|커피',
    '🍺 술집': 'bar(?!becue)|pub|술집|주점|맥주|호프|포차|이자카야|와인',
    '🥩 고기': 'barbecue|bbq|steak|고기|곱창|족발|보쌈|갈비|삼겹',
    '🍜 면': 'noodle|ramen|면|국수',
    '🍰 디저트': 'dessert|bakery|디저트|베이커리|빵|도넛|떡|아이스크림|빙수|케이크',
  };

  @override
  void initState() {
    super.initState();
    controller?.model.addListener(changed);
    controller?.load();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller?.model.removeListener(changed);
      controller?.model.addListener(changed);
      markerPlaces = null;
      markers = {};
      controller?.load(force: true);
    }
  }

  void changed() {
    if (!mounted) return;
    if (controller!.publishedRevision != seenPublishedRevision) {
      seenPublishedRevision = controller!.publishedRevision;
      searchGeneration++;
      query.clear();
      searchMode = false;
      category = '전체';
      final viewport = controller!.viewport;
      map
          ?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(viewport.latitude, viewport.longitude),
              14,
            ),
          )
          .catchError((_) {});
    }
    setState(() {});
    if (markerPlaces != controller!.places) {
      markerPlaces = controller!.places;
      updateMarkers();
    }
  }

  List<Place> get visiblePlaces {
    final places = controller?.places ?? <Place>[];
    final pattern = categories[category]!;
    if (pattern.isEmpty) return places;
    return places.where((p) => _inCategory(pattern, p)).toList();
  }

  Future<void> updateMarkers() async {
    final generation = ++markerGeneration;
    final result = await Future.wait(
      // Cross-map display rights for supplemental providers are not confirmed.
      visiblePlaces
          .where((p) => p.canShowOnMap)
          .map(
            (p) async => Marker(
              markerId: MarkerId(p.key),
              position: LatLng(p.latitude, p.longitude),
              icon: await placeMarkerIcon(p),
              onTap: () => showPlace(p),
            ),
          ),
    );
    if (mounted && generation == markerGeneration) {
      setState(() => markers = result.toSet());
    }
  }

  @override
  void dispose() {
    markerGeneration++;
    controller?.model.removeListener(changed);
    map?.dispose();
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    if (controller == null) return;
    final generation = ++searchGeneration;
    FocusScope.of(context).unfocus();
    setState(() {
      searchMode = query.text.trim().isNotEmpty;
      category = '전체';
    });
    if (searchMode) {
      await controller?.search(query.text);
      if (!mounted || generation != searchGeneration || !searchMode) return;
      final mapPlaces = controller!.places.where((p) => p.canShowOnMap);
      if (mounted && mapPlaces.isNotEmpty) {
        final first = mapPlaces.first;
        await map?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(first.latitude, first.longitude),
            14,
          ),
        );
      }
      // Explicit searches keep all providers reachable without a nearby-list CTA.
      if (mounted && generation == searchGeneration) showResults();
    } else {
      await controller?.load();
    }
  }

  Future<void> searchGoogle() async {
    final generation = ++searchGeneration;
    await controller?.searchGoogle();
    if (mounted && generation == searchGeneration) showResults();
  }

  Future<void> locate() async {
    if (controller == null || locating) return;
    try {
      final location = await controller!.locate();
      if (!mounted) return;
      query.clear();
      setState(() => searchMode = false);
      await map?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          14,
        ),
      );
      await controller?.load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PlaceFailure
                  ? error.message
                  : '현재 위치를 확인하지 못했어요. 검색으로 계속할 수 있어요.',
            ),
          ),
        );
      }
    }
  }

  Future<void> showPlace(Place place) async {
    final detail = controller!.details(place, widget.preferences);
    setState(() => placeOpen = true);
    await showPlaceSheet(context, detail);
    if (mounted) setState(() => placeOpen = false);
  }

  void showResults() {
    if (!mounted ||
        !widget.isActive ||
        !searchMode ||
        controller!.loading ||
        controller!.error != null ||
        visiblePlaces.isEmpty) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .62,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '$category · ${visiblePlaces.length}곳',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            for (final place in visiblePlaces)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: place.imageUrl == null
                    ? const Icon(Icons.restaurant)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          place.imageUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stack) =>
                              const Icon(Icons.restaurant),
                        ),
                      ),
                title: Text(place.name),
                subtitle: Text('${place.address}\n${place.sourceLabel}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showPlace(place);
                },
              ),
            Center(
              child: Text(
                visiblePlaces.map((p) => p.sourceLabel).toSet().join(' · '),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Figma 524:28096. Keep the exported icons at their original dimensions.
  Widget searchBar() {
    const height = 45.4636;
    final radius = BorderRadius.circular(height / 2);
    const textStyle = TextStyle(
      fontSize: 14.4667,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.5,
    );
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, .05),
              offset: Offset(0, 1),
              blurRadius: 1,
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, .05),
              offset: Offset(0, 6),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: CustomPaint(
              foregroundPainter: const _SearchBarHighlights(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(251, 251, 253, .72),
                  borderRadius: radius,
                  border: Border.all(color: PindTheme.border),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 41.2927,
                        child: IconButton(
                          tooltip: '검색',
                          padding: const EdgeInsets.only(left: 9.2667),
                          icon: SvgPicture.asset(
                            'assets/explore/search_icon.svg',
                            width: 15.4927,
                            height: 15.4927,
                          ),
                          onPressed: controller == null ? null : search,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: query,
                          onSubmitted: (_) => search(),
                          textInputAction: TextInputAction.search,
                          textAlignVertical: TextAlignVertical.center,
                          style: textStyle.copyWith(color: PindTheme.ink),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '장소, 메뉴, 분위기 검색',
                            hintStyle: textStyle.copyWith(
                              color: const Color(0xFFABABAB),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: (height - 14.4667 * 1.5) / 2,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40.2569,
                        child: IconButton(
                          tooltip: '취향 수정',
                          padding: const EdgeInsets.only(right: 9.2667),
                          icon: SvgPicture.asset(
                            'assets/explore/filter_icon.svg',
                            width: 14.457,
                            height: 14.457,
                          ),
                          onPressed: widget.onEditPreferences,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        if (widget.mapsEnabled)
          GoogleMap(
            style: pindMapStyle,
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.5665, 126.978),
              zoom: 13,
            ),
            onMapCreated: (value) => map = value,
            markers: markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            padding: EdgeInsets.only(
              bottom: 100 + widget.bottomClearance,
              top: 150,
            ),
          )
        else
          Container(
            color: PindTheme.surface,
            alignment: Alignment.center,
            child: const Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: PindTheme.muted),
                  SizedBox(height: 12),
                  Text('지도를 불러올 수 없어요.'),
                  Text('장소 검색과 목록으로 탐색할 수 있어요.', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.5333, 12.4001, 16.5333, 0),
            child: Column(
              children: [
                searchBar(),
                if (searchMode)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      label: const Text('검색 지우고 주변 보기'),
                      onPressed: () {
                        query.clear();
                        search();
                      },
                    ),
                  ),
                if (searchMode && (controller?.googleSearchEnabled ?? false))
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      label: const Text('Google에서 추가 검색'),
                      onPressed: controller!.loading ? null : searchGoogle,
                    ),
                  ),
                if (controller?.notice != null)
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(controller!.notice!),
                    ),
                  ),
                if (controller?.loading ?? false)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  ),
                if (controller?.error != null)
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      title: Text(controller!.error!),
                      trailing: TextButton(
                        onPressed: search,
                        child: const Text('재시도'),
                      ),
                    ),
                  ),
                if (controller == null)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('연결 설정 후 장소를 탐색할 수 있어요.'),
                  ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: placeOpen ? 20 : 0),
            duration: const Duration(milliseconds: 250),
            builder: (_, sigma, child) => ImageFiltered(
              enabled: sigma > 0,
              imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: child,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  // 14pt between the chip glass and the nav bar (nav top is
                  // clearance − 12); the chip's 44pt hit box adds ~3pt below.
                  bottom: widget.bottomClearance - 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Column(
                            spacing: 4,
                            children: [
                              if (widget.mapsEnabled) ...[
                                _MapGlassButton(
                                  tooltip: '확대',
                                  onPressed: () =>
                                      map?.animateCamera(CameraUpdate.zoomIn()),
                                  child: const Icon(Icons.add),
                                ),
                                _MapGlassButton(
                                  tooltip: '축소',
                                  onPressed: () => map?.animateCamera(
                                    CameraUpdate.zoomOut(),
                                  ),
                                  child: const Icon(Icons.remove),
                                ),
                              ],
                              _MapGlassButton(
                                tooltip: '현재 위치',
                                onPressed: locating ? null : locate,
                                child: locating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.my_location),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            for (final label in categories.keys)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: MapFilterChip(
                                  label: label,
                                  selected: category == label,
                                  onTap: () {
                                    setState(() => category = label);
                                    updateMarkers();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// The inset highlights sit inside the border of the Figma glass surface.
class _SearchBarHighlights extends CustomPainter {
  const _SearchBarHighlights();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = (Offset.zero & size).deflate(1);
    final shape = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(bounds.height / 2),
    );
    canvas.save();
    canvas.clipRRect(shape);
    for (final shadow in const [
      BoxShadow(
        color: Color.fromRGBO(138, 140, 150, .03),
        offset: Offset(0, -1),
        blurRadius: 2.5,
      ),
      BoxShadow(
        color: Color.fromRGBO(255, 255, 255, .9),
        offset: Offset(0, 2),
        blurRadius: 2,
      ),
      BoxShadow(color: Color.fromRGBO(255, 255, 255, .95), blurRadius: 1.5),
    ]) {
      final outside = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(bounds.inflate(16))
        ..addRRect(shape.shift(shadow.offset));
      canvas.drawPath(
        outside,
        Paint()
          ..color = shadow.color
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            shadow.blurRadius / 2,
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SearchBarHighlights oldDelegate) => false;
}

/// Map control in the same liquid glass as the filter chips and nav bar.
class _MapGlassButton extends StatelessWidget {
  const _MapGlassButton({
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    child: Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: PindGlass(
              radius: 20,
              child: SizedBox.square(
                dimension: 38,
                child: Center(
                  child: IconTheme.merge(
                    data: const IconThemeData(size: 22, color: PindTheme.ink),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

bool _inCategory(String pattern, Place place) => RegExp(
  pattern,
  caseSensitive: false,
).hasMatch('${place.category} ${place.name}');

/// Map pin emoji: the first category chip the place falls under, else 🍽️.
String markerEmoji(Place place) {
  for (final MapEntry(:key, :value)
      in _ExploreScreenState.categories.entries.skip(1)) {
    if (_inCategory(value, place)) return key.split(' ').first;
  }
  return '🍽️';
}

/// [placeMarkerIcon] as a widget, for lists that should match the map.
class PlacePin extends StatelessWidget {
  const PlacePin(this.place, {super.key, this.size = 48});
  final Place place;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: PindTheme.purple, width: size * 5 / 112),
    ),
    child: Text(
      markerEmoji(place),
      style: TextStyle(fontSize: size * 48 / 112, height: 1),
    ),
  );
}

/// Hides Google's own business POIs so only Pind pins show.
const pindMapStyle =
    '[{"featureType":"poi.business","stylers":[{"visibility":"off"}]}]';

/// The map screen's pin. Emoji markers are six fixed images, so each is drawn
/// once and reused by every map.
Future<BitmapDescriptor> placeMarkerIcon(Place place) {
  final emoji = markerEmoji(place);
  return _markerIcons.putIfAbsent(emoji, () => _emojiMarker(emoji));
}

final _markerIcons = <String, Future<BitmapDescriptor>>{};

Future<BitmapDescriptor> _emojiMarker(String emoji) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawCircle(
    const Offset(56, 56),
    54,
    Paint()..color = PindTheme.purple,
  );
  canvas.drawCircle(const Offset(56, 56), 49, Paint()..color = Colors.white);
  // Font size keeps the Figma 531:19871 emoji-to-pin ratio (29px glyph in a 57px pin).
  final label = TextPainter(
    text: TextSpan(text: emoji, style: const TextStyle(fontSize: 48)),
    textDirection: TextDirection.ltr,
  )..layout();
  label.paint(
    canvas,
    Offset((112 - label.width) / 2, (112 - label.height) / 2),
  );
  label.dispose();
  final picture = recorder.endRecording();
  final bitmap = await picture.toImage(112, 112);
  picture.dispose();
  final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
  bitmap.dispose();
  return BitmapDescriptor.bytes(
    data!.buffer.asUint8List(),
    width: 56,
    height: 56,
  );
}
