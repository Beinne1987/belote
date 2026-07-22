import 'dart:async';
import 'dart:math';

import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/foundation.dart';

import '../net/table_client.dart';
import '../ui/gift_picker.dart' show kGiftAll;
import '../strings_ar.dart';
import '../ui/gifts/gift_flight.dart';
import 'quick_chat.dart';
import 'seat_player.dart';
import 'view_model.dart';

/// مرحلة تجربة الأونلاين كما تراها الواجهة.
enum OnlineStage { menu, lobby, playing, error }

/// **جسر الأونلاين ↔ واجهة الطاولة.** يستهلك لقطات [LiveTableClient] ويحوّلها إلى
/// نفس عقود العرض (`TableView`/`BidBarView`/`RoundResult`) التي تعرضها `TableScreen`
/// المحلّية — فتعمل الطاولة الأونلاين بنفس اللباد والحركات، لا شاشةٌ منفصلة.
///
/// **تدوير المقاعد:** الخادم يعطي مقعدي الحقيقيّ (0..3)، لكن `TableScreen` ترسم
/// اللاعب في الأسفل (مقعد العرض 0) والشريك أمامه. نُدوّر كل فهرس مقعد بـ
/// `(s - mySeat) % 4` ⇒ مقعدي=0 (أسفل) · شريكي=2 (أعلى) · خصماي=1,3 — مع الحفاظ
/// على تكافؤ الفريق (0,2 نحن) واتجاه الدور.
class OnlineGameController extends ChangeNotifier {
  final LiveTableClient client;

  /// **وضعُ المشاهدة** ([[spectator-system]]): غير null ⇒ هذه الجلسة متفرّجٌ على
  /// الطاولة المذكورة — تُرسَل نيّةُ `spectate` فورًا وتُعاد عند كلّ إعادة اتصال
  /// (الخادم يُسقط المشاهدَ المنقطع فلا لقطةَ تلقائيّةً كالجالس).
  final String? spectateTableId;

  /// صوت اللعب (لعب ورقة/توزيع) — يُوصَل بـ `Sfx` في الإنتاج، null في الاختبار.
  final void Function(GameSound sound)? onSound;

  /// **صمّامُ الدعوة**: صديقٌ دعوتَه انضمّ ⇒ نلتَ لعبةً. يُوصَل بتحديث العدّاد في
  /// الصفحة (الكنترولر لا يعرف الجلسة). null ⇒ لا تحديث (اختبارات).
  final VoidCallback? onInviteReward;

  /// مدد الحركات؛ **صفر ⇒ بلا حركة** (الاختبارات تطبّق اللقطات فورًا).
  final Duration dealAnim; // نافذة التوزيع
  final Duration collectAnim; // جمع الأخذة نحو الفائز
  final Duration trickPause; // وقفة رؤية الورقة الأخيرة قبل الجمع (pliPause أوفلاين)
  final Duration bidHold; // مسك فقاعات الضمانة لتُقرأ قبل بدء اللعب
  final Duration settle; // استقرارٌ قصير بعد جمع الأخذة قبل الدور التالي
  final Duration cardLandDelay; // تأخير صوت اللعب ليتزامن مع هبوط الورقة (= Motion.slideCard)

  /// تفريقُ ظهور اللعبات المتراكمة: لقطات لعبِ الذكاء تصل متراكمةً أثناء وقفات الأونلاين
  /// (جمع الأخذة…)، فتُطبَّق دفعةً واحدة. هذا يفرض حدًّا أدنى للمسافة بين ظهور ورقةٍ وأخرى
  /// كي تظهر متتابعةً كالأوفلاين لا مرّةً واحدة. صفرٌ في الاختبارات.
  final Duration playStagger;

  /// وقفةُ عرض نتيجة الجولة **بين الجولات** (كالأوفلاين ٣ث): تبقى اللوحة لتُقرأ قبل
  /// توزيع الجولة التالية (الخادم يقفز مباشرةً). صفرٌ في الاختبارات.
  final Duration resultHold;

  late final StreamSubscription<TableEvent> _sub;
  late final StreamSubscription<ConnStatus> _statusSub;

  GameEvent? _snapshot;
  LobbyEvent? _lobby;
  RatingEvent? _rating;
  String? _errorCode;
  String? _notice;
  Timer? _noticeTimer;
  bool _reconnecting = false;
  bool _disposed = false; // يوقف الإشعار/الصوت المؤجَّل بعد مغادرة الطاولة

  // تسلسل العرض (لتقليد إحساس الأوفلاين من تيّار لقطاتٍ لحظيّ).
  final List<GameEvent> _queue = [];
  bool _processing = false;
  int? _collectingTo; // مقعد العرض الذي تنجمع نحوه الأخذة
  bool _dealing = false;
  bool _dealingRest = false;

  /// فقاعة ضمانة كل مقعد (بترتيب العرض) — تُشتقّ من تغيّر لقطات الخادم كي تُقرأ
  /// كما في الأوفلاين. تُصفَّر عند بداية جولةٍ جديدة وعند العودة إلى اللوبي.
  List<String?> _seatBids = [null, null, null, null];

  /// أثناء مسك الفقاعات في نهاية الضمانة (bidHold): يُخفى شريط الضمانة كي لا يظهر
  /// على لقطة الضمانة الأخيرة (قد تحمل `yourTurn` بعد انتهائها).
  bool _settlingBids = false;

  /// مهلة دورك في اللعب أونلاين — مطابقةٌ لمهلة الخادم (15ث): إن لم تلعب خلالها
  /// يلعب الذكاء مكانك على الخادم. عدّادٌ محلّيّ للعرض فقط؛ الخادم هو المُنفِّذ.
  static const _turnLimit = Duration(seconds: 15);

  /// يتزايد مع كل بدء دورِ لعبٍ لك — مفتاحٌ يُعيد تشغيل العدّاد التنازليّ في الواجهة.
  int _turnSeq = 0;

  OnlineGameController(
    this.client, {
    this.spectateTableId,
    this.onSound,
    this.onInviteReward,
    this.dealAnim = Duration.zero,
    this.collectAnim = Duration.zero,
    this.trickPause = Duration.zero,
    this.bidHold = Duration.zero,
    this.settle = Duration.zero,
    this.cardLandDelay = Duration.zero,
    this.playStagger = Duration.zero,
    this.resultHold = Duration.zero,
    this.reactionHold = Duration.zero,
  }) {
    _sub = client.events.listen(
      _onEvent,
      onError: (_) {
        _errorCode = 'connection';
        notifyListeners();
      },
    );
    _statusSub = client.status.listen((s) {
      _reconnecting = s == ConnStatus.reconnecting;
      notifyListeners();
    });
    final watch = spectateTableId;
    if (watch != null) {
      client.spectate(watch);
      client.onReopen = () => client.spectate(watch); // انقطاعٌ ⇒ عُد للمدرّجات
    }
  }

