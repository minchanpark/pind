import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/post_controller.dart';
import '../../model/places.dart';
import '../../model/place_search_result.dart';
import '../theme.dart';

class PostPlacePicker extends StatefulWidget {
  const PostPlacePicker({super.key, required this.controller});
  final PostController controller;
  @override
  State<PostPlacePicker> createState() => _PostPlacePickerState();
}

class _PostPlacePickerState extends State<PostPlacePicker> {
  final query = TextEditingController();
  List<Place> results = [];
  bool loading = false;
  String? error;
  int request = 0;
  Timer? debounce;
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
      final places = await widget.controller.searchPlaces(text);
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

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '방문한 식당 선택',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: query,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => search(),
              onChanged: (_) {
                debounce?.cancel();
                request++;
                debounce = Timer(const Duration(milliseconds: 300), search);
              },
              decoration: InputDecoration(
                labelText: '식당 이름 또는 주소',
                hintText: '두 글자 이상 입력해 주세요',
                suffixIcon: IconButton(
                  tooltip: '식당 검색',
                  onPressed: search,
                  icon: const Icon(Icons.search),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (loading) const LinearProgressIndicator(),
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      loading ? '식당을 찾고 있어요.' : '식당 이름이나 주소로 검색해 주세요.',
                      style: const TextStyle(color: PindTheme.muted),
                    ),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (_, index) {
                      final place = results[index];
                      return ListTile(
                        title: Text(place.name),
                        subtitle: Text('${place.category} · ${place.address}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, place),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}
