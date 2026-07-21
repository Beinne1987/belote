import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/services/phone_auth.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _config = ApiConfig.fromOrigin('http://test.local');

/// مصادقة هاتفٍ وهميّة: تُرسل الرمز فورًا وتُعيد توكنًا ثابتًا عند التحقّق.
class _FakeAuth implements PhoneAuthenticator {
  final String idToken;
  _FakeAuth(this.idToken);

  @override
  bool get supported => true;

  @override
  Future<void> sendCode({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function(String idToken)? onAutoVerified,
    bool resend = false,
  }) async =>
      onCodeSent();

  @override
  Future<String> verifyCode(String smsCode) async => idToken;
}

Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

http.Response _json(Object j) => http.Response(jsonEncode(j), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

Future<void> _drain(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('إنشاء حساب: هاتف → رمز → كلمة سرّ+اسم+مدينة ⇒ api.register', (tester) async {
    Map<String, dynamic>? sent;
    final api = ApiClient(
      config: _config,
      httpClient: MockClient((req) async {
        expect(req.url.path, '/auth/register');
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return _json({
          'token': 'jwt.new',
          'player': {
            'id': 'p1',
            'phone': '+22245010203',
            'displayName': 'محمد',
            'countryCode': 'MR',
            'city': 'نواكشوط',
          },
          'isNew': true,
        });
      }),
    );

    AuthSession? got;
    await tester.pumpWidget(_wrap(RegisterScreen(
      api: api,
      phoneAuth: _FakeAuth('fb.token'),
      onAuthenticated: (s) async => got = s,
      onLogin: () {},
    )));

    // ١) الهاتف → إرسال الرمز.
    await tester.enterText(find.byType(TextField), '45010203');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pumpAndSettle();

    // ٢) الرمز → تحقّق.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('تحقّق'));
    await tester.pumpAndSettle();

    // ٣) التفاصيل: كلمة سرّ + اسم + مدينة (الدولة موريتانيا افتراضًا).
    expect(find.text('أكمل حسابك'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'secret1');
    await tester.enterText(find.byType(TextField).at(1), 'محمد');
    await tester.enterText(find.byType(TextField).at(2), 'نواكشوط');
    await tester.tap(find.text('إنشاء الحساب'));
    await _drain(tester);

    expect(sent!['idToken'], 'fb.token');
    expect(sent!['password'], 'secret1');
    expect(sent!['displayName'], 'محمد');
    expect(sent!['countryCode'], 'MR');
    expect(sent!['city'], 'نواكشوط');
    expect(got, isNotNull);
    expect(got!.token, 'jwt.new');
  });

  testWidgets('كلمة سرّ قصيرة ⇒ رسالة تحقّق محلّية (لا نداء خادم)', (tester) async {
    final api = ApiClient(
      config: _config,
      httpClient: MockClient((_) async => throw StateError('يجب ألا يُنادى الخادم')),
    );
    await tester.pumpWidget(_wrap(RegisterScreen(
      api: api,
      phoneAuth: _FakeAuth('fb.token'),
      onAuthenticated: (_) async {},
      onLogin: () {},
    )));

    await tester.enterText(find.byType(TextField), '45010203');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('تحقّق'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '123'); // قصيرة
    await tester.enterText(find.byType(TextField).at(1), 'محمد');
    await tester.enterText(find.byType(TextField).at(2), 'نواكشوط');
    await tester.tap(find.text('إنشاء الحساب'));
    await tester.pump();

    expect(find.text('كلمة السرّ ٦ أحرف على الأقلّ'), findsOneWidget);
  });
}
