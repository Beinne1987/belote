import 'dart:developer' as dev;
import 'dart:math';

import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/foundation.dart';

import '../motion.dart';
import '../strings_ar.dart';
import 'ai.dart';
import 'seat_player.dart';
import 'view_model.dart';

/// **الجسر الوحيد إلى المحرك.** كل استدعاء لدوال القواعد يحدث هنا؛ الواجهة
/// تقرأ [tableView] و[bidBar] الجاهزين وتُطلق النيّات فقط. هكذا لا تتسرّب
/// قاعدة إلى `ui/` (يحرسه `ui_no_rules_test`).
///
/// جولة واحدة كاملة: توزيع ← ضمانة ← (٨ أبالي ← نقاط في الخطوات القادمة).
/// البذرة قابلة للحقن وتُطبع عند بدء كل جولة (تصحيح ٤: كل خطأ قابل للإعادة).
class GameController extends ChangeNotifier {
  final int seed;

  // توقيتات الإيقاع — قابلة للحقن كي تُصفّرها الاختبارات وتلعب جولة فورًا.
  // الإنتاج يستخدم قيم motion.dart.
  final Duration _aiThink;
  final Duration _pliPause;
  final Duration _pliCollect;
  final Duration _pliSettle;
  final Duration _bidHold;
  final Duration _dealPause;

  /// تأخيرُ صوتِ لعب الورقة كي يتزامن مع **هبوطها** على الطاولة (مدّة انزلاقها)، لا مع
  /// بدء الانزلاق. صفر في الاختبارات (فوريّ). = `Motion.slideCard` في الإنتاج.
  final Duration _cardLandDelay;

  /// احتمال أن يرتكب خصمٌ آليّ فوجةً (يترك اتباع اللون رغم امتلاكه) في اللعبة الواحدة.
  /// صفر في الاختبارات ⇒ حتمية؛ الإنتاج يحقن قيمة صغيرة كي يجد اللاعب ما يكتشفه.
  final double _aiFoujaChance;

  /// احتمال أن يكتشف خصمٌ آليّ فوجةَ اللاعب فيعترض عليها. صفر ⇒ لا يعترض (اختبارات/تعطيل).
  final double _aiAccuseChance;

  /// مهلة «تفكير» الخصم قبل الاعتراض على فوجتك — كي لا تنتهي الجولة فجأةً. صفر ⇒ فوري (اختبارات).
  final Duration _aiAccuseDelay;

  /// مدّة عرض نتيجة الجولة قبل التقدّم التلقائي للجولة التالية. صفر ⇒ معطّل
  /// (اختبارات: تقدّمٌ يدويّ). عند فوز المباراة لا تقدّم تلقائي — ينتظر «مباراة جديدة».
  final Duration _resultHold;

  /// مهلة دور اللاعب البشري (ضمانةً أو لعبًا) قبل أن يلعب الذكاء مكانه. صفر ⇒ معطّل.
  final Duration _humanTurnLimit;

  /// رمز انتظار اللاعب — يُبطِل مؤقّت الدور القديم متى بدأ دورٌ جديد أو لعب اللاعب.
  int _humanWaitToken = 0;

  /// خطّاف الصوت — يوصله `main.dart` بـ `Sfx`. null في الاختبارات ⇒ صامت.
  final void Function(GameSound sound)? onSound;

  late Lcg _rng;
  late List<List<Card>> _hands;
  late List<Card> _openingRest;
  late BiddingState _bidding;
  // تتغيّر في الخطوات القادمة (تدوير الموزّع، تجميع النقاط) — ليست final.
  // ignore: prefer_final_fields
  int _dealer = 3; // الموزّع 3 ⇒ أول من يضمن ويلعب هو المقعد 0 = أنت (تصحيح ٢)
  GamePhase _phase = GamePhase.bidding;
  // ignore: prefer_final_fields
  int _usScore = 0;
  // ignore: prefer_final_fields
  int _themScore = 0;
  List<Play> _trick = const [];
  int _playTurn = 0;
  final List<int> _units = [0, 0]; // وحدات الفريقين خلال الجولة
  final List<int> _tricksWon = [0, 0]; // أبالي كل فريق هذه الجولة (لكشف الجولة البيضاء)
  final List<int> _whiteStreak = [0, 0]; // جولاتٌ بيضاء متتالية لكل فريق (مستوى المباراة)
  Object? _matchOutcome; // فائز المباراة المحسوم (0|1|'tiebreak'|null) — قد تحسمه الجولة البيضاء
  int? _collectingTo; // مقعد الفائز أثناء جمع الأبلي
  int _lastTrickWinner = 0; // لِلدير
  List<String?> _seatBids = [null, null, null, null]; // فقاعة ضمانة كل مقعد
  bool _dealingRest = false; // نافذة التوزيع الثانية (الثلاث الباقية بعد الضمانة)
  List<bool> _seatFouja = [false, false, false, false]; // هل فوّج كل مقعد هذه الجولة

