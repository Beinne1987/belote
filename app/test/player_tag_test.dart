import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/player_tag_chip.dart';
import 'package:app/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _config = ApiConfig.fromOrigin('http://test.local');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

Widget _wrapChip(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );

Widget _wrapProfile(SessionController c) => ThemeScope(
      manager: ThemeManager(),
      child: SessionScope(
        controller: c,
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProfileScreen(),
          ),
        ),
      ),
    );

SessionController _controller(MockClient m) => SessionController(
    api: ApiClient(config: _config, httpClient: m), store: SessionStore());

AuthSession _sess({String tag = 'K7M2XP'}) => AuthSession(
      token: 'tok',
      player: AccountPlayer(
        id: 'a1b2c3d4e5f60718293a4b5c6d7e8f90', // معرّفٌ داخليّ 128-بت
        tag: tag,
        phone: '+22200000000',
        displayName: 'محمد',
        countryCode: 'MR',
        city: 'نواكشوط',
      ),
      isNew: false,
    );

/// يلتقط ما كُتِب إلى الحافظة (لا حافظة حقيقيّة في الاختبار).
List<String> _spyClipboard(WidgetTester tester) {
  final copied = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        copied.add((call.arguments as Map)['text'] as String);
      }
      return null;
    },
  );
  return copied;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('النموذج', () {
    test('الرمز يُقرأ من JSON الخادم', () {
      final p = AccountPlayer.fromJson({'id': 'x', 'tag': 'K7M2XP', 'phone': '1'});
      expect(p.tag, 'K7M2XP');
    });

    test('خادمٌ قديم بلا حقل tag ⇒ رمزٌ فارغ لا انهيار', () {
      final p = AccountPlayer.fromJson({'id': 'x', 'phone': '1'});
      expect(p.tag, '');
    });

    test('الرمز يبقى عبر التحويل ذهابًا وإيابًا (يُحفَظ في الجلسة)', () {
      final p = AccountPlayer.fromJson(_sess().player.toJson());
      expect(p.tag, 'K7M2XP');
    });
  });

  group('الشارة', () {
    testWidgets('تعرض الرمز بمُبادِئة #', (tester) async {
      await tester.pumpWidget(_wrapChip(const PlayerTagChip(tag: 'K7M2XP')));
      expect(find.text('#K7M2XP'), findsOneWidget);
    });

    testWidgets('اللمس ينسخ المعروض ويُظهر تأكيدًا ثمّ يعود', (tester) async {
      final copied = _spyClipboard(tester);
      await tester.pumpWidget(_wrapChip(const PlayerTagChip(tag: 'K7M2XP')));

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      await tester.tap(find.byType(PlayerTagChip));
      await tester.pump();

      expect(copied, ['#K7M2XP'], reason: 'ما يُنسَخ = ما يُرى');
      expect(find.byIcon(Icons.check), findsOneWidget, reason: 'تأكيدٌ في مكان اللمس');

      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget, reason: 'يعود بعد التأكيد');
    });

    testWidgets('نصُّ النسخ قابلٌ للتجاوز', (tester) async {
      final copied = _spyClipboard(tester);
      await tester
          .pumpWidget(_wrapChip(const PlayerTagChip(tag: 'K7M2XP', copyText: 'K7M2XP')));
      await tester.tap(find.byType(PlayerTagChip));
      await tester.pump();
      expect(copied, ['K7M2XP']);
      await tester.pump(const Duration(milliseconds: 1500)); // استنفِد مؤقّت التأكيد
    });

    testWidgets('الرمز لاتينيّ معزول الاتّجاه داخل واجهةٍ عربيّة', (tester) async {
      await tester.pumpWidget(_wrapChip(const PlayerTagChip(tag: 'K7M2XP')));
      final text = tester.widget<Text>(find.text('#K7M2XP'));
      expect(text.textDirection, TextDirection.ltr);
    });
  });

  group('الملف الشخصيّ', () {
    testWidgets('مصادَق ⇒ الرمز ظاهرٌ قابلٌ للنسخ (لا المعرّف الداخليّ)', (tester) async {
      final c = _controller(MockClient((req) async {
        if (req.url.path == '/me/wallet') return _json({'diamonds': 0});
        return _json({
          'rating': 1350, 'matches': 12, 'wins': 7, 'losses': 5,
          'winStreak': 1, 'bestStreak': 3, 'winRate': 58,
        });
      }));
      await c.signIn(_sess());
      await tester.pumpWidget(_wrapProfile(c));
      await tester.pumpAndSettle();

      expect(find.text('#K7M2XP'), findsOneWidget);
      expect(find.textContaining('a1b2c3d4'), findsNothing,
          reason: 'المعرّف الداخليّ لا يُعرَض البتّة');
    });

    testWidgets('خادمٌ قديم (رمزٌ فارغ) ⇒ لا شارة ولا خانةٌ فارغة', (tester) async {
      final c = _controller(MockClient((req) async {
        if (req.url.path == '/me/wallet') return _json({'diamonds': 0});
        return _json({
          'rating': 1000, 'matches': 0, 'wins': 0, 'losses': 0,
          'winStreak': 0, 'bestStreak': 0, 'winRate': 0,
        });
      }));
      await c.signIn(_sess(tag: ''));
      await tester.pumpWidget(_wrapProfile(c));
      await tester.pumpAndSettle();

      expect(find.byType(PlayerTagChip), findsNothing);
      expect(find.text('محمد'), findsOneWidget, reason: 'بقيّة الملفّ سليمة');
    });
  });
}
