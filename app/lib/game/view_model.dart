import 'package:belote_engine/belote_engine.dart';

/// طور الجولة كما تراه الواجهة.
/// `dealing` طورٌ عرضيّ قصير قبل الضمانة: يوزَّع الورق من مقعد الموزّع.
enum GamePhase { dealing, bidding, playing, done }

/// ترتيب عرض الألوان في يد اللاعب — **تبديلٌ لونيّ** (أسود·أحمر·أسود·أحمر) كي لا
/// يتجاور لونان من نفس اللون البصريّ فيصعب تمييز أين ينتهي لون ويبدأ آخر.
/// عرضٌ محض؛ لا يمسّ `suits` في المحرك (ترتيب القواعد) ولا المرجع.
const handSuitOrder = <String>['trefle', 'coeur', 'pique', 'carreau']; // ♣ ♥ ♠ ♦

/// حدث صوتيّ يُطلقه الكنترولر ويترجمه `Sfx` إلى نغمة. تعريفه هنا (لا في `sfx.dart`)
/// كي يبقى الكنترولر حرًّا من اعتماد `audioplayers`؛ الوصل يتم في `main.dart`.
/// أحداث الصوت. تُربط بملفّات في `Sfx._assets`. الجديدة مربوطة مؤقّتًا بأصواتٍ
/// قائمة حتى يرفع صاحب المشروع ملفّاته الاحترافيّة (خلط/توزيع/قلب/وضع/جمع/نقطة/زرّ).
enum GameSound {
  shuffle, // خلط الرزمة
  deal, // توزيع ورقة
  cardFlip, // قلب ورقة
  cardPlay, // وضع ورقة على الطاولة
  cardCollect, // جمع الأبلي نحو الفائز
  pointWin, // (قديم) تسجيل نقطة — أُبقيَ للتوافق
  buttonClick, // ضغط زرّ
  fouja, // اعتراض فوجة (نفس صوت نهاية الجولة)
  turnTick, // تكتكة عدّاد الوقت في دورك
  roundEnd, // انتهاء جولة (وتُستعمَل للفوجة)
  win, // الفوز بالمباراة
  // ── الهدايا ── الإطلاقُ واحدٌ للجميع، والوصولُ **بالندرة**: ما دفعتَ فيه أكثرَ
  // يصل أعلى. الربطُ بالاسم لا بالملفّ ⇒ تسجيلٌ خاصٌّ يومًا ما يغيّر `Sfx` وحده.
  giftLaunch, // انطلاق هديّةٍ من مقعد المُرسِل
  giftArrive, // وصولُ هديّةٍ عاديّة/نادرة
  giftArriveEpic, // وصولُ هديّةٍ ملحميّة (جمل/سيّارة)
  giftArriveLegendary, // وصولُ حصريّة VIP
}

/// نتيجة الجولة المنتهية — يحسبها الكنترولر عبر `scoreRound`، وتعرضها اللوحة.
class RoundResult {
  final int usPoints; // نقاط فريقنا هذه الجولة
  final int themPoints;
  final int roundValue; // قيمة الجولة (16/32/26/52)
  final String reason; // 'ok' | 'chute' | 'akwins'
  final int usTotal; // رصيد المباراة بعد هذه الجولة
  final int themTotal;

  /// الثغرة المفتوحة #1: أكوينس + تعادل تام في الوحدات. لا حسم — تُعرض كإشعار.
  final bool openRuleAkwinsTie;

  /// عند `reason == 'fouja'`: هل ثبتت الفوجة (المتّهم فوّج فعلًا)؟ للرسالة في اللوحة.
  final bool? foujaProven;

  /// نتيجة المباراة إن انتهت: 0 نحن · 1 هم · 'tiebreak' · null لم تنتهِ.
  final Object? matchOutcome;

  const RoundResult({
    required this.usPoints,
    required this.themPoints,
    required this.roundValue,
    required this.reason,
    required this.usTotal,
    required this.themTotal,
    this.openRuleAkwinsTie = false,
    this.matchOutcome,
    this.foujaProven,
  });
}

/// **ملخّصُ المباراة جاهزًا للعرض** — الحصيلةُ من المحرّك، مقرونةً بأسماء الجالسين.
///
/// **الإحداثيّاتُ إحداثيّاتُ [insights]** لا إحداثيّاتُ العرض: الكنترولرُ (أوفلاين
/// أو أونلاين) هو من يعرف تحويلَ مقاعده، فيبني [names] و[mySeat] بها مرّةً واحدة.
/// ترجمةُ الحصيلة نفسِها كانت ستعني تدويرَ كلّ لقطةٍ فيها على حدة، وأولُ لقطةٍ
/// جديدةٍ تُنسى.
class MatchSummaryView {
  final MatchInsights insights;

  /// اسمُ صاحب كلّ مقعدٍ بإحداثيّات الحصيلة.
  final List<String> names;

  /// مقعدي أنا فيها — به تُلوَّن لقطاتي وتُقال «أنت».
  final int mySeat;

  const MatchSummaryView({
    required this.insights,
    required this.names,
    required this.mySeat,
  });

  String nameOf(int seat) =>
      (seat >= 0 && seat < names.length) ? names[seat] : 'لاعب';

  bool isMe(int seat) => seat == mySeat;

  /// أطولُ سلسلةِ أبالٍ حقّقها **أيُّ** مقعد — تُعرَض لصاحبها.
  bool get iWon => insights.winnerTeam == teamOf(mySeat);
}

