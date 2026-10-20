import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/countries.dart';
import '../../net/api_client.dart';
import '../../services/phone_auth.dart';
import '../../l10n/app_text.dart';
import '../../theme/belote_theme.dart';
import 'auth_common.dart';

/// إنشاء حساب ثلاثيّ المراحل:
///   ١) الهاتف → إرسال رمز OTP لتأكيد الرقم (+222 عبر خادمنا/ChinqIT، غيره Firebase).
///   ٢) الرمز  → تحقّق ⇒ إثباتُ الهاتف (PhoneCredential).
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

class _RegisterScreenState extends State<RegisterScreen> with ResendCountdown {
  late final PhoneAuthenticator _auth =
      widget.phoneAuth ?? RoutedPhoneAuth.standard(widget.api, OtpPurpose.register);

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
  PhoneCredential? _credential;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _sendCode({OtpChannel channel = OtpChannel.sms, bool resend = false}) async {
    final local = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (local.length < 6) {
      setState(() => _error = context.l10n.invalidPhone);
      return;
    }
    final phone = toE164(_dial, _phone.text);
    if (!_auth.supportsPhone(phone)) {
      setState(() => _error = context.l10n.phoneAuthUnsupported);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    await _auth.sendCode(
      phoneE164: phone,
      channel: channel,
      resend: resend,
      onCodeSent: () {
        if (!mounted) return;
        startResendCountdown();
        setState(() {
          _sentPhone = phone;
          _phase = _Phase.code;
          _busy = false;
        });
      },
      onAutoVerified: (credential) {
        if (!mounted) return;
        setState(() {
          _credential = credential; stopResendCountdown();
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
      setState(() => _error = context.l10n.enterSixDigitCode);
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      _credential = await _auth.verifyCode(_code.text.trim());
      if (!mounted) return;
      stopResendCountdown();
      setState(() { _phase = _Phase.details; _busy = false; });
    } on PhoneAuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Future<void> _createAccount() async {
    if (_password.text.length < 6) {
      setState(() => _error = context.l10n.passwordTooShort);
      return;
    }
    if (_name.text.trim().isEmpty) {
      setState(() => _error = context.l10n.enterYourName);
      return;
    }
    if (_city.text.trim().isEmpty) {
      setState(() => _error = context.l10n.enterYourCity);
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final session = await widget.api.register(
        credential: _credential!,
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
    final l = context.l10n;
    final (icon, title, subtitle, label, action) = switch (_phase) {
      _Phase.phone => (
          Icons.person_add,
          l.createAccount,
          l.registerPhoneSub,
          l.sendCode,
          () => _sendCode()
        ),
      _Phase.code => (
          Icons.sms_outlined,
          l.codeTitle,
          l.codeSentTo(_sentPhone),
          l.verify,
          _verifyCode
        ),
      _Phase.details => (
          Icons.badge_outlined,
          l.completeAccount,
          l.completeAccountSub,
          l.createAccountAction,
          _createAccount
        ),
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
      secondary: switch (_phase) {
        _Phase.phone => [
              TextButton(
                onPressed: _busy ? null : widget.onLogin,
                child: Text(l.haveAccountSignIn,
                    style: TextStyle(color: t.accentBright, fontWeight: FontWeight.w700)),
              ),
            ],
        _Phase.code => resendActions(
          context,
          secondsLeft: resendLeft,
          busy: _busy,
          onResend: () => _sendCode(resend: true),
          onWhatsApp: _auth.supportsWhatsApp(_sentPhone)
              ? () => _sendCode(channel: OtpChannel.whatsapp, resend: true)
              : null,
        ),
        _ => const <Widget>[],
      },
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
              decoration: authDecoration(t, context.l10n.fieldPhone),
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

  List<Widget> _detailFields(BeloteTheme t) {
    final l = context.l10n;
    return [
        TextField(
          controller: _password,
          obscureText: _obscure,
          textAlign: TextAlign.center,
          style: TextStyle(color: t.text, fontSize: 18),
          cursorColor: t.accent,
          enabled: !_busy,
          decoration: authDecoration(t, l.fieldPasswordMin,
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
          decoration: authDecoration(t, l.fieldName).copyWith(counterText: ''),
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
                Text(
                    _country.nameIn(Localizations.localeOf(context).languageCode),
                    style: TextStyle(color: t.text, fontSize: 16)),
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
          decoration: authDecoration(t, l.fieldCity).copyWith(counterText: ''),
        ),
    ];
  }
}
