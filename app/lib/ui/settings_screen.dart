import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_settings.dart';
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
              const SimpleTopBar(title: 'الإعدادات'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _tile(
                      t,
                      icon: Icons.person,
                      title: 'الاسم',
                      trailing: Text(s.name,
                          style: TextStyle(color: t.text2, fontSize: 14)),
                      onTap: () => _editName(context, s),
                    ),
                    _tile(
                      t,
                      icon: Icons.palette_outlined,
                      title: 'الثيم',
                      trailing: Icon(Icons.chevron_left, color: t.text3),
                      onTap: () => showThemeSheet(context),
                    ),
                    _switchTile(
                      t,
                      icon: Icons.volume_up,
                      title: 'الصوت',
                      value: s.soundOn,
                      onChanged: s.setSound,
                    ),
                    _tile(
                      t,
                      icon: Icons.menu_book,
                      title: 'كيف تلعب',
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
                Text('الإصدار $v',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: t.text3, fontSize: 12)),
              ],
            ),
          );
        },
      );

  void _editName(BuildContext context, AppSettings s) {
    final controller = TextEditingController(text: s.name);
    final t = BeloteTheme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('الاسم', style: TextStyle(color: t.text)),
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
            child: Text('إلغاء', style: TextStyle(color: t.text3)),
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
            child: const Text('حفظ'),
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
        ..showSnackBar(const SnackBar(
          content: Text('تعذّر الفتح على هذا الجهاز.', textAlign: TextAlign.center),
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
          child: Text('الدعم الفنّي',
              style: TextStyle(
                  color: t.text2, fontSize: 13, fontWeight: FontWeight.w800)),
        ),
        if (_whatsapp.isNotEmpty)
          tile(
            icon: Icons.chat,
            title: 'واتساب',
            subtitle: '+$_whatsapp',
            onTap: () => _open(Uri.parse('https://wa.me/$_whatsapp')),
          ),
        if (_email.isNotEmpty)
          tile(
            icon: Icons.mail_outline,
            title: 'البريد الإلكتروني',
            subtitle: _email,
            onTap: () => _open(Uri(scheme: 'mailto', path: _email)),
          ),
      ],
    );
  }
}
