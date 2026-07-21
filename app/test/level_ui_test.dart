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

/// **المستوى في صفحة اللاعب.** الجوهر: كلُّ أرقامه من الخادم — منحنى الخبرة قرارٌ
/// خادميّ، ونسخُه هنا يجعل حزمةً قديمةً تعرض مستوًى غيرَ الحقيقيّ.
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

MockClient _client(Map<String, Object> stats) => MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/me/wallet')) return _json({'diamonds': 100});
      if (p.endsWith('/me/stats')) return _json(stats);
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

const _base = {
  'rating': 1200,
  'matches': 8,
  'wins': 5,
  'losses': 3,
  'winStreak': 2,
  'bestStreak': 4,
  'winRate': 62,
};

void main() {
  testWidgets('يعرض المستوى وما بقي للتالي وشريطَ التقدّم', (tester) async {
    final s = await _session(_client({
      ..._base,
      'xp': 220,
      'level': 2,
      'xpToNext': 80,
      'levelProgress': 0.6,
    }));
    await _pump(tester, s);

    expect(find.text('المستوى '), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    // الرقمُ وحده ليس تقدّمًا — الشريطُ يقول أين هو، والنصُّ كم بقي بالضبط.
    expect(find.text('80 خبرة للتالي'), findsOneWidget);

    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(0.6, 1e-9));
  });

  testWidgets('خادمٌ أقدمُ من الميزة ⇒ لا مستوًى مخترَعٌ ولا شريطٌ فارغ',
      (tester) async {
    // `level` غائبٌ ⇒ 0 ⇒ يُخفى القسمُ كلُّه.
    final s = await _session(_client(_base));
    await _pump(tester, s);

    expect(find.text('المستوى '), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('تقدّمٌ خارج المدى لا يُسقط الشاشة', (tester) async {
    // قيمةٌ فاسدةٌ من خادمٍ أحدث: `LinearProgressIndicator` يرمي خارج [0,1]
    // ⇒ شاشةٌ بيضاءُ لأجل شريط. الحارسُ يُثبت أنّ `clamp` يمنعها.
    final s = await _session(_client({
      ..._base,
      'level': 3,
      'xpToNext': 50,
      'levelProgress': 1.7,
    }));
    await _pump(tester, s);

    expect(tester.takeException(), isNull);
    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, 1.0);
  });

  group('لا يُحسَب المنحنى في العميل', () {
    test('المستوى يُقرأ كما أرسله الخادم — لا يُشتقّ من الخبرة', () {
      // خادمٌ غيّر منحناه ⇒ العميلُ يتبعه بلا تحديثِ حزمة. لو حسبنا هنا لاختلفا.
      final v = PlayerStatsView.fromJson({
        ..._base,
        'xp': 100,
        'level': 9, // منحنًى مختلفٌ عمدًا عمّا كنّا سنحسبه
        'xpToNext': 7,
        'levelProgress': 0.3,
      });

      expect(v.level, 9, reason: 'الخادمُ هو المرجع');
      expect(v.xp, 100);
      expect(v.xpToNext, 7);
    });

    test('حقولٌ غائبة ⇒ أصفارٌ لا رمي', () {
      final v = PlayerStatsView.fromJson(_base);
      expect(v.level, 0);
      expect(v.xp, 0);
      expect(v.levelProgress, 0);
    });
  });
}
