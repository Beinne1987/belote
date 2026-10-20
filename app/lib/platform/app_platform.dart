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
  ///
  /// **ماك: نسخةُ المتجر وحدَها** ([isMacStore]) — الإشعاراتُ تحتاج توقيعًا بملفّ
  /// تعريفٍ من Apple وصلاحيّاتٍ مقيَّدةً ([Store.entitlements])، وحزمةُ الـDMG المباشرة
  /// موقَّعةٌ ad-hoc فلا تستطيعها ولا يجوز أن تحاول (تهيئةُ Firebase هناك بلا صلاحيّاتها
  /// فشلٌ مضمون). ويندوز: لا.
  static bool get push => isMobile || isMacStore;

  /// **نسخةُ المتجر** (`--dart-define=DISTRIBUTION=store`): App Store · Play · Mac App
  /// Store. الـ APK المباشر والـ DMG بلا العلم = `direct`. **المتاجرُ تُحدّث نفسَها**
  /// ومَنعُ Google Play التحديثَ الذاتيَّ صريح.
  static const bool isStore =
      String.fromEnvironment('DISTRIBUTION', defaultValue: 'direct') == 'store';

  /// تحديثٌ ذاتيٌّ بتنزيل APK وتثبيته: أندرويد **المباشر** وحدَه — لا نسخةَ المتجر.
  static bool get inAppUpdate => !kIsWeb && Platform.isAndroid && !isStore;

  /// المحادثةُ الصوتيّة: تحتاج إذنَ ميكروفونٍ من `permission_handler` — ولا
  /// تنفيذَ له على سطح المكتب. تُخفى أزرارُها بدل أن تُضغَط فترمي.
  static bool get voice => isMobile;

  /// **Firebase**: للهاتف، ولماك من المتجر ([isMacStore]). حزمةُ الـDMG المباشرة لا تحوي الصلاحيّات
  /// (`GoogleService-Info.plist`) — يقولها سجلُّ النظام على ماك صراحةً — فتهيئتُه
  /// هناك فشلٌ مضمون. ولا يُبنى عليه على الحاسوب شيء: الدفعُ ([push]) مُطفأ،
  /// والدخولُ بكلمة السرّ يمرّ بخادمنا لا بـFirebase.
  static bool get firebase => isMobile || isMacStore;

  /// ماك **من المتجر** (Mac App Store): موقَّعٌ كاملًا بصلاحيّاتِ الإشعارات.
  static bool get isMacStore => !kIsWeb && Platform.isMacOS && isStore;

  /// **متاجرُ Apple** (iOS دائمًا — لا توزيعَ مباشرَ له — وماك من المتجر): الدفعُ الرقميّ
  /// عبر App Store وحده (إرشاد 3.1.1)؛ بنكيلي لا يُعرَض فيها إطلاقًا (قرار المالك
  /// 2026-10-02 بعد رفض Hisabi). أندرويد/ويندوز/DMG المباشر يبقى بنكيلي كما هو.
  /// اسمُ المنصّة كما يُرسَل للخادم: ios · android · macos · windows · linux · web.
  static String get name {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return 'linux';
  }

  static bool get appleStore => !kIsWeb && (Platform.isIOS || isMacStore);
}
