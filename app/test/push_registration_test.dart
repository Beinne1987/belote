import 'dart:async';
import 'dart:convert';

import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/services/push_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **تسجيل جهازي للإشعارات** — بلا هذا لا يعرف الخادمُ عنوانَ هاتفي، فتبقى
/// الدعوةُ حبيسةَ من التطبيقُ مفتوحٌ عنده (بلاغ المالك 2026-07-15).
///
/// `firebase_messaging` يحتاج منصّةً حيّة ⇒ [PushTokens] تُحقَن هنا. ما يبقى
/// للتحقّق الحيّ: أن يظهر الإشعار فعلًا على الشاشة.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _player() => {
      'id': 'p1',
      'tag': 'ABC123',
      'phone': '+22200000000',
      'displayName': 'محمد',
      'countryCode': 'MR',
      'city': 'نواكشوط',
    };

AuthSession _sess() => AuthSession(
      token: 'TOK',
      player: AccountPlayer.fromJson(_player()),
      isNew: false,
    );

/// يردّ على مسارات الجلسة العاديّة (محفظة/إحصاء) كي لا تُشوّش على المفحوص.
http.Response? _common(http.Request req) {
  if (req.url.path.endsWith('/me/wallet')) return _json({'diamonds': 10});
  if (req.url.path.endsWith('/me/stats')) {
    return _json({'rating': 1000, 'matches': 0, 'wins': 0});
  }
  return null;
}

class _FakePush implements PushTokens {
  final String? tokenValue;
  final _refresh = StreamController<String>.broadcast();
  int requested = 0;
  int deleted = 0;
  _FakePush([this.tokenValue = 'DEVICE-1']);

  @override
  Future<String?> requestToken() async {
    requested++;
    return tokenValue;
  }

  @override
  Stream<String> get onRefresh => _refresh.stream;

  @override
  Future<void> delete() async => deleted++;

  @override
  Stream<Map<String, String>> get onTap => const Stream.empty();

  @override
  Future<Map<String, String>?> initialTap() async => null;
}

/// ينهار كما تنهار منصّةٌ بلا Firebase.
class _BrokenPush implements PushTokens {
  @override
  Future<String?> requestToken() async => throw StateError('لا منصّة');
  @override
  Stream<String> get onRefresh => const Stream.empty();
  @override
  Future<void> delete() async => throw StateError('لا منصّة');
  @override
  Stream<Map<String, String>> get onTap => const Stream.empty();
  @override
  Future<Map<String, String>?> initialTap() async => null;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// يلتقط طلبات توكن الجهاز.
  (SessionController, List<(String, Map<String, dynamic>)>) harness(
      PushTokens push) {
    final calls = <(String, Map<String, dynamic>)>[];
    final client = MockClient((req) async {
      final common = _common(req);
      if (common != null) return common;
      if (req.url.path.contains('device-token')) {
        calls.add((req.url.path, jsonDecode(req.body) as Map<String, dynamic>));
        return _json({'ok': true});
      }
      return _json(_player());
    });
    final c = SessionController(
      api: ApiClient(config: _config, httpClient: client),
      store: SessionStore(),
      push: push,
    );
    return (c, calls);
  }

  test('الدخول ⇒ يطلب الإذن ويُسجّل التوكن بتوكن المصادقة', () async {
    final push = _FakePush();
    final (c, calls) = harness(push);

    await c.signIn(_sess());

    expect(push.requested, 1);
    expect(calls.single.$1, endsWith('/me/device-token'));
    expect(calls.single.$2['token'], 'DEVICE-1');
    expect(calls.single.$2['platform'], 'android');
  });

  // من رفض الإذن يلعب كما كان — ولا يُقال لداعيه «أُرسل إشعار».
  test('رفضُ الإذن ⇒ لا تسجيل، ولا عطب', () async {
    final push = _FakePush(null);
    final (c, calls) = harness(push);

    await c.signIn(_sess());

    expect(push.requested, 1);
    expect(calls, isEmpty);
    expect(c.isSignedIn, isTrue, reason: 'الدخول تمّ رغم رفض الإشعارات');
  });

