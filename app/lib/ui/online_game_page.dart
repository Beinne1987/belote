import 'package:flutter/material.dart';

import '../game/online_game_controller.dart';
import '../game/view_model.dart';
import '../motion.dart';
import '../net/api_client.dart';
import '../platform/app_platform.dart';
import '../net/presence_link.dart';
import '../net/session_controller.dart';
import '../net/api_config.dart';
import '../net/table_client.dart';
import '../sfx.dart';
import '../theme/belote_theme.dart';
import '../voice/voice_controller.dart';
import 'chat_sheet.dart';
import 'dm_screen.dart' show showReportDialog;
import 'gift_picker.dart' show giftEmoji, showGiftSheet;
import 'lobby_table.dart';
import 'player_sheet.dart';
import 'table_screen.dart';

/// صفحة اللعب أونلاين: تدير دورة الاتصال بالكامل — قائمة المطابقة، اللوبي، الطاولة
/// (بإعادة استخدام [TableScreen])، والأخطاء. تُنشئ [OnlineGameController] من توكن الجلسة.
class OnlineGamePage extends StatefulWidget {
  final AuthSession session;

  /// حقنٌ للاختبار — الإنتاج يبني الكنترولر من التوكن (WS حقيقيّ).
  final OnlineGameController Function()? controllerFactory;

  /// حقنٌ للاختبار — الإنتاج يبني حالة صوتٍ حقيقيّةً فوق لايف كيت.
  final VoiceController Function()? voiceFactory;

  /// حقنٌ للاختبار — عميلُ الأصدقاء في اللوبي (منتقي الدعوة).
  final ApiClient? apiForFriends;

  /// دعوةٌ وصلت **إشعارًا** خارج التطبيق: رمزُ الطاولة والمقعد. غير null ⇒ ننضمّ
  /// إليها فور الاتّصال. بلا هذا تفتح اللمسةُ قائمةً رئيسيّةً يتيه فيها المدعوّ
  /// وقد تبدأ الطاولةُ قبل أن يجدها.
  final ({String code, int seat})? initialInvite;

  /// **مشاهدة** ([[spectator-system]]): غير null ⇒ الصفحةُ مدرّجاتٌ على هذه
  /// الطاولة — لا لوبي ولا نيّاتِ لعب، والهديّةُ وحدها متاحة.
  final String? spectateTableId;

  const OnlineGamePage({
    super.key,
    required this.session,
    this.controllerFactory,
    this.voiceFactory,
    this.apiForFriends,
    this.initialInvite,
    this.spectateTableId,
  });

  @override
  State<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends State<OnlineGamePage> {
  late final OnlineGameController _c;
  late final VoiceController _voice;
  final _codeCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _voice = widget.voiceFactory?.call() ??
        VoiceController(api: ApiClient(), authToken: widget.session.token);
    _c = widget.controllerFactory?.call() ??
        OnlineGameController(
          LiveTableClient.connect(
            ApiConfig.current.ws('/ws', {'token': widget.session.token}),
          ),
          spectateTableId: widget.spectateTableId,
          onSound: Sfx.instance.play, // صوت لعب الورق والتوزيع كالأوفلاين
          dealAnim: Motion.dealRest, // نافذة توزيع
          collectAnim: Motion.pliCollect, // جمع الأخذة نحو الفائز
          trickPause: Motion.pliPause, // رؤية الورقة الأخيرة قبل الجمع (كالأوفلاين)
          bidHold: Motion.bidBubbleHold, // مسك فقاعات الضمانة لتُقرأ
          settle: Motion.pliSettle, // استقرارٌ قصير بعد الجمع
          cardLandDelay: Motion.slideCard, // صوت اللعب لحظةَ هبوط الورقة
          playStagger: Motion.onlinePlayStagger, // تفريق ظهور اللعبات المتراكمة
          resultHold: const Duration(seconds: 3), // وقفة نتيجة الجولة (كالأوفلاين)
          reactionHold: Motion.reactionHold, // بقاء فقاعة الإيموجي فوق البطاقة
        );
    // دعوةٌ من إشعار ⇒ اجلس في مقعدها مباشرة. **الفشل مسموعٌ لا صامت**: طاولةٌ
    // امتلأت أو بدأت تردّ `join_failed` فيراها المدعوّ رسالةً مفهومة.
    final inv = widget.initialInvite;
    if (inv != null) _c.joinByCode(inv.code, seat: inv.seat);
  }

