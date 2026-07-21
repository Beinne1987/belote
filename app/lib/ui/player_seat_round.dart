import 'package:flutter/material.dart'
    show Icon, Icons, Tooltip; // أيقوناتُ الأزرار وتلميحاتُها
import 'package:flutter/widgets.dart';

import '../game/seat_player.dart';
import '../net/player_rank.dart';
import '../strings_ar.dart';
import '../theme/belote_theme.dart';
import 'app_frame.dart';
import 'player_avatar.dart';

/// حالُ صوتي على زرّ الميكروفون. **نظيرُ `VoiceStatus` بلا استيراد طبقة الصوت**:
/// المقعدُ ودجت عرضٍ محضة، تُرسَم في الاختبارات والمعاينة بلا لايف كيت ولا شبكة.
enum SeatVoice { off, connecting, live, failed }

/// **مقعدُ لاعبٍ دائريّ على الطاولة** — التصميمُ الذي أقرّه المالك:
/// **الاسمُ فوق الصورة**، والصورةُ دائرةٌ، **وتحتها زرّان** في متناول الإبهام.
///
/// الزرّان يختلفان بصاحب المقعد:
/// - **لاعبٌ آخر**: 🎁 هديّةٌ له · 🔇 كتمُ صوته. الكتمُ هنا لا في لوحةٍ مدفونة —
///   من يزعجك تكتمه وأنت تنظر إليه.
/// - **مقعدي أنا** ([mine]): 🎤 **مفتاحُ الصوت كلِّه** (وصلٌ وقطع) · 🎁 **هديّةٌ للجميع**.
///
/// **لا معلومةَ ضاعت** من البطاقة المربّعة: الصورةُ · الاسمُ · الرتبةُ · إطارُ VIP
/// وشارتُه الذهبيّة · شارةُ الميكروفون · توهّجُ الدور · توهّجُ الهديّة.
class PlayerSeatRound extends StatelessWidget {
  final String name;

  /// إيموجي المقعد — **بديلُ الصورة** حين لا صورةَ للاعب (أو تعذّر جلبُها).
  final String emoji;

  /// رابط صورته النسبيّ من الخادم (`/avatars/…`). فارغٌ ⇒ [emoji].
  final String avatarUrl;

  final PlayerRank rank;

  /// **رتبةُ المهارة من الخادم** — إن وُجدت **تتقدّم** [rank] المشتقّة محلّيًّا:
  /// الخادمُ وحدَه يعرف عددَ المباريات (لا رتبةَ قبل الترشيح) والسُّلَّمَ الحاليّ.
  /// null ⇒ ذكاءٌ أو أوفلاين أو خادمٌ أقدم ⇒ تبقى المحلّيّةُ كما كانت.
  final PlayerRankView? skill;

  /// صاحب الدور الآن ⇒ حَلَقةٌ ذهبيّةٌ متوهّجة.
  final bool active;

  /// يتكلّم في المحادثة الصوتيّة الآن ⇒ شارةُ ميكروفونٍ خضراء على الدائرة.
  /// **شارةٌ لا حَلَقة**: الذهبيّةُ محجوزةٌ لصاحب الدور — خبرُ القاعدة لا يزاحمه
  /// خبرٌ اجتماعيّ، ويجتمعان على مقعدٍ واحدٍ بلا لبس.
  final bool speaking;

  /// **أهو VIP؟** ⇒ إطارُه الذهبيُّ الدائريُّ وشارةُ «VIP» ذهبيّة.
  final bool isVip;

  /// **رمزُ لقبِ الأسبوع** (👑/🏆/…) بجانب الاسم — فارغٌ ⇒ لا لقبَ ولا مساحة.
  /// رمزٌ وحدَه لا نصّ: اللوحُ عرضُه `size×2` ويحمل الاسمَ والرتبة.
  /// [[honors-weekly]]
  final String honorEmoji;

  /// **توهّجٌ عابرٌ بلون الهديّة** أثناء طيرانها: يُشعل مقعدَ المُرسِل والمستقبِل
  /// معًا فيُقرأ الطرفان من طرف الشاشة إلى طرفها. null ⇒ لا توهّج.
  final Color? giftGlow;

  /// قطرُ الدائرة — كلُّ المقاييس تُشتقّ منه.
  final double size;

  /// **مقعدي أنا** ⇒ الزرّان ميكروفونٌ وهديّةٌ للجميع بدل هديّةٍ وكتم.
  final bool mine;

  /// **الزرّان بجانب الصورة لا تحتها** — يوفّر ارتفاعَ زرٍّ كاملٍ (≈56% من قطر
  /// الدائرة). يُستعمل لمقعدي أنا: هو المحشورُ بين دائرة اللعب ويدي، وكلُّ بكسلٍ
  /// عموديٍّ هناك يُقتطع من إحداهما (طلبُ المالك 2026-07-21).
  final bool sideButtons;

