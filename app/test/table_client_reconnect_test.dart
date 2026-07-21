import 'dart:async';
import 'dart:convert';

import 'package:app/net/table_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// مصنعٌ وهميّ للقنوات: كل استدعاءٍ يفتح قناةً جديدة، ونحتفظ بها لنحاكي انقطاعها.
class _FakeChannels {
  final List<StreamController<String>> opened = [];
  final List<String> sent = [];

  WsChannel factory(Uri _) {
    final ctl = StreamController<String>();
    opened.add(ctl);
    return (
      stream: ctl.stream,
      send: (s) => sent.add(s),
      close: () {
        if (!ctl.isClosed) ctl.close();
      },
    );
  }

  StreamController<String> get current => opened.last;
}

void main() {
  test('انقطاعٌ غير مقصود ⇒ إعادة اتصال + استئناف اللقطات', () async {
    final fake = _FakeChannels();
    final client = LiveTableClient.connect(
      Uri.parse('ws://x/ws'),
      retry: const Duration(milliseconds: 10),
      channelFactory: fake.factory,
    );
    final statuses = <ConnStatus>[];
    client.status.listen(statuses.add);
    final events = <TableEvent>[];
    client.events.listen(events.add);

    // القناة الأولى تبثّ لقطة لوبي.
    fake.current.add(jsonEncode({'phase': 'lobby', 'tableId': 't1', 'seats': []}));
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<LobbyEvent>().length, 1);
    expect(fake.opened.length, 1);

    // انقطاعٌ غير مقصود ⇒ يجب أن يعيد الاتصال (قناة ثانية) خلال retry.
    await fake.opened.first.close();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(statuses, contains(ConnStatus.reconnecting));
    expect(fake.opened.length, 2, reason: 'فُتحت قناةٌ جديدة');

    // القناة الثانية تستأنف: لقطةٌ جديدة تصل، والحالة تعود connected.
    fake.current.add(jsonEncode({'phase': 'bidding', 'seat': 0, 'yourTurn': false}));
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<GameEvent>().length, 1);
    expect(statuses.last, ConnStatus.connected);

    // dispose يوقف إعادة المحاولة: إغلاقٌ بعده لا يفتح قناةً جديدة.
    await client.dispose();
    await fake.current.close();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(fake.opened.length, 2);
  });

  test('إرسال النيّات يذهب للقناة الحاليّة بعد إعادة الاتصال', () async {
    final fake = _FakeChannels();
    final client = LiveTableClient.connect(
      Uri.parse('ws://x/ws'),
      retry: const Duration(milliseconds: 5),
      channelFactory: fake.factory,
    );
    fake.current.add(jsonEncode({'phase': 'lobby', 'tableId': 't', 'seats': []}));
    await Future<void>.delayed(Duration.zero);
    await fake.opened.first.close();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    client.quickMatch();
    expect(fake.sent, contains(jsonEncode({'type': 'quick'})));
    await client.dispose();
  });
}
