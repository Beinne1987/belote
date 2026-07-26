import 'dart:io';

import 'package:app/services/phone_auth.dart';
import 'package:app/services/push_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// **الشاشةُ البيضاء عند فتح التطبيق (4085، 2026-07-23).**
///
/// حين انتقلت تهيئةُ Firebase إلى ما بعد `runApp` (إصلاحُ نافذة ماك)، بقي
/// `FirebasePushTokens` يحلّ `FirebaseMessaging.instance` في **مُهيّئ حقله**.
/// وذلك الحقلُ يُنشَأ مع حالة `BeloteApp` — أي قبل أن تكتمل التهيئة ⇒ يرمي
/// `[core/no-app]` **أثناء بناء الشجرة**، فتملأ الشاشةَ شاشةُ خطأ فلاتر (في
/// الإصدار: مستطيلٌ فاتحٌ بلا نصّ = «شاشة بيضاء» بلا أيّ رسالة).
///
/// هذه الاختباراتُ تشتري القاعدة: **لا `.instance` إلّا بعد البوّابة**.
void main() {
  group('لا Firebase في الباني', () {
    test('FirebasePushTokens يُنشَأ بلا تهيئةٍ ولا يرمي', () {
      expect(() => FirebasePushTokens(), returnsNormally);
    });

    test('PhoneAuthService يُنشَأ بلا تهيئةٍ ولا يرمي', () {
      expect(() => PhoneAuthService(), returnsNormally);
    });

    // بلا منصّةٍ حيّة تفشل التهيئةُ ويفشل `.instance` بعدها — والعقدُ أن يُترجَم
    // ذلك إلى «لا توكن» لا إلى رميةٍ تصعد إلى الواجهة.
    test('فشلُ Firebase ⇒ لا توكن ولا رمية', () async {
      final push = FirebasePushTokens(ready: () async {});
      expect(await push.requestToken(), isNull);
      expect(await push.initialTap(), isNull);
      await push.delete(); // لا يرمي
    });

    test('بثُّ التوكن المتجدّد ينتهي صامتًا بدل أن يرمي', () async {
      final push = FirebasePushTokens(ready: () async {});
      expect(await push.onRefresh.toList(), isEmpty);
      expect(await push.onTap.toList(), isEmpty);
    });
  });

  /// حارسٌ نصّيّ: الفخُّ يعود بسطرٍ واحدٍ في مُهيّئ حقل، ولا يكشفه اختبارُ ودجت
  /// (الاختباراتُ تحقن مزيّفًا فلا تمرّ على `.instance` أصلًا).
  test('لا `.instance` لـFirebase في مُهيّئ حقلٍ أو حقلٍ نهائيّ', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        if (!l.contains('FirebaseMessaging.instance') &&
            !l.contains('FirebaseAuth.instance')) {
          continue;
        }
        // مسموحٌ داخل جسم دالّة (سطرٌ يبدأ بـ`return` أو إسنادٍ محلّيّ) —
        // الممنوعُ مُهيّئُ الحقل: `: _x = …` أو `final … = …instance`.
        final t = l.trimLeft();
        final inInitializer = t.startsWith(':') ||
            t.startsWith(',') ||
            RegExp(r'^(final|late|static)\b.*=').hasMatch(t);
        if (inInitializer) offenders.add('${f.path}:${i + 1}: $t');
      }
    }
    expect(offenders, isEmpty,
        reason: 'حُلَّ مرجعُ Firebase قبل اكتمال التهيئة ⇒ شاشةٌ بيضاء عند الفتح');
  });
}
