import 'package:flutter/material.dart';

import '../../data/countries.dart';
import '../../theme/belote_theme.dart';

/// يبني رقم E.164 من بادئة الدولة والأرقام المُدخَلة (يُسقط غير الأرقام والأصفار البادئة).
String toE164(Country dial, String local) {
  final d = local.replaceAll(RegExp(r'[^0-9]'), '').replaceAll(RegExp(r'^0+'), '');
  return '+${dial.dial}$d';
}

/// تنسيق حقلٍ موحَّد لشاشات المصادقة.
InputDecoration authDecoration(BeloteTheme t, String hint, {Widget? suffix}) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: t.text3),
      filled: true,
      fillColor: t.surface,
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.accent, width: 1.6),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: t.line),
      ),
    );

/// نافذةٌ سفليّة لاختيار بلد ⇒ يُعيد البلد المُختار أو null.
Future<Country?> pickCountry(BuildContext context) {
  final t = BeloteTheme.of(context);
  return showModalBottomSheet<Country>(
    context: context,
    backgroundColor: t.gradBottom,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: kCountries.length,
          itemBuilder: (_, i) {
            final c = kCountries[i];
            return ListTile(
              leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
              title: Text(c.ar, style: TextStyle(color: t.text)),
              trailing: Text('+${c.dial}', style: TextStyle(color: t.text3)),
              onTap: () => Navigator.of(context).pop(c),
            );
          },
        ),
      ),
    ),
  );
}

/// زرّ بادئة الدولة (علم + رمز الاتّصال) يفتح لائحة الدول ويُبلّغ الاختيار.
class DialButton extends StatelessWidget {
  final Country country;
  final bool enabled;
  final ValueChanged<Country> onPicked;

  const DialButton({super.key, required this.country, required this.onPicked, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return InkWell(
      onTap: enabled
          ? () async {
              final c = await pickCountry(context);
              if (c != null) onPicked(c);
            }
          : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.line),
        ),
        child: Text('${country.flag} +${country.dial}', style: TextStyle(color: t.text, fontSize: 16)),
      ),
    );
  }
}

/// هيكل موحَّد لشاشات المصادقة: خلفية متدرّجة + أيقونة + عنوان + وصف + محتوى +
/// رسالة خطأ + زرّ رئيسيّ + روابط ثانويّة. الشاشات تُمرّر الحقول فقط.
class AuthScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> fields;
  final String? error;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool busy;
  final List<Widget> secondary;

  const AuthScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.primaryLabel,
    required this.onPrimary,
    this.error,
    this.busy = false,
    this.secondary = const [],
  });

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
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward, color: t.text2),
                  tooltip: 'رجوع',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: t.accentBright, size: 48),
                      const SizedBox(height: 10),
                      Text(title,
                          style: TextStyle(
                              color: t.text, fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: t.text2, fontSize: 14)),
                      const SizedBox(height: 24),
                      ...fields,
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: t.error, fontSize: 13.5)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: busy ? null : onPrimary,
                          style: FilledButton.styleFrom(
                            backgroundColor: t.accent,
                            foregroundColor: t.onAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: busy
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4, color: t.onAccent),
                                )
                              : Text(primaryLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                      ...secondary,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
