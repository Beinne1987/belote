import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'dm_screen.dart';
import 'honor_badge.dart';
import 'player_avatar.dart';
import 'player_tag_chip.dart';
import 'simple_top_bar.dart';

/// شاشة الأصدقاء — **بياناتٌ حقيقيّة** من `/me/friends`.
///
/// كانت صدفةً بخمسة أصدقاءَ وهميّين وشارةِ «متصل» مخترَعة. النقطة الخضراء بالذات كانت
/// كذبةً على اللاعب: لا الخادمُ يعرف الحضور ولا العميل — فلم أُبقِها. تعود يوم يُبنى
/// الحضور فعلًا (تحتاجه الدعوة أيضًا).
///
/// ثلاث قوائم: **الوارد أوّلًا** (ينتظر ردًّا منك ⇒ فعلٌ مطلوب)، ثمّ الأصدقاء، ثمّ
/// الصادر (تنتظر ردَّهم ⇒ خبرٌ لا فعل).
class FriendsScreen extends StatefulWidget {
  /// حقنٌ للاختبار؛ الإنتاج يقرأ من [SessionScope].
  final ApiClient? api;
  final String? token;
  const FriendsScreen({super.key, this.api, this.token});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  ApiClient? _api;
  String? _token;
  String _myId = ''; // لشاشة المحادثة — ملكيّةُ الرسالة تُشتقّ منه
  Future<FriendLists>? _future;
  bool _busy = false; // فعلٌ جارٍ (قبول/إزالة) ⇒ لا نقراتٍ متتالية

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) return; // مرّةً واحدة
    // بحثٌ **بلا فرض**: `SessionScope.of` يؤكّد وجود النطاق فيرمي خارج شجرة التطبيق.
    // الشاشة تعمل بتوكنٍ محقونٍ أيضًا (اختبارات)، فلا تفرض ما لا تحتاجه.
    final session = context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
    _api = widget.api ?? session?.api ?? ApiClient();
    _token = widget.token ?? session?.session?.token;
    _myId = session?.player?.id ?? '';
    _reload();
  }

  void _reload() {
    final token = _token;
    // **كتلةٌ لا سهم**: `setState(() => _future = ...)` يُعيد قيمةَ الإسناد (Future)
    // فيظنّها Flutter عملًا غير متزامنٍ داخل setState ويرمي.
    final next =
        token == null ? Future.value(const FriendLists()) : _api!.friends(token);
    setState(() {
      _future = next;
    });
  }

  /// ينفّذ فعلًا ثمّ يُعيد التحميل. الخطأ يُعرَض **بالعربيّة** لا برمزٍ خام.
  Future<void> _act(Future<void> Function() run, String done) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await run();
      if (!mounted) return;
      _toast(done);
      _reload();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(friendErrorText(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));

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
              const SimpleTopBar(title: 'الأصدقاء'),
              if (_token != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: t.accent,
                              foregroundColor: t.onAccent),
                          onPressed: _openAdd,
                          icon: const Icon(Icons.person_add),
                          label: const Text('إضافة بالرمز',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // المحظورون: بابُ الفكّ — الحظرُ نفسُه من المحادثة/الطاولة.
                      IconButton(
                        onPressed: _openBlocked,
                        tooltip: 'المحظورون',
                        icon: Icon(Icons.block, color: t.text3),
                      ),
                    ],
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
    if (_token == null) {
      return _empty(t, Icons.person_outline, 'سجّل الدخول لترى أصدقاءك.');
    }
    return FutureBuilder<FriendLists>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: t.accent));
        }
        if (snap.hasError) {
          return _empty(t, Icons.wifi_off, 'تعذّر جلب الأصدقاء.', onRetry: _reload);
        }
        final d = snap.data ?? const FriendLists();
        if (d.isEmpty) {
          return _empty(t, Icons.group_add_outlined,
              'لا أصدقاء بعد.\nاطلب رمز صاحبك (٦ خانات) وأضفه.');
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // الوارد أوّلًا: هو وحده الذي ينتظر فعلًا منك.
            if (d.incoming.isNotEmpty) ...[
              _header(t, 'يطلبون صداقتك', d.incoming.length),
              for (final p in d.incoming) _row(t, p, incoming: true),
            ],
            if (d.friends.isNotEmpty) ...[
              _header(t, 'أصدقاؤك', d.friends.length),
              for (final p in d.friends) _row(t, p, friend: true),
            ],
            if (d.outgoing.isNotEmpty) ...[
              _header(t, 'بانتظار ردّهم', d.outgoing.length),
              for (final p in d.outgoing) _row(t, p),
            ],
          ],
        );
      },
    );
  }

  Widget _header(BeloteTheme t, String title, int n) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Row(
          children: [
            Text(title,
                style: TextStyle(
                    color: t.text2, fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text(
              '$n',
              // الأرقام لاتينيّة دائمًا (قاعدة المشروع).
              textDirection: TextDirection.ltr,
              style: TextStyle(color: t.text3, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _row(BeloteTheme t, FriendPlayer p, {bool incoming = false, bool friend = false}) {
    final name = p.displayName.trim().isEmpty ? 'لاعب' : p.displayName;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              // **VIP يظهر لأصدقائه** (نصُّ المالك 2026-07-16) — بإطاره الدائريّ.
              p.isVip
                  ? SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PlayerAvatar(
                            url: p.avatarUrl,
                            fallback: name.characters.first,
                            size: 36,
                            borderColor: const Color(0x00000000),
                          ),
                          IgnorePointer(
                            child: Image.asset('assets/VIP/frame_gold_round.png',
                                width: 56, height: 56),
                          ),
                        ],
                      ),
                    )
                  : PlayerAvatar(
                      url: p.avatarUrl,
                      fallback: name.characters.first,
                      size: 40,
                      borderColor: t.surface2,
                    ),
              // النقطة **للأصدقاء وحدهم**: الطلب المعلّق لا يحمل حضورًا أصلًا
              // (الخادم لا يكشفه قبل الصداقة) ⇒ لا نرسم رماديًّا يوهم بالغياب.
              if (friend)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: p.online ? t.success : t.text3,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: t.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                    const SizedBox(width: 5),
                    PlayerHonorBadge(playerId: p.id),
                  ],
                ),
                if (friend)
                  Text(p.online ? 'متصل' : 'غير متصل',
                      style: TextStyle(
                          color: p.online ? t.success : t.text3, fontSize: 12)),
                if (p.tag.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  PlayerTagChip(tag: p.tag),
                ],
              ],
            ),
          ),
          // **المحادثة للأصدقاء** — بشارة غير المقروء من الخادم.
          if (friend)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, color: t.accentBright),
                  tooltip: 'محادثة',
                  onPressed: () => _openDm(p),
                ),
                if (p.unread > 0)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: t.error,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          '${p.unread}',
                          // الأرقام لاتينيّة دائمًا (قاعدة المشروع).
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          if (incoming)
            IconButton(
              icon: Icon(Icons.check_circle, color: t.success),
              tooltip: 'اقبل',
              onPressed: _busy
                  ? null
                  : () => _act(() => _api!.acceptFriend(_token!, p.id), 'صرتما صديقين'),
            ),
          IconButton(
            icon: Icon(incoming ? Icons.cancel : Icons.person_remove_outlined,
                color: t.text3),
            tooltip: incoming ? 'ارفض' : (friend ? 'احذف من الأصدقاء' : 'اسحب الطلب'),
            onPressed: _busy ? null : () => _confirmRemove(p, incoming: incoming, friend: friend),
          ),
        ],
      ),
    );
  }

  /// فكُّ الصداقة وحده يُستأذَن فيه: الرفضُ والسحبُ فعلان صغيران يُعادان بنقرة،
  /// أمّا حذفُ صديقٍ فيُفقد علاقةً بُنيت — والنقرة الخاطئة تقع على أيقونةٍ مجاورة.
  Future<void> _confirmRemove(FriendPlayer p, {required bool incoming, required bool friend}) async {
    final t = BeloteTheme.of(context);
    if (friend) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: t.surface,
          title: Text('حذف صديق', style: TextStyle(color: t.text)),
          content: Text('تحذف ${p.displayName} من أصدقائك؟',
              style: TextStyle(color: t.text2)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('تراجع', style: TextStyle(color: t.text2))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('احذف', style: TextStyle(color: t.error))),
          ],
        ),
      );
      if (ok != true) return;
    }
    await _act(() => _api!.removeFriend(_token!, p.id),
        incoming ? 'رُفض الطلب' : (friend ? 'حُذف الصديق' : 'سُحب الطلب'));
  }

  Future<void> _openAdd() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true, // لوحة المفاتيح لا تغطّي الحقل
      backgroundColor: Colors.transparent,
      builder: (_) => _AddByTagSheet(api: _api!, token: _token!),
    );
    if (added == true) _reload();
  }

  /// يفتح المحادثة، ويُعيد التحميل عند العودة: الشارةُ صُفّرت خادميًّا بالفتح،
  /// وربّما حُظر من داخلها (تُغلَق بـtrue حينها) فسقط من القائمة.
  Future<void> _openDm(FriendPlayer p) async {
    await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) =>
          DmScreen(api: _api!, token: _token!, myId: _myId, other: p),
    ));
    if (mounted) _reload();
  }

  /// لوحة المحظورين — تُجلَب عند الفتح (قائمةٌ نادرة الاستعمال لا تُحمَّل مع
  /// الأصدقاء)، والفكُّ يُعيد تحميل الأصدقاء (قد يعود من فُكّ للظهور بالبحث).
  Future<void> _openBlocked() async {
    final t = BeloteTheme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.gradBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BlockedSheet(api: _api!, token: _token!),
    );
    if (mounted) _reload();
  }

  Widget _empty(BeloteTheme t, IconData icon, String msg, {VoidCallback? onRetry}) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: t.text3, size: 44),
              const SizedBox(height: 12),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.text2, fontSize: 14, height: 1.6)),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                TextButton(
                    onPressed: onRetry,
                    child: Text('أعِد المحاولة', style: TextStyle(color: t.accentBright))),
              ],
            ],
          ),
        ),
      );
}

