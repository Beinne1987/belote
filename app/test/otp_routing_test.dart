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

http.Response _res(Object j, [int status = 200]) => http.Response(jsonEncode(j), status,
    headers: {'content-type': 'application/json; charset=utf-8'});

/// مزوّدٌ وهميّ يسجّل ما مرّ به (بديلُ Firebase في اختبار التوجيه).
class _Spy implements PhoneAuthenticator {
  final List<String> sent = [];
  @override
  bool supportsPhone(String phoneE164) => true;
  @override
  bool supportsWhatsApp(String phoneE164) => false;
  @override
  Future<void> sendCode({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function(PhoneCredential credential)? onAutoVerified,
    bool resend = false,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    sent.add(phoneE164);
    onCodeSent();
  }

  @override
  Future<PhoneCredential> verifyCode(String smsCode) async => const PhoneCredential.firebase('fb');
}

ServerOtpAuth _server(MockClient c, {OtpPurpose purpose = OtpPurpose.register}) => ServerOtpAuth(
      api: ApiClient(config: _config, httpClient: c),
      purpose: purpose,
      deviceId: () async => 'dev1',
      lang: () => 'ar',
    );

void main() {
  group('التوجيه', () {
    test('+222 ⇒ خادمنا، وغيره ⇒ Firebase كما هو', () async {
      final calls = <String>[];
      final fb = _Spy();
      final auth = RoutedPhoneAuth(
        mauritania: _server(MockClient((req) async {
          calls.add(req.url.path);
          return req.url.path == '/otp/send'
              ? _res({'ok': true, 'expiresIn': 600})
              : _res({'phoneProof': 'proof.jwt', 'expiresIn': 600});
        })),
        others: fb,
      );

      var sent = 0;
      await auth.sendCode(
          phoneE164: '+33612345678', onCodeSent: () => sent++, onError: (_) => fail('خطأ'));
      expect(fb.sent, ['+33612345678']);
      expect(calls, isEmpty);
      expect((await auth.verifyCode('111111')).idToken, 'fb');

      await auth.sendCode(
          phoneE164: '+22236123456', onCodeSent: () => sent++, onError: (_) => fail('خطأ'));
      expect(fb.sent, hasLength(1));
      final cred = await auth.verifyCode('123456');
      expect(cred.phoneProof, 'proof.jwt');
      expect(cred.toJson(), {'phoneProof': 'proof.jwt'});
      expect(calls, ['/otp/send', '/otp/verify']);
      expect(sent, 2);
      expect(auth.supportsWhatsApp('+22236123456'), isTrue);
      expect(auth.supportsWhatsApp('+33612345678'), isFalse);
    });

    test('الموريتانيّ مدعومٌ على كلّ منصّة (طلبُ HTTP)', () {
      final s = _server(MockClient((_) async => _res({})));
      expect(s.supportsPhone('+22236123456'), isTrue);
      expect(s.supportsPhone('+212600000000'), isFalse);
    });
  });

  group('خادم OTP', () {
    test('يرسل الحقول بالعقد، والتحقّق بنفس القناة (واتساب)', () async {
      final bodies = <String, Map<String, dynamic>>{};
      final s = _server(MockClient((req) async {
        bodies[req.url.path] = jsonDecode(req.body) as Map<String, dynamic>;
        return req.url.path == '/otp/send'
            ? _res({'ok': true})
            : _res({'phoneProof': 'p', 'expiresIn': 600});
      }), purpose: OtpPurpose.reset);

      await s.sendCode(
        phoneE164: '+22236123456',
        channel: OtpChannel.whatsapp,
        onCodeSent: () {},
        onError: (m) => fail(m),
      );
      await s.verifyCode('654321');
      expect(bodies['/otp/send'], {
        'phone': '+22236123456',
        'channel': 'whatsapp',
        'purpose': 'reset',
        'lang': 'ar',
        'deviceId': 'dev1',
      });
      expect(bodies['/otp/verify'], {
        'phone': '+22236123456',
        'otp': '654321',
        'channel': 'whatsapp',
        'deviceId': 'dev1',
      });
    });

    Future<String> verifyErr(http.Response r) async {
      final s = _server(MockClient((req) async =>
          req.url.path == '/otp/send' ? _res({'ok': true}) : r));
      await s.sendCode(phoneE164: '+22236123456', onCodeSent: () {}, onError: (_) {});
      try {
        await s.verifyCode('000000');
      } on PhoneAuthException catch (e) {
        return e.message;
      }
      fail('كان يجب أن يرمي');
    }

    test('رمزٌ خاطئ ⇒ المحاولاتُ المتبقّية', () async {
      expect(await verifyErr(_res({'error': 'otp_invalid', 'retriesLeft': 2}, 400)), contains('2'));
      expect(await verifyErr(_res({'error': 'otp_invalid'}, 400)), 'الرمز غير صحيح');
      expect(await verifyErr(_res({'error': 'otp_expired'}, 400)), isNot(contains('غير صحيح')));
    });

    test('تعطّلُ الخدمة أو الشبكة ليس «رمزًا خاطئًا»', () async {
      final down = await verifyErr(_res({'error': 'otp_unavailable'}, 503));
      expect(down, contains('غير متاحة'));
      expect(down, isNot(contains('غير صحيح')));

      final s = _server(MockClient((req) async {
        if (req.url.path == '/otp/send') return _res({'ok': true});
        throw const SocketExceptionLike();
      }));
      await s.sendCode(phoneE164: '+22236123456', onCodeSent: () {}, onError: (_) {});
      try {
        await s.verifyCode('000000');
        fail('كان يجب أن يرمي');
      } on PhoneAuthException catch (e) {
        expect(e.message, isNot(contains('غير صحيح')));
      }
    });

    test('أخطاءُ الإرسال تُترجَم برموزها', () async {
      Future<String> sendErr(http.Response r) async {
        String? msg;
        await _server(MockClient((_) async => r)).sendCode(
            phoneE164: '+22236123456', onCodeSent: () => fail('أُرسل'), onError: (m) => msg = m);
        return msg!;
      }

      expect(await sendErr(_res({'error': 'otp_rate_limited', 'retryAfter': 40}, 429)), contains('40'));
      expect(await sendErr(_res({'error': 'phone_taken'}, 409)), contains('حساب'));
      expect(await sendErr(_res({'error': 'invalid_phone'}, 400)), 'رقم الهاتف غير صحيح');
    });
  });

  testWidgets('إنشاءُ حسابٍ موريتانيّ: الإثباتُ يُرسَل بدل idToken، وواتساب بعد العدّاد', (tester) async {
    final paths = <String>[];
    Map<String, dynamic>? registered;
    final api = ApiClient(
      config: _config,
      httpClient: MockClient((req) async {
        paths.add(req.url.path);
        final b = jsonDecode(req.body) as Map<String, dynamic>;
        switch (req.url.path) {
          case '/otp/send':
            paths.add('channel:${b['channel']}');
            return _res({'ok': true});
          case '/otp/verify':
            return _res({'phoneProof': 'proof.jwt'});
          default:
            registered = b;
            return _res({
              'token': 'jwt.new',
              'player': {'id': 'p1', 'phone': '+22236123456', 'displayName': 'محمد'},
              'isNew': true,
            });
        }
      }),
    );
    await tester.pumpWidget(ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: RegisterScreen(
            api: api,
            phoneAuth: RoutedPhoneAuth(
              mauritania: ServerOtpAuth(
                  api: api, purpose: OtpPurpose.register, deviceId: () async => 'd', lang: () => 'ar'),
              others: _Spy(),
            ),
            onAuthenticated: (_) async {},
            onLogin: () {},
          ),
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), '36123456');
    await tester.tap(find.text('إرسال الرمز'));
    await tester.pumpAndSettle();
    expect(find.text('أرسل الرمز عبر واتساب'), findsNothing); // العدّادُ يعمل
    expect(find.textContaining('إعادة الإرسال بعد'), findsOneWidget);

    await tester.pump(const Duration(seconds: 61));
    expect(find.text('أرسل الرمز عبر واتساب'), findsOneWidget);
    await tester.tap(find.text('أرسل الرمز عبر واتساب'));
    await tester.pumpAndSettle();
    expect(paths, ['/otp/send', 'channel:sms', '/otp/send', 'channel:whatsapp']);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('تحقّق'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'secret1');
    await tester.enterText(find.byType(TextField).at(1), 'محمد');
    await tester.enterText(find.byType(TextField).at(2), 'نواكشوط');
    await tester.tap(find.text('إنشاء الحساب'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(registered!['phoneProof'], 'proof.jwt');
    expect(registered!.containsKey('idToken'), isFalse);
  });
}

/// خطأُ شبكةٍ عامّ (أيُّ استثناءٍ من العميل ⇒ ApiException بحالة 0).
class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
}
