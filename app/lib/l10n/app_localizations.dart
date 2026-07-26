import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

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
    Locale('ar'),
    Locale('fr')
  ];

  /// اسم التطبيق
  ///
  /// In ar, this message translates to:
  /// **'بلوت'**
  String get appTitle;

  /// No description provided for @teamUs.
  ///
  /// In ar, this message translates to:
  /// **'نحن'**
  String get teamUs;

  /// No description provided for @teamThem.
  ///
  /// In ar, this message translates to:
  /// **'هم'**
  String get teamThem;

  /// No description provided for @bidNone.
  ///
  /// In ar, this message translates to:
  /// **'لا ضمانة'**
  String get bidNone;

  /// No description provided for @bidAkwins.
  ///
  /// In ar, this message translates to:
  /// **'أكوينس'**
  String get bidAkwins;

  /// No description provided for @bidPass.
  ///
  /// In ar, this message translates to:
  /// **'تمرير'**
  String get bidPass;

  /// No description provided for @bidYours.
  ///
  /// In ar, this message translates to:
  /// **'ضمانتك'**
  String get bidYours;

  /// No description provided for @bidSans.
  ///
  /// In ar, this message translates to:
  /// **'صن'**
  String get bidSans;

  /// No description provided for @bidTout.
  ///
  /// In ar, this message translates to:
  /// **'تو'**
  String get bidTout;

  /// No description provided for @suitTrefle.
  ///
  /// In ar, this message translates to:
  /// **'أتريف'**
  String get suitTrefle;

  /// No description provided for @suitCarreau.
  ///
  /// In ar, this message translates to:
  /// **'كارو'**
  String get suitCarreau;

  /// No description provided for @suitCoeur.
  ///
  /// In ar, this message translates to:
  /// **'كير'**
  String get suitCoeur;

  /// No description provided for @suitPique.
  ///
  /// In ar, this message translates to:
  /// **'أبيك'**
  String get suitPique;

  /// الضمانة الجارية ومعها الأكوينس
  ///
  /// In ar, this message translates to:
  /// **'{bid} · أكوينس'**
  String bidWithAkwins(String bid);

  /// No description provided for @phaseDealing.
  ///
  /// In ar, this message translates to:
  /// **'التوزيع'**
  String get phaseDealing;

  /// No description provided for @phaseBidding.
  ///
  /// In ar, this message translates to:
  /// **'الضمانة'**
  String get phaseBidding;

  /// No description provided for @followSuitRequired.
  ///
  /// In ar, this message translates to:
  /// **'يجب اتباع اللون'**
  String get followSuitRequired;

  /// No description provided for @rankBeginner.
  ///
  /// In ar, this message translates to:
  /// **'مبتدئ'**
  String get rankBeginner;

  /// No description provided for @rankPro.
  ///
  /// In ar, this message translates to:
  /// **'محترف'**
  String get rankPro;

  /// No description provided for @rankExpert.
  ///
  /// In ar, this message translates to:
  /// **'خبير'**
  String get rankExpert;

  /// No description provided for @rankLegend.
  ///
  /// In ar, this message translates to:
  /// **'أسطوريّ'**
  String get rankLegend;

  /// No description provided for @seatYou.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get seatYou;

  /// No description provided for @seatOpponent.
  ///
  /// In ar, this message translates to:
  /// **'الخصم'**
  String get seatOpponent;

  /// No description provided for @seatPartner.
  ///
  /// In ar, this message translates to:
  /// **'الشريك'**
  String get seatPartner;

  /// No description provided for @roundOver.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجولة'**
  String get roundOver;

  /// No description provided for @roundNew.
  ///
  /// In ar, this message translates to:
  /// **'جولة جديدة'**
  String get roundNew;

  /// No description provided for @matchNew.
  ///
  /// In ar, this message translates to:
  /// **'مباراة جديدة'**
  String get matchNew;

  /// No description provided for @backToMenu.
  ///
  /// In ar, this message translates to:
  /// **'القائمة'**
  String get backToMenu;

  /// No description provided for @rating.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get rating;

  /// No description provided for @roundValue.
  ///
  /// In ar, this message translates to:
  /// **'قيمة الجولة'**
  String get roundValue;

  /// No description provided for @matchWonUs.
  ///
  /// In ar, this message translates to:
  /// **'فزتم بالمباراة!'**
  String get matchWonUs;

  /// No description provided for @matchWonThem.
  ///
  /// In ar, this message translates to:
  /// **'فاز الخصم بالمباراة'**
  String get matchWonThem;

  /// No description provided for @matchTiebreak.
  ///
  /// In ar, this message translates to:
  /// **'تعادل — جولة فاصلة'**
  String get matchTiebreak;

  /// No description provided for @openRuleTie.
  ///
  /// In ar, this message translates to:
  /// **'قاعدة مفتوحة: تعادل الأكوينس (نادر — لا حسم)'**
  String get openRuleTie;

  /// No description provided for @fouja.
  ///
  /// In ar, this message translates to:
  /// **'فوجة'**
  String get fouja;

  /// No description provided for @foujaWho.
  ///
  /// In ar, this message translates to:
  /// **'من عمل الفوجة؟'**
  String get foujaWho;

  /// No description provided for @opponentRight.
  ///
  /// In ar, this message translates to:
  /// **'الخصم يمينك'**
  String get opponentRight;

  /// No description provided for @opponentLeft.
  ///
  /// In ar, this message translates to:
  /// **'الخصم يسارك'**
  String get opponentLeft;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @foujaCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الفوجة'**
  String get foujaCancel;

  /// No description provided for @foujaClaimedBy.
  ///
  /// In ar, this message translates to:
  /// **'{name} يعترض بالفوجة…'**
  String foujaClaimedBy(String name);

  /// No description provided for @foujaWonUs.
  ///
  /// In ar, this message translates to:
  /// **'فوجة — لكم نقاط الضمانة'**
  String get foujaWonUs;

  /// No description provided for @foujaWonThem.
  ///
  /// In ar, this message translates to:
  /// **'فوجة — للخصم نقاط الضمانة'**
  String get foujaWonThem;

  /// No description provided for @reasonChute.
  ///
  /// In ar, this message translates to:
  /// **'سقطت الضمانة'**
  String get reasonChute;

  /// No description provided for @reasonAkwins.
  ///
  /// In ar, this message translates to:
  /// **'أكوينس'**
  String get reasonAkwins;

  /// No description provided for @reasonWhite.
  ///
  /// In ar, this message translates to:
  /// **'جولة بيضاء!'**
  String get reasonWhite;

  /// No description provided for @reasonMade.
  ///
  /// In ar, this message translates to:
  /// **'نجحت الضمانة'**
  String get reasonMade;

  /// No description provided for @settingsLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In ar, this message translates to:
  /// **'الفرنسية'**
  String get settingsLanguageFrench;

  /// No description provided for @exitGame.
  ///
  /// In ar, this message translates to:
  /// **'خروج من اللعبة'**
  String get exitGame;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @settingsName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get settingsName;

  /// No description provided for @settingsTheme.
  ///
  /// In ar, this message translates to:
  /// **'الثيم'**
  String get settingsTheme;

  /// No description provided for @settingsSound.
  ///
  /// In ar, this message translates to:
  /// **'الصوت'**
  String get settingsSound;

  /// No description provided for @howToPlay.
  ///
  /// In ar, this message translates to:
  /// **'كيف تلعب'**
  String get howToPlay;

  /// No description provided for @supportSection.
  ///
  /// In ar, this message translates to:
  /// **'الدعم الفنّي'**
  String get supportSection;

  /// No description provided for @supportWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get supportWhatsapp;

  /// No description provided for @supportEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get supportEmail;

  /// No description provided for @openFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الفتح على هذا الجهاز.'**
  String get openFailed;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @appVersion.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String appVersion(String version);

  /// No description provided for @serverUnreachable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالخادم'**
  String get serverUnreachable;

  /// No description provided for @friendsFetchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلبُ الأصدقاء'**
  String get friendsFetchFailed;

  /// No description provided for @noFriendsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا أصدقاءَ بعد — أضفهم من شاشة الأصدقاء برمزهم.'**
  String get noFriendsYet;

  /// No description provided for @invitePartnerPays.
  ///
  /// In ar, this message translates to:
  /// **'ادعُ شريكًا — يدفع رسمَه عند قبوله'**
  String get invitePartnerPays;

  /// No description provided for @unknownInitial.
  ///
  /// In ar, this message translates to:
  /// **'؟'**
  String get unknownInitial;

  /// No description provided for @tournaments.
  ///
  /// In ar, this message translates to:
  /// **'البطولات'**
  String get tournaments;

  /// No description provided for @signInForTournaments.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول للمشاركة في البطولات'**
  String get signInForTournaments;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @createYourEvent.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ مسابقتك'**
  String get createYourEvent;

  /// No description provided for @createEventSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'باسمك وبرسمٍ تحدّده — رسم الإنشاء 50💎'**
  String get createEventSubtitle;

  /// No description provided for @create.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ'**
  String get create;

  /// No description provided for @newEvent.
  ///
  /// In ar, this message translates to:
  /// **'مسابقة جديدة'**
  String get newEvent;

  /// No description provided for @eventName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المسابقة'**
  String get eventName;

  /// No description provided for @entryFeeField.
  ///
  /// In ar, this message translates to:
  /// **'رسم الدخول (10–500 💎)'**
  String get entryFeeField;

  /// No description provided for @sizeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحجم:'**
  String get sizeLabel;

  /// No description provided for @teamsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} فرق'**
  String teamsCount(int count);

  /// No description provided for @eventSchedule.
  ///
  /// In ar, this message translates to:
  /// **'الموعد: {date} · {time}'**
  String eventSchedule(String date, String time);

  /// No description provided for @createEventTerms.
  ///
  /// In ar, this message translates to:
  /// **'رسم الإنشاء 50💎 غير مستردّ. رسوم المشاركين صندوقُ الفائزين (البيت يقتطع 20%) — لا نصيبَ للمنشئ منها؛ المسابقة باسمك.'**
  String get createEventTerms;

  /// No description provided for @createEventConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ المسابقة — 50💎'**
  String get createEventConfirm;

  /// No description provided for @hoursMinutes.
  ///
  /// In ar, this message translates to:
  /// **'{h} س {m} د'**
  String hoursMinutes(int h, int m);

  /// No description provided for @eventLive.
  ///
  /// In ar, this message translates to:
  /// **'جارية الآن'**
  String get eventLive;

  /// No description provided for @eventPlayerMade.
  ///
  /// In ar, this message translates to:
  /// **'مسابقة لاعب'**
  String get eventPlayerMade;

  /// No description provided for @eventOfficial.
  ///
  /// In ar, this message translates to:
  /// **'فعاليّة'**
  String get eventOfficial;

  /// No description provided for @eventOrganizer.
  ///
  /// In ar, this message translates to:
  /// **'ينظّمها: {name}'**
  String eventOrganizer(String name);

  /// No description provided for @eventStats.
  ///
  /// In ar, this message translates to:
  /// **'الدخول: {fee}💎  ·  المسجّلون: {players}/{size}  ·  الصندوق: {pool}💎'**
  String eventStats(int fee, int players, int size, int pool);

  /// No description provided for @startsIn.
  ///
  /// In ar, this message translates to:
  /// **'تبدأ بعد {time}'**
  String startsIn(String time);

  /// No description provided for @partnerInviteEvent.
  ///
  /// In ar, this message translates to:
  /// **'{name} يدعوك شريكًا له في هذه الفعاليّة 🤝'**
  String partnerInviteEvent(String name);

  /// No description provided for @accept.
  ///
  /// In ar, this message translates to:
  /// **'اقبل'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In ar, this message translates to:
  /// **'ارفض'**
  String get decline;

  /// No description provided for @withdrawRefund.
  ///
  /// In ar, this message translates to:
  /// **'انسحب واسترد رسمك'**
  String get withdrawRefund;

  /// No description provided for @invitePartner.
  ///
  /// In ar, this message translates to:
  /// **'ادعُ شريكًا'**
  String get invitePartner;

  /// No description provided for @registerForFee.
  ///
  /// In ar, this message translates to:
  /// **'سجّل — {fee}💎'**
  String registerForFee(int fee);

  /// No description provided for @yourPartner.
  ///
  /// In ar, this message translates to:
  /// **'شريكك: {name} 🤝'**
  String yourPartner(String name);

  /// No description provided for @cancelMyEvent.
  ///
  /// In ar, this message translates to:
  /// **'ألغِ مسابقتك'**
  String get cancelMyEvent;

  /// No description provided for @cancelEventTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء «{title}»؟'**
  String cancelEventTitle(String title);

  /// No description provided for @cancelEventBody.
  ///
  /// In ar, this message translates to:
  /// **'تُردُّ رسومُ المسجّلين ({players}) كاملةً. رسمُ الإنشاء (50💎) لا يعود.'**
  String cancelEventBody(int players);

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'تراجُع'**
  String get back;

  /// No description provided for @cancelEventConfirm.
  ///
  /// In ar, this message translates to:
  /// **'ألغِ المسابقة'**
  String get cancelEventConfirm;

  /// No description provided for @lastTournamentChampions.
  ///
  /// In ar, this message translates to:
  /// **'أبطال آخر بطولة'**
  String get lastTournamentChampions;

  /// No description provided for @partnerInvite.
  ///
  /// In ar, this message translates to:
  /// **'{name} يدعوك شريكًا له 🤝'**
  String partnerInvite(String name);

  /// No description provided for @partnerInviteRegistered.
  ///
  /// In ar, this message translates to:
  /// **'بقبولك تُثبَّتان شريكين على طاولةٍ واحدة.'**
  String get partnerInviteRegistered;

  /// No description provided for @partnerInviteWillPay.
  ///
  /// In ar, this message translates to:
  /// **'بقبولك تُسجَّل وتدفع رسمَك ({fee}💎) وتُثبَّتان شريكين.'**
  String partnerInviteWillPay(int fee);

  /// No description provided for @todaysTournament.
  ///
  /// In ar, this message translates to:
  /// **'بطولة اليوم'**
  String get todaysTournament;

  /// No description provided for @knockoutSize.
  ///
  /// In ar, this message translates to:
  /// **'إقصائيّة {size}'**
  String knockoutSize(int size);

  /// No description provided for @tournamentStats.
  ///
  /// In ar, this message translates to:
  /// **'الدخول: {fee}💎 للشخص  ·  الصندوق حتى الآن: {pool}💎'**
  String tournamentStats(int fee, int pool);

  /// No description provided for @tournamentPayoutNote.
  ///
  /// In ar, this message translates to:
  /// **'الزوج الفائز يقتسم الصندوق — والذكاء يكمل النقص عند البدء.'**
  String get tournamentPayoutNote;

  /// No description provided for @startsWithin.
  ///
  /// In ar, this message translates to:
  /// **'تبدأ خلال {time}'**
  String startsWithin(String time);

  /// No description provided for @registeredCount.
  ///
  /// In ar, this message translates to:
  /// **'المسجّلون {players}/{size}'**
  String registeredCount(int players, int size);

  /// No description provided for @withPartner.
  ///
  /// In ar, this message translates to:
  /// **'مع {name}'**
  String withPartner(String name);

  /// No description provided for @enterYourTable.
  ///
  /// In ar, this message translates to:
  /// **'ادخل طاولتك الآن'**
  String get enterYourTable;

  /// No description provided for @roundFinal.
  ///
  /// In ar, this message translates to:
  /// **'النهائيّ'**
  String get roundFinal;

  /// No description provided for @roundSemi.
  ///
  /// In ar, this message translates to:
  /// **'نصف النهائيّ'**
  String get roundSemi;

  /// No description provided for @roundQuarter.
  ///
  /// In ar, this message translates to:
  /// **'ربع النهائيّ'**
  String get roundQuarter;

  /// No description provided for @roundOfN.
  ///
  /// In ar, this message translates to:
  /// **'دور الـ{n}'**
  String roundOfN(int n);

  /// No description provided for @roundGeneric.
  ///
  /// In ar, this message translates to:
  /// **'جولة'**
  String get roundGeneric;

  /// No description provided for @roundProgress.
  ///
  /// In ar, this message translates to:
  /// **'حُسمت {done} من {total} مباراة'**
  String roundProgress(int done, int total);

  /// No description provided for @yourMatchShown.
  ///
  /// In ar, this message translates to:
  /// **' — تُعرَض مباراتُك'**
  String get yourMatchShown;

  /// No description provided for @nextRoundPending.
  ///
  /// In ar, this message translates to:
  /// **'الجولة التالية تُبنى فور حسم مبارياتها الرافدة…'**
  String get nextRoundPending;

  /// No description provided for @matchLive.
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get matchLive;

  /// No description provided for @versus.
  ///
  /// In ar, this message translates to:
  /// **'ضدّ'**
  String get versus;

  /// No description provided for @botPlayer.
  ///
  /// In ar, this message translates to:
  /// **'ذكاء'**
  String get botPlayer;

  /// No description provided for @playerFallback.
  ///
  /// In ar, this message translates to:
  /// **'لاعب'**
  String get playerFallback;

  /// No description provided for @reportPlayer.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ عن {name}'**
  String reportPlayer(String name);

  /// No description provided for @blockPlayer.
  ///
  /// In ar, this message translates to:
  /// **'حظر {name}'**
  String blockPlayer(String name);

  /// No description provided for @blockPlayerNote.
  ///
  /// In ar, this message translates to:
  /// **'لا يصلك كلامه، ولا يراسلك ولا يدعوك.'**
  String get blockPlayerNote;

  /// No description provided for @reportSent.
  ///
  /// In ar, this message translates to:
  /// **'وصل بلاغك — سيُراجَع.'**
  String get reportSent;

  /// No description provided for @playerBlocked.
  ///
  /// In ar, this message translates to:
  /// **'حُظر {name} — لن يصلك كلامه.'**
  String playerBlocked(String name);

  /// No description provided for @blockFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحظر — تحقّق من الاتّصال.'**
  String get blockFailed;

  /// No description provided for @errInviteOffline.
  ///
  /// In ar, this message translates to:
  /// **'صديقك غير متّصل ولا تصله الإشعارات — لن يعلم بدعوتك حتى يفتح اللعبة.'**
  String get errInviteOffline;

  /// No description provided for @errInviteNotFriend.
  ///
  /// In ar, this message translates to:
  /// **'أضِفه صديقًا أوّلًا لتدعوه.'**
  String get errInviteNotFriend;

  /// No description provided for @errInviteSeatTaken.
  ///
  /// In ar, this message translates to:
  /// **'المقعد شُغل — اختر غيره.'**
  String get errInviteSeatTaken;

  /// No description provided for @errInviteStarted.
  ///
  /// In ar, this message translates to:
  /// **'المباراة بدأت — لا يمكن دعوة أحدٍ الآن.'**
  String get errInviteStarted;

  /// No description provided for @errInviteNotPrivate.
  ///
  /// In ar, this message translates to:
  /// **'الدعوة للطاولة الخاصّة فقط — أنشئ واحدةً ثمّ ادعُه.'**
  String get errInviteNotPrivate;

  /// No description provided for @errGiftInsufficient.
  ///
  /// In ar, this message translates to:
  /// **'ماسك لا يكفي لهذه الهديّة.'**
  String get errGiftInsufficient;

  /// No description provided for @errGiftNotOnTable.
  ///
  /// In ar, this message translates to:
  /// **'لم يعد على الطاولة.'**
  String get errGiftNotOnTable;

  /// No description provided for @errGiftSelf.
  ///
  /// In ar, this message translates to:
  /// **'لا تُهدي نفسك.'**
  String get errGiftSelf;

  /// No description provided for @errGiftUnknown.
  ///
  /// In ar, this message translates to:
  /// **'هذه الهديّة لم تعد متاحة.'**
  String get errGiftUnknown;

  /// No description provided for @errVipGiftEmpty.
  ///
  /// In ar, this message translates to:
  /// **'نفدت هدايا VIP اليوم — تعود ثلاثٌ غدًا.'**
  String get errVipGiftEmpty;

  /// No description provided for @errVipGiftNotVip.
  ///
  /// In ar, this message translates to:
  /// **'هذه الهدايا لمشتركي VIP.'**
  String get errVipGiftNotVip;

  /// No description provided for @inviteRewardMsg.
  ///
  /// In ar, this message translates to:
  /// **'صديقُك انضمّ — نلتَ لعبةً إضافيّةً اليوم! 🎉'**
  String get inviteRewardMsg;

  /// No description provided for @errGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تنفيذ ما طلبت — حاول مرّةً أخرى.'**
  String get errGeneric;

  /// No description provided for @spectatingCount.
  ///
  /// In ar, this message translates to:
  /// **'تشاهد · {count}'**
  String spectatingCount(int count);

  /// No description provided for @enteringStands.
  ///
  /// In ar, this message translates to:
  /// **'جاري الدخول إلى المدرّجات…'**
  String get enteringStands;

  /// No description provided for @reconnecting.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الاتصال…'**
  String get reconnecting;

  /// No description provided for @playOnline.
  ///
  /// In ar, this message translates to:
  /// **'اللعب أونلاين'**
  String get playOnline;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'خروج'**
  String get logout;

  /// No description provided for @quickMatch.
  ///
  /// In ar, this message translates to:
  /// **'لعب سريع'**
  String get quickMatch;

  /// No description provided for @quickMatchSub.
  ///
  /// In ar, this message translates to:
  /// **'اجلس على أول طاولة متاحة مع لاعبين'**
  String get quickMatchSub;

  /// No description provided for @createPrivateTable.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء طاولة خاصّة'**
  String get createPrivateTable;

  /// No description provided for @createPrivateTableSub.
  ///
  /// In ar, this message translates to:
  /// **'ادعُ أصدقاءك برمز الطاولة'**
  String get createPrivateTableSub;

  /// No description provided for @tableCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز الطاولة'**
  String get tableCode;

  /// No description provided for @joinByCode.
  ///
  /// In ar, this message translates to:
  /// **'انضمام برمز'**
  String get joinByCode;

  /// No description provided for @seatRolePartner.
  ///
  /// In ar, this message translates to:
  /// **'شريكًا لك'**
  String get seatRolePartner;

  /// No description provided for @seatRoleOpponent.
  ///
  /// In ar, this message translates to:
  /// **'خصمًا لك'**
  String get seatRoleOpponent;

  /// No description provided for @invitedPlayer.
  ///
  /// In ar, this message translates to:
  /// **'دُعي {name}'**
  String invitedPlayer(String name);

  /// No description provided for @privateTable.
  ///
  /// In ar, this message translates to:
  /// **'طاولة خاصّة'**
  String get privateTable;

  /// No description provided for @quickMatchTitle.
  ///
  /// In ar, this message translates to:
  /// **'مطابقة سريعة'**
  String get quickMatchTitle;

  /// No description provided for @tableCodeIs.
  ///
  /// In ar, this message translates to:
  /// **'الرمز: {code}'**
  String tableCodeIs(String code);

  /// No description provided for @startMatch.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ المباراة'**
  String get startMatch;

  /// No description provided for @searchingPlayers.
  ///
  /// In ar, this message translates to:
  /// **'جاري البحث عن لاعبين…'**
  String get searchingPlayers;

  /// No description provided for @searchingPlayersSub.
  ///
  /// In ar, this message translates to:
  /// **'نبحث لك عن منافسين على الطاولة'**
  String get searchingPlayersSub;

  /// No description provided for @errServerFull.
  ///
  /// In ar, this message translates to:
  /// **'الخوادم ممتلئة الآن — حاول بعد قليل.'**
  String get errServerFull;

  /// No description provided for @errSpectateUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'انتهت هذه المباراة أو لم تعد متاحة للمشاهدة.'**
  String get errSpectateUnavailable;

  /// No description provided for @errSpectateSeated.
  ///
  /// In ar, this message translates to:
  /// **'أنت على طاولةٍ الآن — غادرها ثم شاهد.'**
  String get errSpectateSeated;

  /// No description provided for @errPlayLimit.
  ///
  /// In ar, this message translates to:
  /// **'انتهت لعباتُك اليوم — تعود غدًا. والعبُ مع الذكاء بلا حدود.'**
  String get errPlayLimit;

  /// No description provided for @errJoinFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الانضمام — تحقّق من الرمز.'**
  String get errJoinFailed;

  /// No description provided for @errNoSeat.
  ///
  /// In ar, this message translates to:
  /// **'لا مقعد متاح على هذه الطاولة.'**
  String get errNoSeat;

  /// No description provided for @errUnauthorized.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة — سجّل الدخول من جديد.'**
  String get errUnauthorized;

  /// No description provided for @errConnection.
  ///
  /// In ar, this message translates to:
  /// **'انقطع الاتصال بالخادم.'**
  String get errConnection;

  /// No description provided for @errUnexpected.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقّع.'**
  String get errUnexpected;

  /// No description provided for @goBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get goBack;

  /// No description provided for @invitesYouToTable.
  ///
  /// In ar, this message translates to:
  /// **'{name} يدعوك إلى طاولته'**
  String invitesYouToTable(String name);

  /// No description provided for @later.
  ///
  /// In ar, this message translates to:
  /// **'لاحقًا'**
  String get later;

  /// No description provided for @join.
  ///
  /// In ar, this message translates to:
  /// **'انضمّ'**
  String get join;

  /// No description provided for @fillingSeatsNote.
  ///
  /// In ar, this message translates to:
  /// **'نبحث عن لاعبين للمقاعد الفارغة… وإن لم نجد بدأنا بلاعبي الذكاء.'**
  String get fillingSeatsNote;

  /// No description provided for @playerDefaultName.
  ///
  /// In ar, this message translates to:
  /// **'اللاعب'**
  String get playerDefaultName;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navLeaderboard.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get navLeaderboard;

  /// No description provided for @navStore.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get navStore;

  /// No description provided for @navFriends.
  ///
  /// In ar, this message translates to:
  /// **'الأصدقاء'**
  String get navFriends;

  /// No description provided for @navAbout.
  ///
  /// In ar, this message translates to:
  /// **'حول اللعبة'**
  String get navAbout;

  /// No description provided for @quickPlayOffline.
  ///
  /// In ar, this message translates to:
  /// **'لعب سريع'**
  String get quickPlayOffline;

  /// No description provided for @quickPlayOfflineSub.
  ///
  /// In ar, this message translates to:
  /// **'ضدّ الذكاء — بلا اتصال'**
  String get quickPlayOfflineSub;

  /// No description provided for @vipActiveSub.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكُك قائم — مزاياك كلُّها معك'**
  String get vipActiveSub;

  /// No description provided for @vipOfferSub.
  ///
  /// In ar, this message translates to:
  /// **'مجلسٌ خاصّ · إطارٌ · هدايا · لعبٌ بلا حدود'**
  String get vipOfferSub;

  /// No description provided for @missions.
  ///
  /// In ar, this message translates to:
  /// **'المهامّ'**
  String get missions;

  /// No description provided for @missionsSub.
  ///
  /// In ar, this message translates to:
  /// **'يوميّة وأسبوعيّة — خبرةٌ وماس'**
  String get missionsSub;

  /// No description provided for @tournamentsSub.
  ///
  /// In ar, this message translates to:
  /// **'بطولة اليوم · فعاليات بجوائز'**
  String get tournamentsSub;

  /// No description provided for @liveMatches.
  ///
  /// In ar, this message translates to:
  /// **'مباريات حيّة'**
  String get liveMatches;

  /// No description provided for @liveMatchesSub.
  ///
  /// In ar, this message translates to:
  /// **'شاهد الجاري الآن · شجّع بالهدايا'**
  String get liveMatchesSub;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get comingSoon;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @offline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get offline;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get signIn;

  /// No description provided for @onlineNeedsSignIn.
  ///
  /// In ar, this message translates to:
  /// **'مع لاعبين حقيقيّين — يتطلّب دخولًا'**
  String get onlineNeedsSignIn;

  /// No description provided for @onlineWithPlayers.
  ///
  /// In ar, this message translates to:
  /// **'مع لاعبين حقيقيّين'**
  String get onlineWithPlayers;

  /// No description provided for @graceUnlimited.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك! لعبٌ بلا حدود — الباقي: {left}'**
  String graceUnlimited(String left);

  /// No description provided for @unlimitedLeft.
  ///
  /// In ar, this message translates to:
  /// **'لعبٌ بلا حدود — الباقي: {left}'**
  String unlimitedLeft(String left);

  /// No description provided for @bonusFromInvites.
  ///
  /// In ar, this message translates to:
  /// **' (منها {bonus} من دعوة أصدقائك)'**
  String bonusFromInvites(int bonus);

  /// No description provided for @gamesLeftToday.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{انتهت لعباتُك اليوم — تعود غدًا} =1{بقيت لك لعبةٌ واحدةٌ اليوم} =2{بقيت لك لعبتان اليوم} other{بقيت لك {count} لعباتٍ اليوم}}'**
  String gamesLeftToday(int count);

  /// No description provided for @expired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت'**
  String get expired;

  /// No description provided for @daysLeft.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{يومٌ واحد} =2{يومان} other{{count} أيّام}}'**
  String daysLeft(int count);

  /// No description provided for @hoursLeft.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{أقلُّ من ساعة} =1{ساعةٌ واحدة} =2{ساعتان} other{{count} ساعات}}'**
  String hoursLeft(int count);

  /// No description provided for @myProfile.
  ///
  /// In ar, this message translates to:
  /// **'ملفّي'**
  String get myProfile;

  /// No description provided for @signInToSeeProfile.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لعرض ملفّك وإحصائياتك'**
  String get signInToSeeProfile;

  /// No description provided for @signInAction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signInAction;

  /// No description provided for @statWinRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الفوز'**
  String get statWinRate;

  /// No description provided for @statMatches.
  ///
  /// In ar, this message translates to:
  /// **'المباريات'**
  String get statMatches;

  /// No description provided for @statWins.
  ///
  /// In ar, this message translates to:
  /// **'الفوز'**
  String get statWins;

  /// No description provided for @statLosses.
  ///
  /// In ar, this message translates to:
  /// **'الخسارة'**
  String get statLosses;

  /// No description provided for @statBestStreak.
  ///
  /// In ar, this message translates to:
  /// **'أفضل سلسلة'**
  String get statBestStreak;

  /// No description provided for @statCurrentStreak.
  ///
  /// In ar, this message translates to:
  /// **'السلسلة الحالية'**
  String get statCurrentStreak;

  /// No description provided for @profilePhoto.
  ///
  /// In ar, this message translates to:
  /// **'صورة الملفّ'**
  String get profilePhoto;

  /// No description provided for @pickFromGallery.
  ///
  /// In ar, this message translates to:
  /// **'اختر من الصور'**
  String get pickFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In ar, this message translates to:
  /// **'التقط صورة'**
  String get takePhoto;

  /// No description provided for @deletePhoto.
  ///
  /// In ar, this message translates to:
  /// **'احذف الصورة'**
  String get deletePhoto;

  /// No description provided for @photoPermissionError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الصور. تحقّق من الأذونات.'**
  String get photoPermissionError;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب نهائيًّا'**
  String get deleteAccount;

  /// No description provided for @signOutNote.
  ///
  /// In ar, this message translates to:
  /// **'يبقى حسابك كما هو، وتعود إليه بهاتفك وكلمة سرّك.'**
  String get signOutNote;

  /// No description provided for @backAction.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get backAction;

  /// No description provided for @signOutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'اخرج'**
  String get signOutConfirm;

  /// No description provided for @deleteFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الحذف: {reason}'**
  String deleteFailed(String reason);

  /// No description provided for @levelLabel.
  ///
  /// In ar, this message translates to:
  /// **'المستوى '**
  String get levelLabel;

  /// No description provided for @xpToNext.
  ///
  /// In ar, this message translates to:
  /// **'{xp} خبرة للتالي'**
  String xpToNext(int xp);

  /// No description provided for @myWallet.
  ///
  /// In ar, this message translates to:
  /// **'محفظتي'**
  String get myWallet;

  /// No description provided for @diamonds.
  ///
  /// In ar, this message translates to:
  /// **'الماس'**
  String get diamonds;

  /// No description provided for @myGifts.
  ///
  /// In ar, this message translates to:
  /// **'هداياي'**
  String get myGifts;

  /// No description provided for @noGiftsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا هدايا بعد — اشترِ باقةً من المتجر.'**
  String get noGiftsYet;

  /// No description provided for @deleteAccountBody.
  ///
  /// In ar, this message translates to:
  /// **'يزول اسمك ورمزك وماسك وتصنيفك وأصدقاؤك. لا رجعة في هذا.\nيبقى رقمك متاحًا لحسابٍ جديدٍ إن أردت العودة.'**
  String get deleteAccountBody;

  /// No description provided for @typeYourTagToConfirm.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رمزك للتأكيد:'**
  String get typeYourTagToConfirm;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ar, this message translates to:
  /// **'احذف حسابي'**
  String get deleteAccountConfirm;

  /// No description provided for @addByTag.
  ///
  /// In ar, this message translates to:
  /// **'إضافة بالرمز'**
  String get addByTag;

  /// No description provided for @blockedList.
  ///
  /// In ar, this message translates to:
  /// **'المحظورون'**
  String get blockedList;

  /// No description provided for @signInToSeeFriends.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لترى أصدقاءك.'**
  String get signInToSeeFriends;

  /// No description provided for @friendsFetchFailedShort.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب الأصدقاء.'**
  String get friendsFetchFailedShort;

  /// No description provided for @incomingRequests.
  ///
  /// In ar, this message translates to:
  /// **'يطلبون صداقتك'**
  String get incomingRequests;

  /// No description provided for @yourFriends.
  ///
  /// In ar, this message translates to:
  /// **'أصدقاؤك'**
  String get yourFriends;

  /// No description provided for @awaitingReply.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار ردّهم'**
  String get awaitingReply;

  /// No description provided for @online.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get online;

  /// No description provided for @chat.
  ///
  /// In ar, this message translates to:
  /// **'محادثة'**
  String get chat;

  /// No description provided for @acceptShort.
  ///
  /// In ar, this message translates to:
  /// **'اقبل'**
  String get acceptShort;

  /// No description provided for @nowFriends.
  ///
  /// In ar, this message translates to:
  /// **'صرتما صديقين'**
  String get nowFriends;

  /// No description provided for @declineShort.
  ///
  /// In ar, this message translates to:
  /// **'ارفض'**
  String get declineShort;

  /// No description provided for @removeFriendAction.
  ///
  /// In ar, this message translates to:
  /// **'احذف من الأصدقاء'**
  String get removeFriendAction;

  /// No description provided for @cancelRequest.
  ///
  /// In ar, this message translates to:
  /// **'اسحب الطلب'**
  String get cancelRequest;

  /// No description provided for @removeFriendTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف صديق'**
  String get removeFriendTitle;

  /// No description provided for @removeFriendBody.
  ///
  /// In ar, this message translates to:
  /// **'تحذف {name} من أصدقائك؟'**
  String removeFriendBody(String name);

  /// No description provided for @deleteShort.
  ///
  /// In ar, this message translates to:
  /// **'احذف'**
  String get deleteShort;

  /// No description provided for @requestDeclined.
  ///
  /// In ar, this message translates to:
  /// **'رُفض الطلب'**
  String get requestDeclined;

  /// No description provided for @friendRemoved.
  ///
  /// In ar, this message translates to:
  /// **'حُذف الصديق'**
  String get friendRemoved;

  /// No description provided for @requestWithdrawn.
  ///
  /// In ar, this message translates to:
  /// **'سُحب الطلب'**
  String get requestWithdrawn;

  /// No description provided for @retryAction.
  ///
  /// In ar, this message translates to:
  /// **'أعِد المحاولة'**
  String get retryAction;

  /// No description provided for @listFetchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب القائمة.'**
  String get listFetchFailed;

  /// No description provided for @nobodyBlocked.
  ///
  /// In ar, this message translates to:
  /// **'لا أحدَ محظور.'**
  String get nobodyBlocked;

  /// No description provided for @unblock.
  ///
  /// In ar, this message translates to:
  /// **'فكّ الحظر'**
  String get unblock;

  /// No description provided for @requestSent.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل الطلب'**
  String get requestSent;

  /// No description provided for @addByTagHint.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من صاحبك رمزه (٦ خانات) من ملفّه الشخصيّ.'**
  String get addByTagHint;

  /// No description provided for @sendRequest.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الطلب'**
  String get sendRequest;

  /// No description provided for @storeFetchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب المتجر'**
  String get storeFetchFailed;

  /// No description provided for @bundlePurchased.
  ///
  /// In ar, this message translates to:
  /// **'نالك {qty}× {gift}'**
  String bundlePurchased(int qty, String gift);

  /// No description provided for @notEnoughForBundle.
  ///
  /// In ar, this message translates to:
  /// **'ماسك لا يكفي — الباقة {price}💎'**
  String notEnoughForBundle(int price);

  /// No description provided for @purchaseFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الشراء'**
  String get purchaseFailed;

  /// No description provided for @connectionFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتّصال'**
  String get connectionFailed;

  /// No description provided for @unlimitedEnjoy.
  ///
  /// In ar, this message translates to:
  /// **'لعبٌ بلا حدودٍ — استمتع!'**
  String get unlimitedEnjoy;

  /// No description provided for @notEnoughForTicket.
  ///
  /// In ar, this message translates to:
  /// **'ماسك لا يكفي — التذكرة {price}💎'**
  String notEnoughForTicket(int price);

  /// No description provided for @storeTitle.
  ///
  /// In ar, this message translates to:
  /// **'المتجر'**
  String get storeTitle;

  /// No description provided for @retryShort.
  ///
  /// In ar, this message translates to:
  /// **'إعادة'**
  String get retryShort;

  /// No description provided for @tabPlay.
  ///
  /// In ar, this message translates to:
  /// **'اللعب'**
  String get tabPlay;

  /// No description provided for @tabGifts.
  ///
  /// In ar, this message translates to:
  /// **'الهدايا'**
  String get tabGifts;

  /// No description provided for @tabDiamonds.
  ///
  /// In ar, this message translates to:
  /// **'الماس'**
  String get tabDiamonds;

  /// No description provided for @storeEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا بضاعةَ في المتجر الآن.'**
  String get storeEmpty;

  /// No description provided for @ticketsIntro.
  ///
  /// In ar, this message translates to:
  /// **'العب بلا حدودٍ طوال المدّة — أنت وأصدقاؤك.'**
  String get ticketsIntro;

  /// No description provided for @unlimitedActiveNotice.
  ///
  /// In ar, this message translates to:
  /// **'لديك لعبٌ بلا حدودٍ الآن. أيُّ شراءٍ يمدّده من نهايته.'**
  String get unlimitedActiveNotice;

  /// No description provided for @cheaperThanSevenDays.
  ///
  /// In ar, this message translates to:
  /// **'أوفرُ من سبع تذاكرِ يوم'**
  String get cheaperThanSevenDays;

  /// No description provided for @ticketFullDay.
  ///
  /// In ar, this message translates to:
  /// **'يومٌ كامل — 24 ساعة'**
  String get ticketFullDay;

  /// No description provided for @ticketFullWeek.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعٌ كامل — 7 أيّام'**
  String get ticketFullWeek;

  /// No description provided for @ticketDays.
  ///
  /// In ar, this message translates to:
  /// **'{days} أيّام'**
  String ticketDays(int days);

  /// No description provided for @ticketHours.
  ///
  /// In ar, this message translates to:
  /// **'{hours} ساعة'**
  String ticketHours(int hours);

  /// No description provided for @giftsIntro.
  ///
  /// In ar, this message translates to:
  /// **'اشترِ الآن، وأهدِ متى شئت.'**
  String get giftsIntro;

  /// No description provided for @diamondsIntro.
  ///
  /// In ar, this message translates to:
  /// **'كلُّ ماسةٍ بأوقيّة. والباقةُ الأكبر تُعطيك أكثر.'**
  String get diamondsIntro;

  /// No description provided for @bankilySoon.
  ///
  /// In ar, this message translates to:
  /// **'الشراء عبر بنكيلي — قريبًا.'**
  String get bankilySoon;

  /// No description provided for @bonusPct.
  ///
  /// In ar, this message translates to:
  /// **'هديّة {pct}%'**
  String bonusPct(int pct);

  /// No description provided for @priceOuguiya.
  ///
  /// In ar, this message translates to:
  /// **'{price} أوقية'**
  String priceOuguiya(int price);

  /// No description provided for @ownedCount.
  ///
  /// In ar, this message translates to:
  /// **'تملك {count}'**
  String ownedCount(int count);

  /// No description provided for @savePct.
  ///
  /// In ar, this message translates to:
  /// **'وفّر {pct}%'**
  String savePct(int pct);

  /// No description provided for @missionDailyPlay.
  ///
  /// In ar, this message translates to:
  /// **'العب ثلاث مباريات'**
  String get missionDailyPlay;

  /// No description provided for @missionDailyWin.
  ///
  /// In ar, this message translates to:
  /// **'فُزْ بمباراة'**
  String get missionDailyWin;

  /// No description provided for @missionDailyFriend.
  ///
  /// In ar, this message translates to:
  /// **'العب مع صديق'**
  String get missionDailyFriend;

  /// No description provided for @missionDailyGift.
  ///
  /// In ar, this message translates to:
  /// **'أهدِ هديّة'**
  String get missionDailyGift;

  /// No description provided for @missionDailyFouja.
  ///
  /// In ar, this message translates to:
  /// **'اكشِف فوجةً واحدة'**
  String get missionDailyFouja;

  /// No description provided for @missionWeeklyPlay.
  ///
  /// In ar, this message translates to:
  /// **'العب عشرين مباراة'**
  String get missionWeeklyPlay;

  /// No description provided for @missionWeeklyWin.
  ///
  /// In ar, this message translates to:
  /// **'فُزْ بعشر مباريات'**
  String get missionWeeklyWin;

  /// No description provided for @missionWeeklyFriend.
  ///
  /// In ar, this message translates to:
  /// **'العب ثلاث مباريات مع صديق'**
  String get missionWeeklyFriend;

  /// No description provided for @missionWeeklyInvite.
  ///
  /// In ar, this message translates to:
  /// **'ادعُ صديقًا إلى طاولتك'**
  String get missionWeeklyInvite;

  /// No description provided for @missionWeeklyGifts.
  ///
  /// In ar, this message translates to:
  /// **'أهدِ عشرَ هدايا'**
  String get missionWeeklyGifts;

  /// No description provided for @missionWeeklyRoom.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ غرفةً خاصّة'**
  String get missionWeeklyRoom;

  /// No description provided for @missionWeeklyClean.
  ///
  /// In ar, this message translates to:
  /// **'العب عشرَ مبارياتٍ بلا فوجة'**
  String get missionWeeklyClean;

  /// No description provided for @missionsUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'المهامّ غير متاحةٍ الآن.'**
  String get missionsUnavailable;

  /// No description provided for @missionsFetchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب المهامّ'**
  String get missionsFetchFailed;

  /// No description provided for @missionRewardClaimed.
  ///
  /// In ar, this message translates to:
  /// **'نلت {diamonds}💎 و{xp} خبرة'**
  String missionRewardClaimed(int diamonds, int xp);

  /// No description provided for @missionStateChanged.
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت حالةُ المهمّة'**
  String get missionStateChanged;

  /// No description provided for @claimFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر القبض'**
  String get claimFailed;

  /// No description provided for @missionsDaily.
  ///
  /// In ar, this message translates to:
  /// **'يوميّة'**
  String get missionsDaily;

  /// No description provided for @missionsDailyReset.
  ///
  /// In ar, this message translates to:
  /// **'تُصفَّر كلَّ يوم'**
  String get missionsDailyReset;

  /// No description provided for @missionsWeekly.
  ///
  /// In ar, this message translates to:
  /// **'أسبوعيّة'**
  String get missionsWeekly;

  /// No description provided for @missionsWeeklyReset.
  ///
  /// In ar, this message translates to:
  /// **'تُصفَّر كلَّ اثنين'**
  String get missionsWeeklyReset;

  /// No description provided for @xpSuffix.
  ///
  /// In ar, this message translates to:
  /// **' خبرة'**
  String get xpSuffix;

  /// No description provided for @claim.
  ///
  /// In ar, this message translates to:
  /// **'اقبض'**
  String get claim;

  /// No description provided for @vipFetchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب الاشتراك'**
  String get vipFetchFailed;

  /// No description provided for @vipWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك في VIP!'**
  String get vipWelcome;

  /// No description provided for @notEnoughForVip.
  ///
  /// In ar, this message translates to:
  /// **'ماسك لا يكفي — الاشتراك {price}💎'**
  String notEnoughForVip(int price);

  /// No description provided for @subscribeFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاشتراك'**
  String get subscribeFailed;

  /// No description provided for @vipExtend.
  ///
  /// In ar, this message translates to:
  /// **'مدّد اشتراكك'**
  String get vipExtend;

  /// No description provided for @vipChoosePlan.
  ///
  /// In ar, this message translates to:
  /// **'اختر اشتراكك'**
  String get vipChoosePlan;

  /// No description provided for @vipFrameNote.
  ///
  /// In ar, this message translates to:
  /// **'إطارُك الخاصُّ يرافقك على كلّ طاولة'**
  String get vipFrameNote;

  /// No description provided for @vipActiveUntil.
  ///
  /// In ar, this message translates to:
  /// **'أنت VIP — حتى {date}'**
  String vipActiveUntil(String date);

  /// No description provided for @vipPerkRoom.
  ///
  /// In ar, this message translates to:
  /// **'مجلسٌ خاصّ'**
  String get vipPerkRoom;

  /// No description provided for @vipPerkRoomSub.
  ///
  /// In ar, this message translates to:
  /// **'غرفتُك أنت وأصدقاؤك — لا يدخلها غريب.'**
  String get vipPerkRoomSub;

  /// No description provided for @vipPerkUnlimited.
  ///
  /// In ar, this message translates to:
  /// **'لعبٌ بلا حدود'**
  String get vipPerkUnlimited;

  /// No description provided for @vipPerkUnlimitedSub.
  ///
  /// In ar, this message translates to:
  /// **'انسَ الخمسَ لعبات — العب ما شئت طوال اشتراكك.'**
  String get vipPerkUnlimitedSub;

  /// No description provided for @vipPerkDiamonds.
  ///
  /// In ar, this message translates to:
  /// **'{gems} ماسةً كلَّ شهر'**
  String vipPerkDiamonds(int gems);

  /// No description provided for @vipPerkDiamondsSub.
  ///
  /// In ar, this message translates to:
  /// **'تصلك دفعةً شهريّةً ما دام اشتراكُك قائمًا.'**
  String get vipPerkDiamondsSub;

  /// No description provided for @vipPerkBadge.
  ///
  /// In ar, this message translates to:
  /// **'شارةُ VIP'**
  String get vipPerkBadge;

  /// No description provided for @vipPerkBadgeSub.
  ///
  /// In ar, this message translates to:
  /// **'ترافق اسمَك أينما جلست.'**
  String get vipPerkBadgeSub;

  /// No description provided for @vipGiftsTitle.
  ///
  /// In ar, this message translates to:
  /// **'هدايا لا يملكها غيرُك'**
  String get vipGiftsTitle;

  /// No description provided for @vipGiftsSub.
  ///
  /// In ar, this message translates to:
  /// **'ثلاثٌ كلَّ يومٍ مجّانًا — تُرسلها فيراها كلُّ من على الطاولة.'**
  String get vipGiftsSub;

  /// No description provided for @planYear.
  ///
  /// In ar, this message translates to:
  /// **'سنةٌ كاملة'**
  String get planYear;

  /// No description provided for @planMonth.
  ///
  /// In ar, this message translates to:
  /// **'شهرٌ واحد'**
  String get planMonth;

  /// No description provided for @saveVsMonthly.
  ///
  /// In ar, this message translates to:
  /// **'وفّر {pct}% عن الشهريّ'**
  String saveVsMonthly(int pct);

  /// No description provided for @ruleBasicsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأساس'**
  String get ruleBasicsTitle;

  /// No description provided for @ruleBasicsBody.
  ///
  /// In ar, this message translates to:
  /// **'أربعة لاعبين، فريقان (المقعدان 0 و2 ضدّ 1 و3). 32 ورقة (من 7 إلى الآس). اتجاه اللعب عكس عقارب الساعة — التالي هو من على يمينك.'**
  String get ruleBasicsBody;

  /// No description provided for @ruleDealTitle.
  ///
  /// In ar, this message translates to:
  /// **'التوزيع'**
  String get ruleDealTitle;

  /// No description provided for @ruleDealBody.
  ///
  /// In ar, this message translates to:
  /// **'يوزَّع 3 ثم 2، ثم دور الضمانة، ثم 3 أخيرة (8 لكل لاعب). يمين الموزّع أوّل من يضمن ويلعب، وهو موزّع الجولة القادمة.'**
  String get ruleDealBody;

  /// No description provided for @ruleBidTitle.
  ///
  /// In ar, this message translates to:
  /// **'الضمانة'**
  String get ruleBidTitle;

  /// No description provided for @ruleBidBody.
  ///
  /// In ar, this message translates to:
  /// **'دورة واحدة بالضبط (4 أدوار). اللاعب الأول لا يمرّ. الرفع فقط — لا فتح دورة جديدة بعد الرفع. اللون المضمون هو الحكم.'**
  String get ruleBidBody;

  /// No description provided for @ruleAkwinsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأكوينس'**
  String get ruleAkwinsTitle;

  /// No description provided for @ruleAkwinsBody.
  ///
  /// In ar, this message translates to:
  /// **'للخصم فقط، في دوره فقط — يوقف الضمانة فورًا ويضاعف قيمة الجولة (32 للّون · 52 لصن/تو).'**
  String get ruleAkwinsBody;

  /// No description provided for @rulePlayTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللعب'**
  String get rulePlayTitle;

  /// No description provided for @rulePlayBody.
  ///
  /// In ar, this message translates to:
  /// **'إن ملكتَ لون الافتتاح فالْزَمه. إن لم تملكه فالعب أي ورقة — ولا تُجبر على القصّ بالحكم ولا على تجاوز أعلى حكم.'**
  String get rulePlayBody;

  /// No description provided for @ruleUnitsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوحدات'**
  String get ruleUnitsTitle;

  /// No description provided for @ruleUnitsBody.
  ///
  /// In ar, this message translates to:
  /// **'في الحكم: J=20 و9=14. في اللون العادي: J=2 و9=0. الآس 11، العشرة 10، K=4، Q=3، و8/7 صفر. صن/تو: كل الألوان بسُلَّم الحكم.'**
  String get ruleUnitsBody;

  /// No description provided for @ruleFoujaTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفوجة'**
  String get ruleFoujaTitle;

  /// No description provided for @ruleFoujaBody.
  ///
  /// In ar, this message translates to:
  /// **'عدم اتباع اللون رغم امتلاكه. للخصم أن يعترض متى اكتشفها؛ إن ثبتت أخذ المعترِض قيمة الضمانة كاملة، وإن كان الاتهام خاطئًا أخذها الطرف الآخر. وتتوقف الجولة فورًا.'**
  String get ruleFoujaBody;

  /// No description provided for @ruleWinTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفوز'**
  String get ruleWinTitle;

  /// No description provided for @ruleWinBody.
  ///
  /// In ar, this message translates to:
  /// **'أوّل من يبلغ 100 نقطة والأعلى يفوز بالمباراة. عند التعادل عند 100 فأكثر تُلعب جولة فاصلة.'**
  String get ruleWinBody;

  /// No description provided for @momentMvp.
  ///
  /// In ar, this message translates to:
  /// **'رجل المباراة'**
  String get momentMvp;

  /// No description provided for @momentBestBid.
  ///
  /// In ar, this message translates to:
  /// **'أفضل إعلان'**
  String get momentBestBid;

  /// No description provided for @momentBestBidDetail.
  ///
  /// In ar, this message translates to:
  /// **'جنى {points} نقطة في الجولة {round}'**
  String momentBestBidDetail(int points, int round);

  /// No description provided for @momentStrongestCard.
  ///
  /// In ar, this message translates to:
  /// **'أقوى ورقة'**
  String get momentStrongestCard;

  /// No description provided for @momentStrongestCardDetail.
  ///
  /// In ar, this message translates to:
  /// **'خطفت {units} وحدةً في أبليٍّ واحد'**
  String momentStrongestCardDetail(int units);

  /// No description provided for @momentLongestStreak.
  ///
  /// In ar, this message translates to:
  /// **'أطول سلسلة'**
  String get momentLongestStreak;

  /// No description provided for @momentLongestStreakDetail.
  ///
  /// In ar, this message translates to:
  /// **'{count} أبالٍ متتاليةً بلا أن يقطعها أحد'**
  String momentLongestStreakDetail(int count);

  /// No description provided for @matchMoments.
  ///
  /// In ar, this message translates to:
  /// **'لحظات المباراة'**
  String get matchMoments;

  /// No description provided for @tricksCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} أبالٍ'**
  String tricksCount(int count);

  /// No description provided for @unitsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} وحدة'**
  String unitsCount(int count);

  /// No description provided for @bidsWonCount.
  ///
  /// In ar, this message translates to:
  /// **'وفّى بـ{count} ضمانة'**
  String bidsWonCount(int count);

  /// No description provided for @foujaCaughtCount.
  ///
  /// In ar, this message translates to:
  /// **'كشف {count} فوجة'**
  String foujaCaughtCount(int count);

  /// No description provided for @bidWithAkwinsShort.
  ///
  /// In ar, this message translates to:
  /// **'{bid} أكوينس'**
  String bidWithAkwinsShort(String bid);

  /// No description provided for @youSuffix.
  ///
  /// In ar, this message translates to:
  /// **'{name} (أنت)'**
  String youSuffix(String name);

  /// No description provided for @authTagline.
  ///
  /// In ar, this message translates to:
  /// **'العب مع أصدقائك حول العالم'**
  String get authTagline;

  /// No description provided for @createAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get createAccount;

  /// No description provided for @desktopAuthNote.
  ///
  /// In ar, this message translates to:
  /// **'إنشاءُ الحساب واستعادةُ كلمة السرّ يحتاجان رمزًا بالرسائل ⇒ من تطبيق الهاتف. وتسجيلُ الدخول هنا يعمل كاملًا.'**
  String get desktopAuthNote;

  /// No description provided for @continueAsGuest.
  ///
  /// In ar, this message translates to:
  /// **'الدخول كضيف'**
  String get continueAsGuest;

  /// No description provided for @invalidPhone.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتف صالحًا'**
  String get invalidPhone;

  /// No description provided for @phoneAuthUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'الدخول بالهاتف غير مدعوم على هذه المنصّة'**
  String get phoneAuthUnsupported;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكوَّن من ٦ أرقام'**
  String get enterSixDigitCode;

  /// No description provided for @passwordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السرّ ٦ أحرف على الأقلّ'**
  String get passwordTooShort;

  /// No description provided for @enterPassword.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة السرّ'**
  String get enterPassword;

  /// No description provided for @enterYourName.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك'**
  String get enterYourName;

  /// No description provided for @enterYourCity.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مدينتك'**
  String get enterYourCity;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة السرّ'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSub.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقمك لنرسل رمز تأكيد'**
  String get resetPasswordSub;

  /// No description provided for @sendCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get sendCode;

  /// No description provided for @codeTitle.
  ///
  /// In ar, this message translates to:
  /// **'رمز التأكيد'**
  String get codeTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المُرسَل إلى {phone}'**
  String codeSentTo(String phone);

  /// No description provided for @verify.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق'**
  String get verify;

  /// No description provided for @newPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سرّ جديدة'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSub.
  ///
  /// In ar, this message translates to:
  /// **'اختر كلمة سرّ جديدة لحسابك'**
  String get newPasswordSub;

  /// No description provided for @saveAndSignIn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ ودخول'**
  String get saveAndSignIn;

  /// No description provided for @fieldPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get fieldPhone;

  /// No description provided for @fieldNewPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السرّ الجديدة'**
  String get fieldNewPassword;

  /// No description provided for @fieldPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السرّ'**
  String get fieldPassword;

  /// No description provided for @fieldPasswordMin.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السرّ (٦ أحرف على الأقلّ)'**
  String get fieldPasswordMin;

  /// No description provided for @fieldName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get fieldName;

  /// No description provided for @fieldCity.
  ///
  /// In ar, this message translates to:
  /// **'المدينة / الولاية'**
  String get fieldCity;

  /// No description provided for @loginSub.
  ///
  /// In ar, this message translates to:
  /// **'ادخل برقم هاتفك وكلمة السرّ'**
  String get loginSub;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة السرّ؟'**
  String get forgotPassword;

  /// No description provided for @noAccountCreateOne.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟ أنشئ حسابًا'**
  String get noAccountCreateOne;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب؟ سجّل الدخول'**
  String get haveAccountSignIn;

  /// No description provided for @registerPhoneSub.
  ///
  /// In ar, this message translates to:
  /// **'سنرسل رمزًا لتأكيد رقمك'**
  String get registerPhoneSub;

  /// No description provided for @completeAccount.
  ///
  /// In ar, this message translates to:
  /// **'أكمل حسابك'**
  String get completeAccount;

  /// No description provided for @completeAccountSub.
  ///
  /// In ar, this message translates to:
  /// **'كلمة سرّ للدخول لاحقًا، واسمك ودولتك ومدينتك'**
  String get completeAccountSub;

  /// No description provided for @createAccountAction.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get createAccountAction;

  /// No description provided for @dmConnectionFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتّصال بالخادم.'**
  String get dmConnectionFailed;

  /// No description provided for @sendFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الإرسال — تحقّق من الاتّصال.'**
  String get sendFailed;

  /// No description provided for @blockTitle.
  ///
  /// In ar, this message translates to:
  /// **'حظر {name}؟'**
  String blockTitle(String name);

  /// No description provided for @blockBody.
  ///
  /// In ar, this message translates to:
  /// **'يُحذف من أصدقائك، ولا يراسلك ولا يدعوك، ولا يصلك كلامه على الطاولة.'**
  String get blockBody;

  /// No description provided for @blockConfirm.
  ///
  /// In ar, this message translates to:
  /// **'احظر'**
  String get blockConfirm;

  /// No description provided for @reportPlayerMenu.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ عن اللاعب'**
  String get reportPlayerMenu;

  /// No description provided for @blockMenu.
  ///
  /// In ar, this message translates to:
  /// **'حظر'**
  String get blockMenu;

  /// No description provided for @writeMessageHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالةً…'**
  String get writeMessageHint;

  /// No description provided for @noMessagesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا رسائلَ بعد — ابدأ الحديث.'**
  String get noMessagesYet;

  /// No description provided for @reportAbout.
  ///
  /// In ar, this message translates to:
  /// **'بلاغ عن {name}'**
  String reportAbout(String name);

  /// No description provided for @reportNote.
  ///
  /// In ar, this message translates to:
  /// **'يصل البلاغ إدارةَ اللعبة وتُراجعه بنفسها.'**
  String get reportNote;

  /// No description provided for @reportHint.
  ///
  /// In ar, this message translates to:
  /// **'ما الذي حدث؟ (اختياريّ)'**
  String get reportHint;

  /// No description provided for @giftRose.
  ///
  /// In ar, this message translates to:
  /// **'وردة'**
  String get giftRose;

  /// No description provided for @giftTea.
  ///
  /// In ar, this message translates to:
  /// **'أتاي'**
  String get giftTea;

  /// No description provided for @giftSweet.
  ///
  /// In ar, this message translates to:
  /// **'حلوى'**
  String get giftSweet;

  /// No description provided for @giftCrown.
  ///
  /// In ar, this message translates to:
  /// **'تاج'**
  String get giftCrown;

  /// No description provided for @giftCamel.
  ///
  /// In ar, this message translates to:
  /// **'جمل'**
  String get giftCamel;

  /// No description provided for @giftCar.
  ///
  /// In ar, this message translates to:
  /// **'سيّارة'**
  String get giftCar;

  /// No description provided for @giftVipFlower.
  ///
  /// In ar, this message translates to:
  /// **'وردةُ VIP'**
  String get giftVipFlower;

  /// No description provided for @giftVipBox.
  ///
  /// In ar, this message translates to:
  /// **'صندوقُ VIP'**
  String get giftVipBox;

  /// No description provided for @giftVipPitcher.
  ///
  /// In ar, this message translates to:
  /// **'بَراد VIP'**
  String get giftVipPitcher;

  /// No description provided for @giftTitle.
  ///
  /// In ar, this message translates to:
  /// **'إهداء'**
  String get giftTitle;

  /// No description provided for @giftHumansOnly.
  ///
  /// In ar, this message translates to:
  /// **'الهدايا للاعبين البشر — ولا يجلس معك الآن غير الذكاء.\nادعُ صاحبك إلى طاولةٍ خاصّة لتُهديه.'**
  String get giftHumansOnly;

  /// No description provided for @giftToWhom.
  ///
  /// In ar, this message translates to:
  /// **'إلى مَن؟'**
  String get giftToWhom;

  /// No description provided for @giftToAll.
  ///
  /// In ar, this message translates to:
  /// **'للجميع'**
  String get giftToAll;

  /// No description provided for @vipGifts.
  ///
  /// In ar, this message translates to:
  /// **'هدايا VIP'**
  String get vipGifts;

  /// No description provided for @remainingCount.
  ///
  /// In ar, this message translates to:
  /// **'بقيت {count}'**
  String remainingCount(int count);

  /// No description provided for @giftWhat.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تُهدي؟'**
  String get giftWhat;

  /// No description provided for @giftAllCostNote.
  ///
  /// In ar, this message translates to:
  /// **'تصل الهديّةُ إلى {count} لاعبين — ويُخصم ثمنُها لكلٍّ منهم.'**
  String giftAllCostNote(int count);

  /// No description provided for @giftCostNote.
  ///
  /// In ar, this message translates to:
  /// **'يُخصم الثمن من ماسك.'**
  String get giftCostNote;

  /// No description provided for @claimFailedRetry.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاستلام — حاول ثانيةً'**
  String get claimFailedRetry;

  /// No description provided for @activateFailedRetry.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التفعيل — حاول ثانيةً'**
  String get activateFailedRetry;

  /// No description provided for @giftDayTitle.
  ///
  /// In ar, this message translates to:
  /// **'هديّةٌ منّا: يومٌ كامل'**
  String get giftDayTitle;

  /// No description provided for @openFullDayTitle.
  ///
  /// In ar, this message translates to:
  /// **'افتح يومًا كاملًا'**
  String get openFullDayTitle;

  /// No description provided for @playLimitGiftBody.
  ///
  /// In ar, this message translates to:
  /// **'انتهت لعباتُك الخمسُ اليوم — وهذه أوّلُ مرّة. خذ 24 ساعةً بلا حدودٍ منّا، والعب ما شئت مع أصدقائك.'**
  String get playLimitGiftBody;

  /// No description provided for @playLimitPlainBody.
  ///
  /// In ar, this message translates to:
  /// **'انتهت لعباتُك اليوم — تعود غدًا.'**
  String get playLimitPlainBody;

  /// No description provided for @playLimitOfferBody.
  ///
  /// In ar, this message translates to:
  /// **'انتهت لعباتُك الخمسُ اليوم. فعّل اللعب بلا حدودٍ 24 ساعةً والعب ما شئت مع أصدقائك.'**
  String get playLimitOfferBody;

  /// No description provided for @offlineAlwaysFree.
  ///
  /// In ar, this message translates to:
  /// **'واللعبُ مع الذكاء يبقى مجّانيًّا بلا حدود.'**
  String get offlineAlwaysFree;

  /// No description provided for @claimGift.
  ///
  /// In ar, this message translates to:
  /// **'استلم الهديّة'**
  String get claimGift;

  /// No description provided for @activateNow.
  ///
  /// In ar, this message translates to:
  /// **'فعّل الآن'**
  String get activateNow;

  /// No description provided for @yourTable.
  ///
  /// In ar, this message translates to:
  /// **'طاولتك'**
  String get yourTable;

  /// No description provided for @seatRoleYou.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get seatRoleYou;

  /// No description provided for @seatRoleYourPartner.
  ///
  /// In ar, this message translates to:
  /// **'شريكك'**
  String get seatRoleYourPartner;

  /// No description provided for @seatRoleYourOpponent.
  ///
  /// In ar, this message translates to:
  /// **'خصمك'**
  String get seatRoleYourOpponent;

  /// No description provided for @inviteShort.
  ///
  /// In ar, this message translates to:
  /// **'ادعُ'**
  String get inviteShort;

  /// No description provided for @whoSitsHere.
  ///
  /// In ar, this message translates to:
  /// **'من يجلس {role}؟'**
  String whoSitsHere(String role);

  /// No description provided for @noFriendsAddByTag.
  ///
  /// In ar, this message translates to:
  /// **'لا أصدقاء بعد. أضِف صاحبك برمزه من شاشة الأصدقاء.'**
  String get noFriendsAddByTag;

  /// No description provided for @noFriendOnlineInviteAnyway.
  ///
  /// In ar, this message translates to:
  /// **'لا صديق متّصلٌ الآن — ادعُه على أيّ حال، يصله إشعارٌ على هاتفه.'**
  String get noFriendOnlineInviteAnyway;

  /// No description provided for @offlineGroup.
  ///
  /// In ar, this message translates to:
  /// **'غير متّصلين'**
  String get offlineGroup;

  /// No description provided for @offlineWillBeNotified.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل — يصله إشعار'**
  String get offlineWillBeNotified;

  /// No description provided for @welcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك'**
  String get welcomeTitle;

  /// No description provided for @welcomeGiftsBody.
  ///
  /// In ar, this message translates to:
  /// **'هذه هديّتُنا لك — أهدِها لمن تلعب معه.'**
  String get welcomeGiftsBody;

  /// No description provided for @thanks.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا'**
  String get thanks;

  /// No description provided for @aboutGameTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيلوت'**
  String get aboutGameTitle;

  /// No description provided for @aboutMauritanianEdition.
  ///
  /// In ar, this message translates to:
  /// **'النسخة الموريتانية'**
  String get aboutMauritanianEdition;

  /// No description provided for @aboutSection.
  ///
  /// In ar, this message translates to:
  /// **'عن اللعبة'**
  String get aboutSection;

  /// No description provided for @aboutBody.
  ///
  /// In ar, this message translates to:
  /// **'بيلوت كما تُلعب في موريتانيا: أربعة لاعبين، فريقان، وضمانةٌ بدورةٍ واحدة، والأكوينس للخصم في دوره. قواعدُها كاملةً في «كيف تلعب».'**
  String get aboutBody;

  /// No description provided for @aboutDevSection.
  ///
  /// In ar, this message translates to:
  /// **'برمجة وتطوير'**
  String get aboutDevSection;

  /// No description provided for @aboutMadeWithLove.
  ///
  /// In ar, this message translates to:
  /// **'صُنعت بشغفٍ للعبة أهلها 🃏'**
  String get aboutMadeWithLove;

  /// No description provided for @aboutVersionSection.
  ///
  /// In ar, this message translates to:
  /// **'إصدار التطبيق'**
  String get aboutVersionSection;

  /// No description provided for @appInitial.
  ///
  /// In ar, this message translates to:
  /// **'ب'**
  String get appInitial;

  /// No description provided for @giveGift.
  ///
  /// In ar, this message translates to:
  /// **'أهدِه'**
  String get giveGift;

  /// No description provided for @unmutePlayer.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء كتم {name}'**
  String unmutePlayer(String name);

  /// No description provided for @mutePlayer.
  ///
  /// In ar, this message translates to:
  /// **'اكتم {name}'**
  String mutePlayer(String name);

  /// No description provided for @relFriend.
  ///
  /// In ar, this message translates to:
  /// **'صديقك'**
  String get relFriend;

  /// No description provided for @relOutgoing.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار ردّه'**
  String get relOutgoing;

  /// No description provided for @relIncoming.
  ///
  /// In ar, this message translates to:
  /// **'اقبل صداقته'**
  String get relIncoming;

  /// No description provided for @relAdd.
  ///
  /// In ar, this message translates to:
  /// **'أضِف صديقًا'**
  String get relAdd;

  /// No description provided for @signInToWatch.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لمشاهدة المباريات.'**
  String get signInToWatch;

  /// No description provided for @liveFetchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب المباريات — تحقّق من الاتّصال.'**
  String get liveFetchFailed;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @tournamentChip.
  ///
  /// In ar, this message translates to:
  /// **'بطولة'**
  String get tournamentChip;

  /// No description provided for @versusShort.
  ///
  /// In ar, this message translates to:
  /// **'ضد'**
  String get versusShort;

  /// No description provided for @watchMatch.
  ///
  /// In ar, this message translates to:
  /// **'شاهد المباراة'**
  String get watchMatch;

  /// No description provided for @updateNewVersion.
  ///
  /// In ar, this message translates to:
  /// **'نسخة جديدة {version}'**
  String updateNewVersion(String version);

  /// No description provided for @updateAvailable.
  ///
  /// In ar, this message translates to:
  /// **'تتوفّر نسخة أحدث من اللعبة.'**
  String get updateAvailable;

  /// No description provided for @updateFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحديث'**
  String get updateFailed;

  /// No description provided for @installing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التثبيت…'**
  String get installing;

  /// No description provided for @downloading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التنزيل… {percent}%'**
  String downloading(int percent);

  /// No description provided for @updateNow.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الآن'**
  String get updateNow;

  /// No description provided for @voiceLive.
  ///
  /// In ar, this message translates to:
  /// **'صوتي مفتوح — اضغط لقطع الصوت'**
  String get voiceLive;

  /// No description provided for @voiceConnecting.
  ///
  /// In ar, this message translates to:
  /// **'يتّصل…'**
  String get voiceConnecting;

  /// No description provided for @voiceFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الصوت — اضغط للمحاولة'**
  String get voiceFailed;

  /// No description provided for @voiceOff.
  ///
  /// In ar, this message translates to:
  /// **'الصوت مقطوع — اضغط لتتكلّم'**
  String get voiceOff;

  /// No description provided for @giftToAllTip.
  ///
  /// In ar, this message translates to:
  /// **'هديّة للجميع'**
  String get giftToAllTip;

  /// No description provided for @giftToPlayer.
  ///
  /// In ar, this message translates to:
  /// **'هديّة لِ{name}'**
  String giftToPlayer(String name);

  /// No description provided for @markAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكلّ'**
  String get markAllRead;

  /// No description provided for @agoNow.
  ///
  /// In ar, this message translates to:
  /// **'الآن'**
  String get agoNow;

  /// No description provided for @agoMinutes.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} دقيقة'**
  String agoMinutes(int count);

  /// No description provided for @agoHours.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} ساعة'**
  String agoHours(int count);

  /// No description provided for @agoDays.
  ///
  /// In ar, this message translates to:
  /// **'منذ {count} يوم'**
  String agoDays(int count);

  /// No description provided for @honorBoardWeek.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الشرف — هذا الأسبوع'**
  String get honorBoardWeek;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'الكلّ'**
  String get seeAll;

  /// No description provided for @honorBoardNote.
  ///
  /// In ar, this message translates to:
  /// **'الأوّلُ في كلّ فئةٍ يحمل لقبَها طوال الأسبوع القادم — يراه كلُّ من يجلس معه.'**
  String get honorBoardNote;

  /// No description provided for @honorBoard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الشرف'**
  String get honorBoard;

  /// No description provided for @playerCardDemo.
  ///
  /// In ar, this message translates to:
  /// **'بطاقة اللاعب'**
  String get playerCardDemo;

  /// No description provided for @playerCardDemoSub.
  ///
  /// In ar, this message translates to:
  /// **'عاديّة · نشطة (صاحب الدور)'**
  String get playerCardDemoSub;

  /// No description provided for @rankNextTitle.
  ///
  /// In ar, this message translates to:
  /// **'{title} · التالية: {next}'**
  String rankNextTitle(String title, String next);

  /// No description provided for @leaderboardFetchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب التصنيف'**
  String get leaderboardFetchFailed;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا تصنيف بعد — العب مباريات أونلاين لتظهر هنا.'**
  String get leaderboardEmpty;

  /// No description provided for @matchesAndWins.
  ///
  /// In ar, this message translates to:
  /// **'{matches} مباراة · {wins} فوز'**
  String matchesAndWins(int matches, int wins);

  /// No description provided for @chatTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدردشة'**
  String get chatTitle;

  /// No description provided for @vipUpsellTitle.
  ///
  /// In ar, this message translates to:
  /// **'لماذا لا تصير VIP؟'**
  String get vipUpsellTitle;

  /// No description provided for @vipUpsellBody.
  ///
  /// In ar, this message translates to:
  /// **'تشتري التذاكرَ كثيرًا — والشهرُ الكاملُ من VIP بثمن عشرِ تذاكرٍ فقط، ومعه لعبٌ بلا حدود، ومجلسٌ خاصّ، وهدايا حصريّة، و50💎 كلَّ شهر.'**
  String get vipUpsellBody;

  /// No description provided for @seeVip.
  ///
  /// In ar, this message translates to:
  /// **'شاهد VIP'**
  String get seeVip;

  /// No description provided for @friendFallback.
  ///
  /// In ar, this message translates to:
  /// **'صديقك'**
  String get friendFallback;

  /// No description provided for @invitesYou.
  ///
  /// In ar, this message translates to:
  /// **'{name} يدعوك'**
  String invitesYou(String name);

  /// No description provided for @inviteToPrivateTable.
  ///
  /// In ar, this message translates to:
  /// **'إلى طاولته الخاصّة — مقعدٌ محجوزٌ لك.'**
  String get inviteToPrivateTable;

  /// No description provided for @nameEntryPrompt.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك — اكتب اسمك للبدء'**
  String get nameEntryPrompt;

  /// No description provided for @nameHint.
  ///
  /// In ar, this message translates to:
  /// **'اسمك'**
  String get nameHint;

  /// No description provided for @start.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get start;

  /// No description provided for @profileOf.
  ///
  /// In ar, this message translates to:
  /// **'ملفّ {name}'**
  String profileOf(String name);

  /// No description provided for @messagesTip.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل'**
  String get messagesTip;

  /// No description provided for @latestNews.
  ///
  /// In ar, this message translates to:
  /// **'آخر الأخبار'**
  String get latestNews;

  /// No description provided for @rankedMatchesLeft.
  ///
  /// In ar, this message translates to:
  /// **'تبقّت {count} مباراةً مصنَّفةً للتصنيف'**
  String rankedMatchesLeft(int count);

  /// No description provided for @ratingLabel.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف '**
  String get ratingLabel;

  /// No description provided for @rankedMatchesLeftLong.
  ///
  /// In ar, this message translates to:
  /// **'تبقّت {count} مباراةً مصنَّفةً لتحصل على رتبتك'**
  String rankedMatchesLeftLong(int count);

  /// No description provided for @rankTopReached.
  ///
  /// In ar, this message translates to:
  /// **'بلغتَ أعلى السُّلَّم — الأسطورةُ تُدافع لا تصعد'**
  String get rankTopReached;

  /// No description provided for @rankPointsToNext.
  ///
  /// In ar, this message translates to:
  /// **'إلى {title}: {points} نقطة تصنيف'**
  String rankPointsToNext(String title, int points);

  /// No description provided for @reportAction.
  ///
  /// In ar, this message translates to:
  /// **'أبلِغ'**
  String get reportAction;

  /// No description provided for @pointsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} نقطة'**
  String pointsCount(int count);

  /// No description provided for @developerName.
  ///
  /// In ar, this message translates to:
  /// **'محمد الأمين / تقرة / بينة'**
  String get developerName;

  /// No description provided for @languageArabicNative.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabicNative;

  /// No description provided for @demoNameOne.
  ///
  /// In ar, this message translates to:
  /// **'أحمدو'**
  String get demoNameOne;

  /// No description provided for @demoNameTwo.
  ///
  /// In ar, this message translates to:
  /// **'المختار'**
  String get demoNameTwo;

  /// No description provided for @demoNameThree.
  ///
  /// In ar, this message translates to:
  /// **'سيدي أحمد'**
  String get demoNameThree;

  /// No description provided for @demoNameFour.
  ///
  /// In ar, this message translates to:
  /// **'بَبَّه'**
  String get demoNameFour;

  /// No description provided for @errFriendInvalidTag.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح — ٦ خانات كما تظهر في ملفّ صاحبك.'**
  String get errFriendInvalidTag;

  /// No description provided for @errFriendNotFound.
  ///
  /// In ar, this message translates to:
  /// **'لا لاعب بهذا الرمز. تأكّد منه.'**
  String get errFriendNotFound;

  /// No description provided for @errFriendSelf.
  ///
  /// In ar, this message translates to:
  /// **'هذا رمزك أنت.'**
  String get errFriendSelf;

  /// No description provided for @errFriendAlready.
  ///
  /// In ar, this message translates to:
  /// **'بينكما طلبٌ أو صداقةٌ بالفعل.'**
  String get errFriendAlready;

  /// No description provided for @errFriendNoRequest.
  ///
  /// In ar, this message translates to:
  /// **'لا طلبَ ينتظر ردَّك من هذا اللاعب.'**
  String get errFriendNoRequest;

  /// No description provided for @errFriendNotFriend.
  ///
  /// In ar, this message translates to:
  /// **'لا علاقة بينكما أصلًا.'**
  String get errFriendNotFriend;

  /// No description provided for @errMessageNotFriend.
  ///
  /// In ar, this message translates to:
  /// **'الرسائل بين الأصدقاء — أضفه صديقًا أوّلًا.'**
  String get errMessageNotFriend;

  /// No description provided for @errMessageBlocked.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن مراسلة هذا اللاعب.'**
  String get errMessageBlocked;

  /// No description provided for @errMessageEmpty.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالةً أوّلًا.'**
  String get errMessageEmpty;

  /// No description provided for @errBlockNotFound.
  ///
  /// In ar, this message translates to:
  /// **'اللاعب غير موجود.'**
  String get errBlockNotFound;

  /// No description provided for @errBlockSelf.
  ///
  /// In ar, this message translates to:
  /// **'لا تحظر نفسك.'**
  String get errBlockSelf;

  /// No description provided for @errAvatarTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الصورة كبيرة. اختر واحدةً أصغر.'**
  String get errAvatarTooLarge;

  /// No description provided for @errAvatarBadType.
  ///
  /// In ar, this message translates to:
  /// **'هذا ليس ملفَّ صورة. اختر صورةً (JPG أو PNG).'**
  String get errAvatarBadType;

  /// No description provided for @errAvatarEmpty.
  ///
  /// In ar, this message translates to:
  /// **'الملفّ فارغ.'**
  String get errAvatarEmpty;

  /// No description provided for @errTrnClosed.
  ///
  /// In ar, this message translates to:
  /// **'بطولةٌ جاريةٌ الآن — التسجيل بعد نهايتها.'**
  String get errTrnClosed;

  /// No description provided for @errTrnAlreadyRegistered.
  ///
  /// In ar, this message translates to:
  /// **'أنت مسجَّلٌ أصلًا.'**
  String get errTrnAlreadyRegistered;

  /// No description provided for @errTrnNotRegistered.
  ///
  /// In ar, this message translates to:
  /// **'لستَ مسجَّلًا في هذه البطولة.'**
  String get errTrnNotRegistered;

  /// No description provided for @errTrnFull.
  ///
  /// In ar, this message translates to:
  /// **'اكتمل العدد — بطولةٌ قادمةٌ تفتح قريبًا.'**
  String get errTrnFull;

  /// No description provided for @errTrnInsufficient.
  ///
  /// In ar, this message translates to:
  /// **'ماسُك لا يكفي لرسم الدخول.'**
  String get errTrnInsufficient;

  /// No description provided for @errTrnNotFriends.
  ///
  /// In ar, this message translates to:
  /// **'الشراكة بين الأصدقاء — أضفه صديقًا أوّلًا.'**
  String get errTrnNotFriends;

  /// No description provided for @errTrnPairTaken.
  ///
  /// In ar, this message translates to:
  /// **'لأحدكما شريكٌ أو دعوةٌ قائمة.'**
  String get errTrnPairTaken;

  /// No description provided for @errTrnNoInvite.
  ///
  /// In ar, this message translates to:
  /// **'لا دعوةَ شراكةٍ قائمة.'**
  String get errTrnNoInvite;

  /// No description provided for @errTrnBadRequest.
  ///
  /// In ar, this message translates to:
  /// **'طلبٌ غير صالح.'**
  String get errTrnBadRequest;

  /// No description provided for @errTrnHasActiveEvent.
  ///
  /// In ar, this message translates to:
  /// **'لك مسابقةٌ قائمة — أكملها أو ألغِها أوّلًا.'**
  String get errTrnHasActiveEvent;

  /// No description provided for @errTrnBadTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاسم من 3 إلى 30 حرفًا.'**
  String get errTrnBadTitle;

  /// No description provided for @errTrnBadFee.
  ///
  /// In ar, this message translates to:
  /// **'رسم الدخول من 10 إلى 500 ماسة.'**
  String get errTrnBadFee;

  /// No description provided for @errTrnBadTeams.
  ///
  /// In ar, this message translates to:
  /// **'الحجم: 8 أو 16 فريقًا.'**
  String get errTrnBadTeams;

  /// No description provided for @errTrnBadTime.
  ///
  /// In ar, this message translates to:
  /// **'الموعد بين 10 دقائق و7 أيّام من الآن.'**
  String get errTrnBadTime;

  /// No description provided for @chatSalam.
  ///
  /// In ar, this message translates to:
  /// **'سلامٌ عليكم'**
  String get chatSalam;

  /// No description provided for @chatNice.
  ///
  /// In ar, this message translates to:
  /// **'لعبةٌ جميلة'**
  String get chatNice;

  /// No description provided for @chatBravo.
  ///
  /// In ar, this message translates to:
  /// **'أحسنت'**
  String get chatBravo;

  /// No description provided for @chatLuck.
  ///
  /// In ar, this message translates to:
  /// **'بالتوفيق'**
  String get chatLuck;

  /// No description provided for @chatHurry.
  ///
  /// In ar, this message translates to:
  /// **'أسرِع قليلًا'**
  String get chatHurry;

  /// No description provided for @chatSorry.
  ///
  /// In ar, this message translates to:
  /// **'آسف'**
  String get chatSorry;

  /// No description provided for @chatThanks.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا'**
  String get chatThanks;

  /// No description provided for @chatBye.
  ///
  /// In ar, this message translates to:
  /// **'إلى اللقاء'**
  String get chatBye;

  /// No description provided for @guestOnlineTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللعب أونلاين'**
  String get guestOnlineTitle;

  /// No description provided for @guestOnlineBody.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابًا للّعب مع لاعبين حقيقيّين وحفظ تقدّمك ورصيدك.'**
  String get guestOnlineBody;

  /// No description provided for @spectator.
  ///
  /// In ar, this message translates to:
  /// **'مشاهد'**
  String get spectator;

  /// No description provided for @giftSentTo.
  ///
  /// In ar, this message translates to:
  /// **'{from} أهدى {to}'**
  String giftSentTo(String from, String to);

  /// No description provided for @voiceNotEnabled.
  ///
  /// In ar, this message translates to:
  /// **'الصوت غير مُفعَّلٍ على الخادم بعد.'**
  String get voiceNotEnabled;

  /// No description provided for @voiceNotAtTable.
  ///
  /// In ar, this message translates to:
  /// **'لست على طاولة.'**
  String get voiceNotAtTable;

  /// No description provided for @voiceSessionOver.
  ///
  /// In ar, this message translates to:
  /// **'انتهت جلستك — أعِد الدخول.'**
  String get voiceSessionOver;

  /// No description provided for @voiceConnectFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتّصال بالصوت. تأكّد من إذن الميكروفون والشبكة.'**
  String get voiceConnectFailed;

  /// No description provided for @errUnexpectedShort.
  ///
  /// In ar, this message translates to:
  /// **'خطأ غير متوقّع'**
  String get errUnexpectedShort;

  /// No description provided for @errPhoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف غير صحيح'**
  String get errPhoneInvalid;

  /// No description provided for @errCodeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح'**
  String get errCodeInvalid;

  /// No description provided for @errCodeExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الرمز — اطلب رمزًا جديدًا'**
  String get errCodeExpired;

  /// No description provided for @errTooManyAttempts.
  ///
  /// In ar, this message translates to:
  /// **'محاولاتٌ كثيرة — حاول لاحقًا'**
  String get errTooManyAttempts;

  /// No description provided for @errQuotaExceeded.
  ///
  /// In ar, this message translates to:
  /// **'تجاوزتَ الحصّة المسموحة — حاول لاحقًا'**
  String get errQuotaExceeded;

  /// No description provided for @errNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال بالشبكة'**
  String get errNetwork;

  /// No description provided for @errVerifyFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التحقّق'**
  String get errVerifyFailed;

  /// No description provided for @errNoCodeSent.
  ///
  /// In ar, this message translates to:
  /// **'لم يُرسَل رمزٌ بعد'**
  String get errNoCodeSent;

  /// No description provided for @errTokenFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إصدار توكن الدخول'**
  String get errTokenFailed;

  /// No description provided for @errInstallAndroidOnly.
  ///
  /// In ar, this message translates to:
  /// **'التثبيت داخل التطبيق مدعوم على أندرويد فقط'**
  String get errInstallAndroidOnly;

  /// No description provided for @errInstallPermission.
  ///
  /// In ar, this message translates to:
  /// **'فعّل «السماح من هذا المصدر» ثمّ اضغط إعادة المحاولة'**
  String get errInstallPermission;

  /// No description provided for @errDownloadFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل التنزيل (رمز {code})'**
  String errDownloadFailed(int code);

  /// No description provided for @errDownloadIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'التنزيل غير مكتمل — حاول لاحقًا'**
  String get errDownloadIncomplete;

  /// No description provided for @errInstallerOpen.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح المثبّت ({reason})'**
  String errInstallerOpen(String reason);

  /// No description provided for @errUpdateGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر التحديث — تحقّق من الاتصال وحاول لاحقًا'**
  String get errUpdateGeneric;
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
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
