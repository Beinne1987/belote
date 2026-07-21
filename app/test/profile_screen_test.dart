import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _config = ApiConfig.fromOrigin('http://test.local');

http.Response _json(Object o) =>
    http.Response(jsonEncode(o), 200, headers: {'content-type': 'application/json; charset=utf-8'});

Widget _wrap(SessionController c, {VoidCallback? onSignIn}) => ThemeScope(
      manager: ThemeManager(),
      child: SessionScope(
        controller: c,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProfileScreen(onSignIn: onSignIn),
          ),
        ),
      ),
    );

SessionController _controller(MockClient m) =>
    SessionController(api: ApiClient(config: _config, httpClient: m), store: SessionStore());

AuthSession _sess() => const AuthSession(
      token: 'tok',
      player: AccountPlayer(
          id: 'p1', phone: '+22200000000', displayName: 'محمد', countryCode: 'MR', city: 'نواكشوط'),
      isNew: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('غير مصادَق ⇒ دعوة تسجيل الدخول، والزرّ ينادي onSignIn', (tester) async {
    final c = _controller(MockClient((_) async => _json({})));
    var tapped = false;
    await tester.pumpWidget(_wrap(c, onSignIn: () => tapped = true));
    await tester.pumpAndSettle();

    expect(find.textContaining('سجّل الدخول'), findsWidgets);
    await tester.tap(find.text('تسجيل الدخول'));
    expect(tapped, true);
  });

  testWidgets('مصادَق ⇒ إحصائيات حقيقيّة (اسم + تقييم + تايلات)', (tester) async {
    final c = _controller(MockClient((req) async {
      if (req.url.path == '/me/wallet') return _json({'diamonds': 0});
      return _json({'rating': 1350, 'matches': 12, 'wins': 7, 'losses': 5, 'winStreak': 1, 'bestStreak': 3, 'winRate': 58});
    }));
    await c.signIn(_sess());
    await tester.pumpWidget(_wrap(c));
    await tester.pumpAndSettle();

    expect(find.text('محمد'), findsOneWidget);
    expect(find.text('1350'), findsWidgets); // التقييم
    expect(find.text('58%'), findsWidgets); // نسبة الفوز
    expect(find.text('أفضل سلسلة'), findsOneWidget);
  });
}
