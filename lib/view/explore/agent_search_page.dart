import 'package:flutter/material.dart';

import '../components/pind_glass.dart';
import '../theme.dart';

/// Figma 617:23469 지도 검색. Pops with the query to search, or null.
class AgentSearchPage extends StatefulWidget {
  const AgentSearchPage({super.key});

  /// (emoji, prompt), row by row as in the design.
  static const suggestions = [
    ('🌶️', '매움 단계를 선택할 수 있는 식당'),
    ('🥩', '한국 BBQ를 즐기면서 분위기 좋은 고깃집'),
    ('🇳🇵', '네팔 사람들이 많이 방문한 식당'),
    ('🌿', 'Vegetarian 음식'),
    ('🍜', '한국식 베트남 음식'),
    ('🪑', '혼술 하기 좋은 식당'),
    ('🍜', '느낌 좋은 쌀국수집'),
    ('📍', '서울 성수동에 분위기 좋은 바'),
    ('🍚', '한국 집밥 느낌의 식당'),
    ('🔁', '관광객들이 가장 많이 방문한 식당'),
  ];

  @override
  State<AgentSearchPage> createState() => _AgentSearchPageState();
}

class _AgentSearchPageState extends State<AgentSearchPage> {
  final query = TextEditingController();

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  void submit(String text) {
    if (text.trim().isEmpty) return;
    Navigator.pop(context, text.trim());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F5FA),
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: const PindGlass(
                    radius: 17.4,
                    child: SizedBox.square(
                      dimension: 32.8,
                      child: Icon(Icons.close, size: 16, color: PindTheme.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(22.5, 18, 22.5, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(
                  '개인 맞춤형 음식 검색',
                  style: TextStyle(
                    fontSize: 28,
                    height: 36 / 28,
                    fontWeight: FontWeight.w700,
                    color: PindTheme.ink,
                  ),
                ),
                Text(
                  '원하는 취향을 자세히 알려주면 추천 내용이 더 정확해집니다.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 20 / 13,
                    color: Color(0xFF9A9AA2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(18.4, 20.5, 18.4, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 9.2,
                crossAxisSpacing: 9.2,
                mainAxisExtent: 59,
              ),
              itemCount: AgentSearchPage.suggestions.length,
              itemBuilder: (_, i) {
                final (emoji, text) = AgentSearchPage.suggestions[i];
                return suggestion(emoji, text);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18.4, 16.4, 18.4, 12),
            child: input(),
          ),
        ],
      ),
    ),
  );

  Widget suggestion(String emoji, String text) => Semantics(
    button: true,
    child: PindGlass(
      radius: 14.3,
      child: InkWell(
        onTap: () => submit(text),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13.3),
          child: Row(
            spacing: 9.2,
            children: [
              ExcludeSemantics(
                child: Text(emoji, style: const TextStyle(fontSize: 18.4)),
              ),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.8,
                    height: 17.3 / 12.8,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF222222),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget input() => PindGlass(
    radius: 31,
    padding: const EdgeInsets.fromLTRB(20.5, 10.2, 10.2, 10.2),
    child: Row(
      spacing: 10.2,
      children: [
        Expanded(
          child: TextField(
            controller: query,
            onChanged: (_) => setState(() {}),
            onSubmitted: submit,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14, color: PindTheme.ink),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '무엇이든 물어보세요...',
              hintStyle: TextStyle(fontSize: 14, color: Color(0x73000000)),
            ),
          ),
        ),
        // Mic until there is text to send; voice input is not built yet.
        Semantics(
          button: true,
          label: query.text.trim().isEmpty ? '음성 검색' : '검색',
          child: GestureDetector(
            onTap: () => query.text.trim().isEmpty
                ? ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('음성 검색은 준비 중이에요.')),
                  )
                : submit(query.text),
            child: PindGlass(
              tone: PindGlassTone.purple,
              radius: 19.4,
              child: SizedBox.square(
                dimension: 36.9,
                child: Icon(
                  query.text.trim().isEmpty
                      ? Icons.mic_none_rounded
                      : Icons.arrow_upward_rounded,
                  size: 17,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
