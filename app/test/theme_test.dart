import 'package:app/theme/belote_theme.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/theme/themes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// يحرس نظام الهوية: الثيمات الخمسة موجودة ومتمايزة، والمدير يبدّل ويُخطر،
/// و`BeloteTheme.of` يقرأ الثيم النشط من الشجرة.
void main() {
  test('الثيمات الخمسة موجودة بأسماء متمايزة', () {
    expect(BeloteThemes.all.length, 5);
    final names = BeloteThemes.all.map((t) => t.name).toSet();
    expect(names.length, 5, reason: 'أسماء الثيمات يجب أن تكون فريدة');
    expect(BeloteThemes.all.first, BeloteThemes.classic, reason: 'الافتراضي أولًا');
  });

  test('Marble فاتح والبقية داكنة', () {
    expect(BeloteThemes.marble.brightness, Brightness.light);
    for (final t in BeloteThemes.all.where((t) => t != BeloteThemes.marble)) {
      expect(t.brightness, Brightness.dark, reason: '${t.name} داكن');
    }
  });

  test('ThemeManager يبدّل الثيم ويُخطر', () {
    final m = ThemeManager();
    expect(m.current, BeloteThemes.classic);
    var notified = 0;
    m.addListener(() => notified++);
    m.setTheme(BeloteThemes.royal);
    expect(m.current, BeloteThemes.royal);
    expect(notified, 1);
    m.setTheme(BeloteThemes.royal); // نفس الثيم ⇒ لا إخطار
    expect(notified, 1);
  });

  testWidgets('BeloteTheme.of يقرأ الثيم النشط', (tester) async {
    final m = ThemeManager();
    late BeloteTheme seen;
    await tester.pumpWidget(ThemeScope(
      manager: m,
      child: Builder(builder: (context) {
        seen = BeloteTheme.of(context);
        return const SizedBox();
      }),
    ));
    expect(seen, BeloteThemes.classic);
  });
}
