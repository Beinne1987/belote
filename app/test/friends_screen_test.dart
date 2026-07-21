import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/friends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// شاشة الأصدقاء ببياناتٍ حقيقيّة من عميلٍ مُزيَّف (بلا شبكة).
///
/// كانت الشاشة صدفةً بأسماءَ وهميّة؛ هذه الاختبارات تمنع عودتها: كلُّ اسمٍ يُعرَض
/// يجب أن يأتي من الردّ.
Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(home: child),
    );

Map<String, dynamic> _p(String id, String name, String tag, {bool? online}) => {
      'id': id,
      'displayName': name,
      'tag': tag,
      'countryCode': '',
      'city': '',
      if (online != null) 'online': online,
    };

/// عميلٌ يردّ بما تُمليه [routes] ويسجّل ما أُرسل.
({ApiClient api, List<String> calls, List<String> bodies}) _fake(
  Map<String, (int, Map<String, dynamic>)> routes,
) {
  final calls = <String>[], bodies = <String>[];
  final client = MockClient((req) async {
    // العنوان الحقيقيّ يحمل بادئة `/belote` (ApiConfig) ⇒ طابِق بالنهاية لا بالمساواة،
    // وإلّا مرّ كلُّ طلبٍ من الافتراضيّ فبدت الشاشةُ فارغةً بلا سبب.
    final path = req.url.path;
    calls.add('${req.method} ${_suffix(path, routes.keys)}');
    if (req.body.isNotEmpty) bodies.add(req.body);
    final key = routes.keys.firstWhere(path.endsWith, orElse: () => '');
    final r = routes[key] ?? (200, <String, dynamic>{});
    return http.Response(jsonEncode(r.$2), r.$1,
        headers: {'content-type': 'application/json'});
  });
  return (api: ApiClient(httpClient: client), calls: calls, bodies: bodies);
}

/// المسار كما نسجّله: بلا بادئة النشر، ليقرأ التوقّعُ كما كُتب المسار في الخادم.
String _suffix(String path, Iterable<String> known) =>
    known.firstWhere(path.endsWith, orElse: () => path);

