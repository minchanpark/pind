import '../../controllers/detail_preview_controller.dart';
import '../../model/detail_preview_model.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../design_system.dart';
import '../explore/place_sheet.dart';

void main() {
  if (kReleaseMode) throw StateError('Local QA entrypoint is debug-only');
  runApp(const DetailPreview());
}

class DetailPreview extends StatefulWidget {
  const DetailPreview({super.key});
  @override
  State<DetailPreview> createState() => _DetailPreviewState();
}

class _DetailPreviewState extends State<DetailPreview> {
  final controller = DetailPreviewController();
  final navigator = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('DETAIL_PREVIEW_OPEN')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) open(navigator.currentContext!);
      });
    }
  }

  void open(BuildContext context) {
    final detail = controller.details();
    showPlaceSheet(context, detail);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    debugShowCheckedModeBanner: false,
    theme: PindTheme.data,
    home: Scaffold(
      body: Builder(
        builder: (context) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PindColors.pastelSage,
                PindColors.pastelLavender,
                PindColors.pastelBlue,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '가게 상세 · 로컬 QA',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const Text('실제 계정·가게 데이터가 아닙니다. API 호출 없음.'),
                  DropdownButton<TestFriendship>(
                    value: controller.relationship,
                    items: [
                      for (final value in TestFriendship.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(switch (value) {
                            TestFriendship.none => '친구 없음',
                            TestFriendship.pending => '친구 수락 대기',
                            TestFriendship.accepted => '테스트 친구 연결됨',
                            TestFriendship.removed => '친구 해제됨',
                          }),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => controller.relationship = value!),
                  ),
                  FilledButton(
                    key: const ValueKey('open-detail-preview'),
                    onPressed: () => open(context),
                    child: const Text('네임이즈마빈 · 상세 보기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
