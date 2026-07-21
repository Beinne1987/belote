import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';

/// الرموز المعروضة في المنتقي. **يجب أن تطابق `reactionEmojis`** في
/// `server/lib/game/reactions.dart` — الخادم هو المرجع: ما ليس في قائمته يُرفض
/// بصمتٍ فلا يظهر لأحد (ولا حتى لمرسِله).
const reactionEmojis = <String>['👍', '👏', '😂', '😮', '😢', '🔥', '❤️', '🤔'];

/// شريطٌ صغيرٌ من الرموز يظهر فوق زرّ التفاعل. عرضٌ محض: يُبلّغ [onPick] ويُغلق.
class ReactionPicker extends StatelessWidget {
  final void Function(String emoji) onPick;
  const ReactionPicker({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: t.feltCenter,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.accent, width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in reactionEmojis)
            InkWell(
              onTap: () => onPick(e),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(e, style: const TextStyle(fontSize: 22)),
              ),
            ),
        ],
      ),
    );
  }
}

/// فقاعة التفاعل التي تطفو فوق بطاقة اللاعب عند وصول رمزٍ منه.
class ReactionBubble extends StatelessWidget {
  final String emoji;
  const ReactionBubble({super.key, required this.emoji});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        // تكبر قليلًا ثم تستقرّ — نبضةُ وصولٍ تُلفت النظر بلا إزعاج.
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (_, s, child) => Transform.scale(scale: s, child: child),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      );
}