  /// **ما تركه كلُّ مقعدٍ من ألوانٍ على مرأى الجميع**: لونُ افتتاحٍ لم يتبعه.
  /// هذا وحدَه ما يعرفه الجالسون — أمّا أنّه كان يملك اللون فلا يظهر إلّا إن
  /// عاد فلعبه لاحقًا. عليه يقوم كشفُ الذكاء للفوجة ([[online-fouja]]).
  List<Set<String>> _renounced = [{}, {}, {}, {}];
  bool _revealAll = false; // كشف كل الأيدي (عند المطالبة بفوجة وفي النتيجة)
  bool _claimingFouja = false; // لوحة اختيار الخصم المتّهَم ظاهرة (اللعب متوقّف)

  /// هل ننتظر إدخال اللاعب البشري (ضمانةً أو لعبًا)؟
  bool _awaitingHuman = false;

  /// أُتلِف المتحكّم (غادر اللاعب الطاولة). يوقف كل حلقات التأخير والصوت والإشعار —
  /// فلا تبقى اللعبة «تلعب» في الخلفية بعد زرّ الرجوع.
  bool _disposed = false;

  /// مولّدٌ مستقلّ لتشويش توقيت الذكاء (لا يمسّ [_rng] لئلّا يختلّ حتمية اللعبة).
  final Random _jitter = Random();

  /// مهلة «تفكير» الذكاء مع تشويشٍ عشوائيّ ⇒ إيقاعٌ بشريّ. صفرٌ في الاختبارات (فوريّ).
  Duration get _thinkDelay => _aiThink <= Duration.zero
      ? Duration.zero
      : _aiThink +
          Duration(milliseconds: _jitter.nextInt(Motion.aiThinkJitter.inMilliseconds + 1));

  GameController({
    int? seed,
    Duration aiThink = Motion.aiThink,
    Duration pliPause = Motion.pliPause,
    Duration pliCollect = Motion.pliCollect,
    Duration pliSettle = Motion.pliSettle,
    Duration bidHold = Motion.bidBubbleHold,
    Duration dealPause = Motion.deal,
    double aiFoujaChance = 0,
    double aiAccuseChance = 0,
    Duration aiAccuseDelay = Duration.zero,
    Duration resultHold = Duration.zero,
    Duration humanTurnLimit = Duration.zero,
    Duration cardLandDelay = Motion.slideCard,
    this.onSound,
  })  : seed = seed ?? (DateTime.now().millisecondsSinceEpoch & 0xFFFFFFFF),
        _aiThink = aiThink,
        _pliPause = pliPause,
        _pliCollect = pliCollect,
        _pliSettle = pliSettle,
        _bidHold = bidHold,
        _dealPause = dealPause,
        _cardLandDelay = cardLandDelay,
        _aiFoujaChance = aiFoujaChance,
        _aiAccuseChance = aiAccuseChance,
        _aiAccuseDelay = aiAccuseDelay,
        _resultHold = resultHold,
        _humanTurnLimit = humanTurnLimit {
    _rng = Lcg(this.seed); // مولّد واحد يستمر عبر الجولات (خلط مختلف كل جولة)
    _startRound();
  }

  @override
  void dispose() {
    _disposed = true; // يوقف الحلقات المؤجَّلة والصوت فورًا عند مغادرة الطاولة
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return; // لا إشعار بعد الإتلاف (يمنع الأعطال ويوقف التحديث)
    super.notifyListeners();
  }

  /// صوتٌ محروس: لا يُشغَّل بعد مغادرة الطاولة (يوقف إزعاج الصوت في الخلفية).
  void _sfx(GameSound sound) {
    if (!_disposed) onSound?.call(sound);
  }

  /// صوتٌ مؤجَّل [delay] كي يتزامن مع لحظةٍ في الحركة (مثل هبوط الورقة). صفرٌ ⇒ فوريّ.
  void _sfxDelayed(GameSound sound, Duration delay) {
    if (_disposed) return;
    if (delay <= Duration.zero) {
      _sfx(sound);
      return;
    }
    Future.delayed(delay, () => _sfx(sound));
  }

  /// صوت ختام الجولة: نغمة الفوز إن حُسِمت المباراة، وإلّا نغمة انتهاء الجولة العاديّة.
  void _sfxRoundEnd() =>
      _sfx(_matchOutcome == 0 || _matchOutcome == 1 ? GameSound.win : GameSound.roundEnd);

  /// هويّات المقاعد الأربعة (ثابتة طوال المباراة): 0 نائبٌ للبشريّ (تبدّله الواجهة
  /// بالاسم الحقيقيّ)، و1..3 ذكاءٌ باسمٍ وتصنيف كأنه لاعب حقيقيّ.
  late final List<SeatPlayer> seatPlayers = offlineSeatPlayers(seed);

  /// وحدات الفريقين في الجولة (0 = نحن، 1 = هم) — للاختبار وللنقاط (خطوة ٧).
  List<int> get roundUnits => List.unmodifiable(_units);

  RoundResult? _roundResult;