  /// أنا متفرّجٌ لا لاعب؟ (يثبت من الإنشاء — لا يتقلّب مع اللقطات).
  bool get isSpectator => spectateTableId != null;

  /// انقطاعٌ مؤقّت وإعادة اتصالٍ جارية — تبقى آخر لقطةٍ ظاهرةً مع شارة «إعادة الاتصال…».
  bool get reconnecting => _reconnecting;

  @override
  void notifyListeners() {
    if (_disposed) return; // لا إشعار بعد الإتلاف (يمنع أعطال الحلقات المؤجَّلة)
    super.notifyListeners();
  }

  /// صوتٌ محروس: لا يُشغَّل بعد مغادرة الطاولة.
  void _sfx(GameSound sound) {
    if (!_disposed) onSound?.call(sound);
  }

  /// صوتٌ مؤجَّل [delay] كي يتزامن مع لحظةٍ في الحركة (هبوط الورقة). صفرٌ ⇒ فوريّ.
  void _sfxDelayed(GameSound sound, Duration delay) {
    if (_disposed) return;
    if (delay <= Duration.zero) {
      _sfx(sound);
      return;
    }
    Future.delayed(delay, () => _sfx(sound));
  }

  /// ينتظر نافذة التوزيع [window] مُطلِقًا [ticks] نقرةَ توزيعٍ متتابعةً موزّعةً عليها
  /// (كإيقاع الأوفلاين) بدل صوتٍ واحد في البداية.
  Future<void> _dealTicks(Duration window, int ticks) async {
    final gap = Duration(microseconds: window.inMicroseconds ~/ (ticks + 1));
    for (var i = 0; i < ticks; i++) {
      await Future<void>.delayed(gap);
      if (_disposed) return;
      _sfx(GameSound.deal);
    }
    await Future<void>.delayed(gap);
  }

  void _onEvent(TableEvent e) {
    switch (e) {
      case InviteEvent():
        _invite = e; // تعرضها الواجهة نافذةً؛ الأحدث يزيح الأقدم
        notifyListeners();
      case InviteSentEvent():
        _inviteSentTo = e.playerId;
        notifyListeners();
      case InviteRewardEvent():
        // صديقٌ دعوتَه انضمّ ⇒ نلتَ لعبةً اليوم. ملاحظةٌ عابرةٌ + تحديثُ العدّاد
        // (يُوصَل من الصفحة، فالكنترولر لا يعرف المحفظة ولا الشبكة).
        _showNotice('inviteReward');
        onInviteReward?.call();
      case UnknownEvent():
        // خادمٌ أحدث يبثّ طورًا لا نعرفه ⇒ تجاهلٌ صامتٌ مقصود: لا تمسّ الطاولة ولا
        // تُشعِر. هذا هو ما يُبقي العميل القديم سليمًا فلا يُلزَم بالتحديث.
        break;
      case ServerError(:final code):
        // **خطأٌ لا يعني بالضرورة أنّ الطاولة ماتت.** «صديقُك غير متّصل» خبرٌ عابر،
        // بينما «الخوادم ممتلئة» نهايةُ الطريق. كانا سواءً فكان `invite_offline`
        // يهدم اللوبي كلَّه ويُخرج الداعيَ برسالة «حدث خطأ غير متوقّع» — بلاغ المالك.
        if (_isFatal(code)) {
          _errorCode = code;
          notifyListeners();
        } else {
          _showNotice(code);
        }
      case RatingEvent():
        _rating = e; // مباراةٌ مصنّفة انتهت ⇒ تعرضه لوحة النتيجة
        notifyListeners();
      case ReactionEvent():
        _showBubble(_reactions, _reactionTimers, _view(e.seat), e.emoji);
      case ChatEvent():
        () {
          // **النصُّ يُحسَم هنا**: حرٌّ حرفيًّا، أو عبارةٌ جاهزةٌ تُترجَم. معرّفٌ لا
          // نعرفه (خادمٌ أحدث) ⇒ يُسقَط بلا فقاعةٍ خام.
          final display = e.text ?? (e.phrase == null ? null : quickChatText(e.phrase!));
          if (display == null) return;
          final view = _view(e.seat);
          _showBubble(_chats, _chatTimers, view, display);
          _chatLog.add(ChatLogEntry(
            viewSeat: view,
            text: display,
            mine: view == 0,
            // معرّفُ القائل — به يقع البلاغُ/الحظرُ من لوحة الدردشة (UGC:
            // البلاغ حيث يُرى المحتوى). null للذكاء ولا بلاغَ عنه.
            senderId: seatPlayerIds[view],
          ));
          if (_chatLog.length > _chatLogMax) _chatLog.removeAt(0);
        }();
      case GiftEvent():
        // **تطير من المُرسِل إلى المستقبِل** ثمّ تستقرّ فوقه فقاعةً. الفقاعةُ وحدَها
        // (كما كانت) كانت تُظهر هديّةً بلا مُهدٍ — والمستقبِلُ لا يدري مَن أكرمَه.
        _enqueueGift(
          fromViewSeat: _view(e.from),
          toViewSeat: _view(e.to),
          giftId: e.gift,
          senderName: seatNameAt(_view(e.from)),
        );
      case WatchersEvent():
        _watchers = e.count;
        notifyListeners();
      case SpectatorGiftEvent():
        // تطير **من المدرّجات** (أسفل الشاشة) لا من مقعد: المُهدي ليس على مقعد،
        // واسمُه يسافر معها — فهو **الاستعراض** الذي دفع ثمنه. واللافتةُ السفليّة
        // تبقى كما كانت: الحركةُ عابرةٌ والخبرُ يمكث.
        _enqueueGift(
          fromViewSeat: null,
          toViewSeat: _view(e.to),
          giftId: e.gift,
          senderName: e.name.isEmpty ? 'مشاهد' : e.name,
        );
        _standsGiftTimer?.cancel();
        _standsGift = e;
        notifyListeners();
        if (reactionHold > Duration.zero) {
          _standsGiftTimer = Timer(_noticeHold, () {
            _standsGift = null;
            if (!_disposed) notifyListeners();
          });
        }
      case SpectateEndEvent():
        // انتهى العرض. مباراةٌ اكتملت ⇒ تبقى لوحةُ النتيجة (آخر لقطة) ويُعلَم أن
        // لا مزيد. وإن ماتت الطاولةُ قبل النهاية ⇒ شاشةُ «لم تعد متاحة».
        _spectateEnded = true;
        if (_snapshot?.matchOver != true) _errorCode = 'spectate_unavailable';
        notifyListeners();
      case LobbyEvent():
        _lobby = e;
        _snapshot = null; // عدنا إلى اللوبي (لم تبدأ/انتهت المباراة)
        _errorCode = null;
        _rating = null; // مباراةٌ جديدة ⇒ لا تُبقِ تصنيف السابقة
        _queue.clear();
        _collectingTo = null;
        _dealing = false;
        _dealingRest = false;
        _settlingBids = false;
        _seatBids = [null, null, null, null];
        notifyListeners();
      case GameEvent():
        _errorCode = null;
        // لقطاتُ المشاهد تحمل العدّاد (الجالسون يأخذونه من طور `watchers`).
        final w = e.watchers;
        if (w != null) _watchers = w;
        _queue.add(e);
        _drain(); // تُطبَّق اللقطات بالتسلسل مع الحركات
    }
  }

