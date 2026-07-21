import 'package:flutter/material.dart';

import '../game/online_game_controller.dart' show ChatLogEntry;
import '../game/quick_chat.dart';
import '../game/seat_player.dart';
import '../theme/belote_theme.dart';

/// **لوحةُ الدردشة** — نصٌّ حرٌّ، والعباراتُ الجاهزةُ ردودٌ سريعةٌ على حافّتها
/// (قرار المالك 2026-07-16: «خلِّ الدردشةَ الجاهزةَ كردٍّ جاهزٍ في شريطٍ على حافّة
/// الدردشة الحرّة»).
///
/// **مفصولةٌ عن الكنترولر بالحقن**: تأخذ [listenable] لتُعيد البناءَ حيًّا،
/// ودالّاتٍ للقراءة والإرسال — فتُختبَر بلا شبكةٍ ولا كنترولر.
Future<void> showChatSheet(
  BuildContext context, {
  required Listenable listenable,
  required List<ChatLogEntry> Function() log,
  required List<SeatPlayer> Function() seats,
  required void Function(String phraseId) onPhrase,
  required void Function(String text) onText,
  void Function(ChatLogEntry entry)? onReportEntry,
}) {
  final t = BeloteTheme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.surface,
    isScrollControlled: true, // كي ترتفع فوق لوحة المفاتيح
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ChatSheet(
      listenable: listenable,
      log: log,
      seats: seats,
      onPhrase: onPhrase,
      onText: onText,
      onReportEntry: onReportEntry,
    ),
  );
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet({
    required this.listenable,
    required this.log,
    required this.seats,
    required this.onPhrase,
    required this.onText,
    this.onReportEntry,
  });

  final Listenable listenable;
  final List<ChatLogEntry> Function() log;
  final List<SeatPlayer> Function() seats;
  final void Function(String phraseId) onPhrase;
  final void Function(String text) onText;

  /// ضغطةٌ مطوّلة على رسالة **غيري** ⇒ بلاغ/حظر (UGC: البلاغ حيث يُرى المحتوى).
  /// null ⇒ لا فعلَ (اختبارات · سياقٌ بلا جلسة).
  final void Function(ChatLogEntry entry)? onReportEntry;

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // رسالةٌ جديدةٌ ⇒ انزل إلى القاع (كل تطبيق دردشة).
    widget.listenable.addListener(_scrollToEnd);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_scrollToEnd);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    widget.onText(text); // الخادمُ ينظّفه ويقصّه — لا عرضَ متفائل
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    // يرتفع فوق لوحة المفاتيح.
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // مقبض + عنوان
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      color: t.accentBright, size: 20),
                  const SizedBox(width: 8),
                  Text('الدردشة',
                      style: TextStyle(
                          color: t.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: t.text3),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: t.line),
            // ── سجلّ الرسائل ──
            Expanded(
              child: ListenableBuilder(
                listenable: widget.listenable,
                builder: (context, _) {
                  final entries = widget.log();
                  if (entries.isEmpty) {
                    return Center(
                      child: Text('لا رسائلَ بعد — ابدأ الحديث.',
                          style: TextStyle(color: t.text3, fontSize: 13)),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => _bubble(t, entries[i]),
                  );
                },
              ),
            ),
            // ── شريطُ الردود الجاهزة على حافّة الإدخال ──
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final e in quickChatPhrases.entries)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ActionChip(
                        label: Text(e.value,
                            style: TextStyle(color: t.text, fontSize: 12.5)),
                        backgroundColor: t.surface2,
                        side: BorderSide(color: t.line),
                        onPressed: () => widget.onPhrase(e.key),
                      ),
                    ),
                ],
              ),
            ),
            // ── إدخالُ النصّ الحرّ ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      maxLength: 200, // مطابقٌ لحدّ الخادم — لا نُطيل ما يُقصّ
                      buildCounter: (_,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null, // بلا عدّادٍ يشغل السطر
                      style: TextStyle(color: t.text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالةً…',
                        hintStyle: TextStyle(color: t.text3),
                        filled: true,
                        fillColor: t.surface2,
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
                    icon: Icon(Icons.send, color: t.onAccent, size: 20),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(BeloteTheme t, ChatLogEntry e) {
    final seatsNow = widget.seats();
    final name = e.mine
        ? 'أنت'
        : (e.viewSeat >= 0 && e.viewSeat < seatsNow.length
            ? seatsNow[e.viewSeat].name
            : 'لاعب');
    // البلاغُ على رسالة **بشريٍّ غيري** وحدها: رسالتي لا أُبلغ عنها، والذكاء
    // لا معرّفَ له (senderId=null) ولا معنى للبلاغ عنه.
    final reportable =
        !e.mine && e.senderId != null && widget.onReportEntry != null;
    return Align(
      alignment: e.mine ? Alignment.centerLeft : Alignment.centerRight,
      child: GestureDetector(
        onLongPress: reportable ? () => widget.onReportEntry!(e) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color: e.mine ? t.accent.withValues(alpha: 0.18) : t.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: e.mine ? t.accent : t.line),
          ),
          child: Column(
            crossAxisAlignment:
                e.mine ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              Text(name,
                  style: TextStyle(
                      color: t.accentBright,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(e.text, style: TextStyle(color: t.text, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}
