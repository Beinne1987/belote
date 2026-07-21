import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/countries.dart';
import '../../net/api_client.dart';
import '../../theme/belote_theme.dart';
import 'auth_common.dart';

/// تسجيل الدخول العاديّ: هاتف + كلمة سرّ — بلا OTP. عند النجاح [onAuthenticated].
/// [onRegister]/[onForgot] للانتقال لإنشاء حساب أو استعادة كلمة السرّ.
class LoginScreen extends StatefulWidget {
  final ApiClient api;
  final Future<void> Function(AuthSession session) onAuthenticated;
  final VoidCallback onRegister;
  final VoidCallback onForgot;

  const LoginScreen({
    super.key,
    required this.api,
    required this.onAuthenticated,
    required this.onRegister,
    required this.onForgot,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  Country _dial = kDefaultCountry;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final local = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (local.length < 6) {
      setState(() => _error = 'أدخل رقم هاتف صالحًا');
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'أدخل كلمة السرّ');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await widget.api.login(toE164(_dial, _phone.text), _password.text);
      if (!mounted) return;
      await widget.onAuthenticated(session);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return AuthScaffold(
      icon: Icons.login,
      title: 'تسجيل الدخول',
      subtitle: 'ادخل برقم هاتفك وكلمة السرّ',
      busy: _busy,
      error: _error,
      primaryLabel: 'دخول',
      onPrimary: _login,
      fields: [
        Row(
          textDirection: TextDirection.ltr,
          children: [
            _dialButton(t),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phone,
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: t.text, fontSize: 18, letterSpacing: 1.2),
                cursorColor: t.accent,
                enabled: !_busy,
                decoration: authDecoration(t, 'رقم الهاتف'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          textAlign: TextAlign.center,
          style: TextStyle(color: t.text, fontSize: 18),
          cursorColor: t.accent,
          enabled: !_busy,
          onSubmitted: (_) => _login(),
          decoration: authDecoration(t, 'كلمة السرّ',
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: t.text3),
                onPressed: () => setState(() => _obscure = !_obscure),
              )),
        ),
      ],
      secondary: [
        TextButton(
          onPressed: _busy ? null : widget.onForgot,
          child: Text('نسيت كلمة السرّ؟', style: TextStyle(color: t.text2)),
        ),
        TextButton(
          onPressed: _busy ? null : widget.onRegister,
          child: Text('ليس لديك حساب؟ أنشئ حسابًا',
              style: TextStyle(color: t.accentBright, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _dialButton(BeloteTheme t) => InkWell(
        onTap: _busy ? null : () async {
          final c = await pickCountry(context);
          if (c != null) setState(() => _dial = c);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.line),
          ),
          child: Text('${_dial.flag} +${_dial.dial}', style: TextStyle(color: t.text, fontSize: 16)),
        ),
      );
}
