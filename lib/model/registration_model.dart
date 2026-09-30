import 'package:flutter/foundation.dart';

import 'preferences.dart';

enum LoginProvider { kakao, apple, google }

enum RegistrationStep { login, country, basic, handle, location, taste }

enum ProfileGender { male, female, unspecified }

enum RegistrationPermission { allowed, denied, blocked }

class AuthIdentity {
  const AuthIdentity(this.id, {this.development = false});
  final String id;
  final bool development;
}

enum OnboardingCountry {
  korea('KR', '대한민국', '🇰🇷', '₩', '한국어', 'ko'),
  usa('US', 'United States', '🇺🇸', r'$', 'English', 'en'),
  japan('JP', '日本', '🇯🇵', '¥', '日本語', 'ja'),
  china('CN', '中国', '🇨🇳', '¥', '中文', 'zh'),
  taiwan('TW', '台灣', '🇹🇼', r'NT$', '繁體中文', 'zh-TW'),
  vietnam('VN', 'Việt Nam', '🇻🇳', '₫', 'Tiếng Việt', 'vi');

  const OnboardingCountry(
    this.code,
    this.label,
    this.flag,
    this.currency,
    this.language,
    this.locale,
  );
  final String code, label, flag, currency, language, locale;
  String get subtitle => '$code · $currency · $language';
}

class RegistrationDraft {
  const RegistrationDraft({
    this.country = OnboardingCountry.korea,
    this.name = '',
    this.gender = ProfileGender.unspecified,
    this.birthDate,
    this.handle = '',
    this.avatar = '🍚',
    this.avatarUrl,
    this.privacyConsent = false,
    this.ageConsent = false,
    this.recommendationConsent = false,
    this.locationAllowed = false,
    this.step = RegistrationStep.country,
    this.completed = false,
  });

  final OnboardingCountry country;
  final String name, handle, avatar;
  final String? avatarUrl;
  final ProfileGender gender;
  final DateTime? birthDate;
  final bool privacyConsent, ageConsent, recommendationConsent;
  final bool locationAllowed, completed;
  final RegistrationStep step;

  int? ageAt(DateTime now) {
    final birth = birthDate;
    if (birth == null || birth.isAfter(now)) return null;
    return now.year -
        birth.year -
        (now.month < birth.month ||
                (now.month == birth.month && now.day < birth.day)
            ? 1
            : 0);
  }

  bool basicValid(DateTime now) =>
      name.trim().isNotEmpty &&
      name.trim().length <= 40 &&
      (ageAt(now) ?? -1) >= 14 &&
      privacyConsent &&
      ageConsent;

  bool get handleValid => RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(handle);

  RegistrationDraft copyWith({
    OnboardingCountry? country,
    String? name,
    ProfileGender? gender,
    DateTime? birthDate,
    String? handle,
    String? avatar,
    String? avatarUrl,
    bool? privacyConsent,
    bool? ageConsent,
    bool? recommendationConsent,
    bool? locationAllowed,
    RegistrationStep? step,
    bool? completed,
  }) => RegistrationDraft(
    country: country ?? this.country,
    name: name ?? this.name,
    gender: gender ?? this.gender,
    birthDate: birthDate ?? this.birthDate,
    handle: handle ?? this.handle,
    avatar: avatar ?? this.avatar,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    privacyConsent: privacyConsent ?? this.privacyConsent,
    ageConsent: ageConsent ?? this.ageConsent,
    recommendationConsent: recommendationConsent ?? this.recommendationConsent,
    locationAllowed: locationAllowed ?? this.locationAllowed,
    step: step ?? this.step,
    completed: completed ?? this.completed,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'country': country.name,
    'name': name,
    'gender': gender.name,
    'birthDate': birthDate?.toIso8601String(),
    'handle': handle,
    'avatar': avatar,
    'avatarUrl': avatarUrl,
    'privacyConsent': privacyConsent,
    'ageConsent': ageConsent,
    'recommendationConsent': recommendationConsent,
    'locationAllowed': locationAllowed,
    'step': step.name,
    'completed': completed,
  };

  factory RegistrationDraft.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unknown profile draft');
    }
    return RegistrationDraft(
      country: OnboardingCountry.values.byName(json['country'] as String),
      name: json['name'] as String,
      gender: ProfileGender.values.byName(json['gender'] as String),
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      handle: json['handle'] as String,
      avatar: json['avatar'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      privacyConsent: json['privacyConsent'] == true,
      ageConsent: json['ageConsent'] == true,
      recommendationConsent: json['recommendationConsent'] == true,
      locationAllowed: json['locationAllowed'] == true,
      step: RegistrationStep.values.byName(json['step'] as String),
      completed: json['completed'] == true,
    );
  }
}

class RegistrationModel extends ChangeNotifier {
  RegistrationModel({RegistrationDraft? draft})
    : draft = draft ?? const RegistrationDraft();
  RegistrationDraft draft;
  RegistrationStep step = RegistrationStep.login;
  AuthIdentity? identity;
  TastePreferences? tasteDraft;
  LoginProvider? signingIn;
  bool busy = false;
  bool permissionBlocked = false;
  String? error;
  String countryQuery = '';
  bool get completed => identity != null && draft.completed;
  bool get canContinue => switch (step) {
    RegistrationStep.country => true,
    RegistrationStep.basic => draft.basicValid(DateTime.now()),
    RegistrationStep.handle => draft.handleValid,
    _ => false,
  };

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }
}
