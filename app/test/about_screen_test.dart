import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// «حول اللعبة» — اسمُ من برمجها يُقرأ فيها. سقوطُ هذا السطر سهوًا لا يُلاحَظ
/// في الاستعمال، فيحرسه اختبار.
void main() {
  testWidgets('حول اللعبة: التعريف والمطوّر والإصدار', (t) async {
    await t.pumpWidget(ThemeScope(
      manager: ThemeManager(),
      child: const MaterialApp(home: AboutScreen()),
    ));
    await t.pump();

    expect(find.text('حول اللعبة'), findsOneWidget);
    expect(find.text('برمجة وتطوير'), findsOneWidget);
    expect(find.text('محمد الأمين / تقرة / بينة'), findsOneWidget);
    expect(find.text('إصدار التطبيق'), findsOneWidget);
  });
}
