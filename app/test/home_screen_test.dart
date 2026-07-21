import 'package:app/app_settings.dart';
import 'package:app/net/api_client.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// الشاشة الرئيسيّة — مداخلُها.
///
/// **قرار المالك (2026-07-15):** «زرّ ملفّي يفتح حساب اللاعب، وأنا أعتبره زرًّا زائدًا
/// يجب حذفه لأنّ ملف اللاعب يفتح بالضغط على الحساب وهذا يكفي.» ⇒ **مدخلٌ واحدٌ
/// للملفّ: بطاقةُ الحساب.** هذه الاختبارات تحرس القرار من عودةٍ سهوًا.
Widget _wrap(Widget child) {
  return ThemeScope(
    manager: ThemeManager(),
    child: AppSettingsScope(
      settings: AppSettings(),
      child: SessionScope(
        controller: SessionController(api: ApiClient()),
        child: MaterialApp(home: child),
      ),
    ),
  );
}

void main() {
  testWidgets('**لا زرّ «ملفّي» في الشبكة** — البطاقة تكفي', (t) async {
    await t.pumpWidget(_wrap(HomeScreen(onPlay: () {}, onProfile: () {})));
    await t.pumpAndSettle();
    expect(find.text('ملفّي'), findsNothing);
    expect(find.text('إحصائياتك وإنجازاتك'), findsNothing,
        reason: 'عنوانُ الزرّ المحذوف الفرعيّ');
  });

  testWidgets('بطاقة الحساب تفتح الملفّ — المدخل الوحيد يعمل', (t) async {
    var opened = 0;
    await t.pumpWidget(_wrap(HomeScreen(onPlay: () {}, onProfile: () => opened++)));
    await t.pumpAndSettle();

    // بلا جلسةٍ تُعرَض البطاقة بنصّها الافتراضيّ؛ الضغط عليها يفتح الملفّ.
    await t.tap(find.byType(InkWell).first);
    await t.pumpAndSettle();
    expect(opened, 1, reason: 'حذفُ الزرّ لا يجوز أن يقطع الطريق الوحيد الباقي');
  });

  testWidgets('بقيّة المداخل باقية (لم يُحذف غير الزائد)', (t) async {
    await t.pumpWidget(_wrap(HomeScreen(onPlay: () {}, onProfile: () {})));
    await t.pumpAndSettle();
    // بطاقاتُ اللعب في القائمة، والوجهاتُ الأربع في الشريط السفليّ — **مرّةً واحدة
    // لكلٍّ**: مدخلان لشيءٍ واحدٍ هو ما نحرس منه.
    for (final title in [
      'لعب سريع',
      'اللعب أونلاين',
      'التصنيف',
      'المتجر',
      'الأصدقاء',
      'حول اللعبة',
    ]) {
      expect(find.text(title), findsOneWidget, reason: '$title مدخلٌ مستقلٌّ لا زائد');
    }
  });

  // **الشريطُ السفليّ يوصِّل فعلًا**: زرٌّ لا يفتح شيئًا أسوأُ من غيابه.
  testWidgets('الشريط السفليّ: كلُّ وجهةٍ تفتح شاشتها', (t) async {
    var rank = 0, store = 0, friends = 0, about = 0;
    await t.pumpWidget(_wrap(HomeScreen(
      onPlay: () {},
      onLeaderboard: () => rank++,
      onStore: () => store++,
      onFriends: () => friends++,
      onAbout: () => about++,
    )));
    await t.pumpAndSettle();
    for (final label in ['التصنيف', 'المتجر', 'الأصدقاء', 'حول اللعبة']) {
      await t.tap(find.text(label));
      await t.pumpAndSettle();
    }
    expect([rank, store, friends, about], [1, 1, 1, 1]);
  });

  // **اسمُ الزرّ اسمُ ما يفتحه.** كان «مع الأصدقاء · طاولة خاصّة بدعوة» وهو يفتح
  // قائمة الأصدقاء لا طاولة (بلاغ المالك) — والطاولةُ الخاصّة من «اللعب أونلاين».
  testWidgets('زرّ الأصدقاء يسمّي ما يفتحه — لا يَعِد بطاولةٍ خاصّة', (t) async {
    await t.pumpWidget(_wrap(HomeScreen(onPlay: () {}, onFriends: () {})));
    await t.pumpAndSettle();

    // يطابق عنوان الشاشة التي يفتحها (`SimpleTopBar(title: 'الأصدقاء')`).
    expect(find.text('الأصدقاء'), findsOneWidget);
    expect(find.text('مع الأصدقاء'), findsNothing);
    expect(find.text('طاولة خاصّة بدعوة'), findsNothing,
        reason: 'وعدٌ كاذب: الطاولة الخاصّة تُنشَأ من «اللعب أونلاين»');
  });
}
