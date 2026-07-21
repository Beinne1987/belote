import 'package:app/game/seat_player.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/gift_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// **الهديّة للجميع** — الثمن ×العدد بلا خصم (قرار المالك 2026-07-19).
///
/// أخطرُ ما هنا **تطابقُ الحساب مع الخادم**: لو عرضت اللوحةُ ثمنًا وخصم الخادمُ
/// غيرَه لرأى اللاعبُ سرقةً. القاعدةُ في الطرفين: المخزونُ يُستنفَد أوّلًا ثمّ
/// يُكمَّل بالماس.
Widget _host(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(home: Scaffold(body: child)),
    );

List<({int viewSeat, SeatPlayer player})> _targets(int n) => [
      for (var i = 1; i <= n; i++)
        (viewSeat: i, player: SeatPlayer(name: 'لاعب $i', playerId: 'p$i')),
    ];

void main() {
  Future<void> open(
    WidgetTester tester, {
    required int targets,
    required void Function(int, String) onSend,
    int Function(String)? stock,
  }) async {
    late BuildContext ctx;
    await tester.pumpWidget(_host(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    })));
    showGiftSheet(ctx,
        targets: _targets(targets), onSend: onSend, stock: stock);
    await tester.pumpAndSettle();
  }

  testWidgets('ثلاثةُ جلساء ⇒ شريحةُ «للجميع» حاضرة', (tester) async {
    await open(tester, targets: 3, onSend: (_, __) {});
    expect(find.text('للجميع'), findsOneWidget);
  });

  testWidgets('جليسٌ واحدٌ ⇒ **لا «للجميع»** (خياران لفعلٍ واحدٍ يُربكان)',
      (tester) async {
    await open(tester, targets: 1, onSend: (_, __) {});
    expect(find.text('للجميع'), findsNothing);
  });

  testWidgets('اختيارُ «للجميع» ثمّ هديّةٌ ⇒ تُرسَل بمقعد -1', (tester) async {
    final sent = <(int, String)>[];
    await open(tester, targets: 3, onSend: (s, g) => sent.add((s, g)));

    await tester.tap(find.text('للجميع'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('وردة'));
    await tester.pumpAndSettle();

    expect(sent, hasLength(1));
    expect(sent.first.$1, kGiftAll, reason: 'الخادم يفهم -1 أنّها للكلّ');
    expect(sent.first.$2, 'rose');
  });

  testWidgets('الثمنُ المعروض ×٣ عند «للجميع» — لا ثمنُ الواحدة', (tester) async {
    await open(tester, targets: 3, onSend: (_, __) {});

    // الوردةُ بـ٥ ⇒ مفردةً «5».
    expect(find.text('5'), findsOneWidget);

    await tester.tap(find.text('للجميع'));
    await tester.pumpAndSettle();

    // ثلاثةُ جلساء ⇒ «15» ولا أثرَ لـ«5».
    expect(find.text('15'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('المخزونُ يُستنفَد أوّلًا ثمّ الماس — **نظيرُ الخادم حرفًا**',
      (tester) async {
    // يملك وردتين ويُهدي ثلاثة ⇒ ماسُ **واحدةٍ** = 5 (لا 15).
    await open(tester,
        targets: 3,
        onSend: (_, __) {},
        stock: (id) => id == 'rose' ? 2 : 0);

    await tester.tap(find.text('للجميع'));
    await tester.pumpAndSettle();

    expect(find.text('5'), findsOneWidget, reason: 'الباقيةُ وحدها بالماس');
  });

  testWidgets('مخزونٌ يغطّي الجميع ⇒ **لا ثمنَ بالماس** بل ×العدد',
      (tester) async {
    await open(tester,
        targets: 3,
        onSend: (_, __) {},
        stock: (id) => id == 'rose' ? 5 : 0);

    await tester.tap(find.text('للجميع'));
    await tester.pumpAndSettle();

    expect(find.text('×3'), findsOneWidget, reason: 'ثلاثٌ من المخزون');
  });

  testWidgets('اللوحة تشرح أنّ الثمن لكلّ لاعب', (tester) async {
    await open(tester, targets: 3, onSend: (_, __) {});
    await tester.tap(find.text('للجميع'));
    await tester.pumpAndSettle();

    expect(find.textContaining('3 لاعبين'), findsOneWidget);
  });
}
