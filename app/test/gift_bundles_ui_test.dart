import 'dart:convert';

import 'package:app/app_settings.dart';
import 'package:app/game/seat_player.dart';
import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/gift_picker.dart';
import 'package:app/ui/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **قسمُ الهدايا في المتجر ومخزونُه.** الجوهرُ المفحوص شيئان:
/// 1. الأسعارُ تُعرَض **كما يرسلها الخادم** لا كما نحسبها هنا.
/// 2. ما يملكه اللاعبُ **لا يُعرَض له ثمن** — لن يُخصَم منه شيء.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

const _bundles = {
  'bundles': [
    {'id': 'rosex10', 'gift': 'rose', 'emoji': '🌹', 'qty': 10, 'price': 40, 'fullPrice': 50},
    {'id': 'rosex50', 'gift': 'rose', 'emoji': '🌹', 'qty': 50, 'price': 175, 'fullPrice': 250},
  ]
};

const _packs = {
  'packs': [
    {'id': 'd100', 'price': 100, 'base': 100, 'bonus': 0, 'total': 100},
    {'id': 'd5000', 'price': 5000, 'base': 5000, 'bonus': 1000, 'total': 6000},
  ]
};

MockClient _client(
        {int diamonds = 1000,
        int roses = 0,
        int buyStatus = 200,
        Object packs = _packs}) =>
    MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/store/diamond-packs')) return _json(packs);
      if (p.endsWith('/store/gift-bundles')) return _json(_bundles);
      if (p.endsWith('/me/gift-bundles/buy')) {
        if (buyStatus != 200) {
          return http.Response(jsonEncode({'error': 'store_insufficient'}), buyStatus,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return _json({
          'stock': 10,
          'wallet': {'diamonds': diamonds - 40, 'gift:rose': roses + 10}
        });
      }
      if (p.endsWith('/me/wallet')) {
        return _json({'diamonds': diamonds, if (roses > 0) 'gift:rose': roses});
      }
      if (p.endsWith('/me/stats')) {
        return _json({'rating': 1000, 'matches': 0, 'wins': 0});
      }
      if (p.contains('notifications')) return _json({'unread': 0});
      return _json({'id': 'p1', 'tag': 'ABC123', 'phone': '+2221', 'displayName': 'أحمد'});
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
  return s;
}

Future<void> _pump(WidgetTester tester, SessionController session, Widget home) async {
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
          home: home,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('المتجر', () {
    testWidgets('يعرض ثمنَ الخادم — والكاملَ مشطوبًا والوفر', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));

      expect(find.text('40'), findsOneWidget, reason: 'ثمنُ ×10 كما أرسله الخادم');
      expect(find.text('50'), findsOneWidget, reason: 'الكاملُ مشطوبًا');
      expect(find.text('175'), findsOneWidget);
      // النسبةُ تُشتقّ من رقمَي الخادم — لا معادلةَ خصمٍ منسوخةً هنا تنجرف.
      expect(find.text('وفّر 20%'), findsOneWidget);
      expect(find.text('وفّر 30%'), findsOneWidget);
    });

    testWidgets('رصيدُه أمامه وهو يتسوّق', (tester) async {
      final s = await _session(_client(diamonds: 5000));
      await _pump(tester, s, StoreScreen(session: s));
      expect(find.text('5000'), findsOneWidget);
    });

    testWidgets('شراءٌ ناجح ⇒ المحفظة من الردّ نفسِه', (tester) async {
      final s = await _session(_client(diamonds: 1000));
      await _pump(tester, s, StoreScreen(session: s));

      await tester.tap(find.text('×10'));
      await tester.pumpAndSettle();

      expect(s.diamonds, 960, reason: '1000 − 40 كما قال الخادم');
      expect(s.giftStock('rose'), 10);
      expect(find.text('960'), findsOneWidget, reason: 'الرصيدُ يتحدّث فورًا');
    });

    testWidgets('402 ⇒ رسالةٌ تشرح لا «فشل الشراء»', (tester) async {
      final s = await _session(_client(diamonds: 10, buyStatus: 402));
      await _pump(tester, s, StoreScreen(session: s));

      await tester.tap(find.text('×10'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('ماسك لا يكفي'), findsOneWidget);
      expect(s.diamonds, 10, reason: 'لم يُمَسّ رصيدُه');
    });

    testWidgets('ما يملكه ظاهرٌ عند الشراء', (tester) async {
      final s = await _session(_client(roses: 23));
      await _pump(tester, s, StoreScreen(session: s));
      expect(find.text('تملك 23'), findsOneWidget);
    });
  });

  // **شريطُ الأنواع.** كان القسمان متتاليين في قائمةٍ واحدةٍ ⇒ الماسُ تحت الطيّة،
  // ومَن لا يعلم بوجوده لا يمرّر إليه (طلبُ المالك 2026-07-16).
  group('شريطُ الأنواع', () {
    testWidgets('النوعان ظاهران دفعةً واحدةً بلا تمرير', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));

      expect(find.text('الهدايا'), findsOneWidget);
      expect(find.text('الماس'), findsOneWidget);
    });

    testWidgets('الهدايا افتراضًا — النوعُ الوحيد الذي يُشترى اليوم', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));

      expect(find.text('×10'), findsOneWidget, reason: 'باقةُ هدايا');
      expect(find.text('100 أوقية'), findsNothing, reason: 'الماسُ لم يُفتَح بعد');
    });

    testWidgets('الضغطُ على نوعٍ يفتح صفحتَه في نفس الصفحة', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));

      await tester.tap(find.text('الماس'));
      await tester.pumpAndSettle();

      expect(find.text('100 أوقية'), findsOneWidget, reason: 'صفحةُ الماس فُتحت');
      expect(find.text('×10'), findsNothing, reason: 'وصفحةُ الهدايا انصرفت');
      // **في نفس الصفحة**: لا شاشةَ جديدةً تُكدَّس ⇒ الرصيدُ والشريطُ باقيان.
      expect(find.text('الهدايا'), findsOneWidget, reason: 'الشريطُ باقٍ فيرجع بنقرة');
      expect(find.byType(StoreScreen), findsOneWidget);
    });

    testWidgets('ويرجع بنقرةٍ إلى الهدايا', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));

      await tester.tap(find.text('الماس'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الهدايا'));
      await tester.pumpAndSettle();

      expect(find.text('×10'), findsOneWidget);
    });

    // نوعٌ لا بضاعةَ فيه لا يُعرَض له زرٌّ يفتح فراغًا — والشريطُ يسقط كلُّه إن بقي واحد.
    testWidgets('قسمٌ فارغٌ خادميًّا ⇒ لا زرَّ له ولا شريطَ من واحد', (tester) async {
      final s = await _session(_client(packs: {'packs': []}));
      await _pump(tester, s, StoreScreen(session: s));

      expect(find.text('الماس'), findsNothing, reason: 'لا زرَّ يفتح فراغًا');
      expect(find.text('الهدايا'), findsNothing, reason: 'شريطُ نوعٍ واحدٍ زينةٌ');
      expect(find.text('×10'), findsOneWidget, reason: 'والبضاعةُ الباقيةُ تُعرَض');
    });
  });

  group('باقات الماس', () {
    testWidgets('السلّم: ما تدفع وما تنال والبونصُ منفصلًا', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));
      await tester.tap(find.text('الماس'));
      await tester.pumpAndSettle();

      expect(find.text('100 أوقية'), findsOneWidget, reason: 'ما يدفع');
      expect(find.text('5000 أوقية'), findsOneWidget);
      expect(find.text('6000'), findsOneWidget, reason: 'ما ينال — 5000 + 1000');
      expect(find.text('(5000 + 1000)'), findsOneWidget, reason: 'البونصُ مفصولٌ لا مدسوس');
      expect(find.text('هديّة 20%'), findsOneWidget);
    });

    testWidgets('القاعُ بلا بونص ⇒ لا شارةَ هديّةٍ عليه', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));
      await tester.tap(find.text('الماس'));
      await tester.pumpAndSettle();

      expect(find.text('هديّة 0%'), findsNothing);
      expect(find.text('(100 + 0)'), findsNothing, reason: 'صفرُ بونصٍ لا يُكتَب');
    });

    // **لا زرَّ شراءٍ ميّت**: بنكيلي آخرُ خطوة، وزرٌّ يُنقَر فلا يحدث شيءٌ أسوأُ من
    // غيابه. لكنّ السلّمَ معلومةٌ حقيقيّةٌ يريدها اللاعب ⇒ يُعرَض ويُقال متى يُشترى.
    testWidgets('تُخبر ولا تكذب: لا شراءَ الآن وتقول ذلك', (tester) async {
      final s = await _session(_client());
      await _pump(tester, s, StoreScreen(session: s));
      await tester.tap(find.text('الماس'));
      await tester.pumpAndSettle();

      expect(find.textContaining('بنكيلي'), findsOneWidget);
      expect(find.text('شراء'), findsNothing, reason: 'لا زرَّ لا يعمل');
    });
  });

  group('لوحة الهدايا', () {
    Future<void> pumpSheet(WidgetTester tester, int Function(String)? stock) async {
      await tester.pumpWidget(ThemeScope(
        manager: ThemeManager(),
        child: MaterialApp(
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showGiftSheet(
                  ctx,
                  targets: [(viewSeat: 1, player: const SeatPlayer(name: 'بلال'))],
                  onSend: (_, __) {},
                  stock: stock,
                ),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
    }

    testWidgets('بلا مخزون ⇒ الثمنُ يُعرَض', (tester) async {
      await pumpSheet(tester, null);
      expect(find.text('5'), findsOneWidget, reason: 'ثمنُ الوردة');
      expect(find.text('10'), findsOneWidget, reason: 'وثمنُ الأتاي');
    });

    // **الجوهر**: هديّةٌ تخرج من المخزون لا يُخصَم لها ثمن ⇒ عرضُ الثمن عليها كذب.
    testWidgets('يملك وردًا ⇒ العددُ مكان الثمن', (tester) async {
      await pumpSheet(tester, (g) => g == 'rose' ? 7 : 0);

      expect(find.text('×7'), findsOneWidget);
      expect(find.text('5'), findsNothing, reason: 'لا ثمنَ لِما دُفع سلفًا');
      expect(find.text('10'), findsOneWidget, reason: 'والأتاي بلا مخزونٍ يُبقي ثمنَه');
    });
  });
}
