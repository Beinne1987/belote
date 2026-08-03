import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';
import 'suit_pip.dart';

/// **شكلُ الضمانة الواحد أينما ظهرت** — في شريط اختيارك، وفي الفقاعة أمام من
/// نطق بها (طلبُ المالك 2026-07-23).
///
/// وحدةٌ واحدةٌ للشكل: ما تضغطه هو ما يراه الآخرون. لو تفرّق الرسمُ على مكانين
/// لانفصلا عند أوّل تعديل — والفقاعةُ التي تكتب «كير» بينما الزرُّ يرسم قلبًا
/// تبدو لعبتين لا لعبة.

/// ضمانةُ لونٍ: زرٌّ داكنٌ فيه **قرصٌ فاتحٌ خلف الرمز وحدَه** (البديل «ب»).
///
/// الرمزُ بحبر الورق الحقيقيّ — الكيرُ والكارو أحمران، والبيكُ والأتريفُ
/// أسودان. ولأنّ الأسودَ الخالصَ يكاد يختفي على اللبّاد الأخضر الداكن، يقوم
/// القرصُ الفاتحُ خلفه مقامَ وجه الورقة: بقعةٌ تحت الرمز لا بطاقةٌ بيضاءُ
/// كاملة. وحدُّ الزرّ يحمل لونَ الحبر فيُقرأ اللونُ قبل أن يُقرأ الشكل.
class SuitBidChip extends StatelessWidget {
  final String suit;

  /// ضلعُ المربّع. الافتراضيُّ [side] في الشريط؛ الفقاعةُ أصغرُ قليلًا.
  final double side;

  /// حبرٌ بديلٌ للرمز (الضمانةُ المعطّلة ترمدّ) — وإلّا حبرُ الورق.
  final Color? ink;

  const SuitBidChip({
    super.key,
    required this.suit,
    this.side = 46,
    this.ink,
  });

  /// نسبتا المعاينة نفسُهما: قرصٌ 34 ورمزٌ 22 من ضلعٍ 46.
  static const double discRatio = 0.74, pipRatio = 0.48;

  /// أحمرُ الحدّ **مرفوعٌ قليلًا** عن حبر الورق: `C8102E` على الأخضر الداكن
  /// يغمق فيضيع الحدّ. الحبرُ نفسُه لا يتغيّر.
  static const Color borderRed = Color(0xFFE01B36);

  /// وجهُ القرص — عاجيٌّ مائلٌ إلى الخضرة قليلًا كي لا يقطع اللبّادَ ببياضٍ فجّ.
  static const Color disc = Color(0xFFF0F4EE);

  /// عتمةُ الزرّ: **يحملها بنفسه** — لا لوحةَ تجمع الأزرار.
  static const Color backdrop = Color(0x6B000000);

  static BorderRadius radiusFor(double side) =>
      BorderRadius.circular(side * 0.28);

  @override
  Widget build(BuildContext context) {
    final isRed = SuitPip.redSuits.contains(suit);
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backdrop,
        borderRadius: radiusFor(side),
        border: Border.all(
          color: isRed
              ? borderRed.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Container(
        width: side * discRatio,
        height: side * discRatio,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: disc),
        child: SuitPip(
          suit: suit,
          size: side * pipRatio,
          color: ink ?? SuitPip.cardInk(suit),
        ),
      ),
    );
  }
}

/// ما لا رمزَ له: تمرير · صن · تو · أكوينس — **قرصٌ ممتلئٌ بنصّه**.
///
/// ثلاثُ درجاتٍ تقول وزنَ القرار بلا كلمة: التمريرُ داكنٌ هادئ، وصنٌّ وتوٌّ
/// ذهبيّتان محدودتان، والأكوينسُ **مصمتٌ ذهبيّ** لأنّه يقطع الضمانة فورًا.
enum BidPillTone { pass, high, akwins, disabled }

class BidPill extends StatelessWidget {
  final String label;
  final BidPillTone tone;

  /// في الشريط يملأ الزرُّ نصيبَه من الصفّ؛ في الفقاعة يلتصق بنصّه.
  final bool shrinkWrap;

  /// ارتفاعُ الزرّ. يكبر مع الطاولة في الشريط ([TableMetrics.bidPillHeight])،
  /// ويبقى [height] في الفقاعة — تلك خبرٌ يُقرأ لا هدفٌ يُضغَط.
  final double? boxHeight;

  const BidPill({
    super.key,
    required this.label,
    required this.tone,
    this.shrinkWrap = false,
    this.boxHeight,
  });

  /// ارتفاعُ الهاتف — وأرضيّةُ كلّ ما فوقه.
  static const double height = 38;

  /// حجمُ الخطّ نسبةً إلى الارتفاع: نمَتِ العلبةُ فنما نصُّها معها، وإلّا صارت
  /// كلمةٌ صغيرةٌ في زرٍّ كبيرٍ تقرأ زرًّا مُمطَّطًا لا زرًّا أكبر.
  static const double _fontRatio = 14.5 / height;

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final Color bg, fg, border;
    switch (tone) {
      case BidPillTone.disabled:
        bg = const Color(0x4D000000); // أسود 30% — يُرى ولا يدعو
        fg = t.text3;
        border = t.text3;
      case BidPillTone.akwins:
        bg = t.accent;
        fg = t.onAccent;
        border = t.accent;
      case BidPillTone.pass:
        bg = Color.alphaBlend(
            Colors.white.withValues(alpha: 0.08), SuitBidChip.backdrop);
        fg = t.feltInk2;
        border = t.feltInk2.withValues(alpha: 0.55);
      case BidPillTone.high:
        bg = Color.alphaBlend(
            t.accent.withValues(alpha: 0.22), SuitBidChip.backdrop);
        fg = t.accentBright;
        border = t.accent;
    }

    // النصُّ **يضمر ولا ينكسر**: كلمةٌ طويلةٌ («أكوينس») على هاتفٍ ضيّقٍ تصغر
    // قليلًا بدل أن تنزل سطرًا فينكسر الصفُّ الواحد.
    final box = boxHeight ?? height;
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: TextStyle(
            color: fg, fontSize: box * _fontRatio, fontWeight: FontWeight.w700),
      ),
    );

    return SizedBox(
      height: box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(box * 0.58),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: box * (12 / height)),
          child: Center(widthFactor: shrinkWrap ? 1 : null, child: text),
        ),
      ),
    );
  }
}
