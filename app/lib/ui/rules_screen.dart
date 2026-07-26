import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../theme/belote_theme.dart';
import 'simple_top_bar.dart';

/// شاشة «كيف تلعب» — ملخّص قواعد بيلوت الموريتانية (من docs/RULES.md). عرضٌ محض.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  /// أقسامُ الشاشة — الأيقونةُ ثابتةٌ والنصُّ من لغة اللاعب.
  static List<(IconData, String, String)> _sections(AppLocalizations l) => [
        (Icons.groups, l.ruleBasicsTitle, l.ruleBasicsBody),
        (Icons.style, l.ruleDealTitle, l.ruleDealBody),
        (Icons.campaign, l.ruleBidTitle, l.ruleBidBody),
        (Icons.flash_on, l.ruleAkwinsTitle, l.ruleAkwinsBody),
        (Icons.rule, l.rulePlayTitle, l.rulePlayBody),
        (Icons.calculate, l.ruleUnitsTitle, l.ruleUnitsBody),
        (Icons.gavel, l.ruleFoujaTitle, l.ruleFoujaBody),
        (Icons.emoji_events, l.ruleWinTitle, l.ruleWinBody),
      ];

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final l = context.l10n;
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
              SimpleTopBar(title: l.howToPlay),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [for (final s in _sections(l)) _card(t, s)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BeloteTheme t, (IconData, String, String) s) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(s.$1, color: t.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$2,
                      style: TextStyle(
                          color: t.text, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(s.$3,
                      style: TextStyle(color: t.text2, fontSize: 13.5, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}
