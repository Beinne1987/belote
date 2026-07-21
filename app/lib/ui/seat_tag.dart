import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';

/// شارة مقعد: اسم اللاعب + نقطة بلون فريقه، وتوهّج حين يكون الدور له.
/// ودجة عرض محضة — تتلقّى كل شيء جاهزًا، لا تعرف قاعدة.
class SeatTag extends StatelessWidget {
  final String name;
  final Color teamColor;
  final bool active;

  /// هذا المقعد هو الموزّع ⇒ شارة ورق صغيرة تُبيّن «من عليه التقسيم».
  final bool dealer;

  const SeatTag({
    super.key,
    required this.name,
    required this.teamColor,
    this.active = false,
    this.dealer = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: active ? 0.55 : 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? teamColor : Colors.white24,
          width: active ? 1.6 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: teamColor.withValues(alpha: 0.55), blurRadius: 10)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: teamColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: t.feltInk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (dealer) ...[
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: t.accent.withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(color: t.accent, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.style, size: 11, color: t.accent),
            ),
          ],
        ],
      ),
    );
  }
}
