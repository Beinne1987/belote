import 'package:flutter/material.dart' show Icon, Icons; // شارة الميكروفون فقط
import 'package:flutter/widgets.dart';

import '../game/seat_player.dart';
import '../net/player_rank.dart';
import '../strings_ar.dart';
import '../theme/belote_theme.dart';
import 'player_avatar.dart';

/// **بطاقة لاعبٍ مربّعة** — حوافٌّ دائرية وخلفيّةٌ داكنة، من أعلى لأسفل:
/// إيموجي في دائرة · الاسم · شارة الرتبة. **كل الألوان من الثيم** (`BeloteTheme`) —
/// لا رقم لونٍ هنا. البيانات (الاسم/الرتبة/الإيموجي) **تُمرَّر** ولا تُحسَب. بلا نجوم.
///
/// حالتان: عاديّة، و[active] (صاحب الدور) بإطارٍ ذهبيٍّ متوهّج.
class PlayerCardSquare extends StatelessWidget {
  final String name;

  /// إيموجي المقعد — **بديلُ الصورة** حين لا صورةَ للاعب (أو تعذّر جلبُها).
  final String emoji;

  /// رابط صورته النسبيّ من الخادم (`/avatars/…`). فارغٌ ⇒ [emoji]. أوفلاين ⇒ فارغٌ
  /// دائمًا (لا حسابات، ولا خادمَ يُجلَب منه).
  final String avatarUrl;

  final PlayerRank rank;

  /// **رتبةُ المهارة من الخادم** — إن وُجدت **تتقدّم** [rank] المشتقّة محلّيًّا:
  /// الخادمُ وحدَه يعرف عددَ المباريات (لا رتبةَ قبل الترشيح) والسُّلَّمَ الحاليّ.
  /// null ⇒ ذكاءٌ أو أوفلاين أو خادمٌ أقدم ⇒ تبقى المحلّيّةُ كما كانت.
  final PlayerRankView? skill;

  /// صاحب الدور الآن ⇒ إطارٌ ذهبيٌّ متوهّج.
  final bool active;

  /// يتكلّم في المحادثة الصوتيّة الآن ⇒ شارة ميكروفونٍ خضراء على زاوية البطاقة.
  /// **شارةٌ لا إطار** عمدًا: الإطار الذهبيّ محجوزٌ لصاحب الدور — وهو خبرٌ يخصّ القاعدة،
  /// فلا يزاحمه خبرٌ اجتماعيّ. ويجتمعان على بطاقةٍ واحدةٍ بلا تعارض.
  final bool speaking;

  /// **أهو VIP؟** ⇒ إطارُه الذهبيُّ حول صورته وشارتُه على البطاقة. مَن دفع 500
  /// يُرى — وإلّا اشترى مكانةً لا يراها أحد (بلاغُ المالك 2026-07-16).
  final bool isVip;

  /// ضلع المربّع بالبكسل — كل المقاييس الداخليّة تُشتقّ منه فتتناسب البطاقة.
  final double size;

  /// يفتح لوحةَ اللاعب (ملفّ · تصنيف · صداقة · إهداء). null ⇒ **البطاقةُ لا
  /// تُضغَط**: ذكاءٌ أو مقعدٌ فارغ أو أوفلاين — لا حسابَ خلفها فلا وعدَ نفتحه.
  final VoidCallback? onTap;

  /// **توهّجٌ عابرٌ بلون الهديّة** أثناء طيرانها: يُشعل بطاقةَ المُرسِل وبطاقةَ
  /// المستقبِل معًا فيُقرأ الطرفان من طرف الشاشة إلى طرفها. null ⇒ لا توهّج.
  ///
  /// **لونٌ لا إطار**: الإطارُ الذهبيُّ محجوزٌ لصاحب الدور (خبرُ القاعدة)، فلا
  /// يزاحمه خبرٌ اجتماعيّ — نفس منطق شارة الميكروفون أعلاه.
  final Color? giftGlow;

  const PlayerCardSquare({
    super.key,
    required this.name,
    required this.emoji,
    required this.rank,
    this.skill,
    this.avatarUrl = '',
    this.active = false,
    this.speaking = false,
    this.isVip = false,
    this.size = 132,
    this.onTap,
    this.giftGlow,
  });

  /// الدرجتان الأدنى بشارةٍ خضراء، والأعلى بذهبيّة — اختيارٌ من الثيم لا رقم لون.
  bool get _gold => rank == PlayerRank.expert || rank == PlayerRank.legend;

