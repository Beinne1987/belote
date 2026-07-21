import 'dart:async';

import 'package:app/net/api_client.dart';
import 'package:app/voice/voice_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// غرفةٌ بديلة: تسجّل ما طُلب منها بلا لايف كيت ولا ميكروفون ولا شبكة.
class _FakeRoom implements VoiceRoom {
  final _speaking = StreamController<Set<String>>.broadcast();
  final List<String> log = [];
  bool Function(String)? policy;
  bool micOn = false;
  bool connected = false;

  @override
  Future<void> connect(String url, String token) async {
    connected = true;
    log.add('connect:$url');
  }

  @override
  Future<void> setMicEnabled(bool enabled) async {
    micOn = enabled;
    log.add('mic:$enabled');
  }

  @override
  Future<void> applyPolicy(bool Function(String identity) allow) async {
    policy = allow;
    log.add('policy');
  }

  @override
  Stream<Set<String>> get speaking => _speaking.stream;

  @override
  Future<void> disconnect() async {
    connected = false;
    log.add('disconnect');
  }

  void speak(Set<String> ids) => _speaking.add(ids);

  /// من يُسمَع فعلًا وفق آخر سياسةٍ طُبِّقت.
  bool hears(String id) => policy?.call(id) ?? false;
}

/// عميلٌ بديل يردّ منحةَ صوتٍ ثابتة، أو يرمي خطأً بحالةٍ معيّنة.
class _FakeApi implements ApiClient {
  /// **قابلٌ للتغيير**: يفشل مرّةً ثمّ ينجح — هكذا يُختبَر أنّ الزرَّ لا يموت بعد فشل.
  int? throwStatus;
  _FakeApi({this.throwStatus});

  @override
  Future<VoiceGrant> voiceToken(String token) async {
    if (throwStatus != null) throw ApiException(throwStatus!, 'خطأ');
    return const VoiceGrant(
        url: 'wss://x/belote-voice', room: 'belote-t1', token: 'tk');
  }

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _FakeRoom room;
  VoiceController make({int? throwStatus}) => VoiceController(
        api: _FakeApi(throwStatus: throwStatus),
        authToken: 'auth',
        roomFactory: () => room,
      );

  setUp(() => room = _FakeRoom());

  test('الوضع الابتدائيّ مُطفأ: لا اتّصال ولا ميكروفون حتى يختار اللاعب', () {
    final v = make();
    expect(v.mode, VoiceMode.off);
    expect(v.status, VoiceStatus.off);
    expect(room.connected, isFalse, reason: 'دخول الطاولة وحده لا يفتح ميكروفونك');
  });

  test('اختيار «الجميع» ⇒ يتّصل ويفتح الميكروفون ويسمع الكلّ', () async {
    final v = make();
    await v.setMode(VoiceMode.everyone);

    expect(v.status, VoiceStatus.live);
    expect(room.connected, isTrue);
    expect(room.micOn, isTrue);
    for (final id in ['p1', 'p2', 'p3']) {
      expect(room.hears(id), isTrue, reason: 'الجميع يُسمَعون');
    }
  });

  // ── لا قناةَ خاصّةً لفريق (حُذف وضع «الشريك» في 2026-07-19) ──

  test('**وضعان لا ثالثَ لهما**: عامٌّ أو مُطفأ — لا «شريكٌ فقط»', () {
    expect(VoiceMode.values, [VoiceMode.everyone, VoiceMode.off],
        reason: 'قناةٌ يسمعها الفريقُ وحده تجعل التشاور على الضمانة غشًّا خفيًّا');
  });

  test('في الوضع العامّ **يُسمَع الخصمُ كما يُسمَع الشريك** — لا استثناء', () async {
    final v = make();
    await v.setMode(VoiceMode.everyone);

    // p2 هو الشريك (المقعد المقابل) و p1/p3 خصمان: الثلاثةُ سواء.
    expect(room.hears('p2'), isTrue);
    expect(room.hears('p1'), isTrue, reason: 'لا عزلَ للخصم');
    expect(room.hears('p3'), isTrue);
  });

