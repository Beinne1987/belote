import 'dart:async';
import 'dart:math' as math;

import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;

import '../game/seat_player.dart';
import '../game/view_model.dart';
import '../net/player_rank.dart';
import '../motion.dart';
import '../strings_ar.dart';
import '../theme/belote_theme.dart';
import '../voice/voice_controller.dart';
import 'bid_bar.dart';
import 'card_back.dart';
import 'card_face.dart';
import 'gift_picker.dart';
import 'gifts/gift_flight.dart';
import 'gifts/gift_flight_layer.dart';
import 'player_hand_fan.dart';
import 'player_seat_round.dart';
import 'quick_chat_picker.dart';
import 'reaction_picker.dart';
import 'result_panel.dart';
import 'table/table_surface.dart';
import 'table_controls.dart';
import 'table_metrics.dart';
import 'turn_clock.dart';
import 'vip_room.dart';

/// شاشة الطاولة. عرضٌ محض من [TableView]؛ اللمس يُبلَّغ عبر [onPlayCard].
///
/// هندسة المقاعد **عكس عقارب الساعة** (تصحيح صاحب المشروع):
///   0 أسفل → 1 يمين → 2 أعلى → 3 يسار.
/// الشريك (2) أمامك دائمًا. رغم أن المحرك يعرّف nextSeat=(s+1)%4، فالرسم
/// هنا يذهب يمينًا لا يسارًا — عكس عقارب الساعة.
class TableScreen extends StatelessWidget {
  final TableView view;
  final BidBarView? bidBar;
  final RoundResult? result;
  final void Function(Card card)? onPlayCard;
  final void Function(BidAction action)? onBid;
  final VoidCallback? onNewMatch;
  final VoidCallback? onStartFoujaClaim;
  final VoidCallback? onCancelFoujaClaim;
  final void Function(int accusedSeat)? onAccuseFouja;

  /// اسم اللاعب البشري (المقعد 0) — يظهر على بطاقته إن لم تُمرَّر [seats].
  final String? playerName;

  /// هويّات المقاعد الأربعة (اسم/تصنيف/مستوى/VIP/اتصال) بترتيب العرض 0..3.
  /// null ⇒ يُبنى نائبٌ من أسماء المقاعد الثابتة (توافقٌ خلفيّ للاختبارات).
  final List<SeatPlayer>? seats;

  /// خروجٌ من الطاولة (زرّ الخروج في شريط التحكّم). null ⇒ رجوعٌ عاديّ.
  final VoidCallback? onExit;

  /// تقييم ELO بعد المباراة وتغيّره — يُمرَّران إلى لوحة النتيجة. أونلاين **مصنّف
  /// فقط** (٤ بشر)؛ null في الأوفلاين ومباريات الذكاء.
  final int? rating;
  final int? ratingDelta;

  /// رتبةُ المهارة بعد المباراة و**لحظاتُها** — يُمرَّران إلى لوحة النتيجة.
  /// الملخّصُ يعمل أوفلاينَ وأونلاينَ معًا (حسابٌ واحدٌ في المحرّك)؛ الرتبةُ
  /// أونلاين مصنّفًا فقط.
  final PlayerRankView? rank;
  final MatchSummaryView? summary;

  /// الرمز الظاهر فوق كل مقعدٍ الآن (بترتيب العرض 0..3؛ null ⇒ لا فقاعة).
  /// أونلاين فقط — لا تفاعلات مع الذكاء في الأوفلاين.
  final List<String?>? reactions;

  /// إرسال تفاعل. null ⇒ يُخفى زرّ التفاعلات (الأوفلاين).
  final void Function(String emoji)? onReact;

  /// تكتكة عدّاد دورك في آخر ثوانيه — تُوصَل بالصوت من الصفحة. null ⇒ عدّادٌ صامت
  /// (وبلا مؤقّتات: تبقى اختبارات الودجت خاليةً من مؤقّتاتٍ معلّقة).
  final VoidCallback? onTurnTick;

  /// المحادثة الصوتيّة. null ⇒ **لا زرَّ ميكروفون تحت صورتي ولا كتمَ على المقاعد**
  /// (الأوفلاين: لا أحدَ لتكلّمه).
  final VoiceController? voice;

  /// معرّف لاعب كلّ مقعدٍ بترتيب العرض 0..3 (null للذكاء/الفارغ) — يربط المقعد بهويّته
  /// في غرفة الصوت، فتُعرف بطاقةُ من يتكلّم الآن. **وبه يُعرَف لقبُ الأسبوع** أيضًا.
  final List<String?>? seatPlayerIds;

  /// **ألقابُ الأسبوع**: `playerId` → رمزُ لقبه. فارغةٌ ⇒ لا شارات (أوفلاين أو
  /// خادمٌ أقدم). خريطةٌ لا حقلٌ في كلّ مقعد: حاملوها خمسةٌ في العالم كلِّه،
  /// والشاشةُ لا تعرف الشبكةَ ⇒ الصفحةُ تحقنها. [[honors-weekly]]
  final Map<String, String> honorEmojis;

  /// **نصّ** الدردشة الظاهر فقاعةً فوق كل مقعدٍ الآن (بترتيب العرض؛ null ⇒ لا
  /// فقاعة). محسومٌ في الكنترولر: عبارةٌ جاهزةٌ مُترجَمة أو نصٌّ حرٌّ حرفيّ.
  final List<String?>? chats;

  /// معرّف الهديّة الظاهرة فوق كل مقعدٍ الآن — **فوق المستقبِل** لا المُرسِل.
  final List<String?>? gifts;

  /// يفتح لوحةَ الدردشة (نصٌّ حرٌّ + ردودٌ جاهزة — `chat_sheet.dart`). الشاشةُ لا
  /// تعرف السجلَّ ولا الإرسال؛ الصفحةُ هي الجسر. null ⇒ يُخفى الزرّ (الأوفلاين).
  final VoidCallback? onOpenChat;

  /// إهداء صاحب مقعد العرض. null ⇒ يُخفى زرّ الهديّة (الأوفلاين).
  final void Function(int viewSeat, String giftId)? onGift;

  /// كم يملك من كلّ هديّةٍ (مخزون الباقات) — تُمرَّر من صفحة الأونلاين، فالطاولةُ
  /// لا تعرف الشبكةَ ولا المحفظة عمدًا. null ⇒ الثمنُ يُعرَض كما كان.
  final int Function(String giftId)? giftStock;

  /// رصيدُ هدايا VIP الحصريّة. صفرٌ ⇒ لا قسمَ لها (غيرُ مشترك).
  final int vipGiftStock;

