import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../theme/belote_theme.dart';

/// **شاشةُ الإقلاع** — ما يراه اللاعبُ بين ظهور النافذة وجاهزيّة التطبيق.
///
/// كان المكانُ خلفيّةً خضراءَ فارغةً (`SizedBox.shrink` فوق `t.bg`): على الهاتف
/// تمرّ في لمحةٍ فلا تُلاحَظ، وعلى الحاسوب — حيث النافذةُ تُفتَح أوّلًا ثمّ
/// يُهيَّأ ما تحتها ([AppBoot]) — تبقى ثوانيَ تقرأ **تطبيقًا معلَّقًا**، لا
/// تطبيقًا يعمل. ولا شيءَ يقول للاعب إنّ شيئًا يجري.
///
/// هنا شعارُ اللعبة واسمُها ومؤشّرٌ يدور: الانتظارُ نفسُه، لكنّه **مفهوم**.
///
/// **الشعارُ أصلٌ محزومٌ أصلًا** (`assets/icon/icon.png` — تعرضه «حول اللعبة»)
/// ⇒ بلا زيادةِ بايتٍ في الحزمة. وفشلُ تحميله يُبتلَع إلى حرفٍ ذهبيّ: شاشةُ
/// إقلاعٍ تنهار أسوأُ من شاشةٍ خضراء.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// ضلعُ الشعار. كبيرٌ بما يُرى من بُعدِ شاشةِ حاسوب، دون أن يبتلع نافذةَ هاتف.
  static const double logoSide = 132;

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.gradTop, t.gradBottom],
          ),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            // **ظهورٌ متدرّجٌ لا وميض**: الشاشةُ قد تمرّ في 200ms على الهاتف،
            // فبلا التدرّج تُرى ومضةً بيضاءَ تقرأ عطبًا.
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOut,
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.scale(scale: 0.94 + 0.06 * v, child: child),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: logoSide,
                  height: logoSide,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(logoSide * 0.24),
                    boxShadow: [
                      BoxShadow(
                        color: t.accent.withValues(alpha: 0.28),
                        blurRadius: 34,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                          color: t.shadow,
                          blurRadius: 18,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(logoSide * 0.24),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: logoSide,
                      height: logoSide,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => ColoredBox(
                        color: t.surface,
                        child: Center(
                          child: Text(
                            context.l10n.appTitle.characters.first,
                            style: TextStyle(
                                color: t.accent,
                                fontSize: logoSide * 0.42,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.l10n.appTitle,
                  style: TextStyle(
                    color: t.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 132,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: t.line,
                      valueColor: AlwaysStoppedAnimation<Color>(t.accent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
