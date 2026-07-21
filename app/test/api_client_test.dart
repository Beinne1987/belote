import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// إعدادٌ ثابتٌ للاختبار (لا شبكة فعليّة — العميل الوهميّ يعترض).
final _config = ApiConfig.fromOrigin('http://test.local');

ApiClient _client(MockClient mock) => ApiClient(config: _config, httpClient: mock);

void main() {
  test('login: يرسل الهاتف/كلمة السرّ للمسار الصحيح ويحلّل الجلسة', () async {
    http.Request? seen;
    final api = _client(MockClient((req) async {
      seen = req;
      return http.Response(
          jsonEncode({
            'token': 'jwt.abc',
            'player': {'id': 'p1', 'phone': '+22200000000', 'displayName': 'لاعب'},
            'isNew': false,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    final s = await api.login('+22200000000', 'secret1');
    expect(seen!.url.path, '/auth/login');
    expect(jsonDecode(seen!.body)['password'], 'secret1');
    expect(s.token, 'jwt.abc');
    expect(s.player.id, 'p1');
  });

  test('login: بيانات خاطئة ⇒ 401 ApiException برسالة الخادم', () async {
    final api = _client(MockClient((req) async =>
        http.Response(jsonEncode({'error': 'رقم الهاتف أو كلمة السرّ غير صحيحة'}), 401,
            headers: {'content-type': 'application/json; charset=utf-8'})));
    expect(
      () => api.login('+22200000000', 'wrong'),
      throwsA(isA<ApiException>()
          .having((e) => e.status, 'status', 401)
          .having((e) => e.message, 'message', 'رقم الهاتف أو كلمة السرّ غير صحيحة')),
    );
  });

  test('register: يرسل التوكن وكلمة السرّ والملف ويحلّل الجلسة', () async {
    http.Request? seen;
    final api = _client(MockClient((req) async {
      seen = req;
      return http.Response(
          jsonEncode({
            'token': 'jwt.new',
            'player': {
              'id': 'p1',
              'phone': '+22200000000',
              'displayName': 'محمد',
              'countryCode': 'MR',
              'city': 'نواكشوط',
            },
            'isNew': true,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    final s = await api.register(
        idToken: 'fb.tok', password: 'secret1', displayName: 'محمد', countryCode: 'MR', city: 'نواكشوط');
    expect(seen!.url.path, '/auth/register');
    final body = jsonDecode(seen!.body) as Map<String, dynamic>;
    expect(body['idToken'], 'fb.tok');
    expect(body['countryCode'], 'MR');
    expect(s.isNew, true);
    expect(s.player.city, 'نواكشوط');
  });

  test('me: يرسل ترويسة Bearer ويحلّل اللاعب', () async {
    http.Request? seen;
    final api = _client(MockClient((req) async {
      seen = req;
      return http.Response(
          jsonEncode({'id': 'p1', 'phone': '+22200000000', 'displayName': 'لاعب'}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    final p = await api.me('jwt.abc');
    expect(seen!.headers['authorization'], 'Bearer jwt.abc');
    expect(p.id, 'p1');
  });

  test('فشل الشبكة ⇒ ApiException(0)', () async {
    final api = _client(MockClient((req) async => throw Exception('down')));
    expect(() => api.me('t'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 0)));
  });
}