  /// **غرفةُ VIP**: مضيفُها مشترك ⇒ خلفيّتُه الخاصّة بدل اللبّاد — **يراها كلُّ
  /// الجالسين** لا المشتركُ وحدَه (قرارُ المالك 2026-07-16): مزيّةٌ تُرى تُحفّز،
  /// ومزيّةٌ يراها صاحبُها وحدَه لا يعلم بها أحد.
  final bool vipRoom;

  /// **وضعُ المشاهدة** ([[spectator-system]]): أنا متفرّجٌ لا جالس ⇒ صاحبُ المقعد
  /// السفليّ (عرض 0) لاعبٌ حقيقيٌّ آخر — يدخل أهدافَ الهديّة، ولا يدَ تُرسَم لي.
  final bool spectator;

  /// **رحلةُ الهديّة الطائرة الآن** — يبثّها الكنترولر (طابورٌ واحدٌ للطاولة) وتنفّذها
  /// `GiftFlightLayer`. null ⇒ لا طبقةَ ولا مؤقّت (الأوفلاين دائمًا، والأونلاين بين
  /// الهدايا). الشاشةُ لا تعرف هديّةً من هديّة — تمرّرها كما وصلت.
  final GiftFlight? giftFlight;

  const TableScreen({
    super.key,
    required this.view,
    this.bidBar,
    this.result,
    this.onPlayCard,
    this.onBid,
    this.onNewMatch,
    this.onStartFoujaClaim,
    this.onCancelFoujaClaim,
    this.onAccuseFouja,
    this.playerName,
    this.seats,
    this.onExit,
    this.rating,
    this.ratingDelta,
    this.rank,
    this.summary,
    this.reactions,
    this.onReact,
    this.onTurnTick,
    this.voice,
    this.honorEmojis = const {},
    this.seatPlayerIds,
    this.chats,
    this.gifts,
    this.onOpenChat,
    this.onGift,
    this.giftStock,
    this.vipGiftStock = 0,
    this.vipRoom = false,
    this.spectator = false,
    this.onPlayerTap,
    this.giftFlight,
  });

  /// يفتح لوحةَ صاحب مقعد العرض (ملفّ · تصنيف · صداقة). null ⇒ **البطاقاتُ لا
  /// تُضغَط** (أوفلاين: لا حسابات). ولا تُضغَط بطاقةُ ذكاءٍ ولا مقعدي أنا.
  final void Function(int viewSeat)? onPlayerTap;

  /// من يصحّ إهداؤه: البشر الآخرون (الذكاء لا محفظة له فلا يُهدى).
  /// للمتفرّج يدخل المقعدُ السفليّ (عرض 0) أيضًا — ليس «أنا» بل لاعبٌ حقيقيّ.
  List<({int viewSeat, SeatPlayer player})> get _giftTargets => [
        for (var pos = spectator ? 0 : 1; pos < 4; pos++)
          if (seatPlayerIds != null && seatPlayerIds![pos] != null)
            (viewSeat: pos, player: _seat(pos)),
      ];

  /// هل يتكلّم صاحبُ المقعد [pos] (بترتيب العرض) الآن؟
  bool _speaking(int pos) {
    final id = seatPlayerIds?[pos];
    return id != null && (voice?.isSpeaking(id) ?? false);
  }

  Color _teamColor(int seat, BeloteTheme t) =>
      seat.isEven ? t.accent : t.text2; // 0,2 نحن · 1,3 هم

  /// صاحب «الدور» لعقرب الساعة: أثناء التوزيع الموزّع، وإلا صاحب الدور (ضمانةً/لعبًا).
  int _activeSeat(TableView v) =>
      v.phase == GamePhase.dealing ? v.dealerSeat : v.turn;

  /// هويّة المقعد [i] — من [seats] إن توفّرت، وإلا نائبٌ من الأسماء الثابتة.
  SeatPlayer _seat(int i) {
    if (seats != null && i < seats!.length) return seats![i];
    final name = i == 0 && (playerName?.trim().isNotEmpty ?? false)
        ? playerName!
        : S.seatNames[i];
    return SeatPlayer(name: name);
  }

  /// عنصر [list] عند المقعد [i]، أو null إن لم تُمرَّر القائمة أو قصُرت.
  String? _at(List<String?>? list, int i) =>
      (list != null && i < list.length) ? list[i] : null;

  /// بطاقة اللاعب المربّعة على المقعد [i] (ترتيب العرض) — نشطةٌ حين يكون الدور له،
  /// وحولها فقاعاتُ ما وصل للتوّ: تفاعلٌ أو هديّةٌ أو عبارة.
  ///
  /// **لكلٍّ ركنُه** (التفاعل يمينًا · الهديّة يسارًا · العبارة تحت): الثلاثة قد تجتمع
  /// على مقعدٍ واحدٍ في اللحظة نفسها، ولو تشاركت موضعًا لغطّت إحداها الأخرى.
  /// المقعدُ **حيًّا مع الصوت**: زرّا الكتم والميكروفون حالتُهما في
  /// `VoiceController`، فبلا استماعٍ إليه تُضغَط الأزرارُ ولا يتغيّر شكلُها.
  Widget _seatCardLive(BuildContext context, int i, TableView v, double size) =>
      voice == null
          ? _seatCard(context, i, v, size)
          : ListenableBuilder(
              listenable: voice!,
              builder: (context, _) => _seatCard(context, i, v, size),
            );

  /// **السببُ يُقال لا يُبتلَع**: كانت لوحةُ الصوت تعرض `voice.error` (الخادمُ بلا
  /// صوت 503 · لست على طاولة 409 · إذنُ ميكروفونٍ مرفوض)، وبحذفها يبقى الزرُّ أحمرَ
  /// بلا تفسير. فالفشلُ يُرفَع الآن شريطًا يقرؤه اللاعب.
  Future<void> _toggleVoice(BuildContext context, VoiceController voice) async {
    final messenger = ScaffoldMessenger.of(context);
    await voice.toggleVoice();
    final err = voice.error;
    if (err == null || !context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(err, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ));
  }

