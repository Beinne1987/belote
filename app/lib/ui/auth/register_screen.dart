import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/countries.dart';
import '../../net/api_client.dart';
import '../../services/phone_auth.dart';
import '../../theme/belote_theme.dart';
import 'auth_common.dart';

/// إنشاء حساب ثلاثيّ المراحل:
///   ١) الهاتف → إرسال رمز OTP (Firebase) لتأكيد الرقم.
///   ٢) الرمز  → تحقّق ⇒ توكن هويّة Firebase.
///   ٣) التفاصيل → كلمة سرّ + اسم + دولة + مدينة ⇒ إنشاء الحساب على الخادم.
class RegisterScreen extends StatefulWidget {
  final ApiClient api;
  final Future<void> Function(AuthSession session) onAuthenticated;
  final VoidCallback onLogin;
  final PhoneAuthenticator? phoneAuth;

  const RegisterScreen({
    super.key,
    required this.api,
    required this.onAuthenticated,
    required this.onLogin,
    this.phoneAuth,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

enum _Phase { phone, code, details }

class _RegisterScreenState extends State<RegisterScreen> {
  late final PhoneAuthenticator _auth = widget.phoneAuth ?? PhoneAuthService();

  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _city = TextEditingController();

  _Phase _phase = _Phase.phone;
  Country _dial = kDefaultCountry;
  Country _country = kDefaultCountry;
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
    _name.dispose();
    _city.dispose();
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
    setState(() {
      _busy = true;
      _error = null;
    });
    final phone = toE164(_dial, _phone.text);
    await _auth.sendCode(
      phoneE164: phone,
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _sentPhone = phone;
          _phase = _Phase.code;
          _busy = false;
        });
      },
      onAutoVerified: (idToken) {
        if (!mounted) return;
        setState(() {
          _idToken = idToken;
          _phase = _Phase.details;
          _busy = false;
        });
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
      setState(() { _phase = _Phase.details; _busy = false; });
    } on PhoneAuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Future<void> _createAccount() async {
    if (_password.text.length < 6) {
      setState(() => _error = 'كلمة السرّ ٦ أحرف على الأقلّ');
      return;
    }
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'أدخل اسمك');
      return;
    }
    if (_city.text.trim().isEmpty) {
      setState(() => _error = 'أدخل مدينتك');
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final session = await widget.api.register(
        idToken: _idToken!,
        password: _password.text,
        displayName: _name.text.trim(),
        countryCode: _country.code,
        city: _city.text.trim(),
      );
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
      _Phase.phone => (Icons.person_add, 'إنشاء حساب', 'سنرسل رمزًا لتأكيد رقمك', 'إرسال الرمز', _sendCode),
      _Phase.code => (Icons.sms_outlined, 'رمز التأكيد', 'أدخل الرمز المُرسَل إلى $_sentPhone', 'تحقّق', _verifyCode),
      _Phase.details => (Icons.badge_outlined, 'أكمل حسابك', 'كلمة سرّ للدخول لاحقًا، واسمك ودولتك ومدينتك', 'إنشاء الحساب', _createAccount),
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
        _Phase.phone => [_phoneRow(t)],
        _Phase.code => [_codeField(t)],
        _Phase.details => _detailFields(t),
      },
      secondary: _phase == _Phase.phone
          ? [
              TextButton(
                onPressed: _busy ? null : widget.onLogin,
                child: Text('لديك حساب؟ سجّل الدخول',
                    style: TextStyle(color: t.accentBright, fontWeight: FontWeight.w700)),
              ),
            ]
          : const [],
    );
  }

  Widget _phoneRow(BeloteTheme t) => Row(
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
      );

  Widget _codeField(BeloteTheme t) => TextField(
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
      );

  List<Widget> _detailFields(BeloteTheme t) => [
        TextField(
          controller: _password,
          obscureText: _obscure,
          textAlign: TextAlign.center,
          style: TextStyle(color: t.text, fontSize: 18),
          cursorColor: t.accent,
          enabled: !_busy,
          decoration: authDecoration(t, 'كلمة السرّ (٦ أحرف على الأقلّ)',
              suffix: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: t.text3),
                onPressed: () => setState(() => _obscure = !_obscure),
              )),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          textAlign: TextAlign.center,
          maxLength: 24,
          style: TextStyle(color: t.text, fontSize: 18),
          cursorColor: t.accent,
          enabled: !_busy,
          decoration: authDecoration(t, 'الاسم').copyWith(counterText: ''),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _busy ? null : () async {
            final c = await pickCountry(context);
            if (c != null) setState(() => _country = c);
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.line),
            ),
            child: Row(
              children: [
                Text(_country.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(_country.ar, style: TextStyle(color: t.text, fontSize: 16)),
                const Spacer(),
                Icon(Icons.expand_more, color: t.text3),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _city,
          textAlign: TextAlign.center,
          maxLength: 32,
          style: TextStyle(color: t.text, fontSize: 18),
          cursorColor: t.accent,
          enabled: !_busy,
          decoration: authDecoration(t, 'المدينة / الولاية').copyWith(counterText: ''),
        ),
      ];
}