  /// قناةُ الحضور العامّة — تُوقَف ما دامت هذه الشاشة مفتوحة: قناتُها تكفي
  /// للحضور، وقناتان تعنيان دعوةً تظهر لافتةً هنا ونافذةً فوقها.
  PresenceLink? _presence;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_presence != null) return; // مرّةً واحدة (تتكرّر عند كل تغيّر تبعيّة)
    _presence = PresenceScope.maybeOf(context)?..pause();
  }

  @override
  void dispose() {
    _presence?.resume(); // عادت الشاشةُ ⇒ عاد الحضورُ العامّ
    _voice.dispose(); // مغادرة الطاولة تُغلق غرفة الصوت والميكروفون
    _c.dispose();
    _codeCtl.dispose();
    super.dispose();
  }

  /// **رموزُ ألقاب من على الطاولة** — من خريطة الجلسة (خمسةُ حاملين على الأكثر
  /// في العالم كلِّه). فارغةٌ ⇒ لا شارة. [[honors-weekly]]
  Map<String, String> get _honorEmojis {
    final honors = SessionScope.of(context).honors;
    final out = <String, String>{};
    for (final id in _c.seatPlayerIds) {
      if (id == null) continue;
      final emoji = honors.categoryById(honors.topTitleOf(id))?.emoji;
      if (emoji != null && emoji.isNotEmpty) out[id] = emoji;
    }
    return out;
  }

  /// بلاغٌ/حظرٌ من لوحة دردشة الطاولة — على رسالةِ بشريٍّ غيري (ضغطةٌ مطوّلة).
  Future<void> _reportChatEntry(ChatLogEntry entry) async {
    final senderId = entry.senderId;
    if (senderId == null) return;
    final seats = _c.seatPlayers;
    final name = entry.viewSeat < seats.length ? seats[entry.viewSeat].name : 'لاعب';
    final api = widget.apiForFriends ?? ApiClient();
    final token = widget.session.token;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: BeloteTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final t = BeloteTheme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.flag_outlined, color: t.text2),
                title: Text('بلاغ عن $name', style: TextStyle(color: t.text)),
                onTap: () => Navigator.pop(ctx, 'report'),
              ),
              ListTile(
                leading: Icon(Icons.block, color: t.error),
                title: Text('حظر $name', style: TextStyle(color: t.error)),
                subtitle: Text('لا يصلك كلامه، ولا يراسلك ولا يدعوك.',
                    style: TextStyle(color: t.text3, fontSize: 12)),
                onTap: () => Navigator.pop(ctx, 'block'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'report') {
      final sent = await showReportDialog(
        context,
        api: api,
        token: token,
        playerId: senderId,
        playerName: name,
        area: 'chat',
      );
      if (sent && mounted) _snack('وصل بلاغك — سيُراجَع.');
    } else if (action == 'block') {
      try {
        await api.blockPlayer(token, senderId);
        if (mounted) _snack('حُظر $name — لن يصلك كلامه.');
      } catch (_) {
        if (mounted) _snack('تعذّر الحظر — تحقّق من الاتّصال.');
      }
    }
  }

  /// **لوحةُ جليسٍ على الطاولة** — تُفتَح بالضغط على بطاقته. الجالسُ والمشاهدُ
  /// سواءٌ فيها: كلاهما يرى مَن يلعب ويصادقه ([[spectator-system]]).
  void _openPlayerSheet(int viewSeat) {
    final seats = _c.seatPlayers;
    if (viewSeat < 0 || viewSeat >= seats.length) return;
    final p = seats[viewSeat];
    if (p.playerId.isEmpty) return; // ذكاءٌ أو مقعدٌ فارغ — لا ملفَّ خلفه
    showPlayerSheet(
      context,
      api: widget.apiForFriends ?? ApiClient(),
      token: widget.session.token,
      playerId: p.playerId,
      name: p.name,
      avatarUrl: p.avatarUrl,
      // **الكتمُ عند بطاقته** — الطاولةُ مسمعٌ واحدٌ للجميع (لا قناةَ فريق)،
      // فعلاجُ الإزعاج أن تكتم من يزعجك حيث تراه. يُخفى إن كان الصوت مُطفأً.
      isMuted: () => _voice.isMuted(p.playerId),
      onToggleMute: _voice.mode == VoiceMode.off
          ? null
          : () => _voice.toggleMute(p.playerId),
      // **الإهداءُ من داخل اللوحة**: رأى ملفَّه فأعجبه ⇒ الطريقُ إلى الهديّة
      // خطوةٌ واحدة، لا رجوعٌ وبحثٌ عن اسمه في قائمةٍ أخرى.
      onGift: () => showGiftSheet(
        context,
        targets: [(viewSeat: viewSeat, player: p)],
        onSend: _c.sendGift,
        stock: SessionScope.of(context).giftStock,
        vipStock: SessionScope.of(context).vipGiftStock,
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));

  /// العودة إلى الرئيسية (مغادرة الأونلاين). **لا تسجيلَ خروجٍ من الحساب** — تبقى الجلسة
  /// قائمةً، فلا يُقذَف اللاعب إلى شاشة الدخول ثم يخرج من التطبيق عند الرجوع مجدّدًا
  /// (كان ذلك سبب «الخروج من التطبيق» عند الرجوع من الأونلاين). الاتصال يُغلَق في dispose.
  Future<void> _back() async {
    if (mounted) Navigator.of(context).maybePop();
  }

  /// مغادرةُ المشاهدة: نيّةُ `spectateStop` (تُنزل العدّاد فورًا) ثم رجوع —
  /// إغلاقُ القناة في dispose يتكفّل بالباقي.
  void _leaveSpectate() {
    _c.stopSpectating();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // حالة الصوت تُغيّر الواجهة أيضًا (شارة المتكلّم، حال الاتّصال) ⇒ استمعْ للاثنين.
      listenable: Listenable.merge([_c, _voice]),
      builder: (context, _) {
        final spectating = _c.isSpectator;
        final Widget body = switch (_c.stage) {
          // متفرّج: الطاولةُ نفسُها لكن **قراءةً** — لا ضمانة ولا لعب ولا فوجة ولا
          // دردشة/صوت (الخادم يُسقطها أصلًا)؛ الهديّةُ وحدها بابُ التفاعل (والربح).
          OnlineStage.playing when spectating => TableScreen(
              view: _c.tableView!,
              result: _c.roundResult,
              seats: _c.seatPlayers,
              reactions: _c.reactions,
              chats: _c.chats,
              gifts: _c.gifts,
              // المشاهدُ يرى الرحلةَ كما يراها الجالس — نفس الحدث ونفس اللحظة.
              giftFlight: _c.giftFlight,
              spectator: true,
              onGift: _c.sendGift,
              giftStock: SessionScope.of(context).giftStock,
              vipGiftStock: SessionScope.of(context).vipGiftStock,
              vipRoom: _c.vipRoom,
              seatPlayerIds: _c.seatPlayerIds,
              honorEmojis: _honorEmojis,
              onPlayerTap: _openPlayerSheet,
              // انتهت المباراة ⇒ لا «مباراة جديدة» للمتفرّج: خروجٌ إلى القائمة.
              onNewMatch: _leaveSpectate,
              onExit: _leaveSpectate,
            ),
          OnlineStage.playing => TableScreen(
              view: _c.tableView!,
              bidBar: _c.bidBar,
              result: _c.roundResult,
              seats: _c.seatPlayers,
              rating: _c.rating?.rating, // مصنّفة فقط (٤ بشر) ⇒ null غيرها
              ratingDelta: _c.rating?.delta,
              rank: _c.rating?.skill,
              // الملخّصُ لكلّ مباراةٍ انتهت — مصنّفةً كانت أو مع ذكاء.
              summary: _c.matchSummary,
              reactions: _c.reactions,
              chats: _c.chats,
              gifts: _c.gifts,
              giftFlight: _c.giftFlight,
              onReact: _c.react,
              // لوحةُ الدردشة (نصٌّ حرٌّ + ردودٌ جاهزة): الصفحةُ هي الجسر بين
              // الشاشة (عرضٌ محض) والكنترولر (سجلٌّ وإرسال).
              onOpenChat: () => showChatSheet(
                context,
                listenable: _c,
                log: () => _c.chatLog,
                seats: () => _c.seatPlayers,
                onPhrase: _c.chat,
                onText: _c.chatText,
                // ضغطةٌ مطوّلة على رسالة غيري ⇒ بلاغ/حظر (إلزام المتاجر: البلاغ
                // حيث يُرى المحتوى — دردشةُ الطاولة نصٌّ حرٌّ بلا مرشّح).
                onReportEntry: _reportChatEntry,
              ),
              onGift: _c.sendGift,
              // المخزونُ من الجلسة: الطاولةُ لا تعرف المحفظةَ ولا الشبكة، وهذه
              // الصفحةُ هي الجسر. `SessionScope` يُعيد البناءَ عند تغيّر الرصيد ⇒
              // هديّةٌ تخرج من المخزون يقلّ عدادُها في اللوحة فورًا.
              giftStock: SessionScope.of(context).giftStock,
              vipGiftStock: SessionScope.of(context).vipGiftStock,
              // **الغرفةُ من اللوبي لا من الجلسة**: خلفيّةُ **المضيف** لا خلفيّتي
              // ⇒ يراها الجميع، ولا يراها المشتركُ في غرفة غيره.
              vipRoom: _c.vipRoom,
              onBid: _c.placeBid,
              onPlayCard: _c.playCard,
              onNewMatch: _c.newMatch, // انتهاء المباراة ⇒ العودة للمطابقة
              onStartFoujaClaim: _c.startFoujaClaim,
              onCancelFoujaClaim: _c.cancelFoujaClaim,
              onAccuseFouja: _c.accuseFouja,
              onTurnTick: () => Sfx.instance.play(GameSound.turnTick),
              // **لا صوتَ على سطح المكتب**: طلبُ إذن الميكروفون يمرّ بـ
              // `permission_handler` — ولا تنفيذَ له على ماك، فالضغطُ يرمي
              // `MissingPluginException`. `null` هنا يُخفي الميكروفونَ والكتمَ
              // من كلّ المقاعد بلا شرطٍ ثانٍ في الودجت.
              voice: AppPlatform.voice ? _voice : null,
              seatPlayerIds: _c.seatPlayerIds,
              honorEmojis: _honorEmojis,
              onPlayerTap: _openPlayerSheet,
              // خروجٌ من الطاولة إلى الرئيسية (لا تسجيل خروج) — يُغلق الاتصال في dispose.
              onExit: () => Navigator.of(context).maybePop(),
            ),
          OnlineStage.error => _ErrorView(code: _c.errorCode!, onBack: _back),
          // متفرّجٌ قبل أوّل لقطة (يمرّ باللوبي لحظةً — منه هويّاتُ المقاعد).
          OnlineStage.menu || OnlineStage.lobby when spectating =>
            const _SpectateLoading(),
          OnlineStage.lobby => _LobbyView(
              controller: _c,
              onLogout: _back,
              api: widget.apiForFriends ?? ApiClient(),
              token: widget.session.token,
            ),
          OnlineStage.menu =>
            _MenuView(controller: _c, codeCtl: _codeCtl, onLogout: _back),
        };
        // الدعوة الواردة تعلو **كلَّ** شاشة: قد تصلك وأنت في القائمة أو اللوبي أو
        // وسط مباراة. لافتةٌ لا نافذةٌ حاجبة — لا تُوقف لعبًا جاريًا لأجل دعوة.
        final invite = _c.invite;
        final notice = _c.notice;
        final standsGift = _c.standsGiftLabel;
        return Stack(
          children: [
            body,
            // شارةُ الجمهور: تظهر للجالس والمتفرّج متى وُجد مشاهدون — الجمهورُ
            // الظاهرُ هو ما يجعل هديّةَ الاستعراض تساوي ثمنها.
            if (_c.stage == OnlineStage.playing &&
                (_c.watchers > 0 || spectating))
              _WatchersChip(count: _c.watchers, spectating: spectating),
            // لافتةُ هديّة المدرّجات: باسم راميها — الاسمُ هو الاستعراض.
            if (standsGift != null && _c.standsGift != null)
              _StandsGiftBanner(
                  label: standsGift, giftId: _c.standsGift!.gift),
            if (_c.reconnecting) const _ReconnectingBanner(),
            // خبرٌ عابر (دعوةٌ لم تصل · هديّةٌ رُفضت): يعلو الطاولة ولا يهدمها.
            if (notice != null)
              _NoticeBanner(code: notice, onDismiss: _c.dismissNotice),
            if (invite != null)
              _InviteBanner(
                invite: invite,
                onAccept: _c.acceptInvite,
                onDismiss: _c.dismissInvite,
              ),
          ],
        );
      },
    );
  }
}

