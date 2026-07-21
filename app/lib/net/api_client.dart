import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'player_rank.dart';

/// نوعُ الإشعار — يُملي **أين تذهب اللمسة** وأيُّ أيقونةٍ تُرسم.
///
/// **`unknown` عضوٌ أصيلٌ لا خطأ**: خادمٌ أحدثُ سيبثّ أنواعًا لم تكن يوم بُنيت
/// هذه الحزمة (بطولةٌ · هديّة). العميلُ القديم يقرؤها هنا، فيعرضها بعنوانها ونصّها
/// وأيقونةٍ عامّة ولا يفتح شيئًا بلمسها. **الدرس مدفوعُ الثمن**: طورُ WS جديدٌ كسر
/// العميلَ القديم لأنّ التحليل رمى بدل أن يسقط إلى قيمةٍ آمنة ([[ws-event-forward-compat]]).
enum NotificationKind {
  invite,
  friendRequest,
  system,
  unknown;

  static NotificationKind parse(String? s) => NotificationKind.values.firstWhere(
        (k) => k.name == s,
        orElse: () => NotificationKind.unknown,
      );
}

/// إشعارٌ في صندوقي كما يعيده الخادم.
class AppNotification {
  final String id;
  final NotificationKind kind;
  final String title;
  final String body;

  /// حمولةُ اللمسة — نفسُ حمولة الإشعار المدفوع (`code`/`seat`).
  final Map<String, String> data;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.data = const {},
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String? ?? '',
        kind: NotificationKind.parse(j['kind'] as String?),
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        data: {
          if (j['data'] case final Map<String, dynamic> d)
            for (final e in d.entries) e.key: '${e.value}',
        },
        // وقتٌ فاسدٌ ⇒ الآن: صفٌّ في غير موضعه أهونُ من شاشةٍ تنهار.
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        read: j['read'] as bool? ?? false,
      );

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        kind: kind,
        title: title,
        body: body,
        data: data,
        createdAt: createdAt,
        read: read ?? this.read,
      );
}

/// حساب لاعبٍ كما يعيده الخادم (`Player.toJson`). مرآةٌ للواجهة، بلا منطق مجال.
class AccountPlayer {
  final String id;

  /// رمز اللاعب المعروض (٦ خانات) — هذا ما يُشارَك ويُنسَخ، لا [id].
  /// فارغٌ ⇒ خادمٌ قديمٌ قبل الميزة (تُخفي الواجهة الحقل حينها).
  final String tag;

  final String phone;
  final String displayName;
  final String countryCode;
  final String city;

  /// رابط صورتي **نسبيًّا** كما يخزّنه الخادم (`/avatars/…`) — يُركّب على عنوان
  /// الخادم بـ[ApiConfig.http]. فارغٌ ⇒ بلا صورة (تُعرَض الأحرف الأولى).
  final String avatarUrl;

  const AccountPlayer({
    required this.id,
    this.tag = '',
    required this.phone,
    required this.displayName,
    required this.countryCode,
    required this.city,
    this.avatarUrl = '',
  });

