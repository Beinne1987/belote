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

  /// ضلعُ رمز اللون — يأتي من مقاس الطاولة ([TableMetrics.bidChipSide]) لا من
  /// رقمٍ هنا: الشريطُ يكبر مع الأوراق والمقاعد بدل أن يبقى بحجم هاتفٍ وحده.
  final double chipSide;

  const BidBar({
    super.key,
    required this.view,
    required this.onBid,
    this.chipSide = 46,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final l = context.l10n;
    final grow = chipSide / 46; // كلُّ المقاسات نِسَبٌ من مقاس الهاتف المُقرّ
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
              fontSize: 12 * grow,
              fontWeight: FontWeight.w700,
              shadows: const [
                Shadow(color: Colors.black54, blurRadius: 3),
              ],
            ),
          ),
          SizedBox(height: 8 * grow),
          // Wrap لا تمرير: كل الخيارات مرئية — لا شيء مخفيّ خلف السحب.
          if (suits.isNotEmpty)
            Wrap(
              spacing: 8 * grow,
              runSpacing: 8 * grow,
              alignment: WrapAlignment.center,
              children: [
                for (final o in suits)
                  _SuitChip(option: o, onBid: onBid, side: chipSide),
              ],
            ),
          if (suits.isNotEmpty && rest.isNotEmpty) SizedBox(height: 8 * grow),
          // صفٌّ واحدٌ مضمون: أنصبةٌ متساويةٌ لا `Wrap` — النصُّ يضمر عند الضيق
          // ولا ينزل الزرُّ سطرًا. المدى محدودٌ كي لا تمتدّ الأزرارُ عرضَ
          // الشاشة على اللوح.
          if (rest.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 340 * grow),
              child: Row(
                children: [
                  for (final o in rest) ...[
                    if (o != rest.first) SizedBox(width: 6 * grow),
                    Expanded(
                      child: _BidButton(
                        option: o,
                        onBid: onBid,
                        height: BidPill.height * grow,
                      ),
                    ),
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

  /// ضلعُه. أرضيّتُه 46: صغيرٌ كي تسع الأربعةُ صفًّا واحدًا على أضيق هاتف،
  /// وأكبرُ من 44 ⇒ يبقى هدفَ لمسٍ سليمًا.
  final double side;

  const _SuitChip({required this.option, required this.onBid, this.side = 46});

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
          borderRadius: SuitBidChip.radiusFor(side),
          child: InkWell(
            borderRadius: SuitBidChip.radiusFor(side),
            onTap: enabled ? () => onBid(option.action) : null,
            child: SuitBidChip(
              suit: option.suit!,
              side: side,
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
  final double height;

  const _BidButton({
    required this.option,
    required this.onBid,
    this.height = BidPill.height,
  });

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
          borderRadius: BorderRadius.circular(height * 0.58),
          child: InkWell(
            borderRadius: BorderRadius.circular(height * 0.58),
            onTap: enabled ? () => onBid(option.action) : null,
            child:
                BidPill(label: option.label, tone: tone, boxHeight: height),
          ),
        ),
      ),
    );
  }
}
