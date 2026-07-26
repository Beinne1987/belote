import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_text.dart';
import '../theme/belote_theme.dart';
import 'simple_top_bar.dart';

/// «حول اللعبة» — تعريفٌ ببيلوت، ومن برمجها، وإصدارُ التطبيق.
///
/// **الإصدارُ يُقرأ من الحزمة لا يُكتَب بيد**: رقمٌ مكتوبٌ في الكود يشيخ بلا أن
/// ينتبه أحد، فيبلّغ اللاعبُ عن عطلٍ في إصدارٍ غير الذي بين يديه.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          child: Column(
            children: [
              SimpleTopBar(title: context.l10n.navAbout),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          _emblem(context, t),
                          const SizedBox(height: 12),
                          Text(context.l10n.aboutGameTitle,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(context.l10n.aboutMauritanianEdition,
                              style: TextStyle(color: t.accent, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _card(
                      t,
                      icon: Icons.menu_book,
                      title: context.l10n.aboutSection,
                      child: Text(
                        context.l10n.aboutBody,
                        style: TextStyle(
                            color: t.text2, fontSize: 14.5, height: 1.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(
                      t,
                      icon: Icons.person,
                      title: context.l10n.aboutDevSection,
                      child: Text(
                        context.l10n.developerName,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _versionCard(t),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(context.l10n.aboutMadeWithLove,
                          style: TextStyle(color: t.text3, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// شعارُ التطبيق نفسُه داخل قرصٍ ذهبيّ — وإن تعذّرت الصورة فحرفُ «ب».
  ///
  /// **الصورةُ تُقَصُّ دائريّةً وتملأ القرص** (`ClipOval` + `cover`) لا تُحشَر
  /// مربّعةً فيه: كانت `contain` مع حشوةٍ تضع مربّعًا في دائرةٍ فتُطلّ أركانُه
  /// والتدرّجُ من خلفه (بلاغُ المالك بعد تبديل الأيقونة). القصُّ الدائريُّ
  /// آمنٌ على هذا الماستر — هو نفسُه قناعُ أندرويد الدائريّ ومروحةُ الآسات
  /// كاملةٌ داخله. والتدرّجُ يبقى **حَلَقةً** حولها لا خلفَها.
  Widget _emblem(BuildContext context, BeloteTheme t) => Container(
        width: 92,
        height: 92,
        padding: const EdgeInsets.all(3), // ثخنُ الحَلَقة
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [t.accentBright, t.accentDeep]),
          boxShadow: [
            BoxShadow(color: t.shadow, blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/icon/icon.png',
            fit: BoxFit.cover,
            width: 86,
            height: 86,
            errorBuilder: (_, __, ___) => Center(
              child: Text(context.l10n.appInitial,
                  style: TextStyle(
                      color: t.onAccent,
                      fontSize: 44,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      );

  Widget _versionCard(BeloteTheme t) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snap) => _card(
          t,
          icon: Icons.verified,
          title: context.l10n.aboutVersionSection,
          child: Text(
            snap.hasData
                ? '${snap.data!.version} (${snap.data!.buildNumber})'
                : '…',
            // الأرقام لاتينيّة دائمًا (عُرف المشروع).
            textDirection: TextDirection.ltr,
            style: TextStyle(
                color: t.text, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      );

  Widget _card(BeloteTheme t,
          {required IconData icon,
          required String title,
          required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: t.accent, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}
