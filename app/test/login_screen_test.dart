import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _config = ApiConfig.fromOrigin('http://test.local');

Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

http.Response _json(Object j, [int code = 200]) => http.Response(jsonEncode(j), code,
    headers: {'content-type': 'application/json; charset=utf-8'});

Future<void> _drain(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('دخول صحيح: هاتف + كلمة سرّ ⇒ api.login ⇒ onAuthenticated', (tester) async {
    Map<String, dynamic>? sent;
    final api = ApiClient(
      config: _config,
      httpClient: MockClient((req) async {
        expect(req.url.path, '/auth/login');
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({
          'token': 'jwt.ok',
          'player': {'id': 'p1', 'phone': '+22245010203', 'displayName': 'سالم'},
          'isNew': false,
        });
      }),
    );

    AuthSession? got;
    await tester.pumpWidget(_wrap(LoginScreen(
      api: api,
      onAuthenticated: (s) async => got = s,
      onRegister: () {},
      onForgot: () {},
    )));

    await tester.enterText(find.byType(TextField).at(0), '45010203');
    await tester.enterText(find.byType(TextField).at(1), 'secret1');
    await tester.tap(find.text('دخول'));
    await _drain(tester);

    expect(sent!['phone'], '+22245010203'); // بادئة موريتانيا الافتراضيّة
    expect(sent!['password'], 'secret1');
    expect(got, isNotNull);
    expect(got!.player.displayName, 'سالم');
  });

  testWidgets('كلمة سرّ خاطئة ⇒ رسالة الخطأ من الخادم', (tester) async {
    final api = ApiClient(
      config: _config,
      httpClient: MockClient((req) async =>
          _json({'error': 'رقم الهاتف أو كلمة السرّ غير صحيحة'}, 401)),
    );

    await tester.pumpWidget(_wrap(LoginScreen(
      api: api,
      onAuthenticated: (_) async {},
      onRegister: () {},
      onForgot: () {},
    )));

    await tester.enterText(find.byType(TextField).at(0), '45010203');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(find.text('رقم الهاتف أو كلمة السرّ غير صحيحة'), findsOneWidget);
  });

  testWidgets('روابط: نسيت كلمة السرّ + إنشاء حساب تستدعيان الكولباك', (tester) async {
    var forgot = 0, register = 0;
    await tester.pumpWidget(_wrap(LoginScreen(
      api: ApiClient(config: _config, httpClient: MockClient((_) async => _json({}))),
      onAuthenticated: (_) async {},
      onRegister: () => register++,
      onForgot: () => forgot++,
    )));

    await tester.tap(find.text('نسيت كلمة السرّ؟'));
    await tester.tap(find.text('ليس لديك حساب؟ أنشئ حسابًا'));
    await tester.pump();

    expect(forgot, 1);
    expect(register, 1);
  });
}
