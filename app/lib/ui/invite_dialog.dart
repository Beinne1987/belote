import 'package:flutter/material.dart';

import '../net/table_client.dart';
import '../theme/belote_theme.dart';
import 'player_avatar.dart';

/// **دعوةٌ وصلت واللاعبُ خارج شاشة اللعب** — نافذةٌ فوق أيّ شاشةٍ كان فيها.
///
/// **لا تقول الموضع** («شريكًا» / «خصمًا») بخلاف منتقي المقعد عند الداعي: المقعدُ
/// هنا بإحداثيّات **طاولة الداعي**، ومقعدُ الداعي نفسِه ليس في الحمولة ⇒ لا سبيل
/// إلى معرفة أهو مقابلُه أم لا. وقولُ ما لا نعرف أسوأ من السكوت عنه.
Future<bool?> showInviteDialog(BuildContext context, InviteEvent invite) {
  final t = BeloteTheme.of(context);
  final name = invite.fromName.trim().isEmpty ? 'صديقك' : invite.fromName;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: t.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          PlayerAvatar(
            url: invite.fromAvatarUrl,
            fallback: name.characters.first,
            size: 36,
            borderColor: t.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$name يدعوك',
                style: TextStyle(
                    color: t.text, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      content: Text(
        'إلى طاولته الخاصّة — مقعدٌ محجوزٌ لك.',
        style: TextStyle(color: t.text2, fontSize: 14, height: 1.6),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('لاحقًا', style: TextStyle(color: t.text3)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: t.accent, foregroundColor: t.onAccent),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('انضمّ',
              style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}
