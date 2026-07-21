import 'package:test/test.dart';
import 'package:belote_engine/belote_engine.dart';

int _sum(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);

void main() {
  test('sum(unitsTout) == 62', () {
    expect(_sum(unitsTout), 62);
  });

  test('sum(unitsPlain) == 30', () {
    expect(_sum(unitsPlain), 30);
  });

  test('كل سُلَّم يغطّي الرُّتب الثماني بلا تكرار', () {
    const ranks = {'7', '8', '9', '10', 'J', 'Q', 'K', 'A'};
    expect(unitsTout.keys.toSet(), ranks);
    expect(unitsPlain.keys.toSet(), ranks);
    expect(orderSans.toSet(), ranks);
    expect(orderTout.toSet(), ranks);
    expect(orderSans.length, 8);
    expect(orderTout.length, 8);
  });
}
