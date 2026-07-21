import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';

/// **شارةُ لقبٍ أسبوعيّ** بجانب اسم اللاعب — الرمزُ وحدَه في الأماكن الضيّقة،
/// والرمزُ والنصُّ حيث يتّسع.
///
/// **لقبٌ واحدٌ لا ثلاثة** (قرارُ المالك): من فاز بفئتين تُعرَض شارةُ الأعلى رتبةً
/// على الطاولة واللوبي، وألقابُه كلُّها في ملفّه. ثلاثُ شاراتٍ بجانب اسمٍ على
/// بطاقةٍ قطرُها 54 تزاحم الاسمَ والرتبةَ وشارةَ VIP فلا يُقرأ شيء.
///
/// **لا شارةَ بلا لقب**: `null` ⇒ لا مساحةَ تُحجَز ولا نقطةَ تظهر — وهو حالُ كلّ
/// اللاعبين إلّا خمسةً في الأسبوع، وهذا بالضبط ما يجعلها تُغري.
class HonorBadge extends StatelessWidget {
  /// تعريفُ الفئة كما بثّه الخادم (منه الرمزُ والنصّ). null ⇒ لا شيء يُرسَم.
  final HonorCategoryBoard? category;

  /// حجمُ الرمز. الشارةُ كلُّها تُشتقّ منه.
  final double size;

  /// يُظهر نصَّ اللقب بجانب رمزه (الملفّ · لوحة الشرف). الطاولةُ رمزٌ وحدَه.
  final bool showText;

  const HonorBadge({
    super.key,
    required this.category,
    this.size = 13,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = category;
    if (c == null || c.emoji.isEmpty) return const SizedBox.shrink();
    final t = BeloteTheme.of(context);
    return Tooltip(
      message: c.title,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: size * (showText ? 0.5 : 0.28), vertical: size * 0.2),
        decoration: BoxDecoration(
          // ذهبٌ من الثيم لا رقمَ لون ⇒ الشارةُ تعيش في الثيمات الخمس.
          gradient: LinearGradient(
            colors: [t.accent, t.accentBright],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
                color: t.accent.withValues(alpha: 0.45), blurRadius: size * 0.5),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.emoji, style: TextStyle(fontSize: size)),
            if (showText) ...[
              SizedBox(width: size * 0.3),
              Text(
                c.titleText,
                style: TextStyle(
                  color: t.onAccent,
                  fontSize: size * 0.82,
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

/// **شارةُ لاعبٍ بمعرّفه** — تصل بنفسها إلى خريطة الألقاب في الجلسة.
///
/// بها تصير الشارةُ سطرًا واحدًا في كلّ شاشة (الصدارة · الأصدقاء · الملفّ) بدل
/// تمرير اللقب عبر كلّ نموذجٍ وكلّ حمولة. **وبلا جلسةٍ لا تنهار**: الشاشاتُ
/// تُختبَر وحدَها، وزينةٌ تُسقط شاشةً خطأٌ أفدحُ من زينةٍ لا تظهر.
class PlayerHonorBadge extends StatelessWidget {
  final String playerId;
  final double size;
  final bool showText;

  const PlayerHonorBadge({
    super.key,
    required this.playerId,
    this.size = 12,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    if (playerId.isEmpty) return const SizedBox.shrink();
    final honors = SessionScope.maybeOf(context)?.honors;
    if (honors == null) return const SizedBox.shrink();
    return HonorBadge(
      category: honors.categoryById(honors.topTitleOf(playerId)),
      size: size,
      showText: showText,
    );
  }
}

/// **كلُّ ألقاب لاعبٍ** — للملفّ وحدَه (قرارُ المالك: واحدٌ على الطاولة، والكلُّ
/// في الملفّ). لا لقبَ ⇒ لا صفَّ ولا فراغ.
class AllHonorBadges extends StatelessWidget {
  final String playerId;
  const AllHonorBadges({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    if (playerId.isEmpty) return const SizedBox.shrink();
    final honors = SessionScope.maybeOf(context)?.honors;
    final ids = honors?.titles[playerId] ?? const <String>[];
    if (honors == null || ids.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final id in ids)
          HonorBadge(
              category: honors.categoryById(id), size: 13, showText: true),
      ],
    );
  }
}
