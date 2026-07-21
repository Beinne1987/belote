import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';

/// أدواتُ الطاولة الجانبيّة: **الرسائلُ وحدَها**، ظاهرةً بلا قائمةٍ تُفتَح.
///
/// **لماذا ذهبت القائمة:** الهديّةُ صارت زرًّا تحت كلّ صورة (لكلّ لاعبٍ هديّتُه،
/// ولي «للجميع»)، والخروجُ انتقل إلى أعلى اليسار تحت لوح النتيجة. فلم يبقَ
/// للقائمة ما تُخفيه — وزرٌّ يفتح زرَّين عبثٌ.
///
/// **ولماذا ذهب زرُّ الصوت** (2026-07-20، ملاحظةُ المالك): صار للصوت مكانان
/// أوضحُ منه — الميكروفونُ تحت صورتي يصل ويقطع، والكتمُ على بطاقة من يزعجني.
/// فزرٌّ ثالثٌ لنفس الأمر يُربك؛ ولوحةُ الصوت حُذفت معه.
///
/// **أداةٌ بلا مُعالِجٍ تُخفى** (الأوفلاين: لا رسائل)، أمّا أداةٌ لها مُعالِجٌ
/// وتعذّر استعمالُها الآن فتبقى ظاهرةً وتشرح نفسها. [[gift-button-visibility]]
class TableControls extends StatelessWidget {
  /// يفتح لوحةَ الرسائل. null ⇒ يُخفى زرّها (الأوفلاين: لا أحد يقرؤها).
  final VoidCallback? onOpenChat;

  const TableControls({super.key, this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onOpenChat != null)
          TableToolButton(
            icon: Icons.chat_bubble_outline,
            tip: 'الرسائل',
            onTap: onOpenChat!,
          ),
      ],
    );
  }
}

/// زرُّ أداةٍ دائريٌّ على الطاولة — يشاركه الجانبُ والخروجُ أعلى اليسار، فلا
/// يختلف زرّان في المظهر لاختلاف مكانِهما.
class TableToolButton extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  final bool danger;

  const TableToolButton({
    super.key,
    required this.icon,
    required this.tip,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Tooltip(
      message: tip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        shape: CircleBorder(
          side: BorderSide(color: danger ? t.error : Colors.white24, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 20, color: danger ? t.error : t.feltInk),
          ),
        ),
      ),
    );
  }
}
