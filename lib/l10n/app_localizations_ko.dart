// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Pind';

  @override
  String get navMap => '지도';

  @override
  String get navCompose => '작성';

  @override
  String get navMyPage => '마이페이지';

  @override
  String get loginTagline => '내 취향에 맞는 맛집만, 지도 위에서';

  @override
  String get loginKakao => '카카오로 3초 만에 시작하기';

  @override
  String get loginApple => 'Apple로 계속하기';

  @override
  String get loginGoogle => 'Google로 계속하기';

  @override
  String get loginPreview => '로그인 없이 화면 체험';

  @override
  String get authOpenFailed => '로그인 창을 열지 못했어요. 다시 시도해 주세요.';

  @override
  String get authAnonymousDisabled => '개발용 익명 인증이 허용되지 않았어요.';

  @override
  String get authPreviewFailed => '체험을 시작하지 못했어요.';

  @override
  String get authUnavailable => '로그인에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get back => '뒤로';

  @override
  String get clear => '지우기';

  @override
  String postPhotoOpen(int number) {
    return '게시물 사진 $number 크게 보기';
  }

  @override
  String ratingScore(String criterion, int score) {
    return '$criterion $score점';
  }

  @override
  String get postDelete => '게시물 삭제';

  @override
  String get postDeleteTitle => '게시물을 삭제할까요?';

  @override
  String get postDeleteBody => '사진과 별점도 함께 지워지고, 되돌릴 수 없어요.';

  @override
  String get delete => '삭제';

  @override
  String get close => '닫기';

  @override
  String get qrCameraDenied => '카메라를 사용할 수 없어요. 설정에서 카메라 권한을 허용해 주세요.';

  @override
  String get qrNotPind => 'Pind 친구 코드가 아니에요';

  @override
  String get qrHint => '친구의 Pind QR 코드를 네모 안에 맞춰 주세요';

  @override
  String get qrTitle => '친구 코드 스캔';

  @override
  String get linkCopied => '링크를 복사했어요.';

  @override
  String get shareMyCode => '내 코드 공유';

  @override
  String get profileLoadFailed => '프로필을 불러오지 못했어요.';

  @override
  String get retry => '다시 시도';

  @override
  String get kakaoTalk => '카카오톡';

  @override
  String get instagram => '인스타';

  @override
  String get copyLink => '링크 복사';

  @override
  String get scanFriendCode => '친구 코드 스캔하기';

  @override
  String get myQrCode => '내 Pind QR 코드';

  @override
  String copyLinkLabel(String link) {
    return '링크 복사 $link';
  }

  @override
  String shareTitle(String name) {
    return '$name 님의 Pind';
  }

  @override
  String get shareBody => '음식 취향 지도를 구경해 보세요';

  @override
  String get viewProfile => '프로필 보기';

  @override
  String get inviteToPind => 'Pind 친구 초대';

  @override
  String get criterionTaste => '맛';

  @override
  String get criterionTasteHint => '재료와 조리 완성도';

  @override
  String get criterionAmbience => '분위기·공간';

  @override
  String get criterionAmbienceHint => '인테리어와 좌석';

  @override
  String get criterionValue => '가성비';

  @override
  String get criterionValueHint => '가격 대비 만족';

  @override
  String get criterionPortion => '양';

  @override
  String get criterionPortionHint => '한 끼에 충분한 양';

  @override
  String get criterionService => '청결·서비스';

  @override
  String get criterionServiceHint => '응대와 위생';

  @override
  String get criterionPhotogenic => '사진 잘 나옴';

  @override
  String get criterionPhotogenicHint => '찍을 맛 나는 곳';

  @override
  String get criterionQuiet => '조용함';

  @override
  String get criterionQuietHint => '대화하기 좋은';

  @override
  String get criterionParking => '주차';

  @override
  String get criterionParkingHint => '차 대기 편한';

  @override
  String get occasionSolo => '혼밥';

  @override
  String get occasionSoloHint => '혼자서도 편한 자리';

  @override
  String get occasionFriends => '친구들이랑';

  @override
  String get occasionFriendsHint => '왁자지껄 모임';

  @override
  String get occasionDate => '데이트';

  @override
  String get occasionDateHint => '분위기 있는 곳';

  @override
  String get occasionFamily => '가족 식사';

  @override
  String get occasionFamilyHint => '넓고 조용한 곳';

  @override
  String get occasionGroup => '회식·모임';

  @override
  String get occasionGroupHint => '단체석 있는 곳';

  @override
  String get occasionWork => '카공·작업';

  @override
  String get occasionWorkHint => '콘센트와 와이파이';

  @override
  String get occasionDrinks => '술 한잔';

  @override
  String get occasionDrinksHint => '늦게까지 여는 곳';

  @override
  String get occasionQuick => '급할 때';

  @override
  String get occasionQuickHint => '빨리 나오는 곳';

  @override
  String get cuisineKorean => '한식·백반';

  @override
  String get cuisineBarbecue => '고기구이';

  @override
  String get cuisineSoup => '국물·탕';

  @override
  String get cuisineNoodles => '면·국수';

  @override
  String get cuisineStreet => '분식';

  @override
  String get cuisineJapanese => '일식';

  @override
  String get cuisineSushi => '스시·회';

  @override
  String get cuisineChinese => '중식';

  @override
  String get cuisineWestern => '양식·파스타';

  @override
  String get cuisineAsian => '아시안';

  @override
  String get cuisineChicken => '치킨';

  @override
  String get cuisineDessert => '카페·디저트';

  @override
  String get cuisineBakery => '베이커리';

  @override
  String get cuisineBar => '술집·바';

  @override
  String get pindUser => 'Pind 사용자';

  @override
  String get photoProvider => '사진 제공자';

  @override
  String get sourceSbiz => '소상공인시장진흥공단';

  @override
  String get kakaoMap => '카카오맵';

  @override
  String get naverMap => '네이버 지도';

  @override
  String get unsupportedSource => '지원하지 않는 장소 출처입니다.';

  @override
  String get sourceOpenData => '공공데이터 원본';

  @override
  String get viewOnMap => '지도에서 확인';

  @override
  String get directionsInGoogle => 'Google Maps에서 길찾기';

  @override
  String get viewInKakao => '카카오맵에서 확인';

  @override
  String get searchInNaver => '네이버 지도에서 검색';

  @override
  String friendsVisited(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name 외 $others명이 다녀감',
      zero: '$name님이 다녀감',
    );
    return '$_temp0';
  }

  @override
  String friendsSaved(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name 외 $others명이 저장함',
      zero: '$name님이 저장함',
    );
    return '$_temp0';
  }

  @override
  String get errProfileServer => '프로필 서버에 연결하지 못했어요.';

  @override
  String get errSignInRequired => '로그인이 필요해요.';

  @override
  String get errHandleTaken => '이미 사용 중인 아이디예요.';

  @override
  String get errHandleImmutable => '아이디는 한 번 정하면 바꿀 수 없어요.';

  @override
  String get errProfileSave => '프로필을 저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get errProfileNotFound => '프로필을 찾을 수 없어요.';

  @override
  String get errFeedServer => '피드 서버에 연결하지 못했어요.';

  @override
  String get errNotificationsLoad => '알림을 불러오지 못했어요.';

  @override
  String get errNotificationsRead => '알림을 읽음으로 바꾸지 못했어요.';

  @override
  String get errFeedLoad => '피드를 불러오지 못했어요.';

  @override
  String get errLikeSignIn => '로그인 후 좋아요를 누를 수 있어요.';

  @override
  String get errFriendsServer => '친구 서버에 연결하지 못했어요.';

  @override
  String get errSuggestionsLoad => '추천 목록을 불러오지 못했어요.';

  @override
  String get errSearchFailed => '검색하지 못했어요.';

  @override
  String get errFollowersLoad => '팔로워를 불러오지 못했어요.';

  @override
  String get errFollowingLoad => '팔로잉을 불러오지 못했어요.';

  @override
  String get errFollow => '팔로우하지 못했어요.';

  @override
  String get errUnfollow => '팔로우를 취소하지 못했어요.';

  @override
  String get errQueryLength => '검색어를 2~120자로 입력해 주세요.';

  @override
  String get errPlaceCheck => '장소를 확인하지 못했어요.';

  @override
  String get errPlaceSignIn => '장소를 탐색하려면 로그인이 필요해요.';

  @override
  String get errSessionStart => '세션을 시작하지 못했어요.';

  @override
  String get errPlaceLoad => '장소를 불러오지 못했어요.';

  @override
  String get errPlaceServer => '장소 서버에 연결하지 못했어요.';

  @override
  String get errPostSignIn => '로그인 후 게시물을 작성해 주세요.';

  @override
  String get errPostServer => '게시물 서버에 연결하지 못했어요.';

  @override
  String get errPostDeleteRetry => '게시물을 삭제하지 못했어요. 다시 시도해 주세요.';

  @override
  String get errAccountChanged => '계정이 변경되었어요. 다시 로그인해 주세요.';

  @override
  String get errPostPublishKept => '게시물을 등록하지 못했어요. 입력 내용을 유지했으니 다시 시도해 주세요.';

  @override
  String get inviteGeneric => 'Pind에서 서로의 음식 취향을 팔로우해요!';

  @override
  String get errProfileLoadRetry => '프로필을 불러오지 못했어요. 다시 시도해 주세요.';

  @override
  String get errPhotoUpload => '사진을 올리지 못했어요. 다시 시도해 주세요.';

  @override
  String get errDistanceNeedsLocation => '거리 표시는 위치 권한과 기기 위치 서비스가 필요해요.';

  @override
  String get errLocationUnknown => '현재 위치를 확인하지 못했어요.';

  @override
  String get errSaveUnsupported => '이 출처의 장소 저장은 아직 지원하지 않아요. 원본 지도에서 확인해 주세요.';

  @override
  String get errSaveUnavailable => '저장 기능을 연결하지 못했어요. 상세 정보를 다시 불러와 주세요.';

  @override
  String get errSaveRetry => '저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get errLikeRetry => '좋아요를 반영하지 못했어요. 다시 시도해 주세요.';

  @override
  String get errPostDelete => '게시물을 삭제하지 못했어요.';

  @override
  String get errLinkOpen => '링크를 열지 못했어요. 다시 시도해 주세요.';

  @override
  String get errShareOpen => '공유 창을 열지 못했어요.';

  @override
  String get errLoginIncomplete => '로그인을 완료하지 못했어요. 다시 시도해 주세요.';

  @override
  String get errPreviewRetry => '체험을 시작하지 못했어요. 다시 시도해 주세요.';

  @override
  String get errDraftSave => '입력 내용을 저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String get locationSkipHint => '위치를 허용하지 않아도 검색으로 시작할 수 있어요.';

  @override
  String get errLocationPermission => '위치 권한을 확인하지 못했어요. 나중에 설정할 수 있어요.';

  @override
  String get errSettingsOpen => '설정을 열지 못했어요. 기기 설정에서 위치를 허용해 주세요.';

  @override
  String get errCheckInput => '입력 내용을 확인해 주세요.';

  @override
  String get errLocationServicesOff => '기기의 위치 서비스를 켜 주세요.';

  @override
  String get errLocationDenied => '위치 권한 없이도 지도를 직접 이동하거나 검색할 수 있어요.';

  @override
  String get errOutsideKorea => '현재 위치가 한국 밖이에요. 한국의 장소를 검색해 주세요.';

  @override
  String get errPhotoTooLarge => '사진은 한 장당 10MB 이하로 선택해 주세요.';

  @override
  String get errPhotoFormat => '지원되는 사진 형식을 선택해 주세요.';

  @override
  String get errPhotoLoad => '사진을 불러오지 못했어요.';

  @override
  String get errPlaceSearchSignIn => '로그인 후 식당을 검색해 주세요.';

  @override
  String get errPostPublish => '게시물을 등록하지 못했어요.';

  @override
  String get errConnectionRetry => '연결을 확인하고 다시 시도해 주세요.';

  @override
  String inviteFollow(String who, String link) {
    return 'Pind에서 $who 님을 팔로우하고 음식 취향을 나눠요!\n$link';
  }

  @override
  String agoWeeks(int n) {
    return '$n주 전';
  }

  @override
  String agoDays(int n) {
    return '$n일 전';
  }

  @override
  String get yesterday => '어제';

  @override
  String agoHours(int n) {
    return '$n시간 전';
  }

  @override
  String agoMinutes(int n) {
    return '$n분 전';
  }

  @override
  String get justNow => '방금';

  @override
  String get notifications => '알림';

  @override
  String unreadCount(int count) {
    return '안 읽음 $count';
  }

  @override
  String get markAllRead => '모두 읽음';

  @override
  String get noNotifications => '아직 알림이 없어요.';

  @override
  String get notifLikeRest => '님이 회원님의 게시물을 좋아해요';

  @override
  String get notifVisitMid => '님이 ';

  @override
  String get restaurant => '식당';

  @override
  String get notifVisitEnd => '에 다녀갔어요';

  @override
  String get notifFollowRest => '님이 회원님을 친구로 추가했어요';

  @override
  String get following => '팔로잉';

  @override
  String get followBack => '맞팔로우';

  @override
  String get follow => '팔로우';

  @override
  String unfollowLabel(String label) {
    return '$label, 팔로우 취소';
  }

  @override
  String unfollowTitle(String name) {
    return '$name 님을 팔로우 취소할까요?';
  }

  @override
  String get unfollowBody => '취소해도 언제든 다시 팔로우할 수 있어요.';

  @override
  String get unfollow => '팔로우 취소';

  @override
  String tasteMatchPercent(int percent) {
    return '취향 $percent% 일치';
  }

  @override
  String unfollowName(String name) {
    return '$name 팔로우 취소';
  }

  @override
  String followName(String name) {
    return '$name 팔로우';
  }

  @override
  String get errListLoad => '목록을 불러오지 못했어요.';

  @override
  String get tryAgainPlease => '다시 시도해 주세요.';

  @override
  String peopleCount(int count) {
    return '$count명';
  }

  @override
  String get followers => '팔로워';

  @override
  String get noFollowers => '아직 팔로워가 없어요.';

  @override
  String get noFollowing => '아직 팔로우한 사람이 없어요.';

  @override
  String get signOutTitle => '로그아웃할까요?';

  @override
  String get signOutBody => '다시 로그인하면 게시물과 저장한 장소를 그대로 볼 수 있어요.';

  @override
  String get signOut => '로그아웃';

  @override
  String get errSignOut => '로그아웃하지 못했어요. 다시 시도해 주세요.';

  @override
  String get profileSettings => '프로필 설정';

  @override
  String get changePhoto => '사진 변경';

  @override
  String get noHandle => '아이디 없음';

  @override
  String get handleLocked => '아이디는 변경할 수 없어요';

  @override
  String get name => '이름';

  @override
  String get statusMessage => '상태 메시지';

  @override
  String get statusHint => '오늘의 상태를 남겨 보세요';

  @override
  String get save => '저장';

  @override
  String get addFriend => '친구 추가';

  @override
  String get newNotifications => '새 알림';

  @override
  String get exploreFriendsTaste => '친구들 취향 탐색하기';

  @override
  String get inviteFriends => '친구 초대하기';

  @override
  String get shareFriendsTaste => '친구들의 음식 취향을 공유하세요';

  @override
  String get invite => '초대하기';

  @override
  String get noPostsYet => '아직 게시물이 없어요.';

  @override
  String get postDeleted => '게시물을 삭제했어요.';

  @override
  String get unlike => '좋아요 취소';

  @override
  String get like => '좋아요';

  @override
  String searchResultsCount(int count) {
    return '검색 결과 $count명';
  }

  @override
  String get searchResults => '검색 결과';

  @override
  String get noSearchResults => '검색 결과가 없어요.';

  @override
  String get cantFindSomeone => '찾는 사람이 없나요?';

  @override
  String get inviteByLink => '링크로 초대하기';

  @override
  String get shareMyCodeAction => '내 코드 공유하기';

  @override
  String get inviteByLinkHint => '링크로 친구를 초대해요';

  @override
  String get similarTaste => '취향이 비슷한 사람';

  @override
  String get noSimilarTaste => '아직 취향이 비슷한 사람이 없어요.';

  @override
  String get searchIdOrName => '아이디 또는 이름 검색';

  @override
  String get seeMore => '더보기 ›';

  @override
  String get agentStepRead => '입력한 문장을 분석하고 있어요';

  @override
  String get agentStepPlaces => '게시물이 작성된 장소를 살펴보고 있어요';

  @override
  String get agentStepTaste => '당신의 취향에 맞는 장소를 검색하고 있어요';

  @override
  String get errSearchRetry => '검색하지 못했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get errSaveToggle => '저장 상태를 바꾸지 못했어요. 다시 시도해 주세요.';

  @override
  String get agentTitle => '개인 맞춤형 음식 검색';

  @override
  String get agentSubtitle => '원하는 취향을 자세히 알려주면 추천 내용이 더 정확해집니다.';

  @override
  String recommendedCount(int count) {
    return '추천 장소 $count곳';
  }

  @override
  String get agentNoResults => '게시물이 있는 장소 중에 맞는 곳을 찾지 못했어요. 다르게 말해 볼까요?';

  @override
  String get askAnything => '무엇이든 물어보세요...';

  @override
  String get voiceSearch => '음성 검색';

  @override
  String get search => '검색';

  @override
  String get voiceComingSoon => '음성 검색은 준비 중이에요.';

  @override
  String get rankingFromMapCenter => '현재 위치를 확인하지 못해 지도 중심 10km 기준이에요.';

  @override
  String get rankingEmpty => '10km 안에 게시물이 있는 곳이 아직 없어요.';

  @override
  String get sortByTaste => '내 취향순';

  @override
  String reviewsCount(int count) {
    return '리뷰 $count';
  }

  @override
  String get unsave => '저장 취소';

  @override
  String get taste => '취향';

  @override
  String ratingScoreText(String criterion, String score) {
    return '$criterion $score점';
  }

  @override
  String get backToMap => '지도로 돌아가기';

  @override
  String get checkLocationInSettings => '설정에서 위치 권한 확인';

  @override
  String get allowLocationStart => '위치 허용하고 시작하기';

  @override
  String get later => '나중에 할게요';

  @override
  String get locationTitle => '지금 있는 곳 주변부터\n보여드릴게요';

  @override
  String get locationBody => '위치를 허용하면 내 주변 맛집과 취향을 탐색할 수 있어요.';

  @override
  String get nearbyFood => '내 주변 맛집';

  @override
  String get nearbyFoodHint => '반경 안에서만 추천해요';

  @override
  String get friendsFood => '친구들 맛집';

  @override
  String get friendsFoodHint => '친구들이 간 맛집을 볼 수 있어요';

  @override
  String get localRanking => '동네 랭킹';

  @override
  String get localRankingHint => '#1 in 성수동 같은 지역 순위';

  @override
  String get recentlyViewed => '최근에 본 장소';

  @override
  String get recentlyViewedEmpty => '최근 24시간 안에 본 장소가 여기에 표시돼요.';

  @override
  String get savedPlaces => '저장한 장소';

  @override
  String get noSavedPlaces => '저장한 장소가 아직 없어요.';

  @override
  String get noSharedSaves => '공유한 저장 장소가 없어요.';

  @override
  String get noPlacesToShow => '표시할 장소가 없어요.';

  @override
  String get settings => '설정';

  @override
  String get posts => '게시물';

  @override
  String get myMap => '내 지도';

  @override
  String get badgeFoodie => '맛잘알';

  @override
  String get badgePoster => '게시물왕';

  @override
  String get badgeJudge => '맛집 판별가';

  @override
  String get badges => '뱃지';

  @override
  String get myMapTitle => '나의 지도';

  @override
  String get noPostsWritten => '작성한 게시물이 아직 없어요';

  @override
  String get mapUnavailable => '지도를 사용할 수 없어요';

  @override
  String get viewMap => '맵 보기 ›';

  @override
  String get myTaste => '나의 취향';

  @override
  String tasteType(String criterion) {
    return '$criterion 중시형';
  }

  @override
  String get edit => '✎ 수정';

  @override
  String get tasteEmpty => '취향을 설정하면 여기에 표시돼요.';

  @override
  String get noPublicTaste => '공개한 취향이 없어요.';

  @override
  String tasteOrder(String first, String second, String third) {
    return '$first 먼저, 그다음 $second·$third을 봐요.';
  }

  @override
  String agoYears(int n) {
    return '$n년 전';
  }

  @override
  String agoMonths(int n) {
    return '$n개월 전';
  }

  @override
  String savedAgo(String ago) {
    return '$ago 저장';
  }

  @override
  String get sortRecentSaved => '최근 저장순';

  @override
  String placesCount(int count) {
    return '$count곳';
  }

  @override
  String get onboardingTitlePriorities => '가게 고를 때\n뭘 제일 봐요?';

  @override
  String get onboardingTitleOccasions => '외식 선호도를 선택해주세요.';

  @override
  String get onboardingTitleCuisines => '좋아하는걸 선택해주세요.';

  @override
  String get onboardingHintPriorities => '딱 3개만. 순서대로 50% · 30% · 20%를 반영해요.';

  @override
  String get onboardingHintOccasions => '최대 3개. 상황에 맞는 리스트를 만들어 드려요.';

  @override
  String get onboardingHintCuisines => '3개 이상 골라주세요. 고를수록 추천이 정확해집니다.';

  @override
  String get onboardingPickThree => '중요한 기준 3개를 골라주세요.';

  @override
  String prioritiesOrder(String order) {
    return '$order 순으로 반영됩니다';
  }

  @override
  String selectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get previous => '이전';

  @override
  String onboardingStep(int step) {
    return '취향 설정 $step / 3 단계';
  }

  @override
  String get saving => '저장 중…';

  @override
  String get buildTasteMap => '내 취향 지도 만들기';

  @override
  String get next => '다음';

  @override
  String rankLabel(int rank) {
    return '$rank순위';
  }

  @override
  String get filterNearby => '📍 현재 위치 주변';

  @override
  String get filterRecent => '최근 방문';

  @override
  String get filterSaved => '저장한 곳';

  @override
  String get categoryAll => '전체';

  @override
  String get categoryCafe => '카페';

  @override
  String get categoryBar => '술집';

  @override
  String get categoryMeat => '고기';

  @override
  String get categoryNoodles => '면';

  @override
  String get categoryDessert => '디저트';

  @override
  String get errRestaurantSearch => '식당을 검색하지 못했어요.';

  @override
  String get errLocationCheckPermission => '현재 위치를 확인할 수 없어요. 위치 권한을 확인해 주세요.';

  @override
  String get notInRecent => '최근 방문한 곳 중에 없어요.';

  @override
  String get noRecentViews => '최근 24시간 안에 본 장소가 없어요.';

  @override
  String get notInSaved => '저장한 곳 중에 없어요.';

  @override
  String get findingRestaurants => '식당을 찾고 있어요.';

  @override
  String noNearbyMatch(String distance) {
    return '주변 $distance 안에 맞는 식당이 없어요.';
  }

  @override
  String get searchByNameOrAddress => '식당 이름이나 주소로 검색해 주세요.';

  @override
  String get whereDidYouGo => '어디에 다녀오셨어요?';

  @override
  String get nameOrAddress => '식당 이름 또는 주소';

  @override
  String selectPlace(String name) {
    return '$name 선택';
  }

  @override
  String get select => '선택';

  @override
  String get errProfileOpen => '프로필을 열지 못했어요.';

  @override
  String get postPublished => '게시물을 등록했어요.';

  @override
  String postPhotoOf(int number, int total) {
    return '게시물 사진 $number/$total';
  }

  @override
  String get noPostsYetMine => '아직 작성한 게시물이 없어요.';

  @override
  String get share => '공유';

  @override
  String get errTasteSave => '취향을 저장하지 못했어요. 다시 시도해 주세요.';

  @override
  String countrySelected(String country) {
    return '$country 선택됨';
  }

  @override
  String get countryTitle => '국가를 선택해\n주세요';

  @override
  String get countryBody => '서비스 지역과 언어, 통화 표기가 함께 설정돼요.';

  @override
  String get countrySearch => '국가 검색';

  @override
  String get countryPopular => '자주 선택하는 국가';

  @override
  String get countryKoreaOnly => '현재 맛집 탐색은 대한민국에서 제공해요.';

  @override
  String get basicTitle => '기본 정보를\n알려주세요';

  @override
  String get basicBody => '또래가 좋아하는 맛집을 추천하는 데만 쓰여요.\n프로필에는 공개되지 않습니다.';

  @override
  String get enterName => '이름을 입력해주세요';

  @override
  String get gender => '성별';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get preferNotToSay => '선택 안 함';

  @override
  String get birthDate => '생년월일';

  @override
  String ageBand(int age, int decade, String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'early': '초반',
      'mid': '중반',
      'other': '후반',
    });
    return '$age세 · $decade대 $_temp0';
  }

  @override
  String get ageUsedFor => '또래 취향 추천에 사용돼요';

  @override
  String get ageMinimum => '만 14세 이상부터 이용할 수 있어요.';

  @override
  String get consentPrivacy => '개인정보 수집·이용 동의 (필수)';

  @override
  String get consentPrivacyBody =>
      '이름, 성별, 생년월일은 기본 정보와 취향 추천에 사용하며 공개 프로필에 표시하지 않습니다.';

  @override
  String get consentAge => '만 14세 이상입니다 (필수)';

  @override
  String get consentAgeBody => '생년월일을 확인하고 만 14세 이상인 경우 선택해 주세요.';

  @override
  String get consentPersonalize => '맞춤 추천을 위한 정보 활용 (선택)';

  @override
  String get consentPersonalizeBody => '선택하지 않아도 기본 서비스와 장소 검색을 이용할 수 있습니다.';

  @override
  String get year => '년';

  @override
  String get month => '월';

  @override
  String get day => '일';

  @override
  String viewDetails(String title) {
    return '$title 내용 보기';
  }

  @override
  String get startPind => 'Pind 시작하기';

  @override
  String get handleTitle => '어떻게\n불러드릴까요?';

  @override
  String get handleBody => '아이디는 나중에 바꿀 수 없어요. 닉네임은 언제든 변경 가능합니다.';

  @override
  String get chooseAvatar => '아바타 선택';

  @override
  String get handle => '아이디';

  @override
  String get enterHandle => '아이디를 입력해주세요';

  @override
  String get handleValid => '✓ 사용할 수 있는 형식이에요';

  @override
  String get handleRule => '영문, 숫자, 밑줄로 3~20자를 입력해주세요.';

  @override
  String get chooseEmoji => '나를 표현하는 이모지를 골라주세요';

  @override
  String get pickFromAlbum => '앨범에서 사진 선택';

  @override
  String get errDetailLoad => '상세 정보를 불러오지 못했어요.';

  @override
  String get errContextLoad => '취향·팔로잉 정보를 불러오지 못했어요.';

  @override
  String get detailSwipeHint => '⌃  위로 올려서 소개 · 게시물 보기';

  @override
  String get hoursUnknown => '운영시간 확인 필요';

  @override
  String get openNow => '영업 중';

  @override
  String get closedNow => '영업 종료';

  @override
  String get locating => '위치 확인 중';

  @override
  String get checkDistance => '거리 확인';

  @override
  String pindPostCount(int count) {
    return 'Pind 게시물 $count개';
  }

  @override
  String get reviewCountUnknown => '리뷰 수 확인 필요';

  @override
  String reviewCountLong(int count) {
    return '리뷰 $count개';
  }

  @override
  String get tasteMatchHelp =>
      '전체 공개 평균을 1·2·3순위 50·30·20%로 반영해요. 1점은 해당 기준의 0%, 5점은 100%를 받아요.';

  @override
  String get tasteMatchUnrated => '내 취향 평가 부족';

  @override
  String tasteMatchMine(int percent) {
    return '내 취향 $percent%';
  }

  @override
  String axisNoRatingsDot(String criterion) {
    return '$criterion · 아직 평가가 없어요';
  }

  @override
  String axisAverageDot(String criterion, String score) {
    return '$criterion · 가게 평균 $score / 5';
  }

  @override
  String axisNoRatings(String criterion) {
    return '$criterion 아직 평가가 없어요';
  }

  @override
  String axisAverage(String criterion, String score) {
    return '$criterion 가게 평균 $score점';
  }

  @override
  String friendsVisitedPlace(String names, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$names 외 $others명님이 다녀갔어요',
      zero: '$names님이 다녀갔어요',
    );
    return '$_temp0';
  }

  @override
  String followingSaved(int count) {
    return '팔로잉 $count명 저장';
  }

  @override
  String placePhotoLabel(String place, int number) {
    return '$place 장소 사진 $number';
  }

  @override
  String photoBy(String name) {
    return '사진: $name';
  }

  @override
  String get photoSource => '사진 출처';

  @override
  String get intro => '소개';

  @override
  String oneLineSummaryTitle(String axes) {
    return '$axes 한 줄 요약';
  }

  @override
  String get noOneLiners => '아직 한 줄 평이 없어요.';

  @override
  String get noIntro => '제공된 소개가 없어요.';

  @override
  String dataBy(String source) {
    return '정보 제공: $source';
  }

  @override
  String get saved => '저장됨';

  @override
  String get directions => '길찾기';

  @override
  String get errWalkRoute => '도보 경로를 찾지 못했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get errLocationUseSearch => '현재 위치를 확인하지 못했어요. 검색으로 계속할 수 있어요.';

  @override
  String get walkFinding => '도보 경로를 찾고 있어요…';

  @override
  String get walkArrived => '도착했어요';

  @override
  String get walkRerouting => '경로를 다시 찾고 있어요…';

  @override
  String walkRemaining(String distance, int minutes) {
    return '$distance · 약 $minutes분';
  }

  @override
  String walkTo(String place) {
    return '$place까지 도보';
  }

  @override
  String get walkEnd => '안내 종료';

  @override
  String get openSearch => '검색 열기';

  @override
  String get mapSearchHint => '무엇을 먹고 싶나요?';

  @override
  String get editTaste => '취향 수정';

  @override
  String get mapLoadFailed => '지도를 불러올 수 없어요.';

  @override
  String get mapFallbackHint => '장소 검색과 목록으로 탐색할 수 있어요.';

  @override
  String get needsBackend => '연결 설정 후 장소를 탐색할 수 있어요.';

  @override
  String get zoomIn => '확대';

  @override
  String get zoomOut => '축소';

  @override
  String get myLocation => '현재 위치';

  @override
  String get newPost => '게시물 작성';

  @override
  String get addPhotos => '사진 추가';

  @override
  String get visitedRestaurant => '방문한 식당';

  @override
  String get ratings => '평점';

  @override
  String get ratingsRequired => '맛 · 양 · 분위기 (필수)';

  @override
  String get myAverageRating => '내 평균 별점';

  @override
  String get writeReview => '글 작성하기';

  @override
  String get optional => '선택';

  @override
  String get visibility => '공개 범위';

  @override
  String get visibilityPublic => '전체 공개';

  @override
  String get visibilityFriends => '친구 공개';

  @override
  String get visibilityPublicHint => '모든 사람이 볼 수 있어요';

  @override
  String get visibilityFriendsHint => '나를 팔로우한 친구만 볼 수 있어요';

  @override
  String get reviewHint => '이 음식을 고향 음식에 비유하면? 처음 먹어본 외국인으로서 솔직한 후기를 남겨주세요.';

  @override
  String errorPrefix(String message) {
    return '오류: $message';
  }

  @override
  String get publish => '게시하기';

  @override
  String photoLongPressDelete(int number) {
    return '사진 $number, 길게 눌러 삭제';
  }

  @override
  String get pickVisitedRestaurant => '방문한 식당을 선택해 주세요';

  @override
  String get change => '변경';

  @override
  String get rateBest => '최고예요';

  @override
  String get rateTasty => '맛있어요';

  @override
  String get rateOkay => '괜찮아요';

  @override
  String get rateMeh => '아쉬워요';

  @override
  String get rateBad => '별로예요';

  @override
  String get portionHuge => '아주 많아요';

  @override
  String get portionGenerous => '넉넉해요';

  @override
  String get portionJustRight => '적당해요';

  @override
  String get portionSmall => '적어요';

  @override
  String get portionTiny => '아주 적어요';

  @override
  String get rateGood => '좋아요';

  @override
  String get suggestSpicyLevels => '매움 단계를 선택할 수 있는 식당';

  @override
  String get suggestKoreanBbq => '한국 BBQ를 즐기면서 분위기 좋은 고깃집';

  @override
  String get suggestNepali => '네팔 사람들이 많이 방문한 식당';

  @override
  String get suggestVegetarian => 'Vegetarian 음식';

  @override
  String get suggestKoreanVietnamese => '한국식 베트남 음식';

  @override
  String get suggestSoloDrinks => '혼술 하기 좋은 식당';

  @override
  String get suggestPho => '느낌 좋은 쌀국수집';

  @override
  String get suggestSeongsuBar => '서울 성수동에 분위기 좋은 바';

  @override
  String get suggestHomeStyle => '한국 집밥 느낌의 식당';

  @override
  String get suggestTouristFavorite => '관광객들이 가장 많이 방문한 식당';

  @override
  String get placeKorean => '백반집';

  @override
  String get placeBarbecue => '고깃집';

  @override
  String get placeSoup => '국밥집';

  @override
  String get placeNoodles => '국수집';

  @override
  String get placeStreet => '분식집';

  @override
  String get placeJapanese => '일식집';

  @override
  String get placeSushi => '초밥집';

  @override
  String get placeChinese => '중국집';

  @override
  String get placeWestern => '파스타집';

  @override
  String get placeAsian => '쌀국수집';

  @override
  String get placeChicken => '치킨집';

  @override
  String get placeDessert => '디저트 카페';

  @override
  String get placeBakery => '빵집';

  @override
  String get placeBar => '술집';

  @override
  String get qualityTaste => '맛있는';

  @override
  String get qualityAmbience => '분위기 좋은';

  @override
  String get qualityValue => '가성비 좋은';

  @override
  String get qualityPortion => '양 많은';

  @override
  String get qualityService => '깔끔하고 친절한';

  @override
  String get qualityPhotogenic => '사진 잘 나오는';

  @override
  String get qualityQuiet => '조용한';

  @override
  String get qualityParking => '주차 편한';

  @override
  String get occasionPhraseSolo => '혼밥하기 좋은';

  @override
  String get occasionPhraseFriends => '친구들이랑 가기 좋은';

  @override
  String get occasionPhraseDate => '데이트하기 좋은';

  @override
  String get occasionPhraseFamily => '가족이랑 가기 좋은';

  @override
  String get occasionPhraseGroup => '회식하기 좋은';

  @override
  String get occasionPhraseWork => '카공하기 좋은';

  @override
  String get occasionPhraseDrinks => '한잔하기 좋은';

  @override
  String get occasionPhraseQuick => '빨리 먹을 수 있는';

  @override
  String get genericRestaurant => '식당';

  @override
  String get genericDining => '레스토랑';

  @override
  String get genericCafe => '카페';

  @override
  String get genericBar => '술집';

  @override
  String get suggestForMe => '내가 좋아할만한 곳 추천해줘';

  @override
  String suggestQuality(String quality, String place) {
    return '$quality $place';
  }

  @override
  String suggestOccasion(String phrase, String place) {
    return '$phrase $place';
  }

  @override
  String get cat00 => '백반/한정식';

  @override
  String get cat01 => '카페';

  @override
  String get cat02 => '요리 주점';

  @override
  String get cat03 => '김밥/만두/분식';

  @override
  String get cat04 => '돼지고기 구이/찜';

  @override
  String get cat05 => '빵/도넛';

  @override
  String get cat06 => '일식 회/초밥';

  @override
  String get cat07 => '경양식';

  @override
  String get cat08 => '치킨';

  @override
  String get cat09 => '국/탕/찌개류';

  @override
  String get cat10 => '중국집';

  @override
  String get cat11 => '피자';

  @override
  String get cat12 => '국수/칼국수';

  @override
  String get cat13 => '생맥주 전문';

  @override
  String get cat14 => '일반 유흥 주점';

  @override
  String get cat15 => '횟집';

  @override
  String get cat16 => '해산물 구이/찜';

  @override
  String get cat17 => '베트남식 전문';

  @override
  String get cat18 => '그 외 기타 간이 음식점';

  @override
  String get cat19 => '곱창 전골/구이';

  @override
  String get cat20 => '닭/오리고기 구이/찜';

  @override
  String get cat21 => '족발/보쌈';

  @override
  String get cat22 => '떡/한과';

  @override
  String get cat23 => '버거';

  @override
  String get cat24 => '소고기 구이/찜';

  @override
  String get cat25 => '구내식당';

  @override
  String get cat26 => '마라탕/훠궈';

  @override
  String get cat27 => '토스트/샌드위치/샐러드';

  @override
  String get cat28 => '냉면/밀면';

  @override
  String get cat29 => '일식 면 요리';

  @override
  String get cat30 => '일식 카레/돈가스/덮밥';

  @override
  String get cat31 => '아이스크림/빙수';

  @override
  String get cat32 => '파스타/스테이크';

  @override
  String get cat33 => '기타 서양식 음식점';

  @override
  String get cat34 => '기타 한식 음식점';

  @override
  String get cat35 => '전/부침개';

  @override
  String get cat36 => '뷔페';

  @override
  String get cat37 => '기타 일식 음식점';

  @override
  String get cat38 => '기타 동남아식 전문';

  @override
  String get cat39 => '무도 유흥 주점';

  @override
  String get cat40 => '패밀리레스토랑';

  @override
  String get cat41 => '복 요리 전문';

  @override
  String get cat42 => '분류 안된 외국식 음식점';

  @override
  String get errQueryNotUnderstood => '검색어를 이해하지 못했어요. 다르게 말해 주세요.';

  @override
  String get errOutsideKoreaMap => '대한민국 안에서 지도를 이동해 주세요.';

  @override
  String get errPlaceNotFound => '공개된 장소를 찾지 못했어요.';

  @override
  String get errPlaceServerRetry => '장소 DB에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get errRouteKoreaOnly => '한국 안의 출발지와 도착지만 안내할 수 있어요.';

  @override
  String get errRouteTooFar => '걸어가기엔 너무 멀어요.';

  @override
  String get errRouteUnavailable => '길찾기를 준비 중이에요.';

  @override
  String get errGoogleBusy => 'Google 검색 요청이 많아요. 잠시 후 다시 시도해 주세요.';

  @override
  String agentNotice(String label) {
    return '$label 기준으로 찾았어요.';
  }

  @override
  String get agentNoticeTaste => '내 취향 기준으로 찾았어요.';

  @override
  String agentNoticeTasteFoods(String foods) {
    return '내 취향 · $foods 기준으로 찾았어요.';
  }
}