  Widget _seatCard(BuildContext context, int i, TableView v, double size) {
    final p = _seat(i);
    final emoji = _at(reactions, i);
    final giftId = _at(gifts, i);
    // **النصُّ محسومٌ في الكنترولر** (عبارةٌ مُترجَمةٌ أو نصٌّ حرٌّ حرفيّ) ⇒ يُعرَض
    // كما هو. معرّفٌ لا نعرفه سقط هناك بلا فقاعة.
    final chatText = _at(chats, i);
    final giftGlyph = giftId == null ? null : giftEmoji(giftId);
    // **هديّةُ VIP أصلٌ لا إيموجي** ⇒ فقاعتُها صورة. بلا هذا تُرسَل ولا يراها أحد.
    final vipGift = giftId == null ? null : vipGiftAsset(giftId);

    // **طرفا الرحلة يتوهّجان** بلون الهديّة ما دامت في الجوّ: العينُ تلتقط الطرفين
    // معًا فتقرأ «فلانٌ ← فلان» قبل أن تقرأ اسمًا.
    final f = giftFlight;
    final glowing = f != null && (f.fromSeat == i || f.toSeat == i);

    // **الهديّة**: من مقعدي تُفتَح اللوحةُ على كلّ الأهداف (وفيها «للجميع»)، ومن
    // مقعدِ لاعبٍ تُفتَح عليه وحدَه — ضغطةٌ أقلُّ وقصدٌ أوضح.
    final canGiftHim =
        onGift != null && _giftTargets.any((g) => g.viewSeat == i);
    void openGift({required bool toAll}) => showGiftSheet(
          context,
          targets: toAll
              ? _giftTargets
              : _giftTargets.where((g) => g.viewSeat == i).toList(),
          onSend: onGift!,
          stock: giftStock,
          vipStock: vipGiftStock,
        );

    // **الكتم عند بطاقته** — الطاولةُ مسمعٌ واحدٌ للجميع (لا قناةَ فريق)، فمن
    // يزعجك تكتمه وأنت تنظر إليه لا في لوحةٍ مدفونة.
    final voiceId = seatPlayerIds != null && i < seatPlayerIds!.length
        ? seatPlayerIds![i]
        : null;
    final canMute = voice != null && i != 0 && voiceId != null;

    final card = PlayerSeatRound(
      name: p.name,
      emoji: p.emoji,
      avatarUrl: p.avatarUrl,
      rank: p.rank,
      skill: p.skill,
      giftGlow: glowing ? f.visuals.fx.glow : null,
      active: v.turn == i,
      speaking: _speaking(i),
      isVip: p.isVip,
      honorEmoji: honorEmojis[p.playerId] ?? '',
      size: size,
      mine: i == 0 && !spectator,
      // **زرّا مقعدي بجانب صورتي لا تحتها**: مقعدي محشورٌ بين دائرة اللعب ويدي،
      // فارتفاعُ صفِّ الأزرار يُقتطع من إحداهما (طلبُ المالك 2026-07-21).
      sideButtons: i == 0,
      // **زرُّ هديّتي ظاهرٌ ما دام أونلاين ولو لم يجلس بشريٌّ آخر** — واللوحةُ
      // تشرح وتدلّ. إخفاؤه هو ما خيّب في 4041: ميزةٌ أُعلنت ولم تُرَ أبدًا.
      // [[gift-button-visibility]]
      onGift: i == 0
          ? (onGift != null ? () => openGift(toAll: true) : null)
          : (canGiftHim ? () => openGift(toAll: false) : null),
      onMute: canMute ? () => voice!.toggleMute(voiceId) : null,
      muted: canMute && voice!.isMuted(voiceId),
      // **الميكروفونُ هو الصوتُ كلُّه** (قرار المالك 2026-07-20): لا لوحةَ صوتٍ
      // ولا زرَّ في القائمة الجانبيّة — ضغطةٌ تصل وتفتح، وضغطةٌ تقطع.
      onMic: (i == 0 && !spectator && voice != null)
          ? () => _toggleVoice(context, voice!)
          : null,
      voiceState: switch (voice?.status) {
        VoiceStatus.live => SeatVoice.live,
        VoiceStatus.connecting => SeatVoice.connecting,
        VoiceStatus.failed => SeatVoice.failed,
        VoiceStatus.off || null => SeatVoice.off,
      },
      // **مقعدي ومقعدُ الذكاء لا يُضغَطان**: الأوّل ملفّي أعرفه، والثاني لا حساب
      // خلفه. `playerId` الفارغ يفصل الحالتين عن البشر بلا استثناءٍ مكتوبٍ بيد.
      onTap: (onPlayerTap == null || i == 0 || p.isAI || p.playerId.isEmpty)
          ? null
          : () => onPlayerTap!(i),
    );
    if (emoji == null &&
        giftGlyph == null &&
        vipGift == null &&
        chatText == null) {
      return card;
    }
    return Stack(
      clipBehavior: Clip.none, // الفقاعات تتجاوز حدّ البطاقة
      children: [
        card,
        if (emoji != null)
          Positioned(
            top: -10,
            right: -10,
            child: ReactionBubble(key: ValueKey(emoji), emoji: emoji),
          ),
        if (giftGlyph != null)
          Positioned(
            top: -10,
            left: -10,
            child: ReactionBubble(key: ValueKey(giftGlyph), emoji: giftGlyph),
          ),
        if (vipGift != null)
          Positioned(
            top: -14,
            left: -14,
            child: IgnorePointer(
              child: Image.asset(vipGift, key: ValueKey(vipGift), height: 44),
            ),
          ),
        if (chatText != null)
          Positioned(
            bottom: -16,
            left: -20,
            right: -20,
            child: Center(child: ChatBubble(key: ValueKey(chatText), text: chatText)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // **خلفيّةُ غرفة VIP** بدل اللبّاد — تُرى حول الطاولة لا خلفها فقط
          // (الطاولةُ تُزاح بهامشٍ أدناه). التعتيمُ ضروريّ: الأوراقُ والبطاقاتُ
          // تعلوها، وخلفيّةٌ صارخةٌ تبتلعها فتصير الغرفةُ الفاخرةُ لعبةً لا تُقرأ.
          image: vipRoom ? VipRoom.image(dim: VipRoom.roomDim) : null,
          gradient: vipRoom
              ? null
              : RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [t.feltCenter, t.feltEdge],
                ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth, h = c.maxHeight;
              // **المقاييسُ تكبر بالطاولة**: على الهاتف يحكمها العرض (كما كانت
              // بالضبط)، وعلى نافذةِ حاسوبٍ عاليةٍ يحكمها الارتفاع فتكبر الأوراقُ
              // والمقاعدُ مع المسرح بدل أن تبقى نقاطًا في بحر. `min` بين البعدين
              // ⇒ لا بُعدَ يُفلت وحدَه، و`clamp` يحفظ سلوكَ الهاتف حرفيًّا.
              final handW = TableMetrics.myCardWidth(w, h);
              final backW = TableMetrics.backCardWidth(w, h);
              final seatSize = TableMetrics.seatSize(w, h);

              // **هندسةُ يدي تُحسَب هنا مرّةً** (بنفس مدخلات الودجت ⇒ نفسُ الناتج):
              // منها ارتفاعُها الحقيقيّ، وعليه تجلس الأزرارُ فوقها. كان الارتفاعُ
              // مقدَّرًا بـ`handW×1.95` — رقمٌ يكذب كلّما تغيّر حجمُ الورقة أو
              // تداخلُها، فتغرق الأزرارُ في الورق أو تطفو عنه.
              final hand = HandFanMetrics.fit(
                count: view.myHand.length,
                maxWidth: w - 2 * HandFanMetrics.edgeGuard,
                preferredCardWidth: handW,
              );
              // قاعُ الأزرار: فوق صندوق المروحة بفرجةٍ يسيرة.
              final aboveHand = hand.height + 16;
              final bidderName =
                  view.bidderSeat == null ? null : _seat(view.bidderSeat!).name;

              return Stack(
                children: [
                  // ── سطحُ الطاولة (خشبٌ ولبّادٌ وإضاءة) ──
                  // أوّلَ المكدّس ⇒ كلُّ ما بعدَه يجلس عليها. تملأ المساحةَ
                  // المتاحةَ كلَّها فيصير الإطارُ حافّةَ الشاشة، وتبقى مواضعُ
                  // المقاعدِ والأيدي كما هي داخلَ اللبّاد.
                  // في VIP تُترَك **حاشيةٌ من الغرفة** حول الطاولة فتبدو
                  // الطاولةُ قائمةً في مجلسٍ لا شاشةً ملوّنة؛ ظلُّ الطاولة
                  // الذي يرسمه `PremiumTablePainter` يسقط عندئذٍ على الجدار.
                  Positioned.fill(
                    child: vipRoom
                        ? Padding(
                            padding: EdgeInsets.all(
                                VipRoom.inset(math.min(w, h))),
                            child: const TableSurface(config: TableSurface.vip),
                          )
                        : const TableSurface(config: TableSurface.hall),
                  ),

                  // ── لوحُ المباراة: النتيجة + الضمانة باسم الضامن ──
                  // **داخل الطاولة فوق الشريك** (طلبُ المالك 2026-07-21): كان
                  // شريطًا يمتدّ عرضَ الشاشة كلَّه فوق الطاولة، فيقرأ لوحةَ تطبيقٍ
                  // لا لوحَ نتيجةٍ في مجلس. المساحةُ خلف الشريك فارغةٌ أصلًا.
                  Align(
                    alignment: const Alignment(0, -0.94),
                    child: _MatchPlaque(
                        view: view, bidderName: bidderName, vip: vipRoom),
                  ),

                  // ── المقعد 2 (الشريك) أعلى ──
                  if (view.phase != GamePhase.dealing)
                    Align(
                      alignment: const Alignment(0, -0.42),
                      child: view.revealedHands != null
                          ? _RevealFan(
                              cards: view.revealedHands![2], cardW: backW)
                          : _OpponentFan(
                              count: view.handCounts[2], cardW: backW, seat: 2),
                    ),
                  Align(
                    // **المرسى مشتركٌ مع محرّك الهدايا** (`kSeatAnchors`) — لو نُسخ
                    // الرقمُ هنا لَانزاحت الهديّةُ عن البطاقة عند أوّل تعديل تخطيط.
                    alignment: kSeatAnchors[2],
                    child: _seatCardLive(context, 2, view, seatSize),
                  ),

                  // ── المقعد 1 (الخصم) يمين ──
                  if (view.phase != GamePhase.dealing)
                    Align(
                      // **أخفضُ قليلًا من مركز البطاقة**: مروحةُ الجانبيّ تُرسَم
                      // مثلّثًا رأسُه نحو الوسط، فكتلتُها البصريّة تعلو مركزَ
                      // صندوقها؛ نزولٌ يسيرٌ يجعلها بحذاء البطاقة لا فوقها.
                      alignment: const Alignment(0.80, 0.06),
                      child: view.revealedHands != null
                          ? _RevealFan(
                              cards: view.revealedHands![1], cardW: backW)
                          : _OpponentFan(
                              count: view.handCounts[1], cardW: backW, seat: 1),
                    ),
                  Align(
                    alignment: kSeatAnchors[1],
                    child: _seatCardLive(context, 1, view, seatSize),
                  ),

                  // ── المقعد 3 (الخصم) يسار ──
                  if (view.phase != GamePhase.dealing)
                    Align(
                      alignment: const Alignment(-0.80, 0.06), // كنظيره يمينًا
                      child: view.revealedHands != null
                          ? _RevealFan(
                              cards: view.revealedHands![3], cardW: backW)
                          : _OpponentFan(
                              count: view.handCounts[3], cardW: backW, seat: 3),
                    ),
                  Align(
                    alignment: kSeatAnchors[3],
                    child: _seatCardLive(context, 3, view, seatSize),
                  ),

                  // ── فقاعات الضمانة: ما نطق به كل مقعد يظهر أمامه ──
                  for (var s = 0; s < 4; s++)
                    if (view.seatBids[s] != null)
                      Align(
                        alignment: _bubbleFor(s),
                        child: _BidBubble(text: view.seatBids[s]!),
                      ),

                  // ── دائرة اللعب في مركز الطاولة تمامًا: البئر + عقرب الدور + الأوراق ──
                  Align(
                    alignment: Alignment.center,
                    child: _TrickWell(size: TableMetrics.wellSize(w, h)),
                  ),
                  // مؤشّرٌ نحو صاحب الدور (قوس + رأس سهم) — لعبًا/ضمانةً/توزيعًا.
                  if (view.phase != GamePhase.done)
                    Align(
                      alignment: Alignment.center,
                      child: TurnClock(
                        size: TableMetrics.wellSize(w, h),
                        activeSeat: _activeSeat(view),
                        color: _teamColor(_activeSeat(view), t),
                      ),
                    ),
                  // **لا ضمانةَ في دائرة اللعب**: كانت لوحةً ثانيةً تكرّر ما على
                  // لوح المباراة فوق الشريك، في أكثر بقعةٍ تُنظَر إليها — تكرارٌ
                  // يزاحم الأوراقَ لا خبرٌ جديد (طلبُ المالك 2026-07-21).
                  Align(
                    alignment: Alignment.center,
                    child: _TrickLayer(
                      trick: view.trick,
                      collectingTo: view.collectingTo,
                      size: TableMetrics.trickSpread(w, h),
                      cardW: handW * 0.92,
                    ),
                  ),

                  // ── المقعد 0 (أنت) أسفل — يُخفى حين يعلو شريط الضمانة مكانه ──
                  if (bidBar == null)
                    Align(
                      alignment: kSeatAnchors[0],
                      child: _seatCardLive(context, 0, view, seatSize),
                    ),
                  if (view.phase != GamePhase.dealing)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 8,
                      child: Center(
                        child: PlayerHandFan(
                          cards: view.myHand,
                          cardWidth: handW,
                          // **حدُّ العرض من الشاشة نفسِها**: المروحةُ تنفرج ما
                          // وسعها المكان وتُصغّر الورقةَ عند الضيق — ولا تُقصّ.
                          // ويُترَك حِمى الحافّة على الجانبين: هناك يبتلع النظامُ
                          // اللمسةَ فتموت الورقةُ الطرفيّة.
                          maxWidth: w - 2 * HandFanMetrics.edgeGuard,
                          interactive: view.humanCanPlay,
                          // القانونية لم تعد مفروضة: أي ورقة تُلعب (الفوجة مسموحة).
                          onPlay: (card) => onPlayCard?.call(card),
                        ),
                      ),
                    ),

                  // ── زرّ التفاعلات (أونلاين): يقابل زرّ الفوجة على اليسار. يُخفى
                  // أثناء الفوجة والنتيجة كي لا يزاحم لحظةً حاسمة. ──
                  if (onReact != null && !view.claimingFouja && result == null)
                    Positioned(
                      left: 12,
                      bottom: aboveHand,
                      child: _ReactionButton(onReact: onReact!),
                    ),

                  // ── زرّ الفوجة: يفتح لوحة الاختيار ويكشف الورق ──
                  if (view.canAccuseFouja && onStartFoujaClaim != null)
                    Positioned(
                      right: 12,
                      bottom: aboveHand, // فوق صندوق المروحة
                      child: _FoujaButton(onPressed: onStartFoujaClaim!),
                    ),

                  // ── أدواتُ الجانب: **الرسائلُ وحدَها** ──
                  // ذهب زرُّ الصوت (2026-07-20): الميكروفونُ تحت صورتي يصل ويقطع،
                  // والكتمُ على بطاقة صاحبه ⇒ زرٌّ ثالثٌ لنفس الأمر يُربك لا يفيد.
                  //
                  // **آخرَ المكدّس عمدًا**: المقاعدُ صارت لصيقةَ حافّة الشاشة،
                  // ولو رُسمت الأدواتُ قبلها لَابتلع مقعدُ الخصم لمستَها
                  // (المقعدُ `opaque` وما يُرسَم لاحقًا يفوز باللمس).
                  Align(
                    alignment: const Alignment(0.99, 0.28),
                    child: TableControls(onOpenChat: onOpenChat),
                  ),

                  // ── الخروج: أعلى اليسار (طلبُ المالك) ──
                  // بعيدًا عن الإبهام الذي يلعب الورق: خروجٌ بالخطأ يقطع مباراة.
                  // صعد إلى الحافّة بعد أن صار لوحُ المباراة ضيّقًا في الوسط.
                  Positioned(
                    top: 10,
                    left: 12,
                    child: TableToolButton(
                      icon: Icons.logout,
                      tip: 'خروج من اللعبة',
                      danger: true,
                      onTap: onExit ?? () => Navigator.maybePop(context),
                    ),
                  ),


                  // ── لوحة اختيار من فوّج: غير حاجبة، والورق مكشوف خلفها ──
                  if (view.claimingFouja)
                    Positioned.fill(
                      child: _FoujaClaimPanel(
                        onRight: () => onAccuseFouja?.call(1), // الخصم يمينك = مقعد 1
                        onLeft: () => onAccuseFouja?.call(3), // الخصم يسارك = مقعد 3
                        onCancel: onCancelFoujaClaim ?? () {},
                      ),
                    ),

                  // ── لافتة التجميد لبقيّة اللاعبين: فلانٌ يعترض بالفوجة (بلا كشف) ──
                  if (view.foujaClaimBy != null && !view.claimingFouja)
                    Positioned.fill(
                      child: _FoujaFreezeBanner(
                        name: _seat(view.foujaClaimBy!).name,
                      ),
                    ),

                  // ── عدّاد دورك: يخفت خلال المهلة، ثم يلعب الذكاء مكانك ──
                  // **فوق صندوق المروحة كلِّه** (طلبُ المالك 2026-07-21: «ارفع خطّ
                  // المؤقّت»): كان قاعُه داخل الصندوق فيبدو خطًّا مرسومًا على ظهور
                  // الأوراق — وقد يبتلع لمسةَ ورقةٍ عاليةٍ في المنتصف.
                  if (view.humanCanPlay && view.humanTurnLimit != null)
                    Positioned(
                      left: 40,
                      right: 40,
                      bottom: aboveHand + 8,
                      child: _TurnTimer(
                        key: ValueKey(view.humanTurnSeq),
                        duration: view.humanTurnLimit!,
                        onTick: onTurnTick,
                      ),
                    ),

                  // ── توزيع الورق: أوراق تنطلق من مقعد الموزّع إلى الجميع ──
                  if (view.phase == GamePhase.dealing)
                    Positioned.fill(
                      child: _DealingLayer(
                        // مفتاح يُعيد بناء الطبقة بين نافذتَي التوزيع (افتتاح ثم الباقي).
                        key: ValueKey(view.dealingRest),
                        dealerSeat: view.dealerSeat,
                        cardW: backW,
                        count: view.dealingRest ? 12 : 8,
                        duration:
                            view.dealingRest ? Motion.dealRest : Motion.deal,
                      ),
                    ),

                  // ── شريط الضمانة فوق اليد مباشرة (حين يكون الدور لك) ──
                  if (bidBar != null && onBid != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: aboveHand - 6,
                      child: BidBar(view: bidBar!, onBid: onBid!),
                    ),

                  // ── لوحة النتيجة: تظهر كلّما وُجدت نتيجة جولة (بين الجولات وعند انتهاء
                  // المباراة، أوفلاين وأونلاين) — لا تُشترَط بطور `done` كي تظهر أونلاين
                  // بين الجولات حيث يبقى الطور «لعب». ──
                  if (result != null)
                    Positioned.fill(
                      child: ResultPanel(
                        result: result!,
                        onNewMatch: onNewMatch,
                        onExit: onExit,
                        rating: rating,
                        ratingDelta: ratingDelta,
                        rank: rank,
                        summary: summary,
                      ),
                    ),

                  // ── طبقةُ الهدايا الطائرة: **آخرَ الأبناء = أعلى الطبقات** ──
                  // فوق الأوراق والبطاقات وحتّى لوحة النتيجة: الهديّةُ تعبر الطاولةَ
                  // ولا شيءَ يبتلعها. و`IgnorePointer` داخلها ⇒ لا تسرق لمسةً.
                  if (giftFlight != null)
                    Positioned.fill(child: GiftFlightLayer(flight: giftFlight)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// **لوحةٌ على الطاولة** — سطحٌ داكنٌ شفيفٌ بحدٍّ ذهبيٍّ رفيع، تُركَّب عليه الكتابة.
///
/// **لماذا لوحةٌ لا لون:** ما تحتَها لم يعد لونًا واحدًا — خشبٌ متدرّجٌ (أعلاه
/// أفتحُ ما فيه) · حقلٌ أخضرُ · شريطان أحمران · هلالٌ ذهبيّ · وصورةُ غرفةٍ في
/// VIP. **لا حبرَ واحدٌ يُقرأ على هذه كلِّها**، فمهما بدّلنا اللونَ خسرنا على
/// خلفيّةٍ منها. اللوحةُ تجعل القراءةَ مستقلّةً عمّا تحتها.
///
/// وذهبُها من `TableSurface.inlayFor` — تطعيمُ الطاولة نفسِها ⇒ تبدو مركّبةً
/// عليها لا ملصقةً فوقها، وتتبعُ طاولةَ VIP حين تتغيّر.
class _TablePlaque extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool vip;

  const _TablePlaque({
    required this.child,
    required this.vip,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  /// انحناءُ اللوحة — ثابتٌ لكلّ لوحات الطاولة كي تُقرأ عائلةً واحدة.
  static const double radius = 14;

  /// حبرُ اللوحة: كريميٌّ فاتحٌ يُقرأ على الداكن، وثانويُّه أخفت.
  static const ink = Color(0xFFF3EAD6);
  static const ink2 = Color(0xB3F3EAD6);

  @override
  Widget build(BuildContext context) {
    final gold = TableSurface.inlayFor(vip: vip);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: gold.withValues(alpha: 0.55), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// **لوحُ المباراة** — النتيجةُ والضمانةُ في لوحةٍ واحدةٍ **داخل الطاولة**، أعلاها
/// خلف الشريك حيث المساحةُ فارغة.
///
/// كان شريطًا يمتدّ عرضَ الشاشة فوق حافّة الطاولة: يقرأ شريطَ تطبيقٍ لا لوحًا في
/// مجلس، ويسرق من ارتفاعِ اللعب. وضِيقُه هنا مقصود: `mainAxisSize.min` ⇒ يكبر
/// بالمحتوى ولا يمتدّ، فلا يزاحم بطاقةَ الشريك تحته.
class _MatchPlaque extends StatelessWidget {
  final TableView view;
  final String? bidderName;
  final bool vip;
  const _MatchPlaque({required this.view, this.bidderName, this.vip = false});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    // قبل استقرار الضمانة يظهر حالُ الجولة (توزيعٌ/ضمانة) مكانَها.
    final official =
        view.phase == GamePhase.playing || view.phase == GamePhase.done;
    return _TablePlaque(
      vip: vip,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // **لونُ الفريق يبقى مميِّزًا** (نحن بلون التمييز · هم بالثانويّ)،
          // أمّا الأرقامُ فبحبر اللوحة الكريميّ: يُقرأ على الداكن دائمًا.
          _score(S.us, view.usScore, t.accent),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 26,
            color: _TablePlaque.ink2.withValues(alpha: 0.25),
          ),
          const SizedBox(width: 12),
          if (!official)
            Text(
              view.phase == GamePhase.dealing ? S.dealing : S.bidding,
              style: const TextStyle(
                  color: _TablePlaque.ink2,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.bidLabel(view.bid, akwins: view.akwins),
                  style: const TextStyle(
                      color: _TablePlaque.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
                if (bidderName != null && bidderName!.isNotEmpty)
                  Text(bidderName!,
                      style: const TextStyle(
                          color: _TablePlaque.ink2, fontSize: 11.5)),
              ],
            ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 26,
            color: _TablePlaque.ink2.withValues(alpha: 0.25),
          ),
          const SizedBox(width: 12),
          _score(S.them, view.themScore, t.text2),
        ],
      ),
    );
  }

  Widget _score(String label, int value, Color color) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          Text(
            '$value',
            textDirection: TextDirection.ltr, // أرقام لاتينية
            style: const TextStyle(
                color: _TablePlaque.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800),
          ),
        ],
      );
}

/// بئر الأبلي — دائرة خافتة في وسط الطاولة (تُملأ بالأوراق لاحقًا).
class _TrickWell extends StatelessWidget {
  final double size;
  const _TrickWell({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white10),
      ),
    );
  }
}

/// مروحة ظهر أفقية (المقعد العلوي).
/// **مروحةُ ظهرٍ محورُها القاعدة** — طريقةُ الأيدي في العرض الذي أقرّه المالك:
/// كلُّ أوراق المقعد أسفلُها على **نقطةٍ واحدة**، وتُدار حولها بزوايا متدرّجة ⇒
/// تُجمَع من تحتُ وتُفتَح من فوق كيدٍ تُمسَك حقًّا.
///
/// كانت صفًّا مسطّحًا متداخلًا (بلا زاوية ولا قوس) — يقرأ ورقًا مصفوفًا لا لاعبًا
/// يحمل يدَه. تفتح [_PivotFan] للأعلى دائمًا، ويُدير [_OpponentFan] المروحةَ
/// كاملةً نحو مركز الطاولة حسب المقعد.
class _PivotFan extends StatelessWidget {
  final int count;
  final double cardW;
  const _PivotFan({required this.count, required this.cardW});

  /// أقصى انفراجٍ للمروحة كلِّها (راديان) — يُقسَّم على الأوراق مهما كثرت، فلا
  /// تنفلت يدُ الثماني أوراقٍ عن يدِ الثلاث.
  static const _spread = 0.95;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final cardH = cardW * 1.4;
    final mid = (count - 1) / 2.0;
    final step = count > 1 ? math.min(_spread / (count - 1), 0.17) : 0.0;
    // الصندوقُ يتّسع لأوسع انحرافٍ أفقيّ (نصفُ القوس) + عرضِ الورقة.
    final reach = cardH * math.sin(step * mid);
    final w = cardW + 2 * reach;
    return SizedBox(
      width: w,
      height: cardH * 1.06,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: w / 2 - cardW / 2,
              bottom: 0,
              child: Transform(
                alignment: Alignment.bottomCenter, // المحورُ نقطةُ الجمع
                transform: Matrix4.rotationZ((i - mid) * step),
                child: SizedBox(width: cardW, child: const CardBack()),
              ),
            ),
        ],
      ),
    );
  }
}

