import 'package:app/game/game_controller.dart';
import 'package:app/game/view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// يضمن أن مغادرة الطاولة (dispose) توقف حلقات التأخير والصوت — فلا تبقى اللعبة
/// «تلعب» في الخلفية بعد زرّ الرجوع (ملاحظة صاحب المشروع).
void main() {
  testWidgets('بعد الإتلاف: لا أصوات جديدة من حلقة التوزيع', (tester) async {
    await tester.runAsync(() async {
      var sounds = 0;
      final c = GameController(
        seed: 1,
        aiThink: const Duration(milliseconds: 20),
        pliPause: Duration.zero,
        pliCollect: Duration.zero,
        pliSettle: Duration.zero,
        bidHold: Duration.zero,
        dealPause: const Duration(milliseconds: 40), // حلقة توزيع بخمس نقرات صوت
        onSound: (GameSound _) => sounds++,
      );
      // نُغادر فورًا قبل أن تُطلَق نقرات التوزيع.
      c.dispose();
      final atDispose = sounds;

      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(sounds, atDispose, reason: 'يجب ألا يُطلَق أيّ صوت بعد الإتلاف');
    });
  });

  testWidgets('بعد الإتلاف: notifyListeners لا يُخطر ولا يرمي', (tester) async {
    final c = GameController(
      seed: 2,
      aiThink: Duration.zero,
      pliPause: Duration.zero,
      pliCollect: Duration.zero,
      pliSettle: Duration.zero,
      bidHold: Duration.zero,
      dealPause: Duration.zero,
    );
    var notified = 0;
    c.addListener(() => notified++);
    c.dispose();
    // لا استثناء «used after dispose»، ولا إشعار جديد.
    expect(notified, 0);
  });
}
