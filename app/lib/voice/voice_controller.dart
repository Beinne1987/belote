import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../net/api_client.dart';

/// من تسمع على الطاولة.
/// **وضعُ الصوت: عامٌّ أو مُطفأ — لا ثالثَ لهما.**
///
/// كان ثمّة `partner` («الشريك فقط»)، وحُذف في 2026-07-19 لأنّه **ثغرةُ غشّ**:
/// حين يختاره الفريقان — وهو الاختيارُ الطبيعيّ لكليهما — يصير كلُّ فريقٍ في قناةٍ
/// معزولةٍ عمليًّا، فيتشاور الشريكان على الضمانة وما في اليد («اضمن كذا · العب كذا»)
/// والخصمُ لا يسمع. والبيلوت لعبةُ استنتاجٍ من الظاهر؛ قناةٌ خفيّةٌ تُبطلها.
///
/// الإزعاجُ يُعالَج بالكتم الفرديّ (`toggleMute`) لا بقناةٍ خاصّة: تكتم من يزعجك
/// وتبقى الطاولةُ مسمعًا واحدًا للجميع.
enum VoiceMode { everyone, off }

/// حال الاتّصال الصوتيّ — تُعرَض على زرّ الميكروفون تحت صورتك.
enum VoiceStatus { off, connecting, live, failed }

/// **الطبقة العازلة عن لايف كيت.** كلّ ما تحتاجه اللعبة من الغرفة، بلا WebRTC في
/// التوقيع ⇒ الاختبارات تحقن بديلًا وتفحص المنطق (السياسة/الأوضاع/الكتم) بلا ميكروفون
/// ولا شبكة. التطبيق الحقيقيّ [LiveKitVoiceRoom] وحده يعرف `livekit_client`.
abstract class VoiceRoom {
  Future<void> connect(String url, String token);
  Future<void> setMicEnabled(bool enabled);

  /// يطبّق سياسة الاشتراك: يشترك في صوت من ترجع [allow] لهويّته `true` فقط.
  ///
  /// **الاشتراك حدٌّ حقيقيّ لا إخفاءٌ في الواجهة**: إلغاء الاشتراك يجعل الخادم يكفّ عن
  /// إرسال ذلك الصوت إلى الجهاز أصلًا — فلا يصل ليُلتقط. (خفضُ مستوى الصوت محليًّا
  /// كان سيُبقيه واصلًا.) تُستدعى مجدّدًا كلّما دخل مشاركٌ أو نشر مسارًا.
  Future<void> applyPolicy(bool Function(String identity) allow);

  /// هويّات من يتكلّمون الآن.
  Stream<Set<String>> get speaking;

  Future<void> disconnect();
}

/// الغرفة الحقيقيّة فوق `livekit_client`.
class LiveKitVoiceRoom implements VoiceRoom {
  final lk.Room _room;
  late final lk.EventsListener<lk.RoomEvent> _events;
  final _speaking = StreamController<Set<String>>.broadcast();
  bool Function(String)? _allow;

  LiveKitVoiceRoom()
      : _room = lk.Room(
          // صوتٌ فقط: لا فيديو ⇒ لا حاجة إلى تكييف التدفّق ولا dynacast.
          roomOptions: const lk.RoomOptions(adaptiveStream: false, dynacast: false),
        ) {
    _events = _room.createListener();
    _events
      ..on<lk.ActiveSpeakersChangedEvent>(
          (e) => _speaking.add({for (final p in e.speakers) p.identity}))
      // مشاركٌ جديدٌ أو مسارٌ جديد لا تشمله السياسة المطبَّقة سابقًا ⇒ أعِد تطبيقها،
      // وإلّا سُمِع خصمٌ دخل متأخّرًا في وضع «الشريك فقط».
      ..on<lk.ParticipantConnectedEvent>((_) => _sync())
      ..on<lk.TrackPublishedEvent>((_) => _sync());
  }

  @override
  Future<void> connect(String url, String token) => _room.connect(url, token);

  @override
  Future<void> setMicEnabled(bool enabled) async {
    // يطلب إذن الميكروفون من النظام عند أوّل تفعيل (يرمي إن رُفض).
    await _room.localParticipant?.setMicrophoneEnabled(enabled);
  }

  @override
  Future<void> applyPolicy(bool Function(String identity) allow) async {
    _allow = allow;
    await _sync();
  }

  Future<void> _sync() async {
    final allow = _allow;
    if (allow == null) return;
    for (final p in _room.remoteParticipants.values) {
      final want = allow(p.identity);
      for (final pub in p.audioTrackPublications) {
        if (pub.subscribed == want) continue;
        want ? await pub.subscribe() : await pub.unsubscribe();
      }
    }
  }

  @override
  Stream<Set<String>> get speaking => _speaking.stream;

  @override
  Future<void> disconnect() async {
    await _events.dispose();
    await _room.disconnect();
    await _speaking.close();
    await _room.dispose();
  }
}

