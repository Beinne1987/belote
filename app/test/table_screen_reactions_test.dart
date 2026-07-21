import 'package:app/game/view_model.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/table_screen.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// أبسط طاولةٍ صالحة: طور لعبٍ بلا أوراق على الطاولة ولا يدٍ للاعب.
const _view = TableView(
  myHand: [],
  handCounts: [0, 0, 0, 0],
  usScore: 0,
  themScore: 0,
  bid: null,
  bidderSeat: null,
  akwins: false,
  dealerSeat: 0,
  seatBids: [null, null, null, null],
  turn: 0,
  trick: [],
  legalCards: {},
  phase: GamePhase.playing,
);

Widget _screen({
  List<String?>? reactions,
  void Function(String)? onReact,
  RoundResult? result,
}) =>
    ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: TableScreen(
          view: _view,
          reactions: reactions,
          onReact: onReact,
          result: result,
        ),
      ),
    );

void main() {
  testWidgets('أونلاين (onReact مُمرَّر) ⇒ زرّ التفاعلات ظاهر، والمنتقي يفتح ويرسل',
      (t) async {
    final picked = <String>[];
    await t.pumpWidget(_screen(onReact: picked.add));

    expect(find.byIcon(Icons.add_reaction_outlined), findsOneWidget);
    expect(find.text('🔥'), findsNothing, reason: 'المنتقي مغلقٌ ابتداءً');

    await t.tap(find.byIcon(Icons.add_reaction_outlined));
    await t.pump();
    expect(find.text('🔥'), findsOneWidget, reason: 'الضغط يفتح المنتقي');

    await t.tap(find.text('🔥'));
    await t.pump();
    expect(picked, ['🔥']);
    expect(find.text('🔥'), findsNothing, reason: 'الاختيار يُغلق المنتقي');
  });

  testWidgets('أوفلاين (بلا onReact) ⇒ لا زرّ تفاعلات البتّة', (t) async {
    await t.pumpWidget(_screen());
    expect(find.byIcon(Icons.add_reaction_outlined), findsNothing);
  });

  testWidgets('الفقاعة تظهر فوق بطاقة المقعد صاحبِ التفاعل', (t) async {
    await t.pumpWidget(_screen(reactions: [null, '😂', null, null]));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('😂'), findsOneWidget);
  });

  testWidgets('بلا تفاعلاتٍ جارية ⇒ لا فقاعات', (t) async {
    await t.pumpWidget(_screen(reactions: [null, null, null, null]));
    expect(find.text('😂'), findsNothing);
  });

  testWidgets('لوحة النتيجة ظاهرة ⇒ يُخفى زرّ التفاعلات (لا يزاحم اللحظة الحاسمة)',
      (t) async {
    await t.pumpWidget(_screen(
      onReact: (_) {},
      result: const RoundResult(
        usPoints: 16,
        themPoints: 0,
        usTotal: 104,
        themTotal: 40,
        roundValue: 16,
        reason: 'normal',
        matchOutcome: 0,
      ),
    ));
    expect(find.byIcon(Icons.add_reaction_outlined), findsNothing);
  });
}