  /// نصُّ الشارة: رتبةُ الخادم إن ترشّح صاحبُها، وإلّا المشتقّةُ محلّيًّا.
  /// **لا «غير مصنَّف» على الطاولة**: خبرٌ لا يفيد الجالسين ويزاحم الاسم.
  String get _rankText =>
      (skill?.placed ?? false) ? skill!.title : S.rankLabel(rank);

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final badgeBg = _gold
        ? (rank == PlayerRank.legend ? t.accentBright : t.accent)
        : t.success;
    final badgeInk = _gold ? t.onAccent : t.text;
    final avatar = size * 0.42;

    // **إطار VIP الدائريّ حول الصورة** — بدل الإطار المربّع القديم الذي لم يعد
    // يناسب البطاقة (قرار المالك 2026-07-19). نفسُ الأصل المستعمَل في الأصدقاء
    // واللوبي والملفّ ⇒ إشارةُ VIP موحّدةٌ عبر التطبيق.
    Widget avatarWidget = PlayerAvatar(
      url: avatarUrl,
      fallback: emoji,
      size: avatar,
      borderColor: active ? t.accent : t.line,
    );
    if (isVip) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatarWidget,
          IgnorePointer(
            child: Image.asset(
              'assets/VIP/frame_gold_round.png',
              width: avatar * 1.38,
              height: avatar * 1.38,
            ),
          ),
        ],
      );
    }

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(size * 0.16),
        border: Border.all(
          color: giftGlow ?? (active ? t.accentBright : t.line),
          width: giftGlow != null ? 2.4 : (active ? 2.4 : 1),
        ),
        boxShadow: giftGlow != null
            // **يغلب توهّجُ الهديّة توهّجَ الدور** ما دام يطير: ثانيةٌ واحدةٌ يعود
            // بعدها الذهبيُّ. اجتماعُ الهالتين يُنتج لونًا وحلًا لا يدلّ على شيء.
            ? [
                BoxShadow(
                    color: giftGlow!.withValues(alpha: 0.75),
                    blurRadius: 26,
                    spreadRadius: 3),
                BoxShadow(color: t.shadow, blurRadius: 10, offset: const Offset(0, 4)),
              ]
            : active
            // توهّجٌ ذهبيّ حول صاحب الدور + عمقٌ خفيف.
            ? [
                BoxShadow(
                    color: t.accent.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 1),
                BoxShadow(color: t.shadow, blurRadius: 10, offset: const Offset(0, 4)),
              ]
            : [BoxShadow(color: t.shadow, blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── الصورة (أو الإيموجي) في دائرة — مع إطار VIP الدائريّ إن كان VIP ──
          avatarWidget,

          // ── الاسم ──
          // مرن: حدّ البطاقة النشطة أسمك (2.4 مقابل 1) فيقتطع من ارتفاع المحتوى.
          // بلا مرونةٍ يفيض العمود على البطاقة النشطة تحديدًا — وهي أبرز ما يُنظَر إليه.
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.02),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.text,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.125,
                ),
              ),
            ),
          ),

          // ── شارة الرتبة ──
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: size * 0.09, vertical: size * 0.035),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _rankText,
              style: TextStyle(
                color: badgeInk,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.1,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );

    // **لا كادرٌ مربّعٌ حول البطاقة** بعد الآن (قرار المالك 2026-07-19: «الإطار
    // المربّع لم يعد يناسب البطاقة»). إشارةُ VIP صارت الإطارَ الدائريَّ حول الصورة
    // (أعلاه) + شارةَ «VIP» ذهبيّةً في الزاوية.
    final tappable = onTap == null
        ? card
        : Semantics(
            button: true,
            label: 'ملفّ $name',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: card,
            ),
          );

    if (!speaking && !isVip) return tappable;
    return Stack(
      clipBehavior: Clip.none, // الشارات تتجاوز حدّ البطاقة قليلًا
      children: [
        tappable,
        if (speaking)
          PositionedDirectional(
            top: -size * 0.04,
            start: -size * 0.04,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: t.success,
                shape: BoxShape.circle,
                border: Border.all(color: t.surface, width: size * 0.02),
              ),
              child: Icon(Icons.mic, color: t.onAccent, size: size * 0.15),
            ),
          ),
        // شارةُ VIP الذهبيّة — أعلى اليمين، بعيدًا عن شارة الميكروفون (أعلى اليسار).
        if (isVip)
          PositionedDirectional(
            top: -size * 0.05,
            end: -size * 0.04,
            child: IgnorePointer(
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: size * 0.07, vertical: size * 0.02),
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.onAccent, width: size * 0.01),
                ),
                child: Text('VIP',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: t.onAccent,
                      fontSize: size * 0.115,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    )),
              ),
            ),
          ),
      ],
    );
  }
}
