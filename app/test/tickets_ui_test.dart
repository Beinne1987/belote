import 'dart:convert';

import 'package:app/app_settings.dart';
import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/home_screen.dart';
import 'package:app/ui/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **التذاكر في الواجهة** — النوعُ الوحيد الذي يُباع فعلًا بزرٍّ يعمل.
///
/// الجوهرُ المفحوص: **مَن دفع يرى ما اشترى فورًا** (لا «0/5» لصاحب تذكرة)، و**402
/// تقوده إلى مخرجٍ** (صفحةُ الماس) لا إلى حائط.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

const _tickets = {
  'tickets': [
    {'id': 'day', 'price': 50, 'hours': 24},
    {'id': 'week', 'price': 250, 'hours': 168},
  ]
};

MockClient _client(
        {int diamonds = 100,
        int buyStatus = 200,
        int remaining = 0,
        bool suggestVip = false}) =>
    MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/store/tickets')) return _json(_tickets);
      if (p.endsWith('/store/diamond-packs')) {
        return _json({
          'packs': [
            {'id': 'd100', 'price': 100, 'base': 100, 'bonus': 0, 'total': 100}
          ]
        });
      }
      if (p.endsWith('/store/gift-bundles')) {
        return _json({
          'bundles': [
            {'id': 'rosex10', 'gift': 'rose', 'emoji': '🌹', 'qty': 10, 'price': 40, 'fullPrice': 50}
          ]
        });
      }
      if (p.endsWith('/me/tickets/buy')) {
        if (buyStatus != 200) {
          return http.Response(jsonEncode({'error': 'ticket_insufficient'}),
              buyStatus,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return _json({
          'passUntil':
              DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
          'wallet': {'diamonds': diamonds - 50},
          if (suggestVip) 'suggestVip': true,
        });
      }
      if (p.endsWith('/me/play-limit')) {
        return _json({
          'limit': 5,
          'used': 5 - remaining,
          'remaining': remaining,
          'canPlay': remaining > 0,
          'unlimited': false,
        });
      }
      if (p.endsWith('/me/wallet')) return _json({'diamonds': diamonds});
      if (p.endsWith('/me/stats')) {
        return _json({'rating': 1000, 'matches': 0, 'wins': 0});
      }
      if (p.contains('notifications')) return _json({'unread': 0});
      return _json(
          {'id': 'p1', 'tag': 'ABC123', 'phone': '+2221', 'displayName': 'أحمد'});
    });

Future<SessionController> _session(MockClient client) async {
  SharedPreferences.setMockInitialValues({});
  final s = SessionController(
      api: ApiClient(config: _config, httpClient: client), store: SessionStore());
  await s.signIn(AuthSession(
      token: 'TOK',
      player: AccountPlayer.fromJson(
          {'id': 'p1', 'tag': 'ABC123', 'phone': '+2221', 'displayName': 'أحمد'}),
      isNew: false));
  await s.refresh();
  return s;
}