  /// يطبّق اللقطات المتراكمة واحدةً واحدة (لئلا تتداخل نوافذ الحركة).
  Future<void> _drain() async {
    if (_processing) return;
    _processing = true;
    while (_queue.isNotEmpty) {
      await _apply(_queue.removeAt(0));
    }
    _processing = false;
  }

  Future<void> _apply(GameEvent s) async {
    final prev = _snapshot;
    // توزيع جولةٍ جديدة (بداية المباراة أو بعد نتيجة جولة).
    final newDeal = s.phase == 'bidding' &&
        (prev == null || prev.roundResult != null || prev.phase == 'done');
    // توزيع الثلاث الباقية: الضمانة ⇒ اللعب واليد تكبر.
    final restDeal = prev != null &&
        prev.phase == 'bidding' &&
        s.phase == 'playing' &&
        s.myHand.length > prev.myHand.length;
    // انتهت الضمانة (آخر لقطة ضمانة ⇒ لعب/انتهاء) — لحظة مسك الفقاعات ثم تصفيرها.
    final biddingEnded =
        prev != null && prev.phase == 'bidding' && s.phase != 'bidding';
    final trickCompleted =
        prev != null && prev.trick.length == 4 && s.trick.length < 4;
    // انتهاء جولةٍ لم يسبقه إكمال أخذة (فوجة) ⇒ نمسك اللوحة يدويًّا (لا وقفة جمع تسبقها).
    final roundEnded = prev != null && prev.roundResult == null && s.roundResult != null;

    // ── فقاعة ضمانة المقعد الذي تحرّك (اشتقاقٌ من تغيّر اللقطة) ──
    if (newDeal) _seatBids = [null, null, null, null];
    if (prev != null && prev.phase == 'bidding' && s.phase == 'bidding') {
      // كل نيّة ضمانة يبثّها الخادم كلقطةٍ طورها «bidding»؛ صاحبها هو دور اللقطة
      // السابقة. نتجاهل اللقطات المكرّرة (عودة اتصال) بعدم التغيّر.
      final advanced =
          prev.turn != s.turn || prev.bid != s.bid || prev.akwins != s.akwins;
      if (advanced) _recordBidBubble(prev, s);
    }

    // ── أصوات، مثبّتةٌ على لحظة الحركة ──
    // صوت التوزيع: نقراتٌ متتابعة داخل نافذة التوزيع أدناه (حين تُفعَّل الحركة)، وإلّا
    // نقرةٌ واحدة هنا (وضع بلا حركة/الاختبارات). وصوت ختام الجولة يُطلَق حين تظهر اللوحة.
    if ((newDeal || restDeal) && dealAnim <= Duration.zero) _sfx(GameSound.deal);
    // صوت لعب الورقة يتأخّر ليتزامن مع هبوطها على الطاولة (مدّة الانزلاق).
    if (prev != null && s.trick.length > prev.trick.length) {
      _sfxDelayed(GameSound.cardPlay, cardLandDelay);
    }
    // بدء اعتراض فوجة (لأيّ لاعب) ⇒ تنبيهٌ يسمعه الجميع لحظةَ التجميد.
    if ((prev?.foujaClaimBy) == null && s.foujaClaimBy != null) {
      _sfx(GameSound.fouja);
    }

    // بدءُ دور لعبٍ جديدٍ لك ⇒ أعِد تشغيل عدّاد المهلة (مفتاحُ إعادة التشغيل).
    final myPlayTurn = s.phase == 'playing' && s.yourTurn;
    final wasMyPlayTurn = prev != null && prev.phase == 'playing' && prev.yourTurn;
    if (myPlayTurn && !wasMyPlayTurn) _turnSeq++;

    // ── نافذة توزيع جولةٍ جديدة (نقرات توزيعٍ متتابعة، كالأوفلاين) ──
    if (newDeal && dealAnim > Duration.zero) {
      _snapshot = s;
      _collectingTo = null;
      _dealingRest = false;
      _dealing = true;
      notifyListeners();
      await _dealTicks(dealAnim, 5);
      if (_disposed) return;
      _dealing = false;
      notifyListeners();
      return;
    }

    // ── انتهت الضمانة: امسك الفقاعات لتُقرأ ثم صفّرها قبل بدء اللعب ──
    if (biddingEnded && bidHold > Duration.zero && _seatBids.any((b) => b != null)) {
      _settlingBids = true; // يُخفي شريط الضمانة أثناء المسك
      notifyListeners(); // الفقاعات على لقطة الضمانة الأخيرة ما تزال ظاهرة
      await Future<void>.delayed(bidHold);
      if (_disposed) return;
      _settlingBids = false;
      _seatBids = [null, null, null, null];
      notifyListeners();
    } else if (biddingEnded) {
      _seatBids = [null, null, null, null];
    }

    // ── وقفةٌ لرؤية الورقة الأخيرة ثم جمع الأخذة نحو الفائز قبل إفراغها ──
    if (trickCompleted && collectAnim > Duration.zero) {
      final bid = _bidFromCode(prev.bid);
      if (bid != null) {
        if (trickPause > Duration.zero) {
          await Future<void>.delayed(trickPause); // الأربع ما تزال ظاهرة
          if (_disposed) return;
        }
        final winner = trickWinner(
          [for (final tc in prev.trick) (seat: tc.seat, card: cardFromCode(tc.card)!)],
          bid,
        );
        _collectingTo = _view(winner);
        _sfx(GameSound.cardCollect); // صوت جمع الأبلي مع بداية الحركة (كالأوفلاين)
        notifyListeners(); // اللقطة السابقة (4 أوراق) تنجمع
        await Future<void>.delayed(collectAnim);
        if (_disposed) return;
        _collectingTo = null;
      }
    }

    // ── تطبيق اللقطة (+ نافذة توزيع الثلاث الباقية بنقرات) ──
    _snapshot = s;
    if (restDeal && dealAnim > Duration.zero) {
      _dealingRest = true;
      _dealing = true;
      notifyListeners();
      await _dealTicks(dealAnim, 3);
      if (_disposed) return;
      _dealing = false;
      _dealingRest = false;
    }
    notifyListeners();

    // ختام الجولة: يُطلَق الصوت **حين تظهر لوحة النتيجة** (بعد جمع الأخذة) لا في بدايتها.
    if (roundEnded) _sfx(s.matchOver ? GameSound.win : GameSound.roundEnd);

    // ── استقرارٌ قصير بعد جمع الأخذة، أو مسكٌ للوحة نتيجة الفوجة (لا تسبقها وقفة جمع) ──
    if ((trickCompleted || roundEnded) && settle > Duration.zero) {
      await Future<void>.delayed(settle);
      if (_disposed) return;
    }

    // ── وقفة نتيجة الجولة بين الجولات: تُعرَض اللوحة لتُقرأ قبل التوزيع التالي (كالأوفلاين) ──
    if (roundEnded && !s.matchOver && resultHold > Duration.zero) {
      await Future<void>.delayed(resultHold);
      if (_disposed) return;
    }

    // ── تفريق ظهور اللعبات المتراكمة: كي لا تظهر أوراقٌ عدّة دفعةً واحدة بعد الوقفات ──
    final playGrew = prev != null && s.trick.length > prev.trick.length;
    if (playGrew && !newDeal && !restDeal && playStagger > Duration.zero) {
      await Future<void>.delayed(playStagger);
      if (_disposed) return;
    }
  }

