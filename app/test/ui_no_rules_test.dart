import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **الحارس الحاكم:** لا منطق قواعد داخل `lib/ui/`.
///
/// الواجهة تعرض ما يحسبه `GameController` (عبر المحرك) وتُطلق النيّات فقط.
/// أي استدعاء لدالة قاعدة داخل ui/ يكسر هذا الاختبار — لا يُترك للانضباط.
/// (استيراد أنواع القيمة Card/Bid/Play للـtyping مسموح؛ الممنوع هو الأفعال.)
void main() {
  // أفعال القواعد في المحرك — يجب ألّا تظهر كاستدعاء داخل ui/.
  const forbidden = <String>[
    'legalPlays',
    'legalBidActions',
    'applyBidAction',
    'trickWinner',
    'trickUnits',
    'scoreRound',
    'distributePoints',
    'scoreFouja',
    'strength',
    'cardUnits',
    'orderFor',
    'isTrumpSuit',
    'bidRank',
    'roundValue',
    'successThreshold',
    'roundTotalUnits',
  ];

  test('لا استدعاء لدوال القواعد داخل lib/ui/', () {
    final dir = Directory('lib/ui');
    expect(dir.existsSync(), isTrue, reason: 'مجلد lib/ui غير موجود');

    final violations = <String>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();
      for (final verb in forbidden) {
        // استدعاء دالة: الاسم متبوعًا بقوس. نطاق كلمة على اليسار كي لا نلتقط
        // أسماء أطول تنتهي بنفس الأحرف.
        final re = RegExp(r'(?<![A-Za-z0-9_])' + verb + r'\s*\(');
        if (re.hasMatch(src)) {
          violations.add('${entity.path}: $verb(...)');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'تسرّبت قاعدة إلى ui/ — انقل الحساب إلى GameController:\n'
          '${violations.join('\n')}',
    );
  });
}
