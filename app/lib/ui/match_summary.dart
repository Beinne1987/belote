import 'package:belote_engine/belote_engine.dart' as engine;
import 'package:flutter/material.dart';

import '../game/view_model.dart';
import '../theme/belote_theme.dart';
import 'card_face.dart';

/// **لحظاتُ المباراة** — أربعُ بطاقاتٍ تُروى بعد كلّ مباراة.
///
/// **لماذا تُروى أصلًا؟** الرصيدُ «102 — 87» يقول من فاز ولا يقول ماذا حدث. اللاعبُ
/// يتذكّر «تو أخذتَها بأكوينس» و«فالةٌ خطفت 34 وحدة»، لا الرقمَ النهائيّ — وهذه
/// الذكرى هي ما يُعيده غدًا.
///
/// **ولا لقطةَ تُختلَق**: ما لم يقع لا يُعرَض له صندوقٌ فارغ. مباراةٌ بلا سلسلةٍ
/// تُعرَض بثلاث بطاقات.
class MatchSummary extends StatelessWidget {
  final MatchSummaryView summary;

  const MatchSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final i = summary.insights;
    final mvp = i.seatPerf(i.mvpSeat);

    final cards = <Widget>[
      _MomentCard(
        icon: '⭐',
        label: 'رجل المباراة',
        title: summary.nameOf(i.mvpSeat),
        detail: _mvpDetail(mvp),
        mine: summary.isMe(i.mvpSeat),
        highlight: true,
      ),
      if (i.bestBid != null)
        _MomentCard(
          icon: '📣',
          label: 'أفضل إعلان',
          title: '${summary.nameOf(i.bestBid!.seat)} · ${_bidName(i.bestBid!)}',
          detail: 'جنى ${i.bestBid!.points} نقطة في الجولة ${i.bestBid!.round}',
          mine: summary.isMe(i.bestBid!.seat),
        ),
      if (i.strongestCard != null)
        _MomentCard(
          icon: '🔥',
          label: 'أقوى ورقة',
          title: summary.nameOf(i.strongestCard!.seat),
          detail: 'خطفت ${i.strongestCard!.units} وحدةً في أبليٍّ واحد',
          mine: summary.isMe(i.strongestCard!.seat),
          trailing: _cardOf(i.strongestCard!.card),
        ),
      if (i.longestStreak != null)
        _MomentCard(
          icon: '⚡',
          label: 'أطول سلسلة',
          title: summary.nameOf(i.longestStreak!.seat),
          detail: '${i.longestStreak!.length} أبالٍ متتاليةً بلا أن يقطعها أحد',
          mine: summary.isMe(i.longestStreak!.seat),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('✨ ', style: TextStyle(fontSize: 14, color: t.accent)),
            Text(
              'لحظات المباراة',
              style: TextStyle(
                color: t.accent,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final c in cards) ...[c, const SizedBox(height: 8)],
      ],
    );
  }

  /// سببُ استحقاقه اللقب — رقمٌ يُسنِد الحكم، لا مدحٌ مرسَل.
  String _mvpDetail(engine.SeatPerformance p) {
    final bits = <String>[
      '${p.tricks} أبالٍ',
      '${p.units} وحدة',
      if (p.bidsWon > 0) 'وفّى بـ${p.bidsWon} ضمانة',
      if (p.rightAccusations > 0) 'كشف ${p.rightAccusations} فوجة',
    ];
    return bits.join(' · ');
  }

  String _bidName(engine.BestBidMoment b) {
    final name = switch (b.bid) {
      'A' => 'تو',
      'N' => 'صن',
      'T' => 'أتريف',
      'C' => 'كارو',
      'H' => 'كير',
      'S' => 'أبيك',
      _ => b.bid,
    };
    return b.akwins ? '$name أكوينس' : name;
  }

  /// ورقةٌ مرسومةٌ صغيرةً بجانب لقطتها — الرمزُ وحدَه («SJ») لا يعني شيئًا للاعب.
  Widget? _cardOf(String code) {
    final card = engine.buildDeck().where((c) => c.code == code).firstOrNull;
    return card == null
        ? null
        : SizedBox(width: 30, child: CardFace(card: card));
  }
}

/// بطاقةُ لحظةٍ واحدة: رمزٌ · عنوانُ الفئة · صاحبُها · سببُها.
class _MomentCard extends StatelessWidget {
  final String icon;
  final String label;
  final String title;
  final String detail;

  /// أنا صاحبُ اللقطة ⇒ تُميَّز بحدٍّ ذهبيّ. لحظتُك أنت هي ما يُعيدك.
  final bool mine;

  /// «رجل المباراة» أكبرُ من الباقي — لقبٌ واحدٌ يتصدّر لا أربعةٌ متساوية.
  final bool highlight;

  final Widget? trailing;

  const _MomentCard({
    required this.icon,
    required this.label,
    required this.title,
    required this.detail,
    this.mine = false,
    this.highlight = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: highlight ? 12 : 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: mine ? 0.30 : 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: mine ? t.accent : Colors.white.withValues(alpha: 0.12),
          width: mine ? 1.2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: highlight ? 24 : 19)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      color: t.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  mine ? '$title (أنت)' : title,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.feltInk,
                    fontSize: highlight ? 17 : 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                // **الأرقامُ لاتينيّةٌ دائمًا** ([[latin-digits-ui]]): السطرُ عربيٌّ
                // بأرقامٍ داخله ⇒ `rtl` للجملة، والأرقامُ لاتينيّةٌ بأصلها.
                Text(
                  detail,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: t.feltInk2, fontSize: 12),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