/// مروحةُ خصمٍ موجَّهةٌ نحو مركز الطاولة: العلويُّ تنفتح يدُه للأسفل، واليمينيُّ
/// لليسار، واليساريُّ لليمين — كلٌّ يمسك ورقَه ووجهُه إلينا.
class _OpponentFan extends StatelessWidget {
  final int count;
  final double cardW;
  final int seat; // بترتيب العرض: 1 يمين · 2 أعلى · 3 يسار
  const _OpponentFan(
      {required this.count, required this.cardW, required this.seat});

  @override
  Widget build(BuildContext context) {
    final turn = switch (seat) {
      2 => math.pi, // أعلى ⇒ تنفتح نحونا
      1 => -math.pi / 2, // يمين ⇒ تنفتح يسارًا (نحو الوسط)
      _ => math.pi / 2, // يسار ⇒ تنفتح يمينًا
    };
    return Transform.rotate(
      angle: turn,
      child: _PivotFan(count: count, cardW: cardW),
    );
  }
}

/// عدّاد دور اللاعب — شريطٌ يخفت من الكامل إلى الصفر خلال المهلة. يُعاد بناؤه بمفتاح
/// [humanTurnSeq] فيبدأ من جديد كل دور. اللون يتدرّج من الذهبي إلى الأحمر مع النفاد.
///
/// يُطلق [onTick] تكتكةً كل ثانيةٍ في **آخر [_tickWindow]** فقط — لا طوال المهلة: تكتكةٌ
/// من أوّل الدور تصير ضجيجًا، وإنّما غايتها التنبيه قُرب النفاد. بلا [onTick] لا مؤقّتات
/// أصلاً، فتبقى الاختبارات التي لا تصل الصوت خاليةً من مؤقّتاتٍ معلّقة.
class _TurnTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onTick;
  const _TurnTimer({super.key, required this.duration, this.onTick});

  @override
  State<_TurnTimer> createState() => _TurnTimerState();
}

