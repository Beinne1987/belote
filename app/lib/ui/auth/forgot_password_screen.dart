import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/countries.dart';
import '../../net/api_client.dart';
import '../../services/phone_auth.dart';
import '../../l10n/app_text.dart';
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

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with ResendCountdown {
  late final PhoneAuthenticator _auth =
      widget.phoneAuth ?? RoutedPhoneAuth.standard(widget.api, OtpPurpose.reset);

  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  _Phase _phase = _Phase.phone;
  Country _dial = kDefaultCountry;
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
    setState(() { _busy = true; _error = null; });
    await _auth.sendCode(
      phoneE164: phone,
      channel: channel,
      resend: resend,
      onCodeSent: () {
        if (!mounted) return;
        startResendCountdown();
        setState(() { _sentPhone = phone; _phase = _Phase.code; _busy = false; });
      },
      onAutoVerified: (credential) {
        if (!mounted) return;
        setState(() { _credential = credential; stopResendCountdown(); _phase = _Phase.password; _busy = false; });
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
      setState(() { _phase = _Phase.password; _busy = false; });
    } on PhoneAuthException catch (e) {
      if (mounted) setState(() { _error = e.message; _busy = false; });
    }
  }

  Future<void> _resetPassword() async {
    if (_password.text.length < 6) {
      setState(() => _error = context.l10n.passwordTooShort);
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      final session = await widget.api.resetPassword(credential: _credential!, password: _password.text);
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
          Icons.lock_reset,
          l.resetPasswordTitle,
          l.resetPasswordSub,
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
      _Phase.password => (
          Icons.password,
          l.newPasswordTitle,
          l.newPasswordSub,
          l.saveAndSignIn,
          _resetPassword
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
      secondary: switch (_phase) {
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
                    decoration: authDecoration(t, context.l10n.fieldPhone),
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
              decoration: authDecoration(t, l.fieldNewPassword,
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