  /// نتيجة الجولة المنتهية (null قبل النهاية).
  RoundResult? get roundResult =>
      _phase == GamePhase.done ? _roundResult : null;

  // ── عقود العرض للواجهة ──

  TableView get tableView => TableView(
        myHand: _sortedHand(),
        handCounts: [for (final h in _hands) h.length],
        usScore: _usScore,
        themScore: _themScore,
        bid: _bidding.currentBid,
        bidderSeat: _bidding.bidderSeat,
        akwins: _bidding.akwins,
        dealerSeat: _dealer,
        seatBids: List.unmodifiable(_seatBids),
        turn: _phase == GamePhase.bidding ? _bidding.turn : _playTurn,
        trick: _trick,
        collectingTo: _collectingTo,
        legalCards: _humanLegalPlays(),
        humanCanPlay: _phase == GamePhase.playing && _awaitingHuman,
        phase: _phase,
        dealingRest: _dealingRest,
        canAccuseFouja: _phase == GamePhase.playing && !_claimingFouja,
        claimingFouja: _claimingFouja,
        revealedHands: _revealAll
            ? [for (final hnd in _hands) List<Card>.unmodifiable(hnd)]
            : null,
        humanTurnLimit:
            _humanTurnLimit > Duration.zero ? _humanTurnLimit : null,
        humanTurnSeq: _humanWaitToken,
      );

  /// يد اللاعب البشري مرتّبةً للعرض: **تجميع حسب اللون** (بترتيب [handSuitOrder]
  /// المتناوب لونيًّا) ثم القوة داخل اللون بحسب الضمانة الجارية. ترتيب عرض محض —
  /// لا يمسّ منطق المحرك (`legalPlays`/`remove` لا يعتمدان على ترتيب اليد).
  List<Card> _sortedHand() {
    // قبل استقرار الضمانة نرتّب بسُلَّم «صن» (ثابت، بلا قفزات) — كما في المرجع؛
    // ومتى بدأ اللعب نعيد الترتيب بحسب الحكم النهائي.
    final settled = _phase == GamePhase.playing || _phase == GamePhase.done;
    final bid = settled ? (_bidding.currentBid ?? const Bid.sans()) : const Bid.sans();
    final sorted = [..._hands[0]];
    sorted.sort((a, b) {
      final bySuit = handSuitOrder.indexOf(a.suit) - handSuitOrder.indexOf(b.suit);
      if (bySuit != 0) return bySuit;
      return strength(bid, a) - strength(bid, b); // الأقوى أولًا داخل اللون
    });
    return sorted;
  }

  /// شريط الضمانة — غير null فقط حين ينتظر الدور اللاعب البشري ليضمن.
  BidBarView? get bidBar {
    if (_phase != GamePhase.bidding || !_awaitingHuman) return null;
    final legal = legalBidActions(_bidding);
    bool legalHas(bool Function(BidAction) test) => legal.any(test);

    final options = <BidOption>[
      BidOption(
        label: S.pass,
        action: const BidAction.pass(),
        enabled: legalHas((a) => a.kind == BidKind.pass),
        isPass: true,
      ),
      // الستّ ضمانات بترتيب المحرك المُلزِم — المعطّلة تُعرض ولا تُخفى.
      for (final name in bids)
        BidOption(
          label: S.bidLabel(_bidForName(name)),
          action: BidAction.ofBid(_bidForName(name)),
          enabled: legalHas(
              (a) => a.kind == BidKind.bid && a.bid == _bidForName(name)),
        ),
      // الأكوينس يظهر فقط حين يكون قانونيًا (سياق الخصم، بعد ضمانة).
      if (legalHas((a) => a.kind == BidKind.akwins))
        const BidOption(
          label: S.akwins,
          action: BidAction.akwins(),
          enabled: true,
          isAkwins: true,
        ),
    ];
    return BidBarView(options: options, currentBid: _bidding.currentBid);
  }

  // ── نيّات اللاعب البشري ──

  /// اللاعب البشري يضمن. الشريط لا يعرض إلا الإجراءات القانونية، لكن نتحقّق
  /// دفاعيًا عبر المحرك.
  void placeBid(BidAction action) {
    if (_phase != GamePhase.bidding || _bidding.turn != 0 || !_awaitingHuman) {
      return;
    }
    _seatBids[0] = _bidActionLabel(action); // فقاعة أمامك قبل التطبيق
    applyBidAction(_bidding, action);
    _awaitingHuman = false;
    notifyListeners();
    _advanceBidding();
  }

  /// نصّ فقاعة الضمانة لمقعدٍ ما (يُحسب **قبل** التطبيق كي يقرأ الأكوينس الضمانة
  /// الجارية 32/52 قبل أن تُغلَق).
  String _bidActionLabel(BidAction action) => switch (action.kind) {
        BidKind.pass => S.pass,
        BidKind.akwins =>
          '${S.akwins} ${_bidding.currentBid?.type == BidType.suit ? 32 : 52}',
        BidKind.bid => S.bidLabel(action.bid),
      };

  // ── سير الجولة ──

