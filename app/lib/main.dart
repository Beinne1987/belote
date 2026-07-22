import 'dart:async';

import 'package:flutter/material.dart';

import 'app_settings.dart';
import 'boot.dart';
import 'game/game_controller.dart';
import 'game/view_model.dart';
import 'net/api_client.dart';
import 'net/presence_link.dart';
import 'net/session_controller.dart';
import 'net/table_client.dart';
import 'services/push_service.dart';
import 'services/update_service.dart';
import 'ui/missions_screen.dart';
import 'ui/play_limit_dialog.dart';
import 'ui/vip_screen.dart';
import 'ui/welcome_gifts_dialog.dart';
import 'ui/notifications_screen.dart';
import 'ui/update_dialog.dart';
import 'sfx.dart';
import 'theme.dart';
import 'theme/belote_theme.dart';
import 'theme/theme_manager.dart';
import 'platform/app_platform.dart';
import 'ui/app_frame.dart';
import 'ui/friends_screen.dart';
import 'ui/invite_dialog.dart';
import 'ui/about_screen.dart';
import 'ui/home_screen.dart';
import 'ui/leaderboard_screen.dart';
import 'ui/live_tables_screen.dart';
import 'ui/auth/auth_landing_screen.dart';
import 'ui/online_game_page.dart';
import 'ui/profile_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/store_screen.dart';
import 'ui/table_screen.dart';
import 'ui/tournaments_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // **النافذةُ أوّلًا.** لا نداءَ لإضافةٍ أصليّةٍ قبل `runApp`: خيطُ الواجهة
  // مدموجٌ بالخيط الرئيس في فلاتر الحديث، فإضافةٌ متعثّرةٌ هنا تعني تطبيقًا حيًّا
  // **بلا نافذة** — وهو ما حدث فعلًا على ماك. التفصيلُ في [AppBoot].
  runApp(const BeloteApp());
  AppBoot.instance.startNative();
}

class BeloteApp extends StatefulWidget {
  const BeloteApp({super.key});

  @override
  State<BeloteApp> createState() => _BeloteAppState();
}