/// شارةٌ علويّة تظهر أثناء إعادة الاتصال (فوق أي شاشة، دون حجب اللعب المعروض).
/// شريطُ الخبر العابر — فشلُ دعوةٍ أو هديّة. **لا يمسّ الطاولة**: تبقى تحته حيّةً
/// ويمضي وحده بعد ثوانٍ (أو بلمسة).
class _NoticeBanner extends StatelessWidget {
  final String code;
  final VoidCallback onDismiss;
  const _NoticeBanner({required this.code, required this.onDismiss});

  /// رسالةٌ **لكلّ رمزٍ يبثّه الخادم فعلًا** (`ws.dart`) — يحرسها
  /// `test/online_error_test.dart` من الانجراف. تقول للاعب **ما العمل**، لا
  /// «حدث خطأ»: مَن دعا صديقًا غائبًا يحتاج أن يعرف أنّه غائبٌ لا أنّ شيئًا انكسر.
  static const _messages = {
    // ليس «غير متّصل» وحدَه: غيرُ المتّصل تصله الدعوةُ إشعارًا. هذا الخطأ لمن
    // **لا إشعارَ له** (رفض الإذن أو لم يفتح التطبيق بعد التحديث).
    'invite_offline': 'صديقك غير متّصل ولا تصله الإشعارات — لن يعلم بدعوتك حتى يفتح اللعبة.',
    'invite_notFriend': 'أضِفه صديقًا أوّلًا لتدعوه.',
    'invite_seatTaken': 'المقعد شُغل — اختر غيره.',
    'invite_started': 'المباراة بدأت — لا يمكن دعوة أحدٍ الآن.',
    'invite_notPrivate': 'الدعوة للطاولة الخاصّة فقط — أنشئ واحدةً ثمّ ادعُه.',
    'gift_insufficient': 'ماسك لا يكفي لهذه الهديّة.',
    'gift_notOnTable': 'لم يعد على الطاولة.',
    'gift_self': 'لا تُهدي نفسك.',
    'gift_unknownGift': 'هذه الهديّة لم تعد متاحة.',
    // **هدايا VIP**: رصيدٌ يوميٌّ لا ثمنٌ بالماس ⇒ رسائلُها تشرح الرصيدَ لا المال.
    'vipgift_empty': 'نفدت هدايا VIP اليوم — تعود ثلاثٌ غدًا.',
    'vipgift_notVip': 'هذه الهدايا لمشتركي VIP.',
    'vipgift_unknownGift': 'هذه الهديّة لم تعد متاحة.',
    // **صمّامُ الدعوة**: صديقٌ دعوتَه انضمّ ⇒ نلتَ لعبةً اليوم. خبرٌ سارٌّ لا خطأ،
    // ويستعمل نفسَ الشريط العابر.
    'inviteReward': 'صديقُك انضمّ — نلتَ لعبةً إضافيّةً اليوم! 🎉',
  };

