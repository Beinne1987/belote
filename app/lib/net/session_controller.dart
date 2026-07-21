import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart';

import '../services/push_service.dart';
import 'api_client.dart';
import 'session_store.dart';

/// حالة الجلسة على مستوى التطبيق: اللاعب المصادَق + محفظته + إحصائياته.
/// تُحمَّل من [SessionStore] عند الإقلاع، وتُحدَّث من الخادم. تخلو الشاشات من أي
/// بيانات وهميّة: تقرأ من هنا حين المصادقة، وإلا تعرض حالة «سجّل الدخول».
class SessionController extends ChangeNotifier {
  final ApiClient api;
  final SessionStore store;

  /// توكن الإشعارات. null ⇒ لا إشعارات (اختباراتٌ، أو منصّةٌ بلا Firebase).
  final PushTokens? push;

  StreamSubscription<String>? _pushRefreshSub;

  /// آخرُ توكن جهازٍ سُجِّل — يُحفَظ كي يُمحى **هو بعينه** عند الخروج: طلبُه من
  /// Firebase حينها قد يُعيد غيرَه (أو لا شيء)، فيبقى القديم في القاعدة وتصل
  /// دعواتي إلى جهازٍ خرجتُ منه.
  String? _deviceToken;

  SessionController({ApiClient? api, SessionStore? store, this.push})
      : api = api ?? ApiClient(),
        store = store ?? SessionStore() {
    // تدويرُ Google للتوكن لا يستأذن أحدًا ⇒ الإنصاتُ **دائم** لا عند الدخول فقط.
    _pushRefreshSub = push?.onRefresh.listen((t) {
      _deviceToken = t;
      final s = _session;
      // `this.api` لا `api`: الأخيرة معامل المُنشئ (nullable) يظلّل الحقل.
      if (s != null) this.api.putDeviceToken(s.token, t);
    });
  }

  AuthSession? _session;
  Map<String, int> _wallet = const {};
  PlayerStatsView? _stats;
  bool _loaded = false;

  bool get loaded => _loaded; // انتهت محاولة استعادة الجلسة المحفوظة
  bool get isSignedIn => _session != null;
  AuthSession? get session => _session;
  AccountPlayer? get player => _session?.player;
  int get diamonds => _wallet['diamonds'] ?? 0;

  /// مخزونُ الهديّة [giftId] — ما يملكه ولم يرسله بعد. المخزونُ رصيدٌ في المحفظة
  /// نفسِها بعملةٍ اسمُها `gift:<id>`، فيصله بلا مسارٍ ثانٍ.
  int giftStock(String giftId) => _wallet['gift:$giftId'] ?? 0;

  /// **ما يملكه من هدايا**: معرّفٌ ⇒ عدد. مشتقٌّ من المحفظة لا محفوظٌ على حدة.
  ///
  /// المحفظةُ خريطةُ عملات، والصنفُ تُميّزه بادئتُه ⇒ صنفٌ جديدٌ (أسكنٌ `skin:<id>`)
  /// يظهر بإضافة قارئٍ مثل هذا، بلا مسارٍ ولا جدولٍ ولا إعادةِ تصميم.
  Map<String, int> get ownedGifts => _owned('gift:');

  Map<String, int> _owned(String prefix) => {
        for (final e in _wallet.entries)
          if (e.key.startsWith(prefix) && e.value > 0)
            e.key.substring(prefix.length): e.value
      };
  PlayerStatsView? get stats => _stats;

  /// عددُ ما لم أقرأه — شارةُ الجرس. **صفرٌ إن جُهل**: خادمٌ قديمٌ بلا المسار، أو
  /// شبكةٌ متعثّرة ⇒ لا شارةَ حمراء كاذبة على شيءٍ قد لا يكون موجودًا.
  int get unreadNotifications => _unread;
  int _unread = 0;

  /// رسائلُ خاصّةٌ لم أقرأها — شارةُ بطاقة «الأصدقاء» في الرئيسيّة. **صفرٌ إن
  /// جُهل** كشارة الجرس: لا شارةَ كاذبةً على تعثّر شبكة.
  int get unreadMessages => _unreadMessages;
  int _unreadMessages = 0;

