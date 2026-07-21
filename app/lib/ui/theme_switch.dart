import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';
import '../theme/theme_manager.dart';
import '../theme/themes.dart';

/// قائمة سفلية لتبديل الثيمات الخمسة — مشتركة بين الرئيسية والطاولة.
/// اختيار ثيمٍ يبدّله فورًا عبر [ThemeManager] (ويُحفَظ).
void showThemeSheet(BuildContext context) {
  final manager = ThemeScope.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: manager.current.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final t = BeloteTheme.of(ctx);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text('الثيم',
                  style: TextStyle(
                      color: t.text, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            for (final theme in BeloteThemes.all)
              ListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.accent, width: 2),
                  ),
                ),
                title: Text(theme.name, style: TextStyle(color: t.text)),
                trailing: identical(theme, manager.current)
                    ? Icon(Icons.check_circle, color: t.accent)
                    : null,
                onTap: () {
                  manager.setTheme(theme);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
