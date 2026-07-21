/// **رتبةُ المهارة** — نموذجُ عرضٍ لِما يبثّه الخادم (`server/lib/tiers.dart`).
///
/// يشترك فيه مسارُ HTTP (الملفّ · الصدارة · لوحة اللاعب) ومسارُ WS (رسالةُ التصنيف
/// بعد المباراة)، فوُضع في ملفٍّ محايدٍ بينهما.
library;

/// **رتبةُ المهارة** كما يبثّها الخادم (`tiers.dart`).
///
/// **العتباتُ لا تُنسَخ هنا**: الاسمُ والرمزُ والتقدّمُ كلُّها محسوبةٌ هناك، وحزمةٌ
/// قديمةٌ تحمل سُلَّمًا قديمًا كانت ستعرض «محترف» لمن صار «نخبة». خادمٌ أقدمُ من
/// الميزة ⇒ `null` ⇒ لا شارةَ ولا مكانَ محجوز (كنهج [[honor-badge]]).
class PlayerRankView {
  /// مفتاحُ الرتبة (`beginner` … `legend`) — للثيم لا للعرض.
  final String tier;

  /// الاسمُ المعروض: «محترف» أو «غير مصنَّف».
  final String title;

  /// رمزُ الرتبة — فارغٌ لغير المرشَّح.
  final String emoji;

  /// هل استوفى مبارياتِ الترشيح؟
  final bool placed;

  /// كم مباراةً مصنَّفةً بقيت للترشيح.
  final int remaining;

  /// موقعُه داخل رتبته (0..1) — لشريط التقدّم.
  final double progress;

  /// تصنيفُ الرتبة التالية واسمُها — `null`/فارغٌ لأعلى السُّلَّم.
  final int? nextAt;
  final String nextTitle;

  const PlayerRankView({
    required this.tier,
    required this.title,
    this.emoji = '',
    this.placed = false,
    this.remaining = 0,
    this.progress = 0,
    this.nextAt,
    this.nextTitle = '',
  });

  static PlayerRankView? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : PlayerRankView(
          tier: j['tier'] as String? ?? '',
          title: j['title'] as String? ?? '',
          emoji: j['emoji'] as String? ?? '',
          placed: j['placed'] as bool? ?? false,
          remaining: (j['remaining'] as num?)?.toInt() ?? 0,
          progress: (j['progress'] as num?)?.toDouble() ?? 0,
          nextAt: (j['nextAt'] as num?)?.toInt(),
          nextTitle: j['nextTitle'] as String? ?? '',
        );
}
