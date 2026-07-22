import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'platform/app_platform.dart';
import 'sfx.dart';
import 'ui/card_face.dart';

/// **إقلاعُ التطبيق: ما يُنتظَر وما لا يُنتظَر.**
///
/// الدرسُ الذي وُلد منه هذا الملفّ (2026-07-22، ماك المالك): كان `main()` ينتظر
/// ثلاثَ تهيئاتٍ **قبل** `runApp` — Firebase ورسومَ الأوراق والصوت. وفلاتر
/// الحديث يدمج خيطَ الواجهة مع الخيط الرئيس (يطبع `Running with merged UI and
/// platform thread`)، فأيُّ إضافةٍ تتعثّر في ندائها الأصليّ **تجمّد الخيطَ
/// الرئيس قبل أن تُنشأ النافذة** ⇒ تطبيقٌ حيٌّ في الذاكرة، بلا نافذةٍ ولا
/// رسالةٍ ولا تقريرِ تعطّل. لا يظهر ذلك على مشغّل البناء لأنّ «العمليّة حيّة»
/// هو بالضبط ما يبدو عليه التطبيقُ المعلَّق.
///
/// **القاعدةُ الحاكمة هنا:** لا يعبر طريقَ الإقلاع إلّا ما هو **Dart خالصٌ بلا
/// إضافة أصليّة**. كلُّ ما يمسّ إضافةً يُطلَق بعد `runApp`، بمهلةٍ وحارسِ خطأ،
/// ولا ينتظره أحد. تعثُّرُ إضافةٍ يجب أن يبقى تعثّرًا في ميزتها وحدَها.
class AppBoot {
  AppBoot._();

  /// نسخةٌ واحدة — الإقلاع يقع مرّةً في عمر العمليّة.
  static final AppBoot instance = AppBoot._();

  /// مهلةُ كلّ تهيئةٍ أصليّة. بعدها نمضي ونسجّل بدل أن ننتظر إلى الأبد.
  static const Duration nativeTimeout = Duration(seconds: 8);

  Future<void>? _art;

  /// **رسومُ الأوراق** — تحليلُ SVG في الذاكرة: Dart خالصٌ بلا قناةٍ أصليّة، فلا
  /// يمكن أن يعلّق على منصّة. هذه وحدَها يُنتظَر تمامُها قبل عرض المحتوى، حتى
  /// لا تُرسَم ورقةٌ بلا وجه. تُطلَق مرّةً ويُعاد الوعدُ نفسُه بعدها.
  Future<void> artReady() => _art ??= preloadCardArt();

  /// يُطلق التهيئاتِ الأصليّة **بعد** `runApp`. لا `await` له في `main`.
  void startNative() {
    unawaited(guarded('Firebase', _initFirebase));
    unawaited(guarded('الصوت', Sfx.instance.init));
  }

  /// مصادقةُ الهاتف (Phone Auth) — **للهاتف وحدَه**: حزمةُ الحاسوب لا تحوي
  /// `GoogleService-Info.plist` أصلًا (يقولها سجلُّ النظام صراحةً)، فالتهيئةُ
  /// تفشل حتمًا هناك. فلا نمرّ على الإضافة الأصليّة من الأساس.
  Future<void> _initFirebase() async {
    if (!AppPlatform.firebase) return;
    await Firebase.initializeApp();
  }

  /// يبتلع الفشلَ **والتعليقَ** معًا: الأوّل استثناءٌ يُسجَّل، والثاني مهلةٌ
  /// تنتهي. أيًّا كان، التطبيقُ يواصل والميزةُ وحدَها تُعطَّل.
  @visibleForTesting
  static Future<void> guarded(String name, Future<void> Function() body) async {
    try {
      await body().timeout(nativeTimeout);
    } on TimeoutException {
      debugPrint('تهيئة «$name» تجاوزت ${nativeTimeout.inSeconds}ث — مضينا بدونها');
    } catch (e) {
      debugPrint('تعذّرت تهيئة «$name»: $e');
    }
  }
}

/// **علامةُ «الواجهةُ ظهرت فعلًا»** — تُطبَع مرّةً عند أوّل إطارٍ للمحتوى.
///
/// وجودُها ليس زينةً: اختبارُ الإقلاع في مشغّل ماك كان يسأل «هل العمليّة حيّة
/// بعد عشر ثوانٍ؟»، والتطبيقُ المعلَّق بلا نافذةٍ **حيٌّ تمامًا** — فمرّ الاختبارُ
/// على حزمةٍ لا تفتح شيئًا. الآن يبحث المشغّل عن هذا السطر في مخرجات التطبيق:
/// لا يُطبَع إلّا وقد رُسم إطارٌ حقيقيّ.
const String uiReadyMarker = 'BELOTE_UI_READY';