  /// حدُّ لعباتِ اليوم. **null ⇒ لا نعرف** (لم يُجلَب بعدُ · أو الحدُّ مُطفأٌ خادميًّا)
  /// ⇒ الشاشةُ **تُخفي العدّادَ ولا تخترع رقمًا**: «بقيت لك 5» وهي كذبةٌ أسوأُ من
  /// صمت.
  PlayAllowanceView? get allowance => _allowance;
  PlayAllowanceView? _allowance;

  /// **لوحةُ الشرف وألقابُها** ([[honors-weekly]]). فارغةٌ ⇒ لم تُجلَب بعدُ أو
  /// خادمٌ أقدمُ من الميزة ⇒ **لا شارةَ ولا قسم**، لا شارةٌ كاذبة.
  ///
  /// تُحمَل هنا لا في كلّ شاشة: خريطةُ الألقاب ضئيلةٌ (خمسةُ حاملين على الأكثر)
  /// وتُقرأ من الطاولة والصدارة والملفّ معًا — جلبٌ واحدٌ يخدمها كلَّها.
  HonorsBoard get honors => _honors;
  HonorsBoard _honors = HonorsBoard.empty;

  /// **للاختبار وحدَه**: يحقن لوحةً جاهزةً بلا شبكة، فتُفحَص الشاراتُ في
  /// الشاشات كما يراها اللاعب.
  @visibleForTesting
  void debugSetHonors(HonorsBoard b) {
    _honors = b;
    notifyListeners();
  }

  /// لقبُ [playerId] الأعلى (معرّفُ فئة) — null ⇒ بلا لقب.
  String? titleOf(String playerId) => _honors.topTitleOf(playerId);

  /// **عامّةٌ بلا توكن**: تُجلَب حتى لغير المصادَق (الرئيسيّةُ تعرضها قبل الدخول)،
  /// وتبتلع فشلَها — لوحةُ شرفٍ لا تصل لا تمنع لعبةً.
  Future<void> refreshHonors() async {
    try {
      _honors = await api.honors();
      notifyListeners();
    } catch (_) {
      // خادمٌ أقدم (404) أو شبكة ⇒ أبقِ آخرَ ما نعرف.
    }
  }

  /// يُستدعى مرّة عند الإقلاع: يستعيد الجلسة المحفوظة ثم يحدّثها من الخادم.
  Future<void> loadSaved() async {
    _session = await store.load();
    _loaded = true;
    notifyListeners();
    // **قبل فحص الجلسة**: اللوحةُ عامّةٌ ⇒ يراها غيرُ المصادَق أيضًا.
    unawaited(refreshHonors());
    if (_session != null) {
      await refresh();
      // **كلُّ إقلاعٍ يُسجّل**: التوكن يُدوَّر، والخادم قد يفقد صفَّه، ولاعبٌ
      // مسجَّلٌ منذ شهرٍ قد لا يكون له عنوانٌ صالحٌ اليوم. التسجيل رخيصٌ (`put`
      // تُحدّث صفًّا) وثمنُ إغفاله دعوةٌ لا تصل.
      await _registerDevice();
    }
  }

  /// مصادقة جديدة: يحفظ الجلسة ويجلب بياناتها.
  Future<void> signIn(AuthSession s) async {
    _session = s;
    await store.save(s);
    notifyListeners();
    await refresh();
    await _registerDevice();
  }

  /// يطلب الإذن ويُسجّل التوكن. **لا يرمي ولا يُبطئ**: من رفض الإذن يلعب كما كان.
  Future<void> _registerDevice() async {
    final p = push;
    final s = _session;
    if (p == null || s == null) return;
    try {
      final t = await p.requestToken();
      if (t == null) return; // رُفض الإذن — ليس عطبًا
      _deviceToken = t;
      await api.putDeviceToken(s.token, t);
    } catch (_) {
      // عطبُ منصّةٍ (لا Firebase على هذا الجهاز) لا يمنع الدخول.
    }
  }

