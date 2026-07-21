import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/net/api_client.dart';
import 'package:app/net/table_client.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/online_game_page.dart';
import 'package:app/voice/voice_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// اللوبي يجلب الأصدقاء عند فتحه — عميلٌ وهميٌّ كي لا يلمس الاختبار شبكة.
ApiClient _api() => ApiClient(
      httpClient: MockClient(
        (_) async => http.Response('{"friends":[],"incoming":[],"outgoing":[]}',
            200,
            headers: {'content-type': 'application/json; charset=utf-8'}),
      ),
    );

/// **ما يراه اللاعب** حين تفشل دعوةٌ أو هديّة — الشقّ المرئيّ من إصلاح
/// `online_game_controller` (اختبارات الحالة هناك).
///
/// بلاغ المالك (2026-07-15): دعا صديقًا خارج التطبيق فرأى شاشةً كاملةً تقول **«حدث
/// خطأ غير متوقّع»** وخرج من طاولته. الصواب: شريطٌ يقول الحقيقة («صديقك غير متّصل»)
/// **واللوبي تحته باقٍ**. الاختبار يفحص الاثنين: النصَّ الصادق، وبقاءَ الطاولة.
void main() {
  late StreamController<String> incoming;

  OnlineGameController controller() {
    incoming = StreamController<String>.broadcast();
    return OnlineGameController(
      LiveTableClient(incoming: incoming.stream, send: (_) {}),
    );
  }

  void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));

  Widget page(OnlineGameController c) => ThemeScope(
        manager: ThemeManager(),
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: OnlineGamePage(
              session: const AuthSession(
                token: 't',
                player: AccountPlayer(
                  id: 'p1',
                  phone: '+22200000000',
                  displayName: 'محمد',
                  countryCode: 'MR',
                  city: 'نواكشوط',
                ),
                isNew: false,
              ),
              controllerFactory: () => c,
              apiForFriends: _api(),
              voiceFactory: () => VoiceController(api: _api(), authToken: 't'),
            ),
          ),
        ),
      );

  const lobby = {
    'phase': 'lobby',
    'tableId': 't1',
    'code': 'ABCD',
    'you': 0,
    'seats': [
      {'seat': 0, 'ai': false, 'playerId': 'p1', 'connected': true},
    ],
  };

  testWidgets('دعوةٌ لغائب ⇒ الشريط يقول لماذا، واللوبي تحته باقٍ', (t) async {
    final c = controller();
    await t.pumpWidget(page(c));
    feed(lobby);
    await t.pump();
    await t.pump();
    expect(find.text('طاولة خاصّة'), findsOneWidget, reason: 'تمهيد: نحن في اللوبي');

    feed({'error': 'invite_offline'});
    await t.pump();
    await t.pump();

    expect(find.textContaining('غير متّصل'), findsOneWidget);
    expect(find.text('حدث خطأ غير متوقّع.'), findsNothing,
        reason: 'الرسالة التي رآها المالك — لا تعود');
    expect(find.text('طاولة خاصّة'), findsOneWidget,
        reason: '**اللوبي باقٍ تحت الشريط** — هذا جوهر الإصلاح');

    await t.pumpAndSettle(const Duration(seconds: 6));
  });

  testWidgets('خطأٌ قاتل ⇒ الشاشة الكاملة تبقى كما كانت', (t) async {
    final c = controller();
    await t.pumpWidget(page(c));
    feed(lobby);
    await t.pump();
    await t.pump();

    feed({'error': 'server_full'});
    await t.pump();
    await t.pump();

    expect(find.textContaining('الخوادم ممتلئة'), findsOneWidget);
    expect(find.text('طاولة خاصّة'), findsNothing,
        reason: 'لا طاولةَ بعد هذا الخطأ ⇒ إخفاؤها صادق');
  });
}
