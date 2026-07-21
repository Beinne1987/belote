import 'dart:async';

import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'online_game_page.dart';
import 'player_avatar.dart';
import 'simple_top_bar.dart';

/// **شاشة البطولات** — إقصائيّة 8 لاعبين sit-and-go: تسجيلٌ بالماس (كلٌّ يدفع
/// رسمَه)، شراكةٌ بدعوة صديق، عدّادُ نافذة التجمّع، ثم قوسٌ حيٌّ (نصفا نهائيّ
/// فنهائيّ) وبابُ «ادخل طاولتك». تستطلع `/me/tournament` دوريًّا — ردُّ كلِّ
/// فعلٍ يحمل الحالةَ الجديدة فتُحدَّث الشاشةُ فورًا بلا انتظار الاستطلاع.
class TournamentsScreen extends StatefulWidget {
  /// حقنٌ للاختبار؛ الإنتاج يقرأ من [SessionScope].
  final ApiClient? api;
  final String? token;

  /// فترةُ الاستطلاع — تُصفَّر في الاختبارات (لا مؤقّتات تعلّق الاختبار).
  final Duration pollEvery;

  /// فتحُ طاولة القوس — حقنٌ للاختبار؛ الإنتاج يفتح [OnlineGamePage] بمقعدها.
  final void Function(({String code, int seat}) table)? onEnterTable;

