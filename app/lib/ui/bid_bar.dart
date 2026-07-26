import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;

import '../game/view_model.dart';
import '../l10n/app_text.dart';
import '../theme/belote_theme.dart';
import 'bid_visuals.dart';

/// شريط الضمانة — **فوق يدك مباشرة**، لا نافذة تغطّي الشاشة: ترى أوراقك وأنت
/// تقرّر. الضمانات الأضعف **معطّلة لا مخفيّة**. عرضٌ محض: يرسم [BidBarView]
/// ويُطلق [onBid]؛ لا يقرّر قانونيةً بنفسه.
///
/// **أزرارٌ حرّةٌ بلا لوحةٍ تجمعها (طلبُ المالك 2026-07-23):** لا صندوقَ داكنًا
/// كبيرًا يحيط بالكلّ — كلُّ خيارٍ زرٌّ قائمٌ بذاته يحمل خلفيّته، فيطفو الشريطُ
/// على اللبّاد بدل أن يجلس في علبة. صفّان: رموزُ الألوان فوق، وما لا لونَ له
/// (تمرير · صن · تو · أكوينس) تحتها مباشرةً في سطرٍ واحد.
class BidBar extends StatelessWidget {
  final BidBarView view;
  final void Function(BidAction action) onBid;

  const BidBar({super.key, required this.view, required this.onBid});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final l = context.l10n;
    // التقسيمُ في الواجهة وحدَها — ترتيبُ `options` من المحرّك يبقى كما هو.
    final suits = view.options.where((o) => o.suit != null).toList();
    final rest = view.options.where((o) => o.suit == null).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // العنوانُ بلا علبةٍ خلفه ⇒ ظلٌّ رفيعٌ يفصله عن اللبّاد.
          Text(
            l.bidYours,
            style: TextStyle(
              color: t.feltInk2,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 3),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Wrap لا تمرير: كل الخيارات مرئية — لا شيء مخفيّ خلف السحب.
          if (suits.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final o in suits) _SuitChip(option: o, onBid: onBid),
              ],
            ),
          if (suits.isNotEmpty && rest.isNotEmpty) const SizedBox(height: 8),
          // صفٌّ واحدٌ مضمون: أنصبةٌ متساويةٌ لا `Wrap` — النصُّ يضمر عند الضيق
          // ولا ينزل الزرُّ سطرًا. المدى محدودٌ كي لا تمتدّ الأزرارُ عرضَ
          // الشاشة على اللوح.
          if (rest.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Row(
                children: [
                  for (final o in rest) ...[
                    if (o != rest.first) const SizedBox(width: 6),
                    Expanded(child: _BidButton(option: o, onBid: onBid)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ضمانةُ لونٍ في الشريط: [SuitBidChip] فوق حبرِ لمسٍ. الشكلُ نفسُه يظهر في
/// الفقاعة أمام من نطق بالضمانة — وحدةٌ واحدةٌ في `bid_visuals.dart`.
class _SuitChip extends StatelessWidget {
  final BidOption option;
  final void Function(BidAction action) onBid;

  const _SuitChip({required this.option, required this.onBid});

  /// صغيرٌ كي تسع الأربعةُ صفًّا واحدًا على أضيق هاتف، وأكبرُ من 44 ⇒ يبقى
  /// هدفَ لمسٍ سليمًا.
  static const double _side = 46;

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final enabled = option.enabled;

    return Semantics(
      label: option.label,
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: Material(
          color: Colors.transparent,
          borderRadius: SuitBidChip.radiusFor(_side),
          child: InkWell(
            borderRadius: SuitBidChip.radiusFor(_side),
            onTap: enabled ? () => onBid(option.action) : null,
            child: SuitBidChip(
              suit: option.suit!,
              side: _side,
              // المعطّلةُ برمادِ الحبر لا بلونه: تبقى مقروءةً ولا تُغري باللمس.
              ink: enabled ? null : t.text3,
            ),
          ),
        ),
      ),
    );
  }
}

/// ما لا لونَ له: تمرير · صن · تو · أكوينس — **أزرارٌ ممتلئة** في سطرٍ واحدٍ
/// تحت رموز الألوان مباشرةً.
class _BidButton extends StatelessWidget {
  final BidOption option;
  final void Function(BidAction action) onBid;

  const _BidButton({required this.option, required this.onBid});

  @override
  Widget build(BuildContext context) {
    final enabled = option.enabled;
    final tone = !enabled
        ? BidPillTone.disabled
        : option.isAkwins
            ? BidPillTone.akwins
            : option.isPass
                ? BidPillTone.pass
                : BidPillTone.high;

    return Semantics(
      label: option.label,
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: enabled ? () => onBid(option.action) : null,
            child: BidPill(label: option.label, tone: tone),
          ),
        ),
      ),
    );
  }
}
