import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/table_screen.dart' show DealingLayer;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// **حركةُ التوزيع لا ترمي `Opacity` خارجَ [0،1]** — عطبٌ وجده المالكُ في المحاكي:
/// شاشةٌ حمراءُ «`opacity >= 0.0 && opacity <= 1.0` is not true» لحظةَ وصول آخر ورقة.
///
/// السببُ خطأُ الفاصلة العائمة: `1 - (1.0 - 0.85) / 0.15` = `-2.2e-16` لا صفر. في الإنتاج
/// يبتلعه المحرّك، أمّا في نسخة التطوير فيُطلق شاشةَ الخطأ. يُختبَر بتشغيل الحركة **إلى
/// آخرها** — لا بحسابٍ منفصل — كي يُكشَف أيُّ `Opacity` آخرَ يخرج عن المجال.
void main() {
  for (final count in [5, 8, 32]) {
    testWidgets('التوزيع ($count ورقة) يكتمل بلا استثناء', (tester) async {
      await tester.pumpWidget(ThemeScope(
        manager: ThemeManager(),
        child: MaterialApp(
          home: Scaffold(
            body: DealingLayer(
              dealerSeat: 0,
              cardW: 40,
              count: count,
              duration: const Duration(milliseconds: 1000),
            ),
          ),
        ),
      ));
      // كلُّ إطارٍ على حدة (لا قفزةٌ واحدة) ثمّ الإطارُ الذي تصل فيه آخرُ ورقةٍ تمامًا.
      for (var i = 0; i < 70; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull, reason: 'الإطار $i');
      }
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }
}
