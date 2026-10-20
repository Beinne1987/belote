// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'بلوت';

  @override
  String get teamUs => 'نحن';

  @override
  String get teamThem => 'هم';

  @override
  String get bidNone => 'لا ضمانة';

  @override
  String get bidAkwins => 'أكوينس';

  @override
  String get bidPass => 'تمرير';

  @override
  String get bidYours => 'ضمانتك';

  @override
  String get turnYours => 'دورك الآن';

  @override
  String get bidSans => 'صن';

  @override
  String get bidTout => 'تو';

  @override
  String get suitTrefle => 'أتريف';

  @override
  String get suitCarreau => 'كارو';

  @override
  String get suitCoeur => 'كير';

  @override
  String get suitPique => 'أبيك';

  @override
  String get rankNameA => 'الآس';

  @override
  String get rankName10 => 'الديس';

  @override
  String get rankNameK => 'أرواه';

  @override
  String get rankNameQ => 'الضم';

  @override
  String get rankNameJ => 'الفالة';

  @override
  String get rankName9 => 'النيف';

  @override
  String get rankName8 => 'الويت';

  @override
  String get rankName7 => 'الست';

  @override
  String cardName(String rank, String suit) {
    return '$rank $suit';
  }

  @override
  String foujaCardHint(String card) {
    return '$card — مخالفة';
  }

  @override
  String bidWithAkwins(String bid) {
    return '$bid · أكوينس';
  }

  @override
  String get phaseDealing => 'التوزيع';

  @override
  String get phaseBidding => 'الضمانة';

  @override
  String get followSuitRequired => 'يجب اتباع اللون';

  @override
  String get rankBeginner => 'مبتدئ';

  @override
  String get rankPro => 'محترف';

  @override
  String get rankExpert => 'خبير';

  @override
  String get rankLegend => 'أسطوريّ';

  @override
  String get seatYou => 'أنت';

  @override
  String get seatOpponent => 'الخصم';

  @override
  String get seatPartner => 'الشريك';

  @override
  String get roundOver => 'انتهت الجولة';

  @override
  String get roundNew => 'جولة جديدة';

  @override
  String get matchNew => 'مباراة جديدة';

  @override
  String get backToMenu => 'القائمة';

  @override
  String get rating => 'التصنيف';

  @override
  String get roundValue => 'قيمة الجولة';

  @override
  String get matchWonUs => 'فزتم بالمباراة!';

  @override
  String get matchWonThem => 'فاز الخصم بالمباراة';

  @override
  String get matchTiebreak => 'تعادل — جولة فاصلة';

  @override
  String get openRuleTie => 'قاعدة مفتوحة: تعادل الأكوينس (نادر — لا حسم)';

  @override
  String get fouja => 'فوجة';

  @override
  String get foujaWho => 'من عمل الفوجة؟';

  @override
  String get opponentRight => 'الخصم يمينك';

  @override
  String get opponentLeft => 'الخصم يسارك';

  @override
  String get cancel => 'إلغاء';

  @override
  String get foujaCancel => 'إلغاء الفوجة';

  @override
  String foujaClaimedBy(String name) {
    return '$name يعترض بالفوجة…';
  }

  @override
  String get foujaWonUs => 'فوجة — لكم نقاط الضمانة';

  @override
  String get foujaWonThem => 'فوجة — للخصم نقاط الضمانة';

  @override
  String get reasonChute => 'سقطت الضمانة';

  @override
  String get reasonAkwins => 'أكوينس';

  @override
  String get reasonWhite => 'جولة بيضاء!';

  @override
  String get reasonMade => 'نجحت الضمانة';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageFrench => 'الفرنسية';

  @override
  String get exitGame => 'خروج من اللعبة';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsName => 'الاسم';

  @override
  String get settingsTheme => 'الثيم';

  @override
  String get settingsSound => 'الصوت';

  @override
  String get howToPlay => 'كيف تلعب';

  @override
  String get supportSection => 'الدعم الفنّي';

  @override
  String get supportEmail => 'البريد الإلكتروني';

  @override
  String get openFailed => 'تعذّر الفتح على هذا الجهاز.';

  @override
  String get save => 'حفظ';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get serverUnreachable => 'تعذّر الاتصال بالخادم';

  @override
  String get friendsFetchFailed => 'تعذّر جلبُ الأصدقاء';

  @override
  String get noFriendsYet => 'لا أصدقاءَ بعد — أضفهم من شاشة الأصدقاء برمزهم.';

  @override
  String get invitePartnerPays => 'ادعُ شريكًا — يدفع رسمَه عند قبوله';

  @override
  String get unknownInitial => '؟';

  @override
  String get tournaments => 'البطولات';

  @override
  String get signInForTournaments => 'سجّل الدخول للمشاركة في البطولات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get createYourEvent => 'أنشئ مسابقتك';

  @override
  String get createEventSubtitle => 'باسمك وبرسمٍ تحدّده — رسم الإنشاء 50💎';

  @override
  String get create => 'أنشئ';

  @override
  String get newEvent => 'مسابقة جديدة';

  @override
  String get eventName => 'اسم المسابقة';

  @override
  String get entryFeeField => 'رسم الدخول (10–500 💎)';

  @override
  String get sizeLabel => 'الحجم:';

  @override
  String teamsCount(int count) {
    return '$count فرق';
  }

  @override
  String eventSchedule(String date, String time) {
    return 'الموعد: $date · $time';
  }

  @override
  String get createEventTerms =>
      'رسم الإنشاء 50💎 غير مستردّ. رسوم المشاركين صندوقُ الفائزين (البيت يقتطع 20%) — لا نصيبَ للمنشئ منها؛ المسابقة باسمك.';

  @override
  String get createEventConfirm => 'أنشئ المسابقة — 50💎';

  @override
  String hoursMinutes(int h, int m) {
    return '$h س $m د';
  }

  @override
  String get eventLive => 'جارية الآن';

  @override
  String get eventPlayerMade => 'مسابقة لاعب';

  @override
  String get eventOfficial => 'فعاليّة';

  @override
  String eventOrganizer(String name) {
    return 'ينظّمها: $name';
  }

  @override
  String eventStats(int fee, int players, int size, int pool) {
    return 'الدخول: $fee💎  ·  المسجّلون: $players/$size  ·  الصندوق: $pool💎';
  }

  @override
  String startsIn(String time) {
    return 'تبدأ بعد $time';
  }

  @override
  String partnerInviteEvent(String name) {
    return '$name يدعوك شريكًا له في هذه الفعاليّة 🤝';
  }

  @override
  String get accept => 'اقبل';

  @override
  String get decline => 'ارفض';

  @override
  String get withdrawRefund => 'انسحب واسترد رسمك';

  @override
  String get invitePartner => 'ادعُ شريكًا';

  @override
  String registerForFee(int fee) {
    return 'سجّل — $fee💎';
  }

  @override
  String yourPartner(String name) {
    return 'شريكك: $name 🤝';
  }

  @override
  String get cancelMyEvent => 'ألغِ مسابقتك';

  @override
  String cancelEventTitle(String title) {
    return 'إلغاء «$title»؟';
  }

  @override
  String cancelEventBody(int players) {
    return 'تُردُّ رسومُ المسجّلين ($players) كاملةً. رسمُ الإنشاء (50💎) لا يعود.';
  }

  @override
  String get back => 'تراجُع';

  @override
  String get cancelEventConfirm => 'ألغِ المسابقة';

  @override
  String get lastTournamentChampions => 'أبطال آخر بطولة';

  @override
  String partnerInvite(String name) {
    return '$name يدعوك شريكًا له 🤝';
  }

  @override
  String get partnerInviteRegistered =>
      'بقبولك تُثبَّتان شريكين على طاولةٍ واحدة.';

  @override
  String partnerInviteWillPay(int fee) {
    return 'بقبولك تُسجَّل وتدفع رسمَك ($fee💎) وتُثبَّتان شريكين.';
  }

  @override
  String get todaysTournament => 'بطولة اليوم';

  @override
  String knockoutSize(int size) {
    return 'إقصائيّة $size';
  }

  @override
  String tournamentStats(int fee, int pool) {
    return 'الدخول: $fee💎 للشخص  ·  الصندوق حتى الآن: $pool💎';
  }

  @override
  String get tournamentPayoutNote =>
      'الزوج الفائز يقتسم الصندوق — والذكاء يكمل النقص عند البدء.';

  @override
  String startsWithin(String time) {
    return 'تبدأ خلال $time';
  }

  @override
  String registeredCount(int players, int size) {
    return 'المسجّلون $players/$size';
  }

  @override
  String withPartner(String name) {
    return 'مع $name';
  }

  @override
  String get enterYourTable => 'ادخل طاولتك الآن';

  @override
  String get roundFinal => 'النهائيّ';

  @override
  String get roundSemi => 'نصف النهائيّ';

  @override
  String get roundQuarter => 'ربع النهائيّ';

  @override
  String roundOfN(int n) {
    return 'دور الـ$n';
  }

  @override
  String get roundGeneric => 'جولة';

  @override
  String roundProgress(int done, int total) {
    return 'حُسمت $done من $total مباراة';
  }

  @override
  String get yourMatchShown => ' — تُعرَض مباراتُك';

  @override
  String get nextRoundPending =>
      'الجولة التالية تُبنى فور حسم مبارياتها الرافدة…';

  @override
  String get matchLive => 'جارية';

  @override
  String get versus => 'ضدّ';

  @override
  String get botPlayer => 'ذكاء';

  @override
  String get playerFallback => 'لاعب';

  @override
  String reportPlayer(String name) {
    return 'بلاغ عن $name';
  }

  @override
  String blockPlayer(String name) {
    return 'حظر $name';
  }

  @override
  String get blockPlayerNote => 'لا يصلك كلامه، ولا يراسلك ولا يدعوك.';

  @override
  String get reportSent => 'وصل بلاغك — سيُراجَع.';

  @override
  String playerBlocked(String name) {
    return 'حُظر $name — لن يصلك كلامه.';
  }

  @override
  String get blockFailed => 'تعذّر الحظر — تحقّق من الاتّصال.';

  @override
  String get errInviteOffline =>
      'صديقك غير متّصل ولا تصله الإشعارات — لن يعلم بدعوتك حتى يفتح اللعبة.';

  @override
  String get errInviteNotFriend => 'أضِفه صديقًا أوّلًا لتدعوه.';

  @override
  String get errInviteSeatTaken => 'المقعد شُغل — اختر غيره.';

  @override
  String get errInviteStarted => 'المباراة بدأت — لا يمكن دعوة أحدٍ الآن.';

  @override
  String get errInviteNotPrivate =>
      'الدعوة للطاولة الخاصّة فقط — أنشئ واحدةً ثمّ ادعُه.';

  @override
  String get errGiftInsufficient => 'ماسك لا يكفي لهذه الهديّة.';

  @override
  String get errGiftNotOnTable => 'لم يعد على الطاولة.';

  @override
  String get errGiftSelf => 'لا تُهدي نفسك.';

  @override
  String get errGiftUnknown => 'هذه الهديّة لم تعد متاحة.';

  @override
  String get errVipGiftEmpty => 'نفدت هدايا VIP اليوم — تعود ثلاثٌ غدًا.';

  @override
  String get errVipGiftNotVip => 'هذه الهدايا لمشتركي VIP.';

  @override
  String get inviteRewardMsg => 'صديقُك انضمّ — نلتَ لعبةً إضافيّةً اليوم! 🎉';

  @override
  String get errGeneric => 'تعذّر تنفيذ ما طلبت — حاول مرّةً أخرى.';

  @override
  String spectatingCount(int count) {
    return 'تشاهد · $count';
  }

  @override
  String get enteringStands => 'جاري الدخول إلى المدرّجات…';

  @override
  String get reconnecting => 'إعادة الاتصال…';

  @override
  String get playOnline => 'اللعب أونلاين';

  @override
  String get logout => 'خروج';

  @override
  String get quickMatch => 'لعب سريع';

  @override
  String get quickMatchSub => 'اجلس على أول طاولة متاحة مع لاعبين';

  @override
  String get createPrivateTable => 'إنشاء طاولة خاصّة';

  @override
  String get createPrivateTableSub => 'ادعُ أصدقاءك برمز الطاولة';

  @override
  String get tableCode => 'رمز الطاولة';

  @override
  String get joinByCode => 'انضمام برمز';

  @override
  String get seatRolePartner => 'شريكًا لك';

  @override
  String get seatRoleOpponent => 'خصمًا لك';

  @override
  String invitedPlayer(String name) {
    return 'دُعي $name';
  }

  @override
  String get privateTable => 'طاولة خاصّة';

  @override
  String get quickMatchTitle => 'مطابقة سريعة';

  @override
  String tableCodeIs(String code) {
    return 'الرمز: $code';
  }

  @override
  String get startMatch => 'ابدأ المباراة';

  @override
  String get searchingPlayers => 'جاري البحث عن لاعبين…';

  @override
  String get searchingPlayersSub => 'نبحث لك عن منافسين على الطاولة';

  @override
  String get errServerFull => 'الخوادم ممتلئة الآن — حاول بعد قليل.';

  @override
  String get errSpectateUnavailable =>
      'انتهت هذه المباراة أو لم تعد متاحة للمشاهدة.';

  @override
  String get errSpectateSeated => 'أنت على طاولةٍ الآن — غادرها ثم شاهد.';

  @override
  String get errPlayLimit =>
      'انتهت لعباتُك اليوم — تعود غدًا. والعبُ مع الذكاء بلا حدود.';

  @override
  String get errJoinFailed => 'تعذّر الانضمام — تحقّق من الرمز.';

  @override
  String get errNoSeat => 'لا مقعد متاح على هذه الطاولة.';

  @override
  String get errUnauthorized => 'انتهت الجلسة — سجّل الدخول من جديد.';

  @override
  String get errConnection => 'انقطع الاتصال بالخادم.';

  @override
  String get errUnexpected => 'حدث خطأ غير متوقّع.';

  @override
  String get goBack => 'رجوع';

  @override
  String invitesYouToTable(String name) {
    return '$name يدعوك إلى طاولته';
  }

  @override
  String get later => 'لاحقًا';

  @override
  String get join => 'انضمّ';

  @override
  String get fillingSeatsNote =>
      'نبحث عن لاعبين للمقاعد الفارغة… وإن لم نجد بدأنا بلاعبي الذكاء.';

  @override
  String get playerDefaultName => 'اللاعب';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLeaderboard => 'التصنيف';

  @override
  String get navStore => 'المتجر';

  @override
  String get navFriends => 'الأصدقاء';

  @override
  String get navAbout => 'حول اللعبة';

  @override
  String get quickPlayOffline => 'لعب سريع';

  @override
  String get quickPlayOfflineSub => 'ضدّ الذكاء — بلا اتصال';

  @override
  String get vipActiveSub => 'اشتراكُك قائم — مزاياك كلُّها معك';

  @override
  String get vipOfferSub => 'مجلسٌ خاصّ · إطارٌ · هدايا · لعبٌ بلا حدود';

  @override
  String get missions => 'المهامّ';

  @override
  String get missionsSub => 'يوميّة وأسبوعيّة — خبرةٌ وماس';

  @override
  String get tournamentsSub => 'بطولة اليوم · فعاليات بجوائز';

  @override
  String get liveMatches => 'مباريات حيّة';

  @override
  String get liveMatchesSub => 'شاهد الجاري الآن · شجّع بالهدايا';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get offline => 'غير متصل';

  @override
  String get signIn => 'دخول';

  @override
  String get onlineNeedsSignIn => 'مع لاعبين حقيقيّين — يتطلّب دخولًا';

  @override
  String get onlineWithPlayers => 'مع لاعبين حقيقيّين';

  @override
  String graceUnlimited(String left) {
    return 'أهلًا بك! لعبٌ بلا حدود — الباقي: $left';
  }

  @override
  String unlimitedLeft(String left) {
    return 'لعبٌ بلا حدود — الباقي: $left';
  }

  @override
  String bonusFromInvites(int bonus) {
    return ' (منها $bonus من دعوة أصدقائك)';
  }

  @override
  String gamesLeftToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت لك $count لعباتٍ اليوم',
      two: 'بقيت لك لعبتان اليوم',
      one: 'بقيت لك لعبةٌ واحدةٌ اليوم',
      zero: 'انتهت لعباتُك اليوم — تعود غدًا',
    );
    return '$_temp0';
  }

  @override
  String get expired => 'انتهت';

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أيّام',
      two: 'يومان',
      one: 'يومٌ واحد',
    );
    return '$_temp0';
  }

  @override
  String hoursLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ساعات',
      two: 'ساعتان',
      one: 'ساعةٌ واحدة',
      zero: 'أقلُّ من ساعة',
    );
    return '$_temp0';
  }

  @override
  String get myProfile => 'ملفّي';

  @override
  String get signInToSeeProfile => 'سجّل الدخول لعرض ملفّك وإحصائياتك';

  @override
  String get signInAction => 'تسجيل الدخول';

  @override
  String get statWinRate => 'نسبة الفوز';

  @override
  String get statMatches => 'المباريات';

  @override
  String get statWins => 'الفوز';

  @override
  String get statLosses => 'الخسارة';

  @override
  String get statBestStreak => 'أفضل سلسلة';

  @override
  String get statCurrentStreak => 'السلسلة الحالية';

  @override
  String get profilePhoto => 'صورة الملفّ';

  @override
  String get pickFromGallery => 'اختر من الصور';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get deletePhoto => 'احذف الصورة';

  @override
  String get photoPermissionError => 'تعذّر فتح الصور. تحقّق من الأذونات.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get deleteAccount => 'حذف الحساب نهائيًّا';

  @override
  String get signOutNote => 'يبقى حسابك كما هو، وتعود إليه بهاتفك وكلمة سرّك.';

  @override
  String get backAction => 'تراجع';

  @override
  String get signOutConfirm => 'اخرج';

  @override
  String deleteFailed(String reason) {
    return 'تعذّر الحذف: $reason';
  }

  @override
  String get levelLabel => 'المستوى ';

  @override
  String xpToNext(int xp) {
    return '$xp خبرة للتالي';
  }

  @override
  String get myWallet => 'محفظتي';

  @override
  String get diamonds => 'الماس';

  @override
  String get myGifts => 'هداياي';

  @override
  String get noGiftsYet => 'لا هدايا بعد — اشترِ باقةً من المتجر.';

  @override
  String get deleteAccountBody =>
      'يزول اسمك ورمزك وماسك وتصنيفك وأصدقاؤك. لا رجعة في هذا.\nيبقى رقمك متاحًا لحسابٍ جديدٍ إن أردت العودة.';

  @override
  String get typeYourTagToConfirm => 'اكتب رمزك للتأكيد:';

  @override
  String get deleteAccountConfirm => 'احذف حسابي';

  @override
  String get addByTag => 'إضافة بالرمز';

  @override
  String get blockedList => 'المحظورون';

  @override
  String get signInToSeeFriends => 'سجّل الدخول لترى أصدقاءك.';

  @override
  String get friendsFetchFailedShort => 'تعذّر جلب الأصدقاء.';

  @override
  String get incomingRequests => 'يطلبون صداقتك';

  @override
  String get yourFriends => 'أصدقاؤك';

  @override
  String get awaitingReply => 'بانتظار ردّهم';

  @override
  String get online => 'متصل';

  @override
  String get chat => 'محادثة';

  @override
  String get acceptShort => 'اقبل';

  @override
  String get nowFriends => 'صرتما صديقين';

  @override
  String get declineShort => 'ارفض';

  @override
  String get removeFriendAction => 'احذف من الأصدقاء';

  @override
  String get cancelRequest => 'اسحب الطلب';

  @override
  String get removeFriendTitle => 'حذف صديق';

  @override
  String removeFriendBody(String name) {
    return 'تحذف $name من أصدقائك؟';
  }

  @override
  String get deleteShort => 'احذف';

  @override
  String get requestDeclined => 'رُفض الطلب';

  @override
  String get friendRemoved => 'حُذف الصديق';

  @override
  String get requestWithdrawn => 'سُحب الطلب';

  @override
  String get retryAction => 'أعِد المحاولة';

  @override
  String get listFetchFailed => 'تعذّر جلب القائمة.';

  @override
  String get nobodyBlocked => 'لا أحدَ محظور.';

  @override
  String get unblock => 'فكّ الحظر';

  @override
  String get requestSent => 'أُرسل الطلب';

  @override
  String get addByTagHint => 'اطلب من صاحبك رمزه (٦ خانات) من ملفّه الشخصيّ.';

  @override
  String get sendRequest => 'أرسل الطلب';

  @override
  String get storeFetchFailed => 'تعذّر جلب المتجر';

  @override
  String bundlePurchased(int qty, String gift) {
    return 'نالك $qty× $gift';
  }

  @override
  String notEnoughForBundle(int price) {
    return 'ماسك لا يكفي — الباقة $price💎';
  }

  @override
  String get purchaseFailed => 'تعذّر الشراء';

  @override
  String get connectionFailed => 'تعذّر الاتّصال';

  @override
  String get unlimitedEnjoy => 'لعبٌ بلا حدودٍ — استمتع!';

  @override
  String notEnoughForTicket(int price) {
    return 'ماسك لا يكفي — التذكرة $price💎';
  }

  @override
  String get storeTitle => 'المتجر';

  @override
  String get retryShort => 'إعادة';

  @override
  String get tabPlay => 'اللعب';

  @override
  String get tabGifts => 'الهدايا';

  @override
  String get tabDiamonds => 'الماس';

  @override
  String get storeEmpty => 'لا بضاعةَ في المتجر الآن.';

  @override
  String get ticketsIntro => 'العب بلا حدودٍ طوال المدّة — أنت وأصدقاؤك.';

  @override
  String get unlimitedActiveNotice =>
      'لديك لعبٌ بلا حدودٍ الآن. أيُّ شراءٍ يمدّده من نهايته.';

  @override
  String get cheaperThanSevenDays => 'أوفرُ من سبع تذاكرِ يوم';

  @override
  String get ticketFullDay => 'يومٌ كامل — 24 ساعة';

  @override
  String get ticketFullWeek => 'أسبوعٌ كامل — 7 أيّام';

  @override
  String ticketDays(int days) {
    return '$days أيّام';
  }

  @override
  String ticketHours(int hours) {
    return '$hours ساعة';
  }

  @override
  String get giftsIntro => 'اشترِ الآن، وأهدِ متى شئت.';

  @override
  String get diamondsIntro =>
      'كلُّ ماسةٍ بأوقيّة. والباقةُ الأكبر تُعطيك أكثر.';

  @override
  String get bankilySoon => 'الشراء عبر بنكيلي — قريبًا.';

  @override
  String bonusPct(int pct) {
    return 'هديّة $pct%';
  }

  @override
  String priceOuguiya(int price) {
    return '$price أوقية';
  }

  @override
  String ownedCount(int count) {
    return 'تملك $count';
  }

  @override
  String savePct(int pct) {
    return 'وفّر $pct%';
  }

  @override
  String get missionDailyPlay => 'العب ثلاث مباريات';

  @override
  String get missionDailyWin => 'فُزْ بمباراة';

  @override
  String get missionDailyFriend => 'العب مع صديق';

  @override
  String get missionDailyGift => 'أهدِ هديّة';

  @override
  String get missionDailyFouja => 'اكشِف فوجةً واحدة';

  @override
  String get missionWeeklyPlay => 'العب عشرين مباراة';

  @override
  String get missionWeeklyWin => 'فُزْ بعشر مباريات';

  @override
  String get missionWeeklyFriend => 'العب ثلاث مباريات مع صديق';

  @override
  String get missionWeeklyInvite => 'ادعُ صديقًا إلى طاولتك';

  @override
  String get missionWeeklyGifts => 'أهدِ عشرَ هدايا';

  @override
  String get missionWeeklyRoom => 'أنشئ غرفةً خاصّة';

  @override
  String get missionWeeklyClean => 'العب عشرَ مبارياتٍ بلا فوجة';

  @override
  String get missionsUnavailable => 'المهامّ غير متاحةٍ الآن.';

  @override
  String get missionsFetchFailed => 'تعذّر جلب المهامّ';

  @override
  String missionRewardClaimed(int diamonds, int xp) {
    return 'نلت $diamonds💎 و$xp خبرة';
  }

  @override
  String get missionStateChanged => 'تغيّرت حالةُ المهمّة';

  @override
  String get claimFailed => 'تعذّر القبض';

  @override
  String get missionsDaily => 'يوميّة';

  @override
  String get missionsDailyReset => 'تُصفَّر كلَّ يوم';

  @override
  String get missionsWeekly => 'أسبوعيّة';

  @override
  String get missionsWeeklyReset => 'تُصفَّر كلَّ اثنين';

  @override
  String get xpSuffix => ' خبرة';

  @override
  String get claim => 'اقبض';

  @override
  String get vipFetchFailed => 'تعذّر جلب الاشتراك';

  @override
  String get vipWelcome => 'أهلًا بك في VIP!';

  @override
  String notEnoughForVip(int price) {
    return 'ماسك لا يكفي — الاشتراك $price💎';
  }

  @override
  String get subscribeFailed => 'تعذّر الاشتراك';

  @override
  String get vipExtend => 'مدّد اشتراكك';

  @override
  String get vipChoosePlan => 'اختر اشتراكك';

  @override
  String get vipFrameNote => 'إطارُك الخاصُّ يرافقك على كلّ طاولة';

  @override
  String vipActiveUntil(String date) {
    return 'أنت VIP — حتى $date';
  }

  @override
  String get vipPerkRoom => 'مجلسٌ خاصّ';

  @override
  String get vipPerkRoomSub => 'غرفتُك أنت وأصدقاؤك — لا يدخلها غريب.';

  @override
  String get vipPerkUnlimited => 'لعبٌ بلا حدود';

  @override
  String get vipPerkUnlimitedSub =>
      'انسَ الخمسَ لعبات — العب ما شئت طوال اشتراكك.';

  @override
  String vipPerkDiamonds(int gems) {
    return '$gems ماسةً كلَّ شهر';
  }

  @override
  String get vipPerkDiamondsSub => 'تصلك دفعةً شهريّةً ما دام اشتراكُك قائمًا.';

  @override
  String get vipPerkBadge => 'شارةُ VIP';

  @override
  String get vipPerkBadgeSub => 'ترافق اسمَك أينما جلست.';

  @override
  String get vipGiftsTitle => 'هدايا لا يملكها غيرُك';

  @override
  String get vipGiftsSub =>
      'ثلاثٌ كلَّ يومٍ مجّانًا — تُرسلها فيراها كلُّ من على الطاولة.';

  @override
  String get planYear => 'سنةٌ كاملة';

  @override
  String get planMonth => 'شهرٌ واحد';

  @override
  String saveVsMonthly(int pct) {
    return 'وفّر $pct% عن الشهريّ';
  }

  @override
  String get ruleBasicsTitle => 'الأساس';

  @override
  String get ruleBasicsBody =>
      'أربعة لاعبين، فريقان (المقعدان 0 و2 ضدّ 1 و3). 32 ورقة (من 7 إلى الآس). اتجاه اللعب عكس عقارب الساعة — التالي هو من على يمينك.';

  @override
  String get ruleDealTitle => 'التوزيع';

  @override
  String get ruleDealBody =>
      'يوزَّع 3 ثم 2، ثم دور الضمانة، ثم 3 أخيرة (8 لكل لاعب). يمين الموزّع أوّل من يضمن ويلعب، وهو موزّع الجولة القادمة.';

  @override
  String get ruleBidTitle => 'الضمانة';

  @override
  String get ruleBidBody =>
      'دورة واحدة بالضبط (4 أدوار). اللاعب الأول لا يمرّ. الرفع فقط — لا فتح دورة جديدة بعد الرفع. اللون المضمون هو الحكم.';

  @override
  String get ruleAkwinsTitle => 'الأكوينس';

  @override
  String get ruleAkwinsBody =>
      'للخصم فقط، في دوره فقط — يوقف الضمانة فورًا ويضاعف قيمة الجولة (32 للّون · 52 لصن/تو).';

  @override
  String get rulePlayTitle => 'اللعب';

  @override
  String get rulePlayBody =>
      'إن ملكتَ لون الافتتاح فالْزَمه. إن لم تملكه فالعب أي ورقة — ولا تُجبر على القصّ بالحكم ولا على تجاوز أعلى حكم.';

  @override
  String get ruleUnitsTitle => 'الوحدات';

  @override
  String get ruleUnitsBody =>
      'في الحكم: J=20 و9=14. في اللون العادي: J=2 و9=0. الآس 11، العشرة 10، K=4، Q=3، و8/7 صفر. صن/تو: كل الألوان بسُلَّم الحكم.';

  @override
  String get ruleFoujaTitle => 'الفوجة';

  @override
  String get ruleFoujaBody =>
      'عدم اتباع اللون رغم امتلاكه. للخصم أن يعترض متى اكتشفها؛ إن ثبتت أخذ المعترِض قيمة الضمانة كاملة، وإن كان الاتهام خاطئًا أخذها الطرف الآخر. وتتوقف الجولة فورًا.';

  @override
  String get ruleWinTitle => 'الفوز';

  @override
  String get ruleWinBody =>
      'أوّل من يبلغ 100 نقطة والأعلى يفوز بالمباراة. عند التعادل عند 100 فأكثر تُلعب جولة فاصلة.';

  @override
  String get momentMvp => 'رجل المباراة';

  @override
  String get momentBestBid => 'أفضل إعلان';

  @override
  String momentBestBidDetail(int points, int round) {
    return 'جنى $points نقطة في الجولة $round';
  }

  @override
  String get momentStrongestCard => 'أقوى ورقة';

  @override
  String momentStrongestCardDetail(int units) {
    return 'خطفت $units وحدةً في أبليٍّ واحد';
  }

  @override
  String get momentLongestStreak => 'أطول سلسلة';

  @override
  String momentLongestStreakDetail(int count) {
    return '$count أبالٍ متتاليةً بلا أن يقطعها أحد';
  }

  @override
  String get matchMoments => 'لحظات المباراة';

  @override
  String tricksCount(int count) {
    return '$count أبالٍ';
  }

  @override
  String unitsCount(int count) {
    return '$count وحدة';
  }

  @override
  String bidsWonCount(int count) {
    return 'وفّى بـ$count ضمانة';
  }

  @override
  String foujaCaughtCount(int count) {
    return 'كشف $count فوجة';
  }

  @override
  String bidWithAkwinsShort(String bid) {
    return '$bid أكوينس';
  }

  @override
  String youSuffix(String name) {
    return '$name (أنت)';
  }

  @override
  String get authTagline => 'العب مع أصدقائك حول العالم';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get desktopAuthNote =>
      'إنشاءُ الحساب واستعادةُ كلمة السرّ هنا للأرقام الموريتانيّة (+222)؛ والأرقامُ الأخرى من تطبيق الهاتف. وتسجيلُ الدخول يعمل كاملًا.';

  @override
  String get continueAsGuest => 'الدخول كضيف';

  @override
  String get invalidPhone => 'أدخل رقم هاتف صالحًا';

  @override
  String get phoneAuthUnsupported => 'الدخول بالهاتف غير مدعوم على هذه المنصّة';

  @override
  String get enterSixDigitCode => 'أدخل الرمز المكوَّن من ٦ أرقام';

  @override
  String get passwordTooShort => 'كلمة السرّ ٦ أحرف على الأقلّ';

  @override
  String get enterPassword => 'أدخل كلمة السرّ';

  @override
  String get enterYourName => 'أدخل اسمك';

  @override
  String get enterYourCity => 'أدخل مدينتك';

  @override
  String get resetPasswordTitle => 'استعادة كلمة السرّ';

  @override
  String get resetPasswordSub => 'أدخل رقمك لنرسل رمز تأكيد';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get codeTitle => 'رمز التأكيد';

  @override
  String codeSentTo(String phone) {
    return 'أدخل الرمز المُرسَل إلى $phone';
  }

  @override
  String get verify => 'تحقّق';

  @override
  String get newPasswordTitle => 'كلمة سرّ جديدة';

  @override
  String get newPasswordSub => 'اختر كلمة سرّ جديدة لحسابك';

  @override
  String get saveAndSignIn => 'حفظ ودخول';

  @override
  String get fieldPhone => 'رقم الهاتف';

  @override
  String get fieldNewPassword => 'كلمة السرّ الجديدة';

  @override
  String get fieldPassword => 'كلمة السرّ';

  @override
  String get fieldPasswordMin => 'كلمة السرّ (٦ أحرف على الأقلّ)';

  @override
  String get fieldName => 'الاسم';

  @override
  String get fieldCity => 'المدينة / الولاية';

  @override
  String get loginSub => 'ادخل برقم هاتفك وكلمة السرّ';

  @override
  String get forgotPassword => 'نسيت كلمة السرّ؟';

  @override
  String get noAccountCreateOne => 'ليس لديك حساب؟ أنشئ حسابًا';

  @override
  String get haveAccountSignIn => 'لديك حساب؟ سجّل الدخول';

  @override
  String get registerPhoneSub => 'سنرسل رمزًا لتأكيد رقمك';

  @override
  String get completeAccount => 'أكمل حسابك';

  @override
  String get completeAccountSub =>
      'كلمة سرّ للدخول لاحقًا، واسمك ودولتك ومدينتك';

  @override
  String get createAccountAction => 'إنشاء الحساب';

  @override
  String get dmConnectionFailed => 'تعذّر الاتّصال بالخادم.';

  @override
  String get sendFailed => 'تعذّر الإرسال — تحقّق من الاتّصال.';

  @override
  String blockTitle(String name) {
    return 'حظر $name؟';
  }

  @override
  String get blockBody =>
      'يُحذف من أصدقائك، ولا يراسلك ولا يدعوك، ولا يصلك كلامه على الطاولة.';

  @override
  String get blockConfirm => 'احظر';

  @override
  String get reportPlayerMenu => 'بلاغ عن اللاعب';

  @override
  String get blockMenu => 'حظر';

  @override
  String get writeMessageHint => 'اكتب رسالةً…';

  @override
  String get noMessagesYet => 'لا رسائلَ بعد — ابدأ الحديث.';

  @override
  String reportAbout(String name) {
    return 'بلاغ عن $name';
  }

  @override
  String get reportNote => 'يصل البلاغ إدارةَ اللعبة وتُراجعه بنفسها.';

  @override
  String get reportHint => 'ما الذي حدث؟ (اختياريّ)';

  @override
  String get giftRose => 'وردة';

  @override
  String get giftTea => 'أتاي';

  @override
  String get giftSweet => 'حلوى';

  @override
  String get giftCrown => 'تاج';

  @override
  String get giftCamel => 'جمل';

  @override
  String get giftCar => 'سيّارة';

  @override
  String get giftVipFlower => 'وردةُ VIP';

  @override
  String get giftVipBox => 'صندوقُ VIP';

  @override
  String get giftVipPitcher => 'بَراد VIP';

  @override
  String get giftTitle => 'إهداء';

  @override
  String get giftHumansOnly =>
      'الهدايا للاعبين البشر — ولا يجلس معك الآن غير الذكاء.\nادعُ صاحبك إلى طاولةٍ خاصّة لتُهديه.';

  @override
  String get giftToWhom => 'إلى مَن؟';

  @override
  String get giftToAll => 'للجميع';

  @override
  String get vipGifts => 'هدايا VIP';

  @override
  String remainingCount(int count) {
    return 'بقيت $count';
  }

  @override
  String get giftWhat => 'ماذا تُهدي؟';

  @override
  String giftAllCostNote(int count) {
    return 'تصل الهديّةُ إلى $count لاعبين — ويُخصم ثمنُها لكلٍّ منهم.';
  }

  @override
  String get giftCostNote => 'يُخصم الثمن من ماسك.';

  @override
  String get claimFailedRetry => 'تعذّر الاستلام — حاول ثانيةً';

  @override
  String get activateFailedRetry => 'تعذّر التفعيل — حاول ثانيةً';

  @override
  String get giftDayTitle => 'هديّةٌ منّا: يومٌ كامل';

  @override
  String get openFullDayTitle => 'افتح يومًا كاملًا';

  @override
  String get playLimitGiftBody =>
      'انتهت لعباتُك الخمسُ اليوم — وهذه أوّلُ مرّة. خذ 24 ساعةً بلا حدودٍ منّا، والعب ما شئت مع أصدقائك.';

  @override
  String get playLimitPlainBody => 'انتهت لعباتُك اليوم — تعود غدًا.';

  @override
  String get playLimitOfferBody =>
      'انتهت لعباتُك الخمسُ اليوم. فعّل اللعب بلا حدودٍ 24 ساعةً والعب ما شئت مع أصدقائك.';

  @override
  String get offlineAlwaysFree => 'واللعبُ مع الذكاء يبقى مجّانيًّا بلا حدود.';

  @override
  String get claimGift => 'استلم الهديّة';

  @override
  String get activateNow => 'فعّل الآن';

  @override
  String get yourTable => 'طاولتك';

  @override
  String get seatRoleYou => 'أنت';

  @override
  String get seatRoleYourPartner => 'شريكك';

  @override
  String get seatRoleYourOpponent => 'خصمك';

  @override
  String get inviteShort => 'ادعُ';

  @override
  String whoSitsHere(String role) {
    return 'من يجلس $role؟';
  }

  @override
  String get noFriendsAddByTag =>
      'لا أصدقاء بعد. أضِف صاحبك برمزه من شاشة الأصدقاء.';

  @override
  String get noFriendOnlineInviteAnyway =>
      'لا صديق متّصلٌ الآن — ادعُه على أيّ حال، يصله إشعارٌ على هاتفه.';

  @override
  String get offlineGroup => 'غير متّصلين';

  @override
  String get offlineWillBeNotified => 'غير متصل — يصله إشعار';

  @override
  String get welcomeTitle => 'أهلًا بك';

  @override
  String get welcomeGiftsBody => 'هذه هديّتُنا لك — أهدِها لمن تلعب معه.';

  @override
  String get thanks => 'شكرًا';

  @override
  String get aboutGameTitle => 'بيلوت';

  @override
  String get aboutMauritanianEdition => 'النسخة الموريتانية';

  @override
  String get aboutSection => 'عن اللعبة';

  @override
  String get aboutBody =>
      'بيلوت كما تُلعب في موريتانيا: أربعة لاعبين، فريقان، وضمانةٌ بدورةٍ واحدة، والأكوينس للخصم في دوره. قواعدُها كاملةً في «كيف تلعب».';

  @override
  String get aboutDevSection => 'برمجة وتطوير';

  @override
  String get aboutMadeWithLove => 'صُنعت بشغفٍ للعبة أهلها 🃏';

  @override
  String get aboutVersionSection => 'إصدار التطبيق';

  @override
  String get appInitial => 'ب';

  @override
  String get giveGift => 'أهدِه';

  @override
  String unmutePlayer(String name) {
    return 'إلغاء كتم $name';
  }

  @override
  String mutePlayer(String name) {
    return 'اكتم $name';
  }

  @override
  String get relFriend => 'صديقك';

  @override
  String get relOutgoing => 'بانتظار ردّه';

  @override
  String get relIncoming => 'اقبل صداقته';

  @override
  String get relAdd => 'أضِف صديقًا';

  @override
  String get signInToWatch => 'سجّل الدخول لمشاهدة المباريات.';

  @override
  String get liveFetchFailed => 'تعذّر جلب المباريات — تحقّق من الاتّصال.';

  @override
  String get refresh => 'تحديث';

  @override
  String get tournamentChip => 'بطولة';

  @override
  String get versusShort => 'ضد';

  @override
  String get watchMatch => 'شاهد المباراة';

  @override
  String updateNewVersion(String version) {
    return 'نسخة جديدة $version';
  }

  @override
  String get updateAvailable => 'تتوفّر نسخة أحدث من اللعبة.';

  @override
  String get updateFailed => 'تعذّر التحديث';

  @override
  String get installing => 'جارٍ التثبيت…';

  @override
  String downloading(int percent) {
    return 'جارٍ التنزيل… $percent%';
  }

  @override
  String get updateNow => 'تحديث الآن';

  @override
  String get voiceLive => 'صوتي مفتوح — اضغط لقطع الصوت';

  @override
  String get voiceConnecting => 'يتّصل…';

  @override
  String get voiceFailed => 'تعذّر الصوت — اضغط للمحاولة';

  @override
  String get voiceOff => 'الصوت مقطوع — اضغط لتتكلّم';

  @override
  String get giftToAllTip => 'هديّة للجميع';

  @override
  String giftToPlayer(String name) {
    return 'هديّة لِ$name';
  }

  @override
  String get markAllRead => 'تعليم الكلّ';

  @override
  String get agoNow => 'الآن';

  @override
  String agoMinutes(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String agoHours(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String agoDays(int count) {
    return 'منذ $count يوم';
  }

  @override
  String get honorBoardWeek => 'لوحة الشرف — هذا الأسبوع';

  @override
  String get seeAll => 'الكلّ';

  @override
  String get honorBoardNote =>
      'الأوّلُ في كلّ فئةٍ يحمل لقبَها طوال الأسبوع القادم — يراه كلُّ من يجلس معه.';

  @override
  String get honorBoard => 'لوحة الشرف';

  @override
  String get playerCardDemo => 'بطاقة اللاعب';

  @override
  String get playerCardDemoSub => 'عاديّة · نشطة (صاحب الدور)';

  @override
  String rankNextTitle(String title, String next) {
    return '$title · التالية: $next';
  }

  @override
  String get leaderboardFetchFailed => 'تعذّر جلب التصنيف';

  @override
  String get leaderboardEmpty =>
      'لا تصنيف بعد — العب مباريات أونلاين لتظهر هنا.';

  @override
  String matchesAndWins(int matches, int wins) {
    return '$matches مباراة · $wins فوز';
  }

  @override
  String get chatTitle => 'الدردشة';

  @override
  String get vipUpsellTitle => 'لماذا لا تصير VIP؟';

  @override
  String get vipUpsellBody =>
      'تشتري التذاكرَ كثيرًا — والشهرُ الكاملُ من VIP بثمن عشرِ تذاكرٍ فقط، ومعه لعبٌ بلا حدود، ومجلسٌ خاصّ، وهدايا حصريّة، و50💎 كلَّ شهر.';

  @override
  String get seeVip => 'شاهد VIP';

  @override
  String get friendFallback => 'صديقك';

  @override
  String invitesYou(String name) {
    return '$name يدعوك';
  }

  @override
  String get inviteToPrivateTable => 'إلى طاولته الخاصّة — مقعدٌ محجوزٌ لك.';

  @override
  String get nameEntryPrompt => 'أهلًا بك — اكتب اسمك للبدء';

  @override
  String get nameHint => 'اسمك';

  @override
  String get start => 'ابدأ';

  @override
  String profileOf(String name) {
    return 'ملفّ $name';
  }

  @override
  String get messagesTip => 'الرسائل';

  @override
  String get latestNews => 'آخر الأخبار';

  @override
  String rankedMatchesLeft(int count) {
    return 'تبقّت $count مباراةً مصنَّفةً للتصنيف';
  }

  @override
  String get ratingLabel => 'التصنيف ';

  @override
  String rankedMatchesLeftLong(int count) {
    return 'تبقّت $count مباراةً مصنَّفةً لتحصل على رتبتك';
  }

  @override
  String get rankTopReached =>
      'بلغتَ أعلى السُّلَّم — الأسطورةُ تُدافع لا تصعد';

  @override
  String rankPointsToNext(String title, int points) {
    return 'إلى $title: $points نقطة تصنيف';
  }

  @override
  String get reportAction => 'أبلِغ';

  @override
  String pointsCount(int count) {
    return '$count نقطة';
  }

  @override
  String get developerName => 'محمد الأمين / تقرة / بينة';

  @override
  String get languageArabicNative => 'العربية';

  @override
  String get demoNameOne => 'أحمدو';

  @override
  String get demoNameTwo => 'المختار';

  @override
  String get demoNameThree => 'سيدي أحمد';

  @override
  String get demoNameFour => 'بَبَّه';

  @override
  String get errFriendInvalidTag =>
      'الرمز غير صحيح — ٦ خانات كما تظهر في ملفّ صاحبك.';

  @override
  String get errFriendNotFound => 'لا لاعب بهذا الرمز. تأكّد منه.';

  @override
  String get errFriendSelf => 'هذا رمزك أنت.';

  @override
  String get errFriendAlready => 'بينكما طلبٌ أو صداقةٌ بالفعل.';

  @override
  String get errFriendNoRequest => 'لا طلبَ ينتظر ردَّك من هذا اللاعب.';

  @override
  String get errFriendNotFriend => 'لا علاقة بينكما أصلًا.';

  @override
  String get errMessageNotFriend =>
      'الرسائل بين الأصدقاء — أضفه صديقًا أوّلًا.';

  @override
  String get errMessageBlocked => 'لا يمكن مراسلة هذا اللاعب.';

  @override
  String get errMessageEmpty => 'اكتب رسالةً أوّلًا.';

  @override
  String get errBlockNotFound => 'اللاعب غير موجود.';

  @override
  String get errBlockSelf => 'لا تحظر نفسك.';

  @override
  String get errAvatarTooLarge => 'الصورة كبيرة. اختر واحدةً أصغر.';

  @override
  String get errAvatarBadType => 'هذا ليس ملفَّ صورة. اختر صورةً (JPG أو PNG).';

  @override
  String get errAvatarEmpty => 'الملفّ فارغ.';

  @override
  String get errTrnClosed => 'بطولةٌ جاريةٌ الآن — التسجيل بعد نهايتها.';

  @override
  String get errTrnAlreadyRegistered => 'أنت مسجَّلٌ أصلًا.';

  @override
  String get errTrnNotRegistered => 'لستَ مسجَّلًا في هذه البطولة.';

  @override
  String get errTrnFull => 'اكتمل العدد — بطولةٌ قادمةٌ تفتح قريبًا.';

  @override
  String get errTrnInsufficient => 'ماسُك لا يكفي لرسم الدخول.';

  @override
  String get errTrnNotFriends => 'الشراكة بين الأصدقاء — أضفه صديقًا أوّلًا.';

  @override
  String get errTrnPairTaken => 'لأحدكما شريكٌ أو دعوةٌ قائمة.';

  @override
  String get errTrnNoInvite => 'لا دعوةَ شراكةٍ قائمة.';

  @override
  String get errTrnBadRequest => 'طلبٌ غير صالح.';

  @override
  String get errTrnHasActiveEvent =>
      'لك مسابقةٌ قائمة — أكملها أو ألغِها أوّلًا.';

  @override
  String get errTrnBadTitle => 'الاسم من 3 إلى 30 حرفًا.';

  @override
  String get errTrnBadFee => 'رسم الدخول من 10 إلى 500 ماسة.';

  @override
  String get errTrnBadTeams => 'الحجم: 8 أو 16 فريقًا.';

  @override
  String get errTrnBadTime => 'الموعد بين 10 دقائق و7 أيّام من الآن.';

  @override
  String get chatSalam => 'سلامٌ عليكم';

  @override
  String get chatNice => 'لعبةٌ جميلة';

  @override
  String get chatBravo => 'أحسنت';

  @override
  String get chatLuck => 'بالتوفيق';

  @override
  String get chatHurry => 'أسرِع قليلًا';

  @override
  String get chatSorry => 'آسف';

  @override
  String get chatThanks => 'شكرًا';

  @override
  String get chatBye => 'إلى اللقاء';

  @override
  String get guestOnlineTitle => 'اللعب أونلاين';

  @override
  String get guestOnlineBody =>
      'أنشئ حسابًا للّعب مع لاعبين حقيقيّين وحفظ تقدّمك ورصيدك.';

  @override
  String get spectator => 'مشاهد';

  @override
  String giftSentTo(String from, String to) {
    return '$from أهدى $to';
  }

  @override
  String get voiceNotEnabled => 'الصوت غير مُفعَّلٍ على الخادم بعد.';

  @override
  String get voiceNotAtTable => 'لست على طاولة.';

  @override
  String get voiceSessionOver => 'انتهت جلستك — أعِد الدخول.';

  @override
  String get voiceConnectFailed =>
      'تعذّر الاتّصال بالصوت. تأكّد من إذن الميكروفون والشبكة.';

  @override
  String get errUnexpectedShort => 'خطأ غير متوقّع';

  @override
  String get errPhoneInvalid => 'رقم الهاتف غير صحيح';

  @override
  String get errCodeInvalid => 'الرمز غير صحيح';

  @override
  String get errCodeExpired => 'انتهت صلاحية الرمز — اطلب رمزًا جديدًا';

  @override
  String get errTooManyAttempts => 'محاولاتٌ كثيرة — حاول لاحقًا';

  @override
  String get errQuotaExceeded => 'تجاوزتَ الحصّة المسموحة — حاول لاحقًا';

  @override
  String get errNetwork => 'تعذّر الاتصال بالشبكة';

  @override
  String get errVerifyFailed => 'فشل التحقّق';

  @override
  String get errNoCodeSent => 'لم يُرسَل رمزٌ بعد';

  @override
  String get errTokenFailed => 'تعذّر إصدار توكن الدخول';

  @override
  String get errInstallAndroidOnly =>
      'التثبيت داخل التطبيق مدعوم على أندرويد فقط';

  @override
  String get errInstallPermission =>
      'فعّل «السماح من هذا المصدر» ثمّ اضغط إعادة المحاولة';

  @override
  String errDownloadFailed(int code) {
    return 'فشل التنزيل (رمز $code)';
  }

  @override
  String get errDownloadIncomplete => 'التنزيل غير مكتمل — حاول لاحقًا';

  @override
  String errInstallerOpen(String reason) {
    return 'تعذّر فتح المثبّت ($reason)';
  }

  @override
  String get errUpdateGeneric =>
      'تعذّر التحديث — تحقّق من الاتصال وحاول لاحقًا';

  @override
  String get bankilyBuy => 'شراء عبر بنكيلي';

  @override
  String get bankilySoonBadge => 'قريبًا';

  @override
  String get bankilyTitle => 'الدفع عبر بنكيلي';

  @override
  String get bankilySoonBanner =>
      'الدفع عبر بنكيلي قريبًا. هذه هي الخطوات، وسيعمل زرّ التأكيد فور تفعيله — دون تحديث التطبيق.';

  @override
  String bankilyStepOf(int step) {
    return 'الخطوة $step من 4';
  }

  @override
  String get bankilyStep1Title => 'افتح تطبيق بنكيلي';

  @override
  String get bankilyStep1Body => 'افتح بنكيلي على هاتفك واذهب إلى قسم B-PAY.';

  @override
  String get bankilyStep2Title => 'أدخل رمز التاجر والمبلغ';

  @override
  String get bankilyStep2Body =>
      'في B-PAY أدخل رمز التاجر والمبلغ كما هما هنا بالضبط.';

  @override
  String get bankilyMerchantCode => 'رمز التاجر';

  @override
  String get bankilyAmount => 'المبلغ';

  @override
  String get bankilyStep3Title => 'استلم الرمز';

  @override
  String get bankilyStep3Body =>
      'سيرسل لك بنكيلي رمزًا من 4 أرقام لتأكيد العملية.';

  @override
  String get bankilyStep4Title => 'أكمل الدفع';

  @override
  String get bankilyStep4Body => 'أدخل رقم هاتف بنكيلي والرمز الذي وصلك.';

  @override
  String get bankilyPhone => 'رقم هاتف بنكيلي';

  @override
  String get bankilyCode => 'الرمز المستلم من بنكيلي';

  @override
  String get bankilyConfirm => 'تأكيد الدفع';

  @override
  String get bankilyNext => 'متابعة';

  @override
  String get bankilyBack => 'رجوع';

  @override
  String get bankilyCopied => 'نُسخ';

  @override
  String bankilyYouGet(int diamonds) {
    return 'ستحصل على $diamonds ماسة';
  }

  @override
  String bankilySuccess(int diamonds) {
    return 'وصل ماسُك! أُضيفت $diamonds ماسة إلى رصيدك.';
  }

  @override
  String get bankilyErrPhone => 'رقم الهاتف 8 أرقام يبدأ بـ 2 أو 3 أو 4';

  @override
  String get bankilyErrCode => 'الرمز 4 أرقام';

  @override
  String get bankilyErrRejected =>
      'رفض بنكيلي العملية — تحقّق من الرمز وحاول مجددًا';

  @override
  String get bankilyErrUnreachable => 'تعذّر الوصول إلى بنكيلي — حاول بعد قليل';

  @override
  String get devCredit => 'برمجة وتطوير';

  @override
  String get devName => 'محمد الأمين بينة';

  @override
  String get bankilyTapToCopy => 'اضغط للنسخ';

  @override
  String get storeBuyChoose => 'اختر طريقة الدفع';

  @override
  String get storeBuyViaApple => 'الدفع عبر Apple';

  @override
  String get storeBuyViaGoogle => 'الدفع عبر Google Play';

  @override
  String get storeBuyViaStoreSub => 'بطاقة أو رصيد المتجر';

  @override
  String get storeBuyViaBankilySub => 'من محفظتك في بنكيلي';

  @override
  String get storeBuyCancelled => 'أُلغيت العملية';

  @override
  String get storeBuyUnavailable => 'الشراء من المتجر غير متاح الآن';

  @override
  String get storeBuyFailed =>
      'تعذّر إتمام الشراء — إن خُصم المبلغ فسيصلك الماس تلقائيًا عند فتح التطبيق مجددًا';

  @override
  String get pulseTopPlayers => 'أفضل اللاعبين';

  @override
  String get pulseLiveNow => 'مباريات جارية الآن';

  @override
  String pulseWatchers(int count) {
    return '$count يشاهدون';
  }

  @override
  String get pulseSeeAll => 'عرض الكل';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get helpAndSupport => 'المساعدة والدعم';

  @override
  String get appStoreBuySoon => 'الشراء عبر App Store — قريبًا.';

  @override
  String get errLoginFailed => 'تعذّر إكمال تسجيل الدخول. حاول مرة أخرى.';

  @override
  String errCodeInvalidLeft(int count) {
    return 'الرمز غير صحيح — بقيت $count محاولات';
  }

  @override
  String errOtpRetryAfter(int seconds) {
    return 'طلباتٌ كثيرة — حاول بعد $seconds ثانية';
  }

  @override
  String get errOtpUnavailable =>
      'خدمةُ الرسائل غير متاحةٍ الآن — حاول بعد قليل';

  @override
  String get errPhoneTaken => 'لهذا الرقم حسابٌ مسبقًا — سجّل الدخول';

  @override
  String get errPhoneUnknown => 'لا يوجد حسابٌ بهذا الرقم';

  @override
  String resendCodeIn(int seconds) {
    return 'إعادة الإرسال بعد $seconds ث';
  }

  @override
  String get resendCode => 'أعد إرسال الرمز';

  @override
  String get sendViaWhatsApp => 'أرسل الرمز عبر واتساب';
}
