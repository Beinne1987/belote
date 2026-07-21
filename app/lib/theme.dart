import 'package:flutter/material.dart';

/// ألوان الواجهة وأنسجتها — **المصدر الوحيد** للّون.
///
/// لا تُكتب قيمة لون (Color(0x…)) مباشرةً في أي ملف آخر؛ خذها من هنا.
/// الخط الافتراضي مقبول الآن؛ حين نبنّد خطاً عربياً يُضبط في [buildTheme].
class Palette {
  const Palette._();

  // ── الطاولة: تدرّج إشعاعي من المركز الفاتح إلى الحافة الداكنة ──
  static const Color feltCenter = Color(0xFF14342B);
  static const Color feltEdge = Color(0xFF0C221C);

  /// تدرّج الطاولة الإشعاعي — يوضع في `BoxDecoration(gradient: Palette.feltGradient)`.
  static const RadialGradient feltGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.9,
    colors: [feltCenter, feltEdge],
  );

  // ── النتيجة: لون فريقنا (0,2) ولون الخصم (1,3) ──
  static const Color usTeam = Color(0xFFE8B923); // ذهبي — نحن
  static const Color themTeam = Color(0xFFB9C4C0); // فضّي باهت — هم

  // ── نصوص فوق النسيج ──
  static const Color inkOnFelt = Color(0xFFF7F3E8); // كريمي
  static const Color inkOnFeltDim = Color(0xFF8AA39A); // باهت للثانوي

  // ── الضمانة (bid_bar) ──
  static const Color bidEnabled = Color(0xFFF7F3E8);
  static const Color bidDisabled = Color(0xFF4A5B54); // معطّل: مرئي لكن خافت
  static const Color bidSelected = Color(0xFFE8B923);

  // ── الموزّع وفقاعات الضمانة ──
  /// شارة الموزّع («من عليه التقسيم») ونقطة انطلاق التوزيع.
  static const Color dealerBadge = Color(0xFFE8B923);

  /// فقاعة ما ضمنه كل لاعب أمامه أثناء الضمانة.
  static const Color bidBubbleBg = Color(0xFFE8B923);
  static const Color bidBubbleInk = Color(0xFF14342B);

  // ── الأوراق ──
  /// شفافية الورقة غير القانونية: مرئية لكن باهتة (لا مخفيّة).
  static const double illegalCardOpacity = 0.4;

  /// ظلّ خفيف أسفل كل ورقة على الطاولة.
  static const Color cardShadow = Color(0x55000000);
}

/// السمة العامة: خلفية داكنة، Material 3، اتجاه سيُضبط RTL في التطبيق.
/// الخط `null` = خط النظام مؤقتاً.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.feltCenter,
    brightness: Brightness.dark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.feltEdge,
    fontFamily: null,
  );
}