  /// جولة جديدة تُبقي رصيد المباراة. الموزّع يدور: موزّع الجولة القادمة = أول
  /// لاعب هذه الجولة = يمين الموزّع الحالي (docs/RULES.md).
  void newRound() {
    if (_phase != GamePhase.done) return;
    // بعد إعلان فائز المباراة لا تُلعب «جولة» تواصل التراكم — يلزم مباراة جديدة.
    // نعتمد الفائز المحسوم (قد تحسمه الجولة البيضاء برصيدٍ أقلّ من 100).
    if (_matchOutcome == 0 || _matchOutcome == 1) return;
    _dealer = firstBidder(_dealer);
    _startRound();
  }

  /// مباراة جديدة: تصفير رصيد الفريقين والبدء من الصفر. يُستدعى بعد إعلان الفائز
  /// (بلوغ 100 والأعلى). الجولة الفاصلة (tiebreak) تُلعب بـ [newRound] لا هنا.
  void newMatch() {
    if (_phase != GamePhase.done) return;
    _usScore = 0;
    _themScore = 0;
    _whiteStreak[0] = 0;
    _whiteStreak[1] = 0;
    _matchOutcome = null;
    // **راوٍ جديدٌ لمباراةٍ جديدة**: لقطاتُ المباراة الماضية ليست لقطاتِ هذه، وإبقاؤها
    // كان سيعرض «أقوى ورقة» لُعبت في مباراةٍ انتهت.
    _tracker = MatchTracker();
    _insights = null;
    _dealer = firstBidder(_dealer);
    _startRound();
  }

  Future<void> _startRound() async {
    // تصفير حالة الجولة (الرصيد يبقى في _usScore/_themScore).
    _units[0] = 0;
    _units[1] = 0;
    _tricksWon[0] = 0;
    _tricksWon[1] = 0;
    _trick = const [];
    _collectingTo = null;
    _awaitingHuman = false;
    _roundResult = null;
    _seatBids = [null, null, null, null];
    _dealingRest = false;
    _seatFouja = [false, false, false, false];
    _renounced = [{}, {}, {}, {}];
    _revealAll = false;
    _claimingFouja = false;
    _phase = GamePhase.dealing;

    final deck = shuffle(buildDeck(), _rng); // مولّد مستمر ⇒ خلط جديد
    final opening = dealOpening(deck);
    _hands = opening.hands;
    _openingRest = opening.rest;
    _bidding = createBidding(_dealer);
    dev.log('ROUND seed=$seed dealer=$_dealer', name: 'belote');
    notifyListeners(); // الواجهة تُظهر توزيعًا من مقعد الموزّع

    // نافذة التوزيع العرضية: نقرات صوتية متتابعة ثم الانتقال للضمانة.
    if (_dealPause > Duration.zero) {
      const ticks = 5;
      final gap = Duration(
          microseconds: _dealPause.inMicroseconds ~/ (ticks + 1));
      for (var i = 0; i < ticks; i++) {
        await Future.delayed(gap);
        if (_disposed) return;
        _sfx(GameSound.deal);
      }
      await Future.delayed(gap);
    }

    _phase = GamePhase.bidding;
    notifyListeners();
    _advanceBidding();
  }

  /// يبدأ مهلة دور اللاعب البشري: إن انقضت ولا يزال ينتظره ⇒ يلعب الذكاء مكانه.
  /// [bidding] يميّز الضمانة عن اللعب. يُبطَل تلقائيًا إن بدأ دورٌ جديد (تغيّر الرمز).
  void _startHumanTimeout({required bool bidding}) {
    if (_humanTurnLimit <= Duration.zero) return;
    final token = ++_humanWaitToken;
    Future.delayed(_humanTurnLimit, () {
      if (_disposed || token != _humanWaitToken || !_awaitingHuman) return; // مغادرة أو لعب أو تغيّر الدور
      if (bidding) {
        if (_phase != GamePhase.bidding || _bidding.turn != 0) return;
        final action = aiBid(_bidding, _hands[0]);
        _seatBids[0] = _bidActionLabel(action);
        applyBidAction(_bidding, action);
        _awaitingHuman = false;
        notifyListeners();
        _advanceBidding();
      } else {
        if (_phase != GamePhase.playing || _playTurn != 0) return;
        final card = aiPlay(0, _hands[0], _trick, _bidding.currentBid!);
        _awaitingHuman = false;
        _playCardInternal(0, card);
        notifyListeners();
        _advancePlay();
      }
    });
  }

  Future<void> _advanceBidding() async {
    while (!_bidding.finished) {
      if (_bidding.turn == 0) {
        _awaitingHuman = true; // دور اللاعب البشري ← اعرض الشريط وانتظر
        notifyListeners();
        _startHumanTimeout(bidding: true); // مهلة ثم يضمن الذكاء مكانك
        return;
      }
      await Future.delayed(_thinkDelay);
      if (_disposed) return;
      final seat = _bidding.turn;
      final action = aiBid(_bidding, _hands[seat]);
      _seatBids[seat] = _bidActionLabel(action); // فقاعة أمام المقعد قبل التطبيق
      applyBidAction(_bidding, action);
      notifyListeners();
    }
    await _finishBidding();
  }