  /// يشتقّ نصّ فقاعة المقعد الذي تحرّك بين لقطتَي ضمانة: أكوينس (بقيمة الضمانة
  /// القائمة) · ضمانةٌ جديدة (تغيّر الضامن) · وإلّا تمرير. يوازي `_bidActionLabel`
  /// في الأوفلاين لكن من فرق اللقطات لا من النيّة.
  void _recordBidBubble(GameEvent prev, GameEvent s) {
    final actor = prev.turn; // مقعد الخادم صاحب النيّة
    final String label;
    if (s.akwins && !prev.akwins) {
      final v = _bidFromCode(prev.bid)?.type == BidType.suit ? 32 : 52;
      label = '${S.akwins} $v';
    } else if (s.bidderSeat == actor && s.bid != prev.bid) {
      label = S.bidLabel(_bidFromCode(s.bid)!);
    } else {
      label = S.pass;
    }
    _seatBids[_view(actor)] = label;
  }

  // ── حالة ──
  LobbyEvent? get lobby => _lobby;

  /// تصنيف اللاعب بعد المباراة، أو `null` إن كانت غير مصنّفة (فيها ذكاء) أو لم تنتهِ.
  RatingEvent? get rating => _rating;

  /// **ملخّصُ المباراة** جاهزًا للعرض — من اللقطة الأخيرة التي بثّها الخادم.
  ///
  /// **الأسماءُ تُترجَم هنا**: الحصيلةُ بإحداثيّات الخادم، ومقاعدُ العرض مدارةٌ
  /// بحيث أكون أنا الأسفل ⇒ `_view` تربط بينهما. الملخّصُ يُعرَض للمصنَّفة وغيرِها
  /// (مبارياتُ الذكاء لها لحظاتُها أيضًا) — بخلاف التصنيف.
  MatchSummaryView? get matchSummary {
    final i = _snapshot?.insights;
    if (i == null) return null;
    return MatchSummaryView(
      insights: i,
      names: [for (var s = 0; s < 4; s++) seatPlayers[_view(s)].name],
      mySeat: mySeat,
    );
  }
  String? get errorCode => _errorCode;

  /// خبرٌ عابرٌ يُعرَض شريطًا فوق الطاولة ثمّ يمضي (فشلُ دعوةٍ أو هديّة)، أو null.
  String? get notice => _notice;

  /// **الأخطاء القاتلة وحدها** — قائمةٌ بيضاء: لا طاولةَ بعد أيٍّ منها، فالشاشةُ
  /// الكاملة صادقة. وما عداها **خبرٌ عابر** لا يمسّ لوبيًّا ولا مباراة.
  ///
  /// بيضاءُ لا سوداء **عمدًا** (نظير `UnknownEvent`): رمزٌ جديدٌ من خادمٍ أحدث يصير
  /// خبرًا عابرًا فلا يهدم طاولةً حيّة. الأسوأ أن نُخرج لاعبًا من مباراةٍ سليمةٍ
  /// لرمزٍ لم نكن نعرفه — والقائمةُ السوداء تنسى دائمًا.
  static const _fatalCodes = {
    'server_full',
    'unauthorized',
    'connection',
    'join_failed',
    'no_seat',
    // مشاهدةٌ تعذّرت ⇒ لا شيءَ يُعرَض بعدها — شاشةٌ كاملةٌ صادقة.
    'spectate_unavailable',
    'spectate_seated',
  };

  static bool _isFatal(String code) => _fatalCodes.contains(code);

  void _showNotice(String code) {
    _noticeTimer?.cancel();
    _notice = code;
    notifyListeners();
    if (reactionHold <= Duration.zero) return; // معطّلة (اختبارات)
    _noticeTimer = Timer(_noticeHold, () {
      _notice = null;
      if (!_disposed) notifyListeners();
    });
  }

  /// أطولُ من فقاعة التفاعل: هذا نصٌّ يُقرأ لا رمزٌ يُلمَح.
  static const _noticeHold = Duration(seconds: 4);

  /// يُخفي الخبر العابر فورًا (لمسةُ اللاعب على الشريط).
  void dismissNotice() {
    _noticeTimer?.cancel();
    _notice = null;
    notifyListeners();
  }
  /// مقعدي بإحداثيّات الخادم — من لقطة المباراة، أو من اللوبي قبل أن تبدأ
  /// (`you`). بلا الثانية يُدوَّر اللوبي حول المقعد 0 دائمًا، فيجلس اللاعب في غير
  /// موضعه ويصير «المقعد المقابل» شريكَ غيره.
  ///
  /// **المشاهدُ لا مقعدَ له** (`seat == -1`) ⇒ صفرٌ: يرى الطاولة من منظور مقعد
  /// الخادم 0 بلا تدوير — ولو دخل `-1` الحسابَ لانزاح كلُّ مقعدٍ موضعًا.
  int get mySeat {
    final s = _snapshot?.seat;
    if (s != null && s >= 0) return s;
    if (s == -1) return 0; // متفرّج
    return _lobby?.you ?? 0;
  }

  OnlineStage get stage {
    if (_errorCode != null) return OnlineStage.error;
    if (_snapshot != null) return OnlineStage.playing;
    if (_lobby != null) return OnlineStage.lobby;
    return OnlineStage.menu;
  }

  // ── نيّات اللوبي ──
  void quickMatch() => client.quickMatch();
  void createPrivate() => client.createPrivate();
  /// ينضمّ بالرمز. [seat] لدعوةٍ إلى مقعدٍ بعينه (نافذةً أو إشعارًا) — بلا تمريره
  /// يجلس في أوّل فارغٍ، فيصير شريكَ غيرِ من دعاه.
  void joinByCode(String code, {int? seat}) => client.joinByCode(code, seat: seat);
  void start() => client.start();

