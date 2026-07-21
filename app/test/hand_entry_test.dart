import 'package:app/game/view_model.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/table_screen.dart';
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// **دخولُ اليد**: الأوراقُ تنزل كومةً إلى مروحتها بتتابع. الحركةُ زينةٌ —
/// ويجب ألّا تكلّف اللاعبَ ورقةً: تُلمَس وتُلعَب حتى وهي في الطريق.
const _hand = [
  Card('pique', 'A'),
  Card('pique', '10'),
  Card('coeur', 'K'),
  Card('coeur', 'Q'),
  Card('carreau', 'J'),
  Card('carreau', '9'),
  Card('trefle', 'A'),
  Card('trefle', '8'),
];

TableView _view() => const TableView(
      myHand: _hand,
      handCounts: [8, 8, 8, 8],
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
      humanCanPlay: true,
    );

Widget _screen(void Function(Card)? onPlay) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: TableScreen(view: _view(), onPlayCard: onPlay),
      ),
    );

void main() {
  testWidgets('اليدُ كاملةٌ بعد استقرار الدخول', (t) async {
    await t.pumpWidget(_screen(null));
    await t.pumpAndSettle();
    // الرتبةُ تُرسَم نصًّا في زاويتَي كلّ ورقة (أعلى وأسفل).
    expect(find.text('10'), findsNWidgets(2));
    expect(find.text('Q'), findsNWidgets(2));
  });

  testWidgets('اللمسُ يلعب حتى أثناء الدخول', (t) async {
    Card? played;
    await t.pumpWidget(_screen((c) => played = c));
    await t.pump(const Duration(milliseconds: 80)); // في منتصف الطريق
    await t.tap(find.text('Q').first, warnIfMissed: false);
    expect(played, isNotNull,
        reason: 'ورقةٌ في الطريق يجب أن تُلعَب كأيّ ورقةٍ مستقرّة');
    await t.pumpAndSettle();
  });
}