  Future<void> _finishBidding() async {
    // تبقى فقاعات ضمانة كل لاعب أمامه لحظةً كي تُقرأ قبل أن يبدأ اللعب.
    if (_bidHold > Duration.zero) {
      await Future.delayed(_bidHold);
      if (_disposed) return;
    }
    // الضمانة الرسمية تنتقل إلى لوح الطاولة ⇒ تُفرَّغ الفقاعات.
    _seatBids = [null, null, null, null];
    // التوزيع الأخير (+٣ ⇒ ٨ لكل لاعب).
    dealRest(_hands, _openingRest);

    // نافذة توزيع ثانية عرضية: الثلاث الباقية تنطلق من الموزّع بصوتٍ قبل بدء اللعب.
    // نفس بوّابة الإيقاف كالافتتاح كي تتخطّاها الاختبارات (dealPause: zero). أثناء
    // طور dealing تختفي المراوح وتظهر أوراقٌ طائرة، ثم تعود المراوح بثماني ورقات.
    if (_dealPause > Duration.zero) {
      _dealingRest = true;
      _phase = GamePhase.dealing;
      notifyListeners();
      const ticks = 3;
      final gap = Duration(
          microseconds: Motion.dealRest.inMicroseconds ~/ (ticks + 1));
      for (var i = 0; i < ticks; i++) {
        await Future.delayed(gap);
        if (_disposed) return;
        _sfx(GameSound.deal);
      }
      await Future.delayed(gap);
      _dealingRest = false;
    }

    _phase = GamePhase.playing;
    _tracker.roundStarted(
      bid: _bidding.currentBid!,
      bidderSeat: _bidding.bidderSeat!,
      akwins: _bidding.akwins,
    );
    _playTurn = firstBidder(_dealer); // أول من يلعب = يمين الموزّع = المقعد 0
    _trick = const [];
    dev.log(
      'BID DONE bid=${_bidding.currentBid?.code} bidder=${_bidding.bidderSeat} akwins=${_bidding.akwins}',
      name: 'belote',
    );
    notifyListeners();
    _advancePlay();
  }

  // ── حلقة اللعب: ٨ أبالي ──

  Future<void> _advancePlay() async {
    final bid = _bidding.currentBid!;
    while (_phase == GamePhase.playing) {
      if (_claimingFouja) return; // لوحة الفوجة مفتوحة ⇒ توقّف حتى الحسم/الإلغاء
      if (_trick.length == 4) {
        await _resolveTrick(bid);
        continue;
      }
      if (_playTurn == 0) {
        _awaitingHuman = true; // دور اللاعب البشري ← انتظر لمسه
        notifyListeners();
        _startHumanTimeout(bidding: false); // مهلة ثم يلعب الذكاء مكانك
        return;
      }
      await Future.delayed(_thinkDelay);
      if (_disposed || _phase != GamePhase.playing || _claimingFouja) return; // فوجة/مغادرة ⇒ توقّف
      final card = aiPlay(_playTurn, _hands[_playTurn], _trick, bid,
          rng: _rng, foujaChance: _aiFoujaChance);
      _playCardInternal(_playTurn, card);
      notifyListeners();
    }
  }

  /// اللاعب البشري يلعب ورقة. الشريط/اليد يُظهران القانوني فقط، لكن نتحقّق
  /// دفاعيًا عبر المحرك (رسالة «اتباع اللون» تعرضها الواجهة على اللمس غير القانوني).
  void playCard(Card card) {
    if (_phase != GamePhase.playing || _playTurn != 0 || !_awaitingHuman) {
      return;
    }
    // القانونية لم تعد مفروضة: يجوز لك ترك اتباع اللون (فوجة) — على الخصم كشفها.
    // نتحقّق فقط أن الورقة بيدك فعلًا.
    if (!_hands[0].contains(card)) return;
    _awaitingHuman = false;
    // الكشفُ لا يقع هنا: `_playCardInternal` هو من يرصد لحظةَ ظهور الفوجة على
    // الطاولة (عودتُك إلى لونٍ تركتَه)، فيعترض الخصمُ الآليّ حينها لا قبلها.
    _playCardInternal(0, card);
    notifyListeners();
    if (_phase != GamePhase.playing) return; // اعتراضٌ فوريّ أنهى الجولة
    _advancePlay();
  }

  /// خصمٌ آليّ رأى فوجتك **ظاهرةً على الطاولة** فقد يعترض. الاحتمال يُبقي بعضَ
  /// الفوجات ناجيةً — الخصمُ الآليّ لا يقظٌ دائمًا. صفرٌ ⇒ لا اعتراض (اختبارات).
  void _maybeAiAccuseHuman() {
    if (_aiAccuseChance <= 0 || _rng.next() >= _aiAccuseChance) return;
    if (_aiAccuseDelay <= Duration.zero) {
      _aiAccuseHuman(); // فوري (اختبارات)
      return;
    }
    // «تفكير» لحظيّ: اللعب يستمرّ قليلًا ثم يعترض الخصم — أطبع لا فُجائيّ.
    Future.delayed(_aiAccuseDelay, () {
      if (!_disposed && _phase == GamePhase.playing && !_claimingFouja) _aiAccuseHuman();
    });
  }

