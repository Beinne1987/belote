import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _config = ApiConfig.fromOrigin('http://test.local');

AuthSession _session(String token) => AuthSession(
      token: token,
      player: const AccountPlayer(
          id: 'p1', phone: '+22200000000', displayName: 'لاعب', countryCode: 'MR', city: 'نواكشوط'),
      isNew: false,
    );

http.Response _json(Object o) =>
    http.Response(jsonEncode(o), 200, headers: {'content-type': 'application/json; charset=utf-8'});

SessionController _controller(MockClient mock) => SessionController(
      api: ApiClient(config: _config, httpClient: mock),
      store: SessionStore(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loadSaved بلا جلسة ⇒ غير مصادَق، loaded=true', () async {
    final c = _controller(MockClient((_) async => _json({})));
    await c.loadSaved();
    expect(c.loaded, true);
    expect(c.isSignedIn, false);
  });

  test('signIn ⇒ يجلب المحفظة والإحصائيات ويحفظ الجلسة', () async {
    final c = _controller(MockClient((req) async {
      if (req.url.path == '/me/wallet') {
        return _json({'diamonds': 5, 'gift:rose': 3});
      }
      if (req.url.path == '/me/stats') {
        return _json({'rating': 1200, 'matches': 8, 'wins': 5, 'losses': 3, 'winStreak': 2, 'bestStreak': 4, 'winRate': 62});
      }
      return _json({});
    }));
    await c.signIn(_session('tok'));
    expect(c.isSignedIn, true);
    expect(c.diamonds, 5);
    // المخزونُ يصل في المحفظة نفسِها — لا مسارَ ثانٍ له.
    expect(c.giftStock('rose'), 3);
    expect(c.giftStock('car'), 0, reason: 'ما لا يملكه = صفرٌ لا عطب');
    expect(c.stats!.rating, 1200);
    expect(c.stats!.winRatePct, 62);

    // حُفِظت ⇒ استعادةٌ لاحقة تجدها.
    final restored = await SessionStore().load();
    expect(restored!.token, 'tok');
  });

  test('refresh بتوكن منتهٍ (401) ⇒ خروجٌ تلقائيّ', () async {
    final c = _controller(MockClient((req) async =>
        http.Response(jsonEncode({'error': 'توكن غير صالح'}), 401,
            headers: {'content-type': 'application/json; charset=utf-8'})));
    await c.signIn(_session('expired'));
    expect(c.isSignedIn, false); // signIn استدعى refresh فأخرج
    expect(await SessionStore().load(), isNull);
  });

  test('signOut ⇒ يمسح الجلسة والبيانات', () async {
    final c = _controller(MockClient((req) async {
      if (req.url.path == '/me/wallet') return _json({'diamonds': 50});
      return _json({'rating': 1000, 'matches': 0, 'wins': 0, 'losses': 0, 'winStreak': 0, 'bestStreak': 0, 'winRate': 0});
    }));
    await c.signIn(_session('tok'));
    expect(c.isSignedIn, true);
    await c.signOut();
    expect(c.isSignedIn, false);
    expect(c.diamonds, 0);
    expect(c.stats, isNull);
    expect(await SessionStore().load(), isNull);
  });
}
