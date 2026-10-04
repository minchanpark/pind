import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// App name
  ///
  /// In ko, this message translates to:
  /// **'Pind'**
  String get appTitle;

  /// No description provided for @navMap.
  ///
  /// In ko, this message translates to:
  /// **'지도'**
  String get navMap;

  /// No description provided for @navCompose.
  ///
  /// In ko, this message translates to:
  /// **'작성'**
  String get navCompose;

  /// No description provided for @navMyPage.
  ///
  /// In ko, this message translates to:
  /// **'마이페이지'**
  String get navMyPage;

  /// No description provided for @loginTagline.
  ///
  /// In ko, this message translates to:
  /// **'내 취향에 맞는 맛집만, 지도 위에서'**
  String get loginTagline;

  /// No description provided for @loginKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오로 3초 만에 시작하기'**
  String get loginKakao;

  /// No description provided for @loginApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get loginApple;

  /// No description provided for @loginGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get loginGoogle;

  /// No description provided for @loginPreview.
  ///
  /// In ko, this message translates to:
  /// **'로그인 없이 화면 체험'**
  String get loginPreview;

  /// No description provided for @authOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인 창을 열지 못했어요. 다시 시도해 주세요.'**
  String get authOpenFailed;

  /// No description provided for @authAnonymousDisabled.
  ///
  /// In ko, this message translates to:
  /// **'개발용 익명 인증이 허용되지 않았어요.'**
  String get authAnonymousDisabled;

  /// No description provided for @authPreviewFailed.
  ///
  /// In ko, this message translates to:
  /// **'체험을 시작하지 못했어요.'**
  String get authPreviewFailed;

  /// No description provided for @authUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'로그인에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.'**
  String get authUnavailable;

  /// No description provided for @back.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get back;

  /// No description provided for @clear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get clear;

  /// No description provided for @postPhotoOpen.
  ///
  /// In ko, this message translates to:
  /// **'게시물 사진 {number} 크게 보기'**
  String postPhotoOpen(int number);

  /// No description provided for @ratingScore.
  ///
  /// In ko, this message translates to:
  /// **'{criterion} {score}점'**
  String ratingScore(String criterion, int score);

  /// No description provided for @postDelete.
  ///
  /// In ko, this message translates to:
  /// **'게시물 삭제'**
  String get postDelete;

  /// No description provided for @postDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'게시물을 삭제할까요?'**
  String get postDeleteTitle;

  /// No description provided for @postDeleteBody.
  ///
  /// In ko, this message translates to:
  /// **'사진과 별점도 함께 지워지고, 되돌릴 수 없어요.'**
  String get postDeleteBody;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @qrCameraDenied.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 사용할 수 없어요. 설정에서 카메라 권한을 허용해 주세요.'**
  String get qrCameraDenied;

  /// No description provided for @qrNotPind.
  ///
  /// In ko, this message translates to:
  /// **'Pind 친구 코드가 아니에요'**
  String get qrNotPind;

  /// No description provided for @qrHint.
  ///
  /// In ko, this message translates to:
  /// **'친구의 Pind QR 코드를 네모 안에 맞춰 주세요'**
  String get qrHint;

  /// No description provided for @qrTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구 코드 스캔'**
  String get qrTitle;

  /// No description provided for @linkCopied.
  ///
  /// In ko, this message translates to:
  /// **'링크를 복사했어요.'**
  String get linkCopied;

  /// No description provided for @shareMyCode.
  ///
  /// In ko, this message translates to:
  /// **'내 코드 공유'**
  String get shareMyCode;

  /// No description provided for @profileLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 불러오지 못했어요.'**
  String get profileLoadFailed;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @kakaoTalk.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡'**
  String get kakaoTalk;

  /// No description provided for @instagram.
  ///
  /// In ko, this message translates to:
  /// **'인스타'**
  String get instagram;

  /// No description provided for @copyLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 복사'**
  String get copyLink;

  /// No description provided for @scanFriendCode.
  ///
  /// In ko, this message translates to:
  /// **'친구 코드 스캔하기'**
  String get scanFriendCode;

  /// No description provided for @myQrCode.
  ///
  /// In ko, this message translates to:
  /// **'내 Pind QR 코드'**
  String get myQrCode;

  /// No description provided for @copyLinkLabel.
  ///
  /// In ko, this message translates to:
  /// **'링크 복사 {link}'**
  String copyLinkLabel(String link);

  /// No description provided for @shareTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님의 Pind'**
  String shareTitle(String name);

  /// No description provided for @shareBody.
  ///
  /// In ko, this message translates to:
  /// **'음식 취향 지도를 구경해 보세요'**
  String get shareBody;

  /// No description provided for @viewProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필 보기'**
  String get viewProfile;

  /// No description provided for @inviteToPind.
  ///
  /// In ko, this message translates to:
  /// **'Pind 친구 초대'**
  String get inviteToPind;

  /// No description provided for @criterionTaste.
  ///
  /// In ko, this message translates to:
  /// **'맛'**
  String get criterionTaste;

  /// No description provided for @criterionTasteHint.
  ///
  /// In ko, this message translates to:
  /// **'재료와 조리 완성도'**
  String get criterionTasteHint;

  /// No description provided for @criterionAmbience.
  ///
  /// In ko, this message translates to:
  /// **'분위기·공간'**
  String get criterionAmbience;

  /// No description provided for @criterionAmbienceHint.
  ///
  /// In ko, this message translates to:
  /// **'인테리어와 좌석'**
  String get criterionAmbienceHint;

  /// No description provided for @criterionValue.
  ///
  /// In ko, this message translates to:
  /// **'가성비'**
  String get criterionValue;

  /// No description provided for @criterionValueHint.
  ///
  /// In ko, this message translates to:
  /// **'가격 대비 만족'**
  String get criterionValueHint;

  /// No description provided for @criterionPortion.
  ///
  /// In ko, this message translates to:
  /// **'양'**
  String get criterionPortion;

  /// No description provided for @criterionPortionHint.
  ///
  /// In ko, this message translates to:
  /// **'한 끼에 충분한 양'**
  String get criterionPortionHint;

  /// No description provided for @criterionService.
  ///
  /// In ko, this message translates to:
  /// **'청결·서비스'**
  String get criterionService;

  /// No description provided for @criterionServiceHint.
  ///
  /// In ko, this message translates to:
  /// **'응대와 위생'**
  String get criterionServiceHint;

  /// No description provided for @criterionPhotogenic.
  ///
  /// In ko, this message translates to:
  /// **'사진 잘 나옴'**
  String get criterionPhotogenic;

  /// No description provided for @criterionPhotogenicHint.
  ///
  /// In ko, this message translates to:
  /// **'찍을 맛 나는 곳'**
  String get criterionPhotogenicHint;

  /// No description provided for @criterionQuiet.
  ///
  /// In ko, this message translates to:
  /// **'조용함'**
  String get criterionQuiet;

  /// No description provided for @criterionQuietHint.
  ///
  /// In ko, this message translates to:
  /// **'대화하기 좋은'**
  String get criterionQuietHint;

  /// No description provided for @criterionParking.
  ///
  /// In ko, this message translates to:
  /// **'주차'**
  String get criterionParking;

  /// No description provided for @criterionParkingHint.
  ///
  /// In ko, this message translates to:
  /// **'차 대기 편한'**
  String get criterionParkingHint;

  /// No description provided for @occasionSolo.
  ///
  /// In ko, this message translates to:
  /// **'혼밥'**
  String get occasionSolo;

  /// No description provided for @occasionSoloHint.
  ///
  /// In ko, this message translates to:
  /// **'혼자서도 편한 자리'**
  String get occasionSoloHint;

  /// No description provided for @occasionFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구들이랑'**
  String get occasionFriends;

  /// No description provided for @occasionFriendsHint.
  ///
  /// In ko, this message translates to:
  /// **'왁자지껄 모임'**
  String get occasionFriendsHint;

  /// No description provided for @occasionDate.
  ///
  /// In ko, this message translates to:
  /// **'데이트'**
  String get occasionDate;

  /// No description provided for @occasionDateHint.
  ///
  /// In ko, this message translates to:
  /// **'분위기 있는 곳'**
  String get occasionDateHint;

  /// No description provided for @occasionFamily.
  ///
  /// In ko, this message translates to:
  /// **'가족 식사'**
  String get occasionFamily;

  /// No description provided for @occasionFamilyHint.
  ///
  /// In ko, this message translates to:
  /// **'넓고 조용한 곳'**
  String get occasionFamilyHint;

  /// No description provided for @occasionGroup.
  ///
  /// In ko, this message translates to:
  /// **'회식·모임'**
  String get occasionGroup;

  /// No description provided for @occasionGroupHint.
  ///
  /// In ko, this message translates to:
  /// **'단체석 있는 곳'**
  String get occasionGroupHint;

  /// No description provided for @occasionWork.
  ///
  /// In ko, this message translates to:
  /// **'카공·작업'**
  String get occasionWork;

  /// No description provided for @occasionWorkHint.
  ///
  /// In ko, this message translates to:
  /// **'콘센트와 와이파이'**
  String get occasionWorkHint;

  /// No description provided for @occasionDrinks.
  ///
  /// In ko, this message translates to:
  /// **'술 한잔'**
  String get occasionDrinks;

  /// No description provided for @occasionDrinksHint.
  ///
  /// In ko, this message translates to:
  /// **'늦게까지 여는 곳'**
  String get occasionDrinksHint;

  /// No description provided for @occasionQuick.
  ///
  /// In ko, this message translates to:
  /// **'급할 때'**
  String get occasionQuick;

  /// No description provided for @occasionQuickHint.
  ///
  /// In ko, this message translates to:
  /// **'빨리 나오는 곳'**
  String get occasionQuickHint;

  /// No description provided for @cuisineKorean.
  ///
  /// In ko, this message translates to:
  /// **'한식·백반'**
  String get cuisineKorean;

  /// No description provided for @cuisineBarbecue.
  ///
  /// In ko, this message translates to:
  /// **'고기구이'**
  String get cuisineBarbecue;

  /// No description provided for @cuisineSoup.
  ///
  /// In ko, this message translates to:
  /// **'국물·탕'**
  String get cuisineSoup;

  /// No description provided for @cuisineNoodles.
  ///
  /// In ko, this message translates to:
  /// **'면·국수'**
  String get cuisineNoodles;

  /// No description provided for @cuisineStreet.
  ///
  /// In ko, this message translates to:
  /// **'분식'**
  String get cuisineStreet;

  /// No description provided for @cuisineJapanese.
  ///
  /// In ko, this message translates to:
  /// **'일식'**
  String get cuisineJapanese;

  /// No description provided for @cuisineSushi.
  ///
  /// In ko, this message translates to:
  /// **'스시·회'**
  String get cuisineSushi;

  /// No description provided for @cuisineChinese.
  ///
  /// In ko, this message translates to:
  /// **'중식'**
  String get cuisineChinese;

  /// No description provided for @cuisineWestern.
  ///
  /// In ko, this message translates to:
  /// **'양식·파스타'**
  String get cuisineWestern;

  /// No description provided for @cuisineAsian.
  ///
  /// In ko, this message translates to:
  /// **'아시안'**
  String get cuisineAsian;

  /// No description provided for @cuisineChicken.
  ///
  /// In ko, this message translates to:
  /// **'치킨'**
  String get cuisineChicken;

  /// No description provided for @cuisineDessert.
  ///
  /// In ko, this message translates to:
  /// **'카페·디저트'**
  String get cuisineDessert;

  /// No description provided for @cuisineBakery.
  ///
  /// In ko, this message translates to:
  /// **'베이커리'**
  String get cuisineBakery;

  /// No description provided for @cuisineBar.
  ///
  /// In ko, this message translates to:
  /// **'술집·바'**
  String get cuisineBar;

  /// No description provided for @pindUser.
  ///
  /// In ko, this message translates to:
  /// **'Pind 사용자'**
  String get pindUser;

  /// No description provided for @photoProvider.
  ///
  /// In ko, this message translates to:
  /// **'사진 제공자'**
  String get photoProvider;

  /// No description provided for @sourceSbiz.
  ///
  /// In ko, this message translates to:
  /// **'소상공인시장진흥공단'**
  String get sourceSbiz;

  /// No description provided for @kakaoMap.
  ///
  /// In ko, this message translates to:
  /// **'카카오맵'**
  String get kakaoMap;

  /// No description provided for @naverMap.
  ///
  /// In ko, this message translates to:
  /// **'네이버 지도'**
  String get naverMap;

  /// No description provided for @unsupportedSource.
  ///
  /// In ko, this message translates to:
  /// **'지원하지 않는 장소 출처입니다.'**
  String get unsupportedSource;

  /// No description provided for @sourceOpenData.
  ///
  /// In ko, this message translates to:
  /// **'공공데이터 원본'**
  String get sourceOpenData;

  /// No description provided for @viewOnMap.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 확인'**
  String get viewOnMap;

  /// No description provided for @directionsInGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google Maps에서 길찾기'**
  String get directionsInGoogle;

  /// No description provided for @viewInKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오맵에서 확인'**
  String get viewInKakao;

  /// No description provided for @searchInNaver.
  ///
  /// In ko, this message translates to:
  /// **'네이버 지도에서 검색'**
  String get searchInNaver;

  /// No description provided for @friendsVisited.
  ///
  /// In ko, this message translates to:
  /// **'{others, plural, =0{{name}님이 다녀감} other{{name} 외 {others}명이 다녀감}}'**
  String friendsVisited(String name, int others);

  /// No description provided for @friendsSaved.
  ///
  /// In ko, this message translates to:
  /// **'{others, plural, =0{{name}님이 저장함} other{{name} 외 {others}명이 저장함}}'**
  String friendsSaved(String name, int others);

  /// No description provided for @errProfileServer.
  ///
  /// In ko, this message translates to:
  /// **'프로필 서버에 연결하지 못했어요.'**
  String get errProfileServer;

  /// No description provided for @errSignInRequired.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 필요해요.'**
  String get errSignInRequired;

  /// No description provided for @errHandleTaken.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 아이디예요.'**
  String get errHandleTaken;

  /// No description provided for @errHandleImmutable.
  ///
  /// In ko, this message translates to:
  /// **'아이디는 한 번 정하면 바꿀 수 없어요.'**
  String get errHandleImmutable;

  /// No description provided for @errProfileSave.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 저장하지 못했어요. 다시 시도해 주세요.'**
  String get errProfileSave;

  /// No description provided for @errProfileNotFound.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 찾을 수 없어요.'**
  String get errProfileNotFound;

  /// No description provided for @errFeedServer.
  ///
  /// In ko, this message translates to:
  /// **'피드 서버에 연결하지 못했어요.'**
  String get errFeedServer;

  /// No description provided for @errNotificationsLoad.
  ///
  /// In ko, this message translates to:
  /// **'알림을 불러오지 못했어요.'**
  String get errNotificationsLoad;

  /// No description provided for @errNotificationsRead.
  ///
  /// In ko, this message translates to:
  /// **'알림을 읽음으로 바꾸지 못했어요.'**
  String get errNotificationsRead;

  /// No description provided for @errFeedLoad.
  ///
  /// In ko, this message translates to:
  /// **'피드를 불러오지 못했어요.'**
  String get errFeedLoad;

  /// No description provided for @errLikeSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 좋아요를 누를 수 있어요.'**
  String get errLikeSignIn;

  /// No description provided for @errFriendsServer.
  ///
  /// In ko, this message translates to:
  /// **'친구 서버에 연결하지 못했어요.'**
  String get errFriendsServer;

  /// No description provided for @errSuggestionsLoad.
  ///
  /// In ko, this message translates to:
  /// **'추천 목록을 불러오지 못했어요.'**
  String get errSuggestionsLoad;

  /// No description provided for @errSearchFailed.
  ///
  /// In ko, this message translates to:
  /// **'검색하지 못했어요.'**
  String get errSearchFailed;

  /// No description provided for @errFollowersLoad.
  ///
  /// In ko, this message translates to:
  /// **'팔로워를 불러오지 못했어요.'**
  String get errFollowersLoad;

  /// No description provided for @errFollowingLoad.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉을 불러오지 못했어요.'**
  String get errFollowingLoad;

  /// No description provided for @errFollow.
  ///
  /// In ko, this message translates to:
  /// **'팔로우하지 못했어요.'**
  String get errFollow;

  /// No description provided for @errUnfollow.
  ///
  /// In ko, this message translates to:
  /// **'팔로우를 취소하지 못했어요.'**
  String get errUnfollow;

  /// No description provided for @errQueryLength.
  ///
  /// In ko, this message translates to:
  /// **'검색어를 2~120자로 입력해 주세요.'**
  String get errQueryLength;

  /// No description provided for @errPlaceCheck.
  ///
  /// In ko, this message translates to:
  /// **'장소를 확인하지 못했어요.'**
  String get errPlaceCheck;

  /// No description provided for @errPlaceSignIn.
  ///
  /// In ko, this message translates to:
  /// **'장소를 탐색하려면 로그인이 필요해요.'**
  String get errPlaceSignIn;

  /// No description provided for @errSessionStart.
  ///
  /// In ko, this message translates to:
  /// **'세션을 시작하지 못했어요.'**
  String get errSessionStart;

  /// No description provided for @errPlaceLoad.
  ///
  /// In ko, this message translates to:
  /// **'장소를 불러오지 못했어요.'**
  String get errPlaceLoad;

  /// No description provided for @errPlaceServer.
  ///
  /// In ko, this message translates to:
  /// **'장소 서버에 연결하지 못했어요.'**
  String get errPlaceServer;

  /// No description provided for @errPostSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 게시물을 작성해 주세요.'**
  String get errPostSignIn;

  /// No description provided for @errPostServer.
  ///
  /// In ko, this message translates to:
  /// **'게시물 서버에 연결하지 못했어요.'**
  String get errPostServer;

  /// No description provided for @errPostDeleteRetry.
  ///
  /// In ko, this message translates to:
  /// **'게시물을 삭제하지 못했어요. 다시 시도해 주세요.'**
  String get errPostDeleteRetry;

  /// No description provided for @errAccountChanged.
  ///
  /// In ko, this message translates to:
  /// **'계정이 변경되었어요. 다시 로그인해 주세요.'**
  String get errAccountChanged;

  /// No description provided for @errPostPublishKept.
  ///
  /// In ko, this message translates to:
  /// **'게시물을 등록하지 못했어요. 입력 내용을 유지했으니 다시 시도해 주세요.'**
  String get errPostPublishKept;

  /// No description provided for @inviteGeneric.
  ///
  /// In ko, this message translates to:
  /// **'Pind에서 서로의 음식 취향을 팔로우해요!'**
  String get inviteGeneric;

  /// No description provided for @errProfileLoadRetry.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 불러오지 못했어요. 다시 시도해 주세요.'**
  String get errProfileLoadRetry;

  /// No description provided for @errPhotoUpload.
  ///
  /// In ko, this message translates to:
  /// **'사진을 올리지 못했어요. 다시 시도해 주세요.'**
  String get errPhotoUpload;

  /// No description provided for @errDistanceNeedsLocation.
  ///
  /// In ko, this message translates to:
  /// **'거리 표시는 위치 권한과 기기 위치 서비스가 필요해요.'**
  String get errDistanceNeedsLocation;

  /// No description provided for @errLocationUnknown.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치를 확인하지 못했어요.'**
  String get errLocationUnknown;

  /// No description provided for @errSaveUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 출처의 장소 저장은 아직 지원하지 않아요. 원본 지도에서 확인해 주세요.'**
  String get errSaveUnsupported;

  /// No description provided for @errSaveUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'저장 기능을 연결하지 못했어요. 상세 정보를 다시 불러와 주세요.'**
  String get errSaveUnavailable;

  /// No description provided for @errSaveRetry.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 다시 시도해 주세요.'**
  String get errSaveRetry;

  /// No description provided for @errLikeRetry.
  ///
  /// In ko, this message translates to:
  /// **'좋아요를 반영하지 못했어요. 다시 시도해 주세요.'**
  String get errLikeRetry;

  /// No description provided for @errPostDelete.
  ///
  /// In ko, this message translates to:
  /// **'게시물을 삭제하지 못했어요.'**
  String get errPostDelete;

  /// No description provided for @errLinkOpen.
  ///
  /// In ko, this message translates to:
  /// **'링크를 열지 못했어요. 다시 시도해 주세요.'**
  String get errLinkOpen;

  /// No description provided for @errShareOpen.
  ///
  /// In ko, this message translates to:
  /// **'공유 창을 열지 못했어요.'**
  String get errShareOpen;

  /// No description provided for @errLoginIncomplete.
  ///
  /// In ko, this message translates to:
  /// **'로그인을 완료하지 못했어요. 다시 시도해 주세요.'**
  String get errLoginIncomplete;

  /// No description provided for @errPreviewRetry.
  ///
  /// In ko, this message translates to:
  /// **'체험을 시작하지 못했어요. 다시 시도해 주세요.'**
  String get errPreviewRetry;

  /// No description provided for @errDraftSave.
  ///
  /// In ko, this message translates to:
  /// **'입력 내용을 저장하지 못했어요. 다시 시도해 주세요.'**
  String get errDraftSave;

  /// No description provided for @locationSkipHint.
  ///
  /// In ko, this message translates to:
  /// **'위치를 허용하지 않아도 검색으로 시작할 수 있어요.'**
  String get locationSkipHint;

  /// No description provided for @errLocationPermission.
  ///
  /// In ko, this message translates to:
  /// **'위치 권한을 확인하지 못했어요. 나중에 설정할 수 있어요.'**
  String get errLocationPermission;

  /// No description provided for @errSettingsOpen.
  ///
  /// In ko, this message translates to:
  /// **'설정을 열지 못했어요. 기기 설정에서 위치를 허용해 주세요.'**
  String get errSettingsOpen;

  /// No description provided for @errCheckInput.
  ///
  /// In ko, this message translates to:
  /// **'입력 내용을 확인해 주세요.'**
  String get errCheckInput;

  /// No description provided for @errLocationServicesOff.
  ///
  /// In ko, this message translates to:
  /// **'기기의 위치 서비스를 켜 주세요.'**
  String get errLocationServicesOff;

  /// No description provided for @errLocationDenied.
  ///
  /// In ko, this message translates to:
  /// **'위치 권한 없이도 지도를 직접 이동하거나 검색할 수 있어요.'**
  String get errLocationDenied;

  /// No description provided for @errOutsideKorea.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치가 한국 밖이에요. 한국의 장소를 검색해 주세요.'**
  String get errOutsideKorea;

  /// No description provided for @errPhotoTooLarge.
  ///
  /// In ko, this message translates to:
  /// **'사진은 한 장당 10MB 이하로 선택해 주세요.'**
  String get errPhotoTooLarge;

  /// No description provided for @errPhotoFormat.
  ///
  /// In ko, this message translates to:
  /// **'지원되는 사진 형식을 선택해 주세요.'**
  String get errPhotoFormat;

  /// No description provided for @errPhotoLoad.
  ///
  /// In ko, this message translates to:
  /// **'사진을 불러오지 못했어요.'**
  String get errPhotoLoad;

  /// No description provided for @errPlaceSearchSignIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 식당을 검색해 주세요.'**
  String get errPlaceSearchSignIn;

  /// No description provided for @errPostPublish.
  ///
  /// In ko, this message translates to:
  /// **'게시물을 등록하지 못했어요.'**
  String get errPostPublish;

  /// No description provided for @errConnectionRetry.
  ///
  /// In ko, this message translates to:
  /// **'연결을 확인하고 다시 시도해 주세요.'**
  String get errConnectionRetry;

  /// No description provided for @inviteFollow.
  ///
  /// In ko, this message translates to:
  /// **'Pind에서 {who} 님을 팔로우하고 음식 취향을 나눠요!\n{link}'**
  String inviteFollow(String who, String link);

  /// No description provided for @agoWeeks.
  ///
  /// In ko, this message translates to:
  /// **'{n}주 전'**
  String agoWeeks(int n);

  /// No description provided for @agoDays.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String agoDays(int n);

  /// No description provided for @yesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get yesterday;

  /// No description provided for @agoHours.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간 전'**
  String agoHours(int n);

  /// No description provided for @agoMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String agoMinutes(int n);

  /// No description provided for @justNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get justNow;

  /// No description provided for @notifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notifications;

  /// No description provided for @unreadCount.
  ///
  /// In ko, this message translates to:
  /// **'안 읽음 {count}'**
  String unreadCount(int count);

  /// No description provided for @markAllRead.
  ///
  /// In ko, this message translates to:
  /// **'모두 읽음'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In ko, this message translates to:
  /// **'아직 알림이 없어요.'**
  String get noNotifications;

  /// No description provided for @notifLikeRest.
  ///
  /// In ko, this message translates to:
  /// **'님이 회원님의 게시물을 좋아해요'**
  String get notifLikeRest;

  /// No description provided for @notifVisitMid.
  ///
  /// In ko, this message translates to:
  /// **'님이 '**
  String get notifVisitMid;

  /// No description provided for @restaurant.
  ///
  /// In ko, this message translates to:
  /// **'식당'**
  String get restaurant;

  /// No description provided for @notifVisitEnd.
  ///
  /// In ko, this message translates to:
  /// **'에 다녀갔어요'**
  String get notifVisitEnd;

  /// No description provided for @notifFollowRest.
  ///
  /// In ko, this message translates to:
  /// **'님이 회원님을 친구로 추가했어요'**
  String get notifFollowRest;

  /// No description provided for @following.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉'**
  String get following;

  /// No description provided for @followBack.
  ///
  /// In ko, this message translates to:
  /// **'맞팔로우'**
  String get followBack;

  /// No description provided for @follow.
  ///
  /// In ko, this message translates to:
  /// **'팔로우'**
  String get follow;

  /// No description provided for @unfollowLabel.
  ///
  /// In ko, this message translates to:
  /// **'{label}, 팔로우 취소'**
  String unfollowLabel(String label);

  /// No description provided for @unfollowTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님을 팔로우 취소할까요?'**
  String unfollowTitle(String name);

  /// No description provided for @unfollowBody.
  ///
  /// In ko, this message translates to:
  /// **'취소해도 언제든 다시 팔로우할 수 있어요.'**
  String get unfollowBody;

  /// No description provided for @unfollow.
  ///
  /// In ko, this message translates to:
  /// **'팔로우 취소'**
  String get unfollow;

  /// No description provided for @tasteMatchPercent.
  ///
  /// In ko, this message translates to:
  /// **'취향 {percent}% 일치'**
  String tasteMatchPercent(int percent);

  /// No description provided for @unfollowName.
  ///
  /// In ko, this message translates to:
  /// **'{name} 팔로우 취소'**
  String unfollowName(String name);

  /// No description provided for @followName.
  ///
  /// In ko, this message translates to:
  /// **'{name} 팔로우'**
  String followName(String name);

  /// No description provided for @errListLoad.
  ///
  /// In ko, this message translates to:
  /// **'목록을 불러오지 못했어요.'**
  String get errListLoad;

  /// No description provided for @tryAgainPlease.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도해 주세요.'**
  String get tryAgainPlease;

  /// No description provided for @peopleCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String peopleCount(int count);

  /// No description provided for @followers.
  ///
  /// In ko, this message translates to:
  /// **'팔로워'**
  String get followers;

  /// No description provided for @noFollowers.
  ///
  /// In ko, this message translates to:
  /// **'아직 팔로워가 없어요.'**
  String get noFollowers;

  /// No description provided for @noFollowing.
  ///
  /// In ko, this message translates to:
  /// **'아직 팔로우한 사람이 없어요.'**
  String get noFollowing;

  /// No description provided for @signOutTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃할까요?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In ko, this message translates to:
  /// **'다시 로그인하면 게시물과 저장한 장소를 그대로 볼 수 있어요.'**
  String get signOutBody;

  /// No description provided for @signOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get signOut;

  /// No description provided for @errSignOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃하지 못했어요. 다시 시도해 주세요.'**
  String get errSignOut;

  /// No description provided for @profileSettings.
  ///
  /// In ko, this message translates to:
  /// **'프로필 설정'**
  String get profileSettings;

  /// No description provided for @changePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 변경'**
  String get changePhoto;

  /// No description provided for @noHandle.
  ///
  /// In ko, this message translates to:
  /// **'아이디 없음'**
  String get noHandle;

  /// No description provided for @handleLocked.
  ///
  /// In ko, this message translates to:
  /// **'아이디는 변경할 수 없어요'**
  String get handleLocked;

  /// No description provided for @name.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get name;

  /// No description provided for @statusMessage.
  ///
  /// In ko, this message translates to:
  /// **'상태 메시지'**
  String get statusMessage;

  /// No description provided for @statusHint.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 상태를 남겨 보세요'**
  String get statusHint;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @addFriend.
  ///
  /// In ko, this message translates to:
  /// **'친구 추가'**
  String get addFriend;

  /// No description provided for @newNotifications.
  ///
  /// In ko, this message translates to:
  /// **'새 알림'**
  String get newNotifications;

  /// No description provided for @exploreFriendsTaste.
  ///
  /// In ko, this message translates to:
  /// **'친구들 취향 탐색하기'**
  String get exploreFriendsTaste;

  /// No description provided for @inviteFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구 초대하기'**
  String get inviteFriends;

  /// No description provided for @shareFriendsTaste.
  ///
  /// In ko, this message translates to:
  /// **'친구들의 음식 취향을 공유하세요'**
  String get shareFriendsTaste;

  /// No description provided for @invite.
  ///
  /// In ko, this message translates to:
  /// **'초대하기'**
  String get invite;

  /// No description provided for @noPostsYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 게시물이 없어요.'**
  String get noPostsYet;

  /// No description provided for @postDeleted.
  ///
  /// In ko, this message translates to:
  /// **'게시물을 삭제했어요.'**
  String get postDeleted;

  /// No description provided for @unlike.
  ///
  /// In ko, this message translates to:
  /// **'좋아요 취소'**
  String get unlike;

  /// No description provided for @like.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get like;

  /// No description provided for @searchResultsCount.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과 {count}명'**
  String searchResultsCount(int count);

  /// No description provided for @searchResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과'**
  String get searchResults;

  /// No description provided for @noSearchResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요.'**
  String get noSearchResults;

  /// No description provided for @cantFindSomeone.
  ///
  /// In ko, this message translates to:
  /// **'찾는 사람이 없나요?'**
  String get cantFindSomeone;

  /// No description provided for @inviteByLink.
  ///
  /// In ko, this message translates to:
  /// **'링크로 초대하기'**
  String get inviteByLink;

  /// No description provided for @shareMyCodeAction.
  ///
  /// In ko, this message translates to:
  /// **'내 코드 공유하기'**
  String get shareMyCodeAction;

  /// No description provided for @inviteByLinkHint.
  ///
  /// In ko, this message translates to:
  /// **'링크로 친구를 초대해요'**
  String get inviteByLinkHint;

  /// No description provided for @similarTaste.
  ///
  /// In ko, this message translates to:
  /// **'취향이 비슷한 사람'**
  String get similarTaste;

  /// No description provided for @noSimilarTaste.
  ///
  /// In ko, this message translates to:
  /// **'아직 취향이 비슷한 사람이 없어요.'**
  String get noSimilarTaste;

  /// No description provided for @searchIdOrName.
  ///
  /// In ko, this message translates to:
  /// **'아이디 또는 이름 검색'**
  String get searchIdOrName;

  /// No description provided for @seeMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기 ›'**
  String get seeMore;

  /// No description provided for @agentStepRead.
  ///
  /// In ko, this message translates to:
  /// **'입력한 문장을 분석하고 있어요'**
  String get agentStepRead;

  /// No description provided for @agentStepPlaces.
  ///
  /// In ko, this message translates to:
  /// **'게시물이 작성된 장소를 살펴보고 있어요'**
  String get agentStepPlaces;

  /// No description provided for @agentStepTaste.
  ///
  /// In ko, this message translates to:
  /// **'당신의 취향에 맞는 장소를 검색하고 있어요'**
  String get agentStepTaste;

  /// No description provided for @errSearchRetry.
  ///
  /// In ko, this message translates to:
  /// **'검색하지 못했어요. 잠시 후 다시 시도해 주세요.'**
  String get errSearchRetry;

  /// No description provided for @errSaveToggle.
  ///
  /// In ko, this message translates to:
  /// **'저장 상태를 바꾸지 못했어요. 다시 시도해 주세요.'**
  String get errSaveToggle;

  /// No description provided for @agentTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인 맞춤형 음식 검색'**
  String get agentTitle;

  /// No description provided for @agentSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'원하는 취향을 자세히 알려주면 추천 내용이 더 정확해집니다.'**
  String get agentSubtitle;

  /// No description provided for @recommendedCount.
  ///
  /// In ko, this message translates to:
  /// **'추천 장소 {count}곳'**
  String recommendedCount(int count);

  /// No description provided for @agentNoResults.
  ///
  /// In ko, this message translates to:
  /// **'게시물이 있는 장소 중에 맞는 곳을 찾지 못했어요. 다르게 말해 볼까요?'**
  String get agentNoResults;

  /// No description provided for @askAnything.
  ///
  /// In ko, this message translates to:
  /// **'무엇이든 물어보세요...'**
  String get askAnything;

  /// No description provided for @voiceSearch.
  ///
  /// In ko, this message translates to:
  /// **'음성 검색'**
  String get voiceSearch;

  /// No description provided for @search.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get search;

  /// No description provided for @voiceComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'음성 검색은 준비 중이에요.'**
  String get voiceComingSoon;

  /// No description provided for @rankingFromMapCenter.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치를 확인하지 못해 지도 중심 10km 기준이에요.'**
  String get rankingFromMapCenter;

  /// No description provided for @rankingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'10km 안에 게시물이 있는 곳이 아직 없어요.'**
  String get rankingEmpty;

  /// No description provided for @sortByTaste.
  ///
  /// In ko, this message translates to:
  /// **'내 취향순'**
  String get sortByTaste;

  /// No description provided for @reviewsCount.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 {count}'**
  String reviewsCount(int count);

  /// No description provided for @unsave.
  ///
  /// In ko, this message translates to:
  /// **'저장 취소'**
  String get unsave;

  /// No description provided for @taste.
  ///
  /// In ko, this message translates to:
  /// **'취향'**
  String get taste;

  /// No description provided for @ratingScoreText.
  ///
  /// In ko, this message translates to:
  /// **'{criterion} {score}점'**
  String ratingScoreText(String criterion, String score);

  /// No description provided for @backToMap.
  ///
  /// In ko, this message translates to:
  /// **'지도로 돌아가기'**
  String get backToMap;

  /// No description provided for @checkLocationInSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 위치 권한 확인'**
  String get checkLocationInSettings;

  /// No description provided for @allowLocationStart.
  ///
  /// In ko, this message translates to:
  /// **'위치 허용하고 시작하기'**
  String get allowLocationStart;

  /// No description provided for @later.
  ///
  /// In ko, this message translates to:
  /// **'나중에 할게요'**
  String get later;

  /// No description provided for @locationTitle.
  ///
  /// In ko, this message translates to:
  /// **'지금 있는 곳 주변부터\n보여드릴게요'**
  String get locationTitle;

  /// No description provided for @locationBody.
  ///
  /// In ko, this message translates to:
  /// **'위치를 허용하면 내 주변 맛집과 취향을 탐색할 수 있어요.'**
  String get locationBody;

  /// No description provided for @nearbyFood.
  ///
  /// In ko, this message translates to:
  /// **'내 주변 맛집'**
  String get nearbyFood;

  /// No description provided for @nearbyFoodHint.
  ///
  /// In ko, this message translates to:
  /// **'반경 안에서만 추천해요'**
  String get nearbyFoodHint;

  /// No description provided for @friendsFood.
  ///
  /// In ko, this message translates to:
  /// **'친구들 맛집'**
  String get friendsFood;

  /// No description provided for @friendsFoodHint.
  ///
  /// In ko, this message translates to:
  /// **'친구들이 간 맛집을 볼 수 있어요'**
  String get friendsFoodHint;

  /// No description provided for @localRanking.
  ///
  /// In ko, this message translates to:
  /// **'동네 랭킹'**
  String get localRanking;

  /// No description provided for @localRankingHint.
  ///
  /// In ko, this message translates to:
  /// **'#1 in 성수동 같은 지역 순위'**
  String get localRankingHint;

  /// No description provided for @recentlyViewed.
  ///
  /// In ko, this message translates to:
  /// **'최근에 본 장소'**
  String get recentlyViewed;

  /// No description provided for @recentlyViewedEmpty.
  ///
  /// In ko, this message translates to:
  /// **'최근 24시간 안에 본 장소가 여기에 표시돼요.'**
  String get recentlyViewedEmpty;

  /// No description provided for @savedPlaces.
  ///
  /// In ko, this message translates to:
  /// **'저장한 장소'**
  String get savedPlaces;

  /// No description provided for @noSavedPlaces.
  ///
  /// In ko, this message translates to:
  /// **'저장한 장소가 아직 없어요.'**
  String get noSavedPlaces;

  /// No description provided for @noSharedSaves.
  ///
  /// In ko, this message translates to:
  /// **'공유한 저장 장소가 없어요.'**
  String get noSharedSaves;

  /// No description provided for @noPlacesToShow.
  ///
  /// In ko, this message translates to:
  /// **'표시할 장소가 없어요.'**
  String get noPlacesToShow;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @posts.
  ///
  /// In ko, this message translates to:
  /// **'게시물'**
  String get posts;

  /// No description provided for @myMap.
  ///
  /// In ko, this message translates to:
  /// **'내 지도'**
  String get myMap;

  /// No description provided for @badgeFoodie.
  ///
  /// In ko, this message translates to:
  /// **'맛잘알'**
  String get badgeFoodie;

  /// No description provided for @badgePoster.
  ///
  /// In ko, this message translates to:
  /// **'게시물왕'**
  String get badgePoster;

  /// No description provided for @badgeJudge.
  ///
  /// In ko, this message translates to:
  /// **'맛집 판별가'**
  String get badgeJudge;

  /// No description provided for @badges.
  ///
  /// In ko, this message translates to:
  /// **'뱃지'**
  String get badges;

  /// No description provided for @myMapTitle.
  ///
  /// In ko, this message translates to:
  /// **'나의 지도'**
  String get myMapTitle;

  /// No description provided for @noPostsWritten.
  ///
  /// In ko, this message translates to:
  /// **'작성한 게시물이 아직 없어요'**
  String get noPostsWritten;

  /// No description provided for @mapUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'지도를 사용할 수 없어요'**
  String get mapUnavailable;

  /// No description provided for @viewMap.
  ///
  /// In ko, this message translates to:
  /// **'맵 보기 ›'**
  String get viewMap;

  /// No description provided for @myTaste.
  ///
  /// In ko, this message translates to:
  /// **'나의 취향'**
  String get myTaste;

  /// No description provided for @tasteType.
  ///
  /// In ko, this message translates to:
  /// **'{criterion} 중시형'**
  String tasteType(String criterion);

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'✎ 수정'**
  String get edit;

  /// No description provided for @tasteEmpty.
  ///
  /// In ko, this message translates to:
  /// **'취향을 설정하면 여기에 표시돼요.'**
  String get tasteEmpty;

  /// No description provided for @noPublicTaste.
  ///
  /// In ko, this message translates to:
  /// **'공개한 취향이 없어요.'**
  String get noPublicTaste;

  /// No description provided for @tasteOrder.
  ///
  /// In ko, this message translates to:
  /// **'{first} 먼저, 그다음 {second}·{third}을 봐요.'**
  String tasteOrder(String first, String second, String third);

  /// No description provided for @agoYears.
  ///
  /// In ko, this message translates to:
  /// **'{n}년 전'**
  String agoYears(int n);

  /// No description provided for @agoMonths.
  ///
  /// In ko, this message translates to:
  /// **'{n}개월 전'**
  String agoMonths(int n);

  /// No description provided for @savedAgo.
  ///
  /// In ko, this message translates to:
  /// **'{ago} 저장'**
  String savedAgo(String ago);

  /// No description provided for @sortRecentSaved.
  ///
  /// In ko, this message translates to:
  /// **'최근 저장순'**
  String get sortRecentSaved;

  /// No description provided for @placesCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}곳'**
  String placesCount(int count);

  /// No description provided for @onboardingTitlePriorities.
  ///
  /// In ko, this message translates to:
  /// **'가게 고를 때\n뭘 제일 봐요?'**
  String get onboardingTitlePriorities;

  /// No description provided for @onboardingTitleOccasions.
  ///
  /// In ko, this message translates to:
  /// **'외식 선호도를 선택해주세요.'**
  String get onboardingTitleOccasions;

  /// No description provided for @onboardingTitleCuisines.
  ///
  /// In ko, this message translates to:
  /// **'좋아하는걸 선택해주세요.'**
  String get onboardingTitleCuisines;

  /// No description provided for @onboardingHintPriorities.
  ///
  /// In ko, this message translates to:
  /// **'딱 3개만. 순서대로 50% · 30% · 20%를 반영해요.'**
  String get onboardingHintPriorities;

  /// No description provided for @onboardingHintOccasions.
  ///
  /// In ko, this message translates to:
  /// **'최대 3개. 상황에 맞는 리스트를 만들어 드려요.'**
  String get onboardingHintOccasions;

  /// No description provided for @onboardingHintCuisines.
  ///
  /// In ko, this message translates to:
  /// **'3개 이상 골라주세요. 고를수록 추천이 정확해집니다.'**
  String get onboardingHintCuisines;

  /// No description provided for @onboardingPickThree.
  ///
  /// In ko, this message translates to:
  /// **'중요한 기준 3개를 골라주세요.'**
  String get onboardingPickThree;

  /// No description provided for @prioritiesOrder.
  ///
  /// In ko, this message translates to:
  /// **'{order} 순으로 반영됩니다'**
  String prioritiesOrder(String order);

  /// No description provided for @selectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택됨'**
  String selectedCount(int count);

  /// No description provided for @previous.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get previous;

  /// No description provided for @onboardingStep.
  ///
  /// In ko, this message translates to:
  /// **'취향 설정 {step} / 3 단계'**
  String onboardingStep(int step);

  /// No description provided for @saving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중…'**
  String get saving;

  /// No description provided for @buildTasteMap.
  ///
  /// In ko, this message translates to:
  /// **'내 취향 지도 만들기'**
  String get buildTasteMap;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @rankLabel.
  ///
  /// In ko, this message translates to:
  /// **'{rank}순위'**
  String rankLabel(int rank);

  /// No description provided for @filterNearby.
  ///
  /// In ko, this message translates to:
  /// **'📍 현재 위치 주변'**
  String get filterNearby;

  /// No description provided for @filterRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 방문'**
  String get filterRecent;

  /// No description provided for @filterSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장한 곳'**
  String get filterSaved;

  /// No description provided for @categoryAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get categoryAll;

  /// No description provided for @categoryCafe.
  ///
  /// In ko, this message translates to:
  /// **'카페'**
  String get categoryCafe;

  /// No description provided for @categoryBar.
  ///
  /// In ko, this message translates to:
  /// **'술집'**
  String get categoryBar;

  /// No description provided for @categoryMeat.
  ///
  /// In ko, this message translates to:
  /// **'고기'**
  String get categoryMeat;

  /// No description provided for @categoryNoodles.
  ///
  /// In ko, this message translates to:
  /// **'면'**
  String get categoryNoodles;

  /// No description provided for @categoryDessert.
  ///
  /// In ko, this message translates to:
  /// **'디저트'**
  String get categoryDessert;

  /// No description provided for @errRestaurantSearch.
  ///
  /// In ko, this message translates to:
  /// **'식당을 검색하지 못했어요.'**
  String get errRestaurantSearch;

  /// No description provided for @errLocationCheckPermission.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치를 확인할 수 없어요. 위치 권한을 확인해 주세요.'**
  String get errLocationCheckPermission;

  /// No description provided for @notInRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 방문한 곳 중에 없어요.'**
  String get notInRecent;

  /// No description provided for @noRecentViews.
  ///
  /// In ko, this message translates to:
  /// **'최근 24시간 안에 본 장소가 없어요.'**
  String get noRecentViews;

  /// No description provided for @notInSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장한 곳 중에 없어요.'**
  String get notInSaved;

  /// No description provided for @findingRestaurants.
  ///
  /// In ko, this message translates to:
  /// **'식당을 찾고 있어요.'**
  String get findingRestaurants;

  /// No description provided for @noNearbyMatch.
  ///
  /// In ko, this message translates to:
  /// **'주변 {distance} 안에 맞는 식당이 없어요.'**
  String noNearbyMatch(String distance);

  /// No description provided for @searchByNameOrAddress.
  ///
  /// In ko, this message translates to:
  /// **'식당 이름이나 주소로 검색해 주세요.'**
  String get searchByNameOrAddress;

  /// No description provided for @whereDidYouGo.
  ///
  /// In ko, this message translates to:
  /// **'어디에 다녀오셨어요?'**
  String get whereDidYouGo;

  /// No description provided for @nameOrAddress.
  ///
  /// In ko, this message translates to:
  /// **'식당 이름 또는 주소'**
  String get nameOrAddress;

  /// No description provided for @selectPlace.
  ///
  /// In ko, this message translates to:
  /// **'{name} 선택'**
  String selectPlace(String name);

  /// No description provided for @select.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get select;

  /// No description provided for @errProfileOpen.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 열지 못했어요.'**
  String get errProfileOpen;

  /// No description provided for @postPublished.
  ///
  /// In ko, this message translates to:
  /// **'게시물을 등록했어요.'**
  String get postPublished;

  /// No description provided for @postPhotoOf.
  ///
  /// In ko, this message translates to:
  /// **'게시물 사진 {number}/{total}'**
  String postPhotoOf(int number, int total);

  /// No description provided for @noPostsYetMine.
  ///
  /// In ko, this message translates to:
  /// **'아직 작성한 게시물이 없어요.'**
  String get noPostsYetMine;

  /// No description provided for @share.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get share;

  /// No description provided for @errTasteSave.
  ///
  /// In ko, this message translates to:
  /// **'취향을 저장하지 못했어요. 다시 시도해 주세요.'**
  String get errTasteSave;

  /// No description provided for @countrySelected.
  ///
  /// In ko, this message translates to:
  /// **'{country} 선택됨'**
  String countrySelected(String country);

  /// No description provided for @countryTitle.
  ///
  /// In ko, this message translates to:
  /// **'국가를 선택해\n주세요'**
  String get countryTitle;

  /// No description provided for @countryBody.
  ///
  /// In ko, this message translates to:
  /// **'서비스 지역과 언어, 통화 표기가 함께 설정돼요.'**
  String get countryBody;

  /// No description provided for @countrySearch.
  ///
  /// In ko, this message translates to:
  /// **'국가 검색'**
  String get countrySearch;

  /// No description provided for @countryPopular.
  ///
  /// In ko, this message translates to:
  /// **'자주 선택하는 국가'**
  String get countryPopular;

  /// No description provided for @countryKoreaOnly.
  ///
  /// In ko, this message translates to:
  /// **'현재 맛집 탐색은 대한민국에서 제공해요.'**
  String get countryKoreaOnly;

  /// No description provided for @basicTitle.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보를\n알려주세요'**
  String get basicTitle;

  /// No description provided for @basicBody.
  ///
  /// In ko, this message translates to:
  /// **'또래가 좋아하는 맛집을 추천하는 데만 쓰여요.\n프로필에는 공개되지 않습니다.'**
  String get basicBody;

  /// No description provided for @enterName.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요'**
  String get enterName;

  /// No description provided for @gender.
  ///
  /// In ko, this message translates to:
  /// **'성별'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In ko, this message translates to:
  /// **'남성'**
  String get male;

  /// No description provided for @female.
  ///
  /// In ko, this message translates to:
  /// **'여성'**
  String get female;

  /// No description provided for @preferNotToSay.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get preferNotToSay;

  /// No description provided for @birthDate.
  ///
  /// In ko, this message translates to:
  /// **'생년월일'**
  String get birthDate;

  /// No description provided for @ageBand.
  ///
  /// In ko, this message translates to:
  /// **'{age}세 · {decade}대 {part, select, early{초반} mid{중반} other{후반}}'**
  String ageBand(int age, int decade, String part);

  /// No description provided for @ageUsedFor.
  ///
  /// In ko, this message translates to:
  /// **'또래 취향 추천에 사용돼요'**
  String get ageUsedFor;

  /// No description provided for @ageMinimum.
  ///
  /// In ko, this message translates to:
  /// **'만 14세 이상부터 이용할 수 있어요.'**
  String get ageMinimum;

  /// No description provided for @consentPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 수집·이용 동의 (필수)'**
  String get consentPrivacy;

  /// No description provided for @consentPrivacyBody.
  ///
  /// In ko, this message translates to:
  /// **'이름, 성별, 생년월일은 기본 정보와 취향 추천에 사용하며 공개 프로필에 표시하지 않습니다.'**
  String get consentPrivacyBody;

  /// No description provided for @consentAge.
  ///
  /// In ko, this message translates to:
  /// **'만 14세 이상입니다 (필수)'**
  String get consentAge;

  /// No description provided for @consentAgeBody.
  ///
  /// In ko, this message translates to:
  /// **'생년월일을 확인하고 만 14세 이상인 경우 선택해 주세요.'**
  String get consentAgeBody;

  /// No description provided for @consentPersonalize.
  ///
  /// In ko, this message translates to:
  /// **'맞춤 추천을 위한 정보 활용 (선택)'**
  String get consentPersonalize;

  /// No description provided for @consentPersonalizeBody.
  ///
  /// In ko, this message translates to:
  /// **'선택하지 않아도 기본 서비스와 장소 검색을 이용할 수 있습니다.'**
  String get consentPersonalizeBody;

  /// No description provided for @year.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get year;

  /// No description provided for @month.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get month;

  /// No description provided for @day.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get day;

  /// No description provided for @viewDetails.
  ///
  /// In ko, this message translates to:
  /// **'{title} 내용 보기'**
  String viewDetails(String title);

  /// No description provided for @startPind.
  ///
  /// In ko, this message translates to:
  /// **'Pind 시작하기'**
  String get startPind;

  /// No description provided for @handleTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떻게\n불러드릴까요?'**
  String get handleTitle;

  /// No description provided for @handleBody.
  ///
  /// In ko, this message translates to:
  /// **'아이디는 나중에 바꿀 수 없어요. 닉네임은 언제든 변경 가능합니다.'**
  String get handleBody;

  /// No description provided for @chooseAvatar.
  ///
  /// In ko, this message translates to:
  /// **'아바타 선택'**
  String get chooseAvatar;

  /// No description provided for @handle.
  ///
  /// In ko, this message translates to:
  /// **'아이디'**
  String get handle;

  /// No description provided for @enterHandle.
  ///
  /// In ko, this message translates to:
  /// **'아이디를 입력해주세요'**
  String get enterHandle;

  /// No description provided for @handleValid.
  ///
  /// In ko, this message translates to:
  /// **'✓ 사용할 수 있는 형식이에요'**
  String get handleValid;

  /// No description provided for @handleRule.
  ///
  /// In ko, this message translates to:
  /// **'영문, 숫자, 밑줄로 3~20자를 입력해주세요.'**
  String get handleRule;

  /// No description provided for @chooseEmoji.
  ///
  /// In ko, this message translates to:
  /// **'나를 표현하는 이모지를 골라주세요'**
  String get chooseEmoji;

  /// No description provided for @pickFromAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 사진 선택'**
  String get pickFromAlbum;

  /// No description provided for @errDetailLoad.
  ///
  /// In ko, this message translates to:
  /// **'상세 정보를 불러오지 못했어요.'**
  String get errDetailLoad;

  /// No description provided for @errContextLoad.
  ///
  /// In ko, this message translates to:
  /// **'취향·팔로잉 정보를 불러오지 못했어요.'**
  String get errContextLoad;

  /// No description provided for @detailSwipeHint.
  ///
  /// In ko, this message translates to:
  /// **'⌃  위로 올려서 소개 · 게시물 보기'**
  String get detailSwipeHint;

  /// No description provided for @hoursUnknown.
  ///
  /// In ko, this message translates to:
  /// **'운영시간 확인 필요'**
  String get hoursUnknown;

  /// No description provided for @openNow.
  ///
  /// In ko, this message translates to:
  /// **'영업 중'**
  String get openNow;

  /// No description provided for @closedNow.
  ///
  /// In ko, this message translates to:
  /// **'영업 종료'**
  String get closedNow;

  /// No description provided for @locating.
  ///
  /// In ko, this message translates to:
  /// **'위치 확인 중'**
  String get locating;

  /// No description provided for @checkDistance.
  ///
  /// In ko, this message translates to:
  /// **'거리 확인'**
  String get checkDistance;

  /// No description provided for @pindPostCount.
  ///
  /// In ko, this message translates to:
  /// **'Pind 게시물 {count}개'**
  String pindPostCount(int count);

  /// No description provided for @reviewCountUnknown.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 수 확인 필요'**
  String get reviewCountUnknown;

  /// No description provided for @reviewCountLong.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 {count}개'**
  String reviewCountLong(int count);

  /// No description provided for @tasteMatchHelp.
  ///
  /// In ko, this message translates to:
  /// **'전체 공개 평균을 1·2·3순위 50·30·20%로 반영해요. 1점은 해당 기준의 0%, 5점은 100%를 받아요.'**
  String get tasteMatchHelp;

  /// No description provided for @tasteMatchUnrated.
  ///
  /// In ko, this message translates to:
  /// **'내 취향 평가 부족'**
  String get tasteMatchUnrated;

  /// No description provided for @tasteMatchMine.
  ///
  /// In ko, this message translates to:
  /// **'내 취향 {percent}%'**
  String tasteMatchMine(int percent);

  /// No description provided for @axisNoRatingsDot.
  ///
  /// In ko, this message translates to:
  /// **'{criterion} · 아직 평가가 없어요'**
  String axisNoRatingsDot(String criterion);

  /// No description provided for @axisAverageDot.
  ///
  /// In ko, this message translates to:
  /// **'{criterion} · 가게 평균 {score} / 5'**
  String axisAverageDot(String criterion, String score);

  /// No description provided for @axisNoRatings.
  ///
  /// In ko, this message translates to:
  /// **'{criterion} 아직 평가가 없어요'**
  String axisNoRatings(String criterion);

  /// No description provided for @axisAverage.
  ///
  /// In ko, this message translates to:
  /// **'{criterion} 가게 평균 {score}점'**
  String axisAverage(String criterion, String score);

  /// No description provided for @friendsVisitedPlace.
  ///
  /// In ko, this message translates to:
  /// **'{others, plural, =0{{names}님이 다녀갔어요} other{{names} 외 {others}명님이 다녀갔어요}}'**
  String friendsVisitedPlace(String names, int others);

  /// No description provided for @followingSaved.
  ///
  /// In ko, this message translates to:
  /// **'팔로잉 {count}명 저장'**
  String followingSaved(int count);

  /// No description provided for @placePhotoLabel.
  ///
  /// In ko, this message translates to:
  /// **'{place} 장소 사진 {number}'**
  String placePhotoLabel(String place, int number);

  /// No description provided for @photoBy.
  ///
  /// In ko, this message translates to:
  /// **'사진: {name}'**
  String photoBy(String name);

  /// No description provided for @photoSource.
  ///
  /// In ko, this message translates to:
  /// **'사진 출처'**
  String get photoSource;

  /// No description provided for @intro.
  ///
  /// In ko, this message translates to:
  /// **'소개'**
  String get intro;

  /// No description provided for @oneLineSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'{axes} 한 줄 요약'**
  String oneLineSummaryTitle(String axes);

  /// No description provided for @noOneLiners.
  ///
  /// In ko, this message translates to:
  /// **'아직 한 줄 평이 없어요.'**
  String get noOneLiners;

  /// No description provided for @noIntro.
  ///
  /// In ko, this message translates to:
  /// **'제공된 소개가 없어요.'**
  String get noIntro;

  /// No description provided for @dataBy.
  ///
  /// In ko, this message translates to:
  /// **'정보 제공: {source}'**
  String dataBy(String source);

  /// No description provided for @saved.
  ///
  /// In ko, this message translates to:
  /// **'저장됨'**
  String get saved;

  /// No description provided for @directions.
  ///
  /// In ko, this message translates to:
  /// **'길찾기'**
  String get directions;

  /// No description provided for @errWalkRoute.
  ///
  /// In ko, this message translates to:
  /// **'도보 경로를 찾지 못했어요. 잠시 후 다시 시도해 주세요.'**
  String get errWalkRoute;

  /// No description provided for @errLocationUseSearch.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치를 확인하지 못했어요. 검색으로 계속할 수 있어요.'**
  String get errLocationUseSearch;

  /// No description provided for @walkFinding.
  ///
  /// In ko, this message translates to:
  /// **'도보 경로를 찾고 있어요…'**
  String get walkFinding;

  /// No description provided for @walkArrived.
  ///
  /// In ko, this message translates to:
  /// **'도착했어요'**
  String get walkArrived;

  /// No description provided for @walkRerouting.
  ///
  /// In ko, this message translates to:
  /// **'경로를 다시 찾고 있어요…'**
  String get walkRerouting;

  /// No description provided for @walkRemaining.
  ///
  /// In ko, this message translates to:
  /// **'{distance} · 약 {minutes}분'**
  String walkRemaining(String distance, int minutes);

  /// No description provided for @walkTo.
  ///
  /// In ko, this message translates to:
  /// **'{place}까지 도보'**
  String walkTo(String place);

  /// No description provided for @walkEnd.
  ///
  /// In ko, this message translates to:
  /// **'안내 종료'**
  String get walkEnd;

  /// No description provided for @openSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색 열기'**
  String get openSearch;

  /// No description provided for @mapSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 먹고 싶나요?'**
  String get mapSearchHint;

  /// No description provided for @editTaste.
  ///
  /// In ko, this message translates to:
  /// **'취향 수정'**
  String get editTaste;

  /// No description provided for @mapLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'지도를 불러올 수 없어요.'**
  String get mapLoadFailed;

  /// No description provided for @mapFallbackHint.
  ///
  /// In ko, this message translates to:
  /// **'장소 검색과 목록으로 탐색할 수 있어요.'**
  String get mapFallbackHint;

  /// No description provided for @needsBackend.
  ///
  /// In ko, this message translates to:
  /// **'연결 설정 후 장소를 탐색할 수 있어요.'**
  String get needsBackend;

  /// No description provided for @zoomIn.
  ///
  /// In ko, this message translates to:
  /// **'확대'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In ko, this message translates to:
  /// **'축소'**
  String get zoomOut;

  /// No description provided for @myLocation.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치'**
  String get myLocation;

  /// No description provided for @newPost.
  ///
  /// In ko, this message translates to:
  /// **'게시물 작성'**
  String get newPost;

  /// No description provided for @addPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get addPhotos;

  /// No description provided for @visitedRestaurant.
  ///
  /// In ko, this message translates to:
  /// **'방문한 식당'**
  String get visitedRestaurant;

  /// No description provided for @ratings.
  ///
  /// In ko, this message translates to:
  /// **'평점'**
  String get ratings;

  /// No description provided for @ratingsRequired.
  ///
  /// In ko, this message translates to:
  /// **'맛 · 양 · 분위기 (필수)'**
  String get ratingsRequired;

  /// No description provided for @myAverageRating.
  ///
  /// In ko, this message translates to:
  /// **'내 평균 별점'**
  String get myAverageRating;

  /// No description provided for @writeReview.
  ///
  /// In ko, this message translates to:
  /// **'글 작성하기'**
  String get writeReview;

  /// No description provided for @optional.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get optional;

  /// No description provided for @visibility.
  ///
  /// In ko, this message translates to:
  /// **'공개 범위'**
  String get visibility;

  /// No description provided for @visibilityPublic.
  ///
  /// In ko, this message translates to:
  /// **'전체 공개'**
  String get visibilityPublic;

  /// No description provided for @visibilityFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구 공개'**
  String get visibilityFriends;

  /// No description provided for @visibilityPublicHint.
  ///
  /// In ko, this message translates to:
  /// **'모든 사람이 볼 수 있어요'**
  String get visibilityPublicHint;

  /// No description provided for @visibilityFriendsHint.
  ///
  /// In ko, this message translates to:
  /// **'나를 팔로우한 친구만 볼 수 있어요'**
  String get visibilityFriendsHint;

  /// No description provided for @reviewHint.
  ///
  /// In ko, this message translates to:
  /// **'이 음식을 고향 음식에 비유하면? 처음 먹어본 외국인으로서 솔직한 후기를 남겨주세요.'**
  String get reviewHint;

  /// No description provided for @errorPrefix.
  ///
  /// In ko, this message translates to:
  /// **'오류: {message}'**
  String errorPrefix(String message);

  /// No description provided for @publish.
  ///
  /// In ko, this message translates to:
  /// **'게시하기'**
  String get publish;

  /// No description provided for @photoLongPressDelete.
  ///
  /// In ko, this message translates to:
  /// **'사진 {number}, 길게 눌러 삭제'**
  String photoLongPressDelete(int number);

  /// No description provided for @pickVisitedRestaurant.
  ///
  /// In ko, this message translates to:
  /// **'방문한 식당을 선택해 주세요'**
  String get pickVisitedRestaurant;

  /// No description provided for @change.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get change;

  /// No description provided for @rateBest.
  ///
  /// In ko, this message translates to:
  /// **'최고예요'**
  String get rateBest;

  /// No description provided for @rateTasty.
  ///
  /// In ko, this message translates to:
  /// **'맛있어요'**
  String get rateTasty;

  /// No description provided for @rateOkay.
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요'**
  String get rateOkay;

  /// No description provided for @rateMeh.
  ///
  /// In ko, this message translates to:
  /// **'아쉬워요'**
  String get rateMeh;

  /// No description provided for @rateBad.
  ///
  /// In ko, this message translates to:
  /// **'별로예요'**
  String get rateBad;

  /// No description provided for @portionHuge.
  ///
  /// In ko, this message translates to:
  /// **'아주 많아요'**
  String get portionHuge;

  /// No description provided for @portionGenerous.
  ///
  /// In ko, this message translates to:
  /// **'넉넉해요'**
  String get portionGenerous;

  /// No description provided for @portionJustRight.
  ///
  /// In ko, this message translates to:
  /// **'적당해요'**
  String get portionJustRight;

  /// No description provided for @portionSmall.
  ///
  /// In ko, this message translates to:
  /// **'적어요'**
  String get portionSmall;

  /// No description provided for @portionTiny.
  ///
  /// In ko, this message translates to:
  /// **'아주 적어요'**
  String get portionTiny;

  /// No description provided for @rateGood.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get rateGood;

  /// No description provided for @suggestSpicyLevels.
  ///
  /// In ko, this message translates to:
  /// **'매움 단계를 선택할 수 있는 식당'**
  String get suggestSpicyLevels;

  /// No description provided for @suggestKoreanBbq.
  ///
  /// In ko, this message translates to:
  /// **'한국 BBQ를 즐기면서 분위기 좋은 고깃집'**
  String get suggestKoreanBbq;

  /// No description provided for @suggestNepali.
  ///
  /// In ko, this message translates to:
  /// **'네팔 사람들이 많이 방문한 식당'**
  String get suggestNepali;

  /// No description provided for @suggestVegetarian.
  ///
  /// In ko, this message translates to:
  /// **'Vegetarian 음식'**
  String get suggestVegetarian;

  /// No description provided for @suggestKoreanVietnamese.
  ///
  /// In ko, this message translates to:
  /// **'한국식 베트남 음식'**
  String get suggestKoreanVietnamese;

  /// No description provided for @suggestSoloDrinks.
  ///
  /// In ko, this message translates to:
  /// **'혼술 하기 좋은 식당'**
  String get suggestSoloDrinks;

  /// No description provided for @suggestPho.
  ///
  /// In ko, this message translates to:
  /// **'느낌 좋은 쌀국수집'**
  String get suggestPho;

  /// No description provided for @suggestSeongsuBar.
  ///
  /// In ko, this message translates to:
  /// **'서울 성수동에 분위기 좋은 바'**
  String get suggestSeongsuBar;

  /// No description provided for @suggestHomeStyle.
  ///
  /// In ko, this message translates to:
  /// **'한국 집밥 느낌의 식당'**
  String get suggestHomeStyle;

  /// No description provided for @suggestTouristFavorite.
  ///
  /// In ko, this message translates to:
  /// **'관광객들이 가장 많이 방문한 식당'**
  String get suggestTouristFavorite;

  /// No description provided for @placeKorean.
  ///
  /// In ko, this message translates to:
  /// **'백반집'**
  String get placeKorean;

  /// No description provided for @placeBarbecue.
  ///
  /// In ko, this message translates to:
  /// **'고깃집'**
  String get placeBarbecue;

  /// No description provided for @placeSoup.
  ///
  /// In ko, this message translates to:
  /// **'국밥집'**
  String get placeSoup;

  /// No description provided for @placeNoodles.
  ///
  /// In ko, this message translates to:
  /// **'국수집'**
  String get placeNoodles;

  /// No description provided for @placeStreet.
  ///
  /// In ko, this message translates to:
  /// **'분식집'**
  String get placeStreet;

  /// No description provided for @placeJapanese.
  ///
  /// In ko, this message translates to:
  /// **'일식집'**
  String get placeJapanese;

  /// No description provided for @placeSushi.
  ///
  /// In ko, this message translates to:
  /// **'초밥집'**
  String get placeSushi;

  /// No description provided for @placeChinese.
  ///
  /// In ko, this message translates to:
  /// **'중국집'**
  String get placeChinese;

  /// No description provided for @placeWestern.
  ///
  /// In ko, this message translates to:
  /// **'파스타집'**
  String get placeWestern;

  /// No description provided for @placeAsian.
  ///
  /// In ko, this message translates to:
  /// **'쌀국수집'**
  String get placeAsian;

  /// No description provided for @placeChicken.
  ///
  /// In ko, this message translates to:
  /// **'치킨집'**
  String get placeChicken;

  /// No description provided for @placeDessert.
  ///
  /// In ko, this message translates to:
  /// **'디저트 카페'**
  String get placeDessert;

  /// No description provided for @placeBakery.
  ///
  /// In ko, this message translates to:
  /// **'빵집'**
  String get placeBakery;

  /// No description provided for @placeBar.
  ///
  /// In ko, this message translates to:
  /// **'술집'**
  String get placeBar;

  /// No description provided for @qualityTaste.
  ///
  /// In ko, this message translates to:
  /// **'맛있는'**
  String get qualityTaste;

  /// No description provided for @qualityAmbience.
  ///
  /// In ko, this message translates to:
  /// **'분위기 좋은'**
  String get qualityAmbience;

  /// No description provided for @qualityValue.
  ///
  /// In ko, this message translates to:
  /// **'가성비 좋은'**
  String get qualityValue;

  /// No description provided for @qualityPortion.
  ///
  /// In ko, this message translates to:
  /// **'양 많은'**
  String get qualityPortion;

  /// No description provided for @qualityService.
  ///
  /// In ko, this message translates to:
  /// **'깔끔하고 친절한'**
  String get qualityService;

  /// No description provided for @qualityPhotogenic.
  ///
  /// In ko, this message translates to:
  /// **'사진 잘 나오는'**
  String get qualityPhotogenic;

  /// No description provided for @qualityQuiet.
  ///
  /// In ko, this message translates to:
  /// **'조용한'**
  String get qualityQuiet;

  /// No description provided for @qualityParking.
  ///
  /// In ko, this message translates to:
  /// **'주차 편한'**
  String get qualityParking;

  /// No description provided for @occasionPhraseSolo.
  ///
  /// In ko, this message translates to:
  /// **'혼밥하기 좋은'**
  String get occasionPhraseSolo;

  /// No description provided for @occasionPhraseFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구들이랑 가기 좋은'**
  String get occasionPhraseFriends;

  /// No description provided for @occasionPhraseDate.
  ///
  /// In ko, this message translates to:
  /// **'데이트하기 좋은'**
  String get occasionPhraseDate;

  /// No description provided for @occasionPhraseFamily.
  ///
  /// In ko, this message translates to:
  /// **'가족이랑 가기 좋은'**
  String get occasionPhraseFamily;

  /// No description provided for @occasionPhraseGroup.
  ///
  /// In ko, this message translates to:
  /// **'회식하기 좋은'**
  String get occasionPhraseGroup;

  /// No description provided for @occasionPhraseWork.
  ///
  /// In ko, this message translates to:
  /// **'카공하기 좋은'**
  String get occasionPhraseWork;

  /// No description provided for @occasionPhraseDrinks.
  ///
  /// In ko, this message translates to:
  /// **'한잔하기 좋은'**
  String get occasionPhraseDrinks;

  /// No description provided for @occasionPhraseQuick.
  ///
  /// In ko, this message translates to:
  /// **'빨리 먹을 수 있는'**
  String get occasionPhraseQuick;

  /// No description provided for @genericRestaurant.
  ///
  /// In ko, this message translates to:
  /// **'식당'**
  String get genericRestaurant;

  /// No description provided for @genericDining.
  ///
  /// In ko, this message translates to:
  /// **'레스토랑'**
  String get genericDining;

  /// No description provided for @genericCafe.
  ///
  /// In ko, this message translates to:
  /// **'카페'**
  String get genericCafe;

  /// No description provided for @genericBar.
  ///
  /// In ko, this message translates to:
  /// **'술집'**
  String get genericBar;

  /// No description provided for @suggestForMe.
  ///
  /// In ko, this message translates to:
  /// **'내가 좋아할만한 곳 추천해줘'**
  String get suggestForMe;

  /// No description provided for @suggestQuality.
  ///
  /// In ko, this message translates to:
  /// **'{quality} {place}'**
  String suggestQuality(String quality, String place);

  /// No description provided for @suggestOccasion.
  ///
  /// In ko, this message translates to:
  /// **'{phrase} {place}'**
  String suggestOccasion(String phrase, String place);

  /// No description provided for @cat00.
  ///
  /// In ko, this message translates to:
  /// **'백반/한정식'**
  String get cat00;

  /// No description provided for @cat01.
  ///
  /// In ko, this message translates to:
  /// **'카페'**
  String get cat01;

  /// No description provided for @cat02.
  ///
  /// In ko, this message translates to:
  /// **'요리 주점'**
  String get cat02;

  /// No description provided for @cat03.
  ///
  /// In ko, this message translates to:
  /// **'김밥/만두/분식'**
  String get cat03;

  /// No description provided for @cat04.
  ///
  /// In ko, this message translates to:
  /// **'돼지고기 구이/찜'**
  String get cat04;

  /// No description provided for @cat05.
  ///
  /// In ko, this message translates to:
  /// **'빵/도넛'**
  String get cat05;

  /// No description provided for @cat06.
  ///
  /// In ko, this message translates to:
  /// **'일식 회/초밥'**
  String get cat06;

  /// No description provided for @cat07.
  ///
  /// In ko, this message translates to:
  /// **'경양식'**
  String get cat07;

  /// No description provided for @cat08.
  ///
  /// In ko, this message translates to:
  /// **'치킨'**
  String get cat08;

  /// No description provided for @cat09.
  ///
  /// In ko, this message translates to:
  /// **'국/탕/찌개류'**
  String get cat09;

  /// No description provided for @cat10.
  ///
  /// In ko, this message translates to:
  /// **'중국집'**
  String get cat10;

  /// No description provided for @cat11.
  ///
  /// In ko, this message translates to:
  /// **'피자'**
  String get cat11;

  /// No description provided for @cat12.
  ///
  /// In ko, this message translates to:
  /// **'국수/칼국수'**
  String get cat12;

  /// No description provided for @cat13.
  ///
  /// In ko, this message translates to:
  /// **'생맥주 전문'**
  String get cat13;

  /// No description provided for @cat14.
  ///
  /// In ko, this message translates to:
  /// **'일반 유흥 주점'**
  String get cat14;

  /// No description provided for @cat15.
  ///
  /// In ko, this message translates to:
  /// **'횟집'**
  String get cat15;

  /// No description provided for @cat16.
  ///
  /// In ko, this message translates to:
  /// **'해산물 구이/찜'**
  String get cat16;

  /// No description provided for @cat17.
  ///
  /// In ko, this message translates to:
  /// **'베트남식 전문'**
  String get cat17;

  /// No description provided for @cat18.
  ///
  /// In ko, this message translates to:
  /// **'그 외 기타 간이 음식점'**
  String get cat18;

  /// No description provided for @cat19.
  ///
  /// In ko, this message translates to:
  /// **'곱창 전골/구이'**
  String get cat19;

  /// No description provided for @cat20.
  ///
  /// In ko, this message translates to:
  /// **'닭/오리고기 구이/찜'**
  String get cat20;

  /// No description provided for @cat21.
  ///
  /// In ko, this message translates to:
  /// **'족발/보쌈'**
  String get cat21;

  /// No description provided for @cat22.
  ///
  /// In ko, this message translates to:
  /// **'떡/한과'**
  String get cat22;

  /// No description provided for @cat23.
  ///
  /// In ko, this message translates to:
  /// **'버거'**
  String get cat23;

  /// No description provided for @cat24.
  ///
  /// In ko, this message translates to:
  /// **'소고기 구이/찜'**
  String get cat24;

  /// No description provided for @cat25.
  ///
  /// In ko, this message translates to:
  /// **'구내식당'**
  String get cat25;

  /// No description provided for @cat26.
  ///
  /// In ko, this message translates to:
  /// **'마라탕/훠궈'**
  String get cat26;

  /// No description provided for @cat27.
  ///
  /// In ko, this message translates to:
  /// **'토스트/샌드위치/샐러드'**
  String get cat27;

  /// No description provided for @cat28.
  ///
  /// In ko, this message translates to:
  /// **'냉면/밀면'**
  String get cat28;

  /// No description provided for @cat29.
  ///
  /// In ko, this message translates to:
  /// **'일식 면 요리'**
  String get cat29;

  /// No description provided for @cat30.
  ///
  /// In ko, this message translates to:
  /// **'일식 카레/돈가스/덮밥'**
  String get cat30;

  /// No description provided for @cat31.
  ///
  /// In ko, this message translates to:
  /// **'아이스크림/빙수'**
  String get cat31;

  /// No description provided for @cat32.
  ///
  /// In ko, this message translates to:
  /// **'파스타/스테이크'**
  String get cat32;

  /// No description provided for @cat33.
  ///
  /// In ko, this message translates to:
  /// **'기타 서양식 음식점'**
  String get cat33;

  /// No description provided for @cat34.
  ///
  /// In ko, this message translates to:
  /// **'기타 한식 음식점'**
  String get cat34;

  /// No description provided for @cat35.
  ///
  /// In ko, this message translates to:
  /// **'전/부침개'**
  String get cat35;

  /// No description provided for @cat36.
  ///
  /// In ko, this message translates to:
  /// **'뷔페'**
  String get cat36;

  /// No description provided for @cat37.
  ///
  /// In ko, this message translates to:
  /// **'기타 일식 음식점'**
  String get cat37;

  /// No description provided for @cat38.
  ///
  /// In ko, this message translates to:
  /// **'기타 동남아식 전문'**
  String get cat38;

  /// No description provided for @cat39.
  ///
  /// In ko, this message translates to:
  /// **'무도 유흥 주점'**
  String get cat39;

  /// No description provided for @cat40.
  ///
  /// In ko, this message translates to:
  /// **'패밀리레스토랑'**
  String get cat40;

  /// No description provided for @cat41.
  ///
  /// In ko, this message translates to:
  /// **'복 요리 전문'**
  String get cat41;

  /// No description provided for @cat42.
  ///
  /// In ko, this message translates to:
  /// **'분류 안된 외국식 음식점'**
  String get cat42;

  /// No description provided for @errQueryNotUnderstood.
  ///
  /// In ko, this message translates to:
  /// **'검색어를 이해하지 못했어요. 다르게 말해 주세요.'**
  String get errQueryNotUnderstood;

  /// No description provided for @errOutsideKoreaMap.
  ///
  /// In ko, this message translates to:
  /// **'대한민국 안에서 지도를 이동해 주세요.'**
  String get errOutsideKoreaMap;

  /// No description provided for @errPlaceNotFound.
  ///
  /// In ko, this message translates to:
  /// **'공개된 장소를 찾지 못했어요.'**
  String get errPlaceNotFound;

  /// No description provided for @errPlaceServerRetry.
  ///
  /// In ko, this message translates to:
  /// **'장소 DB에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.'**
  String get errPlaceServerRetry;

  /// No description provided for @errRouteKoreaOnly.
  ///
  /// In ko, this message translates to:
  /// **'한국 안의 출발지와 도착지만 안내할 수 있어요.'**
  String get errRouteKoreaOnly;

  /// No description provided for @errRouteTooFar.
  ///
  /// In ko, this message translates to:
  /// **'걸어가기엔 너무 멀어요.'**
  String get errRouteTooFar;

  /// No description provided for @errRouteUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'길찾기를 준비 중이에요.'**
  String get errRouteUnavailable;

  /// No description provided for @errGoogleBusy.
  ///
  /// In ko, this message translates to:
  /// **'Google 검색 요청이 많아요. 잠시 후 다시 시도해 주세요.'**
  String get errGoogleBusy;

  /// No description provided for @agentNotice.
  ///
  /// In ko, this message translates to:
  /// **'{label} 기준으로 찾았어요.'**
  String agentNotice(String label);

  /// No description provided for @agentNoticeTaste.
  ///
  /// In ko, this message translates to:
  /// **'내 취향 기준으로 찾았어요.'**
  String get agentNoticeTaste;

  /// No description provided for @agentNoticeTasteFoods.
  ///
  /// In ko, this message translates to:
  /// **'내 취향 · {foods} 기준으로 찾았어요.'**
  String agentNoticeTasteFoods(String foods);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
