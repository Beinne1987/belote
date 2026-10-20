import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'player_avatar.dart';

/// **نبضُ اللعبة** — لوحتان تملآن أسفل رئيسيّة الحاسوب: **أفضل خمسة لاعبين**
/// و**المباريات الجارية الآن** (اقتراحُ المراجعة 2026-09-29: نصفُ الشاشة السفليّ
/// كان فارغًا تحت البطاقات).
///
/// **للحاسوب وحدَه** ([HomeScreen] يضعها في عموده الواسع): على الهاتف لا فراغَ
/// ليُملأ. **لا لوحةَ بلا محتوى**: كلُّ لوحةٍ تختفي إن لم يجئ لها صفٌّ (خادمٌ غائب،
/// لا مباريات، ضيفٌ لا يرى المباشر) فلا صناديقَ فارغة. وفشلُ الشبكة صامتٌ — هذه
/// زينةٌ معلوماتيّةٌ لا تُسقط الرئيسيّة.
class DesktopPulse extends StatefulWidget {
  final SessionController session;
  final VoidCallback? onLeaderboard;
  final VoidCallback? onWatchLive;

  const DesktopPulse({
    super.key,
    required this.session,
    this.onLeaderboard,
    this.onWatchLive,
  });

  @override
  State<DesktopPulse> createState() => _DesktopPulseState();
}

class _DesktopPulseState extends State<DesktopPulse> {
  List<LeaderEntry> _top = const [];
  List<LiveTableView> _live = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = widget.session.api;
    try {
      final top = await api.leaderboard();
      if (mounted) setState(() => _top = top.take(5).toList());
    } catch (_) {/* بلا لوحة */}
    final s = widget.session.session;
    if (s == null) return; // الضيفُ لا يرى المباشر (القائمةُ خلف المصادقة)
    try {
      final live = await api.liveTables(s.token);
      if (mounted) {
        // الأكثرُ مشاهدةً أوّلًا، وأربعٌ تكفي.
        final sorted = [...live]
          ..sort((a, b) => b.watchers.compareTo(a.watchers));
        setState(() => _live = sorted.take(4).toList());
      }
    } catch (_) {/* بلا لوحة */}
  }

  @override
  Widget build(BuildContext context) {
    if (_top.isEmpty && _live.isEmpty) return const SizedBox.shrink();
    final l = context.l10n;
    final t = BeloteTheme.of(context);
    final panels = <Widget>[
      if (_top.isNotEmpty)
        Expanded(
          child: _Panel(
            t: t,
            icon: Icons.emoji_events,
            title: l.pulseTopPlayers,
            onTap: widget.onLeaderboard,
            children: [for (final e in _top) _PlayerRow(t: t, e: e)],
          ),
        ),
      if (_top.isNotEmpty && _live.isNotEmpty) const SizedBox(width: 12),
      if (_live.isNotEmpty)
        Expanded(
          child: _Panel(
            t: t,
            icon: Icons.connected_tv,
            title: l.pulseLiveNow,
            onTap: widget.onWatchLive,
            children: [for (final m in _live) _LiveRow(t: t, m: m)],
          ),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: panels),
    );
  }
}

class _Panel extends StatelessWidget {
  final BeloteTheme t;
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final List<Widget> children;
  const _Panel({
    required this.t,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: t.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          color: t.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
                if (onTap != null)
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Text(context.l10n.pulseSeeAll,
                          style: TextStyle(color: t.accent, fontSize: 12)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      );
}

class _PlayerRow extends StatelessWidget {
  final BeloteTheme t;
  final LeaderEntry e;
  const _PlayerRow({required this.t, required this.e});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('${e.rank}',
                  textDirection: TextDirection.ltr, // أرقامٌ لاتينيّةٌ دائمًا
                  style: TextStyle(
                      color: e.rank == 1 ? t.accent : t.text3,
                      fontWeight: FontWeight.w900)),
            ),
            PlayerAvatar(
              url: e.avatarUrl,
              fallback:
                  e.displayName.isEmpty ? '?' : e.displayName.characters.first,
              size: 30,
              borderColor: e.rank == 1 ? t.accent : t.line,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(e.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.text, fontSize: 13.5)),
            ),
            Text('${e.rating}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    color: t.text2, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      );
}

class _LiveRow extends StatelessWidget {
  final BeloteTheme t;
  final LiveTableView m;
  const _LiveRow({required this.t, required this.m});

  @override
  Widget build(BuildContext context) {
    final humans = [
      for (final p in m.players)
        if (!p.ai && p.name.isNotEmpty) p.name
    ];
    final names = humans.isEmpty ? '—' : humans.take(2).join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(m.tournament ? Icons.emoji_events : Icons.circle,
              size: m.tournament ? 16 : 8, color: t.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(names,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.text, fontSize: 13.5)),
          ),
          Text('${m.usScore} – ${m.themScore}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: t.text2, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(width: 10),
          Icon(Icons.visibility, size: 14, color: t.text3),
          const SizedBox(width: 3),
          Text('${m.watchers}',
              textDirection: TextDirection.ltr,
              style: TextStyle(color: t.text3, fontSize: 12)),
        ],
      ),
    );
  }
}
