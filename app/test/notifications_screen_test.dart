import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/ui/notifications_screen.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **شاشة الإشعارات** — نافذةُ الصندوق الذي يبقى بعد أن يختفي الإشعار من الشريط.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _item(
  String id, {
  String kind = 'invite',
  String title = 'دعوةٌ إلى طاولة',
  String body = 'محمّد يدعوك إلى بيلوت',
  bool read = false,
  Map<String, String> data = const {'type': 'invite', 'code': 'ABCD', 'seat': '2'},
}) =>
    {
      'id': id,
      'kind': kind,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'read': read,
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// يبني الشاشة فوق مُتحكّم جلسةٍ حقيقيّ (الشارةُ تتبعه).
  Future<(SessionController, List<String>)> pump(
    WidgetTester tester,
    MockClient client, {
    void Function(AppNotification)? onOpen,
  }) async {
    final calls = <String>[];
    final api = ApiClient(config: _config, httpClient: client);
    final session = SessionController(api: api, store: SessionStore());
    await tester.pumpWidget(ThemeScope(
      manager: ThemeManager(),
      child: SessionScope(
        controller: session,
        child: MaterialApp(
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: NotificationsScreen(api: api, token: 'TOK', onOpen: onOpen),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return (session, calls);
  }

  testWidgets('قائمةٌ بها إشعارات ⇒ عناوينُها ونصوصُها', (tester) async {
    final client = MockClient((req) async => _json({
          'items': [
            _item('n1'),
            _item('n2', kind: 'system', title: 'صيانة', body: 'الخادم يُحدَّث', data: {'type': 'system'}),
          ],
          'unread': 2,
        }));

    final (session, _) = await pump(tester, client);

    expect(find.text('دعوةٌ إلى طاولة'), findsOneWidget);
    expect(find.text('صيانة'), findsOneWidget);
    expect(find.text('الخادم يُحدَّث'), findsOneWidget);
    expect(session.unreadNotifications, 2, reason: 'الشارةُ تتبع القائمة بلا نداءٍ ثانٍ');
  });

  testWidgets('صندوقٌ فارغ ⇒ رسالةٌ لا شاشةٌ بيضاء', (tester) async {
    final client = MockClient((req) async => _json({'items': [], 'unread': 0}));
    await pump(tester, client);
    expect(find.textContaining('لا إشعارات بعد'), findsOneWidget);
  });

  // **الفشل يُقال لا يُبتلع**: فراغٌ كاذبٌ يقول «لا شيء عندك» وهو كذبٌ عن دعوةٍ تنتظر.
  testWidgets('فشلُ الجلب ⇒ رسالةٌ عربيّة + إعادة المحاولة', (tester) async {
    var attempt = 0;
    final client = MockClient((req) async {
      attempt++;
      if (attempt == 1) {
        return http.Response(jsonEncode({'error': 'تعذّر الاتّصال'}), 500,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }
      return _json({'items': [_item('n1')], 'unread': 1});
    });

    await pump(tester, client);
    expect(find.text('تعذّر الاتّصال'), findsOneWidget);
    expect(find.textContaining('لا إشعارات بعد'), findsNothing,
        reason: 'لا فراغَ كاذبٌ مكانَ الخطأ');

    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    expect(find.text('دعوةٌ إلى طاولة'), findsOneWidget);
  });

  testWidgets('لمسةُ دعوةٍ ⇒ تُسلّم حمولتَها كما هي (الرمز والمقعد)', (tester) async {
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/read')) return _json({'unread': 0});
      return _json({'items': [_item('n1')], 'unread': 1});
    });
    AppNotification? opened;

    await pump(tester, client, onOpen: (n) => opened = n);
    await tester.tap(find.text('دعوةٌ إلى طاولة'));
    await tester.pumpAndSettle();

    expect(opened?.kind, NotificationKind.invite);
    expect(opened?.data, {'type': 'invite', 'code': 'ABCD', 'seat': '2'},
        reason: 'نفسُ حمولة الدفع ⇒ لمسةُ الجرس تفتح ما يفتحه الإشعار');
  });

  testWidgets('اللمسة تُعلّم مقروءًا وتُنقص الشارة', (tester) async {
    final read = <String?>[];
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/read')) {
        read.add((jsonDecode(req.body) as Map)['id'] as String?);
        return _json({'unread': 0});
      }
      return _json({'items': [_item('n1')], 'unread': 1});
    });

    final (session, _) = await pump(tester, client);
    await tester.tap(find.text('دعوةٌ إلى طاولة'));
    await tester.pumpAndSettle();

    expect(read, ['n1']);
    expect(session.unreadNotifications, 0);
  });

  testWidgets('«تعليم الكلّ» يظهر لغير المقروء فقط، ويُرسل بلا id', (tester) async {
    final read = <Map<String, dynamic>>[];
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/read')) {
        read.add(jsonDecode(req.body) as Map<String, dynamic>);
        return _json({'unread': 0});
      }
      return _json({'items': [_item('n1'), _item('n2')], 'unread': 2});
    });

    final (session, _) = await pump(tester, client);
    expect(find.text('تعليم الكلّ'), findsOneWidget);

    await tester.tap(find.text('تعليم الكلّ'));
    await tester.pumpAndSettle();

    expect(read.single.containsKey('id'), isFalse, reason: 'بلا id ⇒ الكلّ');
    expect(session.unreadNotifications, 0);
    expect(find.text('تعليم الكلّ'), findsNothing, reason: 'لا شيءَ ليُعلَّم');
  });

  testWidgets('كلُّها مقروءة ⇒ لا زرّ «تعليم الكلّ» أصلًا', (tester) async {
    final client = MockClient((req) async =>
        _json({'items': [_item('n1', read: true)], 'unread': 0}));
    await pump(tester, client);
    expect(find.text('تعليم الكلّ'), findsNothing);
  });

  // **الحارس الأهمّ**: خادمٌ أحدثُ يبثّ نوعًا لم يكن يوم بُنيت هذه الحزمة.
  testWidgets('نوعٌ مجهول ⇒ يُعرَض نصًّا ولا ينكسر شيء', (tester) async {
    final client = MockClient((req) async => _json({
          'items': [
            _item('n1',
                kind: 'tournamentStart',
                title: 'بدأت البطولة',
                body: 'ادخل الآن',
                data: {'type': 'tournamentStart'})
          ],
          'unread': 1,
        }));
    AppNotification? opened;

    await pump(tester, client, onOpen: (n) => opened = n);

    expect(find.text('بدأت البطولة'), findsOneWidget, reason: 'يُقرأ لا يُسقَط');
    await tester.tap(find.text('بدأت البطولة'));
    await tester.pumpAndSettle();
    expect(opened?.kind, NotificationKind.unknown);
    expect(tester.takeException(), isNull);
  });

  testWidgets('حمولةٌ ناقصة (بلا مقعد) لا تُسقط الشاشة', (tester) async {
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/read')) return _json({'unread': 0});
      return _json({
        'items': [
          {'id': 'n1', 'kind': 'invite', 'title': 'دعوة', 'body': 'ن'},
        ],
        'unread': 1,
      });
    });

    await pump(tester, client);
    await tester.tap(find.text('دعوة'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