class _BeloteAppState extends State<BeloteApp> with WidgetsBindingObserver {
  // مدير الثيم متاحٌ للشجرة عبر ThemeScope. الشاشات ستقرأ منه عند الترحيل من Palette
  // (docs/DESIGN-SYSTEM.md)؛ حاليًّا لا تغيير بصريّ.
  final ThemeManager _theme = ThemeManager();
  final AppSettings _settings = AppSettings();
  // **الدفعُ للهاتف وحدَه**: `firebase_messaging` لا تنفيذَ له على ويندوز/ماك،
  // ونداؤه هناك يرمي `MissingPluginException` عند أوّل دخول. صندوقُ الإشعارات
  // داخل التطبيق يعمل على الحاسوب كما هو (الجرسُ يجلب من الخادم).
  final PushTokens _push =
      AppPlatform.push ? FirebasePushTokens() : const NoPushTokens();
  late final SessionController _session = SessionController(push: _push);
  final PresenceLink _presence = PresenceLink();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  bool _updateDialogOpen = false;
  StreamSubscription<Map<String, String>>? _tapSub;
  StreamSubscription<InviteEvent>? _inviteSub;
  bool _inviteOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _theme.loadSaved(); // استعادة الثيم المحفوظ (بلا حجب الإقلاع)
    _settings.load(); // استعادة الاسم/الصوت
    _session.loadSaved(); // استعادة جلسة الأونلاين المحفوظة وتحديثها من الخادم
    // **الحضورُ يتبع الجلسة**: دخولٌ يفتح القناة، وخروجٌ يغلقها — بلا أن تعرف
    // أيُّ شاشةٍ بذلك شيئًا.
    _session.addListener(_syncPresence);
    _syncPresence();
    // دعوةٌ تصل واللاعبُ خارج شاشة اللعب (لوبي · متجر · أصدقاء) ⇒ تُعرَض هنا.
    _inviteSub = _presence.invites.listen(_showInvite);
    // فحص التحديث فور فتح التطبيق (اللوبي) — لا عند دخول اللعب فقط.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
    // لمسةُ إشعارٍ والتطبيق نائم.
    _tapSub = _push.onTap.listen(_openFromPush);
    // ولمسةٌ والتطبيق **ميّت**: الحمولة تنتظر في `getInitialMessage`. بلا هذه
    // يفتح المدعوُّ التطبيقَ على القائمة الرئيسيّة ولا يدري لِمَ أيقظه هاتفُه.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = await _push.initialTap();
      if (data != null) _openFromPush(data);
    });
  }

  /// يُسلّم توكنَ الجلسة إلى قناة الحضور (أو `null` عند الخروج).
  void _syncPresence() => _presence.setToken(_session.session?.token);

  /// **نافذةٌ لا لافتة** — بخلاف الدعوة داخل شاشة اللعب: هناك قد تصل وسط أخذةٍ
  /// فتحجب حجبُها دورًا، وهنا اللاعبُ يتصفّح فلا شيءَ يُقاطَع، والدعوةُ تنتهي
  /// صلاحيّتُها بامتلاء المقعد ⇒ لافتةٌ تُنسى أسوأ.
  Future<void> _showInvite(InviteEvent invite) async {
    if (_inviteOpen) return; // دعوتان معًا ⇒ الأولى تُجاب ثمّ تُعرَض الثانية
    final ctx = _navKey.currentContext;
    if (ctx == null || !ctx.mounted || !_session.isSignedIn) return;
    _inviteOpen = true;
    final accept = await showInviteDialog(ctx, invite);
    _inviteOpen = false;
    if (accept != true || !ctx.mounted) return;
    await Navigator.of(ctx).push(MaterialPageRoute<void>(
      builder: (_) => OnlineGamePage(
        session: _session.session!,
        initialInvite: (code: invite.code, seat: invite.seat),
      ),
    ));
    await _session.refresh();
  }

  void _openFromPush(Map<String, String> data) {
    final ctx = _navKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    openNotificationTarget(ctx, _session, data);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSub?.cancel();
    _inviteSub?.cancel();
    _theme.dispose();
    _settings.dispose();
    _session.removeListener(_syncPresence);
    _session.dispose();
    _presence.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // **الحضورُ يعني «يراك الآن»**: من ذهب إلى الخلفيّة تُغلَق قناتُه فيصير
    // رماديًّا عند أصدقائه — والدعوةُ تصله إشعارًا. وعودتُه تُعيد فتحها.
    _presence.setForeground(state == AppLifecycleState.resumed);
    if (state != AppLifecycleState.resumed) return;
    // إعادة الفحص عند العودة للتطبيق (مثلًا بعد تصفّح المتجر) — يبقى التذكير حاضرًا.
    _checkUpdate();
    // **وشارةُ الجرس**: الإشعار وصل والتطبيقُ في الخلفيّة ⇒ عودةٌ إلى شارةٍ بائتة
    // بلا هذا. رخيصةٌ (فهرسٌ جزئيّ على غير المقروء) وتبتلع فشلها.
    _session.refreshUnread();
    // **وعدّادُ اللعبات**: منتصفُ الليل يمرّ والتطبيقُ في الخلفيّة ⇒ يعود فيرى
    // «انتهت لعباتُك» ولها ساعاتٌ عادت. يبتلع فشلَه كذلك.
    _session.refreshPlayLimit();
  }

  /// يفحص التحديث ويعرض النافذة على الجذر (فوق أي شاشة). يمنع فتح نافذتين.
  Future<void> _checkUpdate() async {
    // **لا مثبِّتَ APK على الحاسوب**: نافذةٌ تعرض تحديثًا لا يمكن تركيبُه وعدٌ
    // كاذب. تحديثُ نسخة سطح المكتب شأنُ متجرِها/مثبِّتِها.
    if (!AppPlatform.inAppUpdate) return;
    if (_updateDialogOpen) return;
    final info = await UpdateService.check();
    if (info == null) return;
    final ctx = _navKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    _updateDialogOpen = true;
    try {
      await UpdateDialog.show(ctx, info);
    } finally {
      _updateDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      manager: _theme,
      child: AppSettingsScope(
        settings: _settings,
        child: SessionScope(
          controller: _session,
          child: PresenceScope(
            link: _presence,
            child: MaterialApp(
              navigatorKey: _navKey,
              title: 'Belote',
              debugShowCheckedModeBanner: false,
              theme: buildTheme(),
              // **الفأرةُ تسحب القوائمَ كالإصبع** على ويندوز وماك.
              scrollBehavior: const AppScrollBehavior(),
              // الترتيبُ مقصود: الاتّجاهُ أوّلًا ثمّ المسرح — فإطارُ المجلس حول
              // المسرح يرث RTL كبقيّة الشجرة.
              builder: (context, child) => Directionality(
                textDirection: TextDirection.rtl,
                child: AppFrame(child: child!),
              ),
              home: const _Root(),
            ),
          ),
        ),
      ),
    );
  }
}

