import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_text.dart';
import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';

/// **شراءُ باقة ماسٍ ببنكيلي** — نفسُ خطوات B-PAY التي يعرفها الموريتانيّون:
///
///   ١. افتح بنكيلي ← B-PAY
///   ٢. أدخل **رمزَ التاجر** والمبلغ (يُنسَخان بنقرة)
///   ٣. يصلك رمزٌ من 4 أرقام
///   ٤. أدخل هنا رقمَ هاتفك والرمز ← تأكيد
///
/// **الرسومُ مرسومةٌ لا صور**: صورُ التطبيق المرجعيّ صغيرةٌ (576px) وتحمل رمزَ
/// تاجرٍ آخر. المرسومُ حادٌّ على كلّ شاشة، ويعرض **رمزَ التاجر الحاليّ من الخادم**
/// ومبلغَ الباقة المختارة — فتغييرُ الرمز من اللوحة لا يُكذّب شرحًا مصوَّرًا.
///
/// **«قريبًا» صادقة** (طلب المالك 2026-09-29): ما لم يعمل بنكيلي في الخادم تُعرَض
/// الخطواتُ كاملةً بشريطٍ يقول ذلك، وزرُّ التأكيد معطّلٌ بشارة «قريبًا» — ظاهرٌ
/// للّاعب ولمراجِع المتجر سواء، لا يُخفى ثمّ يُظهَر.
Future<void> showBankilySheet(
  BuildContext context, {
  required SessionController session,
  required DiamondPackView pack,
  required BankilyConfig config,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BeloteTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) =>
          _BankilySheet(session: session, pack: pack, config: config),
    );

class _BankilySheet extends StatefulWidget {
  final SessionController session;
  final DiamondPackView pack;
  final BankilyConfig config;
  const _BankilySheet(
      {required this.session, required this.pack, required this.config});

  @override
  State<_BankilySheet> createState() => _BankilySheetState();
}