  /// إهداءُ صاحب المقعد (أو **الجميع** إن كان [mine]). null ⇒ لا زرَّ هديّة.
  final VoidCallback? onGift;

  /// كتمُ صوته / فكُّ كتمه. null ⇒ لا زرَّ كتم (أوفلاين أو ذكاءٌ أو بلا صوت).
  final VoidCallback? onMute;
  final bool muted;

  /// **مفتاحُ الصوت كلِّه** — لمقعدي وحدَه: ضغطةٌ تصل وتفتح فمي، وضغطةٌ تقطع.
  /// null ⇒ لا زرَّ ميكروفون (أوفلاين أو متفرّج).
  final VoidCallback? onMic;

  /// حالُ صوتي كما يراها اللاعب. الودجت لا تستورد طبقةَ الصوت — الشاشةُ تترجم.
  final SeatVoice voiceState;

  /// يفتح لوحةَ اللاعب (ملفّ · تصنيف · صداقة). null ⇒ **لا تُفتَح**: ذكاءٌ أو
  /// مقعدٌ فارغٌ أو أوفلاين — لا حسابَ خلفه فلا وعدَ نفتحه.
  final VoidCallback? onTap;

  const PlayerSeatRound({
    super.key,
    required this.name,
    required this.emoji,
    required this.rank,
    this.skill,
    this.avatarUrl = '',
    this.active = false,
    this.speaking = false,
    this.isVip = false,
    this.honorEmoji = '',
    this.giftGlow,
    this.size = 54,
    this.mine = false,
    this.sideButtons = false,
    this.onGift,
    this.onMute,
    this.muted = false,
    this.onMic,
    this.voiceState = SeatVoice.off,
    this.onTap,
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
    final ring = giftGlow ?? (active ? t.accentBright : t.line);
    final rankColor = _gold
        ? (rank == PlayerRank.legend ? t.accentBright : t.accent)
        : t.success;

    Widget circle = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.surface,
        border: Border.all(
            color: ring, width: (giftGlow != null || active) ? 2.4 : 1),
        boxShadow: giftGlow != null
            // **يغلب توهّجُ الهديّة توهّجَ الدور** ما دام يطير: ثانيةٌ واحدةٌ يعود
            // بعدها الذهبيّ. اجتماعُ الهالتين يُنتج لونًا وحلًا لا يدلّ على شيء.
            ? [
                BoxShadow(
                    color: giftGlow!.withValues(alpha: 0.75),
                    blurRadius: 24,
                    spreadRadius: 3),
              ]
            : active
                ? [
                    BoxShadow(
                        color: t.accent.withValues(alpha: 0.55),
                        blurRadius: 16,
                        spreadRadius: 1),
                  ]
                : [
                    BoxShadow(
                        color: t.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
      ),
      child: Center(
        child: PlayerAvatar(
          url: avatarUrl,
          fallback: emoji,
          size: size * 0.88,
          borderColor: t.line.withValues(alpha: 0.4),
        ),
      ),
    );

    if (isVip) {
      circle = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          circle,
          IgnorePointer(
            child: Image.asset('assets/VIP/frame_gold_round.png',
                width: size * 1.32, height: size * 1.32),
          ),
        ],
      );
    }

