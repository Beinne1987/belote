import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/missions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **شاشة المهامّ.** الجوهر: **كلُّ قرارٍ من الخادم** — التقدّمُ والجائزةُ ومتى
/// تُقبَض. حسابٌ ثانٍ هنا يجعل الزرَّ يُضيء لِما يرفضه الخادمُ فيخيب اللاعب.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o, [int status = 200]) =>
    http.Response(jsonEncode(o), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _player() => {
      'id': 'p1',
      'tag': 'ABC123',
      'phone': '+22200000000',
      'displayName': 'محمّد',
      'countryCode': 'MR',
      'city': 'نواكشوط',
    };

Map<String, dynamic> _m(
  String id, {
  String period = 'daily',
  int target = 3,
  int progress = 0,
  int xp = 30,
  int diamonds = 2,
  bool claimed = false,
  bool claimable = false,
}) =>
    {
      'id': id,
      'period': period,
      'target': target,
      'progress': progress,
      'xp': xp,
      'diamonds': diamonds,
      'claimed': claimed,
      'claimable': claimable,
    };

MockClient _client({
  List<Map<String, dynamic>>? missions,
  int missionsStatus = 200,
  int claimStatus = 200,
}) =>
    MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/me/missions')) {
        if (missionsStatus != 200) {
          return _json({'error': 'missions_disabled'}, missionsStatus);
        }
        return _json({'missions': missions ?? [_m('daily_play')]});
      }
      if (p.endsWith('/me/missions/claim')) {
        if (claimStatus != 200) {
          return _json({'error': 'mission_already'}, claimStatus);
        }
        return _json({
          'mission': _m('daily_win', claimed: true),
          'wallet': {'diamonds': 7},
          'stats': {'rating': 1000, 'matches': 1, 'wins': 1, 'xp': 40, 'level': 1},
        });
      }
      if (p.endsWith('/me/wallet')) return _json({'diamonds': 5});
      if (p.endsWith('/me/stats')) {
        return _json({'rating': 1000, 'matches': 0, 'wins': 0, 'xp': 20, 'level': 1});
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

Future<void> _pump(WidgetTester tester, SessionController s) async {
  await tester.pumpWidget(ThemeScope(
    manager: ThemeManager(),
    child: SessionScope(
      controller: s,
      child: MaterialApp(
        builder: (_, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: MissionsScreen(session: s),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('تعرض اليوميّةَ والأسبوعيّةَ مفصولتين', (tester) async {
    final s = await _session(_client(missions: [
      _m('daily_play'),
      _m('weekly_play', period: 'weekly', target: 20),
    ]));
    await _pump(tester, s);

    expect(find.text('يوميّة'), findsOneWidget);
    expect(find.text('أسبوعيّة'), findsOneWidget);
    // التصفيرُ مشروحٌ: لاعبٌ لا يعرف متى تُصفَّر لا يعود غدًا.
    expect(find.text('تُصفَّر كلَّ يوم'), findsOneWidget);
    expect(find.text('تُصفَّر كلَّ اثنين'), findsOneWidget);
  });

  testWidgets('الجائزةُ ظاهرةٌ قبل الإنجاز — مهمّةٌ بلا ثمنٍ لا تُحفّز',
      (tester) async {
    final s = await _session(_client(missions: [_m('daily_play', xp: 30, diamonds: 2)]));
    await _pump(tester, s);

    expect(find.text('30'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget, reason: 'تقدّمُه أمامه');
  });

  group('الزرُّ يتبع الخادم', () {
    testWidgets('claimable ⇒ زرُّ القبض', (tester) async {
      final s = await _session(
          _client(missions: [_m('daily_win', progress: 1, target: 1, claimable: true)]));
      await _pump(tester, s);
      expect(find.text('اقبض'), findsOneWidget);
    });

    // **الجوهر**: لا نحسب `progress >= target` هنا. لو فعلنا لأضاء الزرُّ لِما
    // يرفضه الخادمُ (فترةٌ انقضت · قُبضت في جهازٍ آخر) فيلمسه اللاعبُ ويخيب.
    testWidgets('مكتملةٌ والخادمُ يقول لا ⇒ لا زرّ', (tester) async {
      final s = await _session(_client(missions: [
        _m('daily_play', progress: 3, target: 3, claimable: false)
      ]));
      await _pump(tester, s);

      expect(find.text('اقبض'), findsNothing,
          reason: 'الخادمُ وحدَه يقرّر — ولو بدت مكتملة');
    });

    testWidgets('مقبوضةٌ ⇒ علامةٌ لا زرّ', (tester) async {
      final s = await _session(_client(
          missions: [_m('daily_win', progress: 1, target: 1, claimed: true)]));
      await _pump(tester, s);

      expect(find.text('اقبض'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    // غيرُ مكتملةٍ ⇒ لا زرَّ يُلمَس فلا يحدث شيء (نظيرُ درس زرّ الهديّة).
    testWidgets('غيرُ مكتملةٍ ⇒ لا زرّ', (tester) async {
      final s = await _session(_client(missions: [_m('daily_play', progress: 1)]));
      await _pump(tester, s);
      expect(find.text('اقبض'), findsNothing);
    });
  });

  testWidgets('قبضٌ ناجح ⇒ المحفظةُ والخبرةُ من الردّ نفسِه', (tester) async {
    final s = await _session(
        _client(missions: [_m('daily_win', progress: 1, target: 1, claimable: true)]));
    await _pump(tester, s);

    await tester.tap(find.text('اقبض'));
    await tester.pumpAndSettle();

    expect(s.diamonds, 7, reason: 'من ردّ القبض لا بنداءٍ ثانٍ');
    expect(s.stats!.xp, 40, reason: 'المهمّةُ تمنح الاثنين معًا');
  });

  testWidgets('409 ⇒ يُعيد الجلبَ ولا يلوم اللاعب', (tester) async {
    final s = await _session(_client(
      missions: [_m('daily_win', progress: 1, target: 1, claimable: true)],
      claimStatus: 409,
    ));
    await _pump(tester, s);

    await tester.tap(find.text('اقبض'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // الشاشةُ متأخّرةٌ عن الحقيقة (قُبضت في جهازٍ آخر) ⇒ خبرٌ لا اتّهام.
    expect(find.textContaining('تغيّرت حالةُ المهمّة'), findsOneWidget);
  });

  testWidgets('المهامُّ مُطفأةٌ خادميًّا (503) ⇒ تُشرَح لا تنهار', (tester) async {
    final s = await _session(_client(missionsStatus: 503));
    await _pump(tester, s);

    expect(find.text('المهامّ غير متاحةٍ الآن.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('معرّفٌ لا نعرفه يُسقَط لا يُعرَض خامًا', (tester) async {
    final s = await _session(_client(missions: [
      _m('daily_play'),
      _m('daily_dance', claimable: true), // خادمٌ أحدثُ من الحزمة
    ]));
    await _pump(tester, s);

    expect(find.text('العب ثلاث مباريات'), findsOneWidget);
    expect(find.textContaining('daily_dance'), findsNothing);
    expect(find.text('اقبض'), findsNothing, reason: 'لا زرَّ لمهمّةٍ لا نعرفها');
  });
}
