import 'dart:async';

import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'online_game_page.dart';
import 'player_avatar.dart';
import 'simple_top_bar.dart';

/// **المباريات الحيّة** ([[spectator-system]]): قائمةُ ما يجري الآن — لمسةٌ تُدخل
/// المدرّجات. المشاهدةُ **مجّانيّةٌ عمدًا** (قمعُ التحويل: من نفدت لعباتُه يبقى في
/// اللعبة يتفرّج ويرمي هدايا الماس) — لا بوّابةَ دفعٍ هنا أبدًا.
class LiveTablesScreen extends StatefulWidget {
  /// حقنٌ للاختبار؛ الإنتاج يقرأ من [SessionScope].
  final ApiClient? api;
  final String? token;

  const LiveTablesScreen({super.key, this.api, this.token});

  @override
  State<LiveTablesScreen> createState() => _LiveTablesScreenState();
}

class _LiveTablesScreenState extends State<LiveTablesScreen> {
  SessionController? _session;
  ApiClient? _api;
  String? _token;

  List<LiveTableView> _tables = const [];
  bool _loading = true;
  String? _error;

  /// تحديثٌ دوريّ خفيف: المباريات تبدأ وتنتهي كلَّ دقيقة، وقائمةٌ بائتةٌ تعني
  /// «غير متاحة» عند اللمس. نداءُ قائمةٍ رخيصٌ (O(الطاولات) في الذاكرة).
  Timer? _autoRefresh;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session =
        context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
    _session = session;
    _api = widget.api ?? session?.api ?? ApiClient();
    _token = widget.token ?? session?.session?.token;
    if (_loading && _tables.isEmpty) _refresh();
    _autoRefresh ??= Timer.periodic(
        const Duration(seconds: 15), (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    final token = _token;
    final api = _api;
    if (token == null || api == null) {
      setState(() {
        _loading = false;
        _error = 'سجّل الدخول لمشاهدة المباريات.';
      });
      return;
    }
    if (!silent) setState(() => _loading = _tables.isEmpty);
    try {
      final list = await api.liveTables(token);
      if (!mounted) return;
      setState(() {
        _tables = list;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // قائمةٌ قائمةٌ تبقى معروضةً؛ الخطأ يظهر حين لا شيءَ سواه.
        if (_tables.isEmpty) _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_tables.isEmpty) _error = 'تعذّر جلب المباريات — تحقّق من الاتّصال.';
      });
    }
  }

  Future<void> _watch(LiveTableView t) async {
    final auth = _session?.session;
    if (auth == null) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => OnlineGamePage(session: auth, spectateTableId: t.tableId),
    ));
    if (mounted) _refresh(silent: true); // عاد ⇒ المشهد تغيّر غالبًا
  }

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
              SimpleTopBar(
                title: 'مباريات حيّة',
                trailing: IconButton(
                  tooltip: 'تحديث',
                  onPressed: () => _refresh(),
                  icon: Icon(Icons.refresh, color: t.text2),
                ),
              ),
              Expanded(child: _body(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BeloteTheme t) {
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(strokeWidth: 3, color: t.accent));
    }
    final err = _error;
    if (err != null) {
      return _CenterNote(icon: Icons.wifi_off, text: err);
    }
    if (_tables.isEmpty) {
      return const _CenterNote(
        icon: Icons.visibility_outlined,
        text: 'لا مباريات جاريةً الآن.\nعُد بعد قليل — أو ابدأ واحدةً بنفسك!',
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      color: t.accent,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _tables.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _TableCard(table: _tables[i], onWatch: _watch),
      ),
    );
  }
}

class _CenterNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _CenterNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: t.text3),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.text2, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

/// بطاقةُ مباراةٍ حيّة: الفريقان والنتيجة وعدّاد الجمهور — لمسةٌ تدخل المدرّجات.
class _TableCard extends StatelessWidget {
  final LiveTableView table;
  final void Function(LiveTableView) onWatch;
  const _TableCard({required this.table, required this.onWatch});

  /// اسمُ صاحب المقعد [seat] — الذكاءُ باسمٍ محايد (لا نكشف أنّه روبوت: نفسُ
  /// سياسة شاشة المطابقة التي تُخفيه عن الجالسين أنفسهم).
  String _name(int seat) {
    for (final p in table.players) {
      if (p.seat == seat) return p.ai || p.name.isEmpty ? 'لاعب' : p.name;
    }
    return 'لاعب';
  }

  LiveTablePlayer? _at(int seat) {
    for (final p in table.players) {
      if (p.seat == seat) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onWatch(table),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [t.surface2, t.surface],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: table.tournament ? t.accent : t.line,
                width: table.tournament ? 1.4 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (table.tournament) ...[
                    Icon(Icons.emoji_events, size: 18, color: t.accentBright),
                    const SizedBox(width: 6),
                    Text('بطولة',
                        style: TextStyle(
                            color: t.accentBright,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  Icon(Icons.visibility_outlined, size: 16, color: t.text3),
                  const SizedBox(width: 4),
                  // الأرقام لاتينيّةٌ دائمًا ([[latin-digits-ui]]).
                  Text('${table.watchers}',
                      style: TextStyle(color: t.text2, fontSize: 12.5)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _team(t, 0, 2, table.usScore)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('ضد',
                        style: TextStyle(color: t.text3, fontSize: 12)),
                  ),
                  Expanded(child: _team(t, 1, 3, table.themScore)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.play_circle_outline,
                      size: 18, color: t.accentBright),
                  const SizedBox(width: 6),
                  Text('شاهد المباراة',
                      style: TextStyle(
                          color: t.accentBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// عمودُ فريقٍ: لاعباه فوق بعضهما + نقاطُه. [a] و[b] مقعدا الفريق.
  Widget _team(BeloteTheme t, int a, int b, int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _player(t, a),
        const SizedBox(height: 4),
        _player(t, b),
        const SizedBox(height: 6),
        Text('$score نقطة',
            style: TextStyle(
                color: t.text, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _player(BeloteTheme t, int seat) {
    final p = _at(seat);
    return Row(
      children: [
        PlayerAvatar(
          url: p?.avatarUrl ?? '',
          fallback: _name(seat).characters.first,
          size: 22,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _name(seat),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: t.text2, fontSize: 12.5),
          ),
        ),
        if (p?.vip ?? false) ...[
          const SizedBox(width: 4),
          Icon(Icons.workspace_premium, size: 13, color: t.accentBright),
        ],
      ],
    );
  }
}
