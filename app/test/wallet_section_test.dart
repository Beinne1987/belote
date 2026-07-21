import 'dart:convert';

import 'package:app/app_settings.dart';
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

/// **محفظةُ اللاعب في صفحته** (طلب المالك 2026-07-15): تعرض ما يملك — ماسًا وهدايا.
///
/// الجوهرُ المفحوص: المحفظةُ **خريطةُ عملاتٍ يميّز الصنفَ بادئتُها**، فالهدايا تُشتقّ
/// منها ولا تُحفَظ على حدة — وهو ما يجعل الأسكنَ لاحقًا (`skin:<id>`) إضافةَ قارئٍ
/// لا إعادةَ تصميم.
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

MockClient _client(Map<String, Object> wallet) => MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/me/wallet')) return _json(wallet);
      if (p.endsWith('/me/stats')) {
        return _json({
          'rating': 1200,
          'matches': 8,
          'wins': 5,
          'losses': 3,
          'winStreak': 2,
          'bestStreak': 4,
          'winRate': 62
        });
      }
      if (p.contains('notifications')) return _json({'unread': 0});
      return _json(_player());
    });

Future<SessionController> _session(MockClient client) async {
  SharedPreferences.setMockInitialValues({});
  final s = SessionController(
      api: ApiClient(config: _config, httpClient: client), store: SessionStore());
  await s.signIn(AuthSession(
      token: 'TOK', player: AccountPlayer.fromJson(_player()), isNew: false));
  return s;
}

Future<void> _pump(WidgetTester tester, SessionController session) async {
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
          home: const ProfileScreen(),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('تعرض الماسَ والهدايا معًا', (tester) async {
    final s = await _session(_client({
      'diamonds': 4960,
      'gift:rose': 10,
      'gift:camel': 2,
    }));
    await _pump(tester, s);

    expect(find.text('محفظتي'), findsOneWidget);
    expect(find.text('هداياي'), findsOneWidget);
    expect(find.text('×10'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    // الرقمُ لاتينيٌّ دائمًا — و4960 يظهر مرّتين (الترويسة والمحفظة).
    expect(find.text('4960'), findsNWidgets(2));
  });

  testWidgets('لا هدايا ⇒ حالةٌ تدلّ لا تُحبِط', (tester) async {
    final s = await _session(_client({'diamonds': 100}));
    await _pump(tester, s);

    // «لا هدايا» وحدها تُحبِط ولا تُرشد ⇒ تُحيل إلى المتجر.
    expect(find.textContaining('اشترِ باقةً من المتجر'), findsOneWidget);
  });

  testWidgets('مخزونٌ صفر لا يُعرَض', (tester) async {
    final s = await _session(_client({'diamonds': 100, 'gift:rose': 0}));
    await _pump(tester, s);
    expect(find.textContaining('اشترِ باقةً'), findsOneWidget,
        reason: 'صفرٌ = لا يملك');
  });

  testWidgets('معرّفٌ لا نعرفه يُسقَط لا يُعرَض خامًا', (tester) async {
    // خادمٌ أحدثُ من الحزمة يبيع هديّةً جديدة ⇒ «ferrari» في محفظته قبحٌ.
    final s = await _session(_client({
      'diamonds': 100,
      'gift:rose': 3,
      'gift:ferrari': 5,
    }));
    await _pump(tester, s);

    expect(find.text('×3'), findsOneWidget);
    expect(find.textContaining('ferrari'), findsNothing);
    expect(find.text('×5'), findsNothing);
  });

  group('المشتقّ من المحفظة', () {
    test('الهدايا تُشتقّ بالبادئة — والماسُ ليس هديّة', () async {
      final s = await _session(_client({
        'diamonds': 500,
        'gift:rose': 3,
        'gift:tea': 1,
      }));

      expect(s.ownedGifts, {'rose': 3, 'tea': 1});
      expect(s.ownedGifts.containsKey('diamonds'), isFalse);
      expect(s.diamonds, 500);
    });

    test('صنفٌ آخرُ بالبادئة لا يختلط بالهدايا', () async {
      // هذا **جوهرُ المعمار**: يوم يوجد الأسكن (`skin:<id>`) يظهر بقارئٍ مثل
      // `ownedGifts` بلا مسارٍ ولا جدول — ولا يتسرّب إلى الهدايا اليوم.
      final s = await _session(_client({
        'diamonds': 10,
        'gift:rose': 2,
        'skin:zellij': 1,
      }));

      expect(s.ownedGifts, {'rose': 2});
      expect(s.giftStock('rose'), 2);
    });
  });
}