class _TurnTimerState extends State<_TurnTimer> {
  /// نافذة التكتكة قبل نفاد المهلة (مهلةٌ أقصر منها ⇒ تكتكةٌ من أوّلها).
  static const _tickWindow = Duration(seconds: 5);

  Timer? _lead; // الانتظار حتى دخول النافذة
  Timer? _ticks; // التكتكة داخلها
  int _left = 0; // تكتكاتٌ باقية (تمنع تكتكةً بعد نفاد المهلة)

  @override
  void initState() {
    super.initState();
    if (widget.onTick == null || widget.duration <= Duration.zero) return;
    _left = widget.duration < _tickWindow
        ? widget.duration.inSeconds
        : _tickWindow.inSeconds;
    if (_left <= 0) return;
    final lead = widget.duration - _tickWindow;
    if (lead <= Duration.zero) {
      _beginTicks();
    } else {
      _lead = Timer(lead, _beginTicks);
    }
  }

  void _beginTicks() {
    widget.onTick!(); // تكتكةٌ فور دخول النافذة
    if (--_left <= 0) return;
    _ticks = Timer.periodic(const Duration(seconds: 1), (t) {
      widget.onTick!();
      if (--_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _lead?.cancel();
    _ticks?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: widget.duration,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 5,
          backgroundColor: Colors.black26,
          valueColor: AlwaysStoppedAnimation<Color>(
            Color.lerp(t.error, t.accent, v)!,
          ),
        ),
      ),
    );
  }
}

