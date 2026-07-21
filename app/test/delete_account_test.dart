import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// **الخروج وحذف الحساب** — إلزامُ المتاجر (#11).
///
/// جوهرُ ما يُفحَص: أنّ الزرّين **موجودان** (بلا حذفٍ يُرفض التطبيق)، وأنّ الحذف
/// **لا يمرّ بنقرة** — فعلٌ لا رجعة فيه، ونقرةٌ واحدةٌ ليست تأكيدًا.

/// مخزنُ جلسةٍ في الذاكرة (لا `shared_preferences` في الاختبار).
class _MemStore implements SessionStore {
  AuthSession? _s;
  _MemStore(this._s);
  @override
  Future<AuthSession?> load() async => _s;
  @override
  Future<void> save(AuthSession s) async => _s = s;
  @override
  Future<void> clear() async => _s = null;
}

const _me = AccountPlayer(
  id: 'ME',
  tag: 'JP8TNF',
  phone: '+22211111111',
  displayName: 'محمد',
  countryCode: 'MR',
  city: 'نواكشوط',
);

({Widget widget, SessionController session, List<String> calls}) _harness() {
  final calls = <String>[];
  final client = MockClient((req) async {
    final last = req.url.path.split('/').last;
    calls.add('${req.method} $last');
    // ردٌّ لكلّ مسارٍ بشكله: `{'ok':true}` للجميع يكسر تحويلَ المحفظة/الإحصاء.
    final body = switch (last) {
      'wallet' => {'diamonds': 1000},
      'stats' => {
          'rating': 1000,
          'matches': 4,
          'wins': 2,
          'losses': 2,
          'winStreak': 0,
          'bestStreak': 1,
          'winRate': 50,
        },
      _ => {'ok': true},
    };
    return http.Response(jsonEncode(body), 200,
        headers: {'content-type': 'application/json'});
  });
  final s = SessionController(
    api: ApiClient(httpClient: client),
    store: _MemStore(const AuthSession(token: 'tok', player: _me, isNew: false)),
  );
  return (
    widget: ThemeScope(
      manager: ThemeManager(),
      child: SessionScope(
        controller: s,
        child: MaterialApp(home: ProfileScreen(onSignIn: () {})),
      ),
    ),
    session: s,
    calls: calls,
  );
}

Future<void> _signedIn(WidgetTester t,
    ({Widget widget, SessionController session, List<String> calls}) h) async {
  await h.session.loadSaved();
  await t.pumpWidget(h.widget);
  await t.pumpAndSettle();
  // الأزرار أسفل `ListView` و القائمة تبني الظاهر وحده ⇒ مرِّرْ إليها.
  await t.scrollUntilVisible(find.text('حذف الحساب نهائيًّا'), 300,
      scrollable: find.byType(Scrollable).first); // أكثرُ من قابلِ تمرير في الشجرة
  await t.pumpAndSettle();
}

void main() {
  testWidgets('**الزرّان موجودان** — بلا حذفٍ يُرفض التطبيق في المتاجر', (t) async {
    final h = _harness();
    await _signedIn(t, h);
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    expect(find.text('حذف الحساب نهائيًّا'), findsOneWidget);
  });

  testWidgets('الخروج يُستأذَن فيه، والتراجع لا يُخرج', (t) async {
    final h = _harness();
    await _signedIn(t, h);
    expect(h.session.isSignedIn, isTrue);

    await t.tap(find.text('تسجيل الخروج'));
    await t.pumpAndSettle();
    await t.tap(find.text('تراجع'));
    await t.pumpAndSettle();
    expect(h.session.isSignedIn, isTrue, reason: 'التراجع لا يفعل شيئًا');

    await t.tap(find.text('تسجيل الخروج'));
    await t.pumpAndSettle();
    await t.tap(find.text('اخرج'));
    await t.pumpAndSettle();
    expect(h.session.isSignedIn, isFalse);
    expect(h.calls, isNot(contains('DELETE me')), reason: 'الخروج ليس حذفًا');
  });

  group('الحذف', () {
    testWidgets('**لا يمرّ بنقرة**: الزرّ معطّلٌ حتى يُكتَب الرمز', (t) async {
      final h = _harness();
      await _signedIn(t, h);

      await t.tap(find.text('حذف الحساب نهائيًّا'));
      await t.pumpAndSettle();

      // النافذة تسرد ما يُفقَد.
      expect(find.textContaining('لا رجعة'), findsOneWidget);
      expect(find.textContaining('اكتب رمزك'), findsOneWidget);

      // نقرٌ بلا كتابةٍ ⇒ لا شيء.
      await t.tap(find.text('احذف حسابي'));
      await t.pumpAndSettle();
      expect(h.calls, isNot(contains('DELETE me')));
      expect(h.session.isSignedIn, isTrue);
    });

    testWidgets('رمزٌ خاطئ ⇒ يبقى معطّلًا', (t) async {
      final h = _harness();
      await _signedIn(t, h);
      await t.tap(find.text('حذف الحساب نهائيًّا'));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), 'ZZZZZZ');
      await t.pumpAndSettle();
      await t.tap(find.text('احذف حسابي'));
      await t.pumpAndSettle();
      expect(h.calls, isNot(contains('DELETE me')));
    });

    testWidgets('الرمز الصحيح ⇒ يُحذف ويُسجَّل الخروج (لا جلسةَ تبقى)', (t) async {
      final h = _harness();
      await _signedIn(t, h);
      await t.tap(find.text('حذف الحساب نهائيًّا'));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), 'JP8TNF');
      await t.pumpAndSettle();
      await t.tap(find.text('احذف حسابي'));
      await t.pumpAndSettle();

      expect(h.calls, contains('DELETE me'));
      expect(h.session.isSignedIn, isFalse, reason: 'الحساب زال ⇒ لا جلسةَ على الجهاز');
    });

    testWidgets('الرمز يُطبَّع: حرفٌ صغيرٌ و# يُقبلان (نُسخ من الشاشة نفسها)', (t) async {
      final h = _harness();
      await _signedIn(t, h);
      await t.tap(find.text('حذف الحساب نهائيًّا'));
      await t.pumpAndSettle();

      await t.enterText(find.byType(TextField), ' #jp8tnf ');
      await t.pumpAndSettle();
      await t.tap(find.text('احذف حسابي'));
      await t.pumpAndSettle();
      expect(h.calls, contains('DELETE me'));
    });

    testWidgets('التراجع لا يحذف', (t) async {
      final h = _harness();
      await _signedIn(t, h);
      await t.tap(find.text('حذف الحساب نهائيًّا'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'JP8TNF');
      await t.pumpAndSettle();
      await t.tap(find.text('تراجع'));
      await t.pumpAndSettle();

      expect(h.calls, isNot(contains('DELETE me')));
      expect(h.session.isSignedIn, isTrue);
    });
  });
}
