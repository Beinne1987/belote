import 'package:app/game/view_model.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/table_screen.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// طاولةٌ في دور اللاعب البشريّ مع مهلةٍ جارية ⇒ عدّاد الدور ظاهر.
TableView _view({Duration? limit, int seq = 0}) => TableView(
      myHand: const [],
      handCounts: const [0, 0, 0, 0],
      usScore: 0,
      themScore: 0,
      bid: null,
      bidderSeat: null,
      akwins: false,
      dealerSeat: 0,
      seatBids: const [null, null, null, null],
      turn: 0,
      trick: const [],
      legalCards: const {},
      phase: GamePhase.playing,
      humanCanPlay: true,
      humanTurnLimit: limit,
      humanTurnSeq: seq,
    );

Widget _screen({Duration? limit, VoidCallback? onTurnTick, int seq = 0}) =>
    ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: TableScreen(view: _view(limit: limit, seq: seq), onTurnTick: onTurnTick),
      ),
    );

void main() {
  testWidgets('التكتكة في آخر خمس ثوانٍ فقط، ثمّ تتوقّف عند نفاد المهلة', (t) async {
    var ticks = 0;
    await t.pumpWidget(_screen(
      limit: const Duration(seconds: 15),
      onTurnTick: () => ticks++,
    ));

    await t.pump(const Duration(seconds: 9));
    expect(ticks, 0, reason: 'أوّل الدور صامت — التكتكة تنبيهُ نفادٍ لا خلفيّةُ ضجيج');

    await t.pump(const Duration(seconds: 1)); // دخلنا آخر ٥ ثوانٍ (10/15)
    expect(ticks, 1, reason: 'تكتكةٌ فور دخول النافذة');

    await t.pump(const Duration(seconds: 4)); // 14/15 ⇒ تكتكاتٌ كلَّ ثانية
    expect(ticks, 5, reason: 'خمس تكتكات: واحدةٌ لكلّ ثانيةٍ باقية');

    await t.pump(const Duration(seconds: 5)); // بعد نفاد المهلة
    expect(ticks, 5, reason: 'لا تكتكة بعد انتهاء المهلة (يلعب الذكاء مكانك)');

    // العدّاد نفسه ما يزال يتحرّك ⇒ نُنهي حركته قبل انتهاء الاختبار.
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('مهلةٌ أقصر من نافذة التكتكة ⇒ تكتكةٌ من أوّلها بعدد ثوانيها', (t) async {
    var ticks = 0;
    await t.pumpWidget(_screen(
      limit: const Duration(seconds: 3),
      onTurnTick: () => ticks++,
    ));

    await t.pump(); // تكتكة البداية
    expect(ticks, 1);
    await t.pump(const Duration(seconds: 3));
    expect(ticks, 3, reason: 'ثلاث ثوانٍ ⇒ ثلاث تكتكات، بلا زيادة');

    await t.pumpWidget(const SizedBox());
  });

  testWidgets('بلا onTurnTick ⇒ عدّادٌ صامتٌ بلا مؤقّتاتٍ معلّقة (الأوفلاين/الاختبارات)',
      (t) async {
    await t.pumpWidget(_screen(limit: const Duration(seconds: 15)));
    await t.pump(const Duration(seconds: 15));
    // نجاح الاختبار بلا «A Timer is still pending» هو المُدّعى نفسه.
    await t.pumpWidget(const SizedBox());
  });
}
