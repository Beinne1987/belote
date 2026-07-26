import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sfx.dart';

/// إعدادات محلّية للمستخدم (بلا خادم بعد): اسم اللاعب وحالة الصوت. تُحفظ/تُستعاد
/// عبر `shared_preferences`، وتُخطر عند التغيير. متاحة للشجرة عبر [AppSettingsScope].
/// عند وصول الخادم (الإبيك) يُرحَّل الاسم إلى الحساب.
class AppSettings extends ChangeNotifier {
  static const _kName = 'player_name';
  static const _kSound = 'sound_on';
  static const _kGuest = 'guest_mode';
  static const _kLocale = 'locale';

  /// اللغاتُ المدعومة — **العربيّةُ أوّلًا وهي الافتراض**.
  static const supportedLocales = [Locale('ar'), Locale('fr')];

  String _name = '';
  bool _soundOn = true;
  bool _guest = false;
  bool _loaded = false;
  Locale _locale = supportedLocales.first;

  /// لغةُ الواجهة المختارة. لا تسقط إلى لغة النظام: العربيّةُ هي الافتراضُ
  /// المعلَن، وتبديلُها قرارُ اللاعب لا قرارُ هاتفه.
  Locale get locale => _locale;

  String get name => _name;
  bool get soundOn => _soundOn;
  bool get loaded => _loaded;
  bool get needsName => _name.trim().isEmpty;

  /// وضع الضيف: يلعب محليًّا فقط (لا أونلاين). يُضبط عند اختيار «الدخول كضيف»،
  /// ويُلغى عند إنشاء حساب/تسجيل الدخول. الأونلاين يطلب من الضيف إنشاء حساب.
  bool get isGuest => _guest;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _name = p.getString(_kName) ?? '';
      _soundOn = p.getBool(_kSound) ?? true;
      _guest = p.getBool(_kGuest) ?? false;
      final code = p.getString(_kLocale);
      if (code != null) {
        _locale = supportedLocales.firstWhere(
          (l) => l.languageCode == code,
          orElse: () => _locale,
        );
      }
      Sfx.instance.enabled = _soundOn;
    } catch (_) {/* لا تخزين ⇒ افتراضيات */}
    _loaded = true;
    notifyListeners();
  }

  /// يُفعّل وضع الضيف (بعد إدخال اسمٍ محلّي). يُلغى بـ [clearGuest] عند المصادقة.
  void setGuest(bool on) {
    if (on == _guest) return;
    _guest = on;
    notifyListeners();
    _save();
  }

  /// يبدّل لغةَ الواجهة ويحفظها. تغييرٌ فوريّ: الشجرةُ كلُّها تُعاد بناءً.
  void setLocale(Locale value) {
    if (value.languageCode == _locale.languageCode) return;
    _locale = value;
    notifyListeners();
    _save();
  }

  void setName(String value) {
    final v = value.trim();
    if (v == _name) return;
    _name = v;
    notifyListeners();
    _save();
  }

  void setSound(bool on) {
    if (on == _soundOn) return;
    _soundOn = on;
    Sfx.instance.enabled = on;
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kName, _name);
      await p.setBool(_kSound, _soundOn);
      await p.setBool(_kGuest, _guest);
      await p.setString(_kLocale, _locale.languageCode);
    } catch (_) {/* يُتجاهل */}
  }
}

/// يوفّر [AppSettings] للشجرة ويعيد بناء المستهلكين عند التغيير.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope غير موجود في الشجرة.');
    return scope!.notifier!;
  }
}
