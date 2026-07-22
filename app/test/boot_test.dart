import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/boot.dart';
import 'package:app/platform/app_platform.dart';
import 'package:app/ui/card_art.dart';

/// **حارسُ الإقلاع.** وُلد هذا الملفّ من عطلٍ حقيقيّ (2026-07-22): كان `main()`
/// ينتظر تهيئاتٍ أصليّةً قبل `runApp`، فعلّقت إحداها الخيطَ الرئيس على ماك
/// المالك ⇒ تطبيقٌ حيٌّ **بلا نافذة**، بلا استثناءٍ ولا تقريرِ تعطّل. ما يلي
/// يمنع عودةَ ذلك: كلُّ تهيئةٍ أصليّةٍ محروسةٌ بمهلة، وما يُنتظَر قبل المحتوى
/// Dart خالصٌ وحدَه.
void main() {
  group('AppBoot — ما يُنتظَر', () {
    testWidgets('رسومُ الأوراق تُحلَّل مرّةً واحدةً ويُعاد الوعدُ نفسُه',
        (tester) async {
      await tester.runAsync(() async {
        final first = AppBoot.instance.artReady();
        final second = AppBoot.instance.artReady();
        expect(identical(first, second), isTrue,
            reason: 'استدعاءان ⇒ تحليلٌ واحد، وإلّا تُعاد الـ32 ورقةً بلا داعٍ');
        await first;
      });
      expect(CardArt.has('F:AS') || CardArt.has('B:zellij'), isTrue,
          reason: 'بعد التمام يجب أن تكون الرسومُ في الذاكرة');
    });
  });

  group('AppBoot — ما لا يُنتظَر', () {
    test('تهيئةٌ لا تنتهي أبدًا ⇒ تمضي بعد المهلة ولا تعلّق', () {
      fakeAsync((async) {
        var done = false;
        // تهيئةٌ معلَّقةٌ إلى الأبد — تحاكي إضافةً أصليّةً تجمّد الخيطَ الرئيس.
        AppBoot.guarded('معلَّقة', () => Completer<void>().future)
            .then((_) => done = true);
        async.elapse(AppBoot.nativeTimeout - const Duration(seconds: 1));
        expect(done, isFalse, reason: 'قبل المهلة لا شيءَ يُحسَم');
        async.elapse(const Duration(seconds: 2));
        expect(done, isTrue,
            reason: 'بعد المهلة يمضي الإقلاع — التعليقُ لا يُعدي التطبيق');
      });
    });

    test('تهيئةٌ ترمي ⇒ تُبتلَع ولا تُسقط الإقلاع', () async {
      await expectLater(
        AppBoot.guarded('فاشلة', () => Future<void>.error(StateError('تعذّر'))),
        completes,
      );
    });
  });

  group('قدراتُ المنصّة', () {
    test('Firebase للهاتف وحدَه — حزمةُ الحاسوب بلا ملفّ إعداد', () {
      expect(AppPlatform.firebase, AppPlatform.isMobile);
    });
  });

  test('علامةُ ظهور الواجهة ثابتةٌ — يقرؤها مشغّلُ ماك', () {
    expect(uiReadyMarker, 'BELOTE_UI_READY');
  });
}
