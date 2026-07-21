import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/net/table_client.dart';
import 'package:app/ui/reaction_picker.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('تحليل حدث التفاعل', () {
    test('phase=reaction ⇒ ReactionEvent لا لقطةَ مباراة', () {
      final e = TableEvent.parse({'phase': 'reaction', 'seat': 2, 'emoji': '👏'});
      expect(e, isA<ReactionEvent>());
      expect((e as ReactionEvent).seat, 2);
      expect(e.emoji, '👏');
    });
  });

  group('الكنترولر', () {
    late StreamController<String> incoming;
    late List<String> sent;
    late OnlineGameController c;

    /// مقعد اللاعب = 0 ما لم تصل لقطة، فإحداثيّات العرض = إحداثيّات الخادم هنا.
    void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));

    setUp(() {
      incoming = StreamController<String>.broadcast();
      sent = [];
      c = OnlineGameController(
        LiveTableClient(incoming: incoming.stream, send: sent.add),
      );
    });

    test('الإرسال ينقل النيّة للخادم ولا يعرض شيئًا محليًّا', () {
      c.react('🔥');
      expect(sent, hasLength(1));
      expect(jsonDecode(sent.single), {'type': 'reaction', 'emoji': '🔥'});
      // لا عرضَ متفائل: ما يظهر هو ما بثّه الخادم (قد يُسقِط الرمز حدًّا أو رفضًا).
      expect(c.reactions, [null, null, null, null]);
    });

    test('التفاعل الوارد يظهر فوق مقعده ويُشعِر المستمعين', () async {
      var notified = 0;
      c.addListener(() => notified++);
      feed({'phase': 'reaction', 'seat': 1, 'emoji': '😂'});
      await Future<void>.delayed(Duration.zero);

      expect(c.reactionAt(1), '😂');
      expect(c.reactions, [null, '😂', null, null]);
      expect(notified, greaterThan(0));
    });

    test('تفاعلٌ جديدٌ من نفس المقعد يستبدل السابق (لا تكديس)', () async {
      feed({'phase': 'reaction', 'seat': 1, 'emoji': '😂'});
      await Future<void>.delayed(Duration.zero);
      feed({'phase': 'reaction', 'seat': 1, 'emoji': '😢'});
      await Future<void>.delayed(Duration.zero);

      expect(c.reactionAt(1), '😢');
      expect(c.reactions.where((e) => e != null), hasLength(1));
    });

    test('مقاعد مختلفة ⇒ فقاعات مستقلّة معًا', () async {
      feed({'phase': 'reaction', 'seat': 1, 'emoji': '👍'});
      feed({'phase': 'reaction', 'seat': 3, 'emoji': '🔥'});
      await Future<void>.delayed(Duration.zero);

      expect(c.reactions, [null, '👍', null, '🔥']);
    });

    test('الفقاعة تختفي بعد reactionHold', () async {
      final c = OnlineGameController(
        LiveTableClient(incoming: incoming.stream, send: sent.add),
        reactionHold: const Duration(milliseconds: 40),
      );
      feed({'phase': 'reaction', 'seat': 2, 'emoji': '👏'});
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.reactionAt(2), '👏', reason: 'ما زالت ظاهرة خلال المهلة');

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.reactionAt(2), isNull, reason: 'انقضت المهلة ⇒ تختفي');
    });

    test('الإتلاف أثناء فقاعةٍ حيّة لا يُوقظ كنترولرًا متلَفًا', () async {
      final c = OnlineGameController(
        LiveTableClient(incoming: incoming.stream, send: sent.add),
        reactionHold: const Duration(milliseconds: 30),
      );
      feed({'phase': 'reaction', 'seat': 1, 'emoji': '👍'});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      c.dispose();

      // لو بقي المؤقّت لأشعر بعد الإتلاف ⇒ استثناء. الانتظار يتجاوز المهلة.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });

  group('الواجهة', () {
    testWidgets('المنتقي يعرض كل الرموز ويُبلّغ المختار', (t) async {
      final picked = <String>[];
      await t.pumpWidget(_wrap(ReactionPicker(onPick: picked.add)));

      for (final e in reactionEmojis) {
        expect(find.text(e), findsOneWidget, reason: '$e مفقودٌ من المنتقي');
      }
      await t.tap(find.text('🔥'));
      expect(picked, ['🔥']);
    });

    testWidgets('الفقاعة تعرض الرمز', (t) async {
      await t.pumpWidget(_wrap(const ReactionBubble(emoji: '👏')));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('👏'), findsOneWidget);
    });
  });
}