  /// بعد انتهاء المباراة (أُزيلت طاولتها على الخادم): يمسح حالة الطاولة فيرجع اللاعب
  /// إلى قائمة المطابقة (يختار منها مباراةً جديدة). الاتصال بالخادم يبقى قائمًا.
  void newMatch() {
    _snapshot = null;
    _lobby = null;
    _errorCode = null;
    _queue.clear();
    _flightTimer?.cancel(); // هديّةُ المباراة المنتهية لا تطير فوق التالية
    _flightQueue.clear();
    _flight = null;
    _collectingTo = null;
    _dealing = false;
    _dealingRest = false;
    _settlingBids = false;
    _seatBids = [null, null, null, null];
    _turnSeq = 0;
    notifyListeners();
  }

  // ── تدوير المقاعد ──
  int _view(int server) => (server - mySeat + 4) % 4;

  // ── التفاعلات (رموز تعبيريّة) ──

  /// مدّة بقاء فقاعة التفاعل فوق البطاقة. قصيرةٌ كي لا تحجب اللعب.
  final Duration reactionHold;

  final Map<int, String> _reactions = {}; // مقعد العرض → الرمز الظاهر الآن
  final Map<int, Timer> _reactionTimers = {};

  /// الرمز الظاهر فوق مقعد العرض [viewSeat] الآن، أو null.
  String? reactionAt(int viewSeat) => _reactions[viewSeat];

  /// الرموز الظاهرة الآن بترتيب العرض 0..3 (للواجهة).
  List<String?> get reactions => [for (var i = 0; i < 4; i++) _reactions[i]];

  /// يرسل تفاعلًا. الخادم يُثبّت الرمز ويحدّ المعدّل، ثم يبثّه للجميع — بما فيهم
  /// أنت: لا نعرضه محليًّا كي لا نُظهر ما أسقطه الخادم (حدّ/رمزٌ مرفوض).
  void react(String emoji) => client.react(emoji);

  // ── الدردشة السريعة والهدايا ──
  // كلاهما فقاعةٌ فوق مقعدٍ تختفي بعد [reactionHold] — نفس آليّة التفاعل بالضبط،
  // فتُشارِكها بدل أن تُنسَخ ثلاث مرّات.

  final Map<int, String> _chats = {}; // مقعد العرض → **نصّ** العبارة الظاهر (فقاعة)
  final Map<int, Timer> _chatTimers = {};
  final Map<int, String> _gifts = {}; // مقعد العرض → معرّف الهديّة المُستقبَلة
  final Map<int, Timer> _giftTimers = {};

  // ── طابورُ رحلات الهدايا ──────────────────────────────────────────────────
  //
  // **الزمنُ هنا لا في الودجت.** الكنترولر يقرّر متى تنطلق كلُّ رحلةٍ ومتى تهبط،
  // والطبقةُ البصريّة تنفّذ. فائدتان:
  //   • **رحلةٌ واحدةٌ في الجوّ** مهما تدفّقت الأحداث ⇒ لا تتراكب هديّتان فتصيرا
  //     لطخةً لا يُعرف مُرسلُها — وهديّةُ «للجميع» ثلاثةُ أحداثٍ في لحظةٍ واحدة.
  //   • الاختبارات (`reactionHold == 0`) تمرّ بلا مؤقّتٍ ولا حركة: الفقاعةُ تظهر
  //     فورًا كما كانت، فلا يتغيّر عقدُ أيّ اختبارٍ قائم.

  final List<GiftFlight> _flightQueue = [];
  GiftFlight? _flight;
  int _flightSeq = 0;
  Timer? _flightTimer;

  /// طولٌ أقصى للطابور. مَن يرشُّ الهدايا رشًّا لا يُطيل الطابورَ دقائقَ على من
  /// يلعب: ما زاد يهبط فقاعةً بلا رحلة — الخبرُ يصل والحركةُ لا تحتكر الشاشة.
  static const _flightQueueMax = 8;

  /// فُسحةٌ بين رحلةٍ وأخرى — بلا نفَسٍ تبدو المتتاليةُ رشَّ مدفع.
  static const _flightGap = Duration(milliseconds: 140);

  /// الرحلةُ في الجوّ الآن (تعرضها `GiftFlightLayer`)، أو null.
  GiftFlight? get giftFlight => _flight;

  /// المقعدُ المُرسِل والمقعدُ المستقبِل للرحلة الجارية — تُوهِج بطاقتاهما.
  int? get giftGlowFrom => _flight?.fromSeat;
  int? get giftGlowTo => _flight?.toSeat;

  /// يضع رحلةً في الطابور، ويُطلقها إن كان الجوُّ خاليًا.
  void _enqueueGift({
    required int? fromViewSeat,
    required int toViewSeat,
    required String giftId,
    required String senderName,
  }) {
    // **بلا حركة** (اختبارات/إعدادٌ يُبطلها): الفقاعةُ فورًا كما كانت بالضبط.
    if (reactionHold <= Duration.zero) {
      _showBubble(_gifts, _giftTimers, toViewSeat, giftId);
      return;
    }
    if (_flightQueue.length >= _flightQueueMax) {
      _showBubble(_gifts, _giftTimers, toViewSeat, giftId);
      return;
    }
    _flightQueue.add(GiftFlight(
      id: ++_flightSeq,
      fromSeat: fromViewSeat,
      toSeat: toViewSeat,
      senderName: senderName,
      receiverName: seatNameAt(toViewSeat),
      giftId: giftId,
    ));
    if (_flight == null) {
      _startNextFlight();
    } else {
      notifyListeners();
    }
  }

  /// يُطلق الرحلةَ التالية (إن بقيت)، ويجدول هبوطَها ثمّ التي بعدها.
  void _startNextFlight() {
    _flightTimer?.cancel();
    if (_flightQueue.isEmpty) {
      _flight = null;
      notifyListeners();
      return;
    }
    final f = _flightQueue.removeAt(0);
    _flight = f;
    _sfx(f.visuals.launchSound);
    notifyListeners();

    // الهبوط: صوتُ الوصول + الفقاعةُ تستقرّ فوق المستقبِل (الحركةُ تمضي والخبرُ يبقى).
    _flightTimer = Timer(f.travel, () {
      if (_disposed) return;
      _sfx(f.visuals.arriveSound);
      _showBubble(_gifts, _giftTimers, f.toSeat, f.giftId);
      // ثمّ أثرُ الوصول يُكمل مشهدَه قبل أن تنطلق التالية.
      _flightTimer = Timer(kGiftBurst + _flightGap, () {
        if (_disposed) return;
        _startNextFlight();
      });
    });
  }

  // ── المشاهدة ──

