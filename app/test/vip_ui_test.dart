import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/vip_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **شاشةُ VIP** — «اعرض ما نقدّمه في شاشة الاشتراك: الإطار والغرفة وكلّ شيء
/// للتحفيز على الاشتراك» (نصُّ المالك).
///
/// الجوهرُ المفحوص: **تُري ولا تصف** (صورُ الإطار والغرفة والهدايا حاضرة)، وكلُّ
/// رقمٍ من الخادم، والمشتركُ لا يُباع له ما يملك.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

MockClient _client({bool active = false, int subStatus = 200, int diamonds = 3000}) =>
    MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/store/vip')) {
        return _json({
          'plans': [
            {'id': 'month', 'price': 500, 'days': 30, 'monthlyDiamonds': 50},
            {'id': 'year', 'price': 2200, 'days': 365, 'monthlyDiamonds': 50},
          ]
        });
      }
      if (p.endsWith('/me/vip/subscribe')) {
        if (subStatus != 200) {
          return http.Response(jsonEncode({'error': 'vip_insufficient'}), subStatus,
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return _json({
          'until': DateTime.utc(2026, 8, 15).toIso8601String(),
          'wallet': {'diamonds': diamonds - 500 + 50},
        });
      }
      if (p.endsWith('/me/vip')) {
        return _json({
          'active': active,
          if (active) 'until': DateTime.utc(2026, 9, 1).toIso8601String(),
          'granted': 0,
          'monthlyDiamonds': 50,
          'wallet': {'diamonds': diamonds},
        });
      }
      return _json({'diamonds': diamonds});
    });

Future<SessionController> _session(MockClient c) async {
  SharedPreferences.setMockInitialValues({});
  final s = SessionController(
      api: ApiClient(config: _config, httpClient: c), store: SessionStore());
  await s.signIn(AuthSession(
      token: 'TOK',
      player: AccountPlayer.fromJson(
          {'id': 'p1', 'tag': 'ABC123', 'phone': '+2221', 'displayName': 'أحمد'}),
      isNew: false));
  return s;
}

Future<void> _pump(WidgetTester t, SessionController s) async {
  await t.pumpWidget(ThemeScope(
    manager: ThemeManager(),
    child: SessionScope(
      controller: s,
      child: MaterialApp(
        builder: (_, c) =>
            Directionality(textDirection: TextDirection.rtl, child: c!),
        home: VipScreen(session: s),
      ),
    ),
  ));
  await t.pumpAndSettle();
}

void main() {
  // **تُري ولا تصف**: المزيّةُ الموصوفةُ بالكلام لا تُشترى.
  testWidgets('تعرض الإطارَ والغرفةَ والهدايا صورًا لا أسماء', (tester) async {
    final s = await _session(_client());
    await _pump(tester, s);

    final imgs = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => (i.image as AssetImage).assetName)
        .toList();
    expect(imgs, contains('assets/VIP/player_frame_vip.png'));
    expect(imgs, contains('assets/VIP/VIP_room.png'));
    expect(imgs, contains('assets/VIP/gift_flower.png'));
    expect(imgs, contains('assets/VIP/gift_box.png'));
    expect(imgs, contains('assets/VIP/gift_pitcher.png'));
  });

  testWidgets('كلُّ رقمٍ من الخادم — 500 و2200 و50 ماسة', (tester) async {
    final s = await _session(_client());
    await _pump(tester, s);
    await tester.scrollUntilVisible(find.text('اختر اشتراكك'), 300);

    expect(find.text('500'), findsOneWidget);
    expect(find.text('2200'), findsOneWidget);
    expect(find.text('50 ماسةً كلَّ شهر'), findsOneWidget);
  });

  // «أوفر» بلا رقمٍ دعوى: 2200 مقابل 6000 ⇒ 63%.
  testWidgets('السنةُ تقول كم توفّر بالرقم', (tester) async {
    final s = await _session(_client());
    await _pump(tester, s);
    await tester.scrollUntilVisible(find.text('اختر اشتراكك'), 300);
    expect(find.text('وفّر 63% عن الشهريّ'), findsOneWidget);
  });

  testWidgets('اشتراكٌ ناجح ⇒ يصير VIP والعدّادُ بلا حدود', (tester) async {
    final s = await _session(_client());
    await _pump(tester, s);
    await tester.scrollUntilVisible(find.text('اختر اشتراكك'), 300);

    await tester.tap(find.text('500'));
    await tester.pumpAndSettle();

    expect(s.isVip, isTrue);
    expect(s.diamonds, 2550, reason: '3000 − 500 + 50 دفعتُه الأولى');
  });

  testWidgets('ماسٌ لا يكفي ⇒ يشرح ولا يمسّ رصيدَه', (tester) async {
    final s = await _session(_client(subStatus: 402, diamonds: 100));
    await _pump(tester, s);
    await tester.scrollUntilVisible(find.text('اختر اشتراكك'), 300);

    await tester.tap(find.text('500'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('ماسك لا يكفي'), findsOneWidget);
    expect(s.isVip, isFalse);
  });

  // **المشتركُ لا يُباع له ما يملك** — بل يُقال له متى ينتهي وله أن يمدّد.
  testWidgets('مشتركٌ حيٌّ ⇒ يرى حالتَه لا عرضًا', (tester) async {
    final s = await _session(_client(active: true));
    await _pump(tester, s);

    expect(find.textContaining('أنت VIP — حتى 2026-09-01'), findsOneWidget);
    expect(find.text('مدّد اشتراكك'), findsOneWidget);
    expect(find.text('اختر اشتراكك'), findsNothing);
  });
}
