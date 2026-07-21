import 'package:flutter/material.dart';

import '../game/view_model.dart';
import '../net/player_rank.dart';
import '../strings_ar.dart';
import '../theme/belote_theme.dart';
import 'match_summary.dart';
import 'rank_badge.dart';

/// لوحة نتيجة الجولة — عرضٌ محض لـ [RoundResult]. تظهر فوق الطاولة عند النهاية.
class ResultPanel extends StatelessWidget {
  final RoundResult result;

  /// «مباراة جديدة» (تصفير أوفلاين، أو عودةٌ للمطابقة أونلاين). null ⇒ يُخفى الزرّ.
  final VoidCallback? onNewMatch;

  /// «الخروج/القائمة» — مغادرة الطاولة بعد انتهاء المباراة. null ⇒ يُخفى الزرّ.
  final VoidCallback? onExit;

  /// تقييم ELO بعد المباراة وتغيّره — أونلاين **مصنّف فقط** (٤ بشر). null في
  /// الأوفلاين وفي مباريات الذكاء ⇒ يُخفى السطر كلّه.
  final int? rating;
  final int? ratingDelta;

  /// رتبتُه بعد المباراة — تُعرَض بجانب التصنيف. null ⇒ غيرُ مصنّفةٍ أو خادمٌ أقدم.
  final PlayerRankView? rank;

  /// **لحظاتُ المباراة** — تُعرَض عند انتهائها فقط، لا بين الجولات. null ⇒ لا ملخّص
  /// (خادمٌ أقدمُ من الميزة، أو المباراةُ لم تنتهِ بعد).
  final MatchSummaryView? summary;

  const ResultPanel({
    super.key,
    required this.result,
    this.onNewMatch,
    this.onExit,
    this.rating,
    this.ratingDelta,
    this.rank,
    this.summary,
  });

  /// انتهت المباراة بفائز واضح (0 أو 1)؟ عندها فقط يُعرض زرّ «مباراة جديدة» (تصفير).
  /// بين الجولات لا زرّ: تُعرض النتيجة ثوانٍ ثم تتقدّم تلقائيًّا (الجولة الفاصلة كذلك).
  bool get _matchWon => result.matchOutcome == 0 || result.matchOutcome == 1;

  String get _title {
    if (result.openRuleAkwinsTie) return S.openRuleTie;
    return switch (result.matchOutcome) {
      0 => S.matchWonUs,
      1 => S.matchWonThem,
      'tiebreak' => S.matchTiebreak,
      _ => S.roundOver,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    // مرفوعة للأعلى وبتعتيم خفيف كي يبقى الورق المكشوف مرئيًّا أسفلها (طلب صاحب المشروع).
    return Container(
      color: Colors.black.withValues(alpha: 0.32),
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: t.feltCenter,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.accent, width: 1.4),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
        ),
        // **تمرّرٌ محدودُ الارتفاع**: لوحةُ نهاية المباراة تحمل الآن لحظاتِها الأربع
        // فوق الرصيد والتصنيف، وهاتفٌ قصيرٌ كان سيقصّ الأزرار. الحدُّ 78% كي يبقى
        // من الطاولة ما يُذكّر أين أنت.
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.78),
          child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.feltInk,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (!result.openRuleAkwinsTie) ...[
              const SizedBox(height: 6),
              Text(
                result.reason == 'fouja'
                    ? (result.usPoints > 0 ? S.foujaWonUs : S.foujaWonThem)
                    : '${S.reasonLabel(result.reason)} · ${S.roundValue} ${result.roundValue}',
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.feltInk2, fontSize: 13),
              ),
              const SizedBox(height: 18),
              // نقاط هذه الجولة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _points(S.us, result.usPoints, t.accent, t.feltInk),
                  _points(S.them, result.themPoints, t.text2, t.feltInk),
                ],
              ),
            ],
            const SizedBox(height: 18),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            // رصيد المباراة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _total(S.us, result.usTotal, t.accent, t.feltInk),
                const SizedBox(width: 8),
                Text('—', style: TextStyle(color: t.feltInk2)),
                const SizedBox(width: 8),
                _total(S.them, result.themTotal, t.text2, t.feltInk),
              ],
            ),
            // التصنيف: مباراةٌ مصنّفة انتهت ⇒ التقييم الجديد وتغيّره.
            if (_matchWon && rating != null && ratingDelta != null) ...[
              const SizedBox(height: 12),
              _rating(t),
            ],
            // **الترقيةُ تُرى حين تُستحقّ**: الشارةُ هنا لا في الملفّ وحدَه.
            if (_matchWon && rank != null) ...[
              const SizedBox(height: 8),
              RankBadge(rank: rank, size: 13),
            ],
            // **لحظاتُ المباراة** — بعد الرصيد وقبل الأزرار: يُقرأ الخبرُ ثمّ يُقرَّر.
            if (_matchWon && summary != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 14),
              MatchSummary(summary: summary!),
            ],
            if (_matchWon && (onNewMatch != null || onExit != null)) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onExit != null)
                    OutlinedButton(
                      onPressed: onExit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: t.feltInk,
                        side: BorderSide(color: t.accent),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                      ),
                      child: const Text(S.backToMenu,
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  if (onExit != null && onNewMatch != null)
                    const SizedBox(width: 12),
                  if (onNewMatch != null)
                    FilledButton(
                      onPressed: onNewMatch,
                      style: FilledButton.styleFrom(
                        backgroundColor: t.accent,
                        foregroundColor: t.onAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                      ),
                      child: const Text(S.newMatch,
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// «التصنيف 1016 ▲ +16» — الأرقام لاتينية ومعزولة الاتّجاه (ملاحظة CLAUDE.md).
  Widget _rating(BeloteTheme t) {
    final up = ratingDelta! >= 0;
    final color = up ? t.accent : t.text2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${S.rating} ', style: TextStyle(color: t.feltInk2, fontSize: 13)),
        Text('$rating',
            textDirection: TextDirection.ltr,
            style: TextStyle(
                color: t.feltInk, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(width: 6),
        Icon(up ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: color, size: 20),
        Text('${up ? '+' : '−'}${ratingDelta!.abs()}',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _points(String label, int value, Color color, Color ink) => Column(
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('+$value',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: ink, fontSize: 30, fontWeight: FontWeight.w800)),
        ],
      );

  Widget _total(String label, int value, Color color, Color ink) => Row(
        children: [
          Text('$label ', style: TextStyle(color: color, fontSize: 13)),
          Text('$value',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: ink, fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      );
}
