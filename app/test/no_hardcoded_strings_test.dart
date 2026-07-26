import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **لا نصَّ ظاهرًا مكتوبًا في `lib/ui`** (طلب المالك 2026-07-23).
///
/// النصُّ الحرفيُّ في الودجة يعني شاشةً لا تُترجَم: تبقى عربيّةً في واجهةٍ
/// فرنسيّةٍ فتبدو نصفَ لعبة. هذا الحارسُ يمنع أن يتسلّل واحدٌ جديدٌ مع أوّل
/// ميزةٍ قادمة — الاختبارُ أرخصُ من مراجعةٍ بشريّةٍ لكلّ سطر.
///
/// **يفحص الحرفَ العربيّ لا كلَّ نصّ**: عربيٌّ في `lib/ui` = نصُّ لاعبٍ بلا شكّ.
/// الرموزُ اللاتينيّة (`'fr'` · `'assets/…'` · `'rose'`) معرّفاتٌ لا تُترجَم.
///
/// **ما يُستثنى صراحةً:**
/// - التعليقات (شرحُ الكود عربيٌّ عمدًا — [[arabic-terminal-readability]]).
/// - رسائلُ `throw`/`assert`: تُقال للمبرمج لا للاعب، ولا تُعرَض في شاشة.
/// - `Français` و`العربية` في مبدّل اللغة: **كلُّ لغةٍ باسمها في لغتها** ⇒
///   ترجمتُها تُفسدها. تُقرأ من ARB (`languageArabicNative`) فلا تظهر هنا.
void main() {
  test('لا نصَّ عربيًّا حرفيًّا في lib/ui — كلُّه من AppLocalizations', () {
    final arabic = RegExp(r'[؀-ۿ]');
    // سلسلةٌ نصّيّةٌ بعلامة اقتباسٍ مفردةٍ أو مزدوجة، بلا هروب.
    final literal = RegExp(r"'([^'\\]*)'|" r'"([^"\\]*)"');
    final offenders = <String>[];

    for (final entity in Directory('lib/ui').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//')) continue; // تعليق
        // رسالةٌ للمبرمج لا للاعب.
        if (trimmed.startsWith('throw ') ||
            trimmed.startsWith('assert(') ||
            trimmed.contains('ArgumentError(') ||
            trimmed.contains('StateError(')) {
          continue;
        }
        final code = line.split('//').first; // تعليقٌ في آخر السطر
        for (final m in literal.allMatches(code)) {
          final text = m.group(1) ?? m.group(2) ?? '';
          if (arabic.hasMatch(text)) {
            offenders.add('${entity.path}:${i + 1}: $text');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'نصٌّ ظاهرٌ مكتوبٌ في الودجة لا يُترجَم. انقله إلى '
          'lib/l10n/app_ar.arb و app_fr.arb واقرأه بـAppLocalizations:\n'
          '${offenders.join('\n')}',
    );
  });

  test('كلُّ مفتاحٍ عربيٍّ له مقابلٌ فرنسيّ — لا سقوطَ صامتٌ إلى العربيّة', () {
    List<String> keysOf(String path) {
      final src = File(path).readAsStringSync();
      // مفاتيحُ ARB في أوّل كلِّ سطرٍ من الكائن؛ ما بدأ بـ@ وصفٌ لا نصّ.
      return RegExp(r'^\s*"([^"@][^"]*)"\s*:')
          .allMatches(src)
          .map((m) => m.group(1)!)
          .where((k) => !k.startsWith('@'))
          .toList();
    }

    final ar = keysOf('lib/l10n/app_ar.arb').toSet()..remove('@@locale');
    final fr = keysOf('lib/l10n/app_fr.arb').toSet()..remove('@@locale');
    expect(ar.difference(fr), isEmpty, reason: 'مفاتيحُ بلا ترجمةٍ فرنسيّة');
    expect(fr.difference(ar), isEmpty, reason: 'مفاتيحُ فرنسيّةٌ بلا أصلٍ عربيّ');
  });
}