  /// يستبدل اللاعب في الجلسة بعد تعديل ملفّه (اسم · صورة) **ويحفظه على الجهاز**.
  ///
  /// بلا الحفظ يعود الملفّ القديم عند أوّل إقلاع: الجلسة المحفوظة تحمل نسخةً من
  /// اللاعب، فلا يكفي تحديثُ الذاكرة. والتوكن كما هو — الملفُّ تغيّر لا الهويّة.
  Future<void> updatePlayer(AccountPlayer p) async {
    final s = _session;
    if (s == null) return;
    _session = AuthSession(token: s.token, player: p, isNew: false);
    await store.save(_session!);
    notifyListeners();
  }

  Future<void> signOut() async {
    // **قبل مسح الجلسة**: محوُ التوكن مسارٌ محميٌّ يحتاج توكن المصادقة. لو مسحنا
    // الجلسة أوّلًا لبقي عنوانُ هذا الجهاز في القاعدة، فوصلت دعواتُ من خرج إلى
    // من دخل بعده على نفس الهاتف.
    final s = _session;
    final dev = _deviceToken;
    if (s != null && dev != null) await api.removeDeviceToken(s.token, dev);
    try {
      await push?.delete(); // ولا يبقى للجهاز عنوانٌ أصلًا
    } catch (_) {
      // عطبُ منصّةٍ لا يمنع الخروج.
    }
    _deviceToken = null;
    _session = null;
    _wallet = const {};
    _stats = null;
    _unread = 0; // وإلّا رأى الداخلُ بعده على نفس الهاتف شارةَ من خرج
    _unreadMessages = 0;
    await store.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _pushRefreshSub?.cancel();
    super.dispose();
  }

  /// يعيد جلب المحفظة والإحصائيات وشارة الجرس. توكنٌ منتهٍ (401) ⇒ خروجٌ تلقائيّ.
  Future<void> refresh() async {
    final s = _session;
    if (s == null) return;
    try {
      final results = await Future.wait([api.wallet(s.token), api.stats(s.token)]);
      _wallet = results[0] as Map<String, int>;
      _stats = results[1] as PlayerStatsView;
      notifyListeners();
    } on ApiException catch (e) {
      if (e.status == 401) await signOut(); // توكن منتهٍ ⇒ عُد لغير مصادَق
      // أخطاء أخرى (شبكة) تُتجاهَل: نُبقي آخر بياناتٍ معروفة.
      return;
    }
    // **بعد المحفظة لا معها**: `unreadCount` تبتلع فشلَها بنفسها، فلو دخلت
    // `Future.wait` لأسقط تعثّرُها المحفظةَ والإحصاء — وهما ما طلبه اللاعب.
    await refreshUnread();
    await refreshPlayLimit();
    // **وحالةُ VIP**: بلا هذا لا تعرف الشاشاتُ أنّه مشترك حتى يفتح صفحةَ VIP —
    // فيظهر بلا شارةٍ في ملفّه وهو دافع. **وقراءتُها تصرف دفعتَه الشهريّة** (فتحُ
    // التطبيق هو المُجدوِل، لا cron).
    await refreshVip();
    if (_vipUntil != null) await refreshVipGifts();
    // **بعد الكلّ**: الألقابُ زينةٌ لا يجوز أن يُسقط تعثّرُها محفظةً ولا إحصاءً.
    await refreshHonors();
  }

  /// يُحدّث عدّادَ لعبات اليوم. يُنادى عند الإقلاع، وبعد كلّ مباراةٍ أونلاين،
  /// وعند العودة إلى التطبيق (منتصفُ الليل قد يمرّ والتطبيقُ مفتوح).
  ///
  /// **يبتلع فشلَه**: عدّادٌ لا يُجلَب لا يجوز أن يمنع اللعب. و503 (الحدُّ مُطفأ)
  /// حالةٌ تُعالَج: يبقى `allowance` فارغًا ⇒ لا عدّادَ ولا حدّ.
  Future<void> refreshPlayLimit() async {
    final s = _session;
    if (s == null) return;
    try {
      _allowance = await api.playLimit(s.token);
      notifyListeners();
    } catch (_) {
      // مُطفأٌ (503) أو شبكةٌ ⇒ أبقِ آخرَ ما نعرف؛ لا نمحوه فيومض العدّادُ ويختفي.
    }
  }

