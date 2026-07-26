import 'package:belote_engine/belote_engine.dart' as engine;
import 'package:flutter/material.dart';

import '../game/view_model.dart';
import '../l10n/app_text.dart';
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
    final l = context.l10n;
    final i = summary.insights;
    final mvp = i.seatPerf(i.mvpSeat);

    final cards = <Widget>[
      _MomentCard(
        icon: '⭐',
        label: l.momentMvp,
        title: summary.nameOf(i.mvpSeat),
        detail: _mvpDetail(l, mvp),
        mine: summary.isMe(i.mvpSeat),
        highlight: true,
      ),
      if (i.bestBid != null)
        _MomentCard(
          icon: '📣',
          label: l.momentBestBid,
          title: '${summary.nameOf(i.bestBid!.seat)} · ${_bidName(l, i.bestBid!)}',
          detail: l.momentBestBidDetail(i.bestBid!.points, i.bestBid!.round),
          mine: summary.isMe(i.bestBid!.seat),
        ),
      if (i.strongestCard != null)
        _MomentCard(
          icon: '🔥',
          label: l.momentStrongestCard,
          title: summary.nameOf(i.strongestCard!.seat),
          detail: l.momentStrongestCardDetail(i.strongestCard!.units),
          mine: summary.isMe(i.strongestCard!.seat),
          trailing: _cardOf(i.strongestCard!.card),
        ),
      if (i.longestStreak != null)
        _MomentCard(
          icon: '⚡',
          label: l.momentLongestStreak,
          title: summary.nameOf(i.longestStreak!.seat),
          detail: l.momentLongestStreakDetail(i.longestStreak!.length),
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
              l.matchMoments,
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
  String _mvpDetail(AppLocalizations l, engine.SeatPerformance p) {
    final bits = <String>[
      l.tricksCount(p.tricks),
      l.unitsCount(p.units),
      if (p.bidsWon > 0) l.bidsWonCount(p.bidsWon),
      if (p.rightAccusations > 0) l.foujaCaughtCount(p.rightAccusations),
    ];
    return bits.join(' · ');
  }

  String _bidName(AppLocalizations l, engine.BestBidMoment b) {
    final name = switch (b.bid) {
      'A' => l.bidTout,
      'N' => l.bidSans,
      'T' => l.suitTrefle,
      'C' => l.suitCarreau,
      'H' => l.suitCoeur,
      'S' => l.suitPique,
      _ => b.bid,
    };
    return b.akwins ? l.bidWithAkwinsShort(name) : name;
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
                  style: TextStyle(
                      color: t.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  mine ? context.l10n.youSuffix(title) : title,
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
