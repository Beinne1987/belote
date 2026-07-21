import 'package:app/game/seat_player.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/player_card_square.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _card({required bool active, String name = 'محمد ولد أحمد'}) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayerCardSquare(
              name: name,
              emoji: '🙂',
              rank: PlayerRank.expert,
              active: active,
              size: 78,
            ),
          ),
        ),
      ),
    );

void main() {
  // البطاقة النشطة تُحاط بحدٍّ أسمك (2.4 مقابل 1) يقتطع من ارتفاع المحتوى، فكانت
  // تفيض ببضع بكسلات — على أبرز بطاقةٍ في الشاشة (صاحب الدور).
  testWidgets('البطاقة النشطة لا تفيض', (t) async {
    await t.pumpWidget(_card(active: true));
    await t.pump(const Duration(milliseconds: 250));
    expect(_layoutErrors(), isEmpty);
  });

  testWidgets('البطاقة الخاملة لا تفيض', (t) async {
    await t.pumpWidget(_card(active: false));
    await t.pump(const Duration(milliseconds: 250));
    expect(_layoutErrors(), isEmpty);
  });

  testWidgets('اسمٌ طويل جدًّا يُقصّ بلا فيض', (t) async {
    await t.pumpWidget(_card(active: true, name: 'محمد ولد أحمد ولد سيدي ولد المختار'));
    await t.pump(const Duration(milliseconds: 250));
    expect(_layoutErrors(), isEmpty);
    expect(find.byType(PlayerCardSquare), findsOneWidget);
  });
}

/// خطأ التخطيط (الفيض) يُرفَع كاستثناءٍ في الاختبار؛ هذه تلتقطه إن وقع.
List<Object> _layoutErrors() {
  final e = TestWidgetsFlutterBinding.instance.takeException();
  return e == null ? const [] : [e];
}
