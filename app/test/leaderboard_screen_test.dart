import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _config = ApiConfig.fromOrigin('http://test.local');

ApiClient _api(MockClient m) => ApiClient(config: _config, httpClient: m);

Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

http.Response _json(Object o) =>
    http.Response(jsonEncode(o), 200, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  testWidgets('بيانات ⇒ منصّة + صفوف بأسماء وتقييمات حقيقيّة', (tester) async {
    final api = _api(MockClient((req) async => _json({
          'entries': [
            {'playerId': 'a', 'displayName': 'محمد', 'rating': 1400, 'matches': 20, 'wins': 12},
            {'playerId': 'b', 'displayName': 'عائشة', 'rating': 1300, 'matches': 18, 'wins': 10},
            {'playerId': 'c', 'displayName': 'سيدي', 'rating': 1200, 'matches': 15, 'wins': 8},
            {'playerId': 'd', 'displayName': 'خديجة', 'rating': 1100, 'matches': 10, 'wins': 4},
          ],
        })));
    await tester.pumpWidget(_wrap(LeaderboardScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('محمد'), findsOneWidget); // المركز الأول في المنصّة
    expect(find.text('خديجة'), findsOneWidget); // صفّ رابع
    expect(find.text('1400'), findsOneWidget);
    expect(find.textContaining('10 مباراة'), findsOneWidget); // صفّ خديجة
  });

  testWidgets('فارغ ⇒ رسالة لا تصنيف بعد', (tester) async {
    final api = _api(MockClient((req) async => _json({'entries': []})));
    await tester.pumpWidget(_wrap(LeaderboardScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.textContaining('لا تصنيف بعد'), findsOneWidget);
  });

  testWidgets('خطأ ⇒ رسالة + زرّ إعادة', (tester) async {
    final api = _api(MockClient((req) async =>
        http.Response(jsonEncode({'error': 'خطأ خادم'}), 500,
            headers: {'content-type': 'application/json; charset=utf-8'})));
    await tester.pumpWidget(_wrap(LeaderboardScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