Future<void> _pump(WidgetTester tester, SessionController s, Widget home) async {
  final settings = AppSettings();
  await settings.load();
  await tester.pumpWidget(ThemeScope(
    manager: ThemeManager(),
    child: AppSettingsScope(
      settings: settings,
      child: SessionScope(
        controller: s,
        child: MaterialApp(
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: home,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('صفحةُ التذاكر', () {
    testWidgets('هي الافتراضُ — وما يُباع فعلًا يُرى أوّلًا', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));

      expect(find.text('يومٌ كامل — 24 ساعة'), findsOneWidget);
      expect(find.text('أسبوعٌ كامل — 7 أيّام'), findsOneWidget);
    });

    testWidgets('الأثمانُ من الخادم — 50 و250', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));

      expect(find.text('50'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
    });

    testWidgets('الأسبوعُ يقول لماذا يُشترى', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));
      expect(find.text('أوفرُ من سبع تذاكرِ يوم'), findsOneWidget);
    });

    // **زرٌّ يعمل فعلًا** — بخلاف باقات الماس (لا بنكيلي ⇒ لا زرّ).
    testWidgets('شراءٌ ناجح ⇒ المحفظةُ من الردّ والعدّادُ يصير بلا حدود',
        (tester) async {
      final s = await _session(_client(diamonds: 100));
      await _pump(tester, s, StoreScreen(session: s));

      await tester.tap(find.text('50'));
      await tester.pumpAndSettle();

      expect(s.diamonds, 50, reason: '100 − 50 كما قال الخادم');
      expect(s.allowance!.unlimited, isTrue);
      expect(s.allowance!.canPlay, isTrue);
    });

    // **عرضُ VIP لمن يشتري تذاكرَ كثيرة**: الخادمُ يقرّر، والعميلُ يعرض.
    testWidgets('اشترى تذاكرَ كثيرةً (suggestVip) ⇒ يُعرَض VIP', (tester) async {
      final s = await _session(_client(diamonds: 100, suggestVip: true));
      await _pump(tester, s, StoreScreen(session: s));

      await tester.tap(find.text('50'));
      await tester.pump(); // بدء الشراء
      await tester.pump(const Duration(milliseconds: 300)); // ردُّ الشبكة والنافذة
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('لماذا لا تصير VIP؟'), findsOneWidget);
      expect(find.text('شاهد VIP'), findsOneWidget);
    });

    testWidgets('لا suggestVip ⇒ لا عرض', (tester) async {
      final s = await _session(_client(diamonds: 100));
      await _pump(tester, s, StoreScreen(session: s));

      await tester.tap(find.text('50'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('لماذا لا تصير VIP؟'), findsNothing);
    });

    // **402 تقود إلى مخرجٍ لا إلى حائط.**
    testWidgets('ماسٌ لا يكفي ⇒ يشرح ويفتح صفحةَ الماس', (tester) async {
      final s = await _session(_client(diamonds: 10, buyStatus: 402));
      await _pump(tester, s, StoreScreen(session: s));

      await tester.tap(find.text('50'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('ماسك لا يكفي'), findsOneWidget);
      expect(s.diamonds, 10, reason: 'لم يُمَسّ رصيدُه');
      await tester.pumpAndSettle();
      expect(find.text('100 أوقية'), findsOneWidget,
          reason: 'فُتحت صفحةُ الماس — مخرجٌ لا حائط');
    });
  });

  group('العدّادُ بعد الشراء', () {
    testWidgets('صاحبُ التذكرة يرى «بلا حدود» لا «0/5»', (tester) async {
      final s = await _session(_client(remaining: 0));
      await _pump(tester, s, HomeScreen(onPlay: () {}));
      expect(find.text('0/5'), findsOneWidget); // قبل الشراء

      await s.buyTicket('day');
      await tester.pumpAndSettle();

      expect(find.text('0/5'), findsNothing, reason: 'إهانةٌ لمن دفع');
      // **مطابقةٌ دقيقة**: بطاقةُ VIP تحمل «لعبٌ بلا حدود» في وصفها أيضًا ⇒
      // «الباقي:» وحدَها تخصّ العدّاد.
      expect(find.textContaining('لعبٌ بلا حدود — الباقي:'), findsOneWidget);
      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
    });

    testWidgets('يقول كم بقي من تذكرته بعربيّةٍ سليمة', (tester) async {
      final s = await _session(_client(remaining: 0));
      await _pump(tester, s, HomeScreen(onPlay: () {}));
      await s.buyTicket('day');
      await tester.pumpAndSettle();

      // تذكرةُ يومٍ ⇒ «الباقي: يومٌ واحد» (23 ساعةً و59 دقيقةً تقريبًا ⇒ أقلُّ من يوم)
      expect(find.textContaining('الباقي:'), findsOneWidget);
      expect(find.textContaining('1 يوم'), findsNothing,
          reason: 'المثنّى والمفردُ مضبوطان لا «1 يوم»');
    });
  });
}