  /// خصمٌ آليّ اكتشف فوجة اللاعب واعترض: فريق الخصم (1) هو المدّعي والمُثبِت، فيأخذ
  /// قيمة الضمانة كاملة. يكشف الأوراق وينهي الجولة (RULES.md §8).
  void _aiAccuseHuman() {
    final bid = _bidding.currentBid!;
    final r = scoreFouja(bid: bid, akwins: _bidding.akwins, proven: true);
    final value = r.value;
    _themScore += value;
    _revealAll = true;
    _claimingFouja = false;
    _awaitingHuman = false;
    _whiteStreak[0] = 0; // جولةُ فوجة ليست بيضاء ⇒ ينكسر التتابع
    _whiteStreak[1] = 0;
    // المُتّهِمُ خصمٌ آليّ (المقعد 1) والمتّهَمُ أنت — كما في نصّ هذه الدالّة.
    _tracker.foujaResolved(accuserSeat: 1, accusedSeat: 0, proven: true);
    _matchOutcome = matchResult(_usScore, _themScore);
    _roundResult = RoundResult(
      usPoints: 0,
      themPoints: value,
      roundValue: value,
      reason: 'fouja',
      usTotal: _usScore,
      themTotal: _themScore,
      matchOutcome: _matchOutcome,
      foujaProven: true,
    );
    _phase = GamePhase.done;
    _sfxRoundEnd();
    dev.log('FOUJA by AI on human, them=$value', name: 'belote');
    notifyListeners();
    _scheduleAutoAdvance();
  }

  void _playCardInternal(int seat, Card card) {
    // نرصد الفوجة قبل إزالة الورقة (اليد ما تزال كاملة): لعبُ لونٍ آخر رغم امتلاك لون الافتتاح.
    if (isFouja(_hands[seat], _trick, card)) _seatFouja[seat] = true;
    // **الفوجةُ تُكتشَف على الطاولة لا من النظام**: من ترك لونَ الافتتاح ثمّ عاد
    // فلعب ذلك اللون بعدها فقد أثبت — أمام الجميع — أنّه كان يملكه حين تركه.
    // تلك لحظةُ الكشف الوحيدة؛ قبلها لا يعلم أحدٌ سوى صاحب اليد.
    final revealed = _renounced[seat].contains(card.suit);
    if (_trick.isNotEmpty && card.suit != _trick[0].card.suit) {
      _renounced[seat].add(_trick[0].card.suit);
    }
    _hands[seat].remove(card);
    _trick = [..._trick, (seat: seat, card: card)];
    _playTurn = nextSeat(seat); // عكس عقارب الساعة كما في المحرك
    _sfxDelayed(GameSound.cardPlay, _cardLandDelay); // الصوت لحظةَ هبوط الورقة
    // فوجةُ اللاعب انكشفت الآن ⇒ لخصمِه الآليّ أن يعترض. (الخصمُ الآليّ لا يعترض
    // على شريكه، ومقعدُنا الوحيدُ البشريُّ هنا هو 0.)
    if (seat == 0 && revealed) _maybeAiAccuseHuman();
  }

  /// اللاعب البشري يعترض بفوجة على خصمٍ: المقعد 1 (يمينك) أو 3 (يسارك). لا يُتّهم
  /// الشريك (2) ولا النفس. يُحسم فورًا عبر `scoreFouja`: إن كان المتّهم قد فوّج فعلًا
  /// هذه الجولة ⇒ فريقنا يأخذ قيمة الضمانة كاملة؛ وإلّا (اتهام خاطئ) ⇒ فريق المتّهم يأخذها.
  /// ثم تنتهي الجولة فورًا (RULES.md §8).
  /// يبدأ المطالبة بفوجة: يكشف كل الأيدي ويوقف اللعب، ويُظهر لوحة اختيار الخصم
  /// (يمينك=1 · يسارك=3). لا يُغيّر الطور — الاعتراض أو الإلغاء يحسمه.
  void startFoujaClaim() {
    if (_phase != GamePhase.playing || _claimingFouja) return;
    _claimingFouja = true;
    // لا كشف الآن — الورق يُكشف بعد اختيار المتّهَم فقط (منعًا للنظر ثم الاختيار).
    notifyListeners();
  }

  /// إلغاء المطالبة: يُخفي الكشف واللوحة، ويستأنف اللعب من حيث توقّف.
  void cancelFoujaClaim() {
    if (!_claimingFouja) return;
    _claimingFouja = false;
    _revealAll = false;
    notifyListeners();
    _advancePlay(); // استئناف الحلقة المتوقّفة
  }

