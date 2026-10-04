import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/registration_controller.dart';
import '../../model/preferences.dart';
import '../../model/registration_model.dart';
import '../design_system.dart';
import 'login_screen.dart';
import 'location_permission_screen.dart';
import 'onboarding_screen.dart';
import 'registration_components.dart';
import '../components/pind_image.dart';
import '../../l10n/l10n.dart';

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
            fontSize: PindType.caption,
            fontWeight: FontWeight.w700,
            color: PindColors.muted,
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
    footer: _footer(
      l10n.next,
      caption: l10n.countrySelected(draft.country.label),
    ),
    children: [
      SetupTitle(l10n.countryTitle, l10n.countryBody),
      const SizedBox(height: 20),
      SetupGlass(
        padding: EdgeInsets.zero,
        child: TextField(
          key: const ValueKey('country-search'),
          onChanged: controller.searchCountries,
          decoration: InputDecoration(
            hintText: l10n.countrySearch,
            prefixIcon: Icon(Icons.search, size: 22, color: PindColors.muted),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          ),
          style: const TextStyle(fontSize: PindType.body),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        l10n.countryPopular,
        style: TextStyle(
          fontSize: PindType.label,
          fontWeight: FontWeight.w700,
          color: PindColors.muted,
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
                            fontSize: PindType.bodyLarge,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          country.subtitle,
                          style: const TextStyle(
                            fontSize: PindType.caption,
                            height: 1.2,
                            color: PindColors.muted,
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
                                fontSize: PindType.label,
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
        Padding(padding: EdgeInsets.all(24), child: Text(l10n.noSearchResults)),
      const SizedBox(height: 8),
      Text(
        l10n.countryKoreaOnly,
        style: TextStyle(fontSize: PindType.caption, color: PindColors.muted),
      ),
    ],
  );

  Widget _basic() => SetupPage(
    key: const ValueKey('basic-screen'),
    progress: 2,
    onBack: controller.back,
    footer: _footer(l10n.next),
    children: [
      SetupTitle(l10n.basicTitle, l10n.basicBody),
      const SizedBox(height: 24),
      _label(l10n.name),
      SetupGlass(
        padding: EdgeInsets.zero,
        child: TextFormField(
          key: const ValueKey('profile-name'),
          initialValue: draft.name,
          onChanged: (value) => controller.edit(draft.copyWith(name: value)),
          maxLength: 40,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: l10n.enterName,
            counterText: '',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: draft.name.trim().isEmpty
                ? null
                : const Icon(Icons.check, color: PindColors.success, size: 16),
          ),
          style: const TextStyle(
            fontSize: PindType.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 22),
      _label(l10n.gender),
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
                      ? PindColors.purpleLight
                      : const Color(0xB8FBFBFD),
                  foregroundColor: draft.gender == gender
                      ? Colors.white
                      : PindColors.body,
                  side: BorderSide(
                    color: draft.gender == gender
                        ? PindColors.purple
                        : PindColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  switch (gender) {
                    ProfileGender.male => l10n.male,
                    ProfileGender.female => l10n.female,
                    ProfileGender.unspecified => l10n.preferNotToSay,
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: PindType.bodySmall),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 22),
      _label(l10n.birthDate),
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
                l10n.ageBand(
                  age,
                  age ~/ 10 * 10,
                  age % 10 < 4
                      ? 'early'
                      : age % 10 < 7
                      ? 'mid'
                      : 'late',
                ),
                style: const TextStyle(
                  fontSize: PindType.micro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.ageUsedFor,
              style: TextStyle(
                fontSize: PindType.caption,
                color: PindColors.muted,
              ),
            ),
            if (age < 14)
              Text(
                l10n.ageMinimum,
                style: TextStyle(fontSize: PindType.label, color: Colors.red),
              ),
          ],
        ),
      const SizedBox(height: 24),
      SetupGlass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          children: [
            _consent(
              l10n.consentPrivacy,
              draft.privacyConsent,
              (value) => controller.edit(draft.copyWith(privacyConsent: value)),
              l10n.consentPrivacyBody,
            ),
            const Divider(height: 1, color: PindColors.line),
            _consent(
              l10n.consentAge,
              draft.ageConsent,
              (value) => controller.edit(draft.copyWith(ageConsent: value)),
              l10n.consentAgeBody,
            ),
            const Divider(height: 1, color: PindColors.line),
            _consent(
              l10n.consentPersonalize,
              draft.recommendationConsent,
              (value) =>
                  controller.edit(draft.copyWith(recommendationConsent: value)),
              l10n.consentPersonalizeBody,
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
        fontSize: PindType.label,
        fontWeight: FontWeight.w700,
        color: PindColors.body,
      ),
    ),
  );

  Widget _birthday() {
    final fields = [
      _dateField(l10n.year, draft.birthDate?.year, [
        for (var year = DateTime.now().year; year >= 1900; year--) year,
      ], (value) => _birth(year: value)),
      _dateField(l10n.month, draft.birthDate?.month, [
        for (var month = 1; month <= 12; month++) month,
      ], (value) => _birth(month: value)),
      _dateField(l10n.day, draft.birthDate?.day, [
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
        style: const TextStyle(
          fontSize: PindType.bodySmall,
          color: PindColors.muted,
        ),
      ),
      icon: const Text(
        '▾',
        style: TextStyle(fontSize: PindType.tiny, color: PindColors.muted),
      ),
      selectedItemBuilder: (_) => values
          .map(
            (v) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$v $label',
                style: const TextStyle(
                  fontSize: PindType.body,
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
                      color: checked ? PindColors.purple : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: checked
                            ? const Color(0xB33A0088)
                            : PindColors.border,
                      ),
                    ),
                    child: checked
                        ? const Icon(Icons.check, size: 13, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: PindType.label),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      IconButton(
        tooltip: l10n.viewDetails(title),
        icon: const Icon(
          Icons.chevron_right,
          size: 16,
          color: PindColors.muted,
        ),
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
                    child: Text(l10n.close),
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
    footer: _footer(l10n.startPind),
    children: [
      SetupTitle(l10n.handleTitle, l10n.handleBody),
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
                    color: PindColors.fill,
                    border: Border.fromBorderSide(
                      BorderSide(color: PindColors.line),
                    ),
                  ),
                ),
              ),
              draft.avatarUrl == null
                  ? Center(
                      child: Text(
                        draft.avatar,
                        style: const TextStyle(fontSize: PindType.hero),
                      ),
                    )
                  : ClipOval(
                      child: Image(
                        image: PindImage(draft.avatarUrl!),
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
                  tooltip: l10n.chooseAvatar,
                  onPressed: _chooseAvatar,
                  icon: const Text(
                    '✚',
                    style: TextStyle(
                      fontSize: PindType.bodySmall,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 26),
      _label(l10n.handle),
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
            hintText: l10n.enterHandle,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: PindColors.purple,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: PindColors.purple,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            suffixIcon: draft.handleValid
                ? const Icon(Icons.check, color: PindColors.success, size: 16)
                : null,
          ),
          style: const TextStyle(
            fontSize: PindType.bodyLarge,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Semantics(
        liveRegion: true,
        child: Text(
          draft.handleValid ? l10n.handleValid : l10n.handleRule,
          style: TextStyle(
            fontSize: PindType.label,
            color: draft.handleValid ? PindColors.success : PindColors.muted,
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
            Text(l10n.chooseEmoji),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                controller.pickAvatar();
              },
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(l10n.pickFromAlbum),
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
                      icon: Text(
                        emoji,
                        style: const TextStyle(fontSize: PindType.hero),
                      ),
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
