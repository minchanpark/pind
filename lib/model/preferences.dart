enum PreferenceCriterion {
  taste('맛', '재료와 조리 완성도', '😋'),
  ambience('분위기·공간', '인테리어와 좌석', '🕯️'),
  value('가성비', '가격 대비 만족', '💰'),
  portion('양', '한 끼에 충분한 양', '🍚'),
  service('청결·서비스', '응대와 위생', '🧼'),
  photogenic('사진 잘 나옴', '찍을 맛 나는 곳', '📸'),
  quiet('조용함', '대화하기 좋은', '🤫'),
  parking('주차', '차 대기 편한', '🅿️');

  const PreferenceCriterion(this.label, this.description, this.emoji);
  final String label;
  final String description;
  final String emoji;
}

enum DiningOccasion {
  solo('혼밥', '혼자서도 편한 자리'),
  friends('친구들이랑', '왁자지껄 모임'),
  date('데이트', '분위기 있는 곳'),
  family('가족 식사', '넓고 조용한 곳'),
  group('회식·모임', '단체석 있는 곳'),
  work('카공·작업', '콘센트와 와이파이'),
  drinks('술 한잔', '늦게까지 여는 곳'),
  quick('급할 때', '빨리 나오는 곳');

  const DiningOccasion(this.label, this.description);
  final String label;
  final String description;
}

enum Cuisine {
  korean('한식·백반', '838d7.png'),
  barbecue('고기구이', 'b887a.png'),
  soup('국물·탕', '319be.png'),
  noodles('면·국수', 'eb159.png'),
  street('분식', '230fd.png'),
  japanese('일식', 'c1df7.png'),
  sushi('스시·회', '8aa62.png'),
  chinese('중식', '56250.png'),
  western('양식·파스타', '92aad.png'),
  asian('아시안', '09c52.png'),
  chicken('치킨', '27b11.png'),
  dessert('카페·디저트', 'fc2b8.png'),
  bakery('베이커리', null),
  bar('술집·바', null);

  const Cuisine(this.label, this.asset);
  final String label;
  final String? asset;
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