    // ── الاسمُ (والرتبة) فوق الصورة، على لوحٍ داكنٍ يُقرأ على الخشب واللبّاد ──
    final plate = Container(
      constraints: BoxConstraints(maxWidth: size * 2.0),
      padding:
          EdgeInsets.symmetric(horizontal: size * 0.16, vertical: size * 0.05),
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.line.withValues(alpha: 0.45), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (honorEmoji.isNotEmpty) ...[
                Text(honorEmoji, style: TextStyle(fontSize: size * 0.22)),
                SizedBox(width: size * 0.06),
              ],
              // **مرنٌ لا ثابت**: الاسمُ يتقلّص للقب ولا يدفعه خارج اللوح.
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFF3EAD6),
                    fontWeight: FontWeight.w800,
                    fontSize: size * 0.22,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          Text(
            _rankText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: rankColor,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.16,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    // ── الزرّان تحت الصورة ──
    final buttons = <Widget>[
      if (mine && onMic != null)
        _SeatButton(
          // **الحالُ في الزرّ لا في لوحةٍ مدفونة**: أخضرُ ⇒ صوتي حيٌّ ويسمعني
          // الجميع · رماديٌّ ⇒ مقطوعٌ (ولذلك ليس أحمرَ: القطعُ اختيارٌ لا عطل)
          // · أحمرُ ⇒ تعذّر، والضغطةُ تُعيد المحاولة وتُظهر السبب.
          tip: switch (voiceState) {
            SeatVoice.live => 'صوتي مفتوح — اضغط لقطع الصوت',
            SeatVoice.connecting => 'يتّصل…',
            SeatVoice.failed => 'تعذّر الصوت — اضغط للمحاولة',
            SeatVoice.off => 'الصوت مقطوع — اضغط لتتكلّم',
          },
          icon: switch (voiceState) {
            SeatVoice.live => Icons.mic,
            SeatVoice.connecting => Icons.mic_none, // ريثما يجيب الخادم
            SeatVoice.off || SeatVoice.failed => Icons.mic_off,
          },
          bg: switch (voiceState) {
            SeatVoice.live => t.success,
            SeatVoice.connecting => t.surface2,
            SeatVoice.failed => t.error,
            SeatVoice.off => t.surface2,
          },
          size: size,
          onTap: onMic!,
        ),
      if (onGift != null)
        _SeatButton(
          tip: mine ? 'هديّة للجميع' : 'هديّة لِ$name',
          // **`redeem` لا `card_giftcard`**: الأخيرةُ أيقونةُ زرّ الهدايا في شريط
          // الأدوات؛ لو تشابهتا لَبدا الزرّان واحدًا في مكانين.
          icon: Icons.redeem,
          bg: t.accent,
          size: size,
          onTap: onGift!,
        ),
      if (!mine && onMute != null)
        _SeatButton(
          tip: muted ? 'إلغاء كتم $name' : 'كتم $name',
          icon: muted ? Icons.volume_off : Icons.volume_up,
          bg: muted ? t.error : t.surface2,
          size: size,
          onTap: onMute!,
        ),
    ];

    final avatarStack = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        circle,
        if (speaking)
          Positioned(
            top: -size * 0.03,
            right: -size * 0.07,
            child: Container(
              padding: EdgeInsets.all(size * 0.055),
              decoration: BoxDecoration(
                color: t.success,
                shape: BoxShape.circle,
                border:
                    Border.all(color: t.bg.withValues(alpha: 0.7), width: 1),
              ),
              child: Icon(Icons.mic, size: size * 0.24, color: t.onAccent),
            ),
          ),
        if (isVip)
          Positioned(
            top: -size * 0.05,
            left: -size * 0.12,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: size * 0.12, vertical: size * 0.03),
              decoration: BoxDecoration(
                // **ذهبيّةٌ صريحة** (طلبُ المالك): مَن دفع يُرى ذهبُه.
                gradient: LinearGradient(
                  colors: [t.accentBright, t.accentDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: t.accentBright.withValues(alpha: 0.9), width: 0.8),
                boxShadow: [
                  BoxShadow(
                      color: t.accent.withValues(alpha: 0.55), blurRadius: 8),
                ],
              ),
              child: Text('VIP',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: t.onAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: size * 0.16,
                    height: 1,
                  )),
            ),
          ),
      ],
    );

    // **الزرّان: تحت الصورة أو بجانبها.** الجانبيُّ يضع أوّلَ زرٍّ في جهةٍ
    // والثانيَ في الأخرى فتبقى الصورةُ في المنتصف؛ وزرٌّ واحدٌ يجلس في جهةٍ
    // واحدةٍ ويُوازَن بفراغٍ مثلِه كي لا تنزاح الصورةُ عن مرسى المقعد
    // (`kSeatAnchors`) — وإلّا هبطت الهديّةُ الطائرة بجانب الوجه لا عليه.
    final gap = SizedBox(width: size * 0.12);
    final Widget seat = sideButtons && buttons.isNotEmpty
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              plate,
              SizedBox(height: size * 0.08),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buttons.first,
                  gap,
                  avatarStack,
                  gap,
                  if (buttons.length > 1)
                    buttons[1]
                  else
                    SizedBox(width: size * 0.46),
                ],
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              plate,
              SizedBox(height: size * 0.08),
              avatarStack,
              if (buttons.isNotEmpty) ...[
                SizedBox(height: size * 0.10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < buttons.length; i++) ...[
                      if (i > 0) gap,
                      buttons[i],
                    ],
                  ],
                ),
              ],
            ],
          );

    if (onTap == null) return seat;
    // **الضغطُ على الصورة والاسم يفتح اللوحة، والزرّان مستقلّان**: الزرُّ يبتلع
    // لمستَه (له `GestureDetector` خاصّ) فلا تُفتَح اللوحةُ من تحته.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: seat,
    );
  }
}

/// زرٌّ دائريٌّ صغيرٌ تحت الصورة — مقاسُه من مقاس المقعد فيتناسب معه.
class _SeatButton extends StatelessWidget {
  final String tip;
  final IconData icon;
  final Color bg;
  final double size;
  final VoidCallback onTap;

  const _SeatButton({
    required this.tip,
    required this.icon,
    required this.bg,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final d = size * 0.46;
    return Tooltip(
      message: tip,
      child: Clickable(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: t.bg.withValues(alpha: 0.55), width: 1),
              boxShadow: [
                BoxShadow(
                    color: t.shadow, blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, size: d * 0.58, color: t.onAccent),
          ),
        ),
      ),
    );
  }
}