  int _watchers = 0;
  bool _spectateEnded = false;
  SpectatorGiftEvent? _standsGift;
  Timer? _standsGiftTimer;

  /// عددُ مشاهدي الطاولة الآن — شارةُ «👁» تظهر للجالسين والمتفرّجين حين يزيد
  /// عن صفر (الجمهورُ يُرى فيُحفّز).
  int get watchers => _watchers;

  /// انتهى العرضُ (أُزيلت الطاولة المُشاهدَة) — لا مزيدَ من اللقطات بعده.
  bool get spectateEnded => _spectateEnded;

  /// آخرُ هديّةِ مدرّجاتٍ وصلت (لافتةٌ باسم راميها)، أو null بعد مُهلة العرض.
  SpectatorGiftEvent? get standsGift => _standsGift;

  /// نصُّ لافتة هديّة المدرّجات: «فلان أهدى علّانًا» (الإيموجي تُلحقه الواجهة).
  String? get standsGiftLabel {
    final g = _standsGift;
    if (g == null) return null;
    final from = g.name.isEmpty ? 'مشاهد' : g.name;
    return '$from أهدى ${seatNameAt(_view(g.to))}';
  }

  /// اسمُ صاحب مقعد العرض [viewSeat] — للافتة هديّة المدرّجات («أهدى فلانًا»).
  String seatNameAt(int viewSeat) =>
      (viewSeat >= 0 && viewSeat < 4) ? seatPlayers[viewSeat].name : 'لاعب';

  /// مغادرةُ المشاهدة طوعًا (زرّ الخروج): تُنزل العدّاد عند الجميع فورًا —
  /// إغلاقُ القناة في dispose يكفي وظيفيًّا لكنّه أبطأ خبرًا.
  void stopSpectating() {
    if (isSpectator) client.spectateStop();
  }

  /// **سجلّ الدردشة** — لوحةُ الدردشة تعرضه (الفقاعاتُ عابرةٌ، واللوحةُ تحفظ).
  /// مقصوصٌ عند [_chatLogMax]: طاولةٌ ليست غرفةَ محادثةٍ لا نهائيّة.
  final List<ChatLogEntry> _chatLog = [];
  static const _chatLogMax = 60;
  List<ChatLogEntry> get chatLog => List.unmodifiable(_chatLog);

  /// النصُّ الظاهرُ فقاعةً الآن بترتيب العرض 0..3 (**نصوصٌ لا معرّفات**).
  List<String?> get chats => [for (var i = 0; i < 4; i++) _chats[i]];

  /// الهدايا الظاهرة الآن بترتيب العرض 0..3 (فوق المستقبِل).
  List<String?> get gifts => [for (var i = 0; i < 4; i++) _gifts[i]];

  /// يرسل عبارةً سريعة. كالتفاعل: لا عرض متفائل — ننتظر بثّ الخادم.
  void chat(String phraseId) => client.chat(phraseId);

  /// يرسل نصًّا حرًّا (قرار المالك 2026-07-15). الخادمُ ينظّفه ويقصّه.
  void chatText(String text) => client.chatText(text);

  // ── الدعوة ──

  InviteEvent? _invite;
  String? _inviteSentTo;

  /// دعوةٌ واردةٌ تنتظر ردّي، أو null. **الأحدث يزيح الأقدم**: نافذتان متراكمتان
  /// تُقبَل إحداهما بالخطأ.
  InviteEvent? get invite => _invite;

  /// آخر لاعبٍ وصلته دعوتي (لتأكيدٍ في الواجهة).
  String? get inviteSentTo => _inviteSentTo;

  /// يدعو صديقًا إلى **مقعد عرضٍ** [viewSeat] — يُترجَم لإحداثيّات الخادم كالهديّة.
  /// الخادم يتحقّق من الصداقة والحضور وحال المقعد.
  void inviteToSeat(String playerId, int viewSeat) =>
      client.invite(playerId, (viewSeat + mySeat) % 4);

  /// يقبل الدعوة الواردة: ينضمّ بالرمز **إلى مقعدها**.
  void acceptInvite() {
    final inv = _invite;
    if (inv == null) return;
    _invite = null;
    client.joinByCode(inv.code, seat: inv.seat);
    notifyListeners();
  }

  void dismissInvite() {
    _invite = null;
    notifyListeners();
  }

  /// يُهدي صاحبَ مقعد العرض [viewSeat]. الخادم يخصم ويتحقّق ثم يبثّ؛ الفشل (رصيد
  /// غير كافٍ) يصل كـ`ServerError` فيظهر للمُرسِل وحده.
  ///
  /// **[kGiftAll] (‎-1) يمرّ كما هو**: ليس مقعدًا فلا يُدار. كان يمرّ في تدوير
  /// العرض فيصير `(-1 + mySeat) % 4` — **مقعدًا حقيقيًّا**: «هديّةٌ للجميع» تذهب
  /// إلى لاعبٍ واحدٍ صامتةً، وفرعُ الخادم للجميع لا يُبلَغ أبدًا.
  void sendGift(int viewSeat, String giftId) => client.gift(
      viewSeat == kGiftAll ? kGiftAll : (viewSeat + mySeat) % 4, giftId);

  /// يُظهر القيمة فوق المقعد ويمسحها بعد [reactionHold]. قيمةٌ جديدةٌ من نفس المقعد
  /// تستبدل السابقة وتُعيد ضبط المؤقّت (لا تكديس).
  void _showBubble(Map<int, String> store, Map<int, Timer> timers, int viewSeat,
      String value) {
    timers.remove(viewSeat)?.cancel();
    store[viewSeat] = value;
    notifyListeners();
    if (reactionHold <= Duration.zero) return; // معطّلة (اختبارات)
    timers[viewSeat] = Timer(reactionHold, () {
      timers.remove(viewSeat);
      if (_disposed) return;
      store.remove(viewSeat);
      notifyListeners();
    });
  }

