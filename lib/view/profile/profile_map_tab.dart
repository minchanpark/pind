import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../model/place_context.dart';
import '../../model/places.dart';
import '../../model/preferences.dart';
import '../../model/profile_model.dart';
import '../components/pind_glass.dart';
import '../explore/explore_screen.dart';
import '../theme.dart';
import 'profile_screen.dart';

/// (emoji, label, earned).
// ponytail: thresholds on the two counts we have; a server badge table when
// badges become a real feature.
List<(String, String, bool)> profileBadges(ProfileCounts c) => [
  ('😋', '맛잘알', c.posts >= 1),
  ('📝', '게시물왕', c.posts >= 10),
  ('🤔', '맛집 판별가', c.saved >= 5),
  ('🔒', '???', false),
];

class ProfileMapTab extends StatelessWidget {
  const ProfileMapTab({
    super.key,
    required this.overview,
    this.mine = true,
    this.preferences,
    required this.mapsEnabled,
    this.onEditPreferences,
    this.onShowMap,
    this.onOpenPlace,
  });
  final ProfileOverview overview;

  /// False on someone else's page: no editing, no jump to my map.
  final bool mine;
  final TastePreferences? preferences;
  final bool mapsEnabled;
  final VoidCallback? onEditPreferences;

  /// Opens the map tab focused on [placeId] (the newest post), if any.
  final void Function(int? placeId)? onShowMap;
  final void Function(Place)? onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final places = overview.mapPlaces;
    return Padding(
      padding: profileInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 22,
        children: [
          _TasteCard(preferences, mine ? onEditPreferences : null, mine),
          profileSection('뱃지', badges(), trailing: '더보기 ›'),
          profileSection(
            mine ? '나의 지도' : '지도',
            map(places),
          ),
        ],
      ),
    );
  }

  Widget badges() => Row(
    spacing: 8,
    children: [
      for (final (emoji, label, earned) in profileBadges(overview.counts))
        Expanded(
          child: Opacity(
            opacity: earned ? 1 : .5,
            child: PindGlass(
              radius: 16,
              padding: const EdgeInsets.only(top: 12, bottom: 10),
              child: Column(
                spacing: 4,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: profileBody,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  Widget map(List<Place> places) {
    final content = places.isEmpty
        ? _note('작성한 게시물이 아직 없어요')
        : !mapsEnabled
        ? _note('지도를 사용할 수 없어요')
        : _PostsMap(overview, onOpenPlace);
    return PindGlass(
      radius: 20,
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: 290,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.4),
                child: content,
              ),
            ),
            if (mine && onShowMap != null)
              Positioned(
                left: 10,
                bottom: 12,
                child: GestureDetector(
                  onTap: () => onShowMap!(places.firstOrNull?.id),
                  child: const PindGlass(
                    radius: 56,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Text(
                      '맵 보기 ›',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _note(String text) => Container(
    color: PindTheme.surface,
    alignment: Alignment.center,
    child: mutedNote(text),
  );
}

/// My posted places with the map screen's pins, centered on the newest post.
class _PostsMap extends StatefulWidget {
  const _PostsMap(this.overview, this.onOpen);
  final ProfileOverview overview;
  final void Function(Place)? onOpen;

  @override
  State<_PostsMap> createState() => _PostsMapState();
}

class _PostsMapState extends State<_PostsMap> {
  GoogleMapController? map;
  Set<Marker> markers = {};
  int generation = 0;

  LatLng get center {
    final newest = widget.overview.mapPlaces.first;
    return LatLng(newest.latitude, newest.longitude);
  }

  @override
  void initState() {
    super.initState();
    updateMarkers();
  }

  @override
  void didUpdateWidget(_PostsMap old) {
    super.didUpdateWidget(old);
    // A reload replaces the overview; the newest post may have changed.
    if (identical(old.overview, widget.overview)) return;
    updateMarkers();
    map?.moveCamera(CameraUpdate.newLatLng(center)).catchError((_) {});
  }

  Future<void> updateMarkers() async {
    final current = ++generation;
    final result = await Future.wait(
      widget.overview.mapPlaces.map(
        (p) async => Marker(
          markerId: MarkerId('${p.id}'),
          position: LatLng(p.latitude, p.longitude),
          icon: await placeMarkerIcon(p),
          onTap: widget.onOpen == null ? null : () => widget.onOpen!(p),
        ),
      ),
    );
    if (mounted && current == generation) {
      setState(() => markers = result.toSet());
    }
  }

  @override
  void dispose() {
    generation++;
    map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GoogleMap(
    liteModeEnabled: true,
    style: pindMapStyle,
    // Same focus zoom the map screen uses for a single place.
    initialCameraPosition: CameraPosition(target: center, zoom: 14),
    onMapCreated: (value) => map = value,
    markers: markers,
    zoomControlsEnabled: false,
    zoomGesturesEnabled: false,
    scrollGesturesEnabled: false,
    rotateGesturesEnabled: false,
    tiltGesturesEnabled: false,
    myLocationEnabled: false,
    myLocationButtonEnabled: false,
    mapToolbarEnabled: false,
    compassEnabled: false,
  );
}

class _TasteCard extends StatelessWidget {
  const _TasteCard(this.preferences, this.onEdit, this.mine);
  final TastePreferences? preferences;
  final VoidCallback? onEdit;
  final bool mine;
  static const bars = [Color(0xFFE8336E), Color(0xFF3563FF), Color(0xFFFF8A1F)];
  static const values = [
    Color(0xFFA8154A),
    Color(0xFF1C3FC4),
    Color(0xFFB85600),
  ];

  @override
  Widget build(BuildContext context) {
    final p = preferences?.priorities;
    final ready = p != null && p.length == 3;
    return PindGlass(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              Text(
                mine ? '나의 취향' : '취향',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (ready)
                _pill(
                  '${p[0].label} 중시형',
                  background: const Color.fromRGBO(99, 0, 219, .7),
                  border: const Color.fromRGBO(58, 0, 136, .6),
                  color: Colors.white,
                  weight: FontWeight.w700,
                  vertical: 4,
                ),
              const Spacer(),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: _pill(
                    '✎ 수정',
                    background: const Color.fromRGBO(251, 251, 253, .9),
                    border: const Color(0xFFD9DAE1),
                    color: profileBody,
                    weight: FontWeight.w500,
                    vertical: 5,
                  ),
                ),
            ],
          ),
          if (!ready)
            Text(
              mine ? '취향을 설정하면 여기에 표시돼요.' : '공개한 취향이 없어요.',
              style: const TextStyle(
                fontSize: 12,
                height: 17 / 12,
                color: profileBody,
              ),
            )
          else ...[
            Row(
              spacing: 3,
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    flex: (tasteWeights[i] * 100).round(),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: bars[i],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
              ],
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (var i = 0; i < 3; i++) _chip(p[i], i)],
            ),
            Text(
              '${p[0].label} 먼저, 그다음 ${p[1].label}·${p[2].label}을 봐요.',
              style: const TextStyle(
                fontSize: 12,
                height: 17 / 12,
                color: profileBody,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(
    String text, {
    required Color background,
    required Color border,
    required Color color,
    required FontWeight weight,
    required double vertical,
  }) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: vertical),
    decoration: BoxDecoration(
      color: background,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: weight, color: color),
    ),
  );

  Widget _chip(PreferenceCriterion c, int i) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bars[i].withValues(alpha: .08),
      border: Border.all(color: bars[i].withValues(alpha: .25)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text.rich(
      TextSpan(
        text: '${c.emoji} ${c.label} ',
        children: [
          TextSpan(
            text: '${(tasteWeights[i] * 100).round()}%',
            style: TextStyle(fontWeight: FontWeight.w700, color: values[i]),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 11, color: profileBody),
    ),
  );
}