class _BankilySheetState extends State<_BankilySheet> {
  static const _steps = 4;
  int _step = 0;
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  static final _phoneOk = RegExp(r'^[234]\d{7}$');
  static final _codeOk = RegExp(r'^\d{4}$');

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l = context.l10n;
    final phone = _phone.text.replaceAll(' ', '');
    final code = _code.text.trim();
    if (!_phoneOk.hasMatch(phone)) {
      setState(() => _error = l.bankilyErrPhone);
      return;
    }
    if (!_codeOk.hasMatch(code)) {
      setState(() => _error = l.bankilyErrCode);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final got = await widget.session.bankilyPay(widget.pack.id, phone, code);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        content: Text(l.bankilySuccess(got > 0 ? got : widget.pack.total)),
        duration: const Duration(seconds: 3),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = switch (e.message) {
            'bad_phone' => l.bankilyErrPhone,
            'bad_code' =>
              e.status == 402 ? l.bankilyErrRejected : l.bankilyErrCode,
            'bankily_soon' => l.bankilySoonBanner,
            'bankily_unreachable' => l.bankilyErrUnreachable,
            _ => e.status == 402 ? l.bankilyErrRejected : l.purchaseFailed,
          });
    } catch (_) {
      if (mounted) setState(() => _error = l.connectionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final l = context.l10n;
    final live = widget.config.live;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: t.line, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: t.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.bankilyTitle,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ),
                  if (!live) _SoonChip(t: t),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${l.bankilyYouGet(widget.pack.total)} · ${l.priceOuguiya(widget.pack.price)}',
                style: TextStyle(color: t.text2, fontSize: 13),
              ),
              if (!live) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: t.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.warning.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.schedule, size: 18, color: t.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l.bankilySoonBanner,
                            style: TextStyle(color: t.text2, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _StepDots(t: t, step: _step, count: _steps),
              const SizedBox(height: 6),
              Text(l.bankilyStepOf(_step + 1),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.text3, fontSize: 12)),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _stepBody(t, live),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.error, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _step == 0
                              ? Navigator.pop(context)
                              : setState(() {
                                  _step--;
                                  _error = null;
                                }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.text2,
                        side: BorderSide(color: t.lineStrong),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l.bankilyBack),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _step < _steps - 1
                        ? _primary(
                            t, l.bankilyNext, () => setState(() => _step++))
                        : _primary(
                            t,
                            live ? l.bankilyConfirm : l.bankilySoonBadge,
                            live && !_busy ? _confirm : null,
                            busy: _busy,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primary(BeloteTheme t, String label, VoidCallback? onTap,
          {bool busy = false}) =>
      FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          disabledBackgroundColor: t.surface2,
          disabledForegroundColor: t.text3,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: busy
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: t.onAccent))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      );

  Widget _stepBody(BeloteTheme t, bool live) {
    final l = context.l10n;
    final code = widget.config.merchantCode;
    final amount = '${widget.pack.price}';
    switch (_step) {
      case 0:
        return _StepCard(
          t: t,
          icon: Icons.phone_android,
          title: l.bankilyStep1Title,
          body: l.bankilyStep1Body,
          art: _PhoneMock(t: t, child: _HomeGridArt(t: t)),
        );
      case 1:
        return _StepCard(
          t: t,
          icon: Icons.edit_note,
          title: l.bankilyStep2Title,
          body: l.bankilyStep2Body,
          extra: Row(
            children: [
              Expanded(
                  child: _CopyBox(
                      t: t, label: l.bankilyMerchantCode, value: code)),
              const SizedBox(width: 10),
              Expanded(
                  child: _CopyBox(
                      t: t,
                      label: l.bankilyAmount,
                      value: amount,
                      suffix: 'MRU')),
            ],
          ),
          art: _PhoneMock(
              t: t, child: _FormArt(t: t, code: code, amount: amount)),
        );
      case 2:
        return _StepCard(
          t: t,
          icon: Icons.sms_outlined,
          title: l.bankilyStep3Title,
          body: l.bankilyStep3Body,
          art: _PhoneMock(t: t, child: _SmsArt(t: t)),
        );
      default:
        return _StepCard(
          t: t,
          icon: Icons.check_circle_outline,
          title: l.bankilyStep4Title,
          body: l.bankilyStep4Body,
          extra: Column(
            children: [
              _field(t, _phone, l.bankilyPhone, 8, enabled: live),
              const SizedBox(height: 10),
              _field(t, _code, l.bankilyCode, 4, enabled: live),
            ],
          ),
        );
    }
  }

  Widget _field(BeloteTheme t, TextEditingController c, String label, int max,
          {required bool enabled}) =>
      TextField(
        controller: c,
        enabled: enabled,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(max),
        ],
        textDirection: TextDirection.ltr, // الأرقام لاتينيّةٌ دائمًا
        textAlign: TextAlign.center,
        style: TextStyle(
            color: t.text,
            fontSize: 18,
            letterSpacing: 2,
            fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: t.text3),
          filled: true,
          fillColor: t.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.accent, width: 1.4),
          ),
        ),
      );
}

class _SoonChip extends StatelessWidget {
  final BeloteTheme t;
  const _SoonChip({required this.t});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: t.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.warning.withValues(alpha: 0.6)),
        ),
        child: Text(context.l10n.bankilySoonBadge,
            style: TextStyle(
                color: t.warning, fontSize: 11.5, fontWeight: FontWeight.w800)),
      );
}

class _StepDots extends StatelessWidget {
  final BeloteTheme t;
  final int step;
  final int count;
  const _StepDots({required this.t, required this.step, required this.count});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == step ? 26 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: i <= step ? t.accent : t.surface2,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: i <= step ? t.accent : t.line),
              ),
            ),
            if (i < count - 1) const SizedBox(width: 6),
          ],
        ],
      );
}

class _StepCard extends StatelessWidget {
  final BeloteTheme t;
  final IconData icon;
  final String title;
  final String body;
  final Widget? extra;
  final Widget? art;
  const _StepCard({
    required this.t,
    required this.icon,
    required this.title,
    required this.body,
    this.extra,
    this.art,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: t.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: t.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(body, style: TextStyle(color: t.text2, fontSize: 13)),
            if (extra != null) ...[const SizedBox(height: 12), extra!],
            if (art != null) ...[
              const SizedBox(height: 12),
              Center(child: art!),
            ],
          ],
        ),
      );
}