  /// يشتري باقةَ هدايا ويُحدّث المحفظةَ من **ردّ الشراء نفسِه**.
  ///
  /// لا نداءَ ثانٍ لجلب المحفظة: الردُّ يحملها، ونداءٌ إضافيٌّ يفتح نافذةً يظهر فيها
  /// الرصيدُ القديمُ على الشاشة. ولا نطرح الثمنَ محلّيًّا تفاؤلًا — الخادمُ هو مَن
  /// يعرف الرصيدَ الصادق.
  ///
  /// يُمرِّر [ApiException] كما هي (402 = لا يكفي الماس) ليقرّر المُنادي ما يقول.
  Future<void> buyGiftBundle(String bundleId) async {
    final s = _session;
    if (s == null) return;
    _wallet = await api.buyGiftBundle(s.token, bundleId);
    notifyListeners();
  }

  /// يشتري تذكرةً ويُحدّث **المحفظةَ والعدّادَ من ردّ الشراء نفسِه**.
  ///
  /// نداءٌ ثانٍ لجلب العدّاد يفتح نافذةً يظهر فيها «انتهت لعباتُك» وقد اشترى — وهو
  /// أسوأُ ما يراه مَن دفع للتوّ.
  ///
  /// يُمرِّر [ApiException] كما هي (402 = الماسُ لا يكفي). يُعيد **suggestVip**:
  /// اشترى تذاكرَ كثيرةً ⇒ يُعرَض عليه VIP (التذكرةُ بابٌ إليه لا منافسٌ له).
  Future<bool> buyTicket(String ticketId) async {
    final s = _session;
    if (s == null) return false;
    final r = await api.buyTicket(s.token, ticketId);
    _wallet = r.wallet;
    final a = _allowance;
    // **العدّادُ يصير «بلا حدود» فورًا** بنهايةٍ من الخادم. وإن جُهل العدّادُ بعدُ
    // فلا نخترع سقفًا — يصله عند أوّل تحديث.
    if (a != null) {
      _allowance = PlayAllowanceView(
        limit: a.limit,
        used: a.used,
        remaining: a.remaining,
        canPlay: true,
        passUntil: r.passUntil,
      );
    }
    notifyListeners();
    return r.suggestVip;
  }

  /// **رصيدُ هدايا VIP الحصريّة** (3 يوميًّا حتى 10). صفرٌ ⇒ غيرُ مشتركٍ أو نفد.
  int get vipGiftStock => _vipGiftStock;
  int _vipGiftStock = 0;

  /// يجلب رصيدَ هدايا VIP — **وقراءتُه تجدّد ما استحقّ** (لا cron).
  Future<void> refreshVipGifts() async {
    final s = _session;
    if (s == null) return;
    try {
      _vipGiftStock = await api.vipGiftStock(s.token);
      notifyListeners();
    } catch (_) {
      // مُطفأٌ أو شبكةٌ ⇒ أبقِ آخرَ ما نعرف.
    }
  }

  /// **أهو VIP الآن؟** null ⇒ لا نعرف بعد.
  DateTime? get vipUntil => _vipUntil;
  DateTime? _vipUntil;
  bool get isVip => _vipUntil != null;

  /// يجلب حالةَ VIP — **وقراءتُها تصرف ما استحقّ من دفعاتٍ شهريّة** (فتحُ التطبيق
  /// هو المُجدوِل، لا cron). يُعيد كم دفعةً صُرفت الآن ليُخبَر بها اللاعب.
  ///
  /// يبتلع فشلَه: حالةٌ لا تُجلَب لا تمنع لعبًا.
  Future<int> refreshVip() async {
    final s = _session;
    if (s == null) return 0;
    try {
      final r = await api.vipStatus(s.token);
      _vipUntil = r.active ? r.until : null;
      if (r.wallet.isNotEmpty) _wallet = r.wallet;
      notifyListeners();
      return r.granted;
    } catch (_) {
      return 0;
    }
  }

