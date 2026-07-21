import 'package:app/ui/card_back.dart';
import 'package:app/ui/card_face.dart';
import 'package:app/ui/card_shell.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// الوجهُ والظهرُ يلبسان **الغلافَ نفسَه**: قبلَه كان الوجهُ مدوّرًا مُظلَّلًا
/// والظهرُ مسطّحًا حادَّ الزوايا، فتبدو يدُك محمولةً وأيدي الخصوم مطبوعةً على
/// اللبّاد. هذا الاختبارُ يمنع عودةَ الانحراف.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: 80, child: child))),
    ));
  }

  testWidgets('وجهُ الورقة داخل الغلاف المشترك', (tester) async {
    await pump(tester, const CardFace(card: Card('pique', 'A')));
    expect(find.byType(CardShell), findsOneWidget);
  });

  testWidgets('ظهرُ الورقة داخل الغلاف نفسِه', (tester) async {
    // الظهرُ يرسم من الذاكرة المؤقّتة؛ بلا تحميلٍ يبقى فارغًا (كما في الإقلاع
    // قبل `preloadCardArt`) فلا غلافَ ولا شيء — نحمّله كما يفعل التطبيق.
    await tester.runAsync(preloadCardArt);
    await pump(tester, const CardBack());
    expect(find.byType(CardShell), findsOneWidget);
  });

  test('نصفُ القطر مشتقٌّ من العرض لا رقمٌ مكرّر', () {
    expect(CardShell.radiusFor(100).topLeft.x, closeTo(5.5, 0.001));
    expect(CardShell.radiusFor(50).topLeft.x, closeTo(2.75, 0.001));
  });

  testWidgets('اللمعةُ لا تبتلع اللمس', (tester) async {
    var tapped = false;
    await pump(
      tester,
      GestureDetector(
        onTap: () => tapped = true,
        child: const CardFace(card: Card('coeur', 'K')),
      ),
    );
    await tester.tap(find.byType(CardFace));
    expect(tapped, isTrue);
  });
}