  /// هويّات المقاعد الأربعة بترتيب العرض (0 = أنت). الذكاء باسمٍ ثابت (يبدو
  /// لاعبًا حقيقيًّا) ورتبةٍ **صادقة** من مستوى الخادم (`LobbySeat.aiLevel`)،
  /// والبشر من بيانات اللوبي (اسم/اتصال).
  List<SeatPlayer> get seatPlayers {
    final out = List<SeatPlayer>.generate(4, (_) => const SeatPlayer(name: 'لاعب'));

    // **هويّاتُ اللقطة أوّلًا**: اللوبي يغيب عمّن جلس على مقعدٍ محجوز (بطولة) أو
    // أعاد الوصلَ في منتصف المباراة — وهما بالضبط الحالتان اللتان تُفقَد فيهما
    // الهويّة. فارغةٌ ⇒ خادمٌ أقدمُ من الميزة، فنسقط إلى اللوبي كما كان.
    final ids = _snapshot?.players ?? const [];
    if (ids.isNotEmpty) {
      for (final s in ids) {
        final pos = _view(s.seat);
        if (pos < 0 || pos > 3) continue;
        out[pos] = s.isAI || s.playerId.isEmpty
            ? aiSeatPlayer(Random(s.seat * 7919 + 13), level: _lobbyAiLevel(s.seat))
            : SeatPlayer(
                playerId: s.playerId,
                name: s.name.isNotEmpty ? s.name : 'لاعب',
                avatarUrl: s.avatarUrl,
                connected: s.connected,
                isVip: s.isVip,
                skill: s.skill,
              );
      }
      return out;
    }

    final lob = _lobby;
    if (lob != null) {
      for (final s in lob.seats) {
        final pos = _view(s.seat);
        if (pos < 0 || pos > 3) continue;
        if (s.ai) {
          // حتميٌّ من بذرة المقعد ⇒ ثابتٌ عبر الإطارات بلا خبيئة (خبيئةٌ هنا
          // كانت تُبقي رتبةً قديمة إن تغيّر مستوى الطاولة بانضمام بشريّ).
          out[pos] =
              aiSeatPlayer(Random(s.seat * 7919 + 13), level: s.aiLevel);
        } else {
          out[pos] = SeatPlayer(
            name: (s.name?.isNotEmpty ?? false) ? s.name! : 'لاعب',
            avatarUrl: s.avatarUrl,
            connected: s.connected,
            // **مَن دفع يُرى**: بلا هذا يجلس المشتركُ لاعبًا بسيطًا (بلاغُ المالك
            // 2026-07-16) — `isVip` كان حقلًا ميّتًا لا يصله شيء.
            isVip: s.isVip,
            skill: s.skill,
          );
        }
      }
    }
    return out;
  }

  /// **أهي غرفةُ VIP؟** مضيفُها مشترك ⇒ خلفيّتُه الخاصّة يراها كلُّ الجالسين.
  ///
  /// **تُقرأ من اللوبي المحفوظ** ولو أثناء اللعب: `_lobby` يبقى بعد البدء (منه
  /// تُبنى `seatPlayers` أصلًا) ⇒ لا طورَ جديدٌ يُبثّ ولا حزمةَ إلزاميّة.
  bool get vipRoom => _lobby?.vipRoom ?? false;

  /// مستوى الذكاء المُعلَن للمقعد من اللوبي (إن بقي) — كي تبقى رتبةُ الروبوت صادقة
  /// حتى حين تُبنى المقاعدُ من لقطة اللعب.
  String? _lobbyAiLevel(int serverSeat) {
    for (final s in _lobby?.seats ?? const []) {
      if (s.seat == serverSeat) return s.aiLevel;
    }
    return null;
  }

  /// معرّف لاعب كلّ مقعدٍ بترتيب العرض (0 = أنت · null للذكاء أو المقعد الفارغ).
  /// معرّف اللاعب هو **هويّته في غرفة الصوت** ⇒ به تُعرف بطاقةُ من يتكلّم.
  List<String?> get seatPlayerIds {
    final out = List<String?>.filled(4, null);
    // اللقطةُ أوّلًا كـ[seatPlayers] — نفسُ العلّة ونفسُ الحلّ.
    final ids = _snapshot?.players ?? const [];
    if (ids.isNotEmpty) {
      for (final s in ids) {
        final pos = _view(s.seat);
        if (s.isAI || s.playerId.isEmpty || pos < 0 || pos > 3) continue;
        out[pos] = s.playerId;
      }
      return out;
    }
    for (final s in _lobby?.seats ?? const []) {
      final pos = _view(s.seat);
      if (s.ai || pos < 0 || pos > 3) continue;
      out[pos] = s.playerId;
    }
    return out;
  }

  // ── عقود العرض المشتقّة ──

  /// لقطة الطاولة للعرض، أو null إن لم نكن في مباراة.
  TableView? get tableView {
    final s = _snapshot;
    if (s == null) return null;

    final counts = List<int>.filled(4, 0);
    for (var seat = 0; seat < s.handCounts.length; seat++) {
      counts[_view(seat)] = s.handCounts[seat];
    }
    final trick = <Play>[
      for (final tc in s.trick) (seat: _view(tc.seat), card: cardFromCode(tc.card)!),
    ];

    return TableView(
      myHand: _sortedHand(s),
      handCounts: counts,
      usScore: s.usScore,
      themScore: s.themScore,
      bid: _bidFromCode(s.bid),
      bidderSeat: s.bidderSeat == null ? null : _view(s.bidderSeat!),
      akwins: s.akwins,
      dealerSeat: _view(s.dealerSeat),
      seatBids: List.unmodifiable(_seatBids),
      turn: _view(s.turn),
      trick: trick,
      collectingTo: _collectingTo,
      legalCards: {for (final c in s.legalCards) cardFromCode(c)!},
      humanCanPlay: s.yourTurn && s.phase == 'playing' && !_dealing,
      phase: _dealing ? GamePhase.dealing : _phase(s.phase),
      dealingRest: _dealingRest,
      // زرّ الفوجة يظهر فقط حين لا اعتراضَ جاريًا (وإلّا الطاولة مجمّدة عند الجميع).
      canAccuseFouja: s.canAccuseFouja && s.foujaClaimBy == null && !_dealing,
      claimingFouja: s.foujaClaimBy == s.seat, // المعترِض أنت ⇒ لوحة الاختيار
      foujaClaimBy: s.foujaClaimBy == null ? null : _view(s.foujaClaimBy!),
      revealedHands: _revealedHands(s),
      // عدّاد المهلة يظهر في دور لعبك فقط، وبلا اعتراض فوجةٍ يجمّد الطاولة.
      humanTurnLimit:
          (s.yourTurn && s.phase == 'playing' && s.foujaClaimBy == null) ? _turnLimit : null,
      humanTurnSeq: _turnSeq,
    );
  }

  /// أيدي المقاعد الأربعة مكشوفةً بترتيب العرض (تصل في لقطة نتيجة الفوجة)، أو null.
  List<List<Card>>? _revealedHands(GameEvent s) {
    final rev = s.revealedHands;
    if (rev == null) return null;
    final out = List<List<Card>>.generate(4, (_) => <Card>[]);
    for (var srv = 0; srv < rev.length && srv < 4; srv++) {
      out[_view(srv)] = [for (final c in rev[srv]) cardFromCode(c)!];
    }
    return out;
  }

