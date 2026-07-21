import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/dm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// **شاشة المحادثة الخاصّة** بعميلٍ مزيَّف (بلا شبكة): الجلب والعرض والملكيّة،
/// والإرسال بجسمه الصحيح، والحظر (يستأذن ⇒ يقطع ⇒ يُغلق)، والبلاغ.
Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(home: child),
    );

const _other = FriendPlayer(id: 'F1', tag: 'BCDFGH', displayName: 'سالم');

Map<String, dynamic> _msg(String id, String from, String to, String text) => {
      'id': id,
      'from': from,
      'to': to,
      'text': text,
      'createdAt': '2026-07-16T10:00:00Z',
      'read': false,
    };

({ApiClient api, List<String> calls, List<String> bodies}) _fake(
  Map<String, (int, Map<String, dynamic>)> routes,
) {
  final calls = <String>[], bodies = <String>[];
  final client = MockClient((req) async {
    final path = req.url.path;
    final key = routes.keys.firstWhere(path.endsWith, orElse: () => '');
    calls.add('${req.method} ${key.isEmpty ? path : key}');
    if (req.body.isNotEmpty) bodies.add(req.body);
    final r = routes[key] ?? (200, <String, dynamic>{});
    return http.Response(jsonEncode(r.$2), r.$1,
        headers: {'content-type': 'application/json'});
  });
  return (api: ApiClient(httpClient: client), calls: calls, bodies: bodies);
}

DmScreen _screen(ApiClient api) => DmScreen(
      api: api,
      token: 'T',
      myId: 'ME',
      other: _other,
      // فترةٌ طويلة: الاختبار لا ينتظر استطلاعًا — `dispose` يلغي المؤقّت.
      pollEvery: const Duration(minutes: 10),
    );

void main() {
  const convoPath = '/me/messages/with/F1';

  testWidgets('المحادثة تُجلَب وتُعرَض — رسالتي ورسالتُه معًا', (t) async {
    final f = _fake({
      convoPath: (200, {
        'items': [
          _msg('m2', 'F1', 'ME', 'وعليكم السلام'), // الأحدث أوّلًا كالخادم
          _msg('m1', 'ME', 'F1', 'السلام عليكم'),
        ]
      }),
    });
    await t.pumpWidget(_wrap(_screen(f.api)));
    await t.pumpAndSettle();

    expect(find.text('السلام عليكم'), findsOneWidget);
    expect(find.text('وعليكم السلام'), findsOneWidget);
    expect(f.calls, contains('GET $convoPath'));
  });

  testWidgets('الإرسال: POST بجسمه، والردُّ المنظَّف هو ما يُعرَض', (t) async {
    final f = _fake({
      convoPath: (200, {'items': []}),
      '/me/messages/send': (
        200,
        {'message': _msg('m9', 'ME', 'F1', 'أهلًا يا صاحبي')}
      ),
    });
    await t.pumpWidget(_wrap(_screen(f.api)));
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField), '  أهلًا   يا صاحبي ');
    await t.tap(find.byIcon(Icons.send));
    await t.pumpAndSettle();

    expect(f.calls, contains('POST /me/messages/send'));
    final body = jsonDecode(f.bodies.single) as Map<String, dynamic>;
    expect(body['to'], 'F1');
    // ما يُعرَض هو نصُّ الخادم (بعد تنظيفه) لا نصُّ الحقل.
    expect(find.text('أهلًا يا صاحبي'), findsOneWidget);
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty,
        reason: 'الحقل يُفرَّغ بعد الإرسال');
  });

  testWidgets('رفضُ الخادم (حُظرت) يُعرَض بالعربيّة ولا يُفرِّغ الحقل', (t) async {
    final f = _fake({
      convoPath: (200, {'items': []}),
      '/me/messages/send': (403, {'error': 'message_blocked'}),
    });
    await t.pumpWidget(_wrap(_screen(f.api)));
    await t.pumpAndSettle();

    await t.enterText(find.byType(TextField), 'سلام');
    await t.tap(find.byIcon(Icons.send));
    await t.pumpAndSettle();

    expect(find.text('لا يمكن مراسلة هذا اللاعب.'), findsOneWidget);
  });

  testWidgets('الحظر من القائمة: استئذانٌ ⇒ POST /me/blocks ⇒ إغلاق الشاشة',
      (t) async {
    final f = _fake({
      convoPath: (200, {'items': []}),
      '/me/blocks': (200, {'ok': true}),
    });
    await t.pumpWidget(_wrap(_screen(f.api)));
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.more_vert));
    await t.pumpAndSettle();
    await t.tap(find.text('حظر'));
    await t.pumpAndSettle();
    expect(find.textContaining('يُحذف من أصدقائك'), findsOneWidget,
        reason: 'قطعٌ شاملٌ يُستأذَن فيه ويُشرَح أثرُه');
    await t.tap(find.text('احظر'));
    await t.pumpAndSettle();

    expect(f.calls, contains('POST /me/blocks'));
    expect(jsonDecode(f.bodies.single)['playerId'], 'F1');
    expect(find.byType(DmScreen), findsNothing, reason: 'لا محادثةَ مع مقطوع');
  });

  testWidgets('البلاغ من القائمة يرسل الموضعَ message والسبب', (t) async {
    final f = _fake({
      convoPath: (200, {'items': []}),
      '/me/reports': (200, {'ok': true}),
    });
    await t.pumpWidget(_wrap(_screen(f.api)));
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.more_vert));
    await t.pumpAndSettle();
    await t.tap(find.text('بلاغ عن اللاعب'));
    await t.pumpAndSettle();
    await t.enterText(find.widgetWithText(TextField, '').last, 'كلامٌ مؤذٍ');
    await t.tap(find.text('أبلِغ'));
    await t.pumpAndSettle();

    expect(f.calls, contains('POST /me/reports'));
    final body = jsonDecode(f.bodies.single) as Map<String, dynamic>;
    expect(body['playerId'], 'F1');
    expect(body['area'], 'message');
    expect(body['reason'], 'كلامٌ مؤذٍ');
  });
}
