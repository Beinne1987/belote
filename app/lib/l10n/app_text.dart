import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_ar.dart';

export 'app_localizations.dart';

/// نصوصُ الواجهة **من خارج شجرة الودجات**.
///
/// أكثرُ النصوص تُقرأ بـ`AppLocalizations.of(context)` حيث يوجد `context`.
/// لكنّ بعضَ التسميات يبنيها الكنترولرُ لا الودجة (فقاعةُ الضمانة، أسماءُ
/// مقاعد الذكاء، رسائلُ الخطأ من الشبكة) — ولا `context` هناك. [AppText.s]
/// يعطيها نصوصَ **اللغة النشطة الآن**: الجذرُ يربطها عند كلّ بناءٍ في
/// `main.dart`، فتبديلُ اللغة يبدّلها معها.
///
/// الافتراضُ العربيّةُ قبل أوّل ربط (وفي اختبارات الوحدة بلا شجرة) — العربيّةُ
/// لغةُ التطبيق الأولى، فالسقوطُ إليها سقوطٌ إلى نصٍّ صحيحٍ لا إلى فراغ.
class AppText {
  const AppText._();

  static AppLocalizations _current = AppLocalizationsAr();

  static AppLocalizations get s => _current;

  /// يربط نصوصَ اللغة النشطة. يُستدعى من جذر التطبيق وحدَه.
  static void bind(AppLocalizations value) => _current = value;
}

/// نصوصُ الواجهة من الشجرة: `context.l10n.bidPass`.
///
/// **لا تسقط الشاشةُ إن غاب المندوب**: `AppLocalizations.of` يرمي حين تُبنى
/// ودجةٌ خارج `MaterialApp` المترجَم (اختبارُ وحدةٍ يضخّ ودجةً وحدَها، أو نافذةٌ
/// تُبنى في جذرٍ عارٍ). هنا نسقط إلى نصوص اللغة النشطة [AppText.s] — نصٌّ صحيحٌ
/// خيرٌ من شاشةٍ حمراء، والتطبيقُ نفسُه يحمل المندوبَ دائمًا.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? AppText.s;
}
