import 'dart:math';

import '../net/player_rank.dart';

/// رتبة اللاعب المعروضة على بطاقته — قيمةٌ **تُمرَّر** للبطاقة (لا تحسبها هي).
/// أربع درجات تصاعديّة. تسميتها العربيّة في `S.rankLabel`، ولونُ شارتها يُختار من
/// الثيم داخل البطاقة (أخضر للدرجتين الأدنى · ذهبيّ للأعلى) — لا رقم لونٍ في البطاقة.
enum PlayerRank { beginner, pro, expert, legend }

/// هويّة لاعبٍ على مقعد (بشريّ أو آليّ) — للعرض في بطاقة اللاعب على الطاولة.
/// الذكاء يُعطى اسمًا وتصنيفًا كي يبدو **كلاعبٍ حقيقيّ** (لا يُميَّز بصريًّا).
class SeatPlayer {
  final String name;
  final int? rating; // تصنيف ELO (قد يكون null قبل توفّره للبشر)
  final int level;
  final bool isAI;
  final bool isVip;
  final bool connected;

  /// إيموجي الصورة الرمزيّة على البطاقة (يُختار عند إنشاء اللاعب، لا في البطاقة).
  final String emoji;

  /// رابط صورته الحقيقيّة نسبيًّا (`/avatars/…`) — يأتي من لقطة الخادم. فارغٌ ⇒
  /// [emoji]. **الذكاء فارغٌ دائمًا**: لا حساب له فلا صورة — وهذا وحده ما قد يميّزه
  /// بصريًّا، ولاعبٌ بشريٌّ بلا صورةٍ يبدو مثله تمامًا.
  final String avatarUrl;

  /// **معرّفُ حسابه** — به تُفتَح لوحتُه عند الضغط على بطاقته على الطاولة.
  /// فارغٌ ⇒ لا حساب (ذكاءٌ أو أوفلاين) ⇒ **البطاقةُ لا تُضغَط**: لوحةُ ملفٍّ
  /// لروبوتٍ وعدٌ كاذب. معرّفٌ داخليٌّ لا الرمزَ المعروض ([[player-tag]]).
  final String playerId;

  /// **رتبةُ المهارة كما حسبها الخادم** ([[tiers.dart]]). `null` ⇒ ذكاءٌ أو أوفلاين
  /// أو خادمٌ أقدمُ من الميزة ⇒ تُعرَض [rank] المشتقّةُ محلّيًّا بدلَها.
  ///
  /// **الخادمُ يتقدّم المحلّيّ حين يوجد**: هو وحدَه يعرف عددَ المباريات (الترشيح)
  /// والسُّلَّمَ الحاليّ، وسُلَّمٌ محلّيٌّ في حزمةٍ قديمةٍ يكذب على صاحبه.
  final PlayerRankView? skill;

  const SeatPlayer({
    required this.name,
    this.rating,
    this.level = 1,
    this.isAI = false,
    this.isVip = false,
    this.connected = true,
    this.emoji = '🙂',
    this.avatarUrl = '',
    this.playerId = '',
    this.skill,
  });

  /// رتبة العرض على البطاقة — **تُشتقّ هنا** (طبقة البيانات) لا في البطاقة، من التصنيف
  /// إن توفّر وإلّا من المستوى. عتباتٌ بسيطة؛ عرضٌ محض لا يمسّ قاعدة.
  PlayerRank get rank {
    final r = rating ?? (800 + level * 40);
    if (r >= 1400) return PlayerRank.legend;
    if (r >= 1150) return PlayerRank.expert;
    if (r >= 950) return PlayerRank.pro;
    return PlayerRank.beginner;
  }

  SeatPlayer copyWith(
          {String? name,
          int? rating,
          int? level,
          bool? isVip,
          String? avatarUrl,
          PlayerRankView? skill}) =>
      SeatPlayer(
        name: name ?? this.name,
        rating: rating ?? this.rating,
        level: level ?? this.level,
        isAI: isAI,
        isVip: isVip ?? this.isVip,
        connected: connected,
        emoji: emoji,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        playerId: playerId,
        skill: skill ?? this.skill,
      );
}

