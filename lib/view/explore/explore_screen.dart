import '../../model/place_search_result.dart';

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../components/pind_glass.dart';
import '../design_system.dart';
import '../../model/preferences.dart';
import '../../model/places.dart';
import '../../model/place_context.dart';
import '../../model/walking_route.dart';
import '../../controllers/explore_controller.dart';
import 'place_sheet.dart';
import 'agent_search_page.dart';
import 'map_filter_chip.dart';
import 'nearby_ranking_sheet.dart';
import '../../l10n/l10n.dart';

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
  GoogleMapController? map;

  /// On iOS, Flutter widgets above the map platform view are painted into a
  /// separate overlay, so the sheet's BackdropFilter blurs only the map
  /// natively. Controls under the sheet blur themselves instead.
  bool placeOpen = false;
  bool get locating => controller?.model.locating ?? false;
  String category = '전체';
  int markerGeneration = 0;
  int seenPublishedRevision = 0;
  Set<Marker> markers = {};
  List<Place>? markerPlaces;

  /// 길찾기: the place being walked to, its route and where I am on it.
  Place? walkTarget;
  WalkingRoute? route;
  RouteProgress? progress;
  Marker? walkMarker;
  bool rerouting = false;
  DateTime lastRoute = DateTime(0);
  int walkGeneration = 0;
  StreamSubscription<MapViewport>? walking;
  bool get arrived => (progress?.meters ?? double.infinity) < 20;
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
    if (controller!.model.walkingTo != walkTarget) {
      startWalk(controller!.model.walkingTo);
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

  /// Fetches the walk from my position, then follows me along it. A null
  /// [target] ends guidance.
  Future<void> startWalk(Place? target) async {
    final generation = ++walkGeneration;
    walking?.cancel();
    walking = null;
    setState(() {
      walkTarget = target;
      route = null;
      progress = null;
      walkMarker = null;
      rerouting = false;
    });
    if (target == null) return;
    final explore = controller!;
    try {
      final here = await explore.position(true);
      if (here == null) {
        throw PlaceFailure(l10n.errLocationCheckPermission);
      }
      final found = await explore.repository.walkingRoute(here, target);
      if (!mounted || generation != walkGeneration) return;
      setState(() {
        route = found;
        progress = found.progress(here);
        lastRoute = DateTime.now();
      });
      fitRoute(found);
      if (widget.mapsEnabled) {
        placeMarkerIcon(target).then((icon) {
          if (!mounted || generation != walkGeneration) return;
          setState(
            () => walkMarker = Marker(
              markerId: const MarkerId('walk-to'),
              position: LatLng(target.latitude, target.longitude),
              icon: icon,
            ),
          );
        });
      }
      walking = explore.track().listen(moved, onError: (_) {});
    } catch (error) {
      if (!mounted || generation != walkGeneration) return;
      // A failed route must not hold the map: say why, give search back.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is PlaceFailure ? error.message : l10n.errWalkRoute,
          ),
        ),
      );
      explore.endWalk();
    }
  }

  /// Trims the walked part; off the line by 50m asks for a new route, at most
  /// every 15s.
  void moved(MapViewport at) {
    final current = route;
    if (current == null || !mounted) return;
    final next = current.progress(at, from: progress?.segment ?? 0);
    setState(() => progress = next);
    if (arrived) {
      walking?.cancel();
      walking = null;
    } else if (next.offRoute > 50 &&
        !rerouting &&
        DateTime.now().difference(lastRoute) > const Duration(seconds: 15)) {
      reroute(at);
    }
  }

  Future<void> reroute(MapViewport at) async {
    final generation = walkGeneration, target = walkTarget!;
    setState(() => rerouting = true);
    lastRoute = DateTime.now();
    try {
      final found = await controller!.repository.walkingRoute(at, target);
      if (!mounted || generation != walkGeneration) return;
      setState(() {
        route = found;
        progress = found.progress(at);
      });
    } catch (_) {
      // Keep guiding along the old line.
    } finally {
      if (mounted && generation == walkGeneration) {
        setState(() => rerouting = false);
      }
    }
  }

  void fitRoute(WalkingRoute r) {
    final lats = r.points.map((p) => p.latitude);
    final lngs = r.points.map((p) => p.longitude);
    map
        ?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(lats.reduce(math.min), lngs.reduce(math.min)),
              northeast: LatLng(lats.reduce(math.max), lngs.reduce(math.max)),
            ),
            48,
          ),
        )
        .catchError((_) {});
  }

  @override
  void dispose() {
    walking?.cancel();
    markerGeneration++;
    controller?.model.removeListener(changed);
    map?.dispose();
    super.dispose();
  }

  /// Figma 617:23469. The page answers itself, around the map center; a
  /// result opens its detail over the page.
  Future<void> openSearch() async {
    final explore = controller!;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AgentSearchPage(
          search: (q) async => explore.agentSearch(
            q,
            await mapCenter(),
            taste: widget.preferences,
          ),
          preferences: widget.preferences,
          onOpen: (page, place) =>
              showPlaceSheet(page, explore.details(place, widget.preferences)),
          onSetSaved: explore.placeContext?.setSaved,
        ),
      ),
    );
  }

  Future<void> locate() async {
    if (controller == null || locating) return;
    try {
      final location = await controller!.locate();
      if (!mounted) return;
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
              error is PlaceFailure ? error.message : l10n.errLocationUseSearch,
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

  /// The chip's places within 10km, ranked (Figma 671:33852).
  Future<void> showRanking(String label) async {
    final explore = controller;
    if (explore == null || explore.nearby == null) return;
    final pattern = categories[label]!;
    await showNearbyRanking(
      context,
      title: mapCategoryLabel(label),
      load: () async => explore.nearbyRanking(await mapCenter()),
      include: (p) => pattern.isEmpty || _inCategory(pattern, p),
      preferences: widget.preferences,
      onOpen: focusPlace,
      onSetSaved: explore.placeContext?.setSaved,
    );
  }

  /// Centers the map on [place]; its pin opens the detail as usual.
  void focusPlace(Place place) => map
      ?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(place.latitude, place.longitude), 16),
      )
      .catchError((_) {});

  /// Fallback origin when my location is unavailable.
  Future<MapViewport> mapCenter() async {
    try {
      final b = await map!.getVisibleRegion();
      return MapViewport(
        (b.northeast.latitude + b.southwest.latitude) / 2,
        (b.northeast.longitude + b.southwest.longitude) / 2,
      );
    } catch (_) {
      return controller!.viewport;
    }
  }

  /// Replaces the search bar while walking: where to, what's left, stop.
  Widget walkBanner(Place target) {
    final p = progress, r = route;
    final String status;
    if (p == null || r == null) {
      status = l10n.walkFinding;
    } else if (arrived) {
      status = l10n.walkArrived;
    } else if (rerouting) {
      status = l10n.walkRerouting;
    } else {
      // TMAP's pace for this route, else ~1.2m/s.
      final seconds = r.meters > 0
          ? r.seconds * p.meters / r.meters
          : p.meters / 1.2;
      status = l10n.walkRemaining(
        formatDistance(p.meters),
        math.max(1, (seconds / 60).round()),
      );
    }
    return PindGlass(
      key: const ValueKey('walk-banner'),
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        spacing: 10,
        children: [
          const ExcludeSemantics(
            child: Text('🚶', style: TextStyle(fontSize: 22)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  l10n.walkTo(target.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: PindType.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: PindColors.ink,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: PindType.label,
                    color: PindColors.muted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: controller!.endWalk,
            child: Text(
              arrived ? l10n.close : l10n.walkEnd,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: PindColors.purple,
              ),
            ),
          ),
        ],
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
                  border: Border.all(color: PindColors.border),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 41.2927,
                        child: IconButton(
                          tooltip: l10n.search,
                          padding: const EdgeInsets.only(left: 9.2667),
                          icon: SvgPicture.asset(
                            'assets/explore/search_icon.svg',
                            width: 15.4927,
                            height: 15.4927,
                          ),
                          onPressed: controller == null ? null : openSearch,
                        ),
                      ),
                      // One button: the query is typed on the agent page.
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: l10n.openSearch,
                          excludeSemantics: true,
                          child: InkWell(
                            key: const ValueKey('map-search-button'),
                            onTap: controller == null ? null : openSearch,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l10n.mapSearchHint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textStyle.copyWith(
                                  color: PindColors.placeholder,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40.2569,
                        child: IconButton(
                          tooltip: l10n.editTaste,
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
            // While walking: only the destination, the line left to walk and
            // my own dot.
            markers: walkTarget == null ? markers : {?walkMarker},
            polylines: {
              if (progress case final p? when walkTarget != null)
                Polyline(
                  polylineId: const PolylineId('walk'),
                  points: [
                    for (final v in p.remaining)
                      LatLng(v.latitude, v.longitude),
                  ],
                  color: PindColors.purple,
                  width: 6,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
            },
            myLocationEnabled: walkTarget != null,
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
            color: PindColors.surface,
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: PindColors.muted),
                  SizedBox(height: 12),
                  Text(l10n.mapLoadFailed),
                  Text(l10n.mapFallbackHint, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.5333, 12.4001, 16.5333, 0),
            child: Column(
              children: [
                if (walkTarget case final target?)
                  walkBanner(target)
                else
                  searchBar(),
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
                        onPressed: controller!.load,
                        child: Text(l10n.retry),
                      ),
                    ),
                  ),
                if (controller == null)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(l10n.needsBackend),
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
                                  tooltip: l10n.zoomIn,
                                  onPressed: () =>
                                      map?.animateCamera(CameraUpdate.zoomIn()),
                                  child: const Icon(Icons.add),
                                ),
                                _MapGlassButton(
                                  tooltip: l10n.zoomOut,
                                  onPressed: () => map?.animateCamera(
                                    CameraUpdate.zoomOut(),
                                  ),
                                  child: const Icon(Icons.remove),
                                ),
                              ],
                              _MapGlassButton(
                                tooltip: l10n.myLocation,
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
                                    showRanking(label);
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
                    data: const IconThemeData(size: 22, color: PindColors.ink),
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
      border: Border.all(color: PindColors.purple, width: size * 5 / 112),
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
    Paint()..color = PindColors.purple,
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