  /// يشترك في VIP ويُحدّث **المحفظةَ والحالةَ من ردّ الاشتراك نفسِه**.
  ///
  /// يُمرِّر [ApiException] كما هي (402 = الماسُ لا يكفي).
  Future<void> subscribeVip(String planId) async {
    final s = _session;
    if (s == null) return;
    final r = await api.subscribeVip(s.token, planId);
    _wallet = r.wallet;
    _vipUntil = r.until;
    // **VIP يلعب بلا حدود** ⇒ العدّادُ يصير بلا حدودٍ فورًا، لا بعد جلبٍ ثانٍ.
    final a = _allowance;
    if (a != null) {
      _allowance = PlayAllowanceView(
        limit: a.limit,
        used: a.used,
        remaining: a.remaining,
        canPlay: true,
        passUntil: r.until,
        graceUntil: a.graceUntil,
        trialAvailable: a.trialAvailable,
      );
    }
    notifyListeners();
  }

  /// **يستلم التجربةَ المجّانيّة** ويُحدّث العدّادَ من ردّها. لا محفظةَ تتغيّر —
  /// هديّةٌ لا شراء.
  ///
  /// يُمرِّر [ApiException] كما هي (409 = سبق أن نالها).
  Future<void> claimTrial() async {
    final s = _session;
    if (s == null) return;
    final until = await api.claimTrial(s.token);
    final a = _allowance;
    if (a != null) {
      _allowance = PlayAllowanceView(
        limit: a.limit,
        used: a.used,
        remaining: a.remaining,
        canPlay: true,
        passUntil: until,
        graceUntil: a.graceUntil,
        trialAvailable: false, // نالها ⇒ لا تُعرَض ثانيةً
      );
    }
    notifyListeners();
  }

  /// يقبض جائزةَ مهمّةٍ ويُحدّث **المحفظةَ والإحصاءَ من ردّ القبض نفسِه**.
  ///
  /// المهمّةُ تمنح ماسًا وخبرةً معًا ⇒ الاثنان يتغيّران، والردُّ يحملهما. نداءٌ ثانٍ
  /// يفتح نافذةً يظهر فيها المستوى القديم بعد أن رُفع.
  ///
  /// يُمرِّر [ApiException] كما هي (409 = قُبضت أو لم تكتمل).
  Future<void> claimMission(String missionId) async {
    final s = _session;
    if (s == null) return;
    final r = await api.claimMission(s.token, missionId);
    _wallet = r.wallet;
    _stats = r.stats;
    notifyListeners();
  }

  /// يُحدّث شارتَي الجرس والرسائل — بعد فتح الشاشة أو العودة إلى التطبيق.
  /// نداءان يبتلعان فشلَهما كلٌّ على حدة: تعثّرُ أحدهما لا يُسقط الآخر.
  Future<void> refreshUnread() async {
    final s = _session;
    if (s == null) return;
    final n = await api.unreadCount(s.token);
    final m = await api.unreadMessages(s.token);
    var changed = false;
    if (n != null && n != _unread) {
      _unread = n;
      changed = true;
    }
    if (m != null && m != _unreadMessages) {
      _unreadMessages = m;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  /// تُنادى من شاشة الإشعارات بعد التعليم مقروءًا — الشارةُ تتبع بلا نداءٍ ثانٍ.
  void setUnread(int n) {
    if (n == _unread) return;
    _unread = n;
    notifyListeners();
  }
}

/// يوفّر [SessionController] للشجرة، ويعيد البناء عند تغيّر الجلسة.
class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({super.key, required SessionController controller, required super.child})
      : super(notifier: controller);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope?.notifier != null, 'SessionScope غير موجود في الشجرة');
    return scope!.notifier!;
  }

  /// **بلا تأكيد** — لزينةٍ تعمل بلا جلسة: شارةُ اللقب تُرسَم في شاشاتٍ تُختبَر
  /// وحدَها بلا `SessionScope`، ولا يجوز أن تُسقط الشاشةَ لغيابها. null ⇒ لا زينة.
  static SessionController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()?.notifier;
}