/// لوحةُ المحظورين — عرضٌ وفكٌّ. الحظرُ نفسُه يقع من المحادثة أو الطاولة
/// (حيث يُرى المُضايِق)، وهنا بابُ التراجع وحده.
class _BlockedSheet extends StatefulWidget {
  final ApiClient api;
  final String token;
  const _BlockedSheet({required this.api, required this.token});

  @override
  State<_BlockedSheet> createState() => _BlockedSheetState();
}

class _BlockedSheetState extends State<_BlockedSheet> {
  List<FriendPlayer>? _blocked; // null ⇒ يُجلَب
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.api.blockedPlayers(widget.token);
      if (mounted) setState(() => _blocked = list);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر جلب القائمة.');
    }
  }

  Future<void> _unblock(FriendPlayer p) async {
    try {
      await widget.api.unblockPlayer(widget.token, p.id);
      if (!mounted) return;
      setState(() => _blocked = [
            for (final x in _blocked!) if (x.id != p.id) x
          ]);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(messageErrorText(e.message), textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block, color: t.text2, size: 20),
                const SizedBox(width: 8),
                Text('المحظورون',
                    style: TextStyle(
                        color: t.text, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: TextStyle(color: t.text2, fontSize: 13))
            else if (_blocked == null)
              Center(child: CircularProgressIndicator(color: t.accent))
            else if (_blocked!.isEmpty)
              Text('لا أحدَ محظور.', style: TextStyle(color: t.text3, fontSize: 13))
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in _blocked!)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            PlayerAvatar(
                              url: p.avatarUrl,
                              fallback: (p.displayName.trim().isEmpty
                                      ? 'لاعب'
                                      : p.displayName)
                                  .characters
                                  .first,
                              size: 34,
                              borderColor: t.surface2,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  p.displayName.trim().isEmpty
                                      ? 'لاعب'
                                      : p.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: t.text,
                                      fontWeight: FontWeight.w700)),
                            ),
                            TextButton(
                              onPressed: () => _unblock(p),
                              child: Text('فكّ الحظر',
                                  style: TextStyle(color: t.accentBright)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// لوحةُ «أضف بالرمز». تُغلق بـ`true` إن تغيّرت القائمة.
class _AddByTagSheet extends StatefulWidget {
  final ApiClient api;
  final String token;
  const _AddByTagSheet({required this.api, required this.token});

  @override
  State<_AddByTagSheet> createState() => _AddByTagSheetState();
}

class _AddByTagSheetState extends State<_AddByTagSheet> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await widget.api.requestFriend(widget.token, _ctrl.text);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          // طلبان متقابلان ⇒ صداقةٌ فورًا: قُل ما وقع فعلًا لا ما طلبه.
          content: Text(
              status == 'accepted' ? 'صرتما صديقين' : 'أُرسل الطلب',
              textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
        ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = friendErrorText(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Padding(
      // يرتفع فوق لوحة المفاتيح.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: t.gradBottom,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: t.accentBright),
                const SizedBox(width: 8),
                Text('إضافة بالرمز',
                    style: TextStyle(
                        color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 6),
            Text('اطلب من صاحبك رمزه (٦ خانات) من ملفّه الشخصيّ.',
                style: TextStyle(color: t.text2, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              // الرمز لاتينيٌّ دائمًا مهما كانت لغة الواجهة (قاعدة المشروع)،
              // وحروفه كبيرةٌ كما تُعرَض — والخادم يطبّع الباقي على أيّ حال.
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8, // ٦ خانات + سماحُ '#' وفراغ
              onSubmitted: (_) => _submit(),
              style: TextStyle(
                  color: t.text,
                  fontSize: 20,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                hintText: 'ABC123',
                hintStyle: TextStyle(color: t.text3, letterSpacing: 3),
                errorText: _error,
                counterText: '',
                filled: true,
                fillColor: t.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.accent),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: t.accent, foregroundColor: t.onAccent),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('أرسل الطلب',
                        style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