  test('كتم لاعبٍ يُلغي الاشتراك بصوته، وإلغاء الكتم يعيده', () async {
    final v = make();
    await v.setMode(VoiceMode.everyone);

    await v.toggleMute('p1');
    expect(v.isMuted('p1'), isTrue);
    expect(room.hears('p1'), isFalse, reason: 'المكتوم لا يصل صوته');
    expect(room.hears('p3'), isTrue, reason: 'الكتم فرديٌّ لا يمسّ غيره');

    await v.toggleMute('p1');
    expect(room.hears('p1'), isTrue);
  });

  test('العودة إلى «بدون» تقطع الغرفة ولا تُبقي ميكروفونًا مفتوحًا', () async {
    final v = make();
    await v.setMode(VoiceMode.everyone);
    await v.setMode(VoiceMode.off);

    expect(room.connected, isFalse);
    expect(v.status, VoiceStatus.off);
    expect(room.log.last, 'disconnect');
  });

  test('**الكتم هو علاجُ الإزعاج** لا قناةٌ خاصّة: يكتم واحدًا ويبقى الباقي',
      () async {
    final v = make();
    await v.setMode(VoiceMode.everyone);

    await v.toggleMute('p1'); // مزعجٌ واحد
    expect(room.hears('p1'), isFalse);
    expect(room.hears('p2'), isTrue, reason: 'الطاولةُ تبقى مسمعًا واحدًا');
    expect(room.hears('p3'), isTrue);
  });

  test('من يتكلّم يُنشَر للواجهة', () async {
    final v = make();
    await v.setMode(VoiceMode.everyone);
    var notified = 0;
    v.addListener(() => notified++);

    room.speak({'p1'});
    await Future<void>.delayed(Duration.zero);

    expect(v.isSpeaking('p1'), isTrue);
    expect(v.isSpeaking('p2'), isFalse);
    expect(notified, greaterThan(0), reason: 'الواجهة تُعاد بناؤها');
  });

  test('الصوت غير مُفعَّلٍ على الخادم (503) ⇒ رسالةٌ عربيّة والوضع يعود مُطفأ', () async {
    final v = make(throwStatus: 503);
    await v.setMode(VoiceMode.everyone);

    expect(v.status, VoiceStatus.failed);
    expect(v.mode, VoiceMode.off, reason: 'لا يبقى وضعٌ كاذبٌ معروضًا');
    expect(v.error, contains('غير مُفعَّل'));
  });

  test('لست على طاولة (409) ⇒ رسالةٌ مفهومة', () async {
    final v = make(throwStatus: 409);
    await v.setMode(VoiceMode.everyone);
    expect(v.error, contains('لست على طاولة'));
  });

  // ── زرُّ الميكروفون تحت صورتي هو الصوتُ كلُّه (2026-07-20) ──
  // ذهبت لوحةُ الصوت وزرُّها الجانبيّ: مكانان لأمرٍ واحدٍ أرْبَكا المالك.

  test('**ضغطةٌ تصل وتفتح، وضغطةٌ تقطع كلَّ شيء**', () async {
    final v = make();

    await v.toggleVoice();
    expect(v.status, VoiceStatus.live);
    expect(room.connected, isTrue);
    expect(room.micOn, isTrue, reason: 'من وصل فهو يتكلّم — لا حالةَ صمتٍ متّصل');

    await v.toggleVoice();
    expect(v.status, VoiceStatus.off);
    expect(room.connected, isFalse, reason: 'القطعُ قطعٌ: لا أسمع ولا أُسمَع');
    expect(room.hears('p1'), isFalse);
  });

  test('فشلٌ ثمّ ضغطةٌ ثانية ⇒ **محاولةٌ جديدة** لا زرٌّ ميّت', () async {
    final api = _FakeApi(throwStatus: 503);
    final v =
        VoiceController(api: api, authToken: 'auth', roomFactory: () => room);

    await v.toggleVoice();
    expect(v.status, VoiceStatus.failed);
    // **لبُّ الاختبار**: `_fail` يُعيد الوضعَ مطفأً، فالضغطةُ التالية تمرّ من حارس
    // `setMode` (`_mode == m ⇒ return`). لو بقي الوضعُ «الجميع» بعد الفشل لَصار
    // الزرُّ الأحمرُ لا يفعل شيئًا أبدًا — عطبٌ صامتٌ لا يراه إلّا من فشل مرّة.
    expect(v.mode, VoiceMode.off);

    api.throwStatus = null; // عاد الخادم
    await v.toggleVoice();
    expect(v.status, VoiceStatus.live);
    expect(room.connected, isTrue);
  });
}
