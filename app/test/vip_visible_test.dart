import 'package:app/game/seat_player.dart';
import 'package:app/net/table_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/player_card_square.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// **مَن دفع يُرى** — بلاغُ المالك 2026-07-16: «فعّلت VIP وظهر في قسمه أنّني VIP،
/// لكن لعبتُ فظهرتُ لاعبًا بسيطًا — لا إطار ولا شارة».
///
/// السببُ كان أنّ `isVip` **حقلٌ ميّت**: الخادمُ لا يبثّه والبطاقةُ لا تقرؤه. هذه
/// الاختباراتُ تقفل السلسلةَ كلَّها: **حقلُ الخادم ⇒ `LobbySeat` ⇒ البطاقة**.
Widget _wrap(Widget c) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        builder: (_, w) =>
            Directionality(textDirection: TextDirection.rtl, child: w!),
        home: Scaffold(body: Center(child: c)),
      ),
    );

List<String> _assets(WidgetTester t) => t
    .widgetList<Image>(find.byType(Image))
    .map((i) => (i.image as AssetImage).assetName)
    .toList();

void main() {
  group('حقلُ الخادم يصل', () {
    test('«vip: true» في المقعد ⇒ LobbySeat.isVip', () {
      final s = LobbySeat.fromJson(
          {'seat': 1, 'ai': false, 'name': 'أحمد', 'vip': true});
      expect(s.isVip, isTrue);
    });

    // **خادمٌ قديمٌ لا يبثّ الحقل** ⇒ false بلا انهيار (حقلٌ زائدٌ لا طورٌ جديد).
    test('غيابُ الحقل ⇒ false لا انهيار', () {
      final s = LobbySeat.fromJson({'seat': 1, 'ai': false, 'name': 'أحمد'});
      expect(s.isVip, isFalse);
    });
  });

  // **الإطارُ الدائريُّ حول الصورة** (قرارُ المالك 2026-07-19): أُلغي المربّعُ —
  // «لم يعد يناسب البطاقة» — وصارت إشارةُ VIP الإطارَ الدائريَّ الموحَّدَ (نفسُه
  // في اللوبي والملفّ والأصدقاء) حول الصورة + شارةَ «VIP».
  group('البطاقةُ تُري الإطار', () {
    testWidgets('VIP ⇒ إطارُه الذهبيُّ الدائريُّ حول صورته', (t) async {
      await t.pumpWidget(_wrap(const PlayerCardSquare(
          name: 'أحمد', emoji: '👤', rank: PlayerRank.pro, isVip: true)));
      await t.pumpAndSettle();

      expect(_assets(t), contains('assets/VIP/frame_gold_round.png'));
      // **المربّعُ أُلغي** — لم يعد يناسب البطاقة.
      expect(_assets(t), isNot(contains('assets/VIP/player_frame_vip.png')));
    });

    // **غرفةُ VIP يراها الجميع** (قرارُ المالك 2026-07-16): مضيفُها مشتركٌ ⇒
    // خلفيّتُه — ومزيّةٌ يراها صاحبُها وحدَه لا يعلم بها أحدٌ فلا تُحفّز.
    test('«vipRoom: true» في اللوبي ⇒ LobbyEvent.vipRoom', () {
      final e = LobbyEvent.fromJson(
          {'tableId': 't1', 'seats': <dynamic>[], 'vipRoom': true});
      expect(e.vipRoom, isTrue);
    });

    test('غيابُ الحقل (خادمٌ قديم) ⇒ false لا انهيار', () {
      final e = LobbyEvent.fromJson({'tableId': 't1', 'seats': <dynamic>[]});
      expect(e.vipRoom, isFalse);
    });

    // **ولا إطارَ لمن لم يدفع** — وإلّا فقدت المزيّةُ معناها.
    testWidgets('غيرُ VIP ⇒ لا إطار', (t) async {
      await t.pumpWidget(_wrap(const PlayerCardSquare(
          name: 'بلال', emoji: '👤', rank: PlayerRank.pro)));
      await t.pumpAndSettle();

      expect(_assets(t), isNot(contains('assets/VIP/frame_gold_round.png')));
      expect(_assets(t), isNot(contains('assets/VIP/player_frame_vip.png')));
    });
  });
}