/// حالة الصوت على الطاولة: الوضع · الميكروفون · من كُتِم · من يتكلّم.
///
/// **لا يتّصل من تلقاء نفسه.** الوضع الابتدائيّ [VoiceMode.off]: الدخول إلى طاولةٍ لا
/// يفتح ميكروفونك ولا يطلب إذنًا ولا يستهلك باقتك — الصوت يبدأ بضغطك زرَّ الميكروفون
/// تحت صورتك ([toggleVoice]).
///
/// **حالتان لا ثلاث** (قرار المالك 2026-07-20): متّصلٌ أتكلّم وأسمع، أو مقطوعٌ كلّيًّا.
/// كان ثمّة `setMicOn` تُغلق فمي وأنا متّصلٌ أسمع — سقطت مع لوحة الصوت: زرٌّ واحدٌ
/// لا يحمل ثلاث حالات، ومن أراد الصمت يقطع. الإزعاجُ يُعالَج بكتم صاحبِه على بطاقته.
class VoiceController extends ChangeNotifier {
  final ApiClient api;
  final String authToken;
  final VoiceRoom Function() _newRoom;

  VoiceController({
    required this.api,
    required this.authToken,
    VoiceRoom Function()? roomFactory,
  }) : _newRoom = roomFactory ?? LiveKitVoiceRoom.new;

  VoiceRoom? _room;
  StreamSubscription<Set<String>>? _sub;

  VoiceMode _mode = VoiceMode.off;
  final Set<String> _muted = {};
  Set<String> _speaking = const {};
  VoiceStatus _status = VoiceStatus.off;
  String? _error;

  VoiceMode get mode => _mode;

  /// **مفتاحُ الصوت كلِّه**: مقطوعٌ ⇒ يتّصل ويفتح ميكروفونك · متّصلٌ ⇒ يقطع الغرفة
  /// (لا تسمع ولا تُسمَع، ولا باقةَ تُستهلك). فشلٌ سابق ⇒ محاولةٌ جديدة.
  Future<void> toggleVoice() =>
      setMode(_mode == VoiceMode.off ? VoiceMode.everyone : VoiceMode.off);

  VoiceStatus get status => _status;
  String? get error => _error;
  bool isMuted(String playerId) => _muted.contains(playerId);
  bool isSpeaking(String playerId) => _speaking.contains(playerId);

  /// سياسة الاشتراك — **مصدر الحقيقة الوحيد** لمن يُسمَع: الوضع ثمّ الكتم الفرديّ.
  /// لا استثناءَ لفريقٍ ولا لشريك: الطاولةُ مسمعٌ واحد.
  bool _allow(String identity) {
    if (_mode == VoiceMode.off) return false;
    if (_muted.contains(identity)) return false;
    return true;
  }

  Future<void> setMode(VoiceMode m) async {
    if (_mode == m) return;
    _mode = m;
    notifyListeners();
    if (m == VoiceMode.off) {
      await _teardown();
      _status = VoiceStatus.off;
      _error = null;
      notifyListeners();
      return;
    }
    await _connect();
    await _room?.applyPolicy(_allow);
  }

  /// كتم لاعبٍ بعينه — يُلغي الاشتراك بصوته فيكفّ الخادم عن إرساله.
  Future<void> toggleMute(String playerId) async {
    _muted.contains(playerId) ? _muted.remove(playerId) : _muted.add(playerId);
    notifyListeners();
    await _room?.applyPolicy(_allow);
  }

  Future<void> _connect() async {
    if (_room != null) return;
    _status = VoiceStatus.connecting;
    _error = null;
    notifyListeners();
    try {
      // الجلوس هو الإذن: الخادم يشتقّ الغرفة من طاولتك ولا يقبل اسمًا منّا.
      final grant = await api.voiceToken(authToken);
      final room = _newRoom();
      _sub = room.speaking.listen((s) {
        _speaking = s;
        notifyListeners();
      });
      await room.connect(grant.url, grant.token);
      await room.applyPolicy(_allow);
      // الاتّصالُ والكلامُ شيءٌ واحد: من وصل فهو يتكلّم. (يطلب إذنَ الميكروفون
      // هنا؛ رفضُه يرمي ⇒ `_fail` فيعود الزرُّ إلى المقطوع ومعه سببٌ مكتوب.)
      await room.setMicEnabled(true);
      _room = room;
      _status = VoiceStatus.live;
      notifyListeners();
    } catch (e) {
      await _teardown();
      _fail(e);
    }
  }

  void _fail(Object e) {
    _mode = VoiceMode.off;
    _status = VoiceStatus.failed;
    _error = switch (e) {
      ApiException(status: 503) => 'الصوت غير مُفعَّلٍ على الخادم بعد.',
      ApiException(status: 409) => 'لست على طاولة.',
      ApiException(status: 401) => 'انتهت جلستك — أعِد الدخول.',
      _ => 'تعذّر الاتّصال بالصوت. تأكّد من إذن الميكروفون والشبكة.',
    };
    notifyListeners();
  }

  Future<void> _teardown() async {
    await _sub?.cancel();
    _sub = null;
    _speaking = const {};
    final r = _room;
    _room = null;
    await r?.disconnect();
  }

  @override
  void dispose() {
    _teardown(); // مغادرة الطاولة تُغلق الغرفة — لا ميكروفون يبقى مفتوحًا خلفك.
    super.dispose();
  }
}