void main() {
  const listPath = '/me/friends';

  testWidgets('القوائم الثلاث تُعرَض بأسمائها ورموزها الحقيقيّة', (t) async {
    final f = _fake({
      listPath: (200, {
        'friends': [_p('F1', 'سالم', 'BCDFGH')],
        'incoming': [_p('I1', 'مريم', 'JKMNPQ')],
        'outgoing': [_p('O1', 'يعقوب', 'RSTVWX')],
      }),
    });
    await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
    await t.pumpAndSettle();

    for (final name in ['سالم', 'مريم', 'يعقوب']) {
      expect(find.text(name), findsOneWidget, reason: '$name من الردّ');
    }
    expect(find.text('يطلبون صداقتك'), findsOneWidget);
    expect(find.text('أصدقاؤك'), findsOneWidget);
    expect(find.text('بانتظار ردّهم'), findsOneWidget);
    // لا أثرَ للصدفة القديمة.
    expect(find.text('عائشة'), findsNothing);
  });

  testWidgets('لا أصدقاء ⇒ رسالةٌ تشرح الخطوة التالية', (t) async {
    final f = _fake({
      listPath: (200, {'friends': [], 'incoming': [], 'outgoing': []}),
    });
    await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
    await t.pumpAndSettle();
    expect(find.textContaining('لا أصدقاء بعد'), findsOneWidget);
    expect(find.textContaining('رمز صاحبك'), findsOneWidget);
  });

  testWidgets('فشل الجلب ⇒ رسالةٌ وزرّ إعادة، لا شاشةٌ بيضاء', (t) async {
    final f = _fake({listPath: (500, {'error': 'boom'})});
    await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
    await t.pumpAndSettle();
    expect(find.textContaining('تعذّر جلب'), findsOneWidget);
    expect(find.text('أعِد المحاولة'), findsOneWidget);
  });

  testWidgets('بلا توكن ⇒ ادعُ للدخول ولا تنادِ الخادم', (t) async {
    final f = _fake({});
    await t.pumpWidget(_wrap(FriendsScreen(api: f.api)));
    await t.pumpAndSettle();
    expect(find.textContaining('سجّل الدخول'), findsOneWidget);
    expect(f.calls, isEmpty, reason: 'لا نداءَ بلا توكن');
    expect(find.text('إضافة بالرمز'), findsNothing, reason: 'لا زرَّ لا يعمل');
  });

  testWidgets('قبولُ طلبٍ وارد يرسل معرّفه ثمّ يُعيد التحميل', (t) async {
    final f = _fake({
      listPath: (200, {
        'friends': [],
        'incoming': [_p('I1', 'مريم', 'JKMNPQ')],
        'outgoing': [],
      }),
      '/me/friends/accept': (200, {'status': 'accepted'}),
    });
    await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.check_circle));
    await t.pumpAndSettle();

    expect(f.calls, contains('POST /me/friends/accept'));
    expect(f.bodies.any((b) => b.contains('I1')), isTrue, reason: 'المعرّف لا الرمز');
    expect(f.calls.where((c) => c == 'GET /me/friends'), hasLength(2),
        reason: 'إعادةُ تحميلٍ بعد الفعل');
    expect(find.text('صرتما صديقين'), findsOneWidget);
  });

  testWidgets('زرُّ المحادثة للأصدقاء وحدهم — وشارةُ غير المقروء من الخادم',
      (t) async {
    final f = _fake({
      listPath: (200, {
        'friends': [
          {..._p('F1', 'سالم', 'BCDFGH', online: true), 'unread': 3}
        ],
        'incoming': [_p('I1', 'مريم', 'JKMNPQ')],
        'outgoing': [],
      }),
    });
    await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
    await t.pumpAndSettle();

    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget,
        reason: 'الصديق وحده يُحاوَر — لا زرَّ على الطلبات');
    expect(find.text('3'), findsOneWidget, reason: 'شارةُ الخادم لا اختراع');
  });

  testWidgets('لوحةُ المحظورين: تُجلَب عند الفتح والفكُّ يزيل الصفّ', (t) async {
    final f = _fake({
      listPath: (200, {'friends': [], 'incoming': [], 'outgoing': []}),
      '/me/blocks/remove': (200, {'ok': true}),
      '/me/blocks': (200, {
        'players': [_p('B1', 'خصمٌ مزعج', 'ZBCDFG')]
      }),
    });
    await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.block));
    await t.pumpAndSettle();
    expect(find.text('خصمٌ مزعج'), findsOneWidget);

    await t.tap(find.text('فكّ الحظر'));
    await t.pumpAndSettle();
    expect(f.calls, contains('POST /me/blocks/remove'));
    expect(f.bodies.any((b) => b.contains('B1')), isTrue);
    expect(find.text('خصمٌ مزعج'), findsNothing);
    expect(find.text('لا أحدَ محظور.'), findsOneWidget);
  });

  testWidgets('حذفُ صديقٍ يُستأذَن فيه، والتراجع لا يحذف', (t) async {
    final f = _fake({
      listPath: (200, {
        'friends': [_p('F1', 'سالم', 'BCDFGH')],
        'incoming': [],
        'outgoing': [],
      }),
    });
    await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.person_remove_outlined));
    await t.pumpAndSettle();
    expect(find.text('حذف صديق'), findsOneWidget);

    await t.tap(find.text('تراجع'));
    await t.pumpAndSettle();
    expect(f.calls, isNot(contains('POST /me/friends/remove')));
  });

  testWidgets('سحبُ طلبٍ صادر بلا استئذان (فعلٌ صغيرٌ يُعاد بنقرة)', (t) async {
    final f = _fake({
      listPath: (200, {
        'friends': [],
        'incoming': [],
        'outgoing': [_p('O1', 'يعقوب', 'RSTVWX')],
      }),
      '/me/friends/remove': (200, {'ok': true}),
    });
    await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
    await t.pumpAndSettle();

    await t.tap(find.byIcon(Icons.person_remove_outlined));
    await t.pumpAndSettle();
    expect(find.text('حذف صديق'), findsNothing, reason: 'لا استئذانَ للسحب');
    expect(f.calls, contains('POST /me/friends/remove'));
    expect(find.text('سُحب الطلب'), findsOneWidget);
  });

  group('إضافة بالرمز', () {
    Future<void> openSheet(WidgetTester t, ApiClient api) async {
      await t.pumpWidget(_wrap(FriendsScreen(api: api, token: 'tok')));
      await t.pumpAndSettle();
      await t.tap(find.text('إضافة بالرمز'));
      await t.pumpAndSettle();
    }

    testWidgets('رمزٌ صحيح ⇒ يُرسَل ويُقال «أُرسل الطلب»', (t) async {
      final f = _fake({
        listPath: (200, {'friends': [], 'incoming': [], 'outgoing': []}),
        '/me/friends/request': (200, {'status': 'pending', 'player': _p('X', 'س', 'JKMNPQ')}),
      });
      await openSheet(t, f.api);

      await t.enterText(find.byType(TextField), 'jkmnpq');
      await t.tap(find.text('أرسل الطلب'));
      await t.pumpAndSettle();

      expect(f.bodies.any((b) => b.contains('jkmnpq')), isTrue,
          reason: 'يُرسَل كما كُتب — الخادم يطبّع');
      expect(find.text('أُرسل الطلب'), findsOneWidget);
    });

    testWidgets('طلبان متقابلان ⇒ يقول «صرتما صديقين» لا «أُرسل الطلب»', (t) async {
      final f = _fake({
        listPath: (200, {'friends': [], 'incoming': [], 'outgoing': []}),
        '/me/friends/request': (200, {'status': 'accepted', 'player': _p('X', 'س', 'JKMNPQ')}),
      });
      await openSheet(t, f.api);
      await t.enterText(find.byType(TextField), 'JKMNPQ');
      await t.tap(find.text('أرسل الطلب'));
      await t.pumpAndSettle();

      expect(find.text('صرتما صديقين'), findsOneWidget);
      expect(find.text('أُرسل الطلب'), findsNothing);
    });

    testWidgets('**الخطأ يُعرَض بالعربيّة لا برمزٍ خام**', (t) async {
      final f = _fake({
        listPath: (200, {'friends': [], 'incoming': [], 'outgoing': []}),
        '/me/friends/request': (404, {'error': 'friend_notFound'}),
      });
      await openSheet(t, f.api);
      await t.enterText(find.byType(TextField), 'ZZZZZZ');
      await t.tap(find.text('أرسل الطلب'));
      await t.pumpAndSettle();

      expect(find.textContaining('لا لاعب بهذا الرمز'), findsOneWidget);
      expect(find.textContaining('friend_notFound'), findsNothing,
          reason: 'رمزٌ إنجليزيٌّ خامٌّ في وجه اللاعب = عطب');
      expect(find.text('إضافة بالرمز'), findsWidgets, reason: 'اللوحة تبقى ليصحّح');
    });

    testWidgets('كلّ رموز الأخطاء لها نصٌّ عربيّ', (t) async {
      for (final code in [
        'friend_invalidTag',
        'friend_notFound',
        'friend_self',
        'friend_already',
        'friend_noRequest',
        'friend_notFriend',
      ]) {
        final msg = friendErrorText(code);
        expect(msg, isNot(contains('friend_')), reason: '$code بلا ترجمة');
        expect(msg, isNot(equals(code)));
      }
      // خطأٌ عربيٌّ من الخادم (بقيّة المسارات) يمرّ كما هو.
      expect(friendErrorText('اللاعب غير موجود'), 'اللاعب غير موجود');
    });
  });

  group('الحضور', () {
    testWidgets('صديقٌ متّصلٌ ⇒ «متصل»، وغيره ⇒ «غير متصل»', (t) async {
      final f = _fake({
        listPath: (200, {
          'friends': [
            _p('F1', 'سالم', 'BCDFGH', online: true),
            _p('F2', 'مريم', 'JKMNPQ', online: false),
          ],
          'incoming': [],
          'outgoing': [],
        }),
      });
      await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
      await t.pumpAndSettle();
      expect(find.text('متصل'), findsOneWidget);
      expect(find.text('غير متصل'), findsOneWidget);
    });

    testWidgets('الطلبُ المعلّق بلا شارةِ حضورٍ البتّة (الخادم لا يكشفه)', (t) async {
      final f = _fake({
        listPath: (200, {
          'friends': [],
          'incoming': [_p('I1', 'مريم', 'JKMNPQ')], // بلا حقل online
          'outgoing': [_p('O1', 'يعقوب', 'RSTVWX')],
        }),
      });
      await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
      await t.pumpAndSettle();
      expect(find.text('متصل'), findsNothing);
      expect(find.text('غير متصل'), findsNothing,
          reason: 'رماديٌّ على طلبٍ معلّقٍ يوهم بغيابٍ لا نعرفه');
    });

    testWidgets('خادمٌ بلا حقل online ⇒ غير متصل، لا انهيار', (t) async {
      final f = _fake({
        listPath: (200, {
          'friends': [_p('F1', 'سالم', 'BCDFGH')],
          'incoming': [],
          'outgoing': [],
        }),
      });
      await t.pumpWidget(_wrap(FriendsScreen(api: f.api, token: 'tok')));
      await t.pumpAndSettle();
      expect(find.text('غير متصل'), findsOneWidget);
    });
  });
}