/// **يفتح ما يخصّ إشعارًا** — من شريط الهاتف أو من صفٍّ في الجرس.
///
/// **موضعٌ واحدٌ للوجهة**: [data] هي حمولةُ الدفع وحمولةُ الصندوق معًا (الخادم يكتب
/// واحدةً للاثنين — `NotificationService`). منطقان لوجهةٍ واحدة يفترقان يومَ
/// يُعدَّل أحدهما، فيفتح الجرسُ غيرَ ما يفتحه الإشعار.
///
/// **يُهمل ما لا يعرف** بهدوء: خادمٌ أحدث قد يبثّ نوعًا لم يكن يوم بُنيت هذه
/// الحزمة، وفتحُ شاشةٍ خطأً أسوأ من ألّا نفتح شيئًا ([[ws-event-forward-compat]]).
void openNotificationTarget(
    BuildContext ctx, SessionController session, Map<String, String> data) {
  if (!session.isSignedIn) return;
  switch (data['type']) {
    case 'invite':
      final code = data['code'];
      final seat = int.tryParse(data['seat'] ?? '');
      if (code == null || code.isEmpty || seat == null) return;
      Navigator.of(ctx).push(MaterialPageRoute<void>(
        builder: (_) => OnlineGamePage(
          session: session.session!,
          initialInvite: (code: code, seat: seat),
        ),
      ));
    case 'friendRequest':
      Navigator.of(ctx).push(MaterialPageRoute<void>(
        builder: (_) => const FriendsScreen(),
      ));
    // «بطولةٌ تُجمَّع» و«دعوةُ شراكة» ⇒ شاشةُ البطولات (فيها التسجيلُ والقبول).
    case 'tournament':
      Navigator.of(ctx).push(MaterialPageRoute<void>(
        builder: (_) => const TournamentsScreen(),
      ));
    // `system`: رسالةُ الإدارة **نصٌّ يُقرأ في مكانه** — لا وجهةَ لها، ولمسُها
    // يُعلّمها مقروءةً وكفى.
  }
}

