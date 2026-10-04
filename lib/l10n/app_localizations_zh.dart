// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Pind';

  @override
  String get navMap => '地图';

  @override
  String get navCompose => '发布';

  @override
  String get navMyPage => '我的';

  @override
  String get loginTagline => '只看合你口味的美食，尽在地图上';

  @override
  String get loginKakao => '用 Kakao 3 秒开始';

  @override
  String get loginApple => '通过 Apple 继续';

  @override
  String get loginGoogle => '通过 Google 继续';

  @override
  String get loginPreview => '免登录体验';

  @override
  String get authOpenFailed => '无法打开登录页面，请重试。';

  @override
  String get authAnonymousDisabled => '未启用开发用匿名登录。';

  @override
  String get authPreviewFailed => '无法开始体验。';

  @override
  String get authUnavailable => '无法连接登录服务，请稍后重试。';

  @override
  String get back => '返回';

  @override
  String get clear => '清除';

  @override
  String postPhotoOpen(int number) {
    return '查看帖子照片 $number';
  }

  @override
  String ratingScore(String criterion, int score) {
    return '$criterion $score 分';
  }

  @override
  String get postDelete => '删除帖子';

  @override
  String get postDeleteTitle => '要删除这篇帖子吗？';

  @override
  String get postDeleteBody => '照片和评分也会一并删除，且无法恢复。';

  @override
  String get delete => '删除';

  @override
  String get close => '关闭';

  @override
  String get qrCameraDenied => '无法使用相机，请在设置中允许相机权限。';

  @override
  String get qrNotPind => '这不是 Pind 好友码';

  @override
  String get qrHint => '请将好友的 Pind 二维码对准方框';

  @override
  String get qrTitle => '扫描好友码';

  @override
  String get linkCopied => '链接已复制。';

  @override
  String get shareMyCode => '分享我的代码';

  @override
  String get profileLoadFailed => '无法加载个人资料。';

  @override
  String get retry => '重试';

  @override
  String get kakaoTalk => 'KakaoTalk';

  @override
  String get instagram => 'Instagram';

  @override
  String get copyLink => '复制链接';

  @override
  String get scanFriendCode => '扫描好友码';

  @override
  String get myQrCode => '我的 Pind 二维码';

  @override
  String copyLinkLabel(String link) {
    return '复制链接 $link';
  }

  @override
  String shareTitle(String name) {
    return '$name 的 Pind';
  }

  @override
  String get shareBody => '来看看 TA 的美食口味地图';

  @override
  String get viewProfile => '查看主页';

  @override
  String get inviteToPind => '邀请好友加入 Pind';

  @override
  String get criterionTaste => '口味';

  @override
  String get criterionTasteHint => '食材与烹饪水准';

  @override
  String get criterionAmbience => '氛围·空间';

  @override
  String get criterionAmbienceHint => '装潢与座位';

  @override
  String get criterionValue => '性价比';

  @override
  String get criterionValueHint => '物有所值';

  @override
  String get criterionPortion => '分量';

  @override
  String get criterionPortionHint => '一餐吃得饱';

  @override
  String get criterionService => '卫生·服务';

  @override
  String get criterionServiceHint => '待客与卫生';

  @override
  String get criterionPhotogenic => '出片';

  @override
  String get criterionPhotogenicHint => '值得拍照的地方';

  @override
  String get criterionQuiet => '安静';

  @override
  String get criterionQuietHint => '适合聊天';

  @override
  String get criterionParking => '停车';

  @override
  String get criterionParkingHint => '方便停车';

  @override
  String get occasionSolo => '一人食';

  @override
  String get occasionSoloHint => '一个人也自在';

  @override
  String get occasionFriends => '和朋友';

  @override
  String get occasionFriendsHint => '热闹聚会';

  @override
  String get occasionDate => '约会';

  @override
  String get occasionDateHint => '有氛围的地方';

  @override
  String get occasionFamily => '家庭聚餐';

  @override
  String get occasionFamilyHint => '宽敞安静';

  @override
  String get occasionGroup => '聚餐·聚会';

  @override
  String get occasionGroupHint => '有团体座位';

  @override
  String get occasionWork => '办公·学习';

  @override
  String get occasionWorkHint => '有插座和 Wi-Fi';

  @override
  String get occasionDrinks => '小酌一杯';

  @override
  String get occasionDrinksHint => '营业到很晚';

  @override
  String get occasionQuick => '赶时间';

  @override
  String get occasionQuickHint => '上菜快';

  @override
  String get cuisineKorean => '韩餐·家常饭';

  @override
  String get cuisineBarbecue => '烤肉';

  @override
  String get cuisineSoup => '汤·炖锅';

  @override
  String get cuisineNoodles => '面条';

  @override
  String get cuisineStreet => '小吃';

  @override
  String get cuisineJapanese => '日料';

  @override
  String get cuisineSushi => '寿司·生鱼片';

  @override
  String get cuisineChinese => '中餐';

  @override
  String get cuisineWestern => '西餐·意面';

  @override
  String get cuisineAsian => '东南亚菜';

  @override
  String get cuisineChicken => '炸鸡';

  @override
  String get cuisineDessert => '咖啡·甜点';

  @override
  String get cuisineBakery => '烘焙';

  @override
  String get cuisineBar => '酒馆·酒吧';

  @override
  String get pindUser => 'Pind 用户';

  @override
  String get photoProvider => '照片提供者';

  @override
  String get sourceSbiz => '小工商业者市场振兴公团';

  @override
  String get kakaoMap => 'Kakao 地图';

  @override
  String get naverMap => 'Naver 地图';

  @override
  String get unsupportedSource => '不支持该地点来源。';

  @override
  String get sourceOpenData => '公共数据原始资料';

  @override
  String get viewOnMap => '在地图上查看';

  @override
  String get directionsInGoogle => '在 Google 地图中导航';

  @override
  String get viewInKakao => '在 Kakao 地图中查看';

  @override
  String get searchInNaver => '在 Naver 地图中搜索';

  @override
  String friendsVisited(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name 等 $others 人去过',
      zero: '$name 去过',
    );
    return '$_temp0';
  }

  @override
  String friendsSaved(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name 等 $others 人收藏了',
      zero: '$name 收藏了',
    );
    return '$_temp0';
  }

  @override
  String get errProfileServer => '无法连接个人资料服务器。';

  @override
  String get errSignInRequired => '需要登录。';

  @override
  String get errHandleTaken => '该 ID 已被使用。';

  @override
  String get errHandleImmutable => 'ID 一经设定便无法更改。';

  @override
  String get errProfileSave => '无法保存个人资料，请重试。';

  @override
  String get errProfileNotFound => '找不到该个人资料。';

  @override
  String get errFeedServer => '无法连接动态服务器。';

  @override
  String get errNotificationsLoad => '无法加载通知。';

  @override
  String get errNotificationsRead => '无法将通知标为已读。';

  @override
  String get errFeedLoad => '无法加载动态。';

  @override
  String get errLikeSignIn => '登录后才能点赞。';

  @override
  String get errFriendsServer => '无法连接好友服务器。';

  @override
  String get errSuggestionsLoad => '无法加载推荐列表。';

  @override
  String get errSearchFailed => '搜索失败。';

  @override
  String get errFollowersLoad => '无法加载粉丝。';

  @override
  String get errFollowingLoad => '无法加载关注列表。';

  @override
  String get errFollow => '关注失败。';

  @override
  String get errUnfollow => '取消关注失败。';

  @override
  String get errQueryLength => '请输入 2–120 个字的搜索词。';

  @override
  String get errPlaceCheck => '无法确认该地点。';

  @override
  String get errPlaceSignIn => '浏览地点需要登录。';

  @override
  String get errSessionStart => '无法开始会话。';

  @override
  String get errPlaceLoad => '无法加载地点。';

  @override
  String get errPlaceServer => '无法连接地点服务器。';

  @override
  String get errPostSignIn => '请登录后发布帖子。';

  @override
  String get errPostServer => '无法连接帖子服务器。';

  @override
  String get errPostDeleteRetry => '无法删除帖子，请重试。';

  @override
  String get errAccountChanged => '账号已变更，请重新登录。';

  @override
  String get errPostPublishKept => '发布失败。已保留您的内容，请重试。';

  @override
  String get inviteGeneric => '在 Pind 上互相关注彼此的美食口味吧！';

  @override
  String get errProfileLoadRetry => '无法加载个人资料，请重试。';

  @override
  String get errPhotoUpload => '无法上传照片，请重试。';

  @override
  String get errDistanceNeedsLocation => '显示距离需要位置权限和设备定位服务。';

  @override
  String get errLocationUnknown => '无法获取当前位置。';

  @override
  String get errSaveUnsupported => '暂不支持保存此来源的地点，请在原地图中查看。';

  @override
  String get errSaveUnavailable => '无法使用收藏功能，请重新加载详情。';

  @override
  String get errSaveRetry => '收藏失败，请重试。';

  @override
  String get errLikeRetry => '点赞失败，请重试。';

  @override
  String get errPostDelete => '无法删除帖子。';

  @override
  String get errLinkOpen => '无法打开链接，请重试。';

  @override
  String get errShareOpen => '无法打开分享窗口。';

  @override
  String get errLoginIncomplete => '无法完成登录，请重试。';

  @override
  String get errPreviewRetry => '无法开始体验，请重试。';

  @override
  String get errDraftSave => '无法保存输入内容，请重试。';

  @override
  String get locationSkipHint => '即使不允许定位，也可以从搜索开始。';

  @override
  String get errLocationPermission => '无法确认定位权限，可以稍后设置。';

  @override
  String get errSettingsOpen => '无法打开设置，请在设备设置中允许定位。';

  @override
  String get errCheckInput => '请检查输入内容。';

  @override
  String get errLocationServicesOff => '请开启设备的定位服务。';

  @override
  String get errLocationDenied => '即使没有定位权限，也可以移动地图或搜索。';

  @override
  String get errOutsideKorea => '您当前不在韩国，请搜索韩国的地点。';

  @override
  String get errPhotoTooLarge => '请选择每张 10MB 以下的照片。';

  @override
  String get errPhotoFormat => '请选择支持的照片格式。';

  @override
  String get errPhotoLoad => '无法加载照片。';

  @override
  String get errPlaceSearchSignIn => '请登录后搜索餐厅。';

  @override
  String get errPostPublish => '发布失败。';

  @override
  String get errConnectionRetry => '请检查网络连接后重试。';

  @override
  String inviteFollow(String who, String link) {
    return '在 Pind 上关注 $who，一起分享美食口味吧！\n$link';
  }

  @override
  String agoWeeks(int n) {
    return '$n 周前';
  }

  @override
  String agoDays(int n) {
    return '$n 天前';
  }

  @override
  String get yesterday => '昨天';

  @override
  String agoHours(int n) {
    return '$n 小时前';
  }

  @override
  String agoMinutes(int n) {
    return '$n 分钟前';
  }

  @override
  String get justNow => '刚刚';

  @override
  String get notifications => '通知';

  @override
  String unreadCount(int count) {
    return '$count 条未读';
  }

  @override
  String get markAllRead => '全部已读';

  @override
  String get noNotifications => '暂无通知。';

  @override
  String get notifLikeRest => ' 赞了你的帖子';

  @override
  String get notifVisitMid => ' 去了 ';

  @override
  String get restaurant => '餐厅';

  @override
  String get notifVisitEnd => '';

  @override
  String get notifFollowRest => ' 关注了你';

  @override
  String get following => '已关注';

  @override
  String get followBack => '回关';

  @override
  String get follow => '关注';

  @override
  String unfollowLabel(String label) {
    return '$label，取消关注';
  }

  @override
  String unfollowTitle(String name) {
    return '要取消关注 $name 吗？';
  }

  @override
  String get unfollowBody => '取消后也可以随时重新关注。';

  @override
  String get unfollow => '取消关注';

  @override
  String tasteMatchPercent(int percent) {
    return '口味 $percent% 契合';
  }

  @override
  String unfollowName(String name) {
    return '取消关注 $name';
  }

  @override
  String followName(String name) {
    return '关注 $name';
  }

  @override
  String get errListLoad => '无法加载列表。';

  @override
  String get tryAgainPlease => '请重试。';

  @override
  String peopleCount(int count) {
    return '$count 人';
  }

  @override
  String get followers => '粉丝';

  @override
  String get noFollowers => '还没有粉丝。';

  @override
  String get noFollowing => '还没有关注任何人。';

  @override
  String get signOutTitle => '要退出登录吗？';

  @override
  String get signOutBody => '重新登录后，帖子和收藏的地点都还在。';

  @override
  String get signOut => '退出登录';

  @override
  String get errSignOut => '无法退出登录，请重试。';

  @override
  String get profileSettings => '个人资料设置';

  @override
  String get changePhoto => '更换照片';

  @override
  String get noHandle => '无 ID';

  @override
  String get handleLocked => 'ID 无法更改';

  @override
  String get name => '名字';

  @override
  String get statusMessage => '个性签名';

  @override
  String get statusHint => '写下今天的心情吧';

  @override
  String get save => '保存';

  @override
  String get addFriend => '添加好友';

  @override
  String get newNotifications => '新通知';

  @override
  String get exploreFriendsTaste => '探索好友的口味';

  @override
  String get inviteFriends => '邀请好友';

  @override
  String get shareFriendsTaste => '和好友分享美食口味';

  @override
  String get invite => '邀请';

  @override
  String get noPostsYet => '还没有帖子。';

  @override
  String get postDeleted => '帖子已删除。';

  @override
  String get unlike => '取消点赞';

  @override
  String get like => '点赞';

  @override
  String searchResultsCount(int count) {
    return '搜索结果 $count 人';
  }

  @override
  String get searchResults => '搜索结果';

  @override
  String get noSearchResults => '没有搜索结果。';

  @override
  String get cantFindSomeone => '没找到想找的人？';

  @override
  String get inviteByLink => '通过链接邀请';

  @override
  String get shareMyCodeAction => '分享我的代码';

  @override
  String get inviteByLinkHint => '用链接邀请好友';

  @override
  String get similarTaste => '口味相近的人';

  @override
  String get noSimilarTaste => '暂时没有口味相近的人。';

  @override
  String get searchIdOrName => '搜索 ID 或名字';

  @override
  String get seeMore => '查看更多 ›';

  @override
  String get agentStepRead => '正在分析你输入的内容';

  @override
  String get agentStepPlaces => '正在查看有帖子的地点';

  @override
  String get agentStepTaste => '正在搜索符合你口味的地点';

  @override
  String get errSearchRetry => '搜索失败，请稍后重试。';

  @override
  String get errSaveToggle => '无法更改收藏状态，请重试。';

  @override
  String get agentTitle => '专属美食搜索';

  @override
  String get agentSubtitle => '越详细地描述你的口味，推荐就越准确。';

  @override
  String recommendedCount(int count) {
    return '推荐地点 $count 个';
  }

  @override
  String get agentNoResults => '在有帖子的地点中没有找到合适的，换个说法试试？';

  @override
  String get askAnything => '随便问问吧...';

  @override
  String get voiceSearch => '语音搜索';

  @override
  String get search => '搜索';

  @override
  String get voiceComingSoon => '语音搜索即将推出。';

  @override
  String get rankingFromMapCenter => '无法获取当前位置，以下为地图中心 10 公里内的结果。';

  @override
  String get rankingEmpty => '10 公里内还没有有帖子的地点。';

  @override
  String get sortByTaste => '按我的口味';

  @override
  String reviewsCount(int count) {
    return '评价 $count';
  }

  @override
  String get unsave => '取消收藏';

  @override
  String get taste => '口味';

  @override
  String ratingScoreText(String criterion, String score) {
    return '$criterion $score 分';
  }

  @override
  String get backToMap => '返回地图';

  @override
  String get checkLocationInSettings => '在设置中检查定位权限';

  @override
  String get allowLocationStart => '允许定位并开始';

  @override
  String get later => '以后再说';

  @override
  String get locationTitle => '先给你看看\n你附近的地方';

  @override
  String get locationBody => '允许定位后，就能探索你附近的美食和口味。';

  @override
  String get nearbyFood => '我附近的美食';

  @override
  String get nearbyFoodHint => '只推荐附近范围内的店';

  @override
  String get friendsFood => '好友的美食';

  @override
  String get friendsFoodHint => '可以看到好友去过的餐厅';

  @override
  String get localRanking => '附近排行';

  @override
  String get localRankingHint => '像“圣水洞第 1 名”这样的区域排名';

  @override
  String get recentlyViewed => '最近浏览的地点';

  @override
  String get recentlyViewedEmpty => '最近 24 小时内浏览的地点会显示在这里。';

  @override
  String get savedPlaces => '收藏的地点';

  @override
  String get noSavedPlaces => '还没有收藏的地点。';

  @override
  String get noSharedSaves => '没有分享的收藏地点。';

  @override
  String get noPlacesToShow => '没有可显示的地点。';

  @override
  String get settings => '设置';

  @override
  String get posts => '帖子';

  @override
  String get myMap => '我的地图';

  @override
  String get badgeFoodie => '美食达人';

  @override
  String get badgePoster => '发帖王';

  @override
  String get badgeJudge => '美食鉴定师';

  @override
  String get badges => '徽章';

  @override
  String get myMapTitle => '我的地图';

  @override
  String get noPostsWritten => '还没有发布过帖子';

  @override
  String get mapUnavailable => '无法使用地图';

  @override
  String get viewMap => '查看地图 ›';

  @override
  String get myTaste => '我的口味';

  @override
  String tasteType(String criterion) {
    return '$criterion至上型';
  }

  @override
  String get edit => '✎ 编辑';

  @override
  String get tasteEmpty => '设置口味后会显示在这里。';

  @override
  String get noPublicTaste => '没有公开的口味。';

  @override
  String tasteOrder(String first, String second, String third) {
    return '先看$first，再看$second·$third。';
  }

  @override
  String agoYears(int n) {
    return '$n 年前';
  }

  @override
  String agoMonths(int n) {
    return '$n 个月前';
  }

  @override
  String savedAgo(String ago) {
    return '$ago收藏';
  }

  @override
  String get sortRecentSaved => '最近收藏';

  @override
  String placesCount(int count) {
    return '$count 个';
  }

  @override
  String get onboardingTitlePriorities => '选餐厅时\n你最看重什么？';

  @override
  String get onboardingTitleOccasions => '请选择你的外出用餐场景。';

  @override
  String get onboardingTitleCuisines => '请选择你喜欢的。';

  @override
  String get onboardingHintPriorities => '只选 3 个，依次按 50% · 30% · 20% 计算。';

  @override
  String get onboardingHintOccasions => '最多 3 个，为你生成合适场景的清单。';

  @override
  String get onboardingHintCuisines => '请至少选 3 个，选得越多推荐越准确。';

  @override
  String get onboardingPickThree => '请选出 3 个最重要的标准。';

  @override
  String prioritiesOrder(String order) {
    return '将按 $order 的顺序计算';
  }

  @override
  String selectedCount(int count) {
    return '已选 $count 个';
  }

  @override
  String get previous => '上一步';

  @override
  String onboardingStep(int step) {
    return '口味设置 第 $step / 3 步';
  }

  @override
  String get saving => '保存中…';

  @override
  String get buildTasteMap => '生成我的口味地图';

  @override
  String get next => '下一步';

  @override
  String rankLabel(int rank) {
    return '第 $rank';
  }

  @override
  String get filterNearby => '📍 当前位置附近';

  @override
  String get filterRecent => '最近去过';

  @override
  String get filterSaved => '已收藏';

  @override
  String get categoryAll => '全部';

  @override
  String get categoryCafe => '咖啡馆';

  @override
  String get categoryBar => '酒馆';

  @override
  String get categoryMeat => '烤肉';

  @override
  String get categoryNoodles => '面食';

  @override
  String get categoryDessert => '甜点';

  @override
  String get errRestaurantSearch => '无法搜索餐厅。';

  @override
  String get errLocationCheckPermission => '无法获取当前位置，请检查定位权限。';

  @override
  String get notInRecent => '不在最近去过的地点中。';

  @override
  String get noRecentViews => '最近 24 小时内没有浏览过地点。';

  @override
  String get notInSaved => '不在收藏的地点中。';

  @override
  String get findingRestaurants => '正在寻找餐厅。';

  @override
  String noNearbyMatch(String distance) {
    return '附近 $distance 内没有符合的餐厅。';
  }

  @override
  String get searchByNameOrAddress => '请用餐厅名称或地址搜索。';

  @override
  String get whereDidYouGo => '你去了哪里？';

  @override
  String get nameOrAddress => '餐厅名称或地址';

  @override
  String selectPlace(String name) {
    return '选择 $name';
  }

  @override
  String get select => '选择';

  @override
  String get errProfileOpen => '无法打开个人主页。';

  @override
  String get postPublished => '已发布。';

  @override
  String postPhotoOf(int number, int total) {
    return '帖子照片 $number/$total';
  }

  @override
  String get noPostsYetMine => '你还没有发布帖子。';

  @override
  String get share => '分享';

  @override
  String get errTasteSave => '无法保存口味，请重试。';

  @override
  String countrySelected(String country) {
    return '已选择 $country';
  }

  @override
  String get countryTitle => '请选择\n国家或地区';

  @override
  String get countryBody => '将同时设置服务地区、语言和货币显示。';

  @override
  String get countrySearch => '搜索国家或地区';

  @override
  String get countryPopular => '常选国家或地区';

  @override
  String get countryKoreaOnly => '目前美食探索仅在韩国提供。';

  @override
  String get basicTitle => '请告诉我们\n你的基本信息';

  @override
  String get basicBody => '仅用于推荐同龄人喜欢的餐厅。\n不会公开在个人主页上。';

  @override
  String get enterName => '请输入名字';

  @override
  String get gender => '性别';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get preferNotToSay => '不选择';

  @override
  String get birthDate => '出生日期';

  @override
  String ageBand(int age, int decade, String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'early': '出头',
      'mid': '中段',
      'other': '后段',
    });
    return '$age 岁 · $decade 多岁$_temp0';
  }

  @override
  String get ageUsedFor => '用于同龄人口味推荐';

  @override
  String get ageMinimum => '年满 14 周岁方可使用。';

  @override
  String get consentPrivacy => '同意收集和使用个人信息（必选）';

  @override
  String get consentPrivacyBody => '名字、性别和出生日期仅用于基本信息和口味推荐，不会显示在公开主页上。';

  @override
  String get consentAge => '我已年满 14 周岁（必选）';

  @override
  String get consentAgeBody => '请确认出生日期，年满 14 周岁时勾选。';

  @override
  String get consentPersonalize => '将信息用于个性化推荐（可选）';

  @override
  String get consentPersonalizeBody => '不勾选也可以使用基本服务和地点搜索。';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get day => '日';

  @override
  String viewDetails(String title) {
    return '查看$title';
  }

  @override
  String get startPind => '开始使用 Pind';

  @override
  String get handleTitle => '我们该\n怎么称呼你？';

  @override
  String get handleBody => 'ID 之后无法更改，昵称可以随时修改。';

  @override
  String get chooseAvatar => '选择头像';

  @override
  String get handle => 'ID';

  @override
  String get enterHandle => '请输入 ID';

  @override
  String get handleValid => '✓ 格式可用';

  @override
  String get handleRule => '请输入 3–20 个英文字母、数字或下划线。';

  @override
  String get chooseEmoji => '选一个代表你的表情';

  @override
  String get pickFromAlbum => '从相册选择照片';

  @override
  String get errDetailLoad => '无法加载详细信息。';

  @override
  String get errContextLoad => '无法加载口味和关注信息。';

  @override
  String get detailSwipeHint => '⌃  上滑查看介绍 · 帖子';

  @override
  String get hoursUnknown => '营业时间待确认';

  @override
  String get openNow => '营业中';

  @override
  String get closedNow => '已打烊';

  @override
  String get locating => '正在定位';

  @override
  String get checkDistance => '查看距离';

  @override
  String pindPostCount(int count) {
    return 'Pind 帖子 $count 篇';
  }

  @override
  String get reviewCountUnknown => '评价数待确认';

  @override
  String reviewCountLong(int count) {
    return '评价 $count 条';
  }

  @override
  String get tasteMatchHelp =>
      '按你的第 1·2·3 优先项以 50·30·20% 计算公开平均分。1 分为该项 0%，5 分为 100%。';

  @override
  String get tasteMatchUnrated => '我的口味：评价不足';

  @override
  String tasteMatchMine(int percent) {
    return '我的口味 $percent%';
  }

  @override
  String axisNoRatingsDot(String criterion) {
    return '$criterion · 暂无评价';
  }

  @override
  String axisAverageDot(String criterion, String score) {
    return '$criterion · 店铺平均 $score / 5';
  }

  @override
  String axisNoRatings(String criterion) {
    return '$criterion：暂无评价';
  }

  @override
  String axisAverage(String criterion, String score) {
    return '$criterion：店铺平均 $score 分';
  }

  @override
  String friendsVisitedPlace(String names, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$names 等 $others 人去过',
      zero: '$names 去过',
    );
    return '$_temp0';
  }

  @override
  String followingSaved(int count) {
    return '$count 位关注的人收藏了';
  }

  @override
  String placePhotoLabel(String place, int number) {
    return '$place 照片 $number';
  }

  @override
  String photoBy(String name) {
    return '照片：$name';
  }

  @override
  String get photoSource => '照片来源';

  @override
  String get intro => '介绍';

  @override
  String oneLineSummaryTitle(String axes) {
    return '$axes 一句话总结';
  }

  @override
  String get noOneLiners => '还没有一句话评价。';

  @override
  String get noIntro => '暂无介绍。';

  @override
  String dataBy(String source) {
    return '信息提供：$source';
  }

  @override
  String get saved => '已收藏';

  @override
  String get directions => '路线';

  @override
  String get errWalkRoute => '未找到步行路线，请稍后重试。';

  @override
  String get errLocationUseSearch => '无法获取当前位置，可以继续使用搜索。';

  @override
  String get walkFinding => '正在查找步行路线…';

  @override
  String get walkArrived => '已到达';

  @override
  String get walkRerouting => '正在重新规划路线…';

  @override
  String walkRemaining(String distance, int minutes) {
    return '$distance · 约 $minutes 分钟';
  }

  @override
  String walkTo(String place) {
    return '步行前往 $place';
  }

  @override
  String get walkEnd => '结束导航';

  @override
  String get openSearch => '打开搜索';

  @override
  String get mapSearchHint => '想吃点什么？';

  @override
  String get editTaste => '编辑口味';

  @override
  String get mapLoadFailed => '无法加载地图。';

  @override
  String get mapFallbackHint => '可以通过地点搜索和列表浏览。';

  @override
  String get needsBackend => '设置连接后即可浏览地点。';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '缩小';

  @override
  String get myLocation => '当前位置';

  @override
  String get newPost => '发布帖子';

  @override
  String get addPhotos => '添加照片';

  @override
  String get visitedRestaurant => '去过的餐厅';

  @override
  String get ratings => '评分';

  @override
  String get ratingsRequired => '口味 · 分量 · 氛围（必填）';

  @override
  String get myAverageRating => '我的平均评分';

  @override
  String get writeReview => '写点什么';

  @override
  String get optional => '选填';

  @override
  String get visibility => '公开范围';

  @override
  String get visibilityPublic => '所有人';

  @override
  String get visibilityFriends => '仅好友';

  @override
  String get visibilityPublicHint => 'Pind 上的所有人都能看到';

  @override
  String get visibilityFriendsHint => '只有关注你的人能看到';

  @override
  String get reviewHint => '如果用家乡菜来比喻会是什么？请以第一次品尝的外国人身份留下真实评价。';

  @override
  String errorPrefix(String message) {
    return '错误：$message';
  }

  @override
  String get publish => '发布';

  @override
  String photoLongPressDelete(int number) {
    return '照片 $number，长按删除';
  }

  @override
  String get pickVisitedRestaurant => '请选择去过的餐厅';

  @override
  String get change => '更改';

  @override
  String get rateBest => '超棒';

  @override
  String get rateTasty => '好吃';

  @override
  String get rateOkay => '还行';

  @override
  String get rateMeh => '有点可惜';

  @override
  String get rateBad => '不太好';

  @override
  String get portionHuge => '超多';

  @override
  String get portionGenerous => '挺多';

  @override
  String get portionJustRight => '刚好';

  @override
  String get portionSmall => '偏少';

  @override
  String get portionTiny => '很少';

  @override
  String get rateGood => '不错';

  @override
  String get suggestSpicyLevels => '可以选辣度的餐厅';

  @override
  String get suggestKoreanBbq => '氛围好的韩式烤肉店';

  @override
  String get suggestNepali => '尼泊尔人常去的餐厅';

  @override
  String get suggestVegetarian => '素食';

  @override
  String get suggestKoreanVietnamese => '韩式越南菜';

  @override
  String get suggestSoloDrinks => '适合一个人小酌的店';

  @override
  String get suggestPho => '氛围好的越南河粉店';

  @override
  String get suggestSeongsuBar => '首尔圣水洞氛围好的酒吧';

  @override
  String get suggestHomeStyle => '有韩国家常菜味道的餐厅';

  @override
  String get suggestTouristFavorite => '游客最常去的餐厅';

  @override
  String get placeKorean => '家常菜馆';

  @override
  String get placeBarbecue => '烤肉店';

  @override
  String get placeSoup => '汤饭店';

  @override
  String get placeNoodles => '面馆';

  @override
  String get placeStreet => '小吃店';

  @override
  String get placeJapanese => '日料店';

  @override
  String get placeSushi => '寿司店';

  @override
  String get placeChinese => '中餐馆';

  @override
  String get placeWestern => '意面店';

  @override
  String get placeAsian => '越南河粉店';

  @override
  String get placeChicken => '炸鸡店';

  @override
  String get placeDessert => '甜品咖啡馆';

  @override
  String get placeBakery => '面包店';

  @override
  String get placeBar => '酒馆';

  @override
  String get qualityTaste => '好吃';

  @override
  String get qualityAmbience => '氛围好';

  @override
  String get qualityValue => '性价比高';

  @override
  String get qualityPortion => '分量足';

  @override
  String get qualityService => '干净又亲切';

  @override
  String get qualityPhotogenic => '出片';

  @override
  String get qualityQuiet => '安静';

  @override
  String get qualityParking => '好停车';

  @override
  String get occasionPhraseSolo => '适合一个人吃';

  @override
  String get occasionPhraseFriends => '适合和朋友去';

  @override
  String get occasionPhraseDate => '适合约会';

  @override
  String get occasionPhraseFamily => '适合家庭聚餐';

  @override
  String get occasionPhraseGroup => '适合聚餐';

  @override
  String get occasionPhraseWork => '适合办公学习';

  @override
  String get occasionPhraseDrinks => '适合小酌';

  @override
  String get occasionPhraseQuick => '可以快速吃完';

  @override
  String get genericRestaurant => '餐厅';

  @override
  String get genericDining => '餐厅';

  @override
  String get genericCafe => '咖啡馆';

  @override
  String get genericBar => '酒馆';

  @override
  String get suggestForMe => '推荐我可能喜欢的地方';

  @override
  String suggestQuality(String quality, String place) {
    return '$quality的$place';
  }

  @override
  String suggestOccasion(String phrase, String place) {
    return '$phrase的$place';
  }

  @override
  String get cat00 => '韩式套餐';

  @override
  String get cat01 => '咖啡馆';

  @override
  String get cat02 => '餐酒馆';

  @override
  String get cat03 => '紫菜包饭·小吃';

  @override
  String get cat04 => '烤猪肉·炖猪肉';

  @override
  String get cat05 => '面包·甜甜圈';

  @override
  String get cat06 => '生鱼片·寿司';

  @override
  String get cat07 => '简餐西餐';

  @override
  String get cat08 => '炸鸡';

  @override
  String get cat09 => '汤·炖锅';

  @override
  String get cat10 => '中餐馆';

  @override
  String get cat11 => '披萨';

  @override
  String get cat12 => '面条·刀切面';

  @override
  String get cat13 => '生啤专门店';

  @override
  String get cat14 => '酒吧';

  @override
  String get cat15 => '生鱼片店';

  @override
  String get cat16 => '烤海鲜·蒸海鲜';

  @override
  String get cat17 => '越南菜';

  @override
  String get cat18 => '其他简餐店';

  @override
  String get cat19 => '烤肥肠·肥肠火锅';

  @override
  String get cat20 => '烤鸡鸭·炖鸡鸭';

  @override
  String get cat21 => '猪蹄·菜包肉';

  @override
  String get cat22 => '年糕·韩式点心';

  @override
  String get cat23 => '汉堡';

  @override
  String get cat24 => '烤牛肉·炖牛肉';

  @override
  String get cat25 => '食堂';

  @override
  String get cat26 => '麻辣烫·火锅';

  @override
  String get cat27 => '吐司·三明治·沙拉';

  @override
  String get cat28 => '冷面';

  @override
  String get cat29 => '日式面食';

  @override
  String get cat30 => '日式咖喱·炸猪排·盖饭';

  @override
  String get cat31 => '冰淇淋·刨冰';

  @override
  String get cat32 => '意面·牛排';

  @override
  String get cat33 => '其他西餐厅';

  @override
  String get cat34 => '其他韩餐厅';

  @override
  String get cat35 => '韩式煎饼';

  @override
  String get cat36 => '自助餐';

  @override
  String get cat37 => '其他日料店';

  @override
  String get cat38 => '其他东南亚菜';

  @override
  String get cat39 => '舞厅酒吧';

  @override
  String get cat40 => '家庭餐厅';

  @override
  String get cat41 => '河豚料理';

  @override
  String get cat42 => '其他异国料理';

  @override
  String get errQueryNotUnderstood => '没能理解你的搜索内容，换个说法试试。';

  @override
  String get errOutsideKoreaMap => '请将地图移动到韩国境内。';

  @override
  String get errPlaceNotFound => '找不到该地点。';

  @override
  String get errPlaceServerRetry => '无法连接地点数据库，请稍后重试。';

  @override
  String get errRouteKoreaOnly => '仅支持韩国境内的起点和终点导航。';

  @override
  String get errRouteTooFar => '太远了，不适合步行。';

  @override
  String get errRouteUnavailable => '路线导航即将推出。';

  @override
  String get errGoogleBusy => 'Google 搜索繁忙，请稍后重试。';

  @override
  String agentNotice(String label) {
    return '按“$label”搜索。';
  }

  @override
  String get agentNoticeTaste => '按你的口味推荐。';

  @override
  String agentNoticeTasteFoods(String foods) {
    return '按你的口味推荐：$foods。';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'Pind';

  @override
  String get navMap => '地圖';

  @override
  String get navCompose => '發布';

  @override
  String get navMyPage => '我的';

  @override
  String get loginTagline => '只看合你口味的美食，盡在地圖上';

  @override
  String get loginKakao => '用 Kakao 3 秒開始';

  @override
  String get loginApple => '透過 Apple 繼續';

  @override
  String get loginGoogle => '透過 Google 繼續';

  @override
  String get loginPreview => '免登入體驗';

  @override
  String get authOpenFailed => '無法開啟登入頁面，請再試一次。';

  @override
  String get authAnonymousDisabled => '未啟用開發用匿名登入。';

  @override
  String get authPreviewFailed => '無法開始體驗。';

  @override
  String get authUnavailable => '無法連線至登入服務，請稍後再試。';

  @override
  String get back => '返回';

  @override
  String get clear => '清除';

  @override
  String postPhotoOpen(int number) {
    return '查看貼文照片 $number';
  }

  @override
  String ratingScore(String criterion, int score) {
    return '$criterion $score 分';
  }

  @override
  String get postDelete => '刪除貼文';

  @override
  String get postDeleteTitle => '要刪除這篇貼文嗎？';

  @override
  String get postDeleteBody => '照片和評分也會一併刪除，且無法復原。';

  @override
  String get delete => '刪除';

  @override
  String get close => '關閉';

  @override
  String get qrCameraDenied => '無法使用相機，請在設定中允許相機權限。';

  @override
  String get qrNotPind => '這不是 Pind 好友碼';

  @override
  String get qrHint => '請將好友的 Pind QR 碼對準方框';

  @override
  String get qrTitle => '掃描好友碼';

  @override
  String get linkCopied => '已複製連結。';

  @override
  String get shareMyCode => '分享我的代碼';

  @override
  String get profileLoadFailed => '無法載入個人檔案。';

  @override
  String get retry => '重試';

  @override
  String get kakaoTalk => 'KakaoTalk';

  @override
  String get instagram => 'Instagram';

  @override
  String get copyLink => '複製連結';

  @override
  String get scanFriendCode => '掃描好友碼';

  @override
  String get myQrCode => '我的 Pind QR 碼';

  @override
  String copyLinkLabel(String link) {
    return '複製連結 $link';
  }

  @override
  String shareTitle(String name) {
    return '$name 的 Pind';
  }

  @override
  String get shareBody => '來看看 TA 的美食口味地圖';

  @override
  String get viewProfile => '查看個人頁面';

  @override
  String get inviteToPind => '邀請好友加入 Pind';

  @override
  String get criterionTaste => '口味';

  @override
  String get criterionTasteHint => '食材與烹飪水準';

  @override
  String get criterionAmbience => '氛圍·空間';

  @override
  String get criterionAmbienceHint => '裝潢與座位';

  @override
  String get criterionValue => 'CP值';

  @override
  String get criterionValueHint => '物有所值';

  @override
  String get criterionPortion => '份量';

  @override
  String get criterionPortionHint => '一餐吃得飽';

  @override
  String get criterionService => '衛生·服務';

  @override
  String get criterionServiceHint => '待客與衛生';

  @override
  String get criterionPhotogenic => '好拍';

  @override
  String get criterionPhotogenicHint => '值得拍照的地方';

  @override
  String get criterionQuiet => '安靜';

  @override
  String get criterionQuietHint => '適合聊天';

  @override
  String get criterionParking => '停車';

  @override
  String get criterionParkingHint => '方便停車';

  @override
  String get occasionSolo => '一個人吃飯';

  @override
  String get occasionSoloHint => '一個人也自在';

  @override
  String get occasionFriends => '和朋友';

  @override
  String get occasionFriendsHint => '熱鬧聚會';

  @override
  String get occasionDate => '約會';

  @override
  String get occasionDateHint => '有氛圍的地方';

  @override
  String get occasionFamily => '家庭聚餐';

  @override
  String get occasionFamilyHint => '寬敞安靜';

  @override
  String get occasionGroup => '聚餐·聚會';

  @override
  String get occasionGroupHint => '有團體座位';

  @override
  String get occasionWork => '辦公·讀書';

  @override
  String get occasionWorkHint => '有插座和 Wi-Fi';

  @override
  String get occasionDrinks => '小酌一杯';

  @override
  String get occasionDrinksHint => '營業到很晚';

  @override
  String get occasionQuick => '趕時間';

  @override
  String get occasionQuickHint => '上菜快';

  @override
  String get cuisineKorean => '韓式料理·家常飯';

  @override
  String get cuisineBarbecue => '烤肉';

  @override
  String get cuisineSoup => '湯·燉鍋';

  @override
  String get cuisineNoodles => '麵食';

  @override
  String get cuisineStreet => '小吃';

  @override
  String get cuisineJapanese => '日式料理';

  @override
  String get cuisineSushi => '壽司·生魚片';

  @override
  String get cuisineChinese => '中式料理';

  @override
  String get cuisineWestern => '西式·義大利麵';

  @override
  String get cuisineAsian => '東南亞料理';

  @override
  String get cuisineChicken => '炸雞';

  @override
  String get cuisineDessert => '咖啡·甜點';

  @override
  String get cuisineBakery => '烘焙';

  @override
  String get cuisineBar => '酒館·酒吧';

  @override
  String get pindUser => 'Pind 使用者';

  @override
  String get photoProvider => '照片提供者';

  @override
  String get sourceSbiz => '小工商業者市場振興公團';

  @override
  String get kakaoMap => 'Kakao 地圖';

  @override
  String get naverMap => 'Naver 地圖';

  @override
  String get unsupportedSource => '不支援此地點來源。';

  @override
  String get sourceOpenData => '公共資料原始來源';

  @override
  String get viewOnMap => '在地圖上查看';

  @override
  String get directionsInGoogle => '在 Google 地圖中導航';

  @override
  String get viewInKakao => '在 Kakao 地圖中查看';

  @override
  String get searchInNaver => '在 Naver 地圖中搜尋';

  @override
  String friendsVisited(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name 等 $others 人去過',
      zero: '$name 去過',
    );
    return '$_temp0';
  }

  @override
  String friendsSaved(String name, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$name 等 $others 人收藏了',
      zero: '$name 收藏了',
    );
    return '$_temp0';
  }

  @override
  String get errProfileServer => '無法連線至個人檔案伺服器。';

  @override
  String get errSignInRequired => '需要登入。';

  @override
  String get errHandleTaken => '此 ID 已被使用。';

  @override
  String get errHandleImmutable => 'ID 一經設定便無法更改。';

  @override
  String get errProfileSave => '無法儲存個人檔案，請再試一次。';

  @override
  String get errProfileNotFound => '找不到此個人檔案。';

  @override
  String get errFeedServer => '無法連線至動態伺服器。';

  @override
  String get errNotificationsLoad => '無法載入通知。';

  @override
  String get errNotificationsRead => '無法將通知標為已讀。';

  @override
  String get errFeedLoad => '無法載入動態。';

  @override
  String get errLikeSignIn => '登入後才能按讚。';

  @override
  String get errFriendsServer => '無法連線至好友伺服器。';

  @override
  String get errSuggestionsLoad => '無法載入推薦清單。';

  @override
  String get errSearchFailed => '搜尋失敗。';

  @override
  String get errFollowersLoad => '無法載入粉絲。';

  @override
  String get errFollowingLoad => '無法載入追蹤清單。';

  @override
  String get errFollow => '追蹤失敗。';

  @override
  String get errUnfollow => '取消追蹤失敗。';

  @override
  String get errQueryLength => '請輸入 2–120 個字的搜尋詞。';

  @override
  String get errPlaceCheck => '無法確認此地點。';

  @override
  String get errPlaceSignIn => '瀏覽地點需要登入。';

  @override
  String get errSessionStart => '無法開始工作階段。';

  @override
  String get errPlaceLoad => '無法載入地點。';

  @override
  String get errPlaceServer => '無法連線至地點伺服器。';

  @override
  String get errPostSignIn => '請登入後發布貼文。';

  @override
  String get errPostServer => '無法連線至貼文伺服器。';

  @override
  String get errPostDeleteRetry => '無法刪除貼文，請再試一次。';

  @override
  String get errAccountChanged => '帳號已變更，請重新登入。';

  @override
  String get errPostPublishKept => '發布失敗。已保留您的內容，請再試一次。';

  @override
  String get inviteGeneric => '在 Pind 上互相追蹤彼此的美食口味吧！';

  @override
  String get errProfileLoadRetry => '無法載入個人檔案，請再試一次。';

  @override
  String get errPhotoUpload => '無法上傳照片，請再試一次。';

  @override
  String get errDistanceNeedsLocation => '顯示距離需要位置權限與裝置定位服務。';

  @override
  String get errLocationUnknown => '無法取得目前位置。';

  @override
  String get errSaveUnsupported => '尚不支援儲存此來源的地點，請在原始地圖中查看。';

  @override
  String get errSaveUnavailable => '無法使用收藏功能，請重新載入詳細資料。';

  @override
  String get errSaveRetry => '收藏失敗，請再試一次。';

  @override
  String get errLikeRetry => '按讚失敗，請再試一次。';

  @override
  String get errPostDelete => '無法刪除貼文。';

  @override
  String get errLinkOpen => '無法開啟連結，請再試一次。';

  @override
  String get errShareOpen => '無法開啟分享視窗。';

  @override
  String get errLoginIncomplete => '無法完成登入，請再試一次。';

  @override
  String get errPreviewRetry => '無法開始體驗，請再試一次。';

  @override
  String get errDraftSave => '無法儲存輸入內容，請再試一次。';

  @override
  String get locationSkipHint => '即使不允許定位，也可以從搜尋開始。';

  @override
  String get errLocationPermission => '無法確認定位權限，可以稍後設定。';

  @override
  String get errSettingsOpen => '無法開啟設定，請在裝置設定中允許定位。';

  @override
  String get errCheckInput => '請檢查輸入內容。';

  @override
  String get errLocationServicesOff => '請開啟裝置的定位服務。';

  @override
  String get errLocationDenied => '即使沒有定位權限，也可以移動地圖或搜尋。';

  @override
  String get errOutsideKorea => '您目前不在韓國，請搜尋韓國的地點。';

  @override
  String get errPhotoTooLarge => '請選擇每張 10MB 以下的照片。';

  @override
  String get errPhotoFormat => '請選擇支援的照片格式。';

  @override
  String get errPhotoLoad => '無法載入照片。';

  @override
  String get errPlaceSearchSignIn => '請登入後搜尋餐廳。';

  @override
  String get errPostPublish => '發布失敗。';

  @override
  String get errConnectionRetry => '請檢查網路連線後再試一次。';

  @override
  String inviteFollow(String who, String link) {
    return '在 Pind 上追蹤 $who，一起分享美食口味吧！\n$link';
  }

  @override
  String agoWeeks(int n) {
    return '$n 週前';
  }

  @override
  String agoDays(int n) {
    return '$n 天前';
  }

  @override
  String get yesterday => '昨天';

  @override
  String agoHours(int n) {
    return '$n 小時前';
  }

  @override
  String agoMinutes(int n) {
    return '$n 分鐘前';
  }

  @override
  String get justNow => '剛剛';

  @override
  String get notifications => '通知';

  @override
  String unreadCount(int count) {
    return '$count 則未讀';
  }

  @override
  String get markAllRead => '全部已讀';

  @override
  String get noNotifications => '目前沒有通知。';

  @override
  String get notifLikeRest => ' 按讚了你的貼文';

  @override
  String get notifVisitMid => ' 去了 ';

  @override
  String get restaurant => '餐廳';

  @override
  String get notifVisitEnd => '';

  @override
  String get notifFollowRest => ' 追蹤了你';

  @override
  String get following => '追蹤中';

  @override
  String get followBack => '回追蹤';

  @override
  String get follow => '追蹤';

  @override
  String unfollowLabel(String label) {
    return '$label，取消追蹤';
  }

  @override
  String unfollowTitle(String name) {
    return '要取消追蹤 $name 嗎？';
  }

  @override
  String get unfollowBody => '取消後也可以隨時重新追蹤。';

  @override
  String get unfollow => '取消追蹤';

  @override
  String tasteMatchPercent(int percent) {
    return '口味 $percent% 契合';
  }

  @override
  String unfollowName(String name) {
    return '取消追蹤 $name';
  }

  @override
  String followName(String name) {
    return '追蹤 $name';
  }

  @override
  String get errListLoad => '無法載入清單。';

  @override
  String get tryAgainPlease => '請再試一次。';

  @override
  String peopleCount(int count) {
    return '$count 人';
  }

  @override
  String get followers => '粉絲';

  @override
  String get noFollowers => '還沒有粉絲。';

  @override
  String get noFollowing => '還沒有追蹤任何人。';

  @override
  String get signOutTitle => '要登出嗎？';

  @override
  String get signOutBody => '重新登入後，貼文和收藏的地點都還在。';

  @override
  String get signOut => '登出';

  @override
  String get errSignOut => '無法登出，請再試一次。';

  @override
  String get profileSettings => '個人檔案設定';

  @override
  String get changePhoto => '更換照片';

  @override
  String get noHandle => '無 ID';

  @override
  String get handleLocked => 'ID 無法更改';

  @override
  String get name => '名字';

  @override
  String get statusMessage => '狀態訊息';

  @override
  String get statusHint => '寫下今天的心情吧';

  @override
  String get save => '儲存';

  @override
  String get addFriend => '新增好友';

  @override
  String get newNotifications => '新通知';

  @override
  String get exploreFriendsTaste => '探索好友的口味';

  @override
  String get inviteFriends => '邀請好友';

  @override
  String get shareFriendsTaste => '和好友分享美食口味';

  @override
  String get invite => '邀請';

  @override
  String get noPostsYet => '還沒有貼文。';

  @override
  String get postDeleted => '貼文已刪除。';

  @override
  String get unlike => '收回讚';

  @override
  String get like => '讚';

  @override
  String searchResultsCount(int count) {
    return '搜尋結果 $count 人';
  }

  @override
  String get searchResults => '搜尋結果';

  @override
  String get noSearchResults => '沒有搜尋結果。';

  @override
  String get cantFindSomeone => '沒找到想找的人？';

  @override
  String get inviteByLink => '透過連結邀請';

  @override
  String get shareMyCodeAction => '分享我的代碼';

  @override
  String get inviteByLinkHint => '用連結邀請好友';

  @override
  String get similarTaste => '口味相近的人';

  @override
  String get noSimilarTaste => '暫時沒有口味相近的人。';

  @override
  String get searchIdOrName => '搜尋 ID 或名字';

  @override
  String get seeMore => '查看更多 ›';

  @override
  String get agentStepRead => '正在分析你輸入的內容';

  @override
  String get agentStepPlaces => '正在查看有貼文的地點';

  @override
  String get agentStepTaste => '正在搜尋符合你口味的地點';

  @override
  String get errSearchRetry => '搜尋失敗，請稍後再試。';

  @override
  String get errSaveToggle => '無法變更收藏狀態，請再試一次。';

  @override
  String get agentTitle => '專屬美食搜尋';

  @override
  String get agentSubtitle => '越詳細描述你的口味，推薦就越準確。';

  @override
  String recommendedCount(int count) {
    return '推薦地點 $count 個';
  }

  @override
  String get agentNoResults => '在有貼文的地點中沒有找到合適的，換個說法試試？';

  @override
  String get askAnything => '隨便問問吧...';

  @override
  String get voiceSearch => '語音搜尋';

  @override
  String get search => '搜尋';

  @override
  String get voiceComingSoon => '語音搜尋即將推出。';

  @override
  String get rankingFromMapCenter => '無法取得目前位置，以下為地圖中心 10 公里內的結果。';

  @override
  String get rankingEmpty => '10 公里內還沒有有貼文的地點。';

  @override
  String get sortByTaste => '依我的口味';

  @override
  String reviewsCount(int count) {
    return '評論 $count';
  }

  @override
  String get unsave => '取消收藏';

  @override
  String get taste => '口味';

  @override
  String ratingScoreText(String criterion, String score) {
    return '$criterion $score 分';
  }

  @override
  String get backToMap => '返回地圖';

  @override
  String get checkLocationInSettings => '在設定中檢查定位權限';

  @override
  String get allowLocationStart => '允許定位並開始';

  @override
  String get later => '以後再說';

  @override
  String get locationTitle => '先帶你看看\n你附近的地方';

  @override
  String get locationBody => '允許定位後，就能探索你附近的美食和口味。';

  @override
  String get nearbyFood => '我附近的美食';

  @override
  String get nearbyFoodHint => '只推薦附近範圍內的店';

  @override
  String get friendsFood => '好友的美食';

  @override
  String get friendsFoodHint => '可以看到好友去過的餐廳';

  @override
  String get localRanking => '附近排行';

  @override
  String get localRankingHint => '像「聖水洞第 1 名」這樣的區域排名';

  @override
  String get recentlyViewed => '最近瀏覽的地點';

  @override
  String get recentlyViewedEmpty => '最近 24 小時內瀏覽的地點會顯示在這裡。';

  @override
  String get savedPlaces => '收藏的地點';

  @override
  String get noSavedPlaces => '還沒有收藏的地點。';

  @override
  String get noSharedSaves => '沒有分享的收藏地點。';

  @override
  String get noPlacesToShow => '沒有可顯示的地點。';

  @override
  String get settings => '設定';

  @override
  String get posts => '貼文';

  @override
  String get myMap => '我的地圖';

  @override
  String get badgeFoodie => '美食達人';

  @override
  String get badgePoster => '發文王';

  @override
  String get badgeJudge => '美食鑑定師';

  @override
  String get badges => '徽章';

  @override
  String get myMapTitle => '我的地圖';

  @override
  String get noPostsWritten => '還沒有發布過貼文';

  @override
  String get mapUnavailable => '無法使用地圖';

  @override
  String get viewMap => '查看地圖 ›';

  @override
  String get myTaste => '我的口味';

  @override
  String tasteType(String criterion) {
    return '$criterion至上型';
  }

  @override
  String get edit => '✎ 編輯';

  @override
  String get tasteEmpty => '設定口味後會顯示在這裡。';

  @override
  String get noPublicTaste => '沒有公開的口味。';

  @override
  String tasteOrder(String first, String second, String third) {
    return '先看$first，再看$second·$third。';
  }

  @override
  String agoYears(int n) {
    return '$n 年前';
  }

  @override
  String agoMonths(int n) {
    return '$n 個月前';
  }

  @override
  String savedAgo(String ago) {
    return '$ago收藏';
  }

  @override
  String get sortRecentSaved => '最近收藏';

  @override
  String placesCount(int count) {
    return '$count 個';
  }

  @override
  String get onboardingTitlePriorities => '選餐廳時\n你最看重什麼？';

  @override
  String get onboardingTitleOccasions => '請選擇你的外出用餐情境。';

  @override
  String get onboardingTitleCuisines => '請選擇你喜歡的。';

  @override
  String get onboardingHintPriorities => '只選 3 個，依序按 50% · 30% · 20% 計算。';

  @override
  String get onboardingHintOccasions => '最多 3 個，為你產生合適情境的清單。';

  @override
  String get onboardingHintCuisines => '請至少選 3 個，選得越多推薦越準確。';

  @override
  String get onboardingPickThree => '請選出 3 個最重要的標準。';

  @override
  String prioritiesOrder(String order) {
    return '將按 $order 的順序計算';
  }

  @override
  String selectedCount(int count) {
    return '已選 $count 個';
  }

  @override
  String get previous => '上一步';

  @override
  String onboardingStep(int step) {
    return '口味設定 第 $step / 3 步';
  }

  @override
  String get saving => '儲存中…';

  @override
  String get buildTasteMap => '建立我的口味地圖';

  @override
  String get next => '下一步';

  @override
  String rankLabel(int rank) {
    return '第 $rank';
  }

  @override
  String get filterNearby => '📍 目前位置附近';

  @override
  String get filterRecent => '最近去過';

  @override
  String get filterSaved => '已收藏';

  @override
  String get categoryAll => '全部';

  @override
  String get categoryCafe => '咖啡廳';

  @override
  String get categoryBar => '酒館';

  @override
  String get categoryMeat => '烤肉';

  @override
  String get categoryNoodles => '麵食';

  @override
  String get categoryDessert => '甜點';

  @override
  String get errRestaurantSearch => '無法搜尋餐廳。';

  @override
  String get errLocationCheckPermission => '無法取得目前位置，請檢查定位權限。';

  @override
  String get notInRecent => '不在最近去過的地點中。';

  @override
  String get noRecentViews => '最近 24 小時內沒有瀏覽過地點。';

  @override
  String get notInSaved => '不在收藏的地點中。';

  @override
  String get findingRestaurants => '正在尋找餐廳。';

  @override
  String noNearbyMatch(String distance) {
    return '附近 $distance 內沒有符合的餐廳。';
  }

  @override
  String get searchByNameOrAddress => '請用餐廳名稱或地址搜尋。';

  @override
  String get whereDidYouGo => '你去了哪裡？';

  @override
  String get nameOrAddress => '餐廳名稱或地址';

  @override
  String selectPlace(String name) {
    return '選擇 $name';
  }

  @override
  String get select => '選擇';

  @override
  String get errProfileOpen => '無法開啟個人頁面。';

  @override
  String get postPublished => '已發布。';

  @override
  String postPhotoOf(int number, int total) {
    return '貼文照片 $number/$total';
  }

  @override
  String get noPostsYetMine => '你還沒有發布貼文。';

  @override
  String get share => '分享';

  @override
  String get errTasteSave => '無法儲存口味，請再試一次。';

  @override
  String countrySelected(String country) {
    return '已選擇 $country';
  }

  @override
  String get countryTitle => '請選擇\n國家或地區';

  @override
  String get countryBody => '將同時設定服務地區、語言與貨幣顯示。';

  @override
  String get countrySearch => '搜尋國家或地區';

  @override
  String get countryPopular => '常選國家或地區';

  @override
  String get countryKoreaOnly => '目前美食探索僅在韓國提供。';

  @override
  String get basicTitle => '請告訴我們\n你的基本資料';

  @override
  String get basicBody => '僅用於推薦同齡人喜歡的餐廳。\n不會公開在個人頁面上。';

  @override
  String get enterName => '請輸入名字';

  @override
  String get gender => '性別';

  @override
  String get male => '男';

  @override
  String get female => '女';

  @override
  String get preferNotToSay => '不選擇';

  @override
  String get birthDate => '出生日期';

  @override
  String ageBand(int age, int decade, String part) {
    String _temp0 = intl.Intl.selectLogic(part, {
      'early': '出頭',
      'mid': '中段',
      'other': '後段',
    });
    return '$age 歲 · $decade 多歲$_temp0';
  }

  @override
  String get ageUsedFor => '用於同齡人口味推薦';

  @override
  String get ageMinimum => '年滿 14 歲方可使用。';

  @override
  String get consentPrivacy => '同意蒐集與使用個人資料（必選）';

  @override
  String get consentPrivacyBody => '名字、性別和出生日期僅用於基本資料和口味推薦，不會顯示在公開頁面上。';

  @override
  String get consentAge => '我已年滿 14 歲（必選）';

  @override
  String get consentAgeBody => '請確認出生日期，年滿 14 歲時勾選。';

  @override
  String get consentPersonalize => '將資料用於個人化推薦（可選）';

  @override
  String get consentPersonalizeBody => '不勾選也可以使用基本服務和地點搜尋。';

  @override
  String get year => '年';

  @override
  String get month => '月';

  @override
  String get day => '日';

  @override
  String viewDetails(String title) {
    return '查看$title';
  }

  @override
  String get startPind => '開始使用 Pind';

  @override
  String get handleTitle => '我們該\n怎麼稱呼你？';

  @override
  String get handleBody => 'ID 之後無法更改，暱稱可以隨時修改。';

  @override
  String get chooseAvatar => '選擇頭像';

  @override
  String get handle => 'ID';

  @override
  String get enterHandle => '請輸入 ID';

  @override
  String get handleValid => '✓ 格式可用';

  @override
  String get handleRule => '請輸入 3–20 個英文字母、數字或底線。';

  @override
  String get chooseEmoji => '選一個代表你的表情符號';

  @override
  String get pickFromAlbum => '從相簿選擇照片';

  @override
  String get errDetailLoad => '無法載入詳細資料。';

  @override
  String get errContextLoad => '無法載入口味與追蹤資訊。';

  @override
  String get detailSwipeHint => '⌃  上滑查看介紹 · 貼文';

  @override
  String get hoursUnknown => '營業時間待確認';

  @override
  String get openNow => '營業中';

  @override
  String get closedNow => '已打烊';

  @override
  String get locating => '正在定位';

  @override
  String get checkDistance => '查看距離';

  @override
  String pindPostCount(int count) {
    return 'Pind 貼文 $count 篇';
  }

  @override
  String get reviewCountUnknown => '評論數待確認';

  @override
  String reviewCountLong(int count) {
    return '評論 $count 則';
  }

  @override
  String get tasteMatchHelp =>
      '按你的第 1·2·3 優先項以 50·30·20% 計算公開平均分。1 分為該項 0%，5 分為 100%。';

  @override
  String get tasteMatchUnrated => '我的口味：評價不足';

  @override
  String tasteMatchMine(int percent) {
    return '我的口味 $percent%';
  }

  @override
  String axisNoRatingsDot(String criterion) {
    return '$criterion · 尚無評價';
  }

  @override
  String axisAverageDot(String criterion, String score) {
    return '$criterion · 店家平均 $score / 5';
  }

  @override
  String axisNoRatings(String criterion) {
    return '$criterion：尚無評價';
  }

  @override
  String axisAverage(String criterion, String score) {
    return '$criterion：店家平均 $score 分';
  }

  @override
  String friendsVisitedPlace(String names, int others) {
    String _temp0 = intl.Intl.pluralLogic(
      others,
      locale: localeName,
      other: '$names 等 $others 人去過',
      zero: '$names 去過',
    );
    return '$_temp0';
  }

  @override
  String followingSaved(int count) {
    return '$count 位追蹤的人收藏了';
  }

  @override
  String placePhotoLabel(String place, int number) {
    return '$place 照片 $number';
  }

  @override
  String photoBy(String name) {
    return '照片：$name';
  }

  @override
  String get photoSource => '照片來源';

  @override
  String get intro => '介紹';

  @override
  String oneLineSummaryTitle(String axes) {
    return '$axes 一句話總結';
  }

  @override
  String get noOneLiners => '還沒有一句話評價。';

  @override
  String get noIntro => '暫無介紹。';

  @override
  String dataBy(String source) {
    return '資訊提供：$source';
  }

  @override
  String get saved => '已收藏';

  @override
  String get directions => '路線';

  @override
  String get errWalkRoute => '找不到步行路線，請稍後再試。';

  @override
  String get errLocationUseSearch => '無法取得目前位置，可以繼續使用搜尋。';

  @override
  String get walkFinding => '正在尋找步行路線…';

  @override
  String get walkArrived => '已抵達';

  @override
  String get walkRerouting => '正在重新規劃路線…';

  @override
  String walkRemaining(String distance, int minutes) {
    return '$distance · 約 $minutes 分鐘';
  }

  @override
  String walkTo(String place) {
    return '步行前往 $place';
  }

  @override
  String get walkEnd => '結束導航';

  @override
  String get openSearch => '開啟搜尋';

  @override
  String get mapSearchHint => '想吃點什麼？';

  @override
  String get editTaste => '編輯口味';

  @override
  String get mapLoadFailed => '無法載入地圖。';

  @override
  String get mapFallbackHint => '可以透過地點搜尋和清單瀏覽。';

  @override
  String get needsBackend => '設定連線後即可瀏覽地點。';

  @override
  String get zoomIn => '放大';

  @override
  String get zoomOut => '縮小';

  @override
  String get myLocation => '目前位置';

  @override
  String get newPost => '發布貼文';

  @override
  String get addPhotos => '新增照片';

  @override
  String get visitedRestaurant => '去過的餐廳';

  @override
  String get ratings => '評分';

  @override
  String get ratingsRequired => '口味 · 份量 · 氛圍（必填）';

  @override
  String get myAverageRating => '我的平均評分';

  @override
  String get writeReview => '寫點什麼';

  @override
  String get optional => '選填';

  @override
  String get visibility => '公開範圍';

  @override
  String get visibilityPublic => '所有人';

  @override
  String get visibilityFriends => '僅好友';

  @override
  String get visibilityPublicHint => 'Pind 上的所有人都能看到';

  @override
  String get visibilityFriendsHint => '只有追蹤你的人能看到';

  @override
  String get reviewHint => '如果用家鄉菜來比喻會是什麼？請以第一次品嚐的外國人身分留下真實評價。';

  @override
  String errorPrefix(String message) {
    return '錯誤：$message';
  }

  @override
  String get publish => '發布';

  @override
  String photoLongPressDelete(int number) {
    return '照片 $number，長按刪除';
  }

  @override
  String get pickVisitedRestaurant => '請選擇去過的餐廳';

  @override
  String get change => '變更';

  @override
  String get rateBest => '超棒';

  @override
  String get rateTasty => '好吃';

  @override
  String get rateOkay => '還行';

  @override
  String get rateMeh => '有點可惜';

  @override
  String get rateBad => '不太好';

  @override
  String get portionHuge => '超多';

  @override
  String get portionGenerous => '挺多';

  @override
  String get portionJustRight => '剛好';

  @override
  String get portionSmall => '偏少';

  @override
  String get portionTiny => '很少';

  @override
  String get rateGood => '不錯';

  @override
  String get suggestSpicyLevels => '可以選辣度的餐廳';

  @override
  String get suggestKoreanBbq => '氛圍好的韓式烤肉店';

  @override
  String get suggestNepali => '尼泊爾人常去的餐廳';

  @override
  String get suggestVegetarian => '素食';

  @override
  String get suggestKoreanVietnamese => '韓式越南菜';

  @override
  String get suggestSoloDrinks => '適合一個人小酌的店';

  @override
  String get suggestPho => '氛圍好的越南河粉店';

  @override
  String get suggestSeongsuBar => '首爾聖水洞氛圍好的酒吧';

  @override
  String get suggestHomeStyle => '有韓國家常菜味道的餐廳';

  @override
  String get suggestTouristFavorite => '遊客最常去的餐廳';

  @override
  String get placeKorean => '家常菜館';

  @override
  String get placeBarbecue => '烤肉店';

  @override
  String get placeSoup => '湯飯店';

  @override
  String get placeNoodles => '麵館';

  @override
  String get placeStreet => '小吃店';

  @override
  String get placeJapanese => '日式料理店';

  @override
  String get placeSushi => '壽司店';

  @override
  String get placeChinese => '中餐館';

  @override
  String get placeWestern => '義大利麵店';

  @override
  String get placeAsian => '越南河粉店';

  @override
  String get placeChicken => '炸雞店';

  @override
  String get placeDessert => '甜點咖啡廳';

  @override
  String get placeBakery => '麵包店';

  @override
  String get placeBar => '酒館';

  @override
  String get qualityTaste => '好吃';

  @override
  String get qualityAmbience => '氛圍好';

  @override
  String get qualityValue => 'CP值高';

  @override
  String get qualityPortion => '份量足';

  @override
  String get qualityService => '乾淨又親切';

  @override
  String get qualityPhotogenic => '好拍';

  @override
  String get qualityQuiet => '安靜';

  @override
  String get qualityParking => '好停車';

  @override
  String get occasionPhraseSolo => '適合一個人吃';

  @override
  String get occasionPhraseFriends => '適合和朋友去';

  @override
  String get occasionPhraseDate => '適合約會';

  @override
  String get occasionPhraseFamily => '適合家庭聚餐';

  @override
  String get occasionPhraseGroup => '適合聚餐';

  @override
  String get occasionPhraseWork => '適合辦公讀書';

  @override
  String get occasionPhraseDrinks => '適合小酌';

  @override
  String get occasionPhraseQuick => '可以快速吃完';

  @override
  String get genericRestaurant => '餐廳';

  @override
  String get genericDining => '餐廳';

  @override
  String get genericCafe => '咖啡廳';

  @override
  String get genericBar => '酒館';

  @override
  String get suggestForMe => '推薦我可能喜歡的地方';

  @override
  String suggestQuality(String quality, String place) {
    return '$quality的$place';
  }

  @override
  String suggestOccasion(String phrase, String place) {
    return '$phrase的$place';
  }

  @override
  String get cat00 => '韓式套餐';

  @override
  String get cat01 => '咖啡廳';

  @override
  String get cat02 => '餐酒館';

  @override
  String get cat03 => '紫菜飯捲·小吃';

  @override
  String get cat04 => '烤豬肉·燉豬肉';

  @override
  String get cat05 => '麵包·甜甜圈';

  @override
  String get cat06 => '生魚片·壽司';

  @override
  String get cat07 => '簡餐西餐';

  @override
  String get cat08 => '炸雞';

  @override
  String get cat09 => '湯·燉鍋';

  @override
  String get cat10 => '中餐館';

  @override
  String get cat11 => '披薩';

  @override
  String get cat12 => '麵食·刀削麵';

  @override
  String get cat13 => '生啤專門店';

  @override
  String get cat14 => '酒吧';

  @override
  String get cat15 => '生魚片店';

  @override
  String get cat16 => '烤海鮮·蒸海鮮';

  @override
  String get cat17 => '越南料理';

  @override
  String get cat18 => '其他簡餐店';

  @override
  String get cat19 => '烤腸·腸火鍋';

  @override
  String get cat20 => '烤雞鴨·燉雞鴨';

  @override
  String get cat21 => '豬腳·菜包肉';

  @override
  String get cat22 => '年糕·韓式點心';

  @override
  String get cat23 => '漢堡';

  @override
  String get cat24 => '烤牛肉·燉牛肉';

  @override
  String get cat25 => '員工餐廳';

  @override
  String get cat26 => '麻辣燙·火鍋';

  @override
  String get cat27 => '吐司·三明治·沙拉';

  @override
  String get cat28 => '冷麵';

  @override
  String get cat29 => '日式麵食';

  @override
  String get cat30 => '日式咖哩·炸豬排·蓋飯';

  @override
  String get cat31 => '冰淇淋·剉冰';

  @override
  String get cat32 => '義大利麵·牛排';

  @override
  String get cat33 => '其他西餐廳';

  @override
  String get cat34 => '其他韓式餐廳';

  @override
  String get cat35 => '韓式煎餅';

  @override
  String get cat36 => '自助餐';

  @override
  String get cat37 => '其他日式餐廳';

  @override
  String get cat38 => '其他東南亞料理';

  @override
  String get cat39 => '舞廳酒吧';

  @override
  String get cat40 => '家庭餐廳';

  @override
  String get cat41 => '河豚料理';

  @override
  String get cat42 => '其他異國料理';

  @override
  String get errQueryNotUnderstood => '沒能理解你的搜尋內容，換個說法試試。';

  @override
  String get errOutsideKoreaMap => '請將地圖移動到韓國境內。';

  @override
  String get errPlaceNotFound => '找不到此地點。';

  @override
  String get errPlaceServerRetry => '無法連線至地點資料庫，請稍後再試。';

  @override
  String get errRouteKoreaOnly => '僅支援韓國境內的起點與終點導航。';

  @override
  String get errRouteTooFar => '太遠了，不適合步行。';

  @override
  String get errRouteUnavailable => '路線導航即將推出。';

  @override
  String get errGoogleBusy => 'Google 搜尋忙碌中，請稍後再試。';

  @override
  String agentNotice(String label) {
    return '按「$label」搜尋。';
  }

  @override
  String get agentNoticeTaste => '按你的口味推薦。';

  @override
  String agentNoticeTasteFoods(String foods) {
    return '按你的口味推薦：$foods。';
  }
}
