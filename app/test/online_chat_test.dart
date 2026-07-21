import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/net/table_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// **دردشة الكنترولر** (قرار المالك 2026-07-15: نصٌّ حرٌّ، والجاهزةُ ردودٌ سريعة).
///
/// جوهرُ ما يُفحص: **النصُّ يُحسَم في الكنترولر** — الحرُّ حرفيًّا والجاهزُ
/// مُترجَمًا والمجهولُ يسقط — والشاشةُ تعرض ما وصلها بلا رأي. والسجلُّ يحفظ
/// ما تُفلته الفقاعةُ العابرة، مقصوصًا كي لا تصير الطاولةُ غرفةَ محادثة.
(OnlineGameController, void Function(Map<String, dynamic>), List<Map<String, dynamic>>)
    _harness() {
  final incoming = StreamController<String>.broadcast();
  final sent = <Map<String, dynamic>>[];
  final client = LiveTableClient(
    incoming: incoming.stream,
    send: (s) => sent.add(jsonDecode(s) as Map<String, dynamic>),
  );
  final c = OnlineGameController(client);
  void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));
  return (c, feed, sent);
}

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  test('نصٌّ حرٌّ من الخادم ⇒ فقاعةٌ حرفيّة + سطرٌ في السجلّ', () async {
    final (c, feed, _) = _harness();
    feed({'phase': 'chat', 'seat': 2, 'text': 'يا سلام على اللعبة!'});
    await _tick();

    expect(c.chats[2], 'يا سلام على اللعبة!'); // view(2)=(2-0)%4=2
    expect(c.chatLog, hasLength(1));
    expect(c.chatLog.single.text, 'يا سلام على اللعبة!');
    expect(c.chatLog.single.mine, isFalse);
  });

  test('عبارةٌ جاهزةٌ ⇒ تُترجَم نصًّا (لا معرّفَ خامًا في الفقاعة ولا السجلّ)',
      () async {
    final (c, feed, _) = _harness();
    feed({'phase': 'chat', 'seat': 0, 'phrase': 'bravo'});
    await _tick();

    expect(c.chats[0], 'أحسنت');
    expect(c.chatLog.single.text, 'أحسنت');
    expect(c.chatLog.single.mine, isTrue, reason: 'مقعدي 0 ⇒ رسالتي');
  });

  test('معرّفٌ مجهول (خادمٌ أحدث) ⇒ يسقط بلا فقاعةٍ ولا سجلّ', () async {
    final (c, feed, _) = _harness();
    feed({'phase': 'chat', 'seat': 1, 'phrase': 'from_the_future'});
    await _tick();

    expect(c.chats, [null, null, null, null]);
    expect(c.chatLog, isEmpty);
  });

  test('السجلُّ مقصوصٌ عند 60 — يسقط الأقدم لا الأحدث', () async {
    final (c, feed, _) = _harness();
    for (var i = 0; i < 70; i++) {
      feed({'phase': 'chat', 'seat': 1, 'text': 'رسالة $i'});
    }
    await _tick();

    expect(c.chatLog, hasLength(60));
    expect(c.chatLog.first.text, 'رسالة 10');
    expect(c.chatLog.last.text, 'رسالة 69');
  });

  test('chatText يرسل النصَّ الحرَّ للخادم — ولا عرضَ متفائل', () async {
    final (c, _, sent) = _harness();
    c.chatText('مرحبا يا أصحاب');

    expect(sent, [
      {'type': 'chat', 'text': 'مرحبا يا أصحاب'}
    ]);
    expect(c.chatLog, isEmpty, reason: 'يظهر عند بثّ الخادم لا قبله');
  });
}
