import 'package:flutter/material.dart';

import '../net/player_rank.dart';
import '../theme/belote_theme.dart';

/// **شارةُ رتبةِ المهارة** — «🏅 محترف» بجانب الاسم.
///
/// **رتبةٌ لا رقم**: «1287» لا يقول شيئًا لأحد. الرقمُ يبقى في الملفّ لمن يريده،
/// وعلى الطاولة اسمٌ يُفهَم في لمحة.
///
/// **لا شارةَ لغير المرشَّح** ولا لِخادمٍ أقدمَ من الميزة (`null`): مساحةٌ محجوزةٌ
/// لشيءٍ لا يُعرَض تفسد الصفَّ، و«غير مصنَّف» على الطاولة ضجيجٌ لا خبر — مكانُه
/// الملفُّ حيث يُقرأ معه ما بقي من مبارياتِ الترشيح.
class RankBadge extends StatelessWidget {
  final PlayerRankView? rank;

  /// حجمُ الخطّ الأساس. الشارةُ كلُّها تُشتقّ منه.
  final double size;

  /// يُظهر اسمَ الرتبة بجانب رمزها. الأماكنُ الضيّقة (بطاقةُ الطاولة) رمزٌ وحدَه.
  final bool showText;

  /// يعرض «غير مصنَّف» بدل الاختفاء — للملفّ الشخصيّ وحدَه، حيث الخبرُ مفيد.
  final bool showUnplaced;

  const RankBadge({
    super.key,
    required this.rank,
    this.size = 12,
    this.showText = true,
    this.showUnplaced = false,
  });

  /// لونا الشارة لكلّ رتبة — **تدرّجٌ يصعد مع السُّلَّم**: أخضرُ نامٍ للمبتدئ حتى
  /// ذهبِ الأسطورة. مفتاحٌ مجهولٌ (خادمٌ أحدث برتبةٍ جديدة) يأخذ لونَ الثيم المحايد
  /// فيُعرَض بلا تشويه.
  (Color, Color)? _colors(BeloteTheme t) => switch (rank?.tier) {
        'beginner' => (const Color(0xFF3E8E5A), const Color(0xFF6FBF8B)),
        'player' => (const Color(0xFF3A6EA5), const Color(0xFF6FA8DC)),
        'skilled' => (const Color(0xFF6A4FA3), const Color(0xFF9B7FD4)),
        'pro' => (const Color(0xFFA8792B), const Color(0xFFD9AE5A)),
        'elite' => (const Color(0xFF1F8A93), const Color(0xFF4FD1C5)),
        'legend' => (t.accent, t.accentBright),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final r = rank;
    if (r == null) return const SizedBox.shrink();
    if (!r.placed && !showUnplaced) return const SizedBox.shrink();
    final t = BeloteTheme.of(context);
    final c = _colors(t);

    // غيرُ المرشَّح لا لونَ رتبةٍ له — إطارٌ باهتٌ يقول «بعدُ» لا «أنت هنا».
    final decoration = r.placed && c != null
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [c.$1, c.$2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: c.$1.withValues(alpha: 0.35), blurRadius: size * 0.5),
            ],
          )
        : BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white24),
          );

    return Tooltip(
      message: r.placed
          ? (r.nextTitle.isEmpty
              ? r.title
              : '${r.title} · التالية: ${r.nextTitle}')
          : 'تبقّت ${r.remaining} مباراةً مصنَّفةً للتصنيف',
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: size * (showText ? 0.55 : 0.32), vertical: size * 0.22),
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (r.emoji.isNotEmpty) Text(r.emoji, style: TextStyle(fontSize: size)),
            if (showText) ...[
              if (r.emoji.isNotEmpty) SizedBox(width: size * 0.3),
              Text(
                r.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.92,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// **شريطُ تقدّمٍ نحو الرتبة التالية** — للملفّ الشخصيّ.
///
/// يُجيب سؤالًا واحدًا: *كم بقي؟* بلا شرحِ معادلةِ ELO لأحد.
class RankProgress extends StatelessWidget {
  final PlayerRankView rank;

  /// التصنيفُ الحاليّ — يُعرَض رقمًا لاتينيًّا صغيرًا تحت الشريط.
  final int rating;

  const RankProgress({super.key, required this.rank, required this.rating});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final next = rank.nextAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            RankBadge(rank: rank, size: 13, showUnplaced: true),
            const Spacer(),
            Text('التصنيف ', style: TextStyle(color: t.text2, fontSize: 12)),
            Text('$rating',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    color: t.text, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: rank.progress.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(t.accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          !rank.placed
              ? 'تبقّت ${rank.remaining} مباراةً مصنَّفةً لتحصل على رتبتك'
              : next == null
                  ? 'بلغتَ أعلى السُّلَّم — الأسطورةُ تُدافع لا تصعد'
                  : 'إلى ${rank.nextTitle}: ${next - rating} نقطة تصنيف',
          textDirection: TextDirection.rtl,
          style: TextStyle(color: t.text2, fontSize: 12),
        ),
      ],
    );
  }
}
