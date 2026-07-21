import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/tournaments_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// **شاشة البطولات ببياناتٍ حقيقيّة من عميلٍ مزيَّف** — كانت صدفةً بأسماءَ
/// وهميّة («بطولة نواكشوط»)؛ هذه الاختبارات تمنع عودتها: كلُّ ما يُعرَض يجب
/// أن يأتي من ردّ الخادم، وكلُّ زرٍّ يضرب مسارَه الصحيح.
Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        builder: (_, w) =>
            Directionality(textDirection: TextDirection.rtl, child: w!),
        home: child,
      ),
    );

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

/// شاشةٌ بلا استطلاعٍ دوريّ (المؤقّتات تعلّق pumpAndSettle).
Widget _screen(ApiClient api,
        {void Function(({String code, int seat}))? onEnter}) =>
    _wrap(TournamentsScreen(
      api: api,
      token: 'tk',
      pollEvery: Duration.zero,
      onEnterTable: onEnter,
    ));

Map<String, dynamic> _registering({
  bool registered = false,
  List<Map<String, dynamic>> players = const [],
  int? endsIn,
  String? inviteFrom,
  String? partner,
  List<Map<String, dynamic>>? champions,
}) =>
    {
      'phase': 'registering',
      'entryFee': 50,
      'currency': 'diamonds',
      'size': 8,
      'rakePercent': 20,
      'pool': players.length * 40,
      'registered': registered,
      'players': players,
      'bracket': const [],
      if (endsIn != null) 'endsInSeconds': endsIn,
      if (inviteFrom != null) 'inviteFrom': inviteFrom,
      if (partner != null) 'partner': partner,
      if (champions != null) 'lastChampions': champions,
    };

