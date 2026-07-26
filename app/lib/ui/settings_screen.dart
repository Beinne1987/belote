import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_settings.dart';
import '../l10n/app_text.dart';
import '../net/api_client.dart';
import '../theme/belote_theme.dart';
import 'rules_screen.dart';
import 'simple_top_bar.dart';
import 'theme_switch.dart';

/// شاشة الإعدادات — تعديل الاسم، الثيم، الصوت، ومعلومات الإصدار.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final l = context.l10n;
    final s = AppSettingsScope.of(context);
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
          child: Column(
            children: [
              SimpleTopBar(title: l.settingsTitle),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _tile(
                      t,
                      icon: Icons.person,
                      title: l.settingsName,
                      trailing: Text(s.name,
                          style: TextStyle(color: t.text2, fontSize: 14)),
                      onTap: () => _editName(context, s),
                    ),
                    _tile(
                      t,
                      icon: Icons.palette_outlined,
                      title: l.settingsTheme,
                      trailing: Icon(Icons.chevron_left, color: t.text3),
                      onTap: () => showThemeSheet(context),
                    ),
                    _tile(
                      t,
                      icon: Icons.language,
                      title: l.settingsLanguage,
                      trailing: Text(
                        s.locale.languageCode == 'fr'
                            ? l.settingsLanguageFrench
                            : l.settingsLanguageArabic,
                        style: TextStyle(color: t.text2, fontSize: 14),
                      ),
                      onTap: () => _pickLanguage(context, s),
                    ),
                    _switchTile(
                      t,
                      icon: Icons.volume_up,
                      title: l.settingsSound,
                      value: s.soundOn,
                      onChanged: s.setSound,
                    ),
                    _tile(
                      t,
                      icon: Icons.menu_book,
                      title: l.howToPlay,
                      trailing: Icon(Icons.chevron_left, color: t.text3),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const RulesScreen())),
                    ),
                    // **الدعم الفنّي** (طلب المالك 2026-07-17): القنوات تصل من
                    // الخادم — ما لم يجهز منها لا يُعرَض، فلا زرَّ ميّتًا أبدًا.
                    const _SupportSection(),
                    const SizedBox(height: 10),
                    _about(t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BeloteTheme t,
          {required IconData icon,
          required String title,
          required Widget trailing,
          required VoidCallback onTap}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.line),
        ),
        child: ListTile(
          leading: Icon(icon, color: t.accent),
          title: Text(title, style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
          trailing: trailing,
          onTap: onTap,
        ),
      );

  Widget _switchTile(BeloteTheme t,
          {required IconData icon,
          required String title,
          required bool value,
          required ValueChanged<bool> onChanged}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.line),
        ),
        child: SwitchListTile(
          secondary: Icon(icon, color: t.accent),
          title: Text(title, style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
          value: value,
          activeThumbColor: t.accent,
          onChanged: onChanged,
        ),
      );

  Widget _about(BeloteTheme t) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snap) {
          final v = snap.hasData
              ? '${snap.data!.version} (${snap.data!.buildNumber})'
              : '—';
          return Center(
            child: Column(
              children: [
                Text('Belote',
                    style: TextStyle(
                        color: t.text2, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(context.l10n.appVersion(v),
                    style: TextStyle(color: t.text3, fontSize: 12)),
              ],
            ),
          );
        },
      );

  /// **اختيارُ اللغة** — عربيّةٌ أو فرنسيّة. يُحفَظ فورًا ويُعاد بناءُ التطبيق
  /// كلِّه (الاتّجاهُ معه): لا إعادةَ تشغيلٍ ولا تأكيد.
  void _pickLanguage(BuildContext context, AppSettings s) {
    final t = BeloteTheme.of(context);
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(l.settingsLanguage,
                  style: TextStyle(
                      color: t.text, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            for (final locale in AppSettings.supportedLocales)
              ListTile(
                leading: Icon(
                  locale.languageCode == s.locale.languageCode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: t.accent,
                ),
                // **كلُّ لغةٍ باسمها في لغتها**: من يبحث عن الفرنسيّة يقرأ
                // «Français» ولو كانت الواجهةُ عربيّة، والعكس.
                title: Text(
                  locale.languageCode == 'fr'
                      ? 'Français'
                      : context.l10n.languageArabicNative,
                  textDirection: locale.languageCode == 'fr'
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                  style: TextStyle(color: t.text, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  s.setLocale(locale);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context, AppSettings s) {
    final controller = TextEditingController(text: s.name);
    final t = BeloteTheme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text(context.l10n.settingsName,
            style: TextStyle(color: t.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: TextStyle(color: t.text),
          cursorColor: t.accent,
          decoration: InputDecoration(
            counterText: '',
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: t.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel,
                style: TextStyle(color: t.text3)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: t.accent, foregroundColor: t.onAccent),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                s.setName(controller.text);
              }
              Navigator.pop(ctx);
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }
}

/// **قسم الدعم الفنّي** (طلب المالك 2026-07-17): واتساب وبريد. القيم من الخادم
/// (`GET /support`) ⇒ يومَ تجهز الوسائلُ تُضبَط في بيئة الخادم بلا تحديث تطبيق.
/// لا قيمَ بعد ⇒ لا قسمَ أصلًا: زرُّ دعمٍ لا يفتح شيئًا أسوأُ من غيابه.
class _SupportSection extends StatefulWidget {
  const _SupportSection();

  @override
  State<_SupportSection> createState() => _SupportSectionState();
}

class _SupportSectionState extends State<_SupportSection> {
  String _whatsapp = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ApiClient().support();
      if (mounted) {
        setState(() {
          _whatsapp = s.whatsapp;
          _email = s.email;
        });
      }
    } catch (_) {
      // شبكةٌ غائبة ⇒ يبقى القسم مخفيًّا — الإعدادات تعمل بلا دعم.
    }
  }

  /// يفتح رابطًا خارجيًّا؛ الفشل (لا واتساب على الجهاز مثلًا) يُقال بصدق.
  Future<void> _open(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(context.l10n.openFailed,
              textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_whatsapp.isEmpty && _email.isEmpty) return const SizedBox.shrink();
    final t = BeloteTheme.of(context);

    Widget tile(
            {required IconData icon,
            required String title,
            required String subtitle,
            required VoidCallback onTap}) =>
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.line),
          ),
          child: ListTile(
            leading: Icon(icon, color: t.accent),
            title: Text(title,
                style: TextStyle(color: t.text, fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                style: TextStyle(color: t.text3, fontSize: 12)),
            trailing: Icon(Icons.open_in_new, size: 18, color: t.text3),
            onTap: onTap,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Text(context.l10n.supportSection,
              style: TextStyle(
                  color: t.text2, fontSize: 13, fontWeight: FontWeight.w800)),
        ),
        if (_whatsapp.isNotEmpty)
          tile(
            icon: Icons.chat,
            title: context.l10n.supportWhatsapp,
            subtitle: '+$_whatsapp',
            onTap: () => _open(Uri.parse('https://wa.me/$_whatsapp')),
          ),
        if (_email.isNotEmpty)
          tile(
            icon: Icons.mail_outline,
            title: context.l10n.supportEmail,
            subtitle: _email,
            onTap: () => _open(Uri(scheme: 'mailto', path: _email)),
          ),
      ],
    );
  }
}
