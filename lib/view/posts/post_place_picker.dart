import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/post_controller.dart';
import '../../model/place_context.dart';
import '../../model/places.dart';
import '../../model/place_search_result.dart';
import '../../services/location_service.dart';
import '../components/pind_glass.dart';
import '../components/pind_search_field.dart';
import '../explore/explore_screen.dart' show PlacePin;
import '../profile/profile_screen.dart' show mutedNote;
import '../theme.dart';

enum PlaceFilter {
  nearby('📍 현재 위치 주변'),
  recent('최근 방문'),
  saved('저장한 곳');

  const PlaceFilter(this.label);
  final String label;
}

/// Figma 671:35758. 주변 narrows the server search to [nearbyMeters];
/// 최근 방문 / 저장한 곳 filter My Page's lists by the typed keyword.
class PostPlacePicker extends StatefulWidget {
  const PostPlacePicker({super.key, required this.controller});
  final PostController controller;

  // ponytail: fixed radius; make it adjustable if people search wider.
  static const nearbyMeters = 10000.0;

  @override
  State<PostPlacePicker> createState() => _PostPlacePickerState();
}

class _PostPlacePickerState extends State<PostPlacePicker> {
  PostController get controller => widget.controller;
  final query = TextEditingController();
  List<Place> results = [];
  PlaceFilter? filter;
  MapViewport? here;
  bool loading = false;
  String? error;
  int request = 0;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    // Local filters and the highlight follow every keystroke.
    query.addListener(() => setState(() {}));
    // Distances when location is already allowed; never prompts here.
    controller.currentPosition().then((p) {
      if (mounted && p != null) setState(() => here = p);
    });
  }

  @override
  void dispose() {
    request++;
    debounce?.cancel();
    query.dispose();
    super.dispose();
  }

  Future<void> search() async {
    debounce?.cancel();
    final generation = ++request;
    final text = query.text.trim();
    if (text.length < 2) {
      setState(() {
        results = [];
        error = null;
        loading = false;
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final places = await controller.searchPlaces(text);
      if (mounted && generation == request) setState(() => results = places);
    } catch (caught) {
      if (mounted && generation == request) {
        setState(
          () => error = caught is PlaceFailure
              ? caught.message
              : '식당을 검색하지 못했어요.',
        );
      }
    } finally {
      if (mounted && generation == request) setState(() => loading = false);
    }
  }

  Future<void> choose(PlaceFilter value) async {
    final next = filter == value ? null : value;
    setState(() {
      filter = next;
      error = null;
    });
    if (next != PlaceFilter.nearby || here != null) return;
    final p = await controller.currentPosition(request: true);
    if (!mounted || filter != PlaceFilter.nearby) return;
    setState(() {
      here = p;
      if (p == null) error = '현재 위치를 확인할 수 없어요. 위치 권한을 확인해 주세요.';
    });
  }

  double? distance(Place p) =>
      here == null ? null : LocationService.distance(here!, p);

  /// What the list shows for the current filter and keyword.
  List<Place> get rows {
    final text = query.text.trim().toLowerCase();
    bool matches(Place p) =>
        text.isEmpty ||
        p.name.toLowerCase().contains(text) ||
        p.address.toLowerCase().contains(text);
    final mine = controller.mine?.call();
    final List<Place> list = switch (filter) {
      PlaceFilter.recent => [
        for (final c in mine?.recentViews ?? const [])
          if (matches(c.place)) c.place,
      ],
      PlaceFilter.saved => [
        for (final c in mine?.savedPlaces ?? const [])
          if (matches(c.place)) c.place,
      ],
      PlaceFilter.nearby => [
        for (final p in results)
          if ((distance(p) ?? double.infinity) <= PostPlacePicker.nearbyMeters)
            p,
      ],
      null => [...results],
    };
    // Recent and saved keep their own order; search results go nearest first.
    if (here != null && (filter == null || filter == PlaceFilter.nearby)) {
      list.sort((a, b) => distance(a)!.compareTo(distance(b)!));
    }
    return list;
  }

  String get emptyText {
    final typed = query.text.trim().isNotEmpty;
    return switch (filter) {
      PlaceFilter.recent =>
        typed ? '최근 방문한 곳 중에 없어요.' : '최근 24시간 안에 본 장소가 없어요.',
      PlaceFilter.saved => typed ? '저장한 곳 중에 없어요.' : '저장한 장소가 아직 없어요.',
      _ when loading => '식당을 찾고 있어요.',
      PlaceFilter.nearby when query.text.trim().length >= 2 =>
        '주변 ${formatDistance(PostPlacePicker.nearbyMeters)} 안에 맞는 식당이 없어요.',
      _ when query.text.trim().length >= 2 => '검색 결과가 없어요.',
      _ => '식당 이름이나 주소로 검색해 주세요.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final rows = this.rows;
    final local = filter == PlaceFilter.recent || filter == PlaceFilter.saved;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 11),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCDDE3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '어디에 다녀오셨어요?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: PindTheme.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(context),
                    icon: const Text(
                      '✕',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9B9B9B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PindSearchField(
                controller: query,
                hint: '식당 이름 또는 주소',
                autofocus: true,
                fontSize: 15,
                verticalPadding: 13,
                onSubmitted: (_) => search(),
                onChanged: (_) {
                  debounce?.cancel();
                  request++;
                  debounce = Timer(const Duration(milliseconds: 300), search);
                },
              ),
              const SizedBox(height: 10),
              Row(
                spacing: 8,
                children: [for (final f in PlaceFilter.values) chip(f)],
              ),
              const SizedBox(height: 20),
              Text(
                query.text.trim().isEmpty && filter != null
                    ? filter!.label.replaceFirst('📍 ', '')
                    : '검색 결과',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PindTheme.muted,
                ),
              ),
              const SizedBox(height: 6),
              if (loading && !local) const LinearProgressIndicator(),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    error!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              Expanded(
                child: rows.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: mutedNote(emptyText),
                        ),
                      )
                    : ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Color(0xFFEDEDF1)),
                        itemBuilder: (_, i) => row(rows[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chip(PlaceFilter f) {
    final on = filter == f;
    return Semantics(
      button: true,
      selected: on,
      child: PindGlass(
        tone: on ? PindGlassTone.purple : PindGlassTone.light,
        radius: 16,
        child: InkWell(
          onTap: () => choose(f),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 13, 8),
            child: Text(
              f.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: on ? Colors.white : const Color(0xFF4A4A52),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget row(Place p) {
    final meters = distance(p);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        spacing: 12,
        children: [
          ExcludeSemantics(child: PlacePin(p)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text.rich(
                  highlight(p.name, query.text.trim()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: PindTheme.ink,
                  ),
                ),
                Text(
                  [
                    p.category,
                    shortAddress(p.address),
                    if (meters != null) formatDistance(meters),
                  ].where((t) => t.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: PindTheme.muted),
                ),
              ],
            ),
          ),
          Semantics(
            container: true,
            button: true,
            label: '${p.name} 선택',
            child: PindGlass(
              radius: 14,
              child: InkWell(
                onTap: () => Navigator.pop(context, p),
                child: const ExcludeSemantics(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Text(
                      '선택',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A4A52),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [text] with the first case-insensitive [keyword] match in purple.
TextSpan highlight(String text, String keyword) {
  final at = keyword.isEmpty
      ? -1
      : text.toLowerCase().indexOf(keyword.toLowerCase());
  if (at < 0) return TextSpan(text: text);
  return TextSpan(
    children: [
      TextSpan(text: text.substring(0, at)),
      TextSpan(
        text: text.substring(at, at + keyword.length),
        style: const TextStyle(color: PindTheme.purple),
      ),
      TextSpan(text: text.substring(at + keyword.length)),
    ],
  );
}

/// `서울 중구 을지로3가 12-1` → `중구 을지로3가`: drops the city and the lot.
String shortAddress(String address) => address
    .split(' ')
    .skip(1)
    .where((t) => t.isNotEmpty && !t.startsWith(RegExp(r'\d')))
    .take(2)
    .join(' ');
