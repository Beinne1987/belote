import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// **ما تقدر عليه هذه المنصّة** — سؤالٌ عن *القدرة* لا عن اسم النظام.
///
/// الحزمةُ واحدةٌ للهاتف والحاسوب ([[desktop-support]])، وبعضُ الإضافات لا وجودَ
/// لها على ويندوز وماك (الدفعُ عبر FCM · مثبِّتُ APK · إذنُ الميكروفون). نداءُ
/// إضافةٍ غيرِ مسجَّلةٍ يرمي `MissingPluginException` **وقتَ التشغيل لا الترجمة**
/// ⇒ عطبٌ لا يظهر إلّا في يد اللاعب.
///
/// **لماذا صنفٌ واحدٌ لا `Platform.isX` منثورٌ في الشاشات:** الشرطُ المنثور يُنسى
/// عند إضافة نداءٍ جديد، ولا يُختبَر. هنا موضعٌ واحدٌ يُقرأ ويُراجَع.
class AppPlatform {
  AppPlatform._();

  /// حاسوبٌ مكتبيّ — **ويندوز أو ماك وحدَهما** (قرارُ المشروع: لا لينكس).
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS);

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// إشعاراتُ الدفع (FCM): للهاتف وحدَه. على الحاسوب يبقى **صندوقُ الإشعارات
  /// داخل التطبيق** يعمل كما هو — الجرسُ يجلب من الخادم بلا توكن.
  static bool get push => isMobile;

  /// تحديثٌ ذاتيٌّ بتنزيل APK وتثبيته: أندرويد وحدَه.
  static bool get inAppUpdate => !kIsWeb && Platform.isAndroid;

  /// المحادثةُ الصوتيّة: تحتاج إذنَ ميكروفونٍ من `permission_handler` — ولا
  /// تنفيذَ له على سطح المكتب. تُخفى أزرارُها بدل أن تُضغَط فترمي.
  static bool get voice => isMobile;

  /// **Firebase**: للهاتف وحدَه. حزمةُ الحاسوب لا تحوي ملفَّ الإعداد
  /// (`GoogleService-Info.plist`) — يقولها سجلُّ النظام على ماك صراحةً — فتهيئتُه
  /// هناك فشلٌ مضمون. ولا يُبنى عليه على الحاسوب شيء: الدفعُ ([push]) مُطفأ،
  /// والدخولُ بكلمة السرّ يمرّ بخادمنا لا بـFirebase.
  static bool get firebase => isMobile;
}