  /// يد اللاعب مرتّبةً للعرض: تجميعٌ حسب اللون ثم القوة داخل اللون بحسب الضمانة
  /// الجارية — مطابقٌ لترتيب الأوفلاين (`GameController._sortedHand`). ترتيب عرضٍ
  /// محض؛ الخادم هو من يفرض القانونية فلا يمسّ هذا شيئًا من القواعد.
  List<Card> _sortedHand(GameEvent s) {
    final settled = s.phase == 'playing' || s.phase == 'done';
    final bid = (settled ? _bidFromCode(s.bid) : null) ?? const Bid.sans();
    final sorted = [for (final c in s.myHand) cardFromCode(c)!];
    sorted.sort((a, b) {
      final bySuit = handSuitOrder.indexOf(a.suit) - handSuitOrder.indexOf(b.suit);
      if (bySuit != 0) return bySuit;
      return strength(bid, a) - strength(bid, b); // الأقوى أولًا داخل اللون
    });
    return sorted;
  }

  /// شريط الضمانة — غير null فقط حين يكون الدور دوري في طور الضمانة.
  BidBarView? get bidBar {
    final s = _snapshot;
    if (_settlingBids) return null; // مسك فقاعات نهاية الضمانة ⇒ لا شريط
    if (s == null || s.phase != 'bidding' || !s.yourTurn) return null;
    bool has(bool Function(LegalBid) t) => s.legalBids.any(t);

    final options = <BidOption>[
      BidOption(
        label: S.pass,
        action: const BidAction.pass(),
        enabled: has((b) => b.kind == 'pass'),
        isPass: true,
      ),
      for (final name in bids)
        BidOption(
          label: S.bidLabel(_bidForName(name)),
          suit: _bidForName(name).suit,
          action: BidAction.ofBid(_bidForName(name)),
          enabled: has((b) => b.kind == 'bid' && b.bid == _bidForName(name).code),
        ),
      if (has((b) => b.kind == 'akwins'))
        const BidOption(
          label: S.akwins,
          action: BidAction.akwins(),
          enabled: true,
          isAkwins: true,
        ),
    ];
    return BidBarView(options: options, currentBid: _bidFromCode(s.bid));
  }

  /// نتيجة الجولة إن انتهت (يبثّها الخادم في اللقطة).
  RoundResult? get roundResult {
    final s = _snapshot;
    final rr = s?.roundResult;
    if (s == null || rr == null) return null;
    // الفريق الفائز صراحةً من الخادم (يصحّ حتى للفوز بالجولة البيضاء برصيدٍ أقلّ)،
    // وإلّا (توافقًا مع لقطاتٍ قديمة) يُشتقّ من مقارنة النقاط.
    final Object? outcome =
        s.matchOver ? (s.matchWinner ?? (s.usScore >= s.themScore ? 0 : 1)) : null;
    return RoundResult(
      usPoints: rr.us,
      themPoints: rr.them,
      roundValue: rr.us + rr.them,
      reason: rr.reason,
      usTotal: s.usScore,
      themTotal: s.themScore,
      matchOutcome: outcome,
      foujaProven: rr.proven,
    );
  }

  // ── نيّات المباراة ──

  /// يُرسِل الضمانة المختارة كفهرسٍ في قائمة الخادم القانونية (البروتوكول يستقبل فهرسًا).
  void placeBid(BidAction action) {
    final s = _snapshot;
    if (s == null) return;
    final idx = s.legalBids.indexWhere(
        (b) => b.kind == action.kind.name && b.bid == action.bid?.code);
    if (idx < 0) return; // غير قانونيّ الآن ⇒ يُتجاهَل (الخادم هو الحكَم)
    client.bid(idx);
  }

  void playCard(Card card) => client.play(card.code);

  // ── الفوجة (RULES.md §8) ──

  /// يبدأ اعتراض فوجة على الخادم: تتجمّد الطاولة عند الجميع ويظهر لهم من يعترض،
  /// وتُفتح لوحة اختيار الخصم لك حين تعود لقطة الخادم حاملةً `foujaClaimBy`. لا كشف
  /// قبل الحسم (لافتة فقط للبقيّة). الصوت يُطلق لحظة التجميد في `_apply` عند الجميع.
  void startFoujaClaim() {
    if (_snapshot?.phase != 'playing' || _snapshot?.foujaClaimBy != null) return;
    client.startFoujaClaim();
  }

  /// يُلغي اعتراضك على الخادم ⇒ يرفع التجميد ويُستأنف اللعب عند الجميع.
  void cancelFoujaClaim() => client.cancelFoujaClaim();

  /// يعترض على خصمٍ بمقعد العرض ([viewSeat] 1 يمينك · 3 يسارك). يحوّله إلى مقعد الخادم
  /// ويرسله؛ الخادم يحسم ويكشف ويبثّ نتيجة الفوجة (ويرفع التجميد).
  void accuseFouja(int viewSeat) {
    final serverSeat = (viewSeat + mySeat) % 4; // عكس تدوير العرض
    client.accuse(serverSeat);
  }

  // ── محوّلات ──
  Bid _bidForName(String name) => switch (name) {
        'sans' => const Bid.sans(),
        'tout' => const Bid.tout(),
        _ => Bid.ofSuit(name),
      };

  Bid? _bidFromCode(String? code) => switch (code) {
        null => null,
        'N' => const Bid.sans(),
        'A' => const Bid.tout(),
        _ => Bid.ofSuit(suitCode.entries.firstWhere((e) => e.value == code).key),
      };

  GamePhase _phase(String p) => switch (p) {
        'bidding' => GamePhase.bidding,
        'done' => GamePhase.done,
        _ => GamePhase.playing,
      };

  @override
  void dispose() {
    _disposed = true; // يوقف الإشعار/الصوت في الحلقات المؤجَّلة فورًا
    for (final timers in [_reactionTimers, _chatTimers, _giftTimers]) {
      for (final t in timers.values) {
        t.cancel(); // لا مؤقّت فقاعةٍ يوقظ كنترولرًا متلَفًا
      }
      timers.clear();
    }
    _standsGiftTimer?.cancel(); // لافتة هديّة المدرّجات — كسائر المؤقّتات
    _flightTimer?.cancel(); // رحلةُ الهديّة الجارية: لا هبوطَ في كنترولرٍ متلَف
    _flightQueue.clear();
    _noticeTimer?.cancel(); // كفقاعات المقاعد: لا يوقظ كنترولرًا متلَفًا
    _sub.cancel();
    _statusSub.cancel();
    client.dispose();
    super.dispose();
  }
}

/// سطرٌ في سجلّ الدردشة — يُعرَض في لوحة الدردشة. [viewSeat] بترتيب العرض (0=أنت)،
/// و[mine] كي تُحاذى رسالتُك يمينًا وتُصبَغ بلونٍ مميّز. [senderId] معرّفُ القائل
/// (null للذكاء) — به يقع البلاغُ/الحظرُ بضغطةٍ مطوّلة على رسالته.
class ChatLogEntry {
  final int viewSeat;
  final String text;
  final bool mine;
  final String? senderId;
  const ChatLogEntry({
    required this.viewSeat,
    required this.text,
    required this.mine,
    this.senderId,
  });
}