  test('منصّةٌ بلا Firebase (رمي) ⇒ الدخول يمضي', () async {
    final (c, calls) = harness(_BrokenPush());
    await c.signIn(_sess());
    expect(c.isSignedIn, isTrue);
    expect(calls, isEmpty);
  });

  // **كلُّ إقلاعٍ يُسجّل**: التوكن يُدوَّر وقد يفقد الخادمُ صفَّه.
  test('الإقلاع بجلسةٍ محفوظة ⇒ يُسجّل من جديد', () async {
    final push = _FakePush();
    final (c, calls) = harness(push);
    await c.store.save(_sess());

    await c.loadSaved();

    expect(calls.single.$2['token'], 'DEVICE-1');
  });

  // تدويرُ Google للتوكن لا يستأذن أحدًا — بلا الإنصات تموت الإشعارات بصمت.
  test('تدوير التوكن ⇒ يُسجَّل الجديد بلا تدخّل', () async {
    final push = _FakePush();
    final (c, calls) = harness(push);
    await c.signIn(_sess());
    calls.clear();

    push._refresh.add('DEVICE-2');
    await Future<void>.delayed(Duration.zero);

    expect(calls.single.$2['token'], 'DEVICE-2');
  });

  test('تدويرٌ قبل الدخول ⇒ لا يُرسَل شيء (لا توكن مصادقة)', () async {
    final push = _FakePush();
    final (_, calls) = harness(push);

    push._refresh.add('DEVICE-2');
    await Future<void>.delayed(Duration.zero);

    expect(calls, isEmpty);
  });

  group('الخروج', () {
    // **الفخّ**: المحو مسارٌ محميّ. لو مُسحت الجلسة أوّلًا لبقي عنوانُ الجهاز في
    // القاعدة، فوصلت دعواتُ من خرج إلى من دخل بعده على نفس الهاتف.
    test('يمحو التوكن **قبل** مسح الجلسة، ويُتلفه من الجهاز', () async {
      final push = _FakePush();
      final (c, calls) = harness(push);
      await c.signIn(_sess());
      calls.clear();

      await c.signOut();

      expect(calls.single.$1, endsWith('/me/device-token/remove'));
      expect(calls.single.$2['token'], 'DEVICE-1',
          reason: 'التوكن المسجَّل بعينه — لا ما تردّه Firebase الآن');
      expect(push.deleted, 1);
      expect(c.isSignedIn, isFalse);
    });

    test('خروجٌ بلا تسجيلٍ سابق ⇒ لا نداءَ ولا عطب', () async {
      final push = _FakePush(null); // رفض الإذن ⇒ لا توكن
      final (c, calls) = harness(push);
      await c.signIn(_sess());

      await c.signOut();

      expect(calls, isEmpty);
      expect(c.isSignedIn, isFalse);
    });

    test('عطبُ المنصّة عند المحو ⇒ الخروج يتمّ', () async {
      final (c, _) = harness(_BrokenPush());
      await c.signIn(_sess());
      await c.signOut();
      expect(c.isSignedIn, isFalse);
    });
  });

  // الإشعارات رفاهيّة: خادمٌ قديمٌ (404) أو معطَّل (503) لا يكسر الدخول.
  test('خادمٌ يرفض التسجيل ⇒ الدخول سليم', () async {
    final client = MockClient((req) async {
      final common = _common(req);
      if (common != null) return common;
      if (req.url.path.contains('device-token')) {
        return http.Response('{"error":"push_disabled"}', 503,
            headers: {'content-type': 'application/json; charset=utf-8'});
      }
      return _json(_player());
    });
    final c = SessionController(
      api: ApiClient(config: _config, httpClient: client),
      store: SessionStore(),
      push: _FakePush(),
    );

    await c.signIn(_sess());
    expect(c.isSignedIn, isTrue);
  });
}