  const TournamentsScreen({
    super.key,
    this.api,
    this.token,
    this.pollEvery = const Duration(seconds: 3),
    this.onEnterTable,
  });

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  ApiClient? _api;
  String? _token;
  SessionController? _session;
  TournamentState? _state;
  String? _fatal; // فشلُ الجلب الأوّل — شاشةُ خطأ بزرّ إعادة
  bool _busy = false; // فعلٌ جارٍ ⇒ عطّل الأزرار (لا تسجيلَ مزدوجًا بنقرتين)
  Timer? _poll;
  Timer? _tick; // عدّادُ الثواني بين استطلاعين
  int? _endsIn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session =
        context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
    _session = session;
    _api = widget.api ?? session?.api ?? ApiClient();
    _token = widget.token ?? session?.session?.token;
    if (_state == null && _fatal == null) _refresh();
    _poll ??= widget.pollEvery <= Duration.zero
        ? null
        : Timer.periodic(widget.pollEvery, (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    final token = _token;
    if (token == null) return;
    try {
      final st = await _api!.tournament(token);
      if (!mounted) return;
      setState(() {
        _state = st;
        _fatal = null;
        _endsIn = st.endsInSeconds;
      });
      _armTicker();
    } on ApiException catch (e) {
      if (!mounted || silent) return; // الاستطلاع الفاشل صامتٌ — القديم يُعرَض
      setState(() => _fatal = e.status == 0
          ? 'تعذّر الاتصال بالخادم'
          : tournamentErrorText(e.message));
    }
  }

  /// عدّادٌ محليٌّ ينزل ثانيةً بثانية بين استطلاعين (العرضُ حيٌّ والحقيقةُ من الخادم).
  void _armTicker() {
    _tick?.cancel();
    if (_endsIn == null || widget.pollEvery <= Duration.zero) return;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final v = _endsIn;
      if (!mounted || v == null || v <= 0) return;
      setState(() => _endsIn = v - 1);
    });
  }

  /// ينفّذ فعلًا يعيد الحالةَ الجديدة، ويترجم رمزَ الخطأ رسالةً عابرة.
  Future<void> _act(Future<TournamentState> Function(String token) run) async {
    final token = _token;
    if (token == null || _busy) return;
    setState(() => _busy = true);
    try {
      final st = await run(token);
      if (!mounted) return;
      setState(() {
        _state = st;
        _endsIn = st.endsInSeconds;
      });
      _armTicker();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.status == 0
              ? 'تعذّر الاتصال بالخادم'
              : tournamentErrorText(e.message))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _enterTable(({String code, int seat}) table) {
    final enter = widget.onEnterTable;
    if (enter != null) {
      enter(table);
      return;
    }
    final auth = _session?.session;
    if (auth == null) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(
          builder: (_) => OnlineGamePage(
            session: auth,
            initialInvite: (code: table.code, seat: table.seat),
          ),
        ))
        .then((_) => _refresh(silent: true)); // عاد ⇒ القوس تقدّم غالبًا
  }

  /// منتقي الشريك: قائمةُ أصدقائي — لمسةٌ تدعو. [eventId] لفعاليّةٍ بعينها.
  Future<void> _pickPartner({String? eventId}) async {
    final token = _token;
    if (token == null) return;
    final FriendLists lists;
    try {
      lists = await _api!.friends(token);
    } on ApiException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر جلبُ الأصدقاء')));
      return;
    }
    if (!mounted) return;
    final t = BeloteTheme.of(context);
    final picked = await showModalBottomSheet<FriendPlayer>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => SafeArea(
        child: lists.friends.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text('لا أصدقاءَ بعد — أضفهم من شاشة الأصدقاء برمزهم.',
                    style: TextStyle(color: t.text2)),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text('ادعُ شريكًا — يدفع رسمَه عند قبوله',
                        style: TextStyle(
                            color: t.text, fontWeight: FontWeight.w800)),
                  ),
                  for (final f in lists.friends)
                    ListTile(
                      leading: PlayerAvatar(
                          url: f.avatarUrl,
                          fallback: f.displayName.isEmpty
                              ? '؟'
                              : f.displayName.characters.first,
                          size: 38),
                      title: Text(f.displayName,
                          style: TextStyle(color: t.text)),
                      onTap: () => Navigator.of(ctx).pop(f),
                    ),
                ],
              ),
      ),
    );
    if (picked == null || !mounted) return;
    await _act(
        (tk) => _api!.tournamentInvite(tk, picked.id, eventId: eventId));
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
              const SimpleTopBar(title: 'البطولات'),
              Expanded(child: _body(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BeloteTheme t) {
    if (_token == null) {
      return Center(
        child: Text('سجّل الدخول للمشاركة في البطولات',
            style: TextStyle(color: t.text2)),
      );
    }
    final fatal = _fatal;
    if (fatal != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fatal, style: TextStyle(color: t.text2)),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                setState(() => _fatal = null);
                _refresh();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    final st = _state;
    if (st == null) {
      return Center(child: CircularProgressIndicator(color: t.accent));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        if (st.lastChampions.isNotEmpty) _champions(t, st),
        if (st.inviteFrom != null) _inviteBanner(t, st),
        if (st.myTable != null && st.phase != 'playing')
          _enterButton(t, st.myTable!),
        for (final ev in st.events) _eventCard(t, ev),
        _createEventCard(t),
        if (st.phase == 'playing') ...[
          if (st.myTable != null) _enterButton(t, st.myTable!),
          _bracket(t, st),
        ] else
          _registrationCard(t, st),
      ],
    );
  }

  // ── مسابقات اللاعبين (طلب المالك 2026-07-17) ──

  /// بطاقة «أنشئ مسابقتك» — إنشاءٌ **بدفعٍ إلزاميّ** (50💎 للبيت، غيرُ مستردّ)
  /// وبحدود الخادم (10–500💎 · 8/16 فريقًا · خلال 10د–7 أيّام).
  Widget _createEventCard(BeloteTheme t) => _card(
        t,
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: t.accentBright, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أنشئ مسابقتك',
                      style: TextStyle(
                          color: t.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('باسمك وبرسمٍ تحدّده — رسم الإنشاء 50💎',
                      style: TextStyle(color: t.text2, fontSize: 12)),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: t.accent, foregroundColor: t.bg),
              onPressed: _busy ? null : _openCreateEventSheet,
              child: const Text('أنشئ'),
            ),
          ],
        ),
      );

  Future<void> _openCreateEventSheet() async {
    final t = BeloteTheme.of(context);
    final titleCtl = TextEditingController();
    final feeCtl = TextEditingController(text: '50');
    var teams = 8;
    var startsAt = DateTime.now().add(const Duration(hours: 1));

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('مسابقة جديدة',
                  style: TextStyle(
                      color: t.text, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtl,
                maxLength: 30,
                style: TextStyle(color: t.text),
                cursorColor: t.accent,
                decoration: InputDecoration(
                  labelText: 'اسم المسابقة',
                  labelStyle: TextStyle(color: t.text3),
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: t.line)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: t.accent)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feeCtl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: t.text),
                cursorColor: t.accent,
                decoration: InputDecoration(
                  labelText: 'رسم الدخول (10–500 💎)',
                  labelStyle: TextStyle(color: t.text3),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: t.line)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: t.accent)),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Text('الحجم:', style: TextStyle(color: t.text2)),
                const SizedBox(width: 10),
                for (final n in const [8, 16]) ...[
                  ChoiceChip(
                    label: Text('$n فرق'),
                    selected: teams == n,
                    selectedColor: t.accent,
                    onSelected: (_) => setSheet(() => teams = n),
                  ),
                  const SizedBox(width: 8),
                ],
              ]),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: Icon(Icons.schedule, size: 18, color: t.accentBright),
                label: Text(
                  'الموعد: ${startsAt.day}/${startsAt.month} · '
                  '${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: t.text),
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final day = await showDatePicker(
                    context: ctx,
                    initialDate: startsAt,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 7)),
                  );
                  if (day == null || !ctx.mounted) return;
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(startsAt),
                  );
                  if (time == null) return;
                  setSheet(() => startsAt = DateTime(
                      day.year, day.month, day.day, time.hour, time.minute));
                },
              ),
              const SizedBox(height: 10),
              // **الصدقُ قبل الدفع**: ماذا يدفع وماذا لا يناله.
              Text(
                'رسم الإنشاء 50💎 غير مستردّ. رسوم المشاركين صندوقُ الفائزين '
                '(البيت يقتطع 20%) — لا نصيبَ للمنشئ منها؛ المسابقة باسمك.',
                style: TextStyle(color: t.text3, fontSize: 11.5, height: 1.6),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: t.bg,
                    minimumSize: const Size.fromHeight(46)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('أنشئ المسابقة — 50💎',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
    if (submitted != true || !mounted) return;

    final fee = int.tryParse(feeCtl.text.trim()) ?? 0;
    await _act((tk) => _api!.tournamentCreateEvent(
          tk,
          title: titleCtl.text.trim(),
          startsAt: startsAt,
          entryFee: fee,
          teams: teams,
        ));
  }

  // ── الفعاليات المجدولة ──

  /// عدٌّ تنازليّ مقروء: ساعاتٌ ودقائق للموعد البعيد، ودقائق:ثوانٍ للقريب.
  static String _countdown(int seconds) {
    if (seconds >= 3600) {
      final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60;
      return '$h س $m د';
    }
    return _mmss(seconds);
  }

  Widget _eventCard(BeloteTheme t, EventView ev) {
    final playing = ev.phase == 'playing';
    return _card(
      t,
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration_outlined, color: t.accentBright, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(ev.title,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              _chip(
                  t,
                  playing
                      ? 'جارية الآن'
                      : ev.creatorName.isNotEmpty
                          ? 'مسابقة لاعب'
                          : 'فعاليّة'),
            ],
          ),
          if (ev.creatorName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('ينظّمها: ${ev.creatorName}',
                style: TextStyle(
                    color: t.accentBright,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 6),
          Text(
              'الدخول: ${ev.entryFee}💎  ·  المسجّلون: ${ev.players}/${ev.size}  ·  الصندوق: ${ev.pool}💎',
              style: TextStyle(color: t.text2, fontSize: 12.5)),
          if (!playing) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.timer_outlined, size: 16, color: t.accentBright),
              const SizedBox(width: 6),
              Text('تبدأ بعد ${_countdown(ev.startsInSeconds)}',
                  style: TextStyle(
                      color: t.accentBright, fontWeight: FontWeight.w700)),
            ]),
          ],
          if (ev.inviteFrom != null) ...[
            const SizedBox(height: 8),
            Text('${ev.inviteFrom} يدعوك شريكًا له في هذه الفعاليّة 🤝',
                style: TextStyle(color: t.text, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: t.accent, foregroundColor: t.bg),
                onPressed: _busy
                    ? null
                    : () => _act(
                        (tk) => _api!.tournamentAccept(tk, eventId: ev.id)),
                child: const Text('اقبل'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _act(
                        (tk) => _api!.tournamentDecline(tk, eventId: ev.id)),
                child: const Text('ارفض'),
              ),
            ]),
          ] else if (!playing) ...[
            const SizedBox(height: 10),
            ev.registered
                ? Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _act((tk) =>
                                _api!.tournamentUnregister(tk, eventId: ev.id)),
                        child: const Text('انسحب واسترد رسمك'),
                      ),
                    ),
                    if (ev.partner == null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed:
                            _busy ? null : () => _pickPartner(eventId: ev.id),
                        icon: const Icon(Icons.group_add_outlined, size: 18),
                        label: const Text('ادعُ شريكًا'),
                      ),
                    ],
                  ])
                : FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: t.accent,
                        foregroundColor: t.bg,
                        minimumSize: const Size.fromHeight(44)),
                    onPressed: _busy
                        ? null
                        : () => _act((tk) =>
                            _api!.tournamentRegister(tk, eventId: ev.id)),
                    child: Text('سجّل — ${ev.entryFee}💎'),
                  ),
          ],
          if (ev.partner != null) ...[
            const SizedBox(height: 6),
            Text('شريكك: ${ev.partner} 🤝',
                style: TextStyle(
                    color: t.accentBright, fontWeight: FontWeight.w700)),
          ],
          // مسابقتي أنا ولمّا تبدأ ⇒ أستطيع إلغاءها (ردٌّ كاملٌ للمسجّلين؛
          // رسمُ الإنشاء لا يعود — يقولها الحوار بصدقٍ قبل التأكيد).
          if (ev.mine && !playing) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: t.error,
                  side: BorderSide(color: t.error.withValues(alpha: 0.6))),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('ألغِ مسابقتك'),
              onPressed: _busy ? null : () => _cancelMyEvent(ev),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancelMyEvent(EventView ev) async {
    final t = BeloteTheme.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('إلغاء «${ev.title}»؟', style: TextStyle(color: t.text)),
        content: Text(
          'تُردُّ رسومُ المسجّلين (${ev.players}) كاملةً. '
          'رسمُ الإنشاء (50💎) لا يعود.',
          style: TextStyle(color: t.text2, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('تراجُع', style: TextStyle(color: t.text3)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: t.error, foregroundColor: t.onAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ألغِ المسابقة'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    await _act((tk) => _api!.tournamentCancelEvent(tk, ev.id));
  }

  // ── أبطال آخر بطولة ──

  Widget _champions(BeloteTheme t, TournamentState st) => _card(
        t,
        highlight: true,
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: t.accentBright, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('أبطال آخر بطولة',
                      style: TextStyle(
                          color: t.text, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    [
                      for (final c in st.lastChampions)
                        '${c.name} (+${c.prize}💎)'
                    ].join(' · '),
                    style: TextStyle(color: t.text2, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ── دعوة الشراكة الواردة ──

  Widget _inviteBanner(BeloteTheme t, TournamentState st) => _card(
        t,
        highlight: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${st.inviteFrom} يدعوك شريكًا له 🤝',
                style: TextStyle(color: t.text, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
                st.registered
                    ? 'بقبولك تُثبَّتان شريكين على طاولةٍ واحدة.'
                    : 'بقبولك تُسجَّل وتدفع رسمَك (${st.entryFee}💎) وتُثبَّتان شريكين.',
                style: TextStyle(color: t.text2, fontSize: 12.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: t.accent, foregroundColor: t.bg),
                  onPressed: _busy
                      ? null
                      : () => _act((tk) => _api!.tournamentAccept(tk)),
                  child: const Text('اقبل'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _act((tk) => _api!.tournamentDecline(tk)),
                  child: const Text('ارفض'),
                ),
              ],
            ),
          ],
        ),
      );

  // ── بطاقة التسجيل ──

  Widget _registrationCard(BeloteTheme t, TournamentState st) {
    final ends = _endsIn;
    return _card(
      t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.accent.withValues(alpha: 0.16),
                  border: Border.all(color: t.accent.withValues(alpha: 0.5)),
                ),
                child: Icon(Icons.emoji_events, color: t.accentBright, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('بطولة اليوم',
                            style: TextStyle(
                                color: t.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        _chip(t, 'إقصائيّة ${st.size}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'الدخول: ${st.entryFee}💎 للشخص  ·  الصندوق حتى الآن: ${st.pool}💎',
                        style: TextStyle(color: t.text2, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('الزوج الفائز يقتسم الصندوق — والذكاء يكمل النقص عند البدء.',
              style: TextStyle(color: t.text3, fontSize: 11.5)),
          if (ends != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: t.accentBright),
                const SizedBox(width: 6),
                Text('تبدأ خلال ${_mmss(ends)}',
                    style: TextStyle(
                        color: t.accentBright, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
          if (st.players.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('المسجّلون ${st.players.length}/${st.size}',
                style: TextStyle(color: t.text2, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final p in st.players) _playerChip(t, p)],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: st.registered
                    ? OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () =>
                                _act((tk) => _api!.tournamentUnregister(tk)),
                        child: const Text('انسحب واسترد رسمك'),
                      )
                    : FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: t.accent, foregroundColor: t.bg),
                        onPressed: _busy
                            ? null
                            : () => _act((tk) => _api!.tournamentRegister(tk)),
                        child: Text('سجّل — ${st.entryFee}💎'),
                      ),
              ),
              if (st.registered && st.partner == null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickPartner,
                  icon: const Icon(Icons.group_add_outlined, size: 18),
                  label: const Text('ادعُ شريكًا'),
                ),
              ],
            ],
          ),
          if (st.partner != null) ...[
            const SizedBox(height: 8),
            Text('شريكك: ${st.partner} 🤝',
                style: TextStyle(
                    color: t.accentBright, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Widget _playerChip(BeloteTheme t, TournamentPlayerView p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: p.you ? t.accent.withValues(alpha: 0.14) : t.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: p.you ? t.accent : t.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatar(
                url: p.avatarUrl,
                fallback: p.name.isEmpty ? '؟' : p.name.characters.first,
                size: 22),
            const SizedBox(width: 6),
            Text(p.you ? 'أنت' : p.name,
                style: TextStyle(color: t.text, fontSize: 12.5)),
            if (p.partner != null) ...[
              const SizedBox(width: 4),
              Text('مع ${p.partner}',
                  style: TextStyle(color: t.text3, fontSize: 11)),
            ],
          ],
        ),
      );

  // ── القوس ──

  Widget _enterButton(BeloteTheme t, ({String code, int seat}) table) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: t.accent,
            foregroundColor: t.bg,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: () => _enterTable(table),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('ادخل طاولتك الآن',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      );

  /// اسمُ الجولة من **عدد مبارياتها** لا رقمِها: 1 نهائيّ · 2 نصف · 4 ربع·
  /// وما فوقُ «دور الـN» — فيصحّ لأيّ حجم قوسٍ حتى 512 فريقًا (فتح السعة)
  /// بلا افتراضٍ مقفول. الأرقامُ لاتينيّةٌ دائمًا ([[latin-digits-ui]]).
  static String _roundName(int matchesInRound) => switch (matchesInRound) {
        1 => 'النهائيّ',
        2 => 'نصف النهائيّ',
        4 => 'ربع النهائيّ',
        >= 8 => 'دور الـ${matchesInRound * 2}',
        _ => 'جولة',
      };

  Widget _bracket(BeloteTheme t, TournamentState st) {
    // تجميعُ المباريات بجولتها — الخادمُ يبثّ الموجودَ فقط (التالية تُبنى
    // فور جهوز رافدَيها)، **ويشذّب الجولات الضخمة** في الفعاليات الكبيرة
    // (يُبقي مبارياتي + الجولات الصغيرة، و`roundsInfo` يُجمل الباقي).
    final byRound = <int, List<BracketMatchView>>{};
    for (final m in st.bracket) {
      byRound.putIfAbsent(m.round, () => []).add(m);
    }
    final infoOf = {for (final r in st.roundsInfo) r.round: r};
    // الجولاتُ المعروضة: ما وصل منه مباريات، وما يذكره المُجمل (created > 0).
    final rounds = {
      ...byRound.keys,
      for (final r in st.roundsInfo)
        if (r.created > 0) r.round,
    }.toList()
      ..sort();
    final lastRound = rounds.isEmpty ? -1 : rounds.last;
    final finalReached = lastRound >= 0 &&
        (infoOf[lastRound]?.matches ?? byRound[lastRound]!.length) == 1;

    /// حجمُ الجولة الكامل: من المُجمل إن وُجد (الحقيقة النظريّة)، وإلّا
    /// اشتقاقُ ما قبل المُجمل: الافتتاحُ بعدده، وما بعده نصفُ سابقتها.
    int fullSize(int r) =>
        infoOf[r]?.matches ??
        (r == 0
            ? byRound[0]!.length
            : (byRound[r - 1]?.length ?? byRound[r]!.length * 2) ~/ 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rounds) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(_roundName(fullSize(r)),
                style:
                    TextStyle(color: t.text2, fontWeight: FontWeight.w800)),
          ),
          // جولةٌ مشذَّبة: يظهر تقدّمُها إجمالًا، ثمّ مبارياتي إن وصلت.
          if ((infoOf[r]?.created ?? 0) > (byRound[r]?.length ?? 0))
            _card(t,
                child: Text(
                    'حُسمت ${infoOf[r]!.finished} من ${infoOf[r]!.matches} مباراة'
                    '${(byRound[r]?.isNotEmpty ?? false) ? ' — تُعرَض مباراتُك' : ''}',
                    style: TextStyle(color: t.text3))),
          for (final m in ((byRound[r] ?? [])
            ..sort((a, b) => a.index.compareTo(b.index))))
            _matchCard(t, m),
        ],
        if (!finalReached)
          _card(t,
              child: Text('الجولة التالية تُبنى فور حسم مبارياتها الرافدة…',
                  style: TextStyle(color: t.text3))),
      ],
    );
  }

  Widget _matchCard(BeloteTheme t, BracketMatchView m) => _card(
        t,
        child: Column(
          children: [
            _teamRow(t, m, 0),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Divider(color: t.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: m.live
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: t.accentBright,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text('جارية',
                                  style: TextStyle(
                                      color: t.accentBright, fontSize: 11.5)),
                            ],
                          )
                        : Text('ضدّ',
                            style:
                                TextStyle(color: t.text3, fontSize: 11.5)),
                  ),
                  Expanded(child: Divider(color: t.line)),
                ],
              ),
            ),
            _teamRow(t, m, 1),
          ],
        ),
      );

  Widget _teamRow(BeloteTheme t, BracketMatchView m, int team) {
    final won = m.winnerTeam == team;
    final lost = m.winnerTeam != null && !won;
    final color = lost ? t.text3 : t.text;
    return Row(
      children: [
        if (won) ...[
          Icon(Icons.emoji_events, size: 16, color: t.accentBright),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Wrap(
            spacing: 10,
            children: [
              for (final s in m.team(team))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (s.bot)
                      Icon(Icons.smart_toy_outlined, size: 16, color: t.text3)
                    else
                      PlayerAvatar(
                          url: s.avatarUrl,
                          fallback:
                              s.name.isEmpty ? '؟' : s.name.characters.first,
                          size: 20),
                    const SizedBox(width: 5),
                    Text(
                      s.bot ? 'ذكاء' : (s.you ? 'أنت' : s.name),
                      style: TextStyle(
                        color: s.you ? t.accentBright : color,
                        fontWeight:
                            won || s.you ? FontWeight.w800 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── مشتركات ──

  Widget _card(BeloteTheme t, {required Widget child, bool highlight = false}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.surface2, t.surface],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: highlight ? t.accent : t.line,
              width: highlight ? 1.4 : 1),
          boxShadow: [
            BoxShadow(color: t.shadow, blurRadius: 14, offset: const Offset(0, 6))
          ],
        ),
        child: child,
      );

  Widget _chip(BeloteTheme t, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.line)),
        child: Text(label, style: TextStyle(color: t.text2, fontSize: 10.5)),
      );

  static String _mmss(int seconds) {
    final m = seconds ~/ 60, s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
