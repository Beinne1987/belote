import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:app/game/online_game_controller.dart';
import 'package:app/game/seat_player.dart';
import 'package:app/net/table_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// **رتبةُ الروبوت الصادقة** (#12) — الخادم يعاير مستوى الذكاء من متوسّط تصنيف
/// الجالسين، لكنّ العميل كان يخترع للروبوت تصنيفًا عشوائيًّا `850..1499` فتظهر
/// رتبتُه على البطاقة **كاذبةً**: «أسطورة» تخطئ كمبتدئ، أو «مبتدئ» لا يُخطئ أبدًا.
///
/// هذه الاختبارات تقفل السلسلة كلَّها:
/// **حقلُ الخادم `aiLevel` ⇒ `LobbySeat` ⇒ `seatPlayers` ⇒ `PlayerRank`.**
void main() {
  group('حقلُ الخادم يصل', () {
    test('«aiLevel» في مقعد الذكاء ⇒ LobbySeat.aiLevel', () {
      final s = LobbySeat.fromJson({'seat': 2, 'ai': true, 'aiLevel': 'expert'});
      expect(s.aiLevel, 'expert');
    });

    // **خادمٌ قديمٌ لا يبثّ الحقل** ⇒ null بلا انهيار (حقلٌ زائدٌ لا طورٌ جديد).
    test('غيابُ الحقل ⇒ null لا انهيار', () {
      final s = LobbySeat.fromJson({'seat': 2, 'ai': true});
      expect(s.aiLevel, isNull);
    });
  });

  group('التصنيفُ المشتقُّ داخل نطاق المستوى', () {
    // النطاقات هي عتبات `PlayerRank` نفسها ⇒ الرتبة المعروضة تطابق المستوى حتمًا.
    const bands = {
      'beginner': PlayerRank.beginner,
      'pro': PlayerRank.pro,
      'expert': PlayerRank.expert,
      'legend': PlayerRank.legend,
    };

    test('كلُّ مستوًى ⇒ رتبتُه هو مهما تقلّبت البذور', () {
      for (final e in bands.entries) {
        for (var seed = 0; seed < 200; seed++) {
          final p = aiSeatPlayer(Random(seed), level: e.key);
          expect(p.rank, e.value,
              reason: 'مستوى ${e.key} ببذرة $seed أنتج ${p.rank}');
        }
      }
    });

    test('مستوًى مجهول أو null ⇒ النطاق الكامل (سلوك الخادم القديم)', () {
      for (final level in [null, 'weird']) {
        final ranks = <PlayerRank>{
          for (var seed = 0; seed < 200; seed++)
            aiSeatPlayer(Random(seed), level: level).rank
        };
        expect(ranks, PlayerRank.values.toSet(),
            reason: 'بلا معايرةٍ تُرى كلُّ الرتب كما اليوم');
      }
    });

    // تغيُّر مستوى الطاولة في اللوبي (انضمام بشريّ يرفع المتوسّط) يجدّد الرتبة —
    // ويجب **ألّا يغيّر** اسم الروبوت وصورته أمام الجالسين.
    test('تغيُّر المستوى يغيّر الرتبةَ لا الهويّة', () {
      for (var seed = 0; seed < 50; seed++) {
        final a = aiSeatPlayer(Random(seed), level: 'beginner');
        final b = aiSeatPlayer(Random(seed), level: 'legend');
        expect(b.name, a.name);
        expect(b.emoji, a.emoji);
        expect(b.isVip, a.isVip);
        expect(a.rank, PlayerRank.beginner);
        expect(b.rank, PlayerRank.legend);
      }
    });
  });

  group('المتحكّم يعرض الرتبةَ الصادقة', () {
    (OnlineGameController, void Function(Map<String, dynamic>)) harness() {
      final incoming = StreamController<String>.broadcast();
      final client =
          LiveTableClient(incoming: incoming.stream, send: (_) {});
      final c = OnlineGameController(client);
      return (c, (m) => incoming.add(jsonEncode(m)));
    }

    Map<String, dynamic> lobby(List<Map<String, dynamic>> seats) =>
        {'phase': 'lobby', 'tableId': 't1', 'you': 0, 'seats': seats};

    test('مقعدُ ذكاءٍ بمستوى الخادم ⇒ رتبتُه على البطاقة', () async {
      final (c, feed) = harness();
      feed(lobby([
        {'seat': 0, 'ai': false, 'playerId': 'p1', 'name': 'أنا', 'connected': true},
        {'seat': 1, 'ai': true, 'aiLevel': 'beginner'},
        {'seat': 2, 'ai': true, 'aiLevel': 'beginner'},
        {'seat': 3, 'ai': true, 'aiLevel': 'beginner'},
      ]));
      await Future<void>.delayed(Duration.zero);

      for (var pos = 1; pos < 4; pos++) {
        final p = c.seatPlayers[pos];
        expect(p.isAI, isTrue);
        expect(p.rank, PlayerRank.beginner,
            reason: 'الخادم قال مبتدئ فلا تُعرَض رتبةٌ أخرى');
      }
    });

    test('لوبي متجدّد بمستوًى أعلى ⇒ الرتبةُ تلحقه والاسمُ ثابت', () async {
      final (c, feed) = harness();
      final aiSeat = {'seat': 1, 'ai': true, 'aiLevel': 'beginner'};
      feed(lobby([
        {'seat': 0, 'ai': false, 'playerId': 'p1', 'name': 'أنا', 'connected': true},
        aiSeat,
      ]));
      await Future<void>.delayed(Duration.zero);
      final before = c.seatPlayers[1];
      expect(before.rank, PlayerRank.beginner);

      feed(lobby([
        {'seat': 0, 'ai': false, 'playerId': 'p1', 'name': 'أنا', 'connected': true},
        {'seat': 2, 'ai': false, 'playerId': 'p2', 'name': 'أسطورة', 'connected': true},
        {'seat': 1, 'ai': true, 'aiLevel': 'expert'},
      ]));
      await Future<void>.delayed(Duration.zero);
      final after = c.seatPlayers[1];
      expect(after.rank, PlayerRank.expert, reason: 'خبيئةٌ قديمةٌ كانت ستكذب هنا');
      expect(after.name, before.name, reason: 'الهويّة لا تتبدّل أمام الجالسين');
    });
  });
}