class _CopyBox extends StatelessWidget {
  final BeloteTheme t;
  final String label;
  final String value;
  final String? suffix;
  const _CopyBox(
      {required this.t, required this.label, required this.value, this.suffix});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${context.l10n.bankilyCopied}: $value',
                textAlign: TextAlign.center),
            duration: const Duration(seconds: 1),
          ));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.accent, width: 1.2),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(color: t.text3, fontSize: 11.5)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      suffix == null ? value : '$value $suffix',
                      textDirection: TextDirection.ltr,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.copy, size: 14, color: t.accent),
                ],
              ),
              // النسخُ بنقرةٍ لا يُكتشَف وحده — يُقال صراحةً (طلب المالك 2026-09-29).
              const SizedBox(height: 2),
              Text(context.l10n.bankilyTapToCopy,
                  style: TextStyle(color: t.accent, fontSize: 10.5)),
            ],
          ),
        ),
      );
}

// ── الرسوم: هاتفٌ مصغّرٌ يرسم شاشة بنكيلي المقصودة بلا صورٍ ولا شعارات ──

/// لونُ بنكيلي المميّز (سماويّ). **ثابتٌ عمدًا لا من الثيم**: الرسمُ يصف تطبيقًا
/// آخرَ كما يراه اللاعبُ على هاتفه، فلا يتبدّل بثيم لعبتنا.
const _bankilyTeal = Color(0xFF1EB5C9);

class _PhoneMock extends StatelessWidget {
  final BeloteTheme t;
  final Widget child;
  const _PhoneMock({required this.t, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 150,
        height: 220,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.lineStrong, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  height: 30,
                  color: _bankilyTeal,
                  alignment: Alignment.center,
                  child: const Text('Bankily',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      );
}

class _HomeGridArt extends StatelessWidget {
  final BeloteTheme t;
  const _HomeGridArt({required this.t});

  @override
  Widget build(BuildContext context) {
    Widget tile({bool hot = false}) => Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: hot
                ? t.accent.withValues(alpha: 0.18)
                : const Color(0xFFEFF3F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: hot ? t.accent : const Color(0xFFDCE3E7),
                width: hot ? 2 : 1),
          ),
          alignment: Alignment.center,
          child: hot
              ? const Text('B-PAY',
                  style: TextStyle(
                      color: _bankilyTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.w900))
              : const Icon(Icons.circle, size: 10, color: Color(0xFFC5D0D6)),
        );
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.25,
        children: [tile(), tile(), tile(), tile(), tile(), tile(hot: true)],
      ),
    );
  }
}

class _FormArt extends StatelessWidget {
  final BeloteTheme t;
  final String code;
  final String amount;
  const _FormArt({required this.t, required this.code, required this.amount});

  @override
  Widget build(BuildContext context) {
    Widget field(String hint, String v) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hint,
                  style:
                      const TextStyle(color: Color(0xFF6B7B84), fontSize: 8.5)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: _bankilyTeal, width: 1.4)),
                      ),
                      child: Text(v,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ),
                  Icon(Icons.arrow_back, size: 14, color: t.error),
                ],
              ),
            ],
          ),
        );
    return Directionality(
      textDirection:
          TextDirection.ltr, // شاشةُ بنكيلي فرنسيّةٌ كما يراها اللاعب
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('B-PAY',
                style: TextStyle(
                    color: _bankilyTeal,
                    fontWeight: FontWeight.w900,
                    fontSize: 11)),
            const SizedBox(height: 8),
            field('Code commerçant', code),
            field('Montant', amount),
            const Spacer(),
            Container(
              height: 18,
              decoration: BoxDecoration(
                  color: _bankilyTeal, borderRadius: BorderRadius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmsArt extends StatelessWidget {
  final BeloteTheme t;
  const _SmsArt({required this.t});

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sms, size: 18, color: _bankilyTeal),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bankily',
                        style: TextStyle(
                            color: _bankilyTeal,
                            fontWeight: FontWeight.w900,
                            fontSize: 10)),
                    SizedBox(height: 4),
                    Text('B-PAY code:',
                        style: TextStyle(color: Colors.black54, fontSize: 9)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: t.accent, width: 2),
                  ),
                  child: const Text('• • • •',
                      style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      );
}
