import 'package:flutter/material.dart';

import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'vip_screen.dart';

/// **عرضُ VIP لمن يشتري تذاكرَ كثيرة** — «مَن اشترى تذكرتين في أسبوعٍ يُعرَض عليه
/// VIP» (استراتيجيّة التحويل، اعتمدها المالك 2026-07-16).
///
/// **الحسابُ هو الإقناع**: تذكرةُ اليوم 50 · شهرُ VIP 500 ⇒ الشهرُ كلُّه بثمن عشرِ
/// تذاكر، ومعه مزايا. **التذكرةُ بابٌ إلى VIP لا منافسٌ له** ([[conversion-strategy]]).
///
/// **الخادمُ يقرّر متى** (عدُّ التذاكر في السجلّ)، والعميلُ يعرضه — ولا يُعرَض على
/// مشترك (يُفحَص هنا حارسًا ثانيًا بعد الخادم).
Future<void> showVipUpsell(BuildContext context, SessionController session) {
  if (session.isVip) return Future.value(); // لا نبيع مشتركًا ما يملك
  final t = BeloteTheme.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: t.surface,
      title: Row(
        children: [
          Icon(Icons.workspace_premium, color: t.accent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text('لماذا لا تصير VIP؟',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      content: Text(
        'تشتري التذاكرَ كثيرًا — والشهرُ الكاملُ من VIP بثمن عشرِ تذاكرٍ فقط، ومعه '
        'لعبٌ بلا حدود، ومجلسٌ خاصّ، وهدايا حصريّة، و50💎 كلَّ شهر.',
        textDirection: TextDirection.rtl,
        style: TextStyle(color: t.text2, fontSize: 13.5, height: 1.6),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('لاحقًا')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: t.accent, foregroundColor: t.onAccent),
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => VipScreen(session: session),
            ));
          },
          child: const Text('شاهد VIP'),
        ),
      ],
    ),
  );
}
