import '../../model/place_search_result.dart';

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme.dart';
import '../../model/preferences.dart';
import '../../model/places.dart';
import '../../controllers/explore_controller.dart';
import 'place_sheet.dart';

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
  MapViewport viewport = MapViewport.seoul;
  Timer? debounce;
  bool searchMode = false;
  bool get locating => controller?.model.locating ?? false;
  String category = '전체';
  int markerGeneration = 0;
  int searchGeneration = 0;
  Set<Marker> markers = {};
  List<Place>? markerPlaces;
  static const categories = {
    '전체': '',
    '☕ 카페': 'cafe|coffee|카페|커피',
    '🍺 술집': 'bar|pub|술집|바',
    '🥩 고기': 'barbecue|bbq|steak|고기|구이',
    '🍜 면': 'noodle|ramen|면|국수',
    '🍰 디저트': 'dessert|bakery|디저트|베이커리',
  };

  @override
  void initState() {
    super.initState();
    controller?.model.addListener(changed);
    controller?.load(viewport);
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller?.model.removeListener(changed);
      controller?.model.addListener(changed);
      markerPlaces = null;
      markers = {};
      controller?.load(viewport, force: true);
    }
  }

  void changed() {
    if (!mounted) return;
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
    final expression = RegExp(pattern, caseSensitive: false);
    return places
        .where((p) => expression.hasMatch('${p.category} ${p.name}'))
        .toList();
  }

  Future<void> updateMarkers() async {
    final generation = ++markerGeneration;
    // Marker images belong to the current request only; don't persist provider content.
    final result = await Future.wait(
      // Cross-map display rights for supplemental providers are not confirmed.
      visiblePlaces
          .where((p) => p.canShowOnMap)
          .map(
            (p) async => Marker(
              markerId: MarkerId(p.key),
              position: LatLng(p.latitude, p.longitude),
              icon: await photoMarker(p.imageUrl),
              infoWindow: InfoWindow(title: p.name),
              onTap: () => showPlace(p),
            ),
          ),
    );
    if (mounted && generation == markerGeneration) {
      setState(() => markers = result.toSet());
    }
  }

  Future<BitmapDescriptor> photoMarker(String? url) async {
    ui.Image? photo;
    if (url != null) {
      final completer = Completer<ui.Image>();
      final stream = NetworkImage(url).resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) completer.complete(info.image.clone());
        },
        onError: (Object error, StackTrace? stack) {
          if (!completer.isCompleted) completer.completeError(error);
        },
      );
      stream.addListener(listener);
      try {
        photo = await completer.future.timeout(const Duration(seconds: 5));
      } catch (_) {
        /* Category fallback remains visible. */
      } finally {
        stream.removeListener(listener);
      }
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(56, 56),
      54,
      Paint()..color = PindTheme.purple,
    );
    canvas.drawCircle(const Offset(56, 56), 49, Paint()..color = Colors.white);
    if (photo != null) {
      canvas.save();
      canvas.clipPath(Path()..addOval(const Rect.fromLTWH(14, 14, 84, 84)));
      paintImage(
        canvas: canvas,
        rect: const Rect.fromLTWH(14, 14, 84, 84),
        image: photo,
        fit: BoxFit.cover,
      );
      canvas.restore();
    } else {
      final label = TextPainter(
        text: const TextSpan(text: '🍽️', style: TextStyle(fontSize: 48)),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset((112 - label.width) / 2, (112 - label.height) / 2),
      );
      label.dispose();
    }
    final picture = recorder.endRecording();
    final bitmap = await picture.toImage(112, 112);
    photo?.dispose();
    picture.dispose();
    final data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    bitmap.dispose();
    return BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      width: 56,
      height: 56,
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    markerGeneration++;
    controller?.model.removeListener(changed);
    map?.dispose();
    query.dispose();
    super.dispose();
  }

  void cameraIdle() {
    if (searchMode || !widget.isActive) return;
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 450), () async {
      final activeMap = map;
      if (activeMap == null) return;
      LatLngBounds bounds;
      try {
        bounds = await activeMap.getVisibleRegion();
      } catch (_) {
        // The platform map can be torn down while its bounds are in flight.
        return;
      }
      if (!mounted || searchMode || !widget.isActive) return;
      viewport = MapViewport(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
        latitudeDelta: bounds.northeast.latitude - bounds.southwest.latitude,
        longitudeDelta: bounds.northeast.longitude - bounds.southwest.longitude,
      );
      await controller?.load(viewport);
    });
  }

  Future<void> search() async {
    if (controller == null) return;
    final generation = ++searchGeneration;
    FocusScope.of(context).unfocus();
    debounce?.cancel();
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
      await controller?.load(viewport, force: true);
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
      viewport = location;
      query.clear();
      setState(() => searchMode = false);
      await map?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          14,
        ),
      );
      await controller?.load(viewport, force: true);
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

  void showPlace(Place place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .04),
      builder: (_) => PlaceSheet(
        controller: controller!.details(place, widget.preferences),
      ),
    );
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

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        if (widget.mapsEnabled)
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.5665, 126.978),
              zoom: 13,
            ),
            onMapCreated: (value) => map = value,
            onCameraMoveStarted: () => debounce?.cancel(),
            onCameraIdle: cameraIdle,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: .95),
                  elevation: 2,
                  borderRadius: BorderRadius.circular(28),
                  child: TextField(
                    controller: query,
                    onSubmitted: (_) => search(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: '장소, 메뉴, 분위기 검색',
                      border: InputBorder.none,
                      prefixIcon: IconButton(
                        tooltip: '검색',
                        icon: const Icon(Icons.search),
                        onPressed: controller == null ? null : search,
                      ),
                      suffixIcon: IconButton(
                        tooltip: '취향 수정',
                        onPressed: widget.onEditPreferences,
                        icon: const Icon(Icons.tune),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
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
        Positioned(
          right: 16,
          bottom: 116 + widget.bottomClearance,
          child: Column(
            children: [
              if (widget.mapsEnabled) ...[
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  tooltip: '확대',
                  onPressed: () => map?.animateCamera(CameraUpdate.zoomIn()),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  tooltip: '축소',
                  onPressed: () => map?.animateCamera(CameraUpdate.zoomOut()),
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
              ],
              FloatingActionButton.small(
                heroTag: 'locate',
                tooltip: '현재 위치',
                onPressed: locating ? null : locate,
                child: locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: widget.bottomClearance,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        for (final label in categories.keys)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: category == label,
                              onSelected: (_) {
                                setState(() => category = label);
                                updateMarkers();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (controller != null &&
                      !controller!.loading &&
                      controller!.error == null &&
                      visiblePlaces.isEmpty)
                    const Text(
                      '다른 지역이나 검색어로 찾아보세요.',
                      style: TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