  static String textFor(String code) =>
      _messages[code] ?? 'تعذّر تنفيذ ما طلبت — حاول مرّةً أخرى.';

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.warning),
                  boxShadow: [BoxShadow(color: t.shadow, blurRadius: 12)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: t.warning, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        textFor(code),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: t.text, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// شارةُ الجمهور فوق الطاولة: «👁 N» — وللمتفرّج «أنت تشاهد» معها. أعلى اليسار
/// كي لا تزاحم لافتات أعلى الوسط (خبر/دعوة/إعادة اتصال).
class _WatchersChip extends StatelessWidget {
  final int count;
  final bool spectating;
  const _WatchersChip({required this.count, required this.spectating});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return SafeArea(
      child: Align(
        alignment: AlignmentDirectional.topStart,
        child: Container(
          margin: const EdgeInsetsDirectional.only(start: 12, top: 52),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: t.accentBright),
              const SizedBox(width: 5),
              Text(
                // الأرقام لاتينيّةٌ دائمًا ([[latin-digits-ui]]).
                spectating ? 'تشاهد · $count' : '$count',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    color: t.text, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// لافتةُ هديّةٍ من المدرّجات: «فلان أهدى علّانًا 🌹» — الاسمُ هو الاستعراضُ الذي
/// دُفع ثمنُه، فيُعرَض للجميع لحظاتٍ ثم يمضي.
class _StandsGiftBanner extends StatelessWidget {
  final String label;
  final String giftId;
  const _StandsGiftBanner({required this.label, required this.giftId});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 120, left: 24, right: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: t.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.accent),
            boxShadow: [BoxShadow(color: t.shadow, blurRadius: 12)],
          ),
          child: Text(
            '$label ${giftEmoji(giftId) ?? '🎁'}',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: t.text, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// انتظارُ أوّل لقطةِ مشاهدة (لحظاتٌ بين النيّة واللقطة).
class _SpectateLoading extends StatelessWidget {
  const _SpectateLoading();

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return _Gradient(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3, color: t.accent),
            ),
            const SizedBox(height: 20),
            Text('جاري الدخول إلى المدرّجات…',
                style: TextStyle(
                    color: t.text, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ReconnectingBanner extends StatelessWidget {
  const _ReconnectingBanner();
  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.warning),
            boxShadow: [BoxShadow(color: t.shadow, blurRadius: 12)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: t.warning),
              ),
              const SizedBox(width: 8),
              Text('إعادة الاتصال…',
                  style: TextStyle(color: t.text, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// خلفيّة متدرّجة موحّدة لشاشات ما قبل الطاولة.
class _Gradient extends StatelessWidget {
  final Widget child;
  const _Gradient({required this.child});
  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.gradTop, t.gradBottom],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

/// قائمة المطابقة: لعب سريع · طاولة خاصّة · انضمام برمز.
class _MenuView extends StatelessWidget {
  final OnlineGameController controller;
  final TextEditingController codeCtl;
  final Future<void> Function() onLogout;
  const _MenuView({required this.controller, required this.codeCtl, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return _Gradient(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Row(
              children: [
                Text('اللعب أونلاين',
                    style: TextStyle(color: t.text, fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  onPressed: onLogout,
                  tooltip: 'خروج',
                  icon: Icon(Icons.logout, color: t.text2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _BigAction(
              icon: Icons.bolt,
              title: 'لعب سريع',
              subtitle: 'اجلس على أول طاولة متاحة مع لاعبين',
              onTap: controller.quickMatch,
            ),
            const SizedBox(height: 12),
            _BigAction(
              icon: Icons.add_circle_outline,
              title: 'إنشاء طاولة خاصّة',
              subtitle: 'ادعُ أصدقاءك برمز الطاولة',
              onTap: controller.createPrivate,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: codeCtl,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: t.text, fontSize: 18, letterSpacing: 3),
              cursorColor: t.accent,
              decoration: InputDecoration(
                hintText: 'رمز الطاولة',
                hintStyle: TextStyle(color: t.text3),
                filled: true,
                fillColor: t.surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: t.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: t.accent, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final code = codeCtl.text.trim();
                  if (code.isNotEmpty) controller.joinByCode(code);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: t.text,
                  side: BorderSide(color: t.line),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('انضمام برمز'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// اللوبي بعد الجلوس: المقاعد الأربعة + زرّ البدء + رمز الطاولة إن خاصّة.
class _LobbyView extends StatefulWidget {
  final OnlineGameController controller;
  final Future<void> Function() onLogout;

  /// حقنٌ للاختبار؛ الإنتاج يقرأ من الجلسة.
  final ApiClient? api;
  final String? token;

  const _LobbyView({
    required this.controller,
    required this.onLogout,
    this.api,
    this.token,
  });

  @override
  State<_LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends State<_LobbyView> {
  OnlineGameController get controller => widget.controller;
  List<FriendPlayer> _friends = const [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  /// أصدقائي — لمنتقي الدعوة. الفشل يُترك صامتًا: اللوبي يعمل بلا أصدقاء (رمزُ
  /// الطاولة يبقى سبيلًا)، فلا نُفزع اللاعب بخطأ شبكةٍ لا يمنعه من اللعب.
  Future<void> _loadFriends() async {
    final token = widget.token;
    final api = widget.api;
    if (token == null || api == null) return;
    try {
      final lists = await api.friends(token);
      if (mounted) setState(() => _friends = lists.friends);
    } on ApiException {
      /* لا شيء — انظر أعلاه */
    }
  }

  /// مقاعد اللوبي بترتيب **العرض** (0 = أنا). null ⇒ فارغ.
  List<LobbySeat?> _viewSeats(LobbyEvent lobby) {
    final out = List<LobbySeat?>.filled(4, null);
    final me = lobby.you ?? 0;
    for (final s in lobby.seats) {
      if (s.ai) continue; // في اللوبي `ai:true` تعني «فارغ» (يملؤه الذكاء عند البدء)
      out[(s.seat - me + 4) % 4] = s;
    }
    return out;
  }

  /// يستعمل `context` الحالة (لا مُمرَّرًا) بعد الـ await: `mounted` يحرس الأوّل
  /// وحده — وهذا ما نبّه إليه المحلّل.
  Future<void> _invite(int viewSeat) async {
    final friend = await pickFriendForSeat(
      context,
      friends: _friends,
      seatRole: viewSeat == 2 ? 'شريكًا لك' : 'خصمًا لك',
    );
    if (friend == null || !mounted) return;
    controller.inviteToSeat(friend.id, viewSeat);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('دُعي ${friend.displayName}', textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final lobby = controller.lobby!;
    final isPrivate = lobby.code != null;
    final humans = lobby.seats.where((s) => !s.ai).length;
    return _Gradient(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Row(
              children: [
                Text(isPrivate ? 'طاولة خاصّة' : 'مطابقة سريعة',
                    style: TextStyle(color: t.text, fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  onPressed: widget.onLogout,
                  tooltip: 'خروج',
                  icon: Icon(Icons.logout, color: t.text2),
                ),
              ],
            ),
            if (isPrivate) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.accent),
                ),
                child: Text('الرمز: ${lobby.code}',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: t.accentBright, fontWeight: FontWeight.w800, letterSpacing: 2)),
              ),
            ],
            const SizedBox(height: 20),
            // خاصّة: تُعرَض المقاعد (يرى المضيف من انضمّ بالرمز) ويبدأ يدويًّا.
            // عامّة (مطابقة سريعة): لا نكشف مقاعد الذكاء — شاشة بحثٍ تجعل الانتظار
            // يبدو مطابقةً حقيقية، ثم يدخل اللاعب الطاولة مباشرةً عند البدء تلقائيًّا.
            if (isPrivate) ...[
              // **الطاولة لا القائمة**: الموضع يقول من الشريك ومن الخصم.
              Expanded(
                child: LobbyTable(
                  seats: _viewSeats(lobby),
                  onInvite: _invite,
                ),
              ),
              // البحث حالٌ لا زرّ: الضغط ثانيةً لا يُسرّعه، وإتاحتُه تدعو للنقر عبثًا.
              if (lobby.searching)
                const _SearchingForPlayers()
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.start,
                    style: FilledButton.styleFrom(
                      backgroundColor: t.accent,
                      foregroundColor: t.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('ابدأ المباراة',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
            ] else
              Expanded(child: _Matchmaking(humans: humans)),
          ],
        ),
      ),
    );
  }

}

/// شاشة «جاري البحث عن لاعبين» للمطابقة السريعة — تُخفي وجود الذكاء تمامًا: يشعر
/// اللاعب أنه في مطابقةٍ حقيقية، وعند انتهاء المهلة تبدأ المباراة ويملأ الخادمُ
/// الفراغَ ذكاءً بلا أيّ إشارةٍ إلى ذلك.
class _Matchmaking extends StatelessWidget {
  final int humans; // اللاعبون الحقيقيّون على الطاولة الآن (بمن فيهم أنت)
  const _Matchmaking({required this.humans});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 3, color: t.accent),
          ),
          const SizedBox(height: 24),
          Text('جاري البحث عن لاعبين…',
              style: TextStyle(color: t.text, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 10),
          Text('نبحث لك عن منافسين على الطاولة',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.text2, fontSize: 13.5)),
          const SizedBox(height: 20),
          // نقاطٌ تمثّل اللاعبين الحاضرين (بلا تسمية «ذكاء»): تُضيء بحضور لاعبٍ حقيقيّ.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    i < humans ? Icons.person : Icons.person_outline,
                    color: i < humans ? t.accentBright : t.text3,
                    size: 22,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شاشة خطأ الخادم/الاتصال برسالةٍ عربيّة.
class _ErrorView extends StatelessWidget {
  final String code;
  final Future<void> Function() onBack;
  const _ErrorView({required this.code, required this.onBack});

  static const _messages = {
    'server_full': 'الخوادم ممتلئة الآن — حاول بعد قليل.',
    // المشاهدة ([[spectator-system]]).
    'spectate_unavailable': 'انتهت هذه المباراة أو لم تعد متاحة للمشاهدة.',
    'spectate_seated': 'أنت على طاولةٍ الآن — غادرها ثم شاهد.',
    // **يقول له ما العمل**: «نفدت لعباتُك» وحدَها بابٌ مغلقٌ بلا مفتاح. والأوفلاين
    // حرٌّ بلا حدّ ⇒ هو المخرجُ الصادقُ اليوم (والتذكرةُ وVIP يأتيان).
    'play_limit': 'انتهت لعباتُك اليوم — تعود غدًا. والعبُ مع الذكاء بلا حدود.',
    'join_failed': 'تعذّر الانضمام — تحقّق من الرمز.',
    'no_seat': 'لا مقعد متاح على هذه الطاولة.',
    'unauthorized': 'انتهت الجلسة — سجّل الدخول من جديد.',
    'connection': 'انقطع الاتصال بالخادم.',
  };

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return _Gradient(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: t.error, size: 48),
              const SizedBox(height: 12),
              Text(_messages[code] ?? 'حدث خطأ غير متوقّع.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.text, fontSize: 16)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onBack,
                style: FilledButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.onAccent,
                ),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة إجراء كبيرة في قائمة المطابقة.
class _BigAction extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _BigAction(
      {required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [t.surface2, t.surface],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: t.accent, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.accent.withValues(alpha: 0.16),
                  border: Border.all(color: t.accent.withValues(alpha: 0.5)),
                ),
                child: Icon(icon, color: t.accentBright, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: t.text2, fontSize: 12.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: t.text3),
            ],
          ),
        ),
      ),
    );
  }
}


/// دعوةٌ واردةٌ من صديق — **لافتةٌ لا نافذة**: قد تصل وسط مباراةٍ جارية، وحجبُ
/// الشاشة حينها يخسر دورًا لأجل دعوةٍ قد تُرفض.
///
/// تقول **الموضع** لا «انضمّ» وحدها: «شريكًا لك» تختلف عن «خصمًا لك» — وهي كلُّ
/// المعنى في دعوةٍ إلى مقعدٍ بعينه.
class _InviteBanner extends StatelessWidget {
  final InviteEvent invite;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _InviteBanner({
    required this.invite,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.accent),
            boxShadow: [BoxShadow(color: t.shadow, blurRadius: 16)],
          ),
          child: Row(
            children: [
              Icon(Icons.mail, color: t.accentBright, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${invite.fromName} يدعوك إلى طاولته',
                  style: TextStyle(
                      color: t.text, fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: onDismiss,
                child: Text('لاحقًا', style: TextStyle(color: t.text3)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    foregroundColor: t.onAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: onAccept,
                child: const Text('انضمّ',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// «نبحث عن لاعبين» — حالُ الطاولة الخاصّة بعد «ابدأ» وفيها فراغ.
///
/// **لا نَعِد بما لا نضمن**: لا نقول «سنجد لك لاعبين»، بل نقول ما سيقع يقينًا —
/// نبحث، وإن لم نجد بدأنا. اللاعب الذي وُعد ببشرٍ فجاءه ذكاءٌ يشعر أنّه خُدع؛
/// والذي قيل له الحقيقة يرضى بها. (وشاشةُ المطابقة السريعة تُخفي الذكاء عمدًا —
/// الفرق أنّ هذه طاولتُه هو، اختار مقاعدها بنفسه، فالصدق فيها ممكنٌ بلا كلفة.)
class _SearchingForPlayers extends StatelessWidget {
  const _SearchingForPlayers();

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: t.accentBright),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'نبحث عن لاعبين للمقاعد الفارغة… وإن لم نجد بدأنا بلاعبي الذكاء.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.text2, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
