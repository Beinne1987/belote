import 'package:flutter/material.dart';

import '../../net/api_client.dart';
import '../../services/phone_auth.dart';
import '../../theme/belote_theme.dart';
import '../name_entry_screen.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// أوّل شاشة للاعبٍ غير مصادَق: **تسجيل الدخول · إنشاء حساب · الدخول كضيف**.
/// المصادقة الناجحة ⇒ [onAuthenticated] (يحفظ الجلسة ويعود للرئيسية). الضيف ⇒
/// اسمٌ محلّيّ ثمّ وضع ضيف (يلعب محليًّا، والأونلاين يطلب إنشاء حساب).
class AuthLandingScreen extends StatelessWidget {
  final ApiClient api;
  final Future<void> Function(AuthSession session) onAuthenticated;

  const AuthLandingScreen({super.key, required this.api, required this.onAuthenticated});

  void _push(BuildContext c, Widget screen, {bool replace = false}) {
    final route = MaterialPageRoute<void>(builder: (_) => screen);
    if (replace) {
      Navigator.of(c).pushReplacement(route);
    } else {
      Navigator.of(c).push(route);
    }
  }

  Widget _login(BuildContext c) => LoginScreen(
        api: api,
        onAuthenticated: onAuthenticated,
        onRegister: () => _push(c, _register(c), replace: true),
        onForgot: () => _push(c, ForgotPasswordScreen(api: api, onAuthenticated: onAuthenticated)),
      );

  Widget _register(BuildContext c) => RegisterScreen(
        api: api,
        onAuthenticated: onAuthenticated,
        onLogin: () => _push(c, _login(c), replace: true),
      );

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.gradTop, t.gradBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [t.accentBright, t.accent, t.accentDeep],
                    ).createShader(r),
                    child: const Text('Belote',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2,
                        )),
                  ),
                  const SizedBox(height: 6),
                  Text('العب مع أصدقائك حول العالم',
                      style: TextStyle(color: t.text2, fontSize: 15)),
                  const SizedBox(height: 36),
                  _primary(t, 'تسجيل الدخول', () => _push(context, _login(context))),
                  const SizedBox(height: 12),
                  _outlined(t, 'إنشاء حساب', () => _push(context, _register(context))),
                  // **الحقيقةُ قبل المحاولة، لا بعدها.** إنشاءُ الحساب واستعادةُ
                  // كلمة السرّ يمرّان برمز SMS من Firebase Phone Auth — ولا
                  // تنفيذَ له على ويندوز/ماك. بلا هذا السطر يملأ اللاعبُ
                  // بياناتِه كلَّها ثمّ يصطدم بـ«غير مدعوم» بلا مخرج.
                  // **والدخولُ نفسُه يعمل** (هاتفٌ وكلمةُ سرّ، بلا رمز).
                  if (!PhoneAuthService.isSupported) ...[
                    const SizedBox(height: 10),
                    Text(
                      'إنشاءُ الحساب واستعادةُ كلمة السرّ يحتاجان رمزًا بالرسائل ⇒ '
                      'من تطبيق الهاتف. وتسجيلُ الدخول هنا يعمل كاملًا.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.text2, fontSize: 12.5, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () =>
                        _push(context, const NameEntryScreen(guest: true)),
                    child: Text('الدخول كضيف',
                        style: TextStyle(color: t.text2, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _primary(BeloteTheme t, String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: t.accent,
            foregroundColor: t.onAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      );

  Widget _outlined(BeloteTheme t, String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: t.text,
            side: BorderSide(color: t.accent, width: 1.4),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      );
}
