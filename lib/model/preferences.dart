import '../l10n/l10n.dart';

enum PreferenceCriterion {
  taste('😋'),
  ambience('🕯️'),
  value('💰'),
  portion('🍚'),
  service('🧼'),
  photogenic('📸'),
  quiet('🤫'),
  parking('🅿️');

  const PreferenceCriterion(this.emoji);
  final String emoji;

  String get label => switch (this) {
    taste => l10n.criterionTaste,
    ambience => l10n.criterionAmbience,
    value => l10n.criterionValue,
    portion => l10n.criterionPortion,
    service => l10n.criterionService,
    photogenic => l10n.criterionPhotogenic,
    quiet => l10n.criterionQuiet,
    parking => l10n.criterionParking,
  };

  String get description => switch (this) {
    taste => l10n.criterionTasteHint,
    ambience => l10n.criterionAmbienceHint,
    value => l10n.criterionValueHint,
    portion => l10n.criterionPortionHint,
    service => l10n.criterionServiceHint,
    photogenic => l10n.criterionPhotogenicHint,
    quiet => l10n.criterionQuietHint,
    parking => l10n.criterionParkingHint,
  };
}

enum DiningOccasion {
  solo,
  friends,
  date,
  family,
  group,
  work,
  drinks,
  quick;

  String get label => switch (this) {
    solo => l10n.occasionSolo,
    friends => l10n.occasionFriends,
    date => l10n.occasionDate,
    family => l10n.occasionFamily,
    group => l10n.occasionGroup,
    work => l10n.occasionWork,
    drinks => l10n.occasionDrinks,
    quick => l10n.occasionQuick,
  };

  String get description => switch (this) {
    solo => l10n.occasionSoloHint,
    friends => l10n.occasionFriendsHint,
    date => l10n.occasionDateHint,
    family => l10n.occasionFamilyHint,
    group => l10n.occasionGroupHint,
    work => l10n.occasionWorkHint,
    drinks => l10n.occasionDrinksHint,
    quick => l10n.occasionQuickHint,
  };
}

enum Cuisine {
  korean('korean.png'),
  barbecue('barbecue.png'),
  soup('soup.png'),
  noodles('noodles.png'),
  street('street.png'),
  japanese('japanese.png'),
  sushi('sushi.png'),
  chinese('chinese.png'),
  western('western.png'),
  asian('asian.png'),
  chicken('chicken.png'),
  dessert('dessert.png'),
  bakery(null),
  bar(null);

  const Cuisine(this.asset);
  final String? asset;

  String get label => switch (this) {
    korean => l10n.cuisineKorean,
    barbecue => l10n.cuisineBarbecue,
    soup => l10n.cuisineSoup,
    noodles => l10n.cuisineNoodles,
    street => l10n.cuisineStreet,
    japanese => l10n.cuisineJapanese,
    sushi => l10n.cuisineSushi,
    chinese => l10n.cuisineChinese,
    western => l10n.cuisineWestern,
    asian => l10n.cuisineAsian,
    chicken => l10n.cuisineChicken,
    dessert => l10n.cuisineDessert,
    bakery => l10n.cuisineBakery,
    bar => l10n.cuisineBar,
  };
}

class TastePreferences {
  TastePreferences({
    Iterable<PreferenceCriterion> priorities = const [],
    Iterable<DiningOccasion> occasions = const [],
    Iterable<Cuisine> cuisines = const [],
  }) : priorities = List.unmodifiable(priorities),
       occasions = Set.unmodifiable(occasions),
       cuisines = Set.unmodifiable(cuisines) {
    if (this.priorities.toSet().length != this.priorities.length ||
        this.priorities.length > 3 ||
        this.occasions.length > 3) {
      throw const FormatException('Invalid preference selection');
    }
  }

  final List<PreferenceCriterion> priorities;
  final Set<DiningOccasion> occasions;
  final Set<Cuisine> cuisines;
  bool get isComplete => priorities.length == 3 && cuisines.length >= 3;

  TastePreferences togglePriority(PreferenceCriterion value) {
    final next = [...priorities];
    if (!next.remove(value)) {
      if (next.length == 3) return this;
      next.add(value);
    }
    return TastePreferences(
      priorities: next,
      occasions: occasions,
      cuisines: cuisines,
    );
  }

  TastePreferences toggleOccasion(DiningOccasion value) {
    final next = {...occasions};
    if (!next.remove(value)) {
      if (next.length == 3) return this;
      next.add(value);
    }
    return TastePreferences(
      priorities: priorities,
      occasions: next,
      cuisines: cuisines,
    );
  }

  TastePreferences toggleCuisine(Cuisine value) {
    final next = {...cuisines};
    if (!next.remove(value)) next.add(value);
    return TastePreferences(
      priorities: priorities,
      occasions: occasions,
      cuisines: next,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 2,
    'priorities': priorities.map((v) => v.name).toList(),
    'occasions': occasions.map((v) => v.name).toList(),
    'cuisines': cuisines.map((v) => v.name).toList(),
  };

  factory TastePreferences.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 && json['version'] != 2) {
      throw const FormatException('Unknown preferences version');
    }
    return TastePreferences(
      priorities: (json['priorities'] as List).map(
        (v) => PreferenceCriterion.values.byName(v as String),
      ),
      occasions: (json['occasions'] as List).map(
        (v) => DiningOccasion.values.byName(v as String),
      ),
      cuisines: (json['cuisines'] as List).map(
        (v) => Cuisine.values.byName(v as String),
      ),
    );
  }
}
