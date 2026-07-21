import 'dart:convert';

import 'package:app/app_settings.dart';
import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **جرسُ الإشعارات وشارتُه** في البطاقة العليا.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _player() => {
      'id': 'p1',
      'tag': 'ABC123',
      'phone': '+22200000000',
      'displayName': 'محمّد',
      'countryCode': 'MR',
      'city': 'نواكشوط',
    };

AuthSession _sess() => AuthSession(
    token: 'TOK', player: AccountPlayer.fromJson(_player()), isNew: false);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// [unread] عددُ ما لم يُقرأ كما يردّه الخادم؛ null ⇒ المسار يفشل (خادمٌ قديم).
  Future<SessionController> pump(WidgetTester tester,
      {int? unread, bool signedIn = true}) async {
    final client = MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/me/wallet')) return _json({'diamonds': 2});
      if (p.endsWith('/me/stats')) {
        return _json({'rating': 1000, 'matches': 0, 'wins': 0});
      }
      if (p.endsWith('/notifications/unread')) {
        if (unread == null) return http.Response('{}', 404); // خادمٌ قديم
        return _json({'unread': unread});
      }
      return _json(_player());
    });
    final session = SessionController(
        api: ApiClient(config: _config, httpClient: client),
        store: SessionStore());
    if (signedIn) await session.signIn(_sess());

    final settings = AppSettings();
    await settings.load();
    await tester.pumpWidget(ThemeScope(
      manager: ThemeManager(),
      child: AppSettingsScope(
        settings: settings,
        child: SessionScope(
          controller: session,
          child: MaterialApp(
            builder: (_, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: HomeScreen(onPlay: () {}, onNotifications: () {}),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets('غيرُ مقروءٍ ⇒ جرسٌ نشطٌ بشارةِ العدد', (tester) async {
    await pump(tester, unread: 3);

    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('لا شيءَ غيرَ مقروء ⇒ جرسٌ هادئٌ بلا شارة', (tester) async {
    await pump(tester, unread: 0);

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active), findsNothing);
    expect(find.text('0'), findsNothing, reason: 'صفرٌ ⇒ لا شارةَ أصلًا');
  });

  // خادمٌ قديمٌ بلا المسار: شارةٌ حمراء كاذبة أسوأ من لا شارة.
  testWidgets('فشلُ العدّ ⇒ لا شارة، ولا عطب', (tester) async {
    final session = await pump(tester, unread: null);

    expect(session.unreadNotifications, 0);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('عددٌ كبير ⇒ يُقصّ عند ٩٩ فلا تمطُّ الشارةُ الشريط', (tester) async {
    await pump(tester, unread: 1234);

    expect(find.text('+99'), findsOneWidget);
    expect(find.text('1234'), findsNothing);
  });

  testWidgets('بلا حساب ⇒ لا جرسَ أصلًا', (tester) async {
    await pump(tester, unread: 5, signedIn: false);

    expect(find.byIcon(Icons.notifications_none), findsNothing);
    expect(find.byIcon(Icons.notifications_active), findsNothing);
    expect(find.text('دخول'), findsOneWidget);
  });

  testWidgets('لمسةُ الجرس تفتح الشاشة', (tester) async {
    var opened = 0;
    final client = MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/me/wallet')) return _json({'diamonds': 10});
      if (p.endsWith('/me/stats')) {
        return _json({'rating': 1000, 'matches': 0, 'wins': 0});
      }
      if (p.endsWith('/notifications/unread')) return _json({'unread': 1});
      return _json(_player());
    });
    final session = SessionController(
        api: ApiClient(config: _config, httpClient: client),
        store: SessionStore());
    await session.signIn(_sess());
    final settings = AppSettings();
    await settings.load();

    await tester.pumpWidget(ThemeScope(
      manager: ThemeManager(),
      child: AppSettingsScope(
        settings: settings,
        child: SessionScope(
          controller: session,
          child: MaterialApp(
            builder: (_, child) =>
                Directionality(textDirection: TextDirection.rtl, child: child!),
            home: HomeScreen(onPlay: () {}, onNotifications: () => opened++),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.notifications_active));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });

  testWidgets('الشارة تتبع المتحكّم حيًّا (بعد التعليم مقروءًا)', (tester) async {
    // ‏7 لا 2: الجواهرُ في البطاقة عددُها 2 كذلك — رقمٌ يتصادم يجعل الاختبار
    // يفحص شيئًا آخر ثمّ يُصدّق نفسه.
    final session = await pump(tester, unread: 7);
    expect(find.text('7'), findsOneWidget);

    session.setUnread(0);
    await tester.pumpAndSettle();

    expect(find.text('7'), findsNothing);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });
}
