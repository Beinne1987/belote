import 'package:app/net/api_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/welcome_gifts_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// **نافذةُ هدايا الترحيب** (طلب المالك 2026-07-15): تُعرَض مرّةً واحدةً عند التسجيل
/// وتُري اللاعبَ ما ناله.
///
/// الجوهرُ المفحوص: تعرض **ما منحه الخادمُ** لا قائمةً منسوخة، ولا تَعِد بما لم يقع.
void main() {
  Future<void> pump(WidgetTester tester, Map<String, int> gifts) async {
    await tester.pumpWidget(ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: Builder(
          builder: (ctx) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showWelcomeGifts(ctx, gifts: gifts),
              child: const Text('سجّل'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('سجّل'));
    await tester.pumpAndSettle();
  }

  testWidgets('تعرض ما منحه الخادم — بالعدد والاسم', (tester) async {
    await pump(tester, {'rose': 3, 'tea': 2, 'sweet': 1});

    expect(find.text('أهلًا بك'), findsOneWidget);
    expect(find.text('وردة'), findsOneWidget);
    expect(find.text('×3'), findsOneWidget);
    expect(find.text('أتاي'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.text('حلوى'), findsOneWidget);
    expect(find.text('×1'), findsOneWidget);
  });

  // **الجوهر**: الأعدادُ من الخادم لا من ثابتٍ منسوخ — لو نسخنا القائمةَ لوعدت
  // النافذةُ بثلاثٍ والمخزونُ فيه سبع.
  testWidgets('عددٌ مختلف ⇒ تعرضه كما هو', (tester) async {
    await pump(tester, {'rose': 7});
    expect(find.text('×7'), findsOneWidget);
    expect(find.text('×3'), findsNothing);
  });

  testWidgets('لا منحة ⇒ لا نافذة (لا نَعِد بما لم يقع)', (tester) async {
    await pump(tester, const {});
    expect(find.text('أهلًا بك'), findsNothing);
  });

  testWidgets('معرّفٌ لا نعرفه ⇒ يُتجاهَل لا يُعرَض خامًا', (tester) async {
    // خادمٌ أحدثُ من الحزمة يمنح هديّةً جديدة ⇒ عرضُ «ferrari» أقبحُ من إسقاطها.
    await pump(tester, {'rose': 2, 'ferrari': 9});

    expect(find.text('وردة'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.textContaining('ferrari'), findsNothing);
    expect(find.text('×9'), findsNothing);
  });

  testWidgets('صفرٌ لا يُعرَض', (tester) async {
    await pump(tester, {'rose': 3, 'car': 0});
    expect(find.text('سيّارة'), findsNothing);
  });

  testWidgets('لا تُغلَق بلمسةٍ جانبيّة — هديّةٌ تُقدَّم لا إعلانٌ يُنقَر جانبَه',
      (tester) async {
    await pump(tester, {'rose': 3});
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('أهلًا بك'), findsOneWidget);

    await tester.tap(find.text('شكرًا'));
    await tester.pumpAndSettle();
    expect(find.text('أهلًا بك'), findsNothing);
  });

  group('مرّةً واحدةً بحقّ', () {
    // العلمُ من الخادم لا من الجهاز: `SessionStore` يُعيد `isNew: false` دائمًا
    // (استعادةٌ لا إنشاء) ⇒ إعادةُ الفتح لا تُعيد النافذة، بلا علمٍ محفوظٍ يُنسى محوُه.
    test('الجلسة المستعادة ليست جديدةً ولا منحةَ فيها', () {
      const restored = AuthSession(
          token: 'tok',
          player: AccountPlayer(id: 'p1', displayName: 'أحمد', phone: '+2221', countryCode: 'MR', city: 'نواكشوط'),
          isNew: false);

      expect(restored.isNew, isFalse);
      expect(restored.welcomeGifts, isEmpty);
    });

    test('خادمٌ أقدمُ من الميزة ⇒ لا منحةَ مخترَعة', () {
      // `welcome` غائبةٌ في الردّ ⇒ خريطةٌ فارغةٌ ⇒ لا نافذة.
      const s = AuthSession(
          token: 'tok',
          player: AccountPlayer(id: 'p1', displayName: 'أحمد', phone: '+2221', countryCode: 'MR', city: 'نواكشوط'),
          isNew: true);
      expect(s.welcomeGifts, isEmpty);
    });
  });
}