/// بوّابة الجذر: تُظهر شاشة تحميل حتى تُقرأ الإعدادات، ثم شاشة الاسم إن لزم، وإلا الرئيسية.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  /// **رسومُ الأوراق تُنتظَر هنا لا في `main`** — فالنافذةُ تُرسَم أوّلًا (خلفيّةُ
  /// المجلس) ثمّ يظهر المحتوى. هذا تحليلُ SVG في الذاكرة: Dart خالصٌ بلا قناةٍ
  /// أصليّة ⇒ لا يمكن أن يعلّق على منصّة ([AppBoot]).
  bool _artReady = false;

  @override
  void initState() {
    super.initState();
    AppBoot.instance.artReady().then((_) {
      if (mounted) setState(() => _artReady = true);
    });
  }

  bool _announced = false;

  /// تُطبَع مرّةً واحدةً في عمر العمليّة — إعلانٌ لا سجلٌّ دوريّ.
  void _announceReady() {
    if (_announced) return;
    _announced = true;
    debugPrint(uiReadyMarker);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final session = SessionScope.of(context);
    final t = BeloteTheme.of(context);
    if (!_artReady || !settings.loaded || !session.loaded) {
      return Scaffold(backgroundColor: t.bg, body: const SizedBox.shrink());
    }
    // **إثباتُ أنّ إطارًا حقيقيًّا رُسم** — يقرؤه مشغّلُ ماك (انظر [uiReadyMarker]).
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceReady());
    // غير مصادَقٍ وغير ضيف ⇒ بوّابة الدخول (تسجيل/إنشاء/ضيف). أوّل شاشة يراها اللاعب.
    if (!session.isSignedIn && !settings.isGuest) {
      return AuthLandingScreen(
        api: session.api,
        onAuthenticated: (s) => _onAuthenticated(context, s),
      );
    }
    void go(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    return HomeScreen(
      onPlay: () => go(const GamePage()),
      onOnline: () => _openOnline(context),
      onProfile: () => go(ProfileScreen(onSignIn: () => _pushAuth(context))),
      onLeaderboard: () => go(const LeaderboardScreen()),
      onStore: () => go(StoreScreen(session: session)),
      // **المهامّ تخصّ حسابًا**: تقدّمُها وجائزتُها في الخادم ⇒ الضيفُ يُدعى للدخول
      // بدل شاشةٍ فارغةٍ تقول «لا مهامّ» وهو لا يملك حسابًا أصلًا.
      onMissions: () => session.isSignedIn
          ? go(MissionsScreen(session: session))
          : _pushAuth(context),
      // VIP يخصّ حسابًا (اشتراكٌ ومزايا) ⇒ الضيفُ يُدعى للدخول لا يرى عرضًا لا يشتريه.
      onVip: () => session.isSignedIn
          ? go(VipScreen(session: session))
          : _pushAuth(context),
      onSettings: () => go(const SettingsScreen()),
      // البطولة تخصّ حسابًا (رسمٌ من محفظته وجائزةٌ إليها) ⇒ الضيفُ يُدعى للدخول.
      onTournaments: () => session.isSignedIn
          ? go(const TournamentsScreen())
          : _pushAuth(context),
      onFriends: () => go(const FriendsScreen()),
      onAbout: () => go(const AboutScreen()),
      // المشاهدة تخصّ حسابًا (القائمةُ خلف المصادقة، والهديّةُ من محفظته).
      onWatchLive: () => session.isSignedIn
          ? go(const LiveTablesScreen())
          : _pushAuth(context),
      // **الجرسُ يُعيد استعمال `_openFromPush` نفسِها**: حمولةُ الصندوق هي حمولةُ
      // الإشعار المدفوع حرفيًّا (الخادم يكتب واحدةً للاثنين)، فلمسةُ الصفّ تفعل ما
      // تفعله لمسةُ الشريط بالضبط. منطقان لوجهةٍ واحدةٍ يفترقان يومَ يُعدَّل أحدهما.
      onNotifications: () => go(NotificationsScreen(
          onOpen: (n) => openNotificationTarget(context, session, n.data))),
    );
  }

  /// مصادقةٌ ناجحة (دخول/إنشاء/استعادة): يحفظ الجلسة، يُلغي وضع الضيف، ويعود للرئيسية.
  Future<void> _onAuthenticated(BuildContext context, AuthSession s) async {
    final session = SessionScope.of(context);
    final settings = AppSettingsScope.of(context);
    await session.signIn(s);
    settings.setGuest(false);
    if (settings.needsName && s.player.displayName.isNotEmpty) {
      settings.setName(s.player.displayName); // مزامنة الاسم المحلّي مع الحساب
    }
    if (!context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    // **بعد العودة للرئيسيّة لا قبلها**: النافذةُ فوق شاشةٍ يبقى، وشاشةُ الإنشاء
    // تُغلَق من تحتها. و`isNew` من ردّ الخادم وحدَه ⇒ الدخولُ والاستعادةُ لا
    // يُظهرانها (كلاهما `isNew: false`)، وكذلك إعادةُ فتح التطبيق.
    if (context.mounted && s.isNew) {
      await showWelcomeGifts(context, gifts: s.welcomeGifts);
    }
  }

  /// مدخل الأونلاين: المصادَق ⇒ لصفحة اللعب مباشرة؛ الضيف ⇒ يُطلب منه إنشاء حساب.
  ///
  /// **ونفدت لعباتُه ⇒ عرضُ اليوم الكامل** قبل أن يفتح شيئًا: الخادمُ سيردّه على
  /// أيّ حال، ورفضٌ بعد انتظارٍ أسوأُ من عرضٍ فوريّ. والخادمُ يبقى الحَكَم — هذا
  /// طريقٌ سريعٌ لا بوّابة (عدّادُ العميل قد يكون بائتًا).
  Future<void> _openOnline(BuildContext context) async {
    final session = SessionScope.of(context);
    if (!session.isSignedIn) {
      _promptCreateAccount(context); // ضيف
      return;
    }

    final a = session.allowance;
    if (a != null && !a.canPlay) {
      final bought = await showPlayLimitOffer(
        context,
        session: session,
        onStore: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => StoreScreen(session: session),
        )),
      );
      // لم يشترِ ⇒ لا نفتح صفحةً يردّه الخادمُ منها.
      if (!bought || !context.mounted) return;
    }

    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => OnlineGamePage(session: session.session!),
    ));
    // **بعد اللعب**: لعبتُه استُهلكت خادميًّا، والعدّادُ على الرئيسيّة يبقى
    // كاذبًا حتى إعادة التشغيل بلا هذا. والمهامُّ تقدّمت كذلك ⇒ `refresh`
    // تجلب المحفظةَ والإحصاءَ والعدّادَ معًا.
    await session.refresh();

    // **ذروةُ الرغبة** ([[conversion-strategy]]): خرج توًّا من مباراةٍ ونفدت
    // لعباتُه — يريد أخرى **الآن**. عرضٌ هنا يُقرَأ، ونفسُه صباحًا يُغلَق.
    final after = session.allowance;
    if (context.mounted && after != null && !after.canPlay) {
      final bought = await showPlayLimitOffer(
        context,
        session: session,
        onStore: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => StoreScreen(session: session),
        )),
      );
      // اشترى ⇒ أعِده إلى اللعب فورًا؛ لا يُترَك أمام شاشةٍ بعد أن دفع.
      if (bought && context.mounted) await _openOnline(context);
    }
  }

  /// نافذةٌ تشرح للضيف أن الأونلاين يتطلّب حسابًا، ثمّ تفتح بوّابة الدخول.
  void _promptCreateAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اللعب أونلاين', textDirection: TextDirection.rtl),
        content: const Text(
          'أنشئ حسابًا للّعب مع لاعبين حقيقيّين وحفظ تقدّمك ورصيدك.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('لاحقًا')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _pushAuth(context);
            },
            child: const Text('إنشاء حساب'),
          ),
        ],
      ),
    );
  }

  /// يفتح بوّابة الدخول فوق الرئيسية (لضيفٍ يريد حسابًا أو للتسجيل من الملف الشخصي).
  void _pushAuth(BuildContext context) {
    final session = SessionScope.of(context);
    if (session.isSignedIn) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AuthLandingScreen(
        api: session.api,
        onAuthenticated: (s) => _onAuthenticated(context, s),
      ),
    ));
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final GameController _controller = GameController(
    onSound: Sfx.instance.play,
    aiFoujaChance: 0.06, // خصمٌ آليّ يفوّج نادرًا كي يجد اللاعب ما يكتشفه
    aiAccuseChance: 0.5, // احتمال أن يكتشف الخصم فوجتك فيعترض
    aiAccuseDelay: const Duration(milliseconds: 1300), // «تفكير» قبل اعتراضه
    resultHold: const Duration(seconds: 3), // عرض نتيجة الجولة ثم تقدّم تلقائي
    humanTurnLimit: const Duration(seconds: 15), // مهلة دورك ثم يلعب الذكاء مكانك
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final settings = AppSettingsScope.of(context);
    final playerName = (session.player?.displayName.isNotEmpty ?? false)
        ? session.player!.displayName
        : (settings.name.isNotEmpty ? settings.name : 'أنت');
    // بطاقتك على المقعد 0 باسمك وتصنيفك؛ والمقاعد 1..3 ذكاءٌ بأسماء ثابتة.
    final base = _controller.seatPlayers;
    final seats = [
      base[0].copyWith(name: playerName, rating: session.stats?.rating),
      base[1],
      base[2],
      base[3],
    ];
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => TableScreen(
        view: _controller.tableView,
        bidBar: _controller.bidBar,
        result: _controller.roundResult,
        seats: seats,
        onBid: _controller.placeBid,
        onPlayCard: _controller.playCard,
        onNewMatch: _controller.newMatch,
        // لحظاتُ المباراة أوفلاينَ أيضًا — نفسُ حساب الخادم في المحرّك.
        summary: _controller.matchSummary,
        onStartFoujaClaim: _controller.startFoujaClaim,
        onCancelFoujaClaim: _controller.cancelFoujaClaim,
        onAccuseFouja: _controller.accuseFouja,
        onTurnTick: () => Sfx.instance.play(GameSound.turnTick),
      ),
    );
  }
}
