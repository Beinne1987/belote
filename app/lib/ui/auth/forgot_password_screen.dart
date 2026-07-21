import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/countries.dart';
import '../../net/api_client.dart';
import '../../services/phone_auth.dart';
import '../../theme/belote_theme.dart';
import 'auth_common.dart';

/// استعادة كلمة السرّ: هاتف → OTP (Firebase) لتأكيد الملكيّة → كلمة سرّ جديدة.
class ForgotPasswordScreen extends StatefulWidget {
  final ApiClient api;
  final Future<void> Function(AuthSession session) onAuthenticated;
  final PhoneAuthenticator? phoneAuth;

  const ForgotPasswordScreen({
    super.key,
    required this.api,
    required this.onAuthenticated,
    this.phoneAuth,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Phase { phone, code, password }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final PhoneAuthenticator _auth = widget.phoneAuth ?? PhoneAuthService();

  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  _Phase _phase = _Phase.phone;
  Country _dial = kDefaultCountry;
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String _sentPhone = '';
  String? _idToken;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final local = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (local.length < 6) {
      setState(() => _error = 'أدخل رقم هاتف صالحًا');
      return;
    }
    if (!_auth.supported) {
      setState(() => _error = 'الدخول بالهاتف غير مدعوم على هذه المنصّة');
      return;
    }
    setState(() { _busy = true; _error = null; });
    final phone = toE164(_dial, _phone.text);
    await _auth.sendCode(
      phoneE164: phone,
      onCodeSent: () {
        if (!mounted) return;
        setState(() { _sentPhone = phone; _phase = _Phase.code; _busy = false; });
      },
      onAutoVerified: (idToken) {
        if (!mounted) return;
        setState(() { _idToken = idToken; _phase = _Phase.password; _busy = false; });
      },
      onError: (msg) {
        if (mounted) setState(() { _error = msg; _busy = false; });
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_code.text.trim().length < 6) {
      setState(() => _error = 'أدخل الرمز المكوَّن من ٦ أرقام');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      _idToken = await _auth.verifyCode(_code.text.trim());
      if (!mounted) return;
      setState(() { _phase = _Phase.password; _busy = false; });
    } on PhoneAuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Future<void> _resetPassword() async {
    if (_password.text.length < 6) {
      setState(() => _error = 'كلمة السرّ ٦ أحرف على الأقلّ');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final session = await widget.api.resetPassword(idToken: _idToken!, password: _password.text);
      if (!mounted) return;
      await widget.onAuthenticated(session);
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final (icon, title, subtitle, label, action) = switch (_phase) {
      _Phase.phone => (Icons.lock_reset, 'استعادة كلمة السرّ', 'أدخل رقمك لنرسل رمز تأكيد', 'إرسال الرمز', _sendCode),
      _Phase.code => (Icons.sms_outlined, 'رمز التأكيد', 'أدخل الرمز المُرسَل إلى $_sentPhone', 'تحقّق', _verifyCode),
      _Phase.password => (Icons.password, 'كلمة سرّ جديدة', 'اختر كلمة سرّ جديدة لحسابك', 'حفظ ودخول', _resetPassword),
    };
    return AuthScaffold(
      icon: icon,
      title: title,
      subtitle: subtitle,
      busy: _busy,
      error: _error,
      primaryLabel: label,
      onPrimary: action,
      fields: switch (_phase) {
        _Phase.phone => [
            Row(
              textDirection: TextDirection.ltr,
              children: [
                DialButton(country: _dial, enabled: !_busy, onPicked: (c) => setState(() => _dial = c)),
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
                    onSubmitted: (_) => _sendCode(),
                    decoration: authDecoration(t, 'رقم الهاتف'),
                  ),
                ),
              ],
            ),
          ],
        _Phase.code => [
            TextField(
              controller: _code,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              style: TextStyle(color: t.text, fontSize: 24, letterSpacing: 8),
              cursorColor: t.accent,
              enabled: !_busy,
              onSubmitted: (_) => _verifyCode(),
              decoration: authDecoration(t, '••••••').copyWith(counterText: ''),
            ),
          ],
        _Phase.password => [
            TextField(
              controller: _password,
              obscureText: _obscure,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.text, fontSize: 18),
              cursorColor: t.accent,
              enabled: !_busy,
              onSubmitted: (_) => _resetPassword(),
              decoration: authDecoration(t, 'كلمة السرّ الجديدة',
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: t.text3),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )),
            ),
          ],
      },
    );
  }
}