/// زرّ الاعتراض بفوجة — ظاهر طوال طور اللعب. لمسه يفتح شاشة اختيار الخصم المتّهَم.
/// زرّ التفاعلات: يفتح شريط الرموز فوقه، ويُغلقه فور الاختيار.
/// حالةٌ محليّةٌ محضة (مفتوح/مغلق) — لا شأن للكنترولر بها.
class _ReactionButton extends StatefulWidget {
  final void Function(String emoji) onReact;
  const _ReactionButton({required this.onReact});

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_open)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ReactionPicker(
              onPick: (e) {
                widget.onReact(e);
                setState(() => _open = false);
              },
            ),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: t.feltCenter,
                shape: BoxShape.circle,
                border: Border.all(color: t.accent, width: 1.4),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
              ),
              child: Icon(
                _open ? Icons.close : Icons.add_reaction_outlined,
                color: t.accent,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FoujaButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _FoujaButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: t.feltCenter,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.accent, width: 1.4),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: Text(
            S.fouja,
            style: TextStyle(
              color: t.accent,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

/// مروحة أوراق مكشوفة (وجهًا) لخصمٍ عند المطالبة بفوجة — بدل مروحة الظهر.
class _RevealFan extends StatelessWidget {
  final List<Card> cards;
  final double cardW;
  const _RevealFan({required this.cards, required this.cardW});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final step = cardW * 0.52;
    final totalW = cardW + (cards.length - 1) * step;
    return SizedBox(
      width: totalW,
      height: cardW * 1.4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < cards.length; i++)
            Positioned(
              left: i * step,
              child: SizedBox(width: cardW, child: CardFace(card: cards[i])),
            ),
        ],
      ),
    );
  }
}

