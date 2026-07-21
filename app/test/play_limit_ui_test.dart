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

/// **عدّادُ اللعبات على الشاشة الرئيسيّة** — «مع عدّاد يظهر له كم من لعبة بقيت له»
/// (نصُّ المالك).
///
/// الجوهرُ المفحوص: **العدّادُ لا يخترع رقمًا**. الحدُّ مُطفأٌ خادميًّا أو لم يُجلَب
/// بعدُ ⇒ لا عدّادَ أصلًا؛ لأنّ «بقيت لك 5» كذبةٌ تُكذَّب عند أوّل ضغطة.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

/// [limitStatus] 503 ⇒ الحدُّ مُطفأٌ خادميًّا. [grace] ⇒ لاعبٌ جديدٌ في سماحه.
MockClient _client(
        {int remaining = 3,
        int limitStatus = 200,
        bool grace = false,
        int bonus = 0}) =>
    MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/me/play-limit')) {
        if (limitStatus != 200) {
          return http.Response(jsonEncode({'error': 'limit_disabled'}), limitStatus,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return _json({
          'limit': 5 + bonus,
          'used': 5 + bonus - remaining,
          'remaining': remaining,
          'canPlay': grace || remaining > 0,
          'unlimited': grace,
          if (bonus > 0) 'bonus': bonus,
          if (grace)
            'graceUntil': DateTime.now()
                .toUtc()
                .add(const Duration(days: 2))
                .toIso8601String(),
        });
      }
      if (p.endsWith('/me/wallet')) return _json({'diamonds': 100});
      if (p.endsWith('/me/stats')) {
        return _json({'rating': 1000, 'matches': 0, 'wins': 0});
      }
      if (p.contains('notifications')) return _json({'unread': 0});
      return _json(
          {'id': 'p1', 'tag': 'ABC123', 'phone': '+2221', 'displayName': 'أحمد'});
    });

Future<SessionController> _session(MockClient client,
    {bool signedIn = true}) async {
  SharedPreferences.setMockInitialValues({});
  final s = SessionController(
      api: ApiClient(config: _config, httpClient: client), store: SessionStore());
  if (signedIn) {
    await s.signIn(AuthSession(
        token: 'TOK',
        player: AccountPlayer.fromJson(
            {'id': 'p1', 'tag': 'ABC123', 'phone': '+2221', 'displayName': 'أحمد'}),
        isNew: false));
    await s.refresh(); // يجلب المحفظةَ والإحصاءَ والعدّاد
  }
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
          home: HomeScreen(onPlay: () {}),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('العدّاد يعرض ما يقوله الخادم', () {
    testWidgets('ثلاثٌ باقيةٌ ⇒ 3/5 ونصٌّ يقولها', (tester) async {
      final s = await _session(_client(remaining: 3));
      await _pump(tester, s);

      expect(find.text('3/5'), findsOneWidget);
      expect(find.text('بقيت لك 3 لعباتٍ اليوم'), findsOneWidget);
    });

    // **يقول ما العمل لا «انتهت» وحدَها** — والأوفلاين حرٌّ بلا حدّ.
    testWidgets('نفدت ⇒ 0/5 ويقول متى تعود', (tester) async {
      final s = await _session(_client(remaining: 0));
      await _pump(tester, s);

      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('انتهت لعباتُك اليوم — تعود غدًا'), findsOneWidget);
    });

    // عربيّةٌ سليمة: «1 لعبات» و«2 لعبات» ركاكةٌ يراها كلُّ لاعبٍ كلَّ يوم.
    testWidgets('واحدةٌ ⇒ «لعبةٌ واحدة» لا «1 لعبات»', (tester) async {
      final s = await _session(_client(remaining: 1));
      await _pump(tester, s);
      expect(find.text('بقيت لك لعبةٌ واحدةٌ اليوم'), findsOneWidget);
    });

    testWidgets('اثنتان ⇒ «لعبتان» بالمثنّى', (tester) async {
      final s = await _session(_client(remaining: 2));
      await _pump(tester, s);
      expect(find.text('بقيت لك لعبتان اليوم'), findsOneWidget);
    });

    // الأرقام لاتينيّةٌ دائمًا (CLAUDE.md) — لا ٣/٥.
    testWidgets('الأرقام لاتينيّةٌ لا هنديّة', (tester) async {
      final s = await _session(_client(remaining: 3));
      await _pump(tester, s);
      expect(find.text('٣/٥'), findsNothing);
      expect(find.text('3/5'), findsOneWidget);
    });
  });

  // **سماحُ الجديد**: أوّلُ ثلاثة أيّامٍ يقرّر فيها أيبقى أم يذهب.
  group('اللاعبُ الجديد في سماحه', () {
    testWidgets('يُرحَّب به بلا حدود — لا عدّادَ يُخيفه', (tester) async {
      final s = await _session(_client(grace: true, remaining: 0));
      await _pump(tester, s);

      expect(find.textContaining('أهلًا بك!'), findsOneWidget);
      expect(find.textContaining('لعبٌ بلا حدود — الباقي:'), findsOneWidget);
      expect(find.text('0/5'), findsNothing, reason: 'جدارٌ قبل أن يغرم');
      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
    });

    // **مَن أُهدي لا يُقال له إنّه اشترى.**
    testWidgets('لا يُذكَّر بتذكرةٍ لم يشترها', (tester) async {
      final s = await _session(_client(grace: true));
      await _pump(tester, s);

      expect(s.allowance!.isGrace, isTrue);
      expect(s.allowance!.passUntil, isNull);
    });
  });

  // **صمّامُ الدعوة**: لعباتٌ مكتسَبةٌ تُشكَر عليها فيدعو أكثر.
  group('اللعباتُ المكتسَبةُ من الدعوة', () {
    testWidgets('الحدُّ يشمل المكتسَبَ والنصُّ يشكره', (tester) async {
      final s = await _session(_client(remaining: 4, bonus: 2));
      await _pump(tester, s);

      expect(find.text('4/7'), findsOneWidget, reason: '5 + 2 مكتسبة');
      expect(find.textContaining('من دعوة أصدقائك'), findsOneWidget);
    });
  });

  group('لا يخترع رقمًا', () {
    // **الجوهر**: الإطفاءُ يُطلق ولا يَحبِس ⇒ لا حدَّ ولا عدّاد.
    testWidgets('الحدُّ مُطفأٌ خادميًّا (503) ⇒ لا عدّادَ ولا رقم', (tester) async {
      final s = await _session(_client(limitStatus: 503));
      await _pump(tester, s);

      expect(find.textContaining('/5'), findsNothing);
      expect(find.textContaining('بقيت لك'), findsNothing);
      expect(find.text('مع لاعبين حقيقيّين'), findsOneWidget,
          reason: 'الوصفُ الأصليّ لا رقمٌ مخترَع');
    });

    testWidgets('ضيفٌ غيرُ مصادَق ⇒ لا عدّاد بل دعوةٌ للدخول', (tester) async {
      final s = await _session(_client(), signedIn: false);
      await _pump(tester, s);

      expect(find.textContaining('/5'), findsNothing);
      expect(find.text('مع لاعبين حقيقيّين — يتطلّب دخولًا'), findsOneWidget);
    });
  });
}
