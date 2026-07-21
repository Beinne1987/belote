import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/game/view_model.dart';
import 'package:app/net/table_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/result_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// لوحة نتيجةٍ لمباراةٍ فاز بها فريقنا (التصنيف لا يُعرض إلا عند نهاية المباراة).
Widget _panel({int? rating, int? ratingDelta}) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Scaffold(
          body: ResultPanel(
            result: const RoundResult(
              usPoints: 16,
              themPoints: 0,
              usTotal: 104,
              themTotal: 40,
              roundValue: 16,
              reason: 'normal',
              matchOutcome: 0,
            ),
            onNewMatch: () {},
            rating: rating,
            ratingDelta: ratingDelta,
          ),
        ),
      ),
    );

void main() {
  group('تحليل حدث التصنيف', () {
    test('رسالة phase=rating ⇒ RatingEvent لا لقطةَ مباراة', () {
      final e = TableEvent.parse({'phase': 'rating', 'rating': 1016, 'delta': 16});
      expect(e, isA<RatingEvent>());
      expect((e as RatingEvent).rating, 1016);
      expect(e.delta, 16);
    });

    test('التغيّر السالب يُحفَظ كما هو (الخاسر يهبط)', () {
      final e = TableEvent.parse({'phase': 'rating', 'rating': 984, 'delta': -16})
          as RatingEvent;
      expect(e.delta, -16);
    });
  });

  group('الكنترولر', () {
    late StreamController<String> incoming;
    late OnlineGameController c;

    setUp(() {
      incoming = StreamController<String>.broadcast();
      c = OnlineGameController(LiveTableClient(incoming: incoming.stream, send: (_) {}));
    });

    void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));

    test('لا تصنيف قبل وصول الحدث', () {
      expect(c.rating, isNull);
    });

    test('حدث التصنيف يُخزَّن ويُشعِر المستمعين', () async {
      var notified = 0;
      c.addListener(() => notified++);
      feed({'phase': 'rating', 'rating': 1016, 'delta': 16});
      await Future<void>.delayed(Duration.zero);

      expect(c.rating!.rating, 1016);
      expect(c.rating!.delta, 16);
      expect(notified, greaterThan(0));
    });

    test('العودة إلى اللوبي تمسح تصنيف المباراة السابقة', () async {
      feed({'phase': 'rating', 'rating': 1016, 'delta': 16});
      await Future<void>.delayed(Duration.zero);
      expect(c.rating, isNotNull);

      feed({'phase': 'lobby', 'tableId': 't1', 'seats': <Map<String, dynamic>>[]});
      await Future<void>.delayed(Duration.zero);
      expect(c.rating, isNull, reason: 'مباراةٌ جديدة ⇒ لا تصنيفَ قديم');
    });
  });

  group('لوحة النتيجة', () {
    testWidgets('مباراةٌ مصنّفة ⇒ التقييم وتغيّره ظاهران بسهمٍ صاعد', (t) async {
      await t.pumpWidget(_panel(rating: 1023, ratingDelta: 23));
      expect(find.text('1023'), findsOneWidget);
      expect(find.text('+23'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
    });

    testWidgets('الخاسر ⇒ سهمٌ هابط وإشارة ناقصٍ حقيقيّة (لا سالبٌ مزدوج)', (t) async {
      await t.pumpWidget(_panel(rating: 984, ratingDelta: -16));
      expect(find.text('984'), findsOneWidget);
      expect(find.text('−16'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('مباراةٌ غير مصنّفة (أوفلاين/ذكاء) ⇒ لا سطر تصنيف البتّة', (t) async {
      await t.pumpWidget(_panel());
      expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
      expect(find.textContaining('التصنيف'), findsNothing);
    });
  });
}
