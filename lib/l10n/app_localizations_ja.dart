// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Pind';

  @override
  String get navMap => 'マップ';

  @override
  String get navCompose => '投稿';

  @override
  String get navMyPage => 'マイページ';

  @override
  String get loginTagline => '好みに合うお店だけを、地図の上で';

  @override
  String get loginKakao => 'カカオで3秒ではじめる';

  @override
  String get loginApple => 'Appleで続ける';

  @override
  String get loginGoogle => 'Googleで続ける';

  @override
  String get loginPreview => 'ログインせずに試す';

  @override
  String get authOpenFailed => 'ログイン画面を開けませんでした。もう一度お試しください。';

  @override
  String get authAnonymousDisabled => '開発用の匿名ログインは許可されていません。';

  @override
  String get authPreviewFailed => '体験を開始できませんでした。';

  @override
  String get authUnavailable => 'ログインに接続できませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get back => '戻る';

  @override
  String get clear => 'クリア';

  @override
  String postPhotoOpen(int number) {
    return '投稿写真$numberを拡大';
  }

  @override
  String ratingScore(String criterion, int score) {
    return '$criterion $score点';
  }

  @override
  String get postDelete => '投稿を削除';

  @override
  String get postDeleteTitle => '投稿を削除しますか？';

  @override
  String get postDeleteBody => '写真と評価も一緒に消え、元に戻せません。';

  @override
  String get delete => '削除';

  @override
  String get close => '閉じる';

  @override
  String get qrCameraDenied => 'カメラを使用できません。設定でカメラへのアクセスを許可してください。';

  @override
  String get qrNotPind => 'Pindの友だちコードではありません';

  @override
  String get qrHint => '友だちのPind QRコードを枠内に合わせてください';

  @override
  String get qrTitle => '友だちコードをスキャン';

  @override
  String get linkCopied => 'リンクをコピーしました。';

  @override
  String get shareMyCode => 'マイコードを共有';

  @override
  String get profileLoadFailed => 'プロフィールを読み込めませんでした。';

  @override
  String get retry => '再試行';

  @override
  String get kakaoTalk => 'カカオトーク';

  @override
  String get instagram => 'Instagram';

  @override
  String get copyLink => 'リンクをコピー';

  @override
  String get scanFriendCode => '友だちのコードをスキャン';

  @override
  String get myQrCode => 'マイPind QRコード';

  @override
  String copyLinkLabel(String link) {
    return 'リンクをコピー $link';
  }

  @override
  String shareTitle(String name) {
    return '$nameさんのPind';
  }

  @override
  String get shareBody => '食の好みマップをのぞいてみましょう';

  @override
  String get viewProfile => 'プロフィールを見る';

  @override
  String get inviteToPind => 'Pindに友だちを招待';

  @override
  String get criterionTaste => '味';

  @override
  String get criterionTasteHint => '素材と調理の完成度';

  @override
  String get criterionAmbience => '雰囲気・空間';

  @override
  String get criterionAmbienceHint => 'インテリアと座席';

  @override
  String get criterionValue => 'コスパ';

  @override
  String get criterionValueHint => '価格に対する満足度';

  @override
  String get criterionPortion => '量';

  @override
  String get criterionPortionHint => '一食に十分な量';

  @override
  String get criterionService => '清潔さ・サービス';

  @override
  String get criterionServiceHint => '接客と衛生';

  @override
  String get criterionPhotogenic => '映える';

  @override
  String get criterionPhotogenicHint => '撮りたくなるお店';

  @override
  String get criterionQuiet => '静かさ';

  @override
  String get criterionQuietHint => '会話しやすい';

  @override
  String get criterionParking => '駐車';

  @override
  String get criterionParkingHint => '車を停めやすい';

  @override
  String get occasionSolo => 'ひとりご飯';

  @override
  String get occasionSoloHint => 'ひとりでも気楽な席';

  @override
  String get occasionFriends => '友だちと';

  @override
  String get occasionFriendsHint => 'わいわい集まり';

  @override
  String get occasionDate => 'デート';

  @override
  String get occasionDateHint => '雰囲気のあるお店';

  @override
  String get occasionFamily => '家族の食事';

  @override
  String get occasionFamilyHint => '広くて静かなお店';

  @override
  String get occasionGroup => '飲み会・集まり';

  @override
  String get occasionGroupHint => '団体席のあるお店';

  @override
  String get occasionWork => '作業・勉強';

  @override
  String get occasionWorkHint => 'コンセントとWi-Fi';

  @override
  String get occasionDrinks => '一杯飲む';

  @override
  String get occasionDrinksHint => '遅くまで開いているお店';

  @override
  String get occasionQuick => '急いでいるとき';

  @override
  String get occasionQuickHint => 'すぐ出てくるお店';

  @override
  String get cuisineKorean => '韓国料理・定食';

  @override
  String get cuisineBarbecue => '焼肉';

  @override
  String get cuisineSoup => 'スープ・鍋';

  @override
  String get cuisineNoodles => '麺類';

  @override
  String get cuisineStreet => '粉食・軽食';

  @override
  String get cuisineJapanese => '和食';

  @override
  String get cuisineSushi => '寿司・刺身';

  @override
  String get cuisineChinese => '中華';

  @override
  String get cuisineWestern => '洋食・パスタ';

  @override
  String get cuisineAsian => 'アジア料理';

  @override
  String get cuisineChicken => 'チキン';

  @override
  String get cuisineDessert => 'カフェ・デザート';

  @override
  String get cuisineBakery => 'ベーカリー';

  @override
  String get cuisineBar => '居酒屋・バー';

  @override
  String get pindUser => 'Pindユーザー';

  @override
  String get photoProvider => '写真提供者';

  @override
  String get sourceSbiz => '小商工人市場振興公団';

  @override
  String get kakaoMap => 'カカオマップ';

  @override
  String get naverMap => 'NAVER地図';

  @override
  String get unsupportedSource => '対応していない場所の情報源です。';

  @override
  String get sourceOpenData => '公共データの原本';

  @override
  String get viewOnMap => '地図で見る';

  @override
  String get directionsInGoogle => 'Googleマップで経路検索';

  @override
  String get viewInKakao => 'カカオマップで見る';

  @override
  String get searchInNaver => 'NAVER地図で検索';

  @override
  String friendsVisited(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$nameさんほか$others人が訪問',
      zero: '$nameさんが訪問',
    );
    return '$_temp0';
  }

  @override
  String friendsSaved(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$nameさんほか$others人が保存',
      zero: '$nameさんが保存',
    );
    return '$_temp0';
  }

  @override
  String get errProfileServer => 'プロフィールサーバーに接続できませんでした。';

  @override
  String get errSignInRequired => 'ログインが必要です。';

  @override
  String get errHandleTaken => 'そのIDはすでに使われています。';

  @override
  String get errHandleImmutable => 'IDは一度決めると変更できません。';

  @override
  String get errProfileSave => 'プロフィールを保存できませんでした。もう一度お試しください。';

  @override
  String get errProfileNotFound => 'プロフィールが見つかりません。';

  @override
  String get errFeedServer => 'フィードサーバーに接続できませんでした。';

  @override
  String get errNotificationsLoad => '通知を読み込めませんでした。';

  @override
  String get errNotificationsRead => '通知を既読にできませんでした。';

  @override
  String get errFeedLoad => 'フィードを読み込めませんでした。';

  @override
  String get errLikeSignIn => 'ログインすると「いいね」できます。';

  @override
  String get errFriendsServer => '友だちサーバーに接続できませんでした。';

  @override
  String get errSuggestionsLoad => 'おすすめを読み込めませんでした。';

  @override
  String get errSearchFailed => '検索できませんでした。';

  @override
  String get errFollowersLoad => 'フォロワーを読み込めませんでした。';

  @override
  String get errFollowingLoad => 'フォロー中を読み込めませんでした。';

  @override
  String get errFollow => 'フォローできませんでした。';

  @override
  String get errUnfollow => 'フォローを解除できませんでした。';

  @override
  String get errQueryLength => '検索語は2〜120文字で入力してください。';

  @override
  String get errPlaceCheck => '場所を確認できませんでした。';

  @override
  String get errPlaceSignIn => '場所を探すにはログインが必要です。';

  @override
  String get errSessionStart => 'セッションを開始できませんでした。';

  @override
  String get errPlaceLoad => '場所を読み込めませんでした。';

  @override
  String get errPlaceServer => '場所サーバーに接続できませんでした。';

  @override
  String get errPostSignIn => 'ログインしてから投稿してください。';

  @override
  String get errPostServer => '投稿サーバーに接続できませんでした。';

  @override
  String get errPostDeleteRetry => '投稿を削除できませんでした。もう一度お試しください。';

  @override
  String get errAccountChanged => 'アカウントが変更されました。もう一度ログインしてください。';

  @override
  String get errPostPublishKept => '投稿できませんでした。入力内容は残っているので、もう一度お試しください。';

  @override
  String get inviteGeneric => 'Pindでお互いの食の好みをフォローしよう！';

  @override
  String get errProfileLoadRetry => 'プロフィールを読み込めませんでした。もう一度お試しください。';

  @override
  String get errPhotoUpload => '写真をアップロードできませんでした。もう一度お試しください。';

  @override
  String get errDistanceNeedsLocation => '距離の表示には位置情報の許可と位置情報サービスが必要です。';

  @override
  String get errLocationUnknown => '現在地を確認できませんでした。';

  @override
  String get errSaveUnsupported => 'この情報源の場所はまだ保存できません。元の地図で確認してください。';

  @override
  String get errSaveUnavailable => '保存機能に接続できませんでした。詳細を再読み込みしてください。';

  @override
  String get errSaveRetry => '保存できませんでした。もう一度お試しください。';

  @override
  String get errLikeRetry => '「いいね」を反映できませんでした。もう一度お試しください。';

  @override
  String get errPostDelete => '投稿を削除できませんでした。';

  @override
  String get errLinkOpen => 'リンクを開けませんでした。もう一度お試しください。';

  @override
  String get errShareOpen => '共有シートを開けませんでした。';

  @override
  String get errLoginIncomplete => 'ログインを完了できませんでした。もう一度お試しください。';

  @override
  String get errPreviewRetry => '体験を開始できませんでした。もう一度お試しください。';

  @override
  String get errDraftSave => '入力内容を保存できませんでした。もう一度お試しください。';

  @override
  String get locationSkipHint => '位置情報を許可しなくても、検索からはじめられます。';

  @override
  String get errLocationPermission => '位置情報の許可を確認できませんでした。あとで設定できます。';

  @override
  String get errSettingsOpen => '設定を開けませんでした。端末の設定で位置情報を許可してください。';

  @override
  String get errCheckInput => '入力内容を確認してください。';

  @override
  String get errLocationServicesOff => '端末の位置情報サービスをオンにしてください。';

  @override
  String get errLocationDenied => '位置情報なしでも、地図を動かしたり検索したりできます。';

  @override
  String get errOutsideKorea => '現在地が韓国国外です。韓国の場所を検索してください。';

  @override
  String get errPhotoTooLarge => '写真は1枚10MB以下で選んでください。';

  @override
  String get errPhotoFormat => '対応している形式の写真を選んでください。';

  @override
  String get errPhotoLoad => '写真を読み込めませんでした。';

  @override
  String get errPlaceSearchSignIn => 'ログインしてからお店を検索してください。';

  @override
  String get errPostPublish => '投稿できませんでした。';

  @override
  String get errConnectionRetry => '接続を確認して、もう一度お試しください。';

  @override
  String inviteFollow(String who, String link) {
    return 'Pindで$whoさんをフォローして、食の好みをシェアしよう！\n$link';
  }

  @override
  String agoWeeks(int n) {
    return '$n週間前';
  }

  @override
  String agoDays(int n) {
    return '$n日前';
  }

  @override
  String get yesterday => '昨日';

  @override
  String agoHours(int n) {
    return '$n時間前';
  }

  @override
  String agoMinutes(int n) {
    return '$n分前';
  }

  @override
  String get justNow => 'たった今';

  @override
  String get notifications => '通知';

  @override
  String unreadCount(int count) {
    return '未読 $count';
  }

  @override
  String get markAllRead => 'すべて既読';

  @override
  String get noNotifications => 'まだ通知はありません。';

  @override
  String get notifLikeRest => 'さんがあなたの投稿にいいねしました';

  @override
  String get notifVisitMid => 'さんが';

  @override
  String get restaurant => 'お店';

  @override
  String get notifVisitEnd => 'を訪れました';

  @override
  String get notifFollowRest => 'さんがあなたをフォローしました';

  @override
  String get following => 'フォロー中';

  @override
  String get followBack => 'フォローバック';

  @override
  String get follow => 'フォロー';

  @override
  String unfollowLabel(String label) {
    return '$label、フォロー解除';
  }

  @override
  String unfollowTitle(String name) {
    return '$nameさんのフォローを解除しますか？';
  }

  @override
  String get unfollowBody => '解除してもいつでもまたフォローできます。';

  @override
  String get unfollow => 'フォロー解除';

  @override
  String tasteMatchPercent(int percent) {
    return '好み$percent%一致';
  }

  @override
  String unfollowName(String name) {
    return '$nameのフォローを解除';
  }

  @override
  String followName(String name) {
    return '$nameをフォロー';
  }

  @override
  String get errListLoad => 'リストを読み込めませんでした。';

  @override
  String get tryAgainPlease => 'もう一度お試しください。';

  @override
  String peopleCount(int count) {
    return '$count人';
  }

  @override
  String get followers => 'フォロワー';

  @override
  String get noFollowers => 'まだフォロワーはいません。';

  @override
  String get noFollowing => 'まだ誰もフォローしていません。';

  @override
  String get signOutTitle => 'ログアウトしますか？';

  @override
  String get signOutBody => 'もう一度ログインすれば、投稿と保存した場所はそのまま見られます。';

  @override
  String get signOut => 'ログアウト';

  @override
  String get errSignOut => 'ログアウトできませんでした。もう一度お試しください。';

  @override
  String get profileSettings => 'プロフィール設定';

  @override
  String get changePhoto => '写真を変更';

  @override
  String get noHandle => 'IDなし';

  @override
  String get handleLocked => 'IDは変更できません';

  @override
  String get name => '名前';

  @override
  String get statusMessage => 'ステータスメッセージ';

  @override
  String get statusHint => '今日のひとことをどうぞ';

  @override
  String get save => '保存';

  @override
  String get addFriend => '友だちを追加';

  @override
  String get newNotifications => '新しい通知';

  @override
  String get exploreFriendsTaste => '友だちの好みを探す';

  @override
  String get inviteFriends => '友だちを招待';

  @override
  String get shareFriendsTaste => '友だちと食の好みをシェアしよう';

  @override
  String get invite => '招待する';

  @override
  String get noPostsYet => 'まだ投稿はありません。';

  @override
  String get postDeleted => '投稿を削除しました。';

  @override
  String get unlike => 'いいねを取り消す';

  @override
  String get like => 'いいね';

  @override
  String searchResultsCount(int count) {
    return '検索結果 $count人';
  }

  @override
  String get searchResults => '検索結果';

  @override
  String get noSearchResults => '検索結果はありません。';

  @override
  String get cantFindSomeone => '探している人が見つかりませんか？';

  @override
  String get inviteByLink => 'リンクで招待';

  @override
  String get shareMyCodeAction => 'マイコードを共有';

  @override
  String get inviteByLinkHint => 'リンクで友だちを招待しよう';

  @override
  String get similarTaste => '好みが似ている人';

  @override
  String get noSimilarTaste => 'まだ好みが似ている人はいません。';

  @override
  String get searchIdOrName => 'IDまたは名前で検索';

  @override
  String get seeMore => 'もっと見る ›';

  @override
  String get agentStepRead => '入力した文章を分析しています';

  @override
  String get agentStepPlaces => '投稿のある場所を見ています';

  @override
  String get agentStepTaste => 'あなたの好みに合う場所を探しています';

  @override
  String get errSearchRetry => '検索できませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get errSaveToggle => '保存状態を変更できませんでした。もう一度お試しください。';

  @override
  String get agentTitle => 'あなた好みのグルメ検索';

  @override
  String get agentSubtitle => '好みを詳しく教えるほど、おすすめが正確になります。';

  @override
  String recommendedCount(int count) {
    return 'おすすめの場所 $count件';
  }

  @override
  String get agentNoResults => '投稿のある場所の中に合うお店が見つかりませんでした。言い方を変えてみませんか？';

  @override
  String get askAnything => 'なんでも聞いてください...';

  @override
  String get voiceSearch => '音声検索';

  @override
  String get search => '検索';

  @override
  String get voiceComingSoon => '音声検索は準備中です。';

  @override
  String get rankingFromMapCenter => '現在地を確認できないため、地図の中心から10km以内の結果です。';

  @override
  String get rankingEmpty => '10km以内に投稿のある場所はまだありません。';

  @override
  String get sortByTaste => '好み順';

  @override
  String reviewsCount(int count) {
    return 'レビュー $count';
  }

  @override
  String get unsave => '保存を取り消す';

  @override
  String get taste => '好み';

  @override
  String ratingScoreText(String criterion, String score) {
    return '$criterion $score点';
  }

  @override
  String get backToMap => '地図に戻る';

  @override
  String get checkLocationInSettings => '設定で位置情報の許可を確認';

  @override
  String get allowLocationStart => '位置情報を許可してはじめる';

  @override
  String get later => 'あとで';

  @override
  String get locationTitle => 'いまいる場所の\nまわりから見せますね';

  @override
  String get locationBody => '位置情報を許可すると、近くのおいしいお店や好みを探せます。';

  @override
  String get nearbyFood => '近くのおいしいお店';

  @override
  String get nearbyFoodHint => '近くのお店だけをおすすめ';

  @override
  String get friendsFood => '友だちのおすすめ';

  @override
  String get friendsFoodHint => '友だちが行ったお店が見られます';

  @override
  String get localRanking => 'エリアランキング';

  @override
  String get localRankingHint => '「聖水洞で1位」のようなエリア順位';

  @override
  String get recentlyViewed => '最近見た場所';

  @override
  String get recentlyViewedEmpty => '過去24時間に見た場所がここに表示されます。';

  @override
  String get savedPlaces => '保存した場所';

  @override
  String get noSavedPlaces => '保存した場所はまだありません。';

  @override
  String get noSharedSaves => '共有している保存場所はありません。';

  @override
  String get noPlacesToShow => '表示する場所がありません。';

  @override
  String get settings => '設定';

  @override
  String get posts => '投稿';

  @override
  String get myMap => 'マイマップ';

  @override
  String get badgeFoodie => 'グルメ通';

  @override
  String get badgePoster => '投稿王';

  @override
  String get badgeJudge => '名店鑑定士';

  @override
  String get badges => 'バッジ';

  @override
  String get myMapTitle => 'わたしのマップ';

  @override
  String get noPostsWritten => 'まだ投稿はありません';

  @override
  String get mapUnavailable => '地図を使用できません';

  @override
  String get viewMap => 'マップを見る ›';

  @override
  String get myTaste => 'わたしの好み';

  @override
  String tasteType(String criterion) {
    return '$criterion重視タイプ';
  }

  @override
  String get edit => '✎ 編集';

  @override
  String get tasteEmpty => '好みを設定するとここに表示されます。';

  @override
  String get noPublicTaste => '公開している好みはありません。';

  @override
  String tasteOrder(String first, String second, String third) {
    return 'まず$first、次に$second・$thirdを重視します。';
  }

  @override
  String agoYears(int n) {
    return '$n年前';
  }

  @override
  String agoMonths(int n) {
    return '$nか月前';
  }

  @override
  String savedAgo(String ago) {
    return '$agoに保存';
  }

  @override
  String get sortRecentSaved => '保存が新しい順';

  @override
  String placesCount(int count) {
    return '$count件';
  }

  @override
  String get onboardingTitlePriorities => 'お店を選ぶとき\n何をいちばん重視しますか？';

  @override
  String get onboardingTitleOccasions => '外食のシーンを選んでください。';

  @override
  String get onboardingTitleCuisines => '好きなものを選んでください。';

  @override
  String get onboardingHintPriorities => '3つだけ。順に50% · 30% · 20%で反映します。';

  @override
  String get onboardingHintOccasions => '最大3つ。シーンに合ったリストを作ります。';

  @override
  String get onboardingHintCuisines => '3つ以上選んでください。選ぶほどおすすめが正確になります。';

  @override
  String get onboardingPickThree => '大切な基準を3つ選んでください。';

  @override
  String prioritiesOrder(String order) {
    return '$orderの順に反映されます';
  }

  @override
  String selectedCount(int count) {
    return '$count件選択中';
  }

  @override
  String get previous => '前へ';

  @override
  String onboardingStep(int step) {
    return '好み設定 $step / 3';
  }

  @override
  String get saving => '保存中…';

  @override
  String get buildTasteMap => 'わたしの好みマップを作る';

  @override
  String get next => '次へ';

  @override
  String rankLabel(int rank) {
    return '$rank位';
  }

  @override
  String get filterNearby => '📍 現在地の周辺';

  @override
  String get filterRecent => '最近訪れた';

  @override
  String get filterSaved => '保存した場所';

  @override
  String get categoryAll => 'すべて';

  @override
  String get categoryCafe => 'カフェ';

  @override
  String get categoryBar => '居酒屋';

  @override
  String get categoryMeat => '焼肉';

  @override
  String get categoryNoodles => '麺';

  @override
  String get categoryDessert => 'デザート';

  @override
  String get errRestaurantSearch => 'お店を検索できませんでした。';

  @override
  String get errLocationCheckPermission => '現在地を確認できません。位置情報の許可を確認してください。';

  @override
  String get notInRecent => '最近訪れた場所にはありません。';

  @override
  String get noRecentViews => '過去24時間に見た場所はありません。';

  @override
  String get notInSaved => '保存した場所にはありません。';

  @override
  String get findingRestaurants => 'お店を探しています。';

  @override
  String noNearbyMatch(String distance) {
    return '周辺$distance以内に合うお店がありません。';
  }

  @override
  String get searchByNameOrAddress => 'お店の名前か住所で検索してください。';

  @override
  String get whereDidYouGo => 'どこに行きましたか？';

  @override
  String get nameOrAddress => 'お店の名前または住所';

  @override
  String selectPlace(String name) {
    return '$nameを選択';
  }

  @override
  String get select => '選択';

  @override
  String get errProfileOpen => 'プロフィールを開けませんでした。';

  @override
  String get postPublished => '投稿しました。';

  @override
  String postPhotoOf(int number, int total) {
    return '投稿写真 $number/$total';
  }

  @override
  String get noPostsYetMine => 'まだ投稿していません。';

  @override
  String get share => '共有';

  @override
  String get errTasteSave => '好みを保存できませんでした。もう一度お試しください。';

  @override
  String countrySelected(String country) {
    return '$countryを選択中';
  }

  @override
  String get countryTitle => '国を\n選んでください';

  @override
  String get countryBody => 'サービス地域・言語・通貨表記がまとめて設定されます。';

  @override
  String get countrySearch => '国を検索';

  @override
  String get countryPopular => 'よく選ばれる国';

  @override
  String get countryKoreaOnly => '現在、グルメ探索は韓国で提供しています。';

  @override
  String get basicTitle => '基本情報を\n教えてください';

  @override
  String get basicBody => '同世代に人気のお店をおすすめするためだけに使います。\nプロフィールには公開されません。';

  @override
  String get enterName => '名前を入力してください';

  @override
  String get gender => '性別';

  @override
  String get male => '男性';

  @override
  String get female => '女性';

  @override
  String get preferNotToSay => '選択しない';

  @override
  String get birthDate => '生年月日';

  @override
  String ageBand(int age, int decade, String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'early': '前半',
      'mid': '半ば',
      'other': '後半',
    });
    return '$age歳 · $decade代$_temp0';
  }

  @override
  String get ageUsedFor => '同世代の好みのおすすめに使います';

  @override
  String get ageMinimum => '14歳以上の方がご利用いただけます。';

  @override
  String get consentPrivacy => '個人情報の収集・利用に同意（必須）';

  @override
  String get consentPrivacyBody =>
      '名前・性別・生年月日は基本情報と好みのおすすめに使用し、公開プロフィールには表示しません。';

  @override
  String get consentAge => '14歳以上です（必須）';

  @override
  String get consentAgeBody => '生年月日を確認し、14歳以上の場合は選択してください。';

  @override
  String get consentPersonalize => 'パーソナライズされたおすすめへの情報活用（任意）';

  @override
  String get consentPersonalizeBody => '選択しなくても、基本サービスと場所の検索はご利用いただけます。';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get day => '日';

  @override
  String viewDetails(String title) {
    return '$titleの内容を見る';
  }

  @override
  String get startPind => 'Pindをはじめる';

  @override
  String get handleTitle => 'なんと\nお呼びしましょうか？';

  @override
  String get handleBody => 'IDはあとから変更できません。ニックネームはいつでも変更できます。';

  @override
  String get chooseAvatar => 'アバターを選択';

  @override
  String get handle => 'ID';

  @override
  String get enterHandle => 'IDを入力してください';

  @override
  String get handleValid => '✓ 使用できる形式です';

  @override
  String get handleRule => '英字・数字・アンダーバーで3〜20文字入力してください。';

  @override
  String get chooseEmoji => '自分らしい絵文字を選んでください';

  @override
  String get pickFromAlbum => 'アルバムから写真を選択';

  @override
  String get errDetailLoad => '詳細情報を読み込めませんでした。';

  @override
  String get errContextLoad => '好み・フォロー情報を読み込めませんでした。';

  @override
  String get detailSwipeHint => '⌃  上にスワイプして紹介・投稿を見る';

  @override
  String get hoursUnknown => '営業時間は要確認';

  @override
  String get openNow => '営業中';

  @override
  String get closedNow => '営業終了';

  @override
  String get locating => '位置を確認中';

  @override
  String get checkDistance => '距離を確認';

  @override
  String pindPostCount(int count) {
    return 'Pind投稿 $count件';
  }

  @override
  String get reviewCountUnknown => 'レビュー数は要確認';

  @override
  String reviewCountLong(int count) {
    return 'レビュー $count件';
  }

  @override
  String get tasteMatchHelp =>
      '公開平均を1・2・3位に50・30・20%で反映します。1点はその基準の0%、5点は100%になります。';

  @override
  String get tasteMatchUnrated => '好み：評価不足';

  @override
  String tasteMatchMine(int percent) {
    return '好み $percent%';
  }

  @override
  String axisNoRatingsDot(String criterion) {
    return '$criterion · まだ評価がありません';
  }

  @override
  String axisAverageDot(String criterion, String score) {
    return '$criterion · お店の平均 $score / 5';
  }

  @override
  String axisNoRatings(String criterion) {
    return '$criterion：まだ評価がありません';
  }

  @override
  String axisAverage(String criterion, String score) {
    return '$criterion：お店の平均 $score点';
  }

  @override
  String friendsVisitedPlace(String names, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$namesさんほか$others人が訪れました',
      zero: '$namesさんが訪れました',
    );
    return '$_temp0';
  }

  @override
  String followingSaved(int count) {
    return 'フォロー中 $count人が保存';
  }

  @override
  String placePhotoLabel(String place, int number) {
    return '$placeの写真 $number';
  }

  @override
  String photoBy(String name) {
    return '写真：$name';
  }

  @override
  String get photoSource => '写真の出典';

  @override
  String get intro => '紹介';

  @override
  String oneLineSummaryTitle(String axes) {
    return '$axesのひとこと要約';
  }

  @override
  String get noOneLiners => 'まだひとこと評価はありません。';

  @override
  String get noIntro => '紹介文はありません。';

  @override
  String dataBy(String source) {
    return '情報提供：$source';
  }

  @override
  String get saved => '保存済み';

  @override
  String get directions => '経路';

  @override
  String get errWalkRoute => '徒歩ルートが見つかりませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get errLocationUseSearch => '現在地を確認できませんでした。検索で続けられます。';

  @override
  String get walkFinding => '徒歩ルートを探しています…';

  @override
  String get walkArrived => '到着しました';

  @override
  String get walkRerouting => 'ルートを再検索しています…';

  @override
  String walkRemaining(String distance, int minutes) {
    return '$distance · 約$minutes分';
  }

  @override
  String walkTo(String place) {
    return '$placeまで徒歩';
  }

  @override
  String get walkEnd => '案内を終了';

  @override
  String get openSearch => '検索を開く';

  @override
  String get mapSearchHint => '何が食べたいですか？';

  @override
  String get editTaste => '好みを編集';

  @override
  String get mapLoadFailed => '地図を読み込めません。';

  @override
  String get mapFallbackHint => '場所の検索とリストで探せます。';

  @override
  String get needsBackend => '接続を設定すると場所を探せます。';

  @override
  String get zoomIn => '拡大';

  @override
  String get zoomOut => '縮小';

  @override
  String get myLocation => '現在地';

  @override
  String get newPost => '投稿を作成';

  @override
  String get addPhotos => '写真を追加';

  @override
  String get visitedRestaurant => '訪れたお店';

  @override
  String get ratings => '評価';

  @override
  String get ratingsRequired => '味 · 量 · 雰囲気（必須）';

  @override
  String get myAverageRating => 'わたしの平均評価';

  @override
  String get writeReview => 'レビューを書く';

  @override
  String get optional => '任意';

  @override
  String get visibility => '公開範囲';

  @override
  String get visibilityPublic => '全体公開';

  @override
  String get visibilityFriends => '友だちのみ';

  @override
  String get visibilityPublicHint => 'Pindの誰でも見られます';

  @override
  String get visibilityFriendsHint => 'あなたをフォローしている人だけが見られます';

  @override
  String get reviewHint => '故郷の料理にたとえるなら？初めて食べた外国人として正直なレビューを残してください。';

  @override
  String errorPrefix(String message) {
    return 'エラー：$message';
  }

  @override
  String get publish => '投稿する';

  @override
  String photoLongPressDelete(int number) {
    return '写真$number、長押しで削除';
  }

  @override
  String get pickVisitedRestaurant => '訪れたお店を選んでください';

  @override
  String get change => '変更';

  @override
  String get rateBest => '最高です';

  @override
  String get rateTasty => 'おいしいです';

  @override
  String get rateOkay => 'まあまあです';

  @override
  String get rateMeh => 'いまひとつです';

  @override
  String get rateBad => 'いまいちです';

  @override
  String get portionHuge => 'とても多いです';

  @override
  String get portionGenerous => 'たっぷりです';

  @override
  String get portionJustRight => 'ちょうどいいです';

  @override
  String get portionSmall => '少なめです';

  @override
  String get portionTiny => 'とても少ないです';

  @override
  String get rateGood => 'いいです';

  @override
  String get suggestSpicyLevels => '辛さを選べるお店';

  @override
  String get suggestKoreanBbq => '雰囲気のいい韓国焼肉店';

  @override
  String get suggestNepali => 'ネパールの人がよく訪れるお店';

  @override
  String get suggestVegetarian => 'ベジタリアン料理';

  @override
  String get suggestKoreanVietnamese => '韓国風ベトナム料理';

  @override
  String get suggestSoloDrinks => 'ひとり飲みにいいお店';

  @override
  String get suggestPho => 'いい雰囲気のフォー店';

  @override
  String get suggestSeongsuBar => 'ソウル・聖水洞の雰囲気のいいバー';

  @override
  String get suggestHomeStyle => '韓国の家庭料理のようなお店';

  @override
  String get suggestTouristFavorite => '観光客がいちばん訪れるお店';

  @override
  String get placeKorean => '定食屋';

  @override
  String get placeBarbecue => '焼肉店';

  @override
  String get placeSoup => 'クッパ店';

  @override
  String get placeNoodles => '麺のお店';

  @override
  String get placeStreet => '粉食店';

  @override
  String get placeJapanese => '和食店';

  @override
  String get placeSushi => '寿司店';

  @override
  String get placeChinese => '中華料理店';

  @override
  String get placeWestern => 'パスタ店';

  @override
  String get placeAsian => 'フォー店';

  @override
  String get placeChicken => 'チキン店';

  @override
  String get placeDessert => 'デザートカフェ';

  @override
  String get placeBakery => 'パン屋';

  @override
  String get placeBar => '居酒屋';

  @override
  String get qualityTaste => 'おいしい';

  @override
  String get qualityAmbience => '雰囲気のいい';

  @override
  String get qualityValue => 'コスパのいい';

  @override
  String get qualityPortion => '量が多い';

  @override
  String get qualityService => '清潔で親切な';

  @override
  String get qualityPhotogenic => '映える';

  @override
  String get qualityQuiet => '静かな';

  @override
  String get qualityParking => '駐車しやすい';

  @override
  String get occasionPhraseSolo => 'ひとりご飯にいい';

  @override
  String get occasionPhraseFriends => '友だちと行くのにいい';

  @override
  String get occasionPhraseDate => 'デートにいい';

  @override
  String get occasionPhraseFamily => '家族で行くのにいい';

  @override
  String get occasionPhraseGroup => '飲み会にいい';

  @override
  String get occasionPhraseWork => '作業にいい';

  @override
  String get occasionPhraseDrinks => '一杯飲むのにいい';

  @override
  String get occasionPhraseQuick => 'さっと食べられる';

  @override
  String get genericRestaurant => 'お店';

  @override
  String get genericDining => 'レストラン';

  @override
  String get genericCafe => 'カフェ';

  @override
  String get genericBar => '居酒屋';

  @override
  String get suggestForMe => 'わたし好みのお店をおすすめして';

  @override
  String suggestQuality(String quality, String place) {
    return '$quality$place';
  }

  @override
  String suggestOccasion(String phrase, String place) {
    return '$phrase$place';
  }

  @override
  String get cat00 => '韓国定食';

  @override
  String get cat01 => 'カフェ';

  @override
  String get cat02 => '居酒屋';

  @override
  String get cat03 => 'キンパ・軽食';

  @override
  String get cat04 => '豚肉焼き・蒸し';

  @override
  String get cat05 => 'パン・ドーナツ';

  @override
  String get cat06 => '刺身・寿司';

  @override
  String get cat07 => '洋食';

  @override
  String get cat08 => 'チキン';

  @override
  String get cat09 => 'スープ・鍋';

  @override
  String get cat10 => '中華料理';

  @override
  String get cat11 => 'ピザ';

  @override
  String get cat12 => '麺・カルグクス';

  @override
  String get cat13 => '生ビール専門店';

  @override
  String get cat14 => '酒場';

  @override
  String get cat15 => '刺身店';

  @override
  String get cat16 => '海鮮焼き・蒸し';

  @override
  String get cat17 => 'ベトナム料理';

  @override
  String get cat18 => 'その他の軽食店';

  @override
  String get cat19 => 'ホルモン鍋・焼き';

  @override
  String get cat20 => '鶏・鴨肉焼き・蒸し';

  @override
  String get cat21 => '豚足・ポッサム';

  @override
  String get cat22 => '餅・韓菓';

  @override
  String get cat23 => 'バーガー';

  @override
  String get cat24 => '牛肉焼き・蒸し';

  @override
  String get cat25 => '社員食堂';

  @override
  String get cat26 => 'マーラータン・火鍋';

  @override
  String get cat27 => 'トースト・サンドイッチ・サラダ';

  @override
  String get cat28 => '冷麺';

  @override
  String get cat29 => '和風麺料理';

  @override
  String get cat30 => 'カレー・とんかつ・丼';

  @override
  String get cat31 => 'アイス・かき氷';

  @override
  String get cat32 => 'パスタ・ステーキ';

  @override
  String get cat33 => 'その他の洋食店';

  @override
  String get cat34 => 'その他の韓国料理店';

  @override
  String get cat35 => 'チヂミ';

  @override
  String get cat36 => 'ビュッフェ';

  @override
  String get cat37 => 'その他の和食店';

  @override
  String get cat38 => 'その他の東南アジア料理';

  @override
  String get cat39 => 'ダンスバー';

  @override
  String get cat40 => 'ファミリーレストラン';

  @override
  String get cat41 => 'ふぐ料理';

  @override
  String get cat42 => 'その他の外国料理店';

  @override
  String get errQueryNotUnderstood => '検索語を理解できませんでした。言い方を変えてみてください。';

  @override
  String get errOutsideKoreaMap => '地図を韓国国内に移動してください。';

  @override
  String get errPlaceNotFound => '公開されている場所が見つかりませんでした。';

  @override
  String get errPlaceServerRetry => '場所データベースに接続できませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get errRouteKoreaOnly => '案内できるのは韓国国内の出発地と目的地のみです。';

  @override
  String get errRouteTooFar => '歩くには遠すぎます。';

  @override
  String get errRouteUnavailable => '経路案内は準備中です。';

  @override
  String get errGoogleBusy => 'Google検索が混み合っています。しばらくしてからもう一度お試しください。';

  @override
  String agentNotice(String label) {
    return '「$label」で探しました。';
  }

  @override
  String get agentNoticeTaste => 'あなたの好みで探しました。';

  @override
  String agentNoticeTasteFoods(String foods) {
    return 'あなたの好み（$foods）で探しました。';
  }
}
