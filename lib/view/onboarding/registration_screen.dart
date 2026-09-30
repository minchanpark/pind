import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/registration_controller.dart';
import '../../model/preferences.dart';
import '../../model/registration_model.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'location_permission_screen.dart';
import 'onboarding_screen.dart';
import 'registration_components.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    required this.controller,
    this.preferences,
  });
  final RegistrationController controller;
  final TastePreferences? preferences;
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  RegistrationController get controller => widget.controller;
  RegistrationDraft get draft => controller.model.draft;
  @override
  void initState() {
    super.initState();
    controller.model.addListener(changed);
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant RegistrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != controller) {
      oldWidget.controller.model.removeListener(changed);
      controller.model.addListener(changed);
    }
  }

  @override
  void dispose() {
    controller.model.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = controller.model.step;
    return PopScope(
      canPop: step == RegistrationStep.login || step == RegistrationStep.taste,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && step != RegistrationStep.taste) controller.back();
      },
      child: switch (step) {
        RegistrationStep.login => LoginScreen(controller: controller),
        RegistrationStep.country => _country(),
        RegistrationStep.basic => _basic(),
        RegistrationStep.handle => _handle(),
        RegistrationStep.location => LocationPermissionScreen(
          controller: controller,
        ),
        RegistrationStep.taste => OnboardingScreen(
          initial: controller.model.tasteDraft ?? widget.preferences,
          onChanged: controller.editTastes,
          onCancel: controller.back,
          onComplete: controller.complete,
        ),
      },
    );
  }

  Widget _footer(String title, {String? caption}) => Column(
    children: [
      SetupError(controller.model.error),
      if (caption != null) ...[
        Text(
          caption,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: PindTheme.muted,
          ),
        ),
        const SizedBox(height: 10),
      ],
      SetupButton(
        title,
        busy: controller.model.busy,
        onPressed: controller.model.canContinue
            ? () {
                FocusManager.instance.primaryFocus?.unfocus();
                controller.next();
              }
            : null,
      ),
    ],
  );

  Widget _country() => SetupPage(
    key: const ValueKey('country-screen'),
    progress: 1,
    onBack: controller.back,
    footer: _footer('다음', caption: '${draft.country.label} 선택됨'),
    children: [
      const SetupTitle('국가를 선택해\n주세요', '서비스 지역과 언어, 통화 표기가 함께 설정돼요.'),
      const SizedBox(height: 20),
      SetupGlass(
        padding: EdgeInsets.zero,
        child: TextField(
          key: const ValueKey('country-search'),
          onChanged: controller.searchCountries,
          decoration: const InputDecoration(
            hintText: '국가 검색',
            prefixIcon: Icon(Icons.search, size: 22, color: PindTheme.muted),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        '자주 선택하는 국가',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: PindTheme.muted,
        ),
      ),
      const SizedBox(height: 10),
      for (final country in controller.countries)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            selected: draft.country == country,
            button: true,
            child: SetupGlass(
              selected: draft.country == country,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              onTap: controller.model.busy
                  ? null
                  : () => controller.edit(draft.copyWith(country: country)),
              child: Row(
                children: [
                  Text(country.flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.label,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          country.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.2,
                            color: PindTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (draft.country == country)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(child: SetupCircle.check(24)),
                          const Center(
                            child: Text(
                              '✓',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      if (controller.countries.isEmpty)
        const Padding(padding: EdgeInsets.all(24), child: Text('검색 결과가 없어요.')),
      const SizedBox(height: 8),
      const Text(
        '현재 맛집 탐색은 대한민국에서 제공해요.',
        style: TextStyle(fontSize: 11, color: PindTheme.muted),
      ),
    ],
  );

  Widget _basic() => SetupPage(
    key: const ValueKey('basic-screen'),
    progress: 2,
    onBack: controller.back,
    footer: _footer('다음'),
    children: [
      const SetupTitle(
        '기본 정보를\n알려주세요',
        '또래가 좋아하는 맛집을 추천하는 데만 쓰여요.\n프로필에는 공개되지 않습니다.',
      ),
      const SizedBox(height: 24),
      _label('이름'),
      SetupGlass(
        padding: EdgeInsets.zero,
        child: TextFormField(
          key: const ValueKey('profile-name'),
          initialValue: draft.name,
          onChanged: (value) => controller.edit(draft.copyWith(name: value)),
          maxLength: 40,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: '이름을 입력해주세요',
            counterText: '',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: draft.name.trim().isEmpty
                ? null
                : const Icon(Icons.check, color: Color(0xFF129E5B), size: 16),
          ),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 22),
      _label('성별'),
      Row(
        children: [
          for (final gender in ProfileGender.values) ...[
            if (gender != ProfileGender.male) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: controller.model.busy
                    ? null
                    : () => controller.edit(draft.copyWith(gender: gender)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 14,
                  ),
                  backgroundColor: draft.gender == gender
                      ? PindTheme.button
                      : const Color(0xB8FBFBFD),
                  foregroundColor: draft.gender == gender
                      ? Colors.white
                      : const Color(0xFF4A4A52),
                  side: BorderSide(
                    color: draft.gender == gender
                        ? PindTheme.purple
                        : PindTheme.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  switch (gender) {
                    ProfileGender.male => '남성',
                    ProfileGender.female => '여성',
                    ProfileGender.unspecified => '선택 안 함',
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 22),
      _label('생년월일'),
      _birthday(),
      const SizedBox(height: 10),
      if (draft.ageAt(DateTime.now()) case final int age)
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xD9F4FF5A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x80A3AD00)),
              ),
              child: Text(
                '$age세 · ${age ~/ 10 * 10}대 ${age % 10 < 4
                    ? '초반'
                    : age % 10 < 7
                    ? '중반'
                    : '후반'}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Text(
              '또래 취향 추천에 사용돼요',
              style: TextStyle(fontSize: 11, color: PindTheme.muted),
            ),
            if (age < 14)
              const Text(
                '만 14세 이상부터 이용할 수 있어요.',
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
          ],
        ),
      const SizedBox(height: 24),
      SetupGlass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: [
            _consent(
              '개인정보 수집·이용 동의 (필수)',
              draft.privacyConsent,
              (value) => controller.edit(draft.copyWith(privacyConsent: value)),
              '이름, 성별, 생년월일은 기본 정보와 취향 추천에 사용하며 공개 프로필에 표시하지 않습니다.',
            ),
            const Divider(height: 1, color: Color(0xFFEBEBF0)),
            _consent(
              '만 14세 이상입니다 (필수)',
              draft.ageConsent,
              (value) => controller.edit(draft.copyWith(ageConsent: value)),
              '생년월일을 확인하고 만 14세 이상인 경우 선택해 주세요.',
            ),
            const Divider(height: 1, color: Color(0xFFEBEBF0)),
            _consent(
              '맞춤 추천을 위한 정보 활용 (선택)',
              draft.recommendationConsent,
              (value) =>
                  controller.edit(draft.copyWith(recommendationConsent: value)),
              '선택하지 않아도 기본 서비스와 장소 검색을 이용할 수 있습니다.',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _label(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4A4A52),
      ),
    ),
  );

  Widget _birthday() {
    final fields = [
      _dateField('년', draft.birthDate?.year, [
        for (var year = DateTime.now().year; year >= 1900; year--) year,
      ], (value) => _birth(year: value)),
      _dateField('월', draft.birthDate?.month, [
        for (var month = 1; month <= 12; month++) month,
      ], (value) => _birth(month: value)),
      _dateField('일', draft.birthDate?.day, [
        for (
          var day = 1;
          day <=
              DateTime(
                draft.birthDate?.year ?? 2000,
                (draft.birthDate?.month ?? 1) + 1,
                0,
              ).day;
          day++
        )
          day,
      ], (value) => _birth(day: value)),
    ];
    if (MediaQuery.textScalerOf(context).scale(14) > 20) {
      return Column(
        children: [
          for (final field in fields)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: field),
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(flex: i == 0 ? 12 : 11, child: fields[i]),
        ],
      ],
    );
  }

  Widget _dateField(
    String label,
    int? value,
    List<int> values,
    ValueChanged<int> change,
  ) => SetupGlass(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: DropdownButton<int>(
      key: ValueKey('birth-$label'),
      value: value,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      hint: Text(
        label,
        style: const TextStyle(fontSize: 13, color: PindTheme.muted),
      ),
      icon: const Text(
        '▾',
        style: TextStyle(fontSize: 9, color: PindTheme.muted),
      ),
      selectedItemBuilder: (_) => values
          .map(
            (v) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$v $label',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text('$v $label')))
          .toList(),
      onChanged: controller.model.busy
          ? null
          : (v) {
              if (v != null) change(v);
            },
    ),
  );

  void _birth({int? year, int? month, int? day}) {
    final previous = draft.birthDate;
    final y = year ?? previous?.year ?? 2000;
    final m = month ?? previous?.month ?? 1;
    final d = math.min(day ?? previous?.day ?? 1, DateTime(y, m + 1, 0).day);
    controller.edit(draft.copyWith(birthDate: DateTime(y, m, d)));
  }

  Widget _consent(
    String title,
    bool checked,
    ValueChanged<bool> change,
    String explanation,
  ) => Row(
    children: [
      Expanded(
        child: Semantics(
          checked: checked,
          label: title,
          child: InkWell(
            onTap: controller.model.busy ? null : () => change(!checked),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: checked ? PindTheme.purple : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: checked
                            ? const Color(0xB33A0088)
                            : PindTheme.border,
                      ),
                    ),
                    child: checked
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      IconButton(
        tooltip: '$title 내용 보기',
        icon: const Icon(Icons.chevron_right, size: 16, color: PindTheme.muted),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Text(explanation),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _handle() => SetupPage(
    key: const ValueKey('handle-screen'),
    progress: 3,
    onBack: controller.back,
    footer: _footer('Pind 시작하기'),
    children: [
      const SetupTitle('어떻게\n불러드릴까요?', '아이디는 나중에 바꿀 수 없어요. 닉네임은 언제든 변경 가능합니다.'),
      const SizedBox(height: 20),
      Center(
        child: SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                left: 0,
                top: 0,
                width: 96,
                height: 96,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE2E2E7),
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0xFFE8E8EC)),
                    ),
                  ),
                ),
              ),
              draft.avatarUrl == null
                  ? Center(
                      child: Text(
                        draft.avatar,
                        style: const TextStyle(fontSize: 34),
                      ),
                    )
                  : ClipOval(
                      child: Image.network(
                        draft.avatarUrl!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
              const Positioned(
                left: 66,
                top: 64,
                child: IgnorePointer(child: SetupCircle.check(32)),
              ),
              Positioned(
                left: 60,
                top: 58,
                child: IconButton(
                  tooltip: '아바타 선택',
                  onPressed: _chooseAvatar,
                  icon: const Text(
                    '✚',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 26),
      _label('아이디'),
      SetupGlass(
        padding: EdgeInsets.zero,
        child: TextFormField(
          key: const ValueKey('profile-handle'),
          initialValue: draft.handle,
          onChanged: (value) =>
              controller.edit(draft.copyWith(handle: value.toLowerCase())),
          maxLength: 20,
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
          ],
          decoration: InputDecoration(
            prefixText: '@',
            hintText: '아이디를 입력해주세요',
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: PindTheme.purple, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: PindTheme.purple, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            suffixIcon: draft.handleValid
                ? const Icon(Icons.check, color: Color(0xFF129E5B), size: 16)
                : null,
          ),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 8),
      Semantics(
        liveRegion: true,
        child: Text(
          draft.handleValid ? '✓ 사용할 수 있는 형식이에요' : '영문, 숫자, 밑줄로 3~20자를 입력해주세요.',
          style: TextStyle(
            fontSize: 12,
            color: draft.handleValid
                ? const Color(0xFF129E5B)
                : PindTheme.muted,
          ),
        ),
      ),
    ],
  );

  Future<void> _chooseAvatar() async {
    final avatar = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('나를 표현하는 이모지를 골라주세요'),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                controller.pickAvatar();
              },
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('앨범에서 사진 선택'),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: ['🍚', '🍜', '☕', '🥑', '🍰', '🍣']
                  .map(
                    (emoji) => IconButton(
                      tooltip: emoji,
                      onPressed: () => Navigator.pop(ctx, emoji),
                      icon: Text(emoji, style: const TextStyle(fontSize: 34)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
    if (mounted && avatar != null) {
      controller.edit(draft.copyWith(avatar: avatar));
    }
  }
}
