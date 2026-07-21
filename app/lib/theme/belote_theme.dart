import 'package:flutter/widgets.dart';

import 'theme_manager.dart';

/// **الرموز الدلالية للهوية البصرية** (Design System). صنفٌ immutable يحمل كل ألوان
/// الثيم؛ الشاشات تقرأ منه لا من قيمة صريحة. إضافة ثيم = نسخةٌ جديدة تملأ نفس الحقول
/// (انظر `themes.dart`). المقاييس (مسافات/حواف/حركة) ثابتة عبر الثيمات وتبقى في
/// `theme.dart`/`motion.dart`. تفاصيل: `docs/DESIGN-SYSTEM.md`.
@immutable
class BeloteTheme {
  final String name;
  final Brightness brightness;

  // الخلفية والأسطح
  final Color bg, gradTop, gradBottom, surface, surface2;
  // الطاولة
  final Color feltCenter, feltEdge, feltInk, feltInk2;
  // الذهبي والمميّز
  final Color accent, accentBright, accentDeep, onAccent, premium;
  // النصوص
  final Color text, text2, text3;
  // الحدود والحالات والظلّ
  final Color line, lineStrong, success, warning, error, shadow;

  const BeloteTheme({
    required this.name,
    required this.brightness,
    required this.bg,
    required this.gradTop,
    required this.gradBottom,
    required this.surface,
    required this.surface2,
    required this.feltCenter,
    required this.feltEdge,
    required this.feltInk,
    required this.feltInk2,
    required this.accent,
    required this.accentBright,
    required this.accentDeep,
    required this.onAccent,
    required this.premium,
    required this.text,
    required this.text2,
    required this.text3,
    required this.line,
    required this.lineStrong,
    required this.success,
    required this.warning,
    required this.error,
    required this.shadow,
  });

  /// الثيم النشط من الشجرة. يستلزم `ThemeScope` أعلى (يُغلَّف في `main`).
  static BeloteTheme of(BuildContext context) => ThemeScope.of(context).current;
}