/// لوحة اختيار من فوّج — غير حاجبة (تعتيمٌ خفيف يُبقي الورق مرئيًّا). الزرّان
/// موضوعان مكانيًّا: «يمينك» يمينًا (مقعد 1) و«يسارك» يسارًا (مقعد 3)، كطلب صاحب المشروع.
class _FoujaClaimPanel extends StatelessWidget {
  final VoidCallback onRight;
  final VoidCallback onLeft;
  final VoidCallback onCancel;
  const _FoujaClaimPanel({
    required this.onRight,
    required this.onLeft,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Stack(
      children: [
        const ModalBarrier(color: Colors.black38, dismissible: false),
        Align(
          alignment: const Alignment(0, -0.62),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: t.feltCenter,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.accent, width: 1.2),
            ),
            child: Text(
              S.whoFouja,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  color: t.feltInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 16),
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0.82, 0.05),
          child: _ClaimSide(label: S.opponentRight, onTap: onRight),
        ),
        Align(
          alignment: const Alignment(-0.82, 0.05),
          child: _ClaimSide(label: S.opponentLeft, onTap: onLeft),
        ),
        Align(
          alignment: const Alignment(0, 0.9),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCancel,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.error, width: 1.6),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, color: t.error, size: 18),
                    const SizedBox(width: 6),
                    Text(S.cancelFouja,
                        style: TextStyle(
                            color: t.error, fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// لافتة تجميدٍ لبقيّة اللاعبين حين يعترض أحدهم بفوجة: تُظهر من يعترض وتُبقي اللعب
/// متوقّفًا (بلا كشف أوراق) حتى يختار المعترِض الخصم أو يُلغي.
class _FoujaFreezeBanner extends StatelessWidget {
  final String name;
  const _FoujaFreezeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Stack(
      children: [
        const ModalBarrier(color: Colors.black38, dismissible: false),
        Align(
          alignment: const Alignment(0, -0.35),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: t.feltCenter,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.accent, width: 1.4),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: t.accentBright),
                ),
                const SizedBox(width: 10),
                Text(S.foujaClaimedBy(name),
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                        color: t.feltInk, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// زرّ خصمٍ في لوحة الفوجة — ذهبيّ بارز.
class _ClaimSide extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ClaimSide({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [t.accentBright, t.accent],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
          ),
          child: Text(label,
              style: TextStyle(
                  color: t.onAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ),
      ),
    );
  }
}

/// طبقة الأبلي: كل ورقة تنزلق من جهة صاحبها إلى مربّعها، ثم تنجمع نحو الفائز.
/// كل التوقيتات من [Motion]. الانزلاق فقط — لا حركات معقّدة.
class _TrickLayer extends StatelessWidget {
  final List<Play> trick;
  final int? collectingTo;
  final double size;
  final double cardW;

  const _TrickLayer({
    required this.trick,
    required this.collectingTo,
    required this.size,
    required this.cardW,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final p in trick)
            _TrickCard(
              key: ValueKey(p.card.code),
              play: p,
              cardW: cardW,
              collectingTo: collectingTo,
            ),
        ],
      ),
    );
  }
}

