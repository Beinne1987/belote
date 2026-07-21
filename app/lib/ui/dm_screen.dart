import 'dart:async';

import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../theme/belote_theme.dart';
import 'player_avatar.dart';

/// **شاشة المحادثة الخاصّة** — رسائلُ حرّةٌ بين صديقين (قرار المالك 2026-07-15:
/// بلا مرشّح ألفاظ؛ الإشرافُ **بلاغٌ وحظرٌ بيد اللاعب** من قائمة الشاشة — إلزامُ
/// متاجر التطبيقات لمحتوى المستخدمين).
///
/// **استطلاعٌ لا بثّ**: الرسالة تعيش خارج الطاولة، والشاشةُ المفتوحة تسأل الخادمَ
/// كلّ [pollEvery] — فتحُ المحادثة خادميًّا هو قراءتُها، فالاستطلاعُ يُصفّر الشارةَ
/// أيضًا. بثٌّ حيٌّ ترفٌ يأتي يوم يلزم.
class DmScreen extends StatefulWidget {
  final ApiClient api;
  final String token;

  /// معرّفي — به تُشتقّ ملكيّةُ كلّ رسالة (`from == myId`).
  final String myId;

  /// الصديق المُحاوَر.
  final FriendPlayer other;

  /// فترة الاستطلاع — حقنٌ للاختبار (لا مؤقّتاتٍ حقيقيّةً في الودجت تست).
  final Duration pollEvery;

  const DmScreen({
    super.key,
    required this.api,
    required this.token,
    required this.myId,
    required this.other,
    this.pollEvery = const Duration(seconds: 3),
  });

  @override
  State<DmScreen> createState() => _DmScreenState();
}

class _DmScreenState extends State<DmScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = const []; // الأقدم أوّلًا (للعرض)
  Timer? _poll;
  bool _loading = true;
  bool _sending = false;
  String? _error; // خطأُ الجلب الأوّل وحده — الاستطلاع يفشل بصمت

  @override
  void initState() {
    super.initState();
    _refresh(first: true);
    _poll = Timer.periodic(widget.pollEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool first = false}) async {
    try {
      final items =
          await widget.api.conversation(widget.token, widget.other.id);
      if (!mounted) return;
      final ordered = items.reversed.toList(); // الخادم يعيد الأحدث أوّلًا
      final grew = ordered.length > _messages.length;
      setState(() {
        _messages = ordered;
        _loading = false;
        _error = null;
      });
      if (first || grew) _scrollToEnd();
    } on ApiException catch (e) {
      if (!mounted || !first) return; // استطلاعٌ تعثّر ⇒ اللقطة السابقة تكفي
      setState(() {
        _loading = false;
        _error = messageErrorText(e.message);
      });
    } catch (_) {
      if (!mounted || !first) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر الاتّصال بالخادم.';
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final m =
          await widget.api.sendMessage(widget.token, widget.other.id, text);
      if (!mounted) return;
      _input.clear();
      setState(() => _messages = [..._messages, m]);
      _scrollToEnd();
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(messageErrorText(e.message));
    } catch (_) {
      if (!mounted) return;
      _toast('تعذّر الإرسال — تحقّق من الاتّصال.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));

  /// حظرُ المُحاوَر: يُستأذَن (قطعٌ شامل يفكّ الصداقة)، ثمّ تُغلَق الشاشة —
  /// لا معنى لمحادثةٍ مفتوحةٍ مع من قطعتَه للتوّ.
  Future<void> _block() async {
    final t = BeloteTheme.of(context);
    final name = widget.other.displayName;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('حظر $name؟', style: TextStyle(color: t.text)),
        content: Text(
            'يُحذف من أصدقائك، ولا يراسلك ولا يدعوك، ولا يصلك كلامه على الطاولة.',
            style: TextStyle(color: t.text2, height: 1.6)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('تراجع', style: TextStyle(color: t.text2))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('احظر', style: TextStyle(color: t.error))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.api.blockPlayer(widget.token, widget.other.id);
      if (!mounted) return;
      Navigator.of(context).pop(true); // true ⇒ القائمة تُعيد التحميل
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(messageErrorText(e.message));
    }
  }

  Future<void> _report() async {
    final sent = await showReportDialog(
      context,
      api: widget.api,
      token: widget.token,
      playerId: widget.other.id,
      playerName: widget.other.displayName,
      area: 'message',
    );
    if (sent && mounted) _toast('وصل بلاغك — سيُراجَع.');
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final name = widget.other.displayName.trim().isEmpty
        ? 'لاعب'
        : widget.other.displayName;
    return Scaffold(
      backgroundColor: t.gradBottom,
      appBar: AppBar(
        backgroundColor: t.gradTop,
        foregroundColor: t.text,
        titleSpacing: 0,
        title: Row(
          children: [
            PlayerAvatar(
              url: widget.other.avatarUrl,
              fallback: name.characters.first,
              size: 34,
              borderColor: t.surface2,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  Text(widget.other.online ? 'متصل' : 'غير متصل',
                      style: TextStyle(
                          color: widget.other.online ? t.success : t.text3,
                          fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: t.text2),
            color: t.surface,
            onSelected: (v) => v == 'block' ? _block() : _report(),
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'report',
                  child: Text('بلاغ عن اللاعب',
                      style: TextStyle(color: t.text))),
              PopupMenuItem(
                  value: 'block',
                  child: Text('حظر', style: TextStyle(color: t.error))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _body(t)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 500, // مطابقٌ لحدّ الخادم — لا نُطيل ما يُقصّ
                      buildCounter: (_,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      style: TextStyle(color: t.text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالةً…',
                        hintStyle: TextStyle(color: t.text3),
                        filled: true,
                        fillColor: t.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: t.accent),
                    icon: _sending
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: t.onAccent))
                        : Icon(Icons.send, color: t.onAccent, size: 20),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BeloteTheme t) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: t.accent));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: t.text2, fontSize: 14)),
            TextButton(
                onPressed: () => _refresh(first: true),
                child: Text('أعِد المحاولة',
                    style: TextStyle(color: t.accentBright))),
          ],
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text('لا رسائلَ بعد — ابدأ الحديث.',
            style: TextStyle(color: t.text3, fontSize: 13)),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _bubble(t, _messages[i]),
    );
  }

  Widget _bubble(BeloteTheme t, ChatMessage m) {
    final mine = m.fromId == widget.myId;
    return Align(
      alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? t.accent.withValues(alpha: 0.18) : t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: mine ? t.accent : t.line),
        ),
        child: Text(m.text,
            style: TextStyle(color: t.text, fontSize: 14, height: 1.5)),
      ),
    );
  }
}

