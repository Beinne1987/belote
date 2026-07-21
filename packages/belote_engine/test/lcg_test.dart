import 'package:test/test.dart';
import 'package:belote_engine/belote_engine.dart';

/// الحالات الذهبية: أوّل ٢٠ حالة (uint32) من `Lcg(1000)` في محرك JS المرجعي
/// (نفس معادلة `lcg` في `reference/tools/gen-fixtures.js`).
///
/// نقارن الحالة الصحيحة لا النص العشري: القيمة = state / 2^32 تقسيمٌ **مضبوط**
/// في double، فيُعيد Dart بناء نفس الـ double بت-ببت من نفس العدد الصحيح.
const goldenStates = <int>[
  2678429223, 4219084122, 2266909937, 2938757532, 3652161611,
  1428826414, 1635344053, 3405897872, 957397679, 130099266,
  2243578553, 2361095364, 2040396115, 3018239638, 1432065277,
  2619822648, 3702026295, 2198966314, 4158521729, 1827106028,
];

void main() {
  test('أوّل ٢٠ قيمة من Lcg(1000) تطابق JS تماماً (بت-ببت)', () {
    final rng = Lcg(1000);
    for (var i = 0; i < goldenStates.length; i++) {
      final expected = goldenStates[i] / 4294967296.0;
      expect(rng.next(), expected, reason: 'اختلاف عند الخطوة $i');
    }
  });
}