/// أسماء موريتانيّة/عربيّة شائعة لِلاعبين الآليّين — رجالًا ونساءً، بصورٍ رمزيّة
/// مطابقةٍ للجنس (كي تظهر اللاعبات النساء بوضوح).
const _maleNames = <String>[
  'محمد الأمين', 'سيدي أحمد', 'المختار', 'بَبَّه', 'الشيخ', 'يحيى', 'عبد الله',
  'أحمدو', 'سيداتي', 'اعل', 'بوها', 'إسلمو',
];
const _femaleNames = <String>[
  'خديجة', 'مريم', 'فاطمة', 'عائشة', 'منى', 'الزهرة', 'مباركة', 'تسلمُ',
  'زينب', 'أمّ كلثوم', 'لالة', 'مِنتُ',
];
const _maleEmojis = <String>['🧔', '👳', '👨', '🤵', '🎩', '🤴'];
const _femaleEmojis = <String>['🧕', '👩', '👩‍🦱', '👩‍🦰', '💃', '👸'];

/// تصنيفُ عرضٍ داخل نطاق مستوى الذكاء الذي يلعب به الخادم فعلًا — كي **لا تكذب
/// الرتبة** على البطاقة (النطاقات هي عتبات `PlayerRank` نفسها). [level] هو
/// `LobbySeat.aiLevel`؛ null أو غير معروف (خادمٌ قديمٌ قبل الحقل، أو الأوفلاين
/// حيث لا معايرة) ⇒ النطاق الكامل كسلوك اليوم.
int aiRatingForLevel(String? level, Random r) => switch (level) {
      'beginner' => 850 + r.nextInt(100), // 850..949
      'pro' => 950 + r.nextInt(200), // 950..1149
      'expert' => 1150 + r.nextInt(250), // 1150..1399
      'legend' => 1400 + r.nextInt(150), // 1400..1549
      _ => 850 + r.nextInt(650), // 850..1499
    };

/// يولّد لاعبًا آليًّا يبدو حقيقيًّا: اسم + تصنيف معقول + مستوى مشتقّ + VIP نادرًا +
/// صورةٌ رمزيّة مطابقةٌ لجنس الاسم (نصفهم تقريبًا نساء).
/// [r] مولّدٌ محقون كي تكون الأسماء ثابتة طوال المباراة (لا تتغيّر مع كل إطار).
/// [level] يقيّد التصنيف بنطاق مستوى الخادم ([aiRatingForLevel]) — ويُسحَب
/// **آخرًا** عمدًا: تغيُّرُ مستوى الطاولة (انضمام بشريّ يرفع المتوسّط) يجدّد
/// الرتبةَ ولا يغيّر اسم الروبوت وصورته أمام الجالسين.
SeatPlayer aiSeatPlayer(Random r, {String? level}) {
  final female = r.nextBool();
  final names = female ? _femaleNames : _maleNames;
  final emojis = female ? _femaleEmojis : _maleEmojis;
  final name = names[r.nextInt(names.length)];
  final emoji = emojis[r.nextInt(emojis.length)];
  final vip = r.nextInt(12) == 0; // ~8٪ VIP
  final rating = aiRatingForLevel(level, r);
  return SeatPlayer(
    name: name,
    rating: rating,
    level: 1 + (rating - 850) ~/ 45,
    isAI: true,
    isVip: vip,
    emoji: emoji,
  );
}

/// أربعة مقاعد للّعب المنفرد: المقعد 0 نائبٌ للبشريّ (تُبدّله الواجهة بالاسم الحقيقيّ)،
/// والمقاعد 1..3 ذكاءٌ باسمٍ وتصنيف ثابتين (مشتقّة من [seed]).
List<SeatPlayer> offlineSeatPlayers(int seed) {
  final r = Random(seed);
  return [
    const SeatPlayer(name: 'أنت'),
    for (var i = 1; i < 4; i++) aiSeatPlayer(r),
  ];
}
