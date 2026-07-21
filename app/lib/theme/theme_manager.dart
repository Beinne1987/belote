import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'belote_theme.dart';
import 'themes.dart';

/// يحمل الثيم النشط، يُخطر عند تبديله، ويحفظ/يستعيد الاختيار من التخزين المحلّي.
class ThemeManager extends ChangeNotifier {
  static const _prefKey = 'belote_theme';
  BeloteTheme _current;
  ThemeManager([BeloteTheme? initial]) : _current = initial ?? BeloteThemes.classic;

  BeloteTheme get current => _current;

  void setTheme(BeloteTheme theme) {
    if (identical(theme, _current)) return;
    _current = theme;
    notifyListeners();
    _save(theme.name);
  }

  /// يستعيد الثيم المحفوظ (إن وُجد). يُستدعى عند الإقلاع. آمن: أي فشل يُتجاهل.
  Future<void> loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_prefKey);
      if (name == null) return;
      final saved = BeloteThemes.all.firstWhere(
        (t) => t.name == name,
        orElse: () => _current,
      );
      setTheme(saved);
    } catch (_) {/* لا تخزين متاح ⇒ يبقى الافتراضي */}
  }

  Future<void> _save(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, name);
    } catch (_) {/* يُتجاهل */}
  }
}

/// يوفّر [ThemeManager] للشجرة ويعيد بناء المستهلكين عند تبديل الثيم.
class ThemeScope extends InheritedNotifier<ThemeManager> {
  const ThemeScope({
    super.key,
    required ThemeManager manager,
    required super.child,
  }) : super(notifier: manager);

  static ThemeManager of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope غير موجود في الشجرة — غلِّف MaterialApp به.');
    return scope!.notifier!;
  }
}
