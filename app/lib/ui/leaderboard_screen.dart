import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../theme/belote_theme.dart';
import 'rank_badge.dart';
import 'honor_badge.dart';
import 'player_avatar.dart';
import 'simple_top_bar.dart';

/// شاشة التصنيف — بياناتٌ حقيقيّة من `/leaderboard` (عامّ، بلا مصادقة).
/// منصّة الأوائل الثلاثة + صفوف. حالات: تحميل · خطأ (بإعادة) · فارغ · بيانات.
class LeaderboardScreen extends StatefulWidget {
  /// حقنٌ للاختبار؛ الإنتاج يبني عميلًا افتراضيًّا.
  final ApiClient? api;
  const LeaderboardScreen({super.key, this.api});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final ApiClient _api = widget.api ?? ApiClient();
  late Future<List<LeaderEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.leaderboard();
  }

  void _reload() => setState(() => _future = _api.leaderboard());

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.gradTop, t.gradBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SimpleTopBar(title: 'التصنيف'),
              Expanded(
                child: FutureBuilder<List<LeaderEntry>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(color: t.accent));
                    }
                    if (snap.hasError) {
                      return _message(
                        t,
                        icon: Icons.cloud_off,
                        text: snap.error is ApiException
                            ? (snap.error as ApiException).message
                            : 'تعذّر جلب التصنيف',
                        onRetry: _reload,
                      );
                    }
                    final rows = snap.data ?? const [];
                    if (rows.isEmpty) {
                      return _message(
                        t,
                        icon: Icons.leaderboard_outlined,
                        text: 'لا تصنيف بعد — العب مباريات أونلاين لتظهر هنا.',
                        onRetry: _reload,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => _reload(),
                      color: t.accent,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        children: [
                          if (rows.length >= 3) _podium(t, rows),
                          const SizedBox(height: 14),
                          for (final r in rows.length >= 3 ? rows.skip(3) : rows)
                            _row(t, r),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(BeloteTheme t,
          {required IconData icon, required String text, required VoidCallback onRetry}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: t.text3, size: 44),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.text2, fontSize: 14)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                    foregroundColor: t.text, side: BorderSide(color: t.line)),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );

  Widget _podium(BeloteTheme t, List<LeaderEntry> rows) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _pod(t, rows[1], 108, const Color(0xFFC9CDD2))),
        Expanded(child: _pod(t, rows[0], 140, const Color(0xFFF2C94C))),
        Expanded(child: _pod(t, rows[2], 92, const Color(0xFFCB8A58))),
      ],
    );
  }

  Widget _pod(BeloteTheme t, LeaderEntry r, double h, Color medal) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    LinearGradient(colors: [medal, medal.withValues(alpha: 0.7)]),
                boxShadow: [
                  BoxShadow(color: medal.withValues(alpha: 0.5), blurRadius: 12)
                ],
              ),
              child: Text('${r.rank}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 6),
            Text(_name(r),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: t.text, fontWeight: FontWeight.w700, fontSize: 13)),
            Text('${r.rating}',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: t.accent, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Container(
              height: h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [t.surface2, t.surface],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                border: Border.all(color: t.line),
              ),
            ),
          ],
        ),
      );

  Widget _row(BeloteTheme t, LeaderEntry r) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.line),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text('${r.rank}',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: t.text3, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            PlayerAvatar(
              url: r.avatarUrl,
              fallback: _name(r).characters.first,
              size: 32,
              borderColor: t.surface2,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(_name(r),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: t.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                      // لقبُ الأسبوع بجانب الاسم — [[honors-weekly]].
                      const SizedBox(width: 5),
                      PlayerHonorBadge(playerId: r.playerId),
                      // ورتبةُ مهارته الدائمة بعده — اللقبُ أسبوعٌ والرتبةُ مسار.
                      if (r.skill?.placed ?? false) ...[
                        const SizedBox(width: 5),
                        RankBadge(rank: r.skill, size: 11, showText: false),
                      ],
                    ],
                  ),
                  Text('${r.matches} مباراة · ${r.wins} فوز',
                      style: TextStyle(color: t.text3, fontSize: 11.5)),
                ],
              ),
            ),
            Text('${r.rating}',
                textDirection: TextDirection.ltr,
                style: TextStyle(color: t.accent, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  String _name(LeaderEntry r) => r.displayName.isNotEmpty ? r.displayName : 'لاعب';
}
