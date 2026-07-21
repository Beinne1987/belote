import 'package:flutter/material.dart';

import '../game/quick_chat.dart';
import '../theme/belote_theme.dart';

// **البياناتُ في `game/quick_chat.dart`** ليستعملها الكنترولر بلا استيراد الواجهة؛
// وتُعاد هنا للمستوردين القدامى (شاشات · اختبارات) بلا كسر.
export '../game/quick_chat.dart' show quickChatPhrases, quickChatText;

/// العباراتُ الجاهزةُ تبقى ردودًا سريعةً بجانب الدردشة الحرّة (قرار المالك
/// 2026-07-16): «خلِّ الجاهزةَ ردًّا جاهزًا في شريطٍ على حافّة الدردشة الحرّة».

/// فقاعةُ العبارة فوق بطاقة صاحبها. نظيرةُ `ReactionBubble` — نبضةُ وصولٍ ثمّ تستقرّ
/// — لكنّها **نصٌّ لا رمز**: عرضٌ محدود وسطران بأكثر تقدير كي لا تبتلع الطاولة.
class ChatBubble extends StatelessWidget {
  final String text;
  const ChatBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (_, s, child) => Transform.scale(scale: s, child: child),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 118),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
}

/// شريطُ اختيار العبارة — يظهر فوق زرّ الدردشة ويُغلق فور الاختيار.
class QuickChatPicker extends StatelessWidget {
  final void Function(String id) onPick;
  const QuickChatPicker({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.line),
        boxShadow: [BoxShadow(color: t.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in quickChatPhrases.entries)
            InkWell(
              onTap: () => onPick(e.key),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  e.value,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: t.text, fontSize: 13.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