/// خيار ضمانة واحد في الشريط، جاهز للعرض. القانونية محسوبة في الكنترولر
/// (عبر المحرك)؛ الشريط يعرض المعطّل ولا يخفيه، ولا يقرّر شيئًا.
class BidOption {
  final String label;

  /// لونُ الضمانة إن كانت ضمانةَ لون (`trefle`·`carreau`·`coeur`·`pique`)؛
  /// null لتمريرٍ أو صنٍّ أو توٍّ أو أكوينس. الواجهةُ ترسم **رمزَ اللون** بدله
  /// (طلبُ المالك 2026-07-22) — و[label] يبقى للقراءة والوصول (semantics).
  final String? suit;
  final BidAction action;
  final bool enabled;
  final bool isPass;
  final bool isAkwins;

  const BidOption({
    required this.label,
    required this.action,
    required this.enabled,
    this.suit,
    this.isPass = false,
    this.isAkwins = false,
  });
}

/// عقد عرض شريط الضمانة حين يكون الدور للاعب البشري.
class BidBarView {
  final List<BidOption> options; // تمرير + الستّ + أكوينس، بالترتيب
  final Bid? currentBid;
  const BidBarView({required this.options, required this.currentBid});
}

/// **عقد العرض**: لقطة ثابتة يملأها `GameController` وتعرضها `ui/` فقط.
///
/// هذا هو الحدّ الفاصل الذي يمنع تسرّب القواعد: الواجهة لا تحسب شيئًا —
/// تقرأ `legalCards` و`turn` و`trick` جاهزة، وتُطلق نيّة اللمس فحسب.
/// (الحارس `ui_no_rules_test` يمنع استدعاء دوال المحرك داخل ui/.)
class TableView {
  /// يد اللاعب البشري (المقعد 0)، بالترتيب المعروض.
  final List<Card> myHand;

  /// عدد الأوراق بيد كل مقعد 0..3 (لرسم مراوح الظهر).
  final List<int> handCounts;

  final int usScore;
  final int themScore;

  final Bid? bid;
  final int? bidderSeat;
  final bool akwins;

  /// مقعد الموزّع الحالي (يوزَّع الورق من عنده، ويُوسم بشارة).
  final int dealerSeat;

  /// آخر ما نطق به كل مقعد أثناء الضمانة (فقاعة أمامه)، أو null.
  /// يُفرَّغ عند انتقال الضمانة إلى مكانها الرسمي أعلى الشاشة.
  final List<String?> seatBids;

  /// صاحب الدور الآن (لتمييز مقعده).
  final int turn;

  /// الأوراق المرميّة على الطاولة في الأبلي الجاري.
  final List<Play> trick;

  /// أثناء جمع الأبلي: مقعد الفائز الذي تنجمع نحوه الأوراق (وإلّا null).
  final int? collectingTo;

  /// الأوراق القانونية للاعب البشري الآن (محسوبة في الكنترولر عبر المحرك).
  final Set<Card> legalCards;

  /// هل ينتظر المحرك أن يلعب اللاعب البشري ورقة الآن؟ (يدُه تفاعلية فقط حينها.)
  final bool humanCanPlay;

  final GamePhase phase;

  /// أثناء طور `dealing`: هل هذه نافذة التوزيع الثانية (الثلاث الباقية بعد الضمانة)؟
  /// تفرّق بين توزيع الافتتاح (٥ لكل لاعب) وتوزيع الباقي (٣) في طبقة التوزيع.
  final bool dealingRest;

  /// هل يجوز الآن الاعتراض بفوجة (طور اللعب، ولا لوحة مطالبة مفتوحة)؟ يُظهر زرّ الفوجة.
  final bool canAccuseFouja;

  /// هل لوحة اختيار الخصم المتّهَم مفتوحة الآن (يمين/يسار)؟ اللعب متوقّف حينها.
  /// تُفتح لصاحب الاعتراض وحده؛ بقيّة اللاعبين يرون لافتة التجميد ([foujaClaimBy]).
  final bool claimingFouja;

  /// مقعد العرض للاعبٍ يعترض بفوجة الآن ولمّا يختر الخصم — الطاولة مجمّدة عند الجميع.
  /// null ⇒ لا اعتراض جارٍ. حين يكون == 0 فالمعترِض أنت ([claimingFouja] عندها true).
  final int? foujaClaimBy;

  /// أيدي اللاعبين الأربعة مكشوفةً (عند المطالبة بفوجة وفي النتيجة)، أو null.
  /// الفهرس = المقعد. الواجهة ترسم ورق كل خصمٍ ظاهرًا أمامه بدل الظهر.
  final List<List<Card>>? revealedHands;

  /// مهلة دور اللاعب البشري (null ⇒ معطّلة). تُستخدم لعرض عدّاد تنازليّ في دورك.
  final Duration? humanTurnLimit;

  /// رقم متزايد يتغيّر مع كل بدء دورٍ للاعب — مفتاحٌ يُعيد تشغيل العدّاد التنازلي.
  final int humanTurnSeq;

  const TableView({
    required this.myHand,
    required this.handCounts,
    required this.usScore,
    required this.themScore,
    required this.bid,
    required this.bidderSeat,
    required this.akwins,
    required this.dealerSeat,
    required this.seatBids,
    required this.turn,
    required this.trick,
    this.collectingTo,
    required this.legalCards,
    this.humanCanPlay = false,
    required this.phase,
    this.dealingRest = false,
    this.canAccuseFouja = false,
    this.claimingFouja = false,
    this.foujaClaimBy,
    this.revealedHands,
    this.humanTurnLimit,
    this.humanTurnSeq = 0,
  });
}
