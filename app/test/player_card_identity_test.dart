import 'dart:convert';

import 'package:app/app_settings.dart';
import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/home_screen.dart';
import 'package:app/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **هويّةُ اللاعب وعملتُه في بطاقته** — ثلاثةُ بلاغاتٍ من المالك (2026-07-15):
/// 1. البطاقة تعرض **رمزًا غيرَ** الذي يظهر عند فتحها (`id` داخليّ ≠ `tag`).
/// 2. تعرض **عملتين**، والماسُ وحده عملةُ التطبيق.
/// 3. الماسُ **يختفي** عند فتح البطاقة.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

/// معرّفٌ داخليٌّ ورمزٌ معروض **مختلفان عمدًا**: لو تشابها لمرّ العطبُ الأصليّ
/// (عرضُ أوّل ٦ خاناتٍ من `id`) بلا أن يمسكه أحد.
const _internalId = '4eecfef7f73380236064733357cc582b';
const _tag = 'ABC123';

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _player({String tag = _tag}) => {
      'id': _internalId,
      'tag': tag,
      'phone': '+22200000000',
      'displayName': 'محمّد',
      'countryCode': 'MR',
      'city': 'نواكشوط',
    };

AuthSession _sess({String tag = _tag}) => AuthSession(
    token: 'TOK', player: AccountPlayer.fromJson(_player(tag: tag)), isNew: false);

/// [roses] مخزونُ وردٍ في المحفظة. المحفظةُ **ليست الماسَ وحده**: مخزونُ الهدايا
/// أرصدةٌ فيها بعملاتِ `gift:<id>` ⇒ البطاقةُ يجب أن تنتقي الماسَ لا أن تعرض ما تجد.
MockClient _client({int roses = 3, int diamonds = 25, String tag = _tag}) =>
    MockClient((req) async {
      final p = req.url.path;
      if (p.endsWith('/me/wallet')) {
        return _json({'diamonds': diamonds, 'gift:rose': roses});
      }
      if (p.endsWith('/me/stats')) {
        return _json({'rating': 1200, 'matches': 8, 'wins': 5});
      }
      if (p.contains('notifications')) return _json({'unread': 0});
      return _json(_player(tag: tag));
    });

Future<SessionController> _session(MockClient client, {String tag = _tag}) async {
  final s = SessionController(
      api: ApiClient(config: _config, httpClient: client), store: SessionStore());
  await s.signIn(_sess(tag: tag));
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

/// نصٌّ **داخل شارة الماس** وحدها — لا في الشاشة كلّها.
Finder _inDiamondChip(String text) => find.descendant(
      of: find.ancestor(
          of: find.byIcon(Icons.diamond), matching: find.byType(Row)).first,
      matching: find.text(text),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('الرمز', () {
    // **البلاغ الأوّل**: رمزان لشخصٍ واحد.
    testWidgets('بطاقةُ اللوبي تعرض رمزَ اللاعب لا معرّفَه الداخليّ', (tester) async {
      await _pump(tester, await _session(_client()), HomeScreen(onPlay: () {}));

      expect(find.text('#$_tag'), findsOneWidget);
      expect(find.text('#4EECFE'), findsNothing,
          reason: 'أوّلُ ٦ خاناتٍ من id — الرمزُ المخترَع الذي كان يُعرَض');
    });

    testWidgets('الرمز نفسُه في اللوبي وفي الملفّ — لا رمزان', (tester) async {
      final session = await _session(_client());

      await _pump(tester, session, HomeScreen(onPlay: () {}));
      final inLobby = tester.widget<Text>(find.text('#$_tag')).data;

      await _pump(tester, session, const ProfileScreen());
      // `PlayerTagChip` يعرضه بنفس الصيغة `#ABC123`.
      expect(find.textContaining(_tag), findsWidgets);
      expect(inLobby, '#$_tag');
    });

    testWidgets('خادمٌ أقدمُ بلا رمز ⇒ لا شيء، لا رمزٌ مخترَع', (tester) async {
      await _pump(tester, await _session(_client(tag: ''), tag: ''),
          HomeScreen(onPlay: () {}));

      expect(find.textContaining('#'), findsNothing);
      expect(find.text('#4EECFE'), findsNothing);
    });
  });

  group('العملة', () {
    // **البلاغ الثاني**: عملتان. أُلغيت الرقائق، لكنّ الحارسَ باقٍ ومعناه أحدُّ: صارت
    // المحفظةُ تحمل مخزونَ الهدايا أيضًا، فلو عرضت البطاقةُ ما تجد لظهر الوردُ عملةً.
    testWidgets('بطاقةُ اللوبي تعرض الماسَ وحده — لا مخزونًا ولا عملةً ثانية',
        (tester) async {
      await _pump(tester, await _session(_client(roses: 7, diamonds: 25)),
          HomeScreen(onPlay: () {}));

      expect(find.byIcon(Icons.diamond), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsNothing,
          reason: 'الماسُ عملةُ التطبيق الوحيدة');
      expect(find.text('7'), findsNothing, reason: 'المخزونُ ليس عملةً على البطاقة');
    });

    // **البلاغ الثالث**: الماس يختفي عند فتح البطاقة.
    testWidgets('الملفّ يعرض رصيد الماس', (tester) async {
      await _pump(tester, await _session(_client(diamonds: 25)), const ProfileScreen());

      // موضعان قصدًا بعد إضافة «محفظتي»: شارةُ الترويسة وسطرُ المحفظة. الحارسُ
      // يفحص **الشارةَ** بعينها (`_inDiamondChip`) — وهي ما اشتكى المالك اختفاءَه.
      expect(find.byIcon(Icons.diamond), findsNWidgets(2));
      expect(_inDiamondChip('25'), findsOneWidget);
    });

    testWidgets('رصيدٌ صفر ⇒ يُعرَض 0 لا فراغ', (tester) async {
      await _pump(tester, await _session(_client(diamonds: 0)), const ProfileScreen());

      // **مقيَّدٌ بداخل الشارة**: الشاشة مليئةٌ بأصفار الإحصاء — بحثٌ عامٌّ عن «0»
      // يمرّ بها فيُصدّق نفسَه وهو يفحص شيئًا آخر.
      expect(_inDiamondChip('0'), findsOneWidget,
          reason: 'رصيدٌ معروفٌ وصفر ≠ رصيدٌ مجهول');
    });
  });
}