  void accuseFouja(int accusedSeat) {
    if (_phase != GamePhase.playing) return;
    if (accusedSeat != 1 && accusedSeat != 3) return; // الخصمان فقط
    _claimingFouja = false;
    _revealAll = true; // يبقى الكشف ظاهرًا خلف لوحة النتيجة
    final bid = _bidding.currentBid!;
    final proven = _seatFouja[accusedSeat];
    final r = scoreFouja(bid: bid, akwins: _bidding.akwins, proven: proven);
    final value = r.value; // قيمة الضمانة (16/26/32/52)
    // المتّهِمُ أنت (المقعد 0) — الاعتراضُ في الأوفلاين لك وحدك.
    _tracker.foujaResolved(
        accuserSeat: 0, accusedSeat: accusedSeat, proven: proven);
    // المدّعي = فريقنا (0). المتّهم = فريق المقعد المتّهم (1).
    final winnerTeam = r.winner == 'claimant' ? 0 : teamOf(accusedSeat);
    final usPoints = winnerTeam == 0 ? value : 0;
    final themPoints = winnerTeam == 0 ? 0 : value;
    _usScore += usPoints;
    _themScore += themPoints;
    _awaitingHuman = false;
    _whiteStreak[0] = 0; // جولةُ فوجة ليست بيضاء ⇒ ينكسر التتابع
    _whiteStreak[1] = 0;
    _matchOutcome = matchResult(_usScore, _themScore);
    _roundResult = RoundResult(
      usPoints: usPoints,
      themPoints: themPoints,
      roundValue: value,
      reason: 'fouja',
      usTotal: _usScore,
      themTotal: _themScore,
      matchOutcome: _matchOutcome,
      foujaProven: proven,
    );
    _phase = GamePhase.done;
    _sfxRoundEnd();
    dev.log('FOUJA accused=$accusedSeat proven=$proven us=$usPoints them=$themPoints',
        name: 'belote');
    notifyListeners();
    _scheduleAutoAdvance();
  }

  Future<void> _resolveTrick(Bid bid) async {
    final winner = trickWinner(_trick, bid);
    final units = trickUnits(_trick, bid);
    _tracker.trickWon(trick: _trick, bid: bid, winnerSeat: winner, units: units);
    _units[teamOf(winner)] += units;
    _tricksWon[teamOf(winner)]++;
    notifyListeners(); // اعرض الأبلي كاملًا

    await Future.delayed(_pliPause); // وقفة لترى الأربع
    if (_disposed || _phase != GamePhase.playing || _claimingFouja) return; // فوجة/مغادرة ⇒ توقّف
    _collectingTo = winner;
    _sfx(GameSound.cardCollect); // صوت جمع الأبلي نحو الفائز
    notifyListeners(); // الواجهة تجمع الأوراق نحو الفائز

    await Future.delayed(_pliCollect);
    if (_disposed || _phase != GamePhase.playing || _claimingFouja) return; // فوجة/مغادرة ⇒ توقّف
    _trick = const [];
    _collectingTo = null;
    _lastTrickWinner = winner;
    _playTurn = winner; // الفائز يقود الأبلي التالي

    if (_hands.every((h) => h.isEmpty)) {
      _finishPlay();
      return;
    }
    notifyListeners();

    // استقرارٌ قصير قبل انطلاق الأبلي التالي — كي لا يبدأ الدور فجأةً بعد الجمع.
    await Future.delayed(_pliSettle);
    if (_disposed) return;
  }