  factory AccountPlayer.fromJson(Map<String, dynamic> j) => AccountPlayer(
        id: j['id'] as String? ?? '',
        tag: j['tag'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        countryCode: j['countryCode'] as String? ?? '',
        city: j['city'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tag': tag,
        'phone': phone,
        'displayName': displayName,
        'countryCode': countryCode,
        'city': city,
        'avatarUrl': avatarUrl,
      };
}

/// **لوحةُ الشرف الأسبوعيّة** (من `/honors`) — خمسُ فئاتٍ وخريطةُ ألقاب.
///
/// **الاسمُ واللقبُ والوحدةُ من الخادم لا من العميل**: رقمٌ أو نصٌّ يُنسَخ هنا يصير
/// كذبةً على الشاشة أوّلَ ما يتغيّر هناك (نفسُ سببِ خدمة كتالوج المتجر).
class HonorCategoryBoard {
  final String id;
  final String label; // «أكثر فوزًا»
  final String title; // «🏆 قاهر الطاولات»
  final String unit; // «فوزًا»
  final List<HonorRow> entries;

  const HonorCategoryBoard({
    required this.id,
    required this.label,
    required this.title,
    required this.unit,
    required this.entries,
  });

  factory HonorCategoryBoard.fromJson(Map<String, dynamic> j) =>
      HonorCategoryBoard(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        title: j['title'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        entries: [
          for (final e in (j['entries'] as List?) ?? const [])
            HonorRow.fromJson(e as Map<String, dynamic>)
        ],
      );

  /// رمزُ اللقب وحدَه (أوّلُ كلمة) — للشارة الضيّقة على الطاولة.
  String get emoji => title.isEmpty ? '' : title.split(' ').first;

  /// نصُّ اللقب بلا رمزه — تحت الرمز في الشارة العريضة.
  String get titleText =>
      title.contains(' ') ? title.substring(title.indexOf(' ') + 1) : title;
}

/// لاعبٌ على لوحة الشرف.
class HonorRow {
  final int rank;
  final String playerId;
  final String name;
  final String tag;
  final String avatarUrl;
  final int value;

  const HonorRow({
    required this.rank,
    required this.playerId,
    required this.name,
    required this.tag,
    required this.avatarUrl,
    required this.value,
  });

  factory HonorRow.fromJson(Map<String, dynamic> j) => HonorRow(
        rank: (j['rank'] as num?)?.toInt() ?? 0,
        playerId: j['playerId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        tag: j['tag'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String? ?? '',
        value: (j['value'] as num?)?.toInt() ?? 0,
      );
}

/// ردُّ `/honors` كاملًا: اللوحةُ + **خريطةُ الألقاب** (`playerId` → ألقابُه
/// بترتيب الرتبة). الخريطةُ ضئيلةٌ عمدًا (خمسةُ حاملين على الأكثر) فيحملها
/// العميلُ ويرسم بها الشارةَ في كلّ سطحٍ يعرف فيه معرّفَ اللاعب.
class HonorsBoard {
  final String week;
  final List<HonorCategoryBoard> categories;
  final Map<String, List<String>> titles;

  const HonorsBoard({
    required this.week,
    required this.categories,
    required this.titles,
  });

  static const empty =
      HonorsBoard(week: '', categories: [], titles: {});

  factory HonorsBoard.fromJson(Map<String, dynamic> j) => HonorsBoard(
        week: j['week'] as String? ?? '',
        categories: [
          for (final c in (j['categories'] as List?) ?? const [])
            HonorCategoryBoard.fromJson(c as Map<String, dynamic>)
        ],
        titles: {
          for (final e in ((j['titles'] as Map?) ?? const {}).entries)
            e.key as String: [
              for (final t in (e.value as List?) ?? const []) t as String
            ],
        },
      );

  /// أعلى ألقاب [playerId] رتبةً — **الخادمُ يرسلها مرتَّبةً**، فالأوّلُ هو الأعلى.
  /// null ⇒ بلا لقب (وهو حالُ كلّ الناس إلّا خمسة).
  String? topTitleOf(String playerId) {
    final list = titles[playerId];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  /// تعريفُ فئةٍ بمعرّفها — منه يُؤخَذ رمزُ الشارة ونصُّها.
  HonorCategoryBoard? categoryById(String? id) {
    if (id == null) return null;
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// صفٌّ في لوحة التصنيف (من `/leaderboard`). الرتبة تُشتقّ من الترتيب.
class LeaderEntry {
  final int rank;
  final String playerId;
  final String displayName;

  /// رابط صورته النسبيّ — فارغٌ ⇒ بلا صورة (أو خادمٌ أقدمُ من الحقل).
  final String avatarUrl;

  final int rating;
  final int matches;
  final int wins;

  /// رتبتُه — `null` من خادمٍ أقدمُ من الميزة.
  final PlayerRankView? skill;

  const LeaderEntry({
    required this.rank,
    required this.playerId,
    required this.displayName,
    this.avatarUrl = '',
    required this.rating,
    required this.matches,
    required this.wins,
    this.skill,
  });

  factory LeaderEntry.fromJson(Map<String, dynamic> j, int rank) => LeaderEntry(
        rank: rank,
        playerId: j['playerId'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String? ?? '',
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        matches: (j['matches'] as num?)?.toInt() ?? 0,
        wins: (j['wins'] as num?)?.toInt() ?? 0,
        skill: PlayerRankView.fromJson(j['rank'] as Map<String, dynamic>?),
      );
}

/// باقةُ ماسٍ معروضةٌ في المتجر (من `/store/diamond-packs`).
///
/// [price] بالأوقية و[total] ماسًا — وهما متساويان أساسًا (`1💎 = 1 أوقية`)،
/// والفرقُ بونصٌ فوق السعر لا خصمٌ عليه.
class DiamondPackView {
  final String id;
  final int price; // أوقية
  final int base;
  final int bonus;
  final int total;

  const DiamondPackView({
    required this.id,
    required this.price,
    required this.base,
    required this.bonus,
    required this.total,
  });

  /// نسبةُ البونص مئويّةً — تُشتقّ من رقمَي الخادم لا من ثابتٍ منسوخ.
  int get bonusPct => base == 0 ? 0 : ((bonus / base) * 100).round();

  factory DiamondPackView.fromJson(Map<String, dynamic> j) => DiamondPackView(
        id: j['id'] as String? ?? '',
        price: (j['price'] as num?)?.toInt() ?? 0,
        base: (j['base'] as num?)?.toInt() ?? 0,
        bonus: (j['bonus'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
      );
}

/// حدُّ لعباتِ اليوم بحالته (من `/me/play-limit`).
///
/// **كلُّ أرقامه من الخادم** — السقفُ والمستهلَكُ والباقي. حسابُ الباقي هنا نسخةٌ
/// ثانيةٌ تنجرف، ويُري اللاعبَ لعبةً لا يملكها فيُردّ عند الضغط.
class PlayAllowanceView {
  final int limit;
  final int used;
  final int remaining;
  final bool canPlay;

  /// **تذكرةٌ حيّةٌ ⇒ لعبٌ بلا حدود.** null ⇒ لا تذكرة.
  final DateTime? passUntil;

  /// **سماحُ اللاعب الجديد** — لعبٌ بلا حدودٍ أُهدي إليه. null ⇒ ليس جديدًا.
  final DateTime? graceUntil;

  /// **له تجربةٌ مجّانيّةٌ لم ينلها** ⇒ يُعرَض عليه يومٌ هديّةً لا بثمن.
  final bool trialAvailable;

  /// **لعباتٌ مكتسَبةٌ اليوم** من دعوة الأصدقاء (داخلةٌ في [limit] أصلًا). 0 ⇒ لا مكتسَب.
  final int bonus;

  const PlayAllowanceView({
    required this.limit,
    required this.used,
    required this.remaining,
    required this.canPlay,
    this.passUntil,
    this.graceUntil,
    this.trialAvailable = false,
    this.bonus = 0,
  });

  bool get unlimited => passUntil != null || graceUntil != null;

  /// **أهديناه أم اشترى؟** يفرّق النصَّ: مَن أُهدي شيئًا لا يُقال له إنّه اشتراه.
  bool get isGrace => graceUntil != null && passUntil == null;

  /// نهايةُ ما هو فيه — تذكرتُه أوّلًا (اشتراها فهي الأبعدُ عادةً).
  DateTime? get unlimitedUntil => passUntil ?? graceUntil;

  factory PlayAllowanceView.fromJson(Map<String, dynamic> j) =>
      PlayAllowanceView(
        limit: (j['limit'] as num?)?.toInt() ?? 0,
        used: (j['used'] as num?)?.toInt() ?? 0,
        remaining: (j['remaining'] as num?)?.toInt() ?? 0,
        canPlay: j['canPlay'] as bool? ?? true,
        // **الخادمُ يقرّر السريان لا نحن**: مقارنةُ ساعةِ الهاتف بالنهاية تجعل
        // مَن قدّم ساعتَه يلعب بلا حدود. `passUntil` يصل **إن كانت حيّةً** فقط،
        // وهذا للعرض («حتى 14:30») لا للحكم.
        passUntil: DateTime.tryParse(j['passUntil'] as String? ?? '')?.toLocal(),
        graceUntil:
            DateTime.tryParse(j['graceUntil'] as String? ?? '')?.toLocal(),
        trialAvailable: j['trialAvailable'] as bool? ?? false,
        bonus: (j['bonus'] as num?)?.toInt() ?? 0,
      );
}

/// خطّةُ VIP معروضةٌ للبيع (من `/store/vip`).
///
/// **كلُّ أرقامها من الخادم** — الثمنُ والمدّةُ والدفعةُ الشهريّة.
class VipPlanView {
  final String id;
  final int price;
  final int days;
  final int monthlyDiamonds;

  const VipPlanView({
    required this.id,
    required this.price,
    required this.days,
    required this.monthlyDiamonds,
  });

  bool get isYear => days >= 365;

  factory VipPlanView.fromJson(Map<String, dynamic> j) => VipPlanView(
        id: j['id'] as String? ?? '',
        price: (j['price'] as num?)?.toInt() ?? 0,
        days: (j['days'] as num?)?.toInt() ?? 0,
        monthlyDiamonds: (j['monthlyDiamonds'] as num?)?.toInt() ?? 0,
      );
}

/// تذكرةٌ معروضةٌ للبيع (من `/store/tickets`).
///
/// **كلُّ أرقامها من الخادم** — الثمنُ والمدّة. الاسمُ العربيُّ وحدَه محلّيّ.
class TicketView {
  final String id;
  final int price;
  final int hours;

  const TicketView({
    required this.id,
    required this.price,
    required this.hours,
  });

  factory TicketView.fromJson(Map<String, dynamic> j) => TicketView(
        id: j['id'] as String? ?? '',
        price: (j['price'] as num?)?.toInt() ?? 0,
        hours: (j['hours'] as num?)?.toInt() ?? 0,
      );
}

/// مهمّةٌ يوميّةٌ أو أسبوعيّةٌ بحالتها (من `/me/missions`).
///
/// **كلُّ أرقامها من الخادم** — الهدفُ والتقدّمُ والجائزةُ وحتّى `claimable`. العميلُ
/// لا يقرّر متى تُقبَض: الخادمُ هو مَن يمنح، وحسابٌ ثانٍ هنا يجعل الزرَّ يُضيء لِما
/// يرفضه الخادم.
///
/// الاسمُ العربيُّ وحدَه محلّيّ (`missionCatalogUi`) — كالهدايا: الخادمُ لا يحمل نصًّا.
class MissionView {
  final String id;
  final String period; // daily · weekly
  final int target;
  final int progress;
  final int xp;
  final int diamonds;
  final bool claimed;
  final bool claimable;

  const MissionView({
    required this.id,
    required this.period,
    required this.target,
    required this.progress,
    required this.xp,
    required this.diamonds,
    required this.claimed,
    required this.claimable,
  });

  bool get daily => period == 'daily';

  /// نسبةُ الإنجاز للشريط — مقصوصةٌ في [0,1]: الخادمُ يقصّها أصلًا، وهذا حارسُ عرض.
  double get ratio =>
      target == 0 ? 0 : (progress / target).clamp(0.0, 1.0).toDouble();

  factory MissionView.fromJson(Map<String, dynamic> j) => MissionView(
        id: j['id'] as String? ?? '',
        period: j['period'] as String? ?? 'daily',
        target: (j['target'] as num?)?.toInt() ?? 0,
        progress: (j['progress'] as num?)?.toInt() ?? 0,
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        diamonds: (j['diamonds'] as num?)?.toInt() ?? 0,
        claimed: j['claimed'] as bool? ?? false,
        claimable: j['claimable'] as bool? ?? false,
      );
}

/// باقةُ هدايا معروضةٌ في المتجر (من `/store/gift-bundles`).
///
/// **كلُّ أرقامها من الخادم** — لا تُحسَب هنا. الاسمُ العربيُّ وحدَه محلّيّ
/// (`giftCatalogUi`)، كما في لوحة الهدايا: الخادمُ لا يحمل نصًّا.
class GiftBundleView {
  final String id;
  final String gift;
  final String emoji;
  final int qty;
  final int price;
  final int fullPrice;

  const GiftBundleView({
    required this.id,
    required this.gift,
    required this.emoji,
    required this.qty,
    required this.price,
    required this.fullPrice,
  });

  int get saving => fullPrice - price;

  /// نسبةُ الخصم مئويّةً — للشارة. يُحسَب من رقمَي الخادم لا من معادلةٍ منسوخة.
  int get discountPct =>
      fullPrice == 0 ? 0 : ((saving / fullPrice) * 100).round();

  factory GiftBundleView.fromJson(Map<String, dynamic> j) => GiftBundleView(
        id: j['id'] as String? ?? '',
        gift: j['gift'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '🎁',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        price: (j['price'] as num?)?.toInt() ?? 0,
        fullPrice: (j['fullPrice'] as num?)?.toInt() ?? 0,
      );
}

/// إحصائيات لاعبٍ (من `/me/stats`). `winRatePct` نسبةٌ مئويّة صحيحة كما يرسلها الخادم.
class PlayerStatsView {
  final int rating;
  final int matches;
  final int wins;
  final int losses;
  final int winStreak;
  final int bestStreak;
  final int winRatePct;

  /// **الخبرة والمستوى** — يأتيان من الخادم. `level` **لا يُحسَب هنا**: منحنى
  /// الخبرة قرارٌ خادميّ، ونسخُه يجعل حزمةً قديمةً تعرض مستوًى غيرَ الحقيقيّ.
  /// خادمٌ أقدمُ من الميزة ⇒ `level: 0` ⇒ لا يُعرَض شيء (لا مستوًى مخترَع).
  final int xp;
  final int level;
  final int xpToNext;
  final double levelProgress;

  /// **رتبةُ المهارة** — تُشتقّ خادميًّا من التصنيف وعددِ المباريات. `null` ⇒ خادمٌ
  /// أقدمُ من الميزة ⇒ لا شارةَ تُعرَض.
  final PlayerRankView? skill;

  const PlayerStatsView({
    required this.rating,
    required this.matches,
    required this.wins,
    required this.losses,
    required this.winStreak,
    required this.bestStreak,
    required this.winRatePct,
    this.xp = 0,
    this.level = 0,
    this.xpToNext = 0,
    this.levelProgress = 0,
    this.skill,
  });

  factory PlayerStatsView.fromJson(Map<String, dynamic> j) => PlayerStatsView(
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        matches: (j['matches'] as num?)?.toInt() ?? 0,
        wins: (j['wins'] as num?)?.toInt() ?? 0,
        losses: (j['losses'] as num?)?.toInt() ?? 0,
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 0,
        xpToNext: (j['xpToNext'] as num?)?.toInt() ?? 0,
        levelProgress: (j['levelProgress'] as num?)?.toDouble() ?? 0,
        winStreak: (j['winStreak'] as num?)?.toInt() ?? 0,
        bestStreak: (j['bestStreak'] as num?)?.toInt() ?? 0,
        winRatePct: (j['winRate'] as num?)?.toInt() ?? 0,
        skill: PlayerRankView.fromJson(j['rank'] as Map<String, dynamic>?),
      );
}

/// إذن دخول غرفة صوت الطاولة (من `/me/voice/token`). **الخادم يقرّر الغرفة** —
/// لا نرسل اسمها ولا نختلقها؛ التوكن صالحٌ لغرفةٍ واحدةٍ فقط هي غرفة طاولتك.
class VoiceGrant {
  final String url; // wss://…/belote-voice
  final String room;
  final String token;
  const VoiceGrant({required this.url, required this.room, required this.token});

  factory VoiceGrant.fromJson(Map<String, dynamic> j) => VoiceGrant(
        url: j['url'] as String? ?? '',
        room: j['room'] as String? ?? '',
        token: j['token'] as String? ?? '',
      );
}

/// جلسة مصادقة ناجحة: توكن JWT + اللاعب + هل هو جديد (لعرض ترحيب).
class AuthSession {
  final String token;
  final AccountPlayer player;
  final bool isNew;

  /// **هدايا الترحيب كما منحها الخادم** (`{'rose': 3, …}`) — فارغةٌ للعائد.
  ///
  /// تأتي من الخادم ولا تُنسَخ هنا: قائمةٌ ثانيةٌ تنجرف، فتَعِد النافذةُ بوردتين
  /// والمخزونُ فيه ثلاث.
  final Map<String, int> welcomeGifts;

  const AuthSession({
    required this.token,
    required this.player,
    required this.isNew,
    this.welcomeGifts = const {},
  });
}

/// خطأٌ من الخادم برسالةٍ عربيّة جاهزة للعرض. الحقل `status` = رمز HTTP (0 = فشل شبكة).
class ApiException implements Exception {
  final int status;
  final String message;
  const ApiException(this.status, this.message);
  @override
  String toString() => 'ApiException($status): $message';
}

/// لاعبٌ **كما يراه لاعبٌ آخر** (`Player.toPublicJson`) — بلا هاتف. صديقٌ أو طلبٌ.
///
/// منفصلٌ عن [AccountPlayer] عمدًا: ذاك ملفّي أنا وفيه هاتفي، وهذا غيري. لو وحّدناهما
/// لصار في النوع حقلُ هاتفٍ فارغٌ دائمًا يغري بملئه يومًا من الخادم.
class FriendPlayer {
  final String id;
  final String tag;
  final String displayName;
  final String countryCode;
  final String city;

  /// رابط صورته النسبيّ — فارغٌ ⇒ بلا صورة.
  final String avatarUrl;

  /// أمتّصلٌ الآن؟ **للأصدقاء وحدهم** — الطلب المعلّق لا يحمل الحقل (لا علاقةَ بعد
  /// ⇒ لا يكشف أحدُهما للآخر متى يفتح التطبيق)، فيصل `false` وهو الصادق حينها.
  final bool online;

  /// **أهو VIP؟** يظهر لأصدقائه في قائمتهم (نصُّ المالك 2026-07-16).
  final bool isVip;

  /// رسائلُه الخاصّة غير المقروءة عندي — شارةُ صفّه في القائمة. 0 ⇒ لا شارة.
  final int unread;

  const FriendPlayer({
    required this.id,
    required this.tag,
    required this.displayName,
    this.countryCode = '',
    this.city = '',
    this.avatarUrl = '',
    this.online = false,
    this.isVip = false,
    this.unread = 0,
  });

  factory FriendPlayer.fromJson(Map<String, dynamic> j) => FriendPlayer(
        id: j['id'] as String? ?? '',
        tag: j['tag'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        countryCode: j['countryCode'] as String? ?? '',
        city: j['city'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String? ?? '',
        online: j['online'] as bool? ?? false,
        isVip: j['vip'] as bool? ?? false,
        unread: (j['unread'] as num?)?.toInt() ?? 0,
      );
}

/// رسالةٌ خاصّة كما يعيدها الخادم. **الملكيّة تُشتقّ عند العرض** (`from == myId`)
/// لا تُخزَّن — الرسالة نفسها تصل الطرفين بنفس الشكل.
class ChatMessage {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String? ?? '',
        fromId: j['from'] as String? ?? '',
        toId: j['to'] as String? ?? '',
        text: j['text'] as String? ?? '',
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '')?.toUtc() ??
                DateTime.now().toUtc(),
      );
}

/// **الملفّ العامّ للاعبٍ آخر** كما يعيده `/players/<id>`.
///
/// [friendship] يُملي زرَّ اللوحة: `none` ⇒ «أضِف صديقًا» · `outgoing` ⇒ «بانتظار
/// ردّه» · `incoming` ⇒ «اقبل صداقته» · `friends` ⇒ «صديقك».
class PublicPlayer {
  final String id;
  final String tag;
  final String displayName;
  final String countryCode;
  final String city;
  final String avatarUrl;
  final PlayerStatsView stats;
  final bool isVip;
  final bool online;
  final bool isMe;
  final String friendship;

  const PublicPlayer({
    required this.id,
    required this.tag,
    required this.displayName,
    required this.stats,
    this.countryCode = '',
    this.city = '',
    this.avatarUrl = '',
    this.isVip = false,
    this.online = false,
    this.isMe = false,
    this.friendship = 'none',
  });

  factory PublicPlayer.fromJson(Map<String, dynamic> j) => PublicPlayer(
        id: j['id'] as String? ?? '',
        tag: j['tag'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        countryCode: j['countryCode'] as String? ?? '',
        city: j['city'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String? ?? '',
        stats: PlayerStatsView.fromJson(
            (j['stats'] as Map<String, dynamic>?) ?? const {}),
        isVip: j['vip'] as bool? ?? false,
        online: j['online'] as bool? ?? false,
        isMe: j['isMe'] as bool? ?? false,
        friendship: j['friendship'] as String? ?? 'none',
      );
}

/// قوائم الأصدقاء الثلاث كما يعيدها `/me/friends`.
class FriendLists {
  final List<FriendPlayer> friends;
  final List<FriendPlayer> incoming; // ينتظرون ردّي
  final List<FriendPlayer> outgoing; // أنتظر ردّهم

  const FriendLists({
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
  });

  static List<FriendPlayer> _list(Object? v) => [
        for (final e in (v as List? ?? const []))
          FriendPlayer.fromJson(e as Map<String, dynamic>)
      ];

  factory FriendLists.fromJson(Map<String, dynamic> j) => FriendLists(
        friends: _list(j['friends']),
        incoming: _list(j['incoming']),
        outgoing: _list(j['outgoing']),
      );

  bool get isEmpty => friends.isEmpty && incoming.isEmpty && outgoing.isEmpty;
}

/// نصٌّ عربيٌّ لرمز خطأ الأصدقاء. **مسارات الأصدقاء تُعيد رموزًا لا نصوصًا**
/// (`friend_notFound`) — والترجمة شأن العميل كالعبارات والهدايا. بلا هذه الدالّة
/// يرى اللاعب رمزًا إنجليزيًّا خامًا في [ApiException.message].
String friendErrorText(String code) => switch (code) {
      'friend_invalidTag' => 'الرمز غير صحيح — ٦ خانات كما تظهر في ملفّ صاحبك.',
      'friend_notFound' => 'لا لاعب بهذا الرمز. تأكّد منه.',
      'friend_self' => 'هذا رمزك أنت.',
      'friend_already' => 'بينكما طلبٌ أو صداقةٌ بالفعل.',
      'friend_noRequest' => 'لا طلبَ ينتظر ردَّك من هذا اللاعب.',
      'friend_notFriend' => 'لا علاقة بينكما أصلًا.',
      _ => code, // خطأٌ عربيٌّ من الخادم (بقيّة المسارات) أو رمزٌ لا نعرفه
    };

/// نصٌّ عربيٌّ لرموز أخطاء الرسائل الخاصّة والحظر — نظير [friendErrorText].
String messageErrorText(String code) => switch (code) {
      'message_notFriend' => 'الرسائل بين الأصدقاء — أضفه صديقًا أوّلًا.',
      'message_blocked' => 'لا يمكن مراسلة هذا اللاعب.',
      'message_empty' => 'اكتب رسالةً أوّلًا.',
      'block_notFound' => 'اللاعب غير موجود.',
      'block_self' => 'لا تحظر نفسك.',
      _ => code,
    };

/// نصٌّ عربيٌّ لرمز خطأ الصورة — نظير [friendErrorText] (الخادم يُعيد رموزًا).
///
/// **لا رسالةَ إشرافٍ هنا**: لا يُرفَض محتوى (قرار المالك 2026-07-15)، فالرفض إمّا
/// حجمٌ أو ملفٌّ ليس صورةً أصلًا.
String avatarErrorText(String code) => switch (code) {
      'avatar_tooLarge' => 'الصورة كبيرة. اختر واحدةً أصغر.',
      'avatar_badType' => 'هذا ليس ملفَّ صورة. اختر صورةً (JPG أو PNG).',
      'avatar_empty' => 'الملفّ فارغ.',
      _ => code,
    };

/// رمزُ خطأ بطولةٍ (`trn_*`) → رسالته العربيّة. غيرُ المعروف يُعاد كما هو
/// (خادمٌ أحدث قد يبثّ رمزًا لم يكن يومَ بُنيت هذه الحزمة).
String tournamentErrorText(String code) => switch (code) {
      'trn_closed' => 'بطولةٌ جاريةٌ الآن — التسجيل بعد نهايتها.',
      'trn_alreadyRegistered' => 'أنت مسجَّلٌ أصلًا.',
      'trn_notRegistered' => 'لستَ مسجَّلًا في هذه البطولة.',
      'trn_full' => 'اكتمل العدد — بطولةٌ قادمةٌ تفتح قريبًا.',
      'trn_insufficient' => 'ماسُك لا يكفي لرسم الدخول.',
      'trn_notFriends' => 'الشراكة بين الأصدقاء — أضفه صديقًا أوّلًا.',
      'trn_pairTaken' => 'لأحدكما شريكٌ أو دعوةٌ قائمة.',
      'trn_noInvite' => 'لا دعوةَ شراكةٍ قائمة.',
      'trn_badRequest' => 'طلبٌ غير صالح.',
      // مسابقات اللاعبين — الرسائل تقول **ما العمل** لا «خطأ».
      'trn_hasActiveEvent' => 'لك مسابقةٌ قائمة — أكملها أو ألغِها أوّلًا.',
      'trn_badTitle' => 'الاسم من 3 إلى 30 حرفًا.',
      'trn_badFee' => 'رسم الدخول من 10 إلى 500 ماسة.',
      'trn_badTeams' => 'الحجم: 8 أو 16 فريقًا.',
      'trn_badTime' => 'الموعد بين 10 دقائق و7 أيّام من الآن.',
      _ => code,
    };

/// مقاتلٌ في مقعدِ مباراةِ قوس: بشريٌّ باسمه أو روبوت.
class BracketSeatView {
  final bool bot;
  final String name;
  final String avatarUrl;
  final bool you;
  const BracketSeatView(
      {required this.bot, this.name = '', this.avatarUrl = '', this.you = false});

  factory BracketSeatView.fromJson(Map<String, dynamic> j) => BracketSeatView(
        bot: j['bot'] as bool? ?? false,
        name: j['name'] as String? ?? '',
        avatarUrl: j['avatar'] as String? ?? '',
        you: j['you'] as bool? ?? false,
      );
}

/// مباراةٌ في القوس — المقاعد بإحداثيّات الخادم: الفريقان (0،2) و(1،3).
class BracketMatchView {
  final int round; // 0 نصف النهائيّ · 1 النهائيّ
  final int index;
  final List<BracketSeatView> seats;
  final int? winnerTeam;
  final bool live;
  const BracketMatchView({
    required this.round,
    required this.index,
    required this.seats,
    this.winnerTeam,
    this.live = false,
  });

  factory BracketMatchView.fromJson(Map<String, dynamic> j) => BracketMatchView(
        round: (j['round'] as num?)?.toInt() ?? 0,
        index: (j['index'] as num?)?.toInt() ?? 0,
        seats: [
          for (final s in (j['seats'] as List? ?? const []))
            BracketSeatView.fromJson(s as Map<String, dynamic>)
        ],
        winnerTeam: (j['winnerTeam'] as num?)?.toInt(),
        live: j['live'] as bool? ?? false,
      );

  /// عنصرا الفريق [team] (0 ⇒ المقعدان 0و2 · 1 ⇒ 1و3).
  List<BracketSeatView> team(int team) => seats.length < 4
      ? const []
      : (team == 0 ? [seats[0], seats[2]] : [seats[1], seats[3]]);
}

/// مُجملُ جولةٍ في قوسٍ كبير: كم مباراةً فيها نظريًّا، كم بُني، كم حُسم.
/// به تُعرَض الفعالياتُ الكبيرة (فتح السعة) دون بثّ مئات المباريات — الخادمُ
/// يشذّب الجولات الضخمة ويُبقي مبارياتي، وهذا يسدّ الصورة.
class RoundInfoView {
  final int round;
  final int matches; // الحجم النظريّ الكامل
  final int created;
  final int finished;
  const RoundInfoView({
    required this.round,
    required this.matches,
    this.created = 0,
    this.finished = 0,
  });

  factory RoundInfoView.fromJson(Map<String, dynamic> j) => RoundInfoView(
        round: (j['round'] as num?)?.toInt() ?? 0,
        matches: (j['matches'] as num?)?.toInt() ?? 0,
        created: (j['created'] as num?)?.toInt() ?? 0,
        finished: (j['finished'] as num?)?.toInt() ?? 0,
      );
}

/// مسجَّلٌ في قائمة الانتظار.
class TournamentPlayerView {
  final String name;
  final String avatarUrl;
  final bool you;
  final String? partner; // اسمُ شريكه المثبَّت إن وُجد
  const TournamentPlayerView(
      {required this.name, this.avatarUrl = '', this.you = false, this.partner});

  factory TournamentPlayerView.fromJson(Map<String, dynamic> j) =>
      TournamentPlayerView(
        name: j['name'] as String? ?? '',
        avatarUrl: j['avatar'] as String? ?? '',
        you: j['you'] as bool? ?? false,
        partner: j['partner'] as String?,
      );
}

/// بطلٌ سابقٌ وجائزتُه — للعرض.
class ChampionView {
  final String name;
  final int prize;
  const ChampionView({required this.name, required this.prize});

  factory ChampionView.fromJson(Map<String, dynamic> j) => ChampionView(
        name: j['name'] as String? ?? '',
        prize: (j['prize'] as num?)?.toInt() ?? 0,
      );
}

/// حالةُ البطولة كما يبثّها `/me/tournament` — يستطلعها العميل دوريًّا.
class TournamentState {
  final String phase; // registering | playing
  final int entryFee;
  final int size;
  final int pool;
  final bool registered;

  /// كم ثانيةً بقيت لنافذة التسجيل — null قبل أوّل مسجّل.
  final int? endsInSeconds;

  /// اسمُ من يدعوني شريكًا — null بلا دعوة.
  final String? inviteFrom;

  /// اسمُ شريكي المثبَّت.
  final String? partner;
  final List<TournamentPlayerView> players;
  final List<BracketMatchView> bracket;

  /// مُجمل جولات القوس (للفعاليات الكبيرة) — خادمٌ قديم لا يبثّه ⇒ فارغة.
  final List<RoundInfoView> roundsInfo;

  /// طاولتي الجاريةُ في القوس (رمزٌ ومقعد) — null إن لم أكن في مباراةٍ حيّة.
  final ({String code, int seat})? myTable;
  final List<ChampionView> lastChampions;

  /// الفعالياتُ المجدولة (بطولاتٌ باسمٍ وموعدٍ ورسمٍ مخصّص) — خادمٌ قديمٌ لا
  /// يبثّها ⇒ قائمةٌ فارغة.
  final List<EventView> events;

  const TournamentState({
    required this.phase,
    required this.entryFee,
    required this.size,
    required this.pool,
    required this.registered,
    this.endsInSeconds,
    this.inviteFrom,
    this.partner,
    this.players = const [],
    this.bracket = const [],
    this.roundsInfo = const [],
    this.myTable,
    this.lastChampions = const [],
    this.events = const [],
  });

  factory TournamentState.fromJson(Map<String, dynamic> j) {
    final table = j['myTable'] as Map<String, dynamic>?;
    final code = table?['code'] as String?;
    final seat = (table?['seat'] as num?)?.toInt();
    return TournamentState(
      phase: j['phase'] as String? ?? 'registering',
      entryFee: (j['entryFee'] as num?)?.toInt() ?? 0,
      size: (j['size'] as num?)?.toInt() ?? 8,
      pool: (j['pool'] as num?)?.toInt() ?? 0,
      registered: j['registered'] as bool? ?? false,
      endsInSeconds: (j['endsInSeconds'] as num?)?.toInt(),
      inviteFrom: j['inviteFrom'] as String?,
      partner: j['partner'] as String?,
      players: [
        for (final p in (j['players'] as List? ?? const []))
          TournamentPlayerView.fromJson(p as Map<String, dynamic>)
      ],
      bracket: [
        for (final m in (j['bracket'] as List? ?? const []))
          BracketMatchView.fromJson(m as Map<String, dynamic>)
      ],
      roundsInfo: [
        for (final r in (j['roundsInfo'] as List? ?? const []))
          RoundInfoView.fromJson(r as Map<String, dynamic>)
      ],
      myTable: code != null && code.isNotEmpty && seat != null
          ? (code: code, seat: seat)
          : null,
      lastChampions: [
        for (final c in (j['lastChampions'] as List? ?? const []))
          ChampionView.fromJson(c as Map<String, dynamic>)
      ],
      events: [
        for (final e in (j['events'] as List? ?? const []))
          EventView.fromJson(e as Map<String, dynamic>)
      ],
    );
  }
}

/// فعاليّةٌ مجدولة كما تصل في حالة البطولة.
class EventView {
  final String id;
  final String title;
  final int entryFee;
  final int size;
  final int players;
  final int pool;
  final bool registered;
  final String phase; // registering | playing
  final int startsInSeconds;
  final String? partner;
  final String? inviteFrom;

  /// اسمُ منشئها إن كانت **مسابقةَ لاعبٍ** («مسابقة فلان») — فارغٌ لفعاليّة
  /// الإدارة. و[mine]: أنا منشئُها ⇒ يظهر زرُّ الإلغاء قبل بدئها.
  final String creatorName;
  final bool mine;

  const EventView({
    required this.id,
    required this.title,
    required this.entryFee,
    required this.size,
    required this.players,
    required this.pool,
    required this.registered,
    required this.phase,
    required this.startsInSeconds,
    this.partner,
    this.inviteFrom,
    this.creatorName = '',
    this.mine = false,
  });

  factory EventView.fromJson(Map<String, dynamic> j) => EventView(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        entryFee: (j['entryFee'] as num?)?.toInt() ?? 0,
        size: (j['size'] as num?)?.toInt() ?? 0,
        players: (j['players'] as num?)?.toInt() ?? 0,
        pool: (j['pool'] as num?)?.toInt() ?? 0,
        registered: j['registered'] as bool? ?? false,
        phase: j['phase'] as String? ?? 'registering',
        startsInSeconds: (j['startsInSeconds'] as num?)?.toInt() ?? 0,
        partner: j['partner'] as String?,
        inviteFrom: j['inviteFrom'] as String?,
        creatorName: j['creatorName'] as String? ?? '',
        mine: j['mine'] as bool? ?? false,
      );
}

/// خبرٌ من مركز المحتوى.
class NewsView {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  const NewsView(
      {required this.id,
      required this.title,
      required this.body,
      required this.createdAt});

  factory NewsView.fromJson(Map<String, dynamic> j) => NewsView(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// لافتةٌ (صورةٌ برابطٍ نسبيّ).
class BannerView {
  final String id;
  final String imageUrl;
  const BannerView({required this.id, required this.imageUrl});

  factory BannerView.fromJson(Map<String, dynamic> j) => BannerView(
        id: j['id'] as String? ?? '',
        imageUrl: j['image'] as String? ?? '',
      );
}

/// لاعبٌ على مباراةٍ حيّةٍ قابلةٍ للمشاهدة. مقعدُ ذكاءٍ ⇒ [ai] بلا اسم.
class LiveTablePlayer {
  final int seat;
  final bool ai;
  final String name;
  final String avatarUrl;
  final bool vip;
  const LiveTablePlayer({
    required this.seat,
    this.ai = false,
    this.name = '',
    this.avatarUrl = '',
    this.vip = false,
  });

  factory LiveTablePlayer.fromJson(Map<String, dynamic> j) => LiveTablePlayer(
        seat: j['seat'] as int? ?? 0,
        ai: j['ai'] as bool? ?? false,
        name: j['name'] as String? ?? '',
        avatarUrl: j['avatar'] as String? ?? '',
        vip: j['vip'] as bool? ?? false,
      );
}

/// مباراةٌ حيّةٌ قابلةٌ للمشاهدة (من `GET /tables/live`) — [[spectator-system]].
class LiveTableView {
  final String tableId;
  final bool tournament;
  final int watchers;
  final int usScore; // فريق المقعدين 0+2
  final int themScore; // فريق المقعدين 1+3
  final List<LiveTablePlayer> players;
  const LiveTableView({
    required this.tableId,
    this.tournament = false,
    this.watchers = 0,
    this.usScore = 0,
    this.themScore = 0,
    this.players = const [],
  });

  factory LiveTableView.fromJson(Map<String, dynamic> j) => LiveTableView(
        tableId: j['tableId'] as String? ?? '',
        tournament: j['tournament'] as bool? ?? false,
        watchers: j['watchers'] as int? ?? 0,
        usScore: j['usScore'] as int? ?? 0,
        themScore: j['themScore'] as int? ?? 0,
        players: [
          for (final p in (j['players'] as List? ?? const []))
            LiveTablePlayer.fromJson(p as Map<String, dynamic>)
        ],
      );
}

/// عميل HTTP لخادم Belote — المصادقة والحساب فقط (WS منفصلٌ في [LiveTableClient]).
/// يقبل `http.Client` محقونًا ⇒ قابل للاختبار بلا شبكة.
class ApiClient {
  final ApiConfig config;
  final http.Client _http;
  final Duration timeout;

  ApiClient({ApiConfig? config, http.Client? httpClient, this.timeout = const Duration(seconds: 12)})
      : config = config ?? ApiConfig.current,
        _http = httpClient ?? http.Client();

  /// **الدخول العاديّ:** هاتف + كلمة سرّ — بلا OTP. يرمي [ApiException] عند الخطأ.
  Future<AuthSession> login(String phone, String password) async {
    final j = await _post('/auth/login', {'phone': phone, 'password': password});
    return _session(j);
  }

  /// **إنشاء حساب:** توكن هويّة Firebase (يُثبت الهاتف بعد OTP) + كلمة سرّ + ملف.
  Future<AuthSession> register({
    required String idToken,
    required String password,
    String? displayName,
    String? countryCode,
    String? city,
  }) async {
    final j = await _post('/auth/register', {
      'idToken': idToken,
      'password': password,
      if (displayName != null) 'displayName': displayName,
      if (countryCode != null) 'countryCode': countryCode,
      if (city != null) 'city': city,
    });
    return _session(j);
  }

  /// **استعادة كلمة السرّ:** توكن هويّة Firebase (بعد OTP) + كلمة سرّ جديدة ⇒ جلسة.
  Future<AuthSession> resetPassword({
    required String idToken,
    required String password,
  }) async {
    final j = await _post('/auth/reset-password', {'idToken': idToken, 'password': password});
    return _session(j);
  }

  AuthSession _session(Map<String, dynamic> j) => AuthSession(
        token: j['token'] as String,
        player: AccountPlayer.fromJson(j['player'] as Map<String, dynamic>),
        isNew: j['isNew'] as bool? ?? false,
        // خادمٌ أقدمُ من الميزة ⇒ خريطةٌ فارغة ⇒ لا نافذة. لا نخترع منحةً لم تقع.
        welcomeGifts: {
          for (final e in (j['welcome'] as Map<String, dynamic>? ?? const {}).entries)
            e.key: (e.value as num?)?.toInt() ?? 0,
        },
      );

  /// يحدّث ملف اللاعب (اسم/دولة/مدينة). الدولة والمدينة تُقبَلان مرّةً واحدة على الخادم
  /// (منع تلاعب). يُعيد اللاعب بعد التحديث. يرمي [ApiException] عند الفشل.
  Future<AccountPlayer> updateProfile(
    String token, {
    String? displayName,
    String? countryCode,
    String? city,
  }) async {
    final j = await _post(
      '/me/profile',
      {
        if (displayName != null) 'displayName': displayName,
        if (countryCode != null) 'countryCode': countryCode,
        if (city != null) 'city': city,
      },
      token: token,
    );
    return AccountPlayer.fromJson(j);
  }

  /// يجلب اللاعب الحاليّ بتوكنه (للتحقّق أنّ التوكن المحفوظ ما زال صالحًا).
  Future<AccountPlayer> me(String token) async {
    final j = await _get('/me', token: token);
    return AccountPlayer.fromJson(j);
  }

  /// **يرفع صورة الملفّ**: بايتات الصورة خامّةً في الجسم (لا multipart ولا base64 —
  /// ملفٌّ واحدٌ معروف الوجهة، وbase64 يضخّمه الثلث). يُعيد اللاعب بعد التحديث.
  ///
  /// يرمي [ApiException] برسالةٍ عربيّة: 413 ⇒ كبيرةٌ جدًّا · 400 ⇒ ليست صورة.
  Future<AccountPlayer> uploadAvatar(String token, Uint8List bytes) async {
    final j = await _send(() => _http.post(
          config.http('/me/avatar'),
          headers: {
            'authorization': 'Bearer $token',
            'content-type': 'application/octet-stream',
          },
          body: bytes,
        ));
    return AccountPlayer.fromJson(j);
  }

  /// يحذف صورة الملفّ ⇒ العودة إلى الأحرف الأولى. يُعيد اللاعب بعد التحديث.
  Future<AccountPlayer> deleteAvatar(String token) async =>
      AccountPlayer.fromJson(await _delete('/me/avatar', token: token));

  // ── إشعارات خارج التطبيق ──

  /// يُسجّل توكن هذا الجهاز عند الخادم — به تصلني الدعوةُ وأنا خارج التطبيق.
  ///
  /// **يبتلع الفشل**: الإشعارات رفاهيّةٌ لا شرطٌ للّعب. خادمٌ قديمٌ بلا المسار
  /// (404) أو معطَّلُ الإشعارات (503) أو شبكةٌ متعثّرة — لا شيء منها يستحقّ أن
  /// يُفشل دخولَ اللاعب.
  Future<void> putDeviceToken(String token, String deviceToken,
      {String platform = 'android'}) async {
    try {
      await _post('/me/device-token', {'token': deviceToken, 'platform': platform},
          token: token);
    } catch (_) {
      // صمت — [[online-wiring]]: لا ميزةَ ثانويّةٌ تكسر مسارًا أساسيًّا.
    }
  }

  /// يمحو توكن هذا الجهاز (خروجٌ من الحساب) — كي لا تصل دعواتي إلى جهازٍ تركتُه.
  Future<void> removeDeviceToken(String token, String deviceToken) async {
    try {
      await _post('/me/device-token/remove', {'token': deviceToken}, token: token);
    } catch (_) {
      // صمت: الخروج يمضي وإن تعثّر المحو — التوكن يُطوى عند أوّل إرسالٍ فاشل.
    }
  }

  // ── صندوق الإشعارات (الجرس) ──

  /// صندوقي: الأحدثُ أوّلًا، ومعه عددُ غير المقروء (نداءٌ واحدٌ لا اثنان).
  ///
  /// **يرمي على العكس من نداءات الدفع**: الجرسُ شاشةٌ يفتحها اللاعب قاصدًا — فشلُها
  /// يُقال له («تعذّر الجلب · أعِد») لا يُبتلع فيرى فراغًا كاذبًا يظنّه «لا شيء».
  Future<({List<AppNotification> items, int unread})> notifications(String token,
      {int limit = 50, DateTime? before}) async {
    final q = {
      'limit': '$limit',
      if (before != null) 'before': before.toUtc().toIso8601String(),
    };
    final j = await _get('/me/notifications', token: token, query: q);
    return (
      items: [
        for (final e in (j['items'] as List? ?? const []))
          AppNotification.fromJson(e as Map<String, dynamic>),
      ],
      unread: (j['unread'] as num?)?.toInt() ?? 0,
    );
  }

  /// شارةُ الجرس وحدها — أرخصُ من جلب القائمة.
  ///
  /// **تبتلع الفشل**: تُنادى تلقائيًّا عند كلّ فتحةٍ ولم يطلبها أحد؛ خطأٌ أحمر
  /// لشيءٍ لم يُطلَب إزعاج. غيابُ الشارة أهونُ من إنذارٍ كاذب.
  Future<int?> unreadCount(String token) async {
    try {
      final j = await _get('/me/notifications/unread', token: token);
      return (j['unread'] as num?)?.toInt();
    } catch (_) {
      return null; // لا نعرف ⇒ لا شارة (لا صفرٌ كاذب)
    }
  }

  /// يُعلّم إشعارًا مقروءًا — أو **كلَّها** إن كان [id] فارغًا. يُعيد العدّ الجديد.
  Future<int> markNotificationRead(String token, {String? id}) async {
    final j = await _post('/me/notifications/read', {if (id != null) 'id': id},
        token: token);
    return (j['unread'] as num?)?.toInt() ?? 0;
  }

  // ── الأصدقاء ──

  /// قوائمي الثلاث: أصدقاءٌ · طلباتٌ واردة · طلباتٌ صادرة.
  /// قنواتُ الدعم الفنّي (واتساب/بريد) — يدفعها الخادم فتُضبَط يومَ تجهز الوسائل
  /// بلا تحديث تطبيق. حقلٌ فارغٌ ⇒ القناة غير جاهزة (يُخفيها قسمُ الإعدادات).
  Future<({String whatsapp, String email})> support() async {
    final j = await _get('/support');
    return (
      whatsapp: j['whatsapp'] as String? ?? '',
      email: j['email'] as String? ?? '',
    );
  }

  /// المباريات الحيّة القابلة للمشاهدة — الأكثرُ جمهورًا أوّلًا ([[spectator-system]]).
  Future<List<LiveTableView>> liveTables(String token) async {
    final j = await _get('/tables/live', token: token);
    return [
      for (final t in (j['tables'] as List? ?? const []))
        LiveTableView.fromJson(t as Map<String, dynamic>)
    ];
  }

  Future<FriendLists> friends(String token) async =>
      FriendLists.fromJson(await _get('/me/friends', token: token));

  /// يطلب صداقة صاحب [tag]. يُعيد الحال الناتجة: `pending` أو `accepted`
  /// (الأخيرة حين يكون قد طلبني فيتقابل الطلبان). الفشل [ApiException] برمزٍ
  /// يُترجمه [friendErrorText].
  Future<String> requestFriend(String token, String tag) async {
    final j = await _post('/me/friends/request', {'tag': tag}, token: token);
    return j['status'] as String? ?? 'pending';
  }

  /// يطلب صداقة صاحب [playerId] — **نظيرُ [requestFriend] من الطاولة**، حيث نعرف
  /// جليسَنا بمعرّفه لا برمزه (لقطةُ اللعب لا تحمل الرمز).
  Future<String> requestFriendById(String token, String playerId) async {
    final j =
        await _post('/me/friends/request', {'playerId': playerId}, token: token);
    return j['status'] as String? ?? 'pending';
  }

  /// **الملفّ العامّ للاعبٍ آخر** — يُفتَح بالضغط على بطاقته على الطاولة.
  Future<PublicPlayer> playerProfile(String token, String playerId) async =>
      PublicPlayer.fromJson(await _get('/players/$playerId', token: token));

  /// يقبل طلبًا واردًا من [playerId] (المعرّف الداخليّ من القائمة، لا الرمز).
  Future<void> acceptFriend(String token, String playerId) =>
      _post('/me/friends/accept', {'playerId': playerId}, token: token);

  /// يزيل العلاقة: رفضُ واردٍ · سحبُ صادرٍ · فكُّ صداقة — الثلاثة فعلٌ واحد.
  Future<void> removeFriend(String token, String playerId) =>
      _post('/me/friends/remove', {'playerId': playerId}, token: token);

  /// **حذف الحساب** — إلزامُ المتاجر. لا رجعةَ فيه: يُخلي الهاتف والرمز ويمحو
  /// الصداقات والمحفظة والإحصاء. على المُنادي أن يُسجّل الخروج بعده.
  Future<void> deleteAccount(String token) => _delete('/me', token: token);

  // ── الرسائل الخاصّة ──

  /// محادثتي مع [otherId] — الأحدثُ أوّلًا، و[before] لصفحةٍ أقدم.
  /// **فتحُها يقرؤها خادميًّا**: ما وصلني منه يُعلَّم مقروءًا في النداء نفسه.
  Future<List<ChatMessage>> conversation(String token, String otherId,
      {int limit = 50, DateTime? before}) async {
    final j = await _get('/me/messages/with/$otherId', token: token, query: {
      'limit': '$limit',
      if (before != null) 'before': before.toUtc().toIso8601String(),
    });
    return [
      for (final e in (j['items'] as List? ?? const []))
        ChatMessage.fromJson(e as Map<String, dynamic>)
    ];
  }

  /// يرسل رسالةً خاصّة. يُعيدها **كما خزّنها الخادم** (بعد التنظيف والقصّ) —
  /// هي ما سيراه الطرف الآخر. الفشل [ApiException] برمزٍ يُترجمه [messageErrorText].
  Future<ChatMessage> sendMessage(String token, String to, String text) async {
    final j = await _post('/me/messages/send', {'to': to, 'text': text},
        token: token);
    return ChatMessage.fromJson(j['message'] as Map<String, dynamic>);
  }

  /// شارةُ الرسائل الكلّيّة. **تبتلع الفشل** كشارة الجرس: تُنادى تلقائيًّا،
  /// وغيابُها أهون من إنذارٍ كاذب.
  Future<int?> unreadMessages(String token) async {
    try {
      final j = await _get('/me/messages/unread', token: token);
      return (j['total'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  // ── الحظر والبلاغ (إلزامُ المتاجر — UGC) ──

  /// من حظرتُهم — لقسم «المحظورون» في شاشة الأصدقاء.
  Future<List<FriendPlayer>> blockedPlayers(String token) async {
    final j = await _get('/me/blocks', token: token);
    return [
      for (final e in (j['players'] as List? ?? const []))
        FriendPlayer.fromJson(e as Map<String, dynamic>)
    ];
  }

  /// يحظر [playerId]: يفكّ الصداقةَ خادميًّا ويقطع الرسائلَ والدعواتِ ودردشةَ
  /// الطاولة بالاتّجاهين.
  Future<void> blockPlayer(String token, String playerId) =>
      _post('/me/blocks', {'playerId': playerId}, token: token);

  /// يفكّ حظري أنا وحده.
  Future<void> unblockPlayer(String token, String playerId) =>
      _post('/me/blocks/remove', {'playerId': playerId}, token: token);

  /// يُبلغ عن [playerId] — [area]: `chat` · `message` · `profile` · `other`.
  /// يصل لوحةَ تحكّم المالك، ولا يُعاقِب آليًّا.
  Future<void> reportPlayer(String token, String playerId,
          {required String area, String reason = ''}) =>
      _post('/me/reports',
          {'playerId': playerId, 'area': area, if (reason.isNotEmpty) 'reason': reason},
          token: token);

  /// رصيد المحفظة: الماس ومخزونُ الهدايا (gift:&lt;id&gt;). المفاتيح الغائبة = 0.
  Future<Map<String, int>> wallet(String token) async {
    final j = await _get('/me/wallet', token: token);
    return {
      for (final e in j.entries) e.key: (e.value as num?)?.toInt() ?? 0,
    };
  }

  /// **كم لعبةً بقيت لي اليوم**.
  ///
  /// يرمي [ApiException] بـ**503** إن كان الحدُّ مُطفأً خادميًّا — وهي حالةٌ تُعالَج
  /// (أخفِ العدّادَ، واللعبُ بلا حدّ) لا عطبٌ يُبلَّغ.
  Future<PlayAllowanceView> playLimit(String token) async =>
      PlayAllowanceView.fromJson(await _get('/me/play-limit', token: token));

  // ── البطولات ──
  // كلُّ فعلٍ يعيد الحالةَ الجديدةَ كاملةً — الشاشةُ تستطلع دوريًّا وتُحدَّث فورًا
  // من ردّ الفعل نفسه بلا استطلاعٍ إضافيّ. الأخطاء [ApiException] برمز `trn_*`
  // تترجمه [tournamentErrorText] (402 = اشترِ ماسًا · 409 = تعارضُ حال).

  Future<TournamentState> tournament(String token) async =>
      TournamentState.fromJson(await _get('/me/tournament', token: token));

  // [eventId] لفعاليّةٍ بعينها؛ null ⇒ البطولةُ اليوميّة.
  Future<TournamentState> tournamentRegister(String token,
          {String? eventId}) async =>
      TournamentState.fromJson(await _post('/me/tournament/register',
          {if (eventId != null) 'event': eventId},
          token: token));

  Future<TournamentState> tournamentUnregister(String token,
          {String? eventId}) async =>
      TournamentState.fromJson(await _post('/me/tournament/unregister',
          {if (eventId != null) 'event': eventId},
          token: token));

  /// يدعو صديقًا شريكًا له في البطولة (كلٌّ يدفع رسمَه عند تسجيله).
  Future<TournamentState> tournamentInvite(String token, String playerId,
          {String? eventId}) async =>
      TournamentState.fromJson(await _post(
          '/me/tournament/invite',
          {'playerId': playerId, if (eventId != null) 'event': eventId},
          token: token));

  Future<TournamentState> tournamentAccept(String token,
          {String? eventId}) async =>
      TournamentState.fromJson(await _post('/me/tournament/accept',
          {if (eventId != null) 'event': eventId},
          token: token));

  Future<TournamentState> tournamentDecline(String token,
          {String? eventId}) async =>
      TournamentState.fromJson(await _post('/me/tournament/decline',
          {if (eventId != null) 'event': eventId},
          token: token));

  /// **إنشاءُ مسابقة لاعب** (رسمُ الإنشاء 50💎 غيرُ مستردّ — يُخصم خادميًّا).
  /// الحدود: الاسم 3–30 · الرسم 10–500 · الحجم 8/16 فريقًا · الموعد خلال
  /// 10د–7أيّام. الفشل [ApiException] برمزٍ يترجمه [tournamentErrorText].
  Future<TournamentState> tournamentCreateEvent(
    String token, {
    required String title,
    required DateTime startsAt,
    required int entryFee,
    required int teams,
  }) async =>
      TournamentState.fromJson(await _post(
          '/me/tournament/events/create',
          {
            'title': title,
            'startsAt': startsAt.toUtc().toIso8601String(),
            'entryFee': entryFee,
            'teams': teams,
          },
          token: token));

  /// إلغاءُ **منشئِ** المسابقة لمسابقته قبل بدئها — ردٌّ كاملٌ للمسجّلين،
  /// ورسمُ الإنشاء لا يعود.
  Future<TournamentState> tournamentCancelEvent(
          String token, String eventId) async =>
      TournamentState.fromJson(await _post(
          '/me/tournament/events/cancel', {'event': eventId},
          token: token));

  /// مركزُ المحتوى (أخبارٌ ولافتات) — عامٌّ بلا توكن.
  Future<({List<NewsView> news, List<BannerView> banners})> content() async {
    final j = await _get('/content');
    return (
      news: [
        for (final n in (j['news'] as List? ?? const []))
          NewsView.fromJson(n as Map<String, dynamic>)
      ],
      banners: [
        for (final b in (j['banners'] as List? ?? const []))
          BannerView.fromJson(b as Map<String, dynamic>)
      ],
    );
  }

  /// **التذاكر المعروضة** — بلا توكن. السعرُ معلومةٌ لا سرّ.
  Future<List<TicketView>> tickets() async {
    final j = await _get('/store/tickets');
    return [
      for (final t in (j['tickets'] as List? ?? const []))
        TicketView.fromJson(t as Map<String, dynamic>)
    ];
  }

  /// يشتري تذكرةً بالماس. يُعيد (نهايةُ النافذة، المحفظةُ الجديدة).
  ///
  /// يرمي [ApiException] بـ**402** إن كان الماسُ لا يكفي — حالةٌ تُعالَج (قُدْه إلى
  /// باقات الماس) يفرّقها المُنادي عن معرّفٍ فاسد (400).
  Future<
      ({
        DateTime passUntil,
        Map<String, int> wallet,
        bool suggestVip
      })> buyTicket(String token, String ticketId) async {
    final j = await _post('/me/tickets/buy', {'ticket': ticketId}, token: token);
    final w = j['wallet'] as Map<String, dynamic>? ?? const {};
    return (
      passUntil: DateTime.parse(j['passUntil'] as String).toLocal(),
      wallet: {for (final e in w.entries) e.key: (e.value as num?)?.toInt() ?? 0},
      // **الخادمُ يقرّر متى يُعرَض VIP** لا العميل: العدُّ في السجلّ لا في الجهاز.
      suggestVip: j['suggestVip'] as bool? ?? false,
    );
  }

  /// **خطط VIP المعروضة** — بلا توكن. السعرُ معلومةٌ لا سرّ.
  Future<List<VipPlanView>> vipPlans() async {
    final j = await _get('/store/vip');
    return [
      for (final p in (j['plans'] as List? ?? const []))
        VipPlanView.fromJson(p as Map<String, dynamic>)
    ];
  }

  /// **حالةُ VIP** — وتصرف ما استحقّ من دفعاتٍ شهريّة (فتحُ التطبيق هو المُجدوِل).
  /// تُعيد (أهو VIP، نهايتُه، كم دفعةً صُرفت الآن، المحفظة).
  Future<({bool active, DateTime? until, int granted, Map<String, int> wallet})>
      vipStatus(String token) async {
    final j = await _get('/me/vip', token: token);
    final w = j['wallet'] as Map<String, dynamic>? ?? const {};
    return (
      active: j['active'] as bool? ?? false,
      until: DateTime.tryParse(j['until'] as String? ?? '')?.toLocal(),
      granted: (j['granted'] as num?)?.toInt() ?? 0,
      wallet: {for (final e in w.entries) e.key: (e.value as num?)?.toInt() ?? 0},
    );
  }

  /// يشترك في VIP بالماس. يُعيد (نهايةُ الاشتراك، المحفظةُ الجديدة).
  ///
  /// يرمي [ApiException] بـ**402** إن كان الماسُ لا يكفي.
  Future<({DateTime until, Map<String, int> wallet})> subscribeVip(
      String token, String planId) async {
    final j = await _post('/me/vip/subscribe', {'plan': planId}, token: token);
    final w = j['wallet'] as Map<String, dynamic>? ?? const {};
    return (
      until: DateTime.parse(j['until'] as String).toLocal(),
      wallet: {for (final e in w.entries) e.key: (e.value as num?)?.toInt() ?? 0},
    );
  }

  /// **رصيدُ هدايا VIP** — وقراءتُه تجدّد ما استحقّ (فتحُ التطبيق هو المُجدوِل).
  Future<int> vipGiftStock(String token) async {
    final j = await _get('/me/vip/gifts', token: token);
    return (j['stock'] as num?)?.toInt() ?? 0;
  }

  /// **يستلم التجربةَ المجّانيّة** — يومٌ هديّةً، مرّةً في العمر. يُعيد نهايتَها.
  ///
  /// يرمي [ApiException] بـ**409** إن سبق أن نالها — حالةٌ تُعالَج (اعرض الشراء)
  /// لا عطبٌ يُبلَّغ.
  Future<DateTime> claimTrial(String token) async {
    final j = await _post('/me/tickets/trial', const {}, token: token);
    return DateTime.parse(j['passUntil'] as String).toLocal();
  }

  /// **مهامّي** بحالتها في فتراتها الحاليّة.
  ///
  /// يرمي [ApiException] بـ**503** إن كانت المهامّ مُطفأةً خادميًّا — وهي حالةٌ
  /// تُعالَج (أخفِ القسم) لا عطبٌ يُبلَّغ.
  Future<List<MissionView>> missions(String token) async {
    final j = await _get('/me/missions', token: token);
    return [
      for (final m in (j['missions'] as List? ?? const []))
        MissionView.fromJson(m as Map<String, dynamic>)
    ];
  }

  /// يقبض جائزةَ مهمّة. يُعيد (المحفظةَ الجديدة، الإحصاءَ الجديد).
  ///
  /// يرمي [ApiException] بـ**409** إن كانت قد قُبضت أو لم تكتمل — طلبٌ سليمٌ في
  /// حالةٍ لا تسمح، يفرّقه المُنادي عن معرّفٍ فاسد (400).
  Future<({Map<String, int> wallet, PlayerStatsView stats})> claimMission(
      String token, String missionId) async {
    final j = await _post('/me/missions/claim', {'mission': missionId},
        token: token);
    final w = j['wallet'] as Map<String, dynamic>? ?? const {};
    return (
      wallet: {for (final e in w.entries) e.key: (e.value as num?)?.toInt() ?? 0},
      stats: PlayerStatsView.fromJson(
          j['stats'] as Map<String, dynamic>? ?? const {}),
    );
  }

  /// **باقات الماس المعروضة** — بلا توكن.
  ///
  /// **لا شراءَ يقابلها**: بنكيلي آخرُ خطوةٍ في المشروع، فالصفحةُ تُخبر بالسلّم وحدَه.
  Future<List<DiamondPackView>> diamondPacks() async {
    final j = await _get('/store/diamond-packs');
    return [
      for (final p in (j['packs'] as List? ?? const []))
        DiamondPackView.fromJson(p as Map<String, dynamic>)
    ];
  }

  /// **باقات الهدايا المعروضة** — بلا توكن: الأسعار ليست سرًّا.
  ///
  /// الثمنُ يأتي من الخادم ولا يُحسَب هنا: نسخةٌ ثانيةٌ من معادلة الخصم تنجرف عن
  /// الحقيقة أوّلَ ما يتغيّر السعر، فيرى اللاعبُ رقمًا ويُخصَم غيرُه.
  Future<List<GiftBundleView>> giftBundles() async {
    final j = await _get('/store/gift-bundles');
    return [
      for (final b in (j['bundles'] as List? ?? const []))
        GiftBundleView.fromJson(b as Map<String, dynamic>)
    ];
  }

  /// يشتري باقةً. يُعيد المحفظةَ بعد الشراء.
  ///
  /// يرمي [ApiException] بـ**402** إن لم يكفِ الماس — وهي ليست عطبًا بل حالةٌ
  /// تُعالَج (افتح المتجر)، فلا تُخلَط بـ400.
  Future<Map<String, int>> buyGiftBundle(String token, String bundleId) async {
    final j = await _post('/me/gift-bundles/buy', {'bundle': bundleId},
        token: token);
    final w = j['wallet'] as Map<String, dynamic>? ?? const {};
    return {for (final e in w.entries) e.key: (e.value as num?)?.toInt() ?? 0};
  }

  /// إحصائيات اللاعب الحاليّ (تصنيف، مباريات، فوز/خسارة، سلاسل).
  Future<PlayerStatsView> stats(String token) async {
    final j = await _get('/me/stats', token: token);
    return PlayerStatsView.fromJson(j);
  }

  /// توكن صوت الطاولة التي يجلس عليها اللاعب الآن.
  /// يرمي [ApiException] 409 إن لم يكن على طاولة، و503 إن كان الصوت غير مُهيّأ خادميًّا.
  Future<VoiceGrant> voiceToken(String token) async {
    final j = await _get('/me/voice/token', token: token);
    return VoiceGrant.fromJson(j);
  }

  /// **لوحةُ الشرف الأسبوعيّة** (عامّةٌ بلا توكن كالصدارة).
  Future<HonorsBoard> honors() async =>
      HonorsBoard.fromJson(await _get('/honors'));

  /// لوحة التصنيف العامّة (لا تحتاج توكنًا). مرتّبة تنازليًّا؛ الرتبة = الترتيب.
  Future<List<LeaderEntry>> leaderboard() async {
    final j = await _get('/leaderboard');
    final rows = (j['entries'] as List?) ?? const [];
    return [
      for (var i = 0; i < rows.length; i++)
        LeaderEntry.fromJson(rows[i] as Map<String, dynamic>, i + 1),
    ];
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
          {String? token}) =>
      _send(() => _http.post(
            config.http(path),
            headers: {
              'content-type': 'application/json',
              if (token != null) 'authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          ));

  Future<Map<String, dynamic>> _delete(String path, {String? token}) =>
      _send(() => _http.delete(
            config.http(path),
            headers: {if (token != null) 'authorization': 'Bearer $token'},
          ));

  /// GET، بتوكن Bearer اختياريّ (المسارات العامّة كالتصنيف بلا توكن).
  Future<Map<String, dynamic>> _get(String path,
          {String? token, Map<String, String>? query}) =>
      _send(() => _http.get(
            query == null || query.isEmpty
                ? config.http(path)
                : config.http(path).replace(queryParameters: query),
            headers: {if (token != null) 'authorization': 'Bearer $token'},
          ));

  /// ينفّذ الطلب ويوحّد معالجة الأخطاء: يقرأ `error` العربيّ من الخادم عند فشل الحالة،
  /// ويحوّل فشل الشبكة/المهلة إلى [ApiException] بحالة 0 — لا استثناءات خامّة تتسرّب.
  Future<Map<String, dynamic>> _send(Future<http.Response> Function() run) async {
    final http.Response res;
    try {
      res = await run().timeout(timeout);
    } catch (e) {
      throw const ApiException(0, 'تعذّر الاتصال بالخادم');
    }
    Map<String, dynamic> j;
    try {
      j = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      j = {};
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return j;
    throw ApiException(res.statusCode, (j['error'] as String?) ?? 'خطأ غير متوقّع');
  }

  void close() => _http.close();
}
