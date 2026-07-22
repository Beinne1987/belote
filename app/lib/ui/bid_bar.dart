import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;

import '../game/view_model.dart';
import '../strings_ar.dart';
import '../theme/belote_theme.dart';
import 'suit_pip.dart';

/// شريط الضمانة — **فوق يدك مباشرة**، لا نافذة تغطّي الشاشة: ترى أوراقك وأنت
/// تقرّر. الضمانات الأضعف **معطّلة لا مخفيّة**. عرضٌ محض: يرسم [BidBarView]
/// ويُطلق [onBid]؛ لا يقرّر قانونيةً بنفسه.
class BidBar extends StatelessWidget {
  final BidBarView view;
  final void Function(BidAction action) onBid;

  const BidBar({super.key, required this.view, required this.onBid});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            S.yourBid,
            style: TextStyle(
              color: t.feltInk2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Wrap لا تمرير: كل الخيارات مرئية — لا شيء مخفيّ خلف السحب.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (final o in view.options) _BidChip(option: o, onBid: onBid),
            ],
          ),
        ],
      ),
    );
  }
}

class _BidChip extends StatelessWidget {
  final BidOption option;
  final void Function(BidAction action) onBid;

  const _BidChip({required this.option, required this.onBid});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final enabled = option.enabled;
    final Color bg, fg, border;
    if (!enabled) {
      bg = Colors.transparent;
      fg = t.text3;
      border = t.text3;
    } else if (option.isAkwins) {
      bg = t.accent.withValues(alpha: 0.18);
      fg = t.accent;
      border = t.accent;
    } else if (option.isPass) {
      bg = Colors.transparent;
      fg = t.feltInk2;
      border = t.feltInk2;
    } else {
      bg = t.feltInk.withValues(alpha: 0.12);
      fg = t.feltInk;
      border = t.feltInk;
    }

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? () => onBid(option.action) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: 1.2),
            ),
            // **ضماناتُ الألوان رموزٌ لا أسماء** (طلبُ المالك 2026-07-22):
            // «أبيك» و«كير» أسماءٌ تُقرَأ، والرمزُ يُعرَف بلمحة — وهو نفسُه
            // الذي على الورق في يدك. صن وتو وأكوينس تبقى نصًّا (لا رمزَ لها).
            // الاسمُ يبقى في `Semantics` فلا يخسر قارئُ الشاشة شيئًا.
            child: option.suit == null
                ? Text(
                    option.label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Semantics(
                    label: option.label,
                    child: SuitPip(
                      suit: option.suit!,
                      size: 20,
                      color: enabled
                          ? SuitPip.inkOnDark(option.suit!, t.feltInk)
                          : t.text3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