/// موضع مربّع كل مقعد داخل الطبقة (عكس عقارب الساعة: 0 أسفل، 1 يمين، 2 أعلى، 3 يسار).
Alignment _slotFor(int seat) => switch (seat) {
      0 => const Alignment(0, 0.62),
      1 => const Alignment(0.62, 0),
      2 => const Alignment(0, -0.62),
      3 => const Alignment(-0.62, 0),
      _ => Alignment.center,
    };

/// حافة جهة المقعد — نقطة انطلاق الانزلاق (ووجهة الجمع نحو الفائز).
Alignment _edgeFor(int seat) => switch (seat) {
      0 => const Alignment(0, 2.4),
      1 => const Alignment(2.4, 0),
      2 => const Alignment(0, -2.4),
      3 => const Alignment(-2.4, 0),
      _ => Alignment.center,
    };

/// موضع فقاعة ضمانة كل مقعد — أمامه، منزاحةً قليلًا نحو المركز.
Alignment _bubbleFor(int seat) => switch (seat) {
      0 => const Alignment(0, 0.30),
      1 => const Alignment(0.52, 0.04),
      2 => const Alignment(0, -0.30),
      3 => const Alignment(-0.52, 0.04),
      _ => Alignment.center,
    };

/// موضع استقرار الورقة الموزَّعة عند كل مقعد (قرب مروحته).
Alignment _dealTargetFor(int seat) => switch (seat) {
      0 => const Alignment(0, 0.66),
      1 => const Alignment(0.80, 0.06), // = مرسى مروحته
      2 => const Alignment(0, -0.42),
      3 => const Alignment(-0.80, 0.06),
      _ => Alignment.center,
    };

/// فقاعة صغيرة تُظهر ما نطق به لاعبٌ أثناء الضمانة (تنبثق بلطف عند ظهورها).
class _BidBubble extends StatelessWidget {
  final String text;
  const _BidBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 170),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(
        scale: 0.7 + 0.3 * v,
        child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: t.accent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            color: t.onAccent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// طبقة التوزيع: أوراق (ظهرها) تنطلق من حافة مقعد الموزّع إلى الجميع بالتتابع،
/// ثم تتلاشى عند الوصول لتحلّ محلّها المراوح الحقيقية. عرضٌ محض عابر.
class _DealingLayer extends StatefulWidget {
  final int dealerSeat;
  final double cardW;
  final int count; // كم ورقة تمثيلية تنطلق (٨ للافتتاح، ١٢ للثلاث الباقية)
  final Duration duration;
  const _DealingLayer({
    super.key,
    required this.dealerSeat,
    required this.cardW,
    required this.count,
    required this.duration,
  });

  @override
  State<_DealingLayer> createState() => _DealingLayerState();
}

class _DealingLayerState extends State<_DealingLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.count;
    final start = _edgeFor(widget.dealerSeat);
    // نوزّع الانطلاقات على أول 60% من الزمن كي تبقى للورقة الأخيرة رحلة كافية،
    // مهما كان عددها. span = زمن رحلة الورقة الواحدة (كسر من المدّة الكلّية).
    final stagger = n > 1 ? 0.6 / (n - 1) : 0.0;
    final span = (1 - stagger * (n - 1)).clamp(0.15, 1.0);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < n; i++)
            if (_c.value >= i * stagger)
              Align(
                alignment: Alignment.lerp(
                  start,
                  _dealTargetFor(i % 4),
                  Motion.dealCurve.transform(
                      (((_c.value - i * stagger) / span)).clamp(0.0, 1.0)),
                )!,
                child: Opacity(
                  opacity: _fade(((_c.value - i * stagger) / span).clamp(0.0, 1.0)),
                  child:
                      SizedBox(width: widget.cardW, child: const CardBack()),
                ),
              ),
        ],
      ),
    );
  }

  // تبقى ظاهرة طوال الرحلة ثم تتلاشى في آخر 15% عند الاستقرار.
  double _fade(double raw) => raw < 0.85 ? 1.0 : (1 - (raw - 0.85) / 0.15);
}

class _TrickCard extends StatefulWidget {
  final Play play;
  final double cardW;
  final int? collectingTo;

  const _TrickCard({
    super.key,
    required this.play,
    required this.cardW,
    required this.collectingTo,
  });

  @override
  State<_TrickCard> createState() => _TrickCardState();
}

class _TrickCardState extends State<_TrickCard> {
  bool _entered = false; // أول إطار: من الحافة → المربّع (انزلاق الدخول)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final collecting = widget.collectingTo != null;
    final Alignment target = collecting
        ? _edgeFor(widget.collectingTo!) // ينجمع نحو الفائز
        : (_entered ? _slotFor(widget.play.seat) : _edgeFor(widget.play.seat));

    return AnimatedAlign(
      alignment: target,
      duration: collecting ? Motion.pliCollect : Motion.slideCard,
      curve: collecting ? Motion.pliCollectCurve : Motion.slideCardCurve,
      // عند الجمع: تتقلّص قليلاً وتخفت تدريجيًّا وهي تتراكم نحو الفائز.
      child: AnimatedScale(
        scale: collecting ? 0.82 : 1.0,
        duration: Motion.pliCollect,
        curve: Motion.pliCollectCurve,
        child: AnimatedOpacity(
          opacity: collecting ? 0.0 : 1.0,
          duration: Motion.pliCollect,
          curve: Curves.easeInCubic,
          child: DecoratedBox(
            // ظلّ ناعم أسفل الورقة يمنح عمقًا أثناء الحركة.
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            child: SizedBox(
              width: widget.cardW,
              child: CardFace(card: widget.play.card),
            ),
          ),
        ),
      ),
    );
  }
}
