// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Pind';

  @override
  String get navMap => 'Map';

  @override
  String get navCompose => 'Post';

  @override
  String get navMyPage => 'My Page';

  @override
  String get loginTagline => 'Only places that fit your taste, on the map';

  @override
  String get loginKakao => 'Start with Kakao in 3 seconds';

  @override
  String get loginApple => 'Continue with Apple';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginPreview => 'Try it without signing in';

  @override
  String get authOpenFailed => 'Couldn\'t open sign-in. Please try again.';

  @override
  String get authAnonymousDisabled =>
      'Anonymous sign-in for development isn\'t enabled.';

  @override
  String get authPreviewFailed => 'Couldn\'t start the preview.';

  @override
  String get authUnavailable =>
      'Couldn\'t reach sign-in. Please try again shortly.';

  @override
  String get back => 'Back';

  @override
  String get clear => 'Clear';

  @override
  String postPhotoOpen(int number) {
    return 'View post photo $number';
  }

  @override
  String ratingScore(String criterion, int score) {
    return '$criterion $score points';
  }

  @override
  String get postDelete => 'Delete post';

  @override
  String get postDeleteTitle => 'Delete this post?';

  @override
  String get postDeleteBody =>
      'Its photos and ratings go too, and this can\'t be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get qrCameraDenied =>
      'The camera isn\'t available. Allow camera access in Settings.';

  @override
  String get qrNotPind => 'That\'s not a Pind friend code';

  @override
  String get qrHint => 'Fit your friend\'s Pind QR code inside the square';

  @override
  String get qrTitle => 'Scan a friend code';

  @override
  String get linkCopied => 'Link copied.';

  @override
  String get shareMyCode => 'Share my code';

  @override
  String get profileLoadFailed => 'Couldn\'t load the profile.';

  @override
  String get retry => 'Try again';

  @override
  String get kakaoTalk => 'KakaoTalk';

  @override
  String get instagram => 'Instagram';

  @override
  String get copyLink => 'Copy link';

  @override
  String get scanFriendCode => 'Scan a friend\'s code';

  @override
  String get myQrCode => 'My Pind QR code';

  @override
  String copyLinkLabel(String link) {
    return 'Copy link $link';
  }

  @override
  String shareTitle(String name) {
    return '$name\'s Pind';
  }

  @override
  String get shareBody => 'Take a look at their food taste map';

  @override
  String get viewProfile => 'View profile';

  @override
  String get inviteToPind => 'Invite friends to Pind';

  @override
  String get criterionTaste => 'Taste';

  @override
  String get criterionTasteHint => 'Ingredients and cooking';

  @override
  String get criterionAmbience => 'Ambience';

  @override
  String get criterionAmbienceHint => 'Interior and seating';

  @override
  String get criterionValue => 'Value';

  @override
  String get criterionValueHint => 'Worth the price';

  @override
  String get criterionPortion => 'Portion';

  @override
  String get criterionPortionHint => 'Enough for a meal';

  @override
  String get criterionService => 'Cleanliness & service';

  @override
  String get criterionServiceHint => 'Staff and hygiene';

  @override
  String get criterionPhotogenic => 'Photogenic';

  @override
  String get criterionPhotogenicHint => 'Worth a photo';

  @override
  String get criterionQuiet => 'Quiet';

  @override
  String get criterionQuietHint => 'Easy to talk';

  @override
  String get criterionParking => 'Parking';

  @override
  String get criterionParkingHint => 'Easy to park';

  @override
  String get occasionSolo => 'Eating solo';

  @override
  String get occasionSoloHint => 'Comfortable on your own';

  @override
  String get occasionFriends => 'With friends';

  @override
  String get occasionFriendsHint => 'Lively get-togethers';

  @override
  String get occasionDate => 'Date';

  @override
  String get occasionDateHint => 'Places with a mood';

  @override
  String get occasionFamily => 'Family meal';

  @override
  String get occasionFamilyHint => 'Spacious and quiet';

  @override
  String get occasionGroup => 'Team dinner';

  @override
  String get occasionGroupHint => 'Room for groups';

  @override
  String get occasionWork => 'Working';

  @override
  String get occasionWorkHint => 'Outlets and Wi-Fi';

  @override
  String get occasionDrinks => 'A drink';

  @override
  String get occasionDrinksHint => 'Open late';

  @override
  String get occasionQuick => 'In a hurry';

  @override
  String get occasionQuickHint => 'Food comes fast';

  @override
  String get cuisineKorean => 'Korean home-style';

  @override
  String get cuisineBarbecue => 'Korean BBQ';

  @override
  String get cuisineSoup => 'Soups & stews';

  @override
  String get cuisineNoodles => 'Noodles';

  @override
  String get cuisineStreet => 'Street food';

  @override
  String get cuisineJapanese => 'Japanese';

  @override
  String get cuisineSushi => 'Sushi & sashimi';

  @override
  String get cuisineChinese => 'Chinese';

  @override
  String get cuisineWestern => 'Western & pasta';

  @override
  String get cuisineAsian => 'Asian';

  @override
  String get cuisineChicken => 'Fried chicken';

  @override
  String get cuisineDessert => 'Cafés & desserts';

  @override
  String get cuisineBakery => 'Bakery';

  @override
  String get cuisineBar => 'Bars & pubs';

  @override
  String get pindUser => 'Pind user';

  @override
  String get photoProvider => 'Photo provider';

  @override
  String get sourceSbiz => 'Small Enterprise and Market Service';

  @override
  String get kakaoMap => 'Kakao Map';

  @override
  String get naverMap => 'Naver Map';

  @override
  String get unsupportedSource => 'This place source isn\'t supported.';

  @override
  String get sourceOpenData => 'Open data source';

  @override
  String get viewOnMap => 'View on map';

  @override
  String get directionsInGoogle => 'Directions in Google Maps';

  @override
  String get viewInKakao => 'View in Kakao Map';

  @override
  String get searchInNaver => 'Search in Naver Map';

  @override
  String friendsVisited(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name and $others others visited',
      one: '$name and 1 other visited',
      zero: '$name visited',
    );
    return '$_temp0';
  }

  @override
  String friendsSaved(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name and $others others saved this',
      one: '$name and 1 other saved this',
      zero: '$name saved this',
    );
    return '$_temp0';
  }

  @override
  String get errProfileServer => 'Couldn\'t reach the profile server.';

  @override
  String get errSignInRequired => 'Please sign in.';

  @override
  String get errHandleTaken => 'That ID is already taken.';

  @override
  String get errHandleImmutable => 'Your ID can\'t be changed once it\'s set.';

  @override
  String get errProfileSave => 'Couldn\'t save your profile. Please try again.';

  @override
  String get errProfileNotFound => 'Profile not found.';

  @override
  String get errFeedServer => 'Couldn\'t reach the feed server.';

  @override
  String get errNotificationsLoad => 'Couldn\'t load notifications.';

  @override
  String get errNotificationsRead => 'Couldn\'t mark notifications as read.';

  @override
  String get errFeedLoad => 'Couldn\'t load the feed.';

  @override
  String get errLikeSignIn => 'Sign in to like posts.';

  @override
  String get errFriendsServer => 'Couldn\'t reach the friends server.';

  @override
  String get errSuggestionsLoad => 'Couldn\'t load suggestions.';

  @override
  String get errSearchFailed => 'Search failed.';

  @override
  String get errFollowersLoad => 'Couldn\'t load followers.';

  @override
  String get errFollowingLoad => 'Couldn\'t load who you follow.';

  @override
  String get errFollow => 'Couldn\'t follow.';

  @override
  String get errUnfollow => 'Couldn\'t unfollow.';

  @override
  String get errQueryLength => 'Enter 2–120 characters to search.';

  @override
  String get errPlaceCheck => 'Couldn\'t verify the place.';

  @override
  String get errPlaceSignIn => 'Sign in to explore places.';

  @override
  String get errSessionStart => 'Couldn\'t start a session.';

  @override
  String get errPlaceLoad => 'Couldn\'t load places.';

  @override
  String get errPlaceServer => 'Couldn\'t reach the places server.';

  @override
  String get errPostSignIn => 'Sign in to post.';

  @override
  String get errPostServer => 'Couldn\'t reach the post server.';

  @override
  String get errPostDeleteRetry =>
      'Couldn\'t delete the post. Please try again.';

  @override
  String get errAccountChanged => 'Your account changed. Please sign in again.';

  @override
  String get errPostPublishKept =>
      'Couldn\'t publish. Your draft is kept, so please try again.';

  @override
  String get inviteGeneric => 'Follow each other\'s food taste on Pind!';

  @override
  String get errProfileLoadRetry =>
      'Couldn\'t load the profile. Please try again.';

  @override
  String get errPhotoUpload => 'Couldn\'t upload the photo. Please try again.';

  @override
  String get errDistanceNeedsLocation =>
      'Showing distance needs location access and Location Services.';

  @override
  String get errLocationUnknown => 'Couldn\'t find your current location.';

  @override
  String get errSaveUnsupported =>
      'Saving places from this source isn\'t supported yet. Check the original map.';

  @override
  String get errSaveUnavailable =>
      'Saving isn\'t available. Please reload the details.';

  @override
  String get errSaveRetry => 'Couldn\'t save. Please try again.';

  @override
  String get errLikeRetry => 'Couldn\'t update the like. Please try again.';

  @override
  String get errPostDelete => 'Couldn\'t delete the post.';

  @override
  String get errLinkOpen => 'Couldn\'t open the link. Please try again.';

  @override
  String get errShareOpen => 'Couldn\'t open the share sheet.';

  @override
  String get errLoginIncomplete =>
      'Couldn\'t finish signing in. Please try again.';

  @override
  String get errPreviewRetry =>
      'Couldn\'t start the preview. Please try again.';

  @override
  String get errDraftSave =>
      'Couldn\'t save what you entered. Please try again.';

  @override
  String get locationSkipHint =>
      'You can start with search even without location access.';

  @override
  String get errLocationPermission =>
      'Couldn\'t check location access. You can set it later.';

  @override
  String get errSettingsOpen =>
      'Couldn\'t open Settings. Allow location in your device settings.';

  @override
  String get errCheckInput => 'Please check what you entered.';

  @override
  String get errLocationServicesOff => 'Turn on Location Services.';

  @override
  String get errLocationDenied =>
      'Without location access, you can still move the map or search.';

  @override
  String get errOutsideKorea =>
      'You\'re outside Korea. Search for places in Korea.';

  @override
  String get errPhotoTooLarge => 'Choose photos of 10 MB or less each.';

  @override
  String get errPhotoFormat => 'Choose a supported photo format.';

  @override
  String get errPhotoLoad => 'Couldn\'t load the photo.';

  @override
  String get errPlaceSearchSignIn => 'Sign in to search restaurants.';

  @override
  String get errPostPublish => 'Couldn\'t publish the post.';

  @override
  String get errConnectionRetry => 'Check your connection and try again.';

  @override
  String inviteFollow(String who, String link) {
    return 'Follow $who on Pind and share your food taste!\n$link';
  }

  @override
  String agoWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String agoDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String agoHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String agoMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get notifications => 'Notifications';

  @override
  String unreadCount(int count) {
    return '$count unread';
  }

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotifications => 'No notifications yet.';

  @override
  String get notifLikeRest => ' liked your post';

  @override
  String get notifVisitMid => ' visited ';

  @override
  String get restaurant => 'a restaurant';

  @override
  String get notifVisitEnd => '';

  @override
  String get notifFollowRest => ' followed you';

  @override
  String get following => 'Following';

  @override
  String get followBack => 'Follow back';

  @override
  String get follow => 'Follow';

  @override
  String unfollowLabel(String label) {
    return '$label, unfollow';
  }

  @override
  String unfollowTitle(String name) {
    return 'Unfollow $name?';
  }

  @override
  String get unfollowBody => 'You can follow again anytime.';

  @override
  String get unfollow => 'Unfollow';

  @override
  String tasteMatchPercent(int percent) {
    return '$percent% taste match';
  }

  @override
  String unfollowName(String name) {
    return 'Unfollow $name';
  }

  @override
  String followName(String name) {
    return 'Follow $name';
  }

  @override
  String get errListLoad => 'Couldn\'t load the list.';

  @override
  String get tryAgainPlease => 'Please try again.';

  @override
  String peopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get followers => 'Followers';

  @override
  String get noFollowers => 'No followers yet.';

  @override
  String get noFollowing => 'You\'re not following anyone yet.';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutBody =>
      'Sign back in and your posts and saved places will be right here.';

  @override
  String get signOut => 'Sign out';

  @override
  String get errSignOut => 'Couldn\'t sign out. Please try again.';

  @override
  String get profileSettings => 'Profile settings';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get noHandle => 'No ID';

  @override
  String get handleLocked => 'Your ID can\'t be changed';

  @override
  String get name => 'Name';

  @override
  String get statusMessage => 'Status';

  @override
  String get statusHint => 'How\'s your day going?';

  @override
  String get save => 'Save';

  @override
  String get addFriend => 'Add friends';

  @override
  String get newNotifications => 'New notifications';

  @override
  String get exploreFriendsTaste => 'Explore your friends\' taste';

  @override
  String get inviteFriends => 'Invite friends';

  @override
  String get shareFriendsTaste => 'Share food taste with your friends';

  @override
  String get invite => 'Invite';

  @override
  String get noPostsYet => 'No posts yet.';

  @override
  String get postDeleted => 'Post deleted.';

  @override
  String get unlike => 'Unlike';

  @override
  String get like => 'Like';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get searchResults => 'Search results';

  @override
  String get noSearchResults => 'No results.';

  @override
  String get cantFindSomeone => 'Can\'t find who you\'re looking for?';

  @override
  String get inviteByLink => 'Invite with a link';

  @override
  String get shareMyCodeAction => 'Share my code';

  @override
  String get inviteByLinkHint => 'Invite friends with a link';

  @override
  String get similarTaste => 'People with similar taste';

  @override
  String get noSimilarTaste => 'No one with similar taste yet.';

  @override
  String get searchIdOrName => 'Search by ID or name';

  @override
  String get seeMore => 'See more ›';

  @override
  String get agentStepRead => 'Reading what you asked for';

  @override
  String get agentStepPlaces => 'Looking through places with posts';

  @override
  String get agentStepTaste => 'Finding places that fit your taste';

  @override
  String get errSearchRetry => 'Search failed. Please try again shortly.';

  @override
  String get errSaveToggle =>
      'Couldn\'t change the saved state. Please try again.';

  @override
  String get agentTitle => 'Food search made for you';

  @override
  String get agentSubtitle =>
      'The more you tell us about your taste, the better the picks.';

  @override
  String recommendedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places for you',
      one: '1 place for you',
    );
    return '$_temp0';
  }

  @override
  String get agentNoResults =>
      'No places with posts matched. Want to try putting it differently?';

  @override
  String get askAnything => 'Ask anything...';

  @override
  String get voiceSearch => 'Voice search';

  @override
  String get search => 'Search';

  @override
  String get voiceComingSoon => 'Voice search is coming soon.';

  @override
  String get rankingFromMapCenter =>
      'Couldn\'t find your location, so this is within 10 km of the map center.';

  @override
  String get rankingEmpty => 'No places with posts within 10 km yet.';

  @override
  String get sortByTaste => 'By my taste';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get unsave => 'Remove from saved';

  @override
  String get taste => 'Taste';

  @override
  String ratingScoreText(String criterion, String score) {
    return '$criterion $score points';
  }

  @override
  String get backToMap => 'Back to map';

  @override
  String get checkLocationInSettings => 'Check location access in Settings';

  @override
  String get allowLocationStart => 'Allow location and start';

  @override
  String get later => 'Maybe later';

  @override
  String get locationTitle => 'Let\'s start with\nwhere you are now';

  @override
  String get locationBody =>
      'Allow location to explore great food and tastes around you.';

  @override
  String get nearbyFood => 'Food near me';

  @override
  String get nearbyFoodHint => 'Picks within your area only';

  @override
  String get friendsFood => 'Friends\' favorites';

  @override
  String get friendsFoodHint => 'See where your friends have eaten';

  @override
  String get localRanking => 'Local ranking';

  @override
  String get localRankingHint => 'Area rankings like #1 in Seongsu-dong';

  @override
  String get recentlyViewed => 'Recently viewed';

  @override
  String get recentlyViewedEmpty =>
      'Places you viewed in the last 24 hours show up here.';

  @override
  String get savedPlaces => 'Saved places';

  @override
  String get noSavedPlaces => 'No saved places yet.';

  @override
  String get noSharedSaves => 'No shared saved places.';

  @override
  String get noPlacesToShow => 'No places to show.';

  @override
  String get settings => 'Settings';

  @override
  String get posts => 'Posts';

  @override
  String get myMap => 'My map';

  @override
  String get badgeFoodie => 'Foodie';

  @override
  String get badgePoster => 'Top poster';

  @override
  String get badgeJudge => 'Restaurant judge';

  @override
  String get badges => 'Badges';

  @override
  String get myMapTitle => 'My map';

  @override
  String get noPostsWritten => 'No posts yet';

  @override
  String get mapUnavailable => 'The map isn\'t available';

  @override
  String get viewMap => 'View map ›';

  @override
  String get myTaste => 'My taste';

  @override
  String tasteType(String criterion) {
    return '$criterion first';
  }

  @override
  String get edit => '✎ Edit';

  @override
  String get tasteEmpty => 'Set your taste and it\'ll show up here.';

  @override
  String get noPublicTaste => 'No public taste.';

  @override
  String tasteOrder(String first, String second, String third) {
    return '$first first, then $second and $third.';
  }

  @override
  String agoYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String agoMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String savedAgo(String ago) {
    return 'Saved $ago';
  }

  @override
  String get sortRecentSaved => 'Recently saved';

  @override
  String placesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get onboardingTitlePriorities =>
      'What matters most\nwhen you pick a place?';

  @override
  String get onboardingTitleOccasions => 'When do you usually eat out?';

  @override
  String get onboardingTitleCuisines => 'Pick what you like.';

  @override
  String get onboardingHintPriorities =>
      'Exactly 3. They count 50% · 30% · 20%, in order.';

  @override
  String get onboardingHintOccasions =>
      'Up to 3. We\'ll make lists for each occasion.';

  @override
  String get onboardingHintCuisines =>
      'Pick 3 or more. The more you pick, the better the picks.';

  @override
  String get onboardingPickThree => 'Pick the 3 things that matter most.';

  @override
  String prioritiesOrder(String order) {
    return 'Counted in this order: $order';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get previous => 'Back';

  @override
  String onboardingStep(int step) {
    return 'Taste setup, step $step of 3';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get buildTasteMap => 'Build my taste map';

  @override
  String get next => 'Next';

  @override
  String rankLabel(int rank) {
    return '#$rank';
  }

  @override
  String get filterNearby => '📍 Near me';

  @override
  String get filterRecent => 'Recently visited';

  @override
  String get filterSaved => 'Saved';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryCafe => 'Cafés';

  @override
  String get categoryBar => 'Bars';

  @override
  String get categoryMeat => 'BBQ';

  @override
  String get categoryNoodles => 'Noodles';

  @override
  String get categoryDessert => 'Desserts';

  @override
  String get errRestaurantSearch => 'Couldn\'t search restaurants.';

  @override
  String get errLocationCheckPermission =>
      'Can\'t find your location. Check location access.';

  @override
  String get notInRecent => 'Not among places you recently visited.';

  @override
  String get noRecentViews => 'No places viewed in the last 24 hours.';

  @override
  String get notInSaved => 'Not among your saved places.';

  @override
  String get findingRestaurants => 'Finding restaurants.';

  @override
  String noNearbyMatch(String distance) {
    return 'No matching restaurants within $distance.';
  }

  @override
  String get searchByNameOrAddress => 'Search by restaurant name or address.';

  @override
  String get whereDidYouGo => 'Where did you go?';

  @override
  String get nameOrAddress => 'Restaurant name or address';

  @override
  String selectPlace(String name) {
    return 'Select $name';
  }

  @override
  String get select => 'Select';

  @override
  String get errProfileOpen => 'Couldn\'t open the profile.';

  @override
  String get postPublished => 'Posted.';

  @override
  String postPhotoOf(int number, int total) {
    return 'Post photo $number of $total';
  }

  @override
  String get noPostsYetMine => 'You haven\'t posted yet.';

  @override
  String get share => 'Share';

  @override
  String get errTasteSave => 'Couldn\'t save your taste. Please try again.';

  @override
  String countrySelected(String country) {
    return '$country selected';
  }

  @override
  String get countryTitle => 'Choose\nyour country';

  @override
  String get countryBody =>
      'This sets the service area, language and currency.';

  @override
  String get countrySearch => 'Search countries';

  @override
  String get countryPopular => 'Popular countries';

  @override
  String get countryKoreaOnly =>
      'Restaurant discovery is currently available in South Korea.';

  @override
  String get basicTitle => 'Tell us\nabout you';

  @override
  String get basicBody =>
      'Used only to suggest places people your age love.\nIt\'s never shown on your profile.';

  @override
  String get enterName => 'Enter your name';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get preferNotToSay => 'Prefer not to say';

  @override
  String get birthDate => 'Date of birth';

  @override
  String ageBand(int age, int decade, String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'early': 'early',
      'mid': 'mid',
      'other': 'late',
    });
    return '$age · $_temp0 ${decade}s';
  }

  @override
  String get ageUsedFor => 'Used for suggestions from people your age';

  @override
  String get ageMinimum => 'You must be 14 or older to use Pind.';

  @override
  String get consentPrivacy =>
      'I agree to the collection and use of personal info (required)';

  @override
  String get consentPrivacyBody =>
      'Your name, gender and date of birth are used for your basic info and taste suggestions, and never shown on your public profile.';

  @override
  String get consentAge => 'I\'m 14 or older (required)';

  @override
  String get consentAgeBody =>
      'Check your date of birth and tick this if you\'re 14 or older.';

  @override
  String get consentPersonalize =>
      'Use my info for personalized suggestions (optional)';

  @override
  String get consentPersonalizeBody =>
      'You can still use the basic service and place search without it.';

  @override
  String get year => 'Year';

  @override
  String get month => 'Month';

  @override
  String get day => 'Day';

  @override
  String viewDetails(String title) {
    return 'View $title';
  }

  @override
  String get startPind => 'Start Pind';

  @override
  String get handleTitle => 'What should\nwe call you?';

  @override
  String get handleBody =>
      'Your ID can\'t be changed later. Your nickname can be changed anytime.';

  @override
  String get chooseAvatar => 'Choose avatar';

  @override
  String get handle => 'ID';

  @override
  String get enterHandle => 'Enter an ID';

  @override
  String get handleValid => '✓ Looks good';

  @override
  String get handleRule => 'Use 3–20 letters, numbers or underscores.';

  @override
  String get chooseEmoji => 'Pick an emoji that\'s you';

  @override
  String get pickFromAlbum => 'Choose from photos';

  @override
  String get errDetailLoad => 'Couldn\'t load the details.';

  @override
  String get errContextLoad => 'Couldn\'t load taste and following info.';

  @override
  String get detailSwipeHint => '⌃  Swipe up for intro · posts';

  @override
  String get hoursUnknown => 'Check opening hours';

  @override
  String get openNow => 'Open';

  @override
  String get closedNow => 'Closed';

  @override
  String get locating => 'Locating';

  @override
  String get checkDistance => 'Check distance';

  @override
  String pindPostCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Pind posts',
      one: '1 Pind post',
    );
    return '$_temp0';
  }

  @override
  String get reviewCountUnknown => 'Review count unknown';

  @override
  String reviewCountLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get tasteMatchHelp =>
      'Public averages count 50·30·20% for your 1st·2nd·3rd priority. A 1 scores 0% on that criterion and a 5 scores 100%.';

  @override
  String get tasteMatchUnrated => 'My taste: not enough ratings';

  @override
  String tasteMatchMine(int percent) {
    return 'My taste $percent%';
  }

  @override
  String axisNoRatingsDot(String criterion) {
    return '$criterion · No ratings yet';
  }

  @override
  String axisAverageDot(String criterion, String score) {
    return '$criterion · Average $score / 5';
  }

  @override
  String axisNoRatings(String criterion) {
    return '$criterion: no ratings yet';
  }

  @override
  String axisAverage(String criterion, String score) {
    return '$criterion: average $score points';
  }

  @override
  String friendsVisitedPlace(String names, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$names and $others others visited',
      one: '$names and 1 other visited',
      zero: '$names visited',
    );
    return '$_temp0';
  }

  @override
  String followingSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people you follow saved this',
      one: '1 person you follow saved this',
    );
    return '$_temp0';
  }

  @override
  String placePhotoLabel(String place, int number) {
    return '$place photo $number';
  }

  @override
  String photoBy(String name) {
    return 'Photo: $name';
  }

  @override
  String get photoSource => 'Photo source';

  @override
  String get intro => 'Intro';

  @override
  String oneLineSummaryTitle(String axes) {
    return 'One-line takes: $axes';
  }

  @override
  String get noOneLiners => 'No one-line takes yet.';

  @override
  String get noIntro => 'No intro available.';

  @override
  String dataBy(String source) {
    return 'Data: $source';
  }

  @override
  String get saved => 'Saved';

  @override
  String get directions => 'Directions';

  @override
  String get errWalkRoute =>
      'Couldn\'t find a walking route. Please try again shortly.';

  @override
  String get errLocationUseSearch =>
      'Couldn\'t find your location. You can keep going with search.';

  @override
  String get walkFinding => 'Finding a walking route…';

  @override
  String get walkArrived => 'You\'ve arrived';

  @override
  String get walkRerouting => 'Finding a new route…';

  @override
  String walkRemaining(String distance, int minutes) {
    return '$distance · about $minutes min';
  }

  @override
  String walkTo(String place) {
    return 'Walking to $place';
  }

  @override
  String get walkEnd => 'End';

  @override
  String get openSearch => 'Open search';

  @override
  String get mapSearchHint => 'What are you craving?';

  @override
  String get editTaste => 'Edit taste';

  @override
  String get mapLoadFailed => 'The map couldn\'t load.';

  @override
  String get mapFallbackHint => 'You can still explore with search and lists.';

  @override
  String get needsBackend => 'Set up the connection to explore places.';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get myLocation => 'My location';

  @override
  String get newPost => 'New post';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get visitedRestaurant => 'Restaurant you visited';

  @override
  String get ratings => 'Ratings';

  @override
  String get ratingsRequired => 'Taste · Portion · Ambience (required)';

  @override
  String get myAverageRating => 'My average rating';

  @override
  String get writeReview => 'Write something';

  @override
  String get optional => 'Optional';

  @override
  String get visibility => 'Who can see this';

  @override
  String get visibilityPublic => 'Everyone';

  @override
  String get visibilityFriends => 'Friends';

  @override
  String get visibilityPublicHint => 'Anyone on Pind can see this';

  @override
  String get visibilityFriendsHint => 'Only people who follow you can see this';

  @override
  String get reviewHint =>
      'What food from home is it like? Leave an honest take as someone trying it for the first time.';

  @override
  String errorPrefix(String message) {
    return 'Error: $message';
  }

  @override
  String get publish => 'Post';

  @override
  String photoLongPressDelete(int number) {
    return 'Photo $number, long-press to remove';
  }

  @override
  String get pickVisitedRestaurant => 'Choose the restaurant you visited';

  @override
  String get change => 'Change';

  @override
  String get rateBest => 'Amazing';

  @override
  String get rateTasty => 'Tasty';

  @override
  String get rateOkay => 'It\'s okay';

  @override
  String get rateMeh => 'A bit lacking';

  @override
  String get rateBad => 'Not good';

  @override
  String get portionHuge => 'Huge';

  @override
  String get portionGenerous => 'Generous';

  @override
  String get portionJustRight => 'Just right';

  @override
  String get portionSmall => 'Small';

  @override
  String get portionTiny => 'Tiny';

  @override
  String get rateGood => 'Good';

  @override
  String get suggestSpicyLevels => 'Places where you can pick the spice level';

  @override
  String get suggestKoreanBbq => 'Korean BBQ spots with a great vibe';

  @override
  String get suggestNepali => 'Places popular with Nepali visitors';

  @override
  String get suggestVegetarian => 'Vegetarian food';

  @override
  String get suggestKoreanVietnamese => 'Korean-style Vietnamese food';

  @override
  String get suggestSoloDrinks => 'Good spots for a drink alone';

  @override
  String get suggestPho => 'Cozy pho places';

  @override
  String get suggestSeongsuBar =>
      'Bars with a great vibe in Seongsu-dong, Seoul';

  @override
  String get suggestHomeStyle => 'Places that taste like Korean home cooking';

  @override
  String get suggestTouristFavorite => 'Places tourists visit most';

  @override
  String get placeKorean => 'Korean home-style places';

  @override
  String get placeBarbecue => 'BBQ places';

  @override
  String get placeSoup => 'gukbap places';

  @override
  String get placeNoodles => 'noodle places';

  @override
  String get placeStreet => 'street food spots';

  @override
  String get placeJapanese => 'Japanese restaurants';

  @override
  String get placeSushi => 'sushi places';

  @override
  String get placeChinese => 'Chinese restaurants';

  @override
  String get placeWestern => 'pasta places';

  @override
  String get placeAsian => 'pho places';

  @override
  String get placeChicken => 'fried chicken places';

  @override
  String get placeDessert => 'dessert cafés';

  @override
  String get placeBakery => 'bakeries';

  @override
  String get placeBar => 'bars';

  @override
  String get qualityTaste => 'Delicious';

  @override
  String get qualityAmbience => 'Cozy';

  @override
  String get qualityValue => 'Great-value';

  @override
  String get qualityPortion => 'Big-portion';

  @override
  String get qualityService => 'Clean, friendly';

  @override
  String get qualityPhotogenic => 'Photogenic';

  @override
  String get qualityQuiet => 'Quiet';

  @override
  String get qualityParking => 'Easy-parking';

  @override
  String get occasionPhraseSolo => 'for eating solo';

  @override
  String get occasionPhraseFriends => 'for going with friends';

  @override
  String get occasionPhraseDate => 'for a date';

  @override
  String get occasionPhraseFamily => 'for a family meal';

  @override
  String get occasionPhraseGroup => 'for a team dinner';

  @override
  String get occasionPhraseWork => 'for working';

  @override
  String get occasionPhraseDrinks => 'for a drink';

  @override
  String get occasionPhraseQuick => 'for a quick bite';

  @override
  String get genericRestaurant => 'Restaurants';

  @override
  String get genericDining => 'Restaurants';

  @override
  String get genericCafe => 'Cafés';

  @override
  String get genericBar => 'Bars';

  @override
  String get suggestForMe => 'Recommend places I\'d like';

  @override
  String suggestQuality(String quality, String place) {
    return '$quality $place';
  }

  @override
  String suggestOccasion(String phrase, String place) {
    return '$place $phrase';
  }

  @override
  String get cat00 => 'Korean set meals';

  @override
  String get cat01 => 'Café';

  @override
  String get cat02 => 'Gastropub';

  @override
  String get cat03 => 'Kimbap & snacks';

  @override
  String get cat04 => 'Grilled pork';

  @override
  String get cat05 => 'Bread & donuts';

  @override
  String get cat06 => 'Sashimi & sushi';

  @override
  String get cat07 => 'Western-style diner';

  @override
  String get cat08 => 'Fried chicken';

  @override
  String get cat09 => 'Soups & stews';

  @override
  String get cat10 => 'Chinese restaurant';

  @override
  String get cat11 => 'Pizza';

  @override
  String get cat12 => 'Noodles';

  @override
  String get cat13 => 'Draft beer pub';

  @override
  String get cat14 => 'Bar';

  @override
  String get cat15 => 'Raw fish restaurant';

  @override
  String get cat16 => 'Grilled & steamed seafood';

  @override
  String get cat17 => 'Vietnamese';

  @override
  String get cat18 => 'Casual eatery';

  @override
  String get cat19 => 'Grilled & hot pot tripe';

  @override
  String get cat20 => 'Grilled & braised chicken and duck';

  @override
  String get cat21 => 'Jokbal & bossam';

  @override
  String get cat22 => 'Rice cakes & Korean sweets';

  @override
  String get cat23 => 'Burgers';

  @override
  String get cat24 => 'Grilled beef';

  @override
  String get cat25 => 'Cafeteria';

  @override
  String get cat26 => 'Malatang & hot pot';

  @override
  String get cat27 => 'Toast, sandwiches & salads';

  @override
  String get cat28 => 'Cold noodles';

  @override
  String get cat29 => 'Japanese noodles';

  @override
  String get cat30 => 'Japanese curry, katsu & rice bowls';

  @override
  String get cat31 => 'Ice cream & bingsu';

  @override
  String get cat32 => 'Pasta & steak';

  @override
  String get cat33 => 'Western restaurant';

  @override
  String get cat34 => 'Korean restaurant';

  @override
  String get cat35 => 'Korean pancakes';

  @override
  String get cat36 => 'Buffet';

  @override
  String get cat37 => 'Japanese restaurant';

  @override
  String get cat38 => 'Southeast Asian';

  @override
  String get cat39 => 'Dance bar';

  @override
  String get cat40 => 'Family restaurant';

  @override
  String get cat41 => 'Pufferfish';

  @override
  String get cat42 => 'International restaurant';

  @override
  String get errQueryNotUnderstood =>
      'Couldn\'t understand that. Try saying it differently.';

  @override
  String get errOutsideKoreaMap => 'Move the map within South Korea.';

  @override
  String get errPlaceNotFound => 'Couldn\'t find that place.';

  @override
  String get errPlaceServerRetry =>
      'Couldn\'t reach the places database. Please try again shortly.';

  @override
  String get errRouteKoreaOnly =>
      'Directions are only available within South Korea.';

  @override
  String get errRouteTooFar => 'That\'s too far to walk.';

  @override
  String get errRouteUnavailable => 'Directions are coming soon.';

  @override
  String get errGoogleBusy =>
      'Google search is busy. Please try again shortly.';

  @override
  String agentNotice(String label) {
    return 'Searched for: $label.';
  }

  @override
  String get agentNoticeTaste => 'Picked for your taste.';

  @override
  String agentNoticeTasteFoods(String foods) {
    return 'Picked for your taste: $foods.';
  }
}