/// **نافذة البلاغ** — تُشارِكها شاشةُ المحادثة ولوحةُ دردشة الطاولة: سببٌ حرٌّ
/// اختياريّ، والموضعُ [area] يمليه المُنادي (`message` · `chat` · `profile`).
/// تُعيد true إن أُرسل.
Future<bool> showReportDialog(
  BuildContext context, {
  required ApiClient api,
  required String token,
  required String playerId,
  required String playerName,
  required String area,
}) async {
  // الحوار يملك متحكّمه ويُغلَق **بالنصّ** (null = تراجُع) — لا متحكّمَ خارجيًّا
  // يُتلَف والحوارُ ما يزال في حركة الإغلاق.
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => _ReportDialog(playerName: playerName),
  );
  if (reason == null) return false;
  try {
    await api.reportPlayer(token, playerId, area: area, reason: reason);
    return true;
  } catch (_) {
    return false; // بلاغٌ تعثّر — لا نُفشل الشاشة لأجله
  }
}

class _ReportDialog extends StatefulWidget {
  final String playerName;
  const _ReportDialog({required this.playerName});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return AlertDialog(
      backgroundColor: t.surface,
      title: Text('بلاغ عن ${widget.playerName}', style: TextStyle(color: t.text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('يصل البلاغ إدارةَ اللعبة وتُراجعه بنفسها.',
              style: TextStyle(color: t.text2, fontSize: 13)),
          const SizedBox(height: 10),
          TextField(
            controller: _reason,
            maxLines: 3,
            maxLength: 300,
            style: TextStyle(color: t.text, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ما الذي حدث؟ (اختياريّ)',
              hintStyle: TextStyle(color: t.text3, fontSize: 13),
              counterText: '',
              filled: true,
              fillColor: t.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('تراجع', style: TextStyle(color: t.text2))),
        TextButton(
            onPressed: () => Navigator.pop(context, _reason.text.trim()),
            child: Text('أبلِغ', style: TextStyle(color: t.error))),
      ],
    );
  }
}
