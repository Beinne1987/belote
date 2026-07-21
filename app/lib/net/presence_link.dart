import 'dart:async';

import 'package:flutter/widgets.dart';

import 'api_config.dart';
import 'table_client.dart';

/// **قناةُ الحضور** — تُبقي اللاعبَ «متّصلًا» ما دام التطبيقُ مفتوحًا، لا ما دام
/// جالسًا على شاشة اللعب.
///
/// كان الحضورُ في الخادم صحيحًا والعميلُ هو الناقص: لا قناةَ إلّا في
/// `OnlineGamePage` ⇒ صاحبُك يتصفّح اللوبي أو المتجر وأنت تراه في قائمتك
/// رماديًّا، فلا تدعوه. هذه القناة تفتح `/ws?mode=presence` (الخادم يجعلها
/// **خاملة**: حضورٌ واستقبالٌ بلا لعب) فتصير النقطةُ الخضراء صادقة.
///
/// **تُغلَق في ثلاث حالات**، وكلُّها مقصودة:
/// - خرج من حسابه ⇒ لا حضورَ لمن لا هويّة له.
/// - غادر التطبيقَ إلى الخلفيّة ⇒ «متّصل» تعني «يراك الآن»، ومن أغلق الشاشة
///   لا يراك؛ الدعوةُ حينها تصله إشعارًا وهو أصدق.
/// - فُتحت شاشةُ اللعب ([pause]) ⇒ قناتُها تكفي للحضور، وقناتان تعنيان دعوةً
///   تظهر مرّتين.
class PresenceLink extends ChangeNotifier {
  /// حاقنُ العميل — للاختبار وحده (قناةٌ وهميّة بلا شبكة).
  final LiveTableClient Function(Uri uri)? clientFactory;

  PresenceLink({this.clientFactory});

  final _invites = StreamController<InviteEvent>.broadcast();

  /// الدعواتُ الواردةُ **خارج شاشة اللعب** — من يستمع إليها يعرضها.
  Stream<InviteEvent> get invites => _invites.stream;

  String? _token;
  bool _foreground = true;
  int _pauses = 0; // عدّادٌ لا رايةٌ: شاشتا لعبٍ متراكمتان لا تفكّان بعضهما
  LiveTableClient? _client;
  StreamSubscription<TableEvent>? _sub;
  bool _disposed = false;

  /// أمتّصلٌ الآن؟ (لتشخيصٍ واختبار — لا تعرضه الواجهة: الحضورُ خبرٌ عن غيرك.)
  bool get isLinked => _client != null;

  /// التوكن الحاليّ — `null` عند الخروج. يُستدعى من `SessionController`.
  void setToken(String? token) {
    if (_token == token) return;
    _token = token;
    _reconcile();
  }

  /// دورةُ حياة التطبيق (`resumed` ⇒ true).
  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _reconcile();
  }

  /// تُوقف القناة ما دامت شاشةُ اللعب مفتوحة. كلُّ [pause] يقابلها [resume].
  void pause() {
    _pauses++;
    _reconcile();
  }

  void resume() {
    if (_pauses > 0) _pauses--;
    _reconcile();
  }

  bool get _wanted =>
      !_disposed && _token != null && _foreground && _pauses == 0;

  void _reconcile() {
    if (_wanted == isLinked) return;
    if (!_wanted) {
      _close();
      notifyListeners();
      return;
    }
    final uri = ApiConfig.current
        .ws('/ws', {'token': _token!, 'mode': 'presence'});
    final c = (clientFactory ?? LiveTableClient.connect)(uri);
    _client = c;
    // **الدعوةُ وحدَها**: القناة خاملة، وكلُّ ما عداها من الأحداث يخصّ طاولةً
    // لسنا عليها. ما لا نعرفه يُهمَل بهدوء ([[ws-event-forward-compat]]).
    _sub = c.events.listen((e) {
      if (e is InviteEvent && !_invites.isClosed) _invites.add(e);
    }, onError: (_) {});
    notifyListeners();
  }

  void _close() {
    _sub?.cancel();
    _sub = null;
    _client?.dispose();
    _client = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _close();
    _invites.close();
    super.dispose();
  }
}

/// يتيح [PresenceLink] للشجرة — شاشةُ اللعب تُوقفه عند فتحها وتستأنفه عند خروجها.
class PresenceScope extends InheritedWidget {
  final PresenceLink link;

  const PresenceScope({super.key, required this.link, required super.child});

  /// `null` إن لم يكن في الشجرة (اختباراتُ شاشةٍ مفردة) — لا انهيار.
  static PresenceLink? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PresenceScope>()
      ?.link;

  @override
  bool updateShouldNotify(PresenceScope old) => old.link != link;
}
