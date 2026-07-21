import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/net/api_client.dart';
import 'package:app/net/table_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/lobby_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// لوبي المقاعد والدعوة — [[private-table-lobby]].
///
/// **التدوير هو ما يُحرَس هنا**: بلا `you` يُدوَّر اللوبي حول المقعد 0 دائمًا، فيرى
/// الجالسُ في المقعد 2 نفسَه «شريكًا لنفسه» ويدعو صاحبَه إلى مقعد خصمه — والعطب
/// **لا يظهر** إلّا بعد أن تبدأ المباراة.
Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(home: Scaffold(body: child)),
    );

LobbySeat _seat(int i, String name) =>
    LobbySeat(seat: i, ai: false, playerId: 'P$i', name: name, connected: true);

FriendPlayer _friend(String id, String name, {bool online = true}) =>
    FriendPlayer(id: id, tag: 'BCDFG$id', displayName: name, online: online);

void main() {
  group('الشكل', () {
    testWidgets('المقاعد الأربعة بأدوارها: أنت · شريكك · خصمك مرّتين', (t) async {
      await t.pumpWidget(_wrap(LobbyTable(
        seats: [_seat(0, 'أنا'), null, null, null],
        onInvite: (_) {},
      )));

      expect(find.text('أنت'), findsOneWidget);
      expect(find.text('شريكك'), findsOneWidget, reason: 'المقابل شريك');
      expect(find.text('خصمك'), findsNWidgets(2), reason: 'الجانبان خصمان');
      expect(find.text('أنا'), findsOneWidget);
    });

    testWidgets('المقعد الفارغ **زرُّ دعوةٍ** لا لافتةُ انتظار', (t) async {
      final invited = <int>[];
      await t.pumpWidget(_wrap(LobbyTable(
        seats: [_seat(0, 'أنا'), null, null, null],
        onInvite: invited.add,
      )));

      expect(find.text('ادعُ'), findsNWidgets(3), reason: 'ثلاثة فوارغ');
      // اضغط «ادعُ» أعلى الشاشة = المقعد المقابل = الشريك.
      await t.tap(find.text('ادعُ').at(1));
      expect(invited, isNotEmpty);
    });

    testWidgets('مقعدٌ مشغولٌ يعرض الاسم بلا زرّ دعوة', (t) async {
      await t.pumpWidget(_wrap(LobbyTable(
        seats: [_seat(0, 'أنا'), null, _seat(2, 'سالم'), null],
        onInvite: (_) {},
      )));
      expect(find.text('سالم'), findsOneWidget);
      expect(find.text('ادعُ'), findsNWidgets(2), reason: 'بقي فارغان');
    });
  });

  group('منتقي الصديق', () {
    // **غيرُ المتّصل يُدعى كذلك**: كان معطَّلًا يوم كانت الدعوة لا تُسلَّم إلّا
    // عبر القناة الحيّة؛ وهي اليوم تصل إشعارًا إلى هاتفه.
    testWidgets('المتّصل وغيرُ المتّصل كلاهما قابلٌ للدعوة', (t) async {
      FriendPlayer? picked;
      await t.pumpWidget(_wrap(Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () async {
            picked = await pickFriendForSeat(
              ctx,
              friends: [
                _friend('A', 'سالم'),
                _friend('B', 'مريم', online: false),
              ],
              seatRole: 'شريكًا لك',
            );
          },
          child: const Text('افتح'),
        ),
      )));
      await t.tap(find.text('افتح'));
      await t.pumpAndSettle();

      expect(find.text('من يجلس شريكًا لك؟'), findsOneWidget,
          reason: 'الدور يُسمّى — هو كلّ معنى الدعوة إلى مقعد');
      expect(find.text('سالم'), findsOneWidget);
      expect(find.text('مريم'), findsOneWidget);
      expect(find.textContaining('يصله إشعار'), findsOneWidget,
          reason: 'يُقال للداعي كيف تصل دعوتُه، لا «غير متصل» وكفى');

      await t.tap(find.text('مريم')); // غير متّصل ⇒ يُختار ويصله إشعار
      await t.pumpAndSettle();
      expect(picked?.id, 'B');

      await t.tap(find.text('افتح'));
      await t.pumpAndSettle();
      await t.tap(find.text('سالم'));
      await t.pumpAndSettle();
      expect(picked?.id, 'A');
    });

    testWidgets('لا صديقَ متّصل ⇒ يقول إنّ الدعوة تصل إشعارًا', (t) async {
      await t.pumpWidget(_wrap(Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => pickFriendForSeat(ctx,
              friends: [_friend('B', 'مريم', online: false)], seatRole: 'خصمًا لك'),
          child: const Text('افتح'),
        ),
      )));
      await t.tap(find.text('افتح'));
      await t.pumpAndSettle();
      expect(find.textContaining('يصله إشعارٌ على هاتفه'), findsOneWidget);
    });

    testWidgets('لا أصدقاء البتّة ⇒ يدلّ على شاشة الأصدقاء', (t) async {
      await t.pumpWidget(_wrap(Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => pickFriendForSeat(ctx, friends: const [], seatRole: 'شريكًا لك'),
          child: const Text('افتح'),
        ),
      )));
      await t.tap(find.text('افتح'));
      await t.pumpAndSettle();
      expect(find.textContaining('أضِف صاحبك برمزه'), findsOneWidget);
    });
  });

  group('الكنترولر: التدوير والدعوة', () {
    late StreamController<String> incoming;
    late List<String> sent;
    late OnlineGameController c;

    void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));

    Map<String, dynamic> lobby({required int you}) => {
          'phase': 'lobby',
          'tableId': 't1',
          'code': 'WXYZ',
          'you': you,
          'seats': [
            for (var i = 0; i < 4; i++)
              if (i == you)
                {'seat': i, 'ai': false, 'playerId': 'ME', 'name': 'أنا', 'connected': true}
              else
                {'seat': i, 'ai': true},
          ],
        };

    setUp(() {
      incoming = StreamController<String>.broadcast();
      sent = [];
      c = OnlineGameController(
        LiveTableClient(incoming: incoming.stream, send: sent.add),
      );
    });

    test('mySeat يأتي من `you` قبل بدء المباراة', () async {
      feed(lobby(you: 3));
      await Future<void>.delayed(Duration.zero);
      expect(c.mySeat, 3, reason: 'بلا هذا يُدوَّر اللوبي حول 0 دائمًا');
    });

    test('**الدعوة إلى المقابل تعني الشريك** مهما كان مقعدي', () async {
      // مقعدي 1 ⇒ شريكي هو مقعد الخادم 3.
      feed(lobby(you: 1));
      await Future<void>.delayed(Duration.zero);

      c.inviteToSeat('F1', 2); // 2 = المقابل بالعرض = الشريك
      expect(jsonDecode(sent.last), {'type': 'invite', 'playerId': 'F1', 'seat': 3});

      c.inviteToSeat('F2', 1); // يميني بالعرض ⇒ خادم 2
      expect(jsonDecode(sent.last), {'type': 'invite', 'playerId': 'F2', 'seat': 2});
    });

    test('خادمٌ بلا `you` ⇒ لا تدوير (لا انهيار)', () async {
      final m = lobby(you: 0)..remove('you');
      feed(m);
      await Future<void>.delayed(Duration.zero);
      expect(c.mySeat, 0);
    });

    test('الدعوة الواردة تُعرَض، والقبول ينضمّ **بمقعدها**', () async {
      feed({
        'phase': 'invite',
        'from': {'id': 'F1', 'displayName': 'سالم', 'tag': 'BCDFGH'},
        'code': 'WXYZ',
        'seat': 2,
      });
      await Future<void>.delayed(Duration.zero);
      expect(c.invite?.fromName, 'سالم');
      expect(c.invite?.seat, 2);

      c.acceptInvite();
      expect(jsonDecode(sent.last), {'type': 'join', 'code': 'WXYZ', 'seat': 2},
          reason: 'المقعد يُنقل كما دُعي — لا أوّل فارغ');
      expect(c.invite, isNull, reason: 'اللافتة تختفي بعد القبول');
    });

    test('**الأحدث يزيح الأقدم** — نافذتان تُقبَل إحداهما بالخطأ', () async {
      for (final name in ['سالم', 'مريم']) {
        feed({
          'phase': 'invite',
          'from': {'id': 'F', 'displayName': name},
          'code': 'WXYZ',
          'seat': 2,
        });
        await Future<void>.delayed(Duration.zero);
      }
      expect(c.invite?.fromName, 'مريم');
    });

    test('«لاحقًا» تُخفيها بلا انضمام', () async {
      feed({
        'phase': 'invite',
        'from': {'id': 'F1', 'displayName': 'سالم'},
        'code': 'WXYZ',
        'seat': 2,
      });
      await Future<void>.delayed(Duration.zero);
      c.dismissInvite();
      expect(c.invite, isNull);
      expect(sent, isEmpty, reason: 'لا نيّةَ انضمام');
    });

    test('تأكيدُ الوصول يصل الداعي', () async {
      feed({'phase': 'inviteSent', 'playerId': 'F1', 'seat': 2});
      await Future<void>.delayed(Duration.zero);
      expect(c.inviteSentTo, 'F1');
    });

    test('دعوةٌ بحقولٍ ناقصة ⇒ لا انهيار', () async {
      feed({'phase': 'invite'});
      await Future<void>.delayed(Duration.zero);
      expect(c.invite?.fromName, 'صديقك', reason: 'اسمٌ بديلٌ لا استثناء');
      expect(c.invite?.code, '');
    });
  });

  group('البحث عن بشرٍ قبل الذكاء (#8)', () {
    test('`searching` تُقرأ من اللقطة', () async {
      final incoming = StreamController<String>.broadcast();
      final c = OnlineGameController(
        LiveTableClient(incoming: incoming.stream, send: (_) {}),
      );
      incoming.add(jsonEncode({
        'phase': 'lobby',
        'tableId': 't1',
        'code': 'WXYZ',
        'you': 0,
        'searching': true,
        'seats': [
          {'seat': 0, 'ai': false, 'playerId': 'ME', 'name': 'أنا', 'connected': true},
          {'seat': 1, 'ai': true},
          {'seat': 2, 'ai': true},
          {'seat': 3, 'ai': true},
        ],
      }));
      await Future<void>.delayed(Duration.zero);
      expect(c.lobby?.searching, isTrue);
    });

    test('خادمٌ بلا الحقل ⇒ false لا انهيار', () async {
      final incoming = StreamController<String>.broadcast();
      final c = OnlineGameController(
        LiveTableClient(incoming: incoming.stream, send: (_) {}),
      );
      incoming.add(jsonEncode({
        'phase': 'lobby',
        'tableId': 't1',
        'code': 'WXYZ',
        'seats': <Map<String, dynamic>>[],
      }));
      await Future<void>.delayed(Duration.zero);
      expect(c.lobby?.searching, isFalse);
    });
  });
}