void main() {
  testWidgets('حالة التسجيل: الرسم والصندوق والمسجّلون من الردّ', (t) async {
    final f = _fake({
      '/me/tournament': (
        200,
        _registering(players: [
          {'name': 'أحمد', 'you': true},
          {'name': 'بلال', 'partner': 'جميل'},
        ], endsIn: 95)
      ),
    });
    await t.pumpWidget(_screen(f.api));
    await t.pumpAndSettle();

    expect(find.text('بطولة اليوم'), findsOneWidget);
    expect(find.textContaining('50💎'), findsWidgets);
    expect(find.textContaining('الصندوق حتى الآن: 80💎'), findsOneWidget);
    expect(find.textContaining('المسجّلون 2/8'), findsOneWidget);
    expect(find.text('أنت'), findsOneWidget, reason: 'صاحبُ العرض «أنت» لا اسمه');
    expect(find.text('بلال'), findsOneWidget);
    expect(find.text('مع جميل'), findsOneWidget);
    expect(find.textContaining('تبدأ خلال 1:35'), findsOneWidget);
    expect(find.textContaining('سجّل — 50💎'), findsOneWidget);
  });

  testWidgets('زرّ التسجيل يضرب register والردُّ يقلب الزرّ انسحابًا', (t) async {
    var registered = false;
    final f = _fake({});
    final client = MockClient((req) async {
      final body = req.url.path.endsWith('/register')
          ? (registered = true, _registering(registered: true, players: [
              {'name': 'أحمد', 'you': true}
            ]))
              .$2
          : _registering(registered: registered);
      return http.Response(jsonEncode(body), 200,
          headers: {'content-type': 'application/json'});
    });
    final api = ApiClient(httpClient: client);
    await t.pumpWidget(_screen(api));
    await t.pumpAndSettle();

    await t.tap(find.textContaining('سجّل — 50💎'));
    await t.pumpAndSettle();
    expect(find.text('انسحب واسترد رسمك'), findsOneWidget);
    expect(find.text('ادعُ شريكًا'), findsOneWidget,
        reason: 'المسجَّل بلا شريكٍ يستطيع الدعوة');
    f.calls.clear();
  });

  testWidgets('رمز الخطأ يُترجَم رسالةً عربيّةً عابرة', (t) async {
    final f = _fake({
      '/me/tournament/register': (402, {'error': 'trn_insufficient'}),
      '/me/tournament': (200, _registering()),
    });
    await t.pumpWidget(_screen(f.api));
    await t.pumpAndSettle();

    await t.tap(find.textContaining('سجّل — 50💎'));
    await t.pumpAndSettle();
    expect(find.text('ماسُك لا يكفي لرسم الدخول.'), findsOneWidget);
  });

  testWidgets('دعوة شراكة واردة: القبول يضرب accept', (t) async {
    final f = _fake({
      '/me/tournament/accept': (
        200,
        _registering(registered: true, partner: 'أحمد', players: [
          {'name': 'أحمد'},
          {'name': 'بلال', 'you': true},
        ])
      ),
      '/me/tournament': (200, _registering(inviteFrom: 'أحمد')),
    });
    await t.pumpWidget(_screen(f.api));
    await t.pumpAndSettle();

    expect(find.textContaining('أحمد يدعوك شريكًا'), findsOneWidget);
    await t.tap(find.text('اقبل'));
    await t.pumpAndSettle();
    expect(f.calls, contains('POST /me/tournament/accept'));
    expect(find.textContaining('شريكك: أحمد'), findsOneWidget);
  });

  testWidgets('القوس: فريقان وروبوتات وفائزٌ وزرُّ الدخول لطاولتي', (t) async {
    ({String code, int seat})? entered;
    final f = _fake({
      '/me/tournament': (
        200,
        {
          'phase': 'playing',
          'entryFee': 50,
          'size': 8,
          'pool': 80,
          'registered': true,
          'players': const [],
          'bracket': [
            {
              'round': 0,
              'index': 0,
              'seats': [
                {'bot': false, 'name': 'أحمد', 'you': true},
                {'bot': true},
                {'bot': false, 'name': 'بلال'},
                {'bot': true},
              ],
              'live': true,
            },
            {
              'round': 0,
              'index': 1,
              'seats': [
                {'bot': false, 'name': 'جميل'},
                {'bot': true},
                {'bot': true},
                {'bot': true},
              ],
              'winnerTeam': 1,
              'live': false,
            },
          ],
          'myTable': {'code': 'AB12', 'seat': 0},
        }
      ),
    });
    await t.pumpWidget(_screen(f.api, onEnter: (x) => entered = x));
    await t.pumpAndSettle();

    expect(find.text('نصف النهائيّ'), findsOneWidget);
    expect(find.text('أنت'), findsOneWidget);
    expect(find.text('بلال'), findsOneWidget);
    expect(find.text('جميل'), findsOneWidget);
    expect(find.text('ذكاء'), findsNWidgets(5));
    expect(find.text('جارية'), findsOneWidget);
    expect(find.textContaining('الجولة التالية تُبنى'), findsOneWidget,
        reason: 'النهائيّ لم يُبنَ بعد ⇒ لافتةُ انتظار');

    await t.tap(find.text('ادخل طاولتك الآن'));
    expect(entered, isNotNull);
    expect(entered!.code, 'AB12');
    expect(entered!.seat, 0);
  });

  testWidgets('أبطال آخر بطولة يُعرَضون بأسمائهم وجوائزهم', (t) async {
    final f = _fake({
      '/me/tournament': (
        200,
        _registering(champions: [
          {'name': 'أحمد', 'prize': 160},
          {'name': 'بلال', 'prize': 160},
        ])
      ),
    });
    await t.pumpWidget(_screen(f.api));
    await t.pumpAndSettle();

    expect(find.text('أبطال آخر بطولة'), findsOneWidget);
    expect(find.textContaining('أحمد (+160💎)'), findsOneWidget);
    expect(find.textContaining('بلال (+160💎)'), findsOneWidget);
  });

  testWidgets('فشل الجلب الأوّل ⇒ رسالةٌ وزرُّ إعادة يعيد الجلب', (t) async {
    var fail = true;
    final client = MockClient((req) async {
      if (fail) return http.Response('{}', 500);
      return http.Response(jsonEncode(_registering()), 200,
          headers: {'content-type': 'application/json'});
    });
    await t.pumpWidget(_screen(ApiClient(httpClient: client)));
    await t.pumpAndSettle();
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    fail = false;
    await t.tap(find.text('إعادة المحاولة'));
    await t.pumpAndSettle();
    expect(find.text('بطولة اليوم'), findsOneWidget);
  });
}