  void _finishPlay() {
    _units[teamOf(_lastTrickWinner)] += derUnits; // الدير
    _tracker.derAwarded(seat: _lastTrickWinner, units: derUnits);
    final bid = _bidding.currentBid!;

    // ── الجولة البيضاء (الكابوت): تسبق التسجيل العاديّ، تعتمد عدد الأبالي ──
    final white =
        scoreWhiteRound(bid: bid, akwins: _bidding.akwins, tricksWon: _tricksWon);
    if (white != null) {
      _whiteStreak[white.team]++;
      _whiteStreak[1 - white.team] = 0;
      // أكوينس أبيض ⇒ حسمٌ فوريّ · جولتان بيضاوان متتاليتان ⇒ حسمٌ فوريّ.
      final decides = _bidding.akwins || _whiteStreak[white.team] >= 2;
      final usPoints = white.team == 0 ? white.value : 0;
      final themPoints = white.team == 0 ? 0 : white.value;
      _usScore += usPoints;
      _themScore += themPoints;
      _matchOutcome = decides ? white.team : matchResult(_usScore, _themScore);
      _roundResult = RoundResult(
        usPoints: usPoints,
        themPoints: themPoints,
        roundValue: white.value,
        reason: 'white',
        usTotal: _usScore,
        themTotal: _themScore,
        matchOutcome: _matchOutcome,
      );
      dev.log('WHITE team=${white.team} value=${white.value} decides=$decides '
          'streak=$_whiteStreak totals=$_usScore/$_themScore', name: 'belote');
      _phase = GamePhase.done;
      _sfxRoundEnd();
      notifyListeners();
      _scheduleAutoAdvance();
      return;
    }
    _whiteStreak[0] = 0; // جولةٌ غير بيضاء ⇒ ينكسر التتابع
    _whiteStreak[1] = 0;

    final bt = teamOf(_bidding.bidderSeat!); // فريق الضامن
    final value = roundValue(bid, _bidding.akwins);

    try {
      final s = scoreRound(
        bid: bid,
        akwins: _bidding.akwins,
        unitsBidder: _units[bt],
        unitsOpp: _units[1 - bt],
      );
      // نقاط الضامن/الخصم → نحن/هم بحسب فريق الضامن (0 = نحن).
      final usPoints = bt == 0 ? s.bidder : s.opponent;
      final themPoints = bt == 0 ? s.opponent : s.bidder;
      _usScore += usPoints;
      _themScore += themPoints;
      _matchOutcome = matchResult(_usScore, _themScore);
      _roundResult = RoundResult(
        usPoints: usPoints,
        themPoints: themPoints,
        roundValue: value,
        reason: s.reason,
        usTotal: _usScore,
        themTotal: _themScore,
        matchOutcome: _matchOutcome,
      );
      dev.log('SCORE us=$usPoints them=$themPoints reason=${s.reason} '
          'totals=$_usScore/$_themScore', name: 'belote');
    } on AkwinsTieException {
      // الثغرة المفتوحة #1 — لا نخمّن حسمًا (CLAUDE.md). نعرضها كإشعار.
      _matchOutcome = null; // لا حسم
      _roundResult = RoundResult(
        usPoints: 0,
        themPoints: 0,
        roundValue: value,
        reason: 'akwins',
        usTotal: _usScore,
        themTotal: _themScore,
        openRuleAkwinsTie: true,
      );
      dev.log('OPEN_RULE_AKWINS_TIE seed=$seed', name: 'belote');
    }

    _phase = GamePhase.done;
    _sfxRoundEnd(); // فوزٌ أو انتهاء جولة
    notifyListeners();
    _scheduleAutoAdvance();
  }

  /// **راوي المباراة** — نفسُ الوحدة التي يستعملها الخادم (`MatchTracker` في
  /// المحرّك). أوفلاينَ وأونلاينَ يُروى الملخّصُ بحسابٍ واحد، فلا يرى اللاعبُ
  /// «رجلَ مباراةٍ» مختلفًا باختلاف مكان جلوسه.
  MatchTracker _tracker = MatchTracker();

  /// ملخّصُ المباراة المنتهية — `null` قبل نهايتها.
  MatchInsights? _insights;
  MatchInsights? get insights => _insights;

  /// الملخّصُ جاهزًا للعرض. **أوفلاينَ الإحداثيّاتُ هي إحداثيّاتُ العرض نفسُها**
  /// (المقعد 0 هو اللاعب دائمًا) ⇒ لا تدوير.
  MatchSummaryView? get matchSummary {
    final i = _insights;
    if (i == null) return null;
    return MatchSummaryView(
      insights: i,
      names: [for (final p in seatPlayers) p.name],
      mySeat: 0,
    );
  }

  /// **مَعبرٌ واحدٌ لكلّ نهايات الجولة**: كلُّ مسارٍ (لعبٌ عاديّ · جولةٌ بيضاء · فوجةٌ
  /// باتّهامي أو باتّهامه · تعادلُ الأكوينس) ينتهي إلى [_scheduleAutoAdvance]، فتُسجَّل
  /// الجولةُ هنا مرّةً واحدة. تسجيلٌ عند كلّ مسارٍ على حدةٍ كان ينسى واحدًا يومًا.
  void _trackRoundEnd() {
    final r = _roundResult;
    if (r == null) return;
    _tracker.roundEnded(
        team0Points: r.usPoints, team1Points: r.themPoints, reason: r.reason);
    final m = _matchOutcome;
    if (m is int) _insights = _tracker.build(winnerTeam: m);
  }

  /// بعد انتهاء جولة (لا مباراة): اعرض النتيجة مدّةً ثم ابدأ الجولة التالية تلقائيًّا.
  /// عند وجود فائز مباراة (0/1) لا تقدّم — ينتظر اللاعب زرّ «مباراة جديدة».
  void _scheduleAutoAdvance() {
    _trackRoundEnd();
    if (_matchOutcome == 0 || _matchOutcome == 1) return; // فائز ⇒ لا تقدّم تلقائي
    if (_resultHold <= Duration.zero) return; // معطّل (اختبارات)
    Future.delayed(_resultHold, () {
      if (!_disposed && _phase == GamePhase.done) newRound();
    });
  }

  // ── مساعدات (كلها عبر المحرك) ──

  Set<Card> _humanLegalPlays() {
    if (_phase != GamePhase.playing || !_awaitingHuman) return const {};
    return legalPlays(_hands[0], _trick).toSet();
  }

  Bid _bidForName(String name) => switch (name) {
        'sans' => const Bid.sans(),
        'tout' => const Bid.tout(),
        _ => Bid.ofSuit(name),
      };
}
