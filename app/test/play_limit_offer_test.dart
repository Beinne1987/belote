import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/play_limit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **عرضُ «افتح يومًا كاملًا»** — طلبُ المالك: نافذةٌ عند نفاد الخمس تعرض تفعيلَ
/// 24 ساعةً وفيها زرٌّ يقود إلى مكان الدفع.
///
/// الجوهرُ المفحوص ثلاثةٌ ([[conversion-strategy]]):
/// 1. **تبيع رغبةً لا ترفع عقوبة** — العنوانُ عرضٌ لا نعي.
/// 2. **لا تُحاصِره** — تقول إنّ الأوفلاين حرٌّ ومتى تعود لعباتُه.
/// 3. **402 تقود إلى مكان الدفع** لا إلى حائط.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

MockClient _client(
        {int buyStatus = 200,
        bool ticketsFail = false,
        bool trial = false,
        int trialStatus = 200}) =>
    MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/me/tickets/trial')) {
        if (trialStatus != 200) {
          return http.Response(jsonEncode({'error': 'trial_used'}), trialStatus,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return _json({
          'passUntil':
              DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
        });
      }
      if (p.endsWith('/me/play-limit')) {
        return _json({
          'limit': 5,
          'used': 5,
          'remaining': 0,
          'canPlay': false,
          'unlimited': false,
          'trialAvailable': trial,
        });
      }
      if (p.endsWith('/store/tickets')) {
        if (ticketsFail) return http.Response('nope', 500);
        return _json({
          'tickets': [
            {'id': 'day', 'price': 50, 'hours': 24},
            {'id': 'week', 'price': 250, 'hours': 168},
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
          'wallet': {'diamonds': 50},
        });
      }
      return _json({'diamonds': 100});
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
  await s.refreshPlayLimit(); // النافذةُ تقرأ `trialAvailable` من العدّاد
  return s;
}

/// يفتح العرضَ ويلتقط نتيجتَه وهل فُتح المتجر.
Future<({List<bool> bought, List<int> store})> _open(
    WidgetTester tester, SessionController s) async {
  final bought = <bool>[];
  final store = <int>[];
  await tester.pumpWidget(ThemeScope(
    manager: ThemeManager(),
    child: MaterialApp(
      builder: (_, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: ElevatedButton(
            onPressed: () async => bought.add(await showPlayLimitOffer(ctx,
                session: s, onStore: () => store.add(1))),
            child: const Text('افتح'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('افتح'));
  await tester.pumpAndSettle();
  return (bought: bought, store: store);
}

void main() {
  testWidgets('تبيع رغبةً لا ترفع عقوبة — العنوانُ عرضٌ لا نعي', (tester) async {
    final s = await _session(_client());
    await _open(tester, s);

    expect(find.text('افتح يومًا كاملًا'), findsOneWidget);
    expect(find.textContaining('فعّل الآن'), findsOneWidget);
    expect(find.text('50'), findsOneWidget, reason: 'ثمنُ الخادم لا رقمٌ مكتوب');
  });

  // **لا تُحاصِره**: المحاصَرُ بلا مخرجٍ يحذف التطبيق ولا يشتري.
  testWidgets('تقول إنّ الأوفلاين حرٌّ ومتى تعود لعباتُه', (tester) async {
    final s = await _session(_client());
    await _open(tester, s);

    expect(find.textContaining('الذكاء يبقى مجّانيًّا بلا حدود'), findsOneWidget);
    expect(find.text('لاحقًا'), findsOneWidget, reason: 'له أن يرفض بلا حصار');
  });

  testWidgets('تفعيلٌ ناجح ⇒ تُغلَق بـtrue والعدّادُ بلا حدود', (tester) async {
    final s = await _session(_client());
    final r = await _open(tester, s);

    await tester.tap(find.textContaining('فعّل الآن'));
    await tester.pumpAndSettle();

    expect(r.bought, [true], reason: 'يمضي إلى اللعب فورًا لا إلى نقطة الصفر');
    expect(s.diamonds, 50);
  });

  // **زرٌّ يقود إلى مكان الدفع** (نصُّ المالك).
  testWidgets('ماسٌ لا يكفي ⇒ تفتح المتجرَ لا تقف حائطًا', (tester) async {
    final s = await _session(_client(buyStatus: 402));
    final r = await _open(tester, s);

    await tester.tap(find.textContaining('فعّل الآن'));
    await tester.pumpAndSettle();

    expect(r.store, [1], reason: 'قادته إلى الدفع');
    expect(r.bought, [false]);
  });

  testWidgets('«لاحقًا» ⇒ تُغلَق بـfalse بلا شراء', (tester) async {
    final s = await _session(_client());
    final r = await _open(tester, s);

    await tester.tap(find.text('لاحقًا'));
    await tester.pumpAndSettle();

    expect(r.bought, [false]);
    expect(s.diamonds, 100, reason: 'لم يُمَسّ رصيدُه — رفضَ فلم يُخصَم');
  });

  // **لا ثمنَ مخترَع**: تعذّر جلبُ السلّم ⇒ خبرٌ صادقٌ بلا زرِّ شراء.
  testWidgets('تعذّر جلبُ التذاكر ⇒ خبرٌ بلا زرٍّ يكذب', (tester) async {
    final s = await _session(_client(ticketsFail: true));
    await _open(tester, s);

    expect(find.textContaining('فعّل الآن'), findsNothing);
    expect(find.textContaining('انتهت لعباتُك اليوم'), findsOneWidget);
    expect(find.text('لاحقًا'), findsOneWidget);
  });

  // **أوّلُ نفادٍ في العمر ⇒ هديّةٌ لا فاتورة**: يذوق «بلا حدود» مرّةً فيعرف في
  // الثانية *ما* يشتري — لا يشتري وصفًا.
  group('التجربةُ المجّانيّة (أوّلُ نفاد)', () {
    testWidgets('يُعرَض عليه يومٌ هديّةً لا بثمن', (tester) async {
      final s = await _session(_client(trial: true));
      await _open(tester, s);

      expect(find.text('هديّةٌ منّا: يومٌ كامل'), findsOneWidget);
      expect(find.text('استلم الهديّة'), findsOneWidget);
      expect(find.textContaining('فعّل الآن'), findsNothing,
          reason: 'لا فاتورةَ لمن نُهديه');
      expect(find.text('50'), findsNothing, reason: 'ولا ثمنَ يُعرَض');
    });

    testWidgets('استلامٌ ناجح ⇒ بلا حدودٍ ورصيدُه لم يُمَسّ', (tester) async {
      final s = await _session(_client(trial: true));
      final r = await _open(tester, s);

      await tester.tap(find.text('استلم الهديّة'));
      await tester.pumpAndSettle();

      expect(r.bought, [true], reason: 'يمضي إلى اللعب فورًا');
      expect(s.allowance!.unlimited, isTrue);
      expect(s.allowance!.trialAvailable, isFalse, reason: 'نالها ⇒ لا تُعرَض ثانيةً');
      expect(s.diamonds, 100, reason: 'هديّةٌ لا شراء');
    });

    testWidgets('نالها من قبل ⇒ يُعرَض الشراءُ لا الهديّة', (tester) async {
      final s = await _session(_client(trial: false));
      await _open(tester, s);

      expect(find.text('استلم الهديّة'), findsNothing);
      expect(find.textContaining('فعّل الآن'), findsOneWidget);
    });

    // **الهديّةُ لا تنتظر السلّم**: بلا ثمنٍ فلا حاجةَ إلى `/store/tickets`.
    testWidgets('تعذّر جلبُ السلّم ⇒ الهديّةُ تُعرَض رغم ذلك', (tester) async {
      final s = await _session(_client(trial: true, ticketsFail: true));
      await _open(tester, s);
      expect(find.text('استلم الهديّة'), findsOneWidget);
    });
  });
}
