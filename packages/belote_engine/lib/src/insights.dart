/// **لقطاتُ المباراة وأداءُ لاعبيها** — راوٍ يجلس على الطاولة ولا يلعب.
///
/// وحدةٌ خالصةٌ **لا تفرض قاعدةً ولا تغيّر واحدة**: تتلقّى ما وقع (ضمانةٌ رُفعت ·
/// أبليٌ حُسم · جولةٌ سُجّلت · فوجةٌ ثبتت) وتُخرج شيئين:
///
/// 1. **[MatchInsights]** — أربعُ لحظاتٍ تُروى بعد المباراة: أفضلُ إعلان · أقوى
///    ورقة · أطولُ سلسلة · رجلُ المباراة.
/// 2. **[SeatPerformance.score]** — رقمُ أداءٍ لكلّ مقعد، يُغذّي التصنيف كي يقيس
///    **المهارة** لا مجرّدَ الفوز.
///
/// **لماذا هنا لا في الخادم؟** الأوفلاين قائمٌ ولن يُحذف (قرارُ المالك)، ولاعبُه
/// يستحقّ الملخّصَ نفسَه. نسختان من هذا الحساب تعنيان يومًا تختلفان فيه، فيرى
/// اللاعبُ «رجلَ مباراةٍ» مختلفًا حسب مكان جلوسه. المحرّكُ يشترك فيه الطرفان.
///
/// **لا مساسَ بالقواعد**: لا شيءَ من هنا يدخل `scoreRound` ولا `legalPlays`،
/// و`fixtures/golden.json` لا يعرف بوجود هذا الملفّ أصلًا.
library;

import 'bid.dart';
import 'card.dart';
import 'play.dart';
import 'seats.dart';

/// **أفضل إعلان**: أثمنُ ضمانةٍ وفّى بها صاحبُها. الأكوينسُ إعلانٌ أيضًا.
class BestBidMoment {
  final int seat;

  /// ترميزُ الضمانة (`T`·`C`·`H`·`S`·`N`·`A`) — العرضُ يترجمه.
  final String bid;
  final bool akwins;

  /// النقاطُ التي جناها فريقُه في تلك الجولة.
  final int points;

  /// رقمُ الجولة داخل المباراة (يبدأ من 1) — للسرد: «في الجولة الثالثة».
  final int round;

  const BestBidMoment({
    required this.seat,
    required this.bid,
    required this.akwins,
    required this.points,
    required this.round,
  });

  Map<String, dynamic> toJson() => {
        'seat': seat,
        'bid': bid,
        'akwins': akwins,
        'points': points,
        'round': round,
      };

  static BestBidMoment? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : BestBidMoment(
          seat: (j['seat'] as num).toInt(),
          bid: j['bid'] as String? ?? '',
          akwins: j['akwins'] as bool? ?? false,
          points: (j['points'] as num?)?.toInt() ?? 0,
          round: (j['round'] as num?)?.toInt() ?? 0,
        );
}

/// **أقوى ورقة**: الورقةُ التي خطفت أثقلَ أبليٍّ في المباراة.
///
/// «أقوى» بالوحدات المخطوفة لا برتبة الورقة: سبعةٌ تأخذ أبليًا فيه ثلاثون وحدةً
/// أعظمُ أثرًا من آسٍ يأخذ أبليًا فارغًا — وهذا ما يتذكّره اللاعبون.
class StrongestCardMoment {
  final int seat;

  /// ترميزُ الورقة (`SJ` · `H10`) — العرضُ يرسمها.
  final String card;

  /// وحداتُ الأبلي الذي أخذته.
  final int units;

  /// ضمانةُ تلك الجولة — بها تُرسَم الورقةُ في سياقها (حكمٌ أم لا).
  final String bid;
  final int round;

  const StrongestCardMoment({
    required this.seat,
    required this.card,
    required this.units,
    required this.bid,
    required this.round,
  });

  Map<String, dynamic> toJson() => {
        'seat': seat,
        'card': card,
        'units': units,
        'bid': bid,
        'round': round,
      };

  static StrongestCardMoment? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : StrongestCardMoment(
          seat: (j['seat'] as num).toInt(),
          card: j['card'] as String? ?? '',
          units: (j['units'] as num?)?.toInt() ?? 0,
          bid: j['bid'] as String? ?? '',
          round: (j['round'] as num?)?.toInt() ?? 0,
        );
}

/// **أطولُ سلسلة**: أكثرُ أبالٍ متتاليةٍ أخذها مقعدٌ واحدٌ بلا أن يقطعها أحد.
///
/// السلسلةُ تُقاس داخل الجولة الواحدة: بدايةُ جولةٍ جديدةٍ توزيعٌ جديد، ووصلُ
/// الأبالي عبرها يصنع رقمًا لا يعني شيئًا.
class StreakMoment {
  final int seat;
  final int length;
  final int round;

  const StreakMoment(
      {required this.seat, required this.length, required this.round});

  Map<String, dynamic> toJson() =>
      {'seat': seat, 'length': length, 'round': round};

  static StreakMoment? fromJson(Map<String, dynamic>? j) => j == null
      ? null
      : StreakMoment(
          seat: (j['seat'] as num).toInt(),
          length: (j['length'] as num?)?.toInt() ?? 0,
          round: (j['round'] as num?)?.toInt() ?? 0,
        );
}

/// حصيلةُ مقعدٍ في المباراة، ورقمُ أدائه.
class SeatPerformance {
  final int seat;

  /// عددُ الأبالي التي أخذها.
  final int tricks;

  /// الوحداتُ التي جرّها إلى فريقه (أبالٍ + الدير إن كان آخرَ آخذ).
  final int units;

  /// كم مرّةً ضمن (رفعَ ضمانةً استقرّت عليه).
  final int bids;

  /// كم منها وفّى بها (فريقُه أخذ نقاطَ الجولة).
  final int bidsWon;

  /// كم أكوينسًا أعلن، وكم منها ربح.
  final int akwinsCalls;
  final int akwinsWon;

  /// فوجاتٌ ضُبطت عليه (اتُّهم فثبتت).
  final int foujasCaught;

  /// اتهاماتُ فوجةٍ صائبةٌ وخاطئة.
  final int rightAccusations;
  final int wrongAccusations;

  /// أطولُ سلسلةِ أبالٍ متتاليةٍ له.
  final int bestTrickStreak;

  /// **رقمُ الأداء** — مجموعٌ مرجّحٌ يُحسَب في [MatchTracker.build]. متوسّطُه على
  /// الأربعة نحو 15، ومداه العمليّ ‎−20..60. يُقرأ **نسبيًّا** لا مطلقًا: يُقارَن
  /// بأداء الجالسين معه في المباراة نفسِها فقط.
  final double score;

  const SeatPerformance({
    required this.seat,
    this.tricks = 0,
    this.units = 0,
    this.bids = 0,
    this.bidsWon = 0,
    this.akwinsCalls = 0,
    this.akwinsWon = 0,
    this.foujasCaught = 0,
    this.rightAccusations = 0,
    this.wrongAccusations = 0,
    this.bestTrickStreak = 0,
    this.score = 0,
  });

  Map<String, dynamic> toJson() => {
        'seat': seat,
        'tricks': tricks,
        'units': units,
        'bids': bids,
        'bidsWon': bidsWon,
        'akwinsCalls': akwinsCalls,
        'akwinsWon': akwinsWon,
        'foujasCaught': foujasCaught,
        'rightAccusations': rightAccusations,
        'wrongAccusations': wrongAccusations,
        'bestTrickStreak': bestTrickStreak,
        // العرضُ لا يقرأ الكسور، والتصنيفُ يقرؤها ⇒ رقمٌ واحدٌ بمنزلةٍ عشريّة.
        'score': double.parse(score.toStringAsFixed(1)),
      };

  static SeatPerformance fromJson(Map<String, dynamic> j) => SeatPerformance(
        seat: (j['seat'] as num).toInt(),
        tricks: (j['tricks'] as num?)?.toInt() ?? 0,
        units: (j['units'] as num?)?.toInt() ?? 0,
        bids: (j['bids'] as num?)?.toInt() ?? 0,
        bidsWon: (j['bidsWon'] as num?)?.toInt() ?? 0,
        akwinsCalls: (j['akwinsCalls'] as num?)?.toInt() ?? 0,
        akwinsWon: (j['akwinsWon'] as num?)?.toInt() ?? 0,
        foujasCaught: (j['foujasCaught'] as num?)?.toInt() ?? 0,
        rightAccusations: (j['rightAccusations'] as num?)?.toInt() ?? 0,
        wrongAccusations: (j['wrongAccusations'] as num?)?.toInt() ?? 0,
        bestTrickStreak: (j['bestTrickStreak'] as num?)?.toInt() ?? 0,
        score: (j['score'] as num?)?.toDouble() ?? 0,
      );
}

/// حصيلةُ المباراة كاملةً: أداءُ المقاعد الأربعة ولحظاتُها الأربع.
class MatchInsights {
  /// الفريقُ الفائز (0 = المقعدان 0+2).
  final int winnerTeam;

  /// أداءُ المقاعد **مرتّبًا بالمقعد** (`seats[i].seat == i`) — العرضُ يفهرس مباشرة.
  final List<SeatPerformance> seats;

  /// **رجلُ المباراة**: أعلى [SeatPerformance.score].
  ///
  /// قد يكون من الفريق الخاسر، وهذا مقصود: من جرّ الوحداتِ ووفّى بضماناته بينما
  /// غرق شريكُه يستحقّ ذكرَه — ولو أُجبر على أن يكون فائزًا لصار اللقبُ إعادةَ
  /// إعلانٍ للنتيجة لا خبرًا جديدًا.
  final int mvpSeat;

  final BestBidMoment? bestBid;
  final StrongestCardMoment? strongestCard;
  final StreakMoment? longestStreak;

  /// عددُ الجولات التي استغرقتها المباراة.
  final int rounds;

  const MatchInsights({
    required this.winnerTeam,
    required this.seats,
    required this.mvpSeat,
    required this.rounds,
    this.bestBid,
    this.strongestCard,
    this.longestStreak,
  });

  /// أداءُ مقعدٍ بعينه.
  SeatPerformance seatPerf(int seat) => seats[seat];

  Map<String, dynamic> toJson() => {
        'winnerTeam': winnerTeam,
        'mvpSeat': mvpSeat,
        'rounds': rounds,
        'seats': [for (final s in seats) s.toJson()],
        if (bestBid != null) 'bestBid': bestBid!.toJson(),
        if (strongestCard != null) 'strongestCard': strongestCard!.toJson(),
        if (longestStreak != null) 'longestStreak': longestStreak!.toJson(),
      };

  static MatchInsights fromJson(Map<String, dynamic> j) {
    final raw = (j['seats'] as List?) ?? const [];
    final seats = [
      for (final s in raw) SeatPerformance.fromJson(s as Map<String, dynamic>)
    ];
    return MatchInsights(
      winnerTeam: (j['winnerTeam'] as num?)?.toInt() ?? 0,
      // مقعدٌ ناقصٌ في حمولةٍ مشوّهة أفضلُ من شاشةٍ تنهار: نُكمل بأداءٍ صفريّ.
      seats: [
        for (var i = 0; i < 4; i++)
          i < seats.length ? seats[i] : SeatPerformance(seat: i)
      ],
      mvpSeat: (j['mvpSeat'] as num?)?.toInt() ?? 0,
      rounds: (j['rounds'] as num?)?.toInt() ?? 0,
      bestBid: BestBidMoment.fromJson(j['bestBid'] as Map<String, dynamic>?),
      strongestCard:
          StrongestCardMoment.fromJson(j['strongestCard'] as Map<String, dynamic>?),
      longestStreak:
          StreakMoment.fromJson(j['longestStreak'] as Map<String, dynamic>?),
    );
  }
}

/// **الراوي**: يُغذَّى بأحداث المباراة بالترتيب، ثمّ يُبنى منه [MatchInsights].
///
/// نسخةٌ واحدةٌ لكلّ مباراة (لا تُعاد تهيئتُها). التغذيةُ رخيصة: عدّاداتٌ ومقارنات،
/// بلا نسخِ أوراقٍ ولا تخزينِ سجلٍّ كامل — الطاولةُ الحيّة تستدعيها بعد كلّ أبلي.
class MatchTracker {
  final _tricks = <int>[0, 0, 0, 0];
  final _units = <int>[0, 0, 0, 0];
  final _bids = <int>[0, 0, 0, 0];
  final _bidsWon = <int>[0, 0, 0, 0];
  final _akwinsCalls = <int>[0, 0, 0, 0];
  final _akwinsWon = <int>[0, 0, 0, 0];
  final _foujasCaught = <int>[0, 0, 0, 0];
  final _rightAccusations = <int>[0, 0, 0, 0];
  final _wrongAccusations = <int>[0, 0, 0, 0];
  final _bestStreak = <int>[0, 0, 0, 0];

  /// سلسلةُ الأبالي الجارية داخل الجولة الحاليّة (مقعد، طول).
  int _streakSeat = -1;
  int _streakLen = 0;

  int _round = 0;
  Bid? _bid;
  int? _bidderSeat;
  bool _akwins = false;

  BestBidMoment? _bestBid;
  StrongestCardMoment? _strongestCard;
  StreakMoment? _longestStreak;

  /// عددُ الجولات المكتملة.
  int get rounds => _round;

  /// **بدءُ جولة** بعد استقرار الضمانة: من ضمن، وبماذا، وهل أكوينس.
  void roundStarted(
      {required Bid bid, required int bidderSeat, required bool akwins}) {
    _round++;
    _bid = bid;
    _bidderSeat = bidderSeat;
    _akwins = akwins;
    _bids[bidderSeat]++;
    if (akwins) _akwinsCalls[bidderSeat]++;
    // الجولةُ توزيعٌ جديد ⇒ لا تُوصَل سلسلةُ الجولة الماضية بها.
    _streakSeat = -1;
    _streakLen = 0;
  }

  /// **أبليٌ حُسم**: من أخذه، بكم وحدة، وبأيّ أوراق.
  void trickWon(
      {required List<Play> trick,
      required Bid bid,
      required int winnerSeat,
      required int units}) {
    _tricks[winnerSeat]++;
    _units[winnerSeat] += units;

    if (_streakSeat == winnerSeat) {
      _streakLen++;
    } else {
      _streakSeat = winnerSeat;
      _streakLen = 1;
    }
    if (_streakLen > _bestStreak[winnerSeat]) _bestStreak[winnerSeat] = _streakLen;
    // سلسلةٌ من أبليٍّ واحدٍ ليست سلسلة: لا تُروى إلّا اثنان فأكثر.
    if (_streakLen >= 2 &&
        (_longestStreak == null || _streakLen > _longestStreak!.length)) {
      _longestStreak =
          StreakMoment(seat: winnerSeat, length: _streakLen, round: _round);
    }

    final winning =
        trick.where((p) => p.seat == winnerSeat).map((p) => p.card).firstOrNull;
    if (winning == null) return; // آخذٌ ليس في الأبلي — لا لقطةَ تُروى
    final best = _strongestCard;
    // تعادلُ الوحدات المخطوفة يُحسَم بوحدات الورقة الآخذة نفسِها (فالةُ الحكم قبل
    // الآس): رقمٌ قابلٌ للمقارنة بين الضمانات، بخلاف `strength` وهو فهرسٌ داخل
    // ترتيبِ لونٍ بعينه لا يعني شيئًا خارجه.
    final better = best == null ||
        units > best.units ||
        (units == best.units &&
            cardUnits(bid, winning) > _unitsOfCode(best.bid, best.card));
    if (better) {
      _strongestCard = StrongestCardMoment(
        seat: winnerSeat,
        card: winning.code,
        units: units,
        bid: bid.code,
        round: _round,
      );
    }
  }

  /// **الدير**: عشرُ وحداتٍ لآخذ الأبلي الأخير — تُحسَب في وحداته لا في أبالِيه.
  void derAwarded({required int seat, required int units}) {
    _units[seat] += units;
  }

  /// **فوجةٌ حُسمت**: اتّهامٌ ثبت أو خاب. يُستدعى مرّةً واحدةً لكلّ اعتراض.
  void foujaResolved(
      {required int accuserSeat,
      required int accusedSeat,
      required bool proven}) {
    if (proven) {
      _rightAccusations[accuserSeat]++;
      _foujasCaught[accusedSeat]++;
    } else {
      _wrongAccusations[accuserSeat]++;
    }
  }

  /// **نهايةُ جولة** بنقاطها وسببها (`ok` · `chute` · `akwins` · `white` · `fouja`).
  ///
  /// [team0Points] للمقعدين 0+2. تُقاس بها وفاءُ الضامن بضمانته — إلّا جولةَ الفوجة:
  /// حسمَها اتّهامٌ لا لعبٌ، فلا تُحسَب على الضمانة نجاحًا ولا سقوطًا.
  void roundEnded(
      {required int team0Points,
      required int team1Points,
      required String reason}) {
    final bidder = _bidderSeat;
    final bid = _bid;
    if (bidder == null || bid == null) return;
    if (reason != 'fouja') {
      final bidderTeam = teamOf(bidder);
      final mine = bidderTeam == 0 ? team0Points : team1Points;
      final theirs = bidderTeam == 0 ? team1Points : team0Points;
      if (mine > theirs) {
        _bidsWon[bidder]++;
        if (_akwins) _akwinsWon[bidder]++;
        final best = _bestBid;
        // «الأفضل» بنقاط الجولة أوّلًا (الأكوينسُ يضاعفها فيتقدّم طبعًا)، ثمّ
        // بثقل الضمانة: تو ثمّ صن ثمّ لون.
        final better = best == null ||
            mine > best.points ||
            (mine == best.points && _bidWeight(bid) > _bidWeightOfCode(best.bid));
        if (better) {
          _bestBid = BestBidMoment(
            seat: bidder,
            bid: bid.code,
            akwins: _akwins,
            points: mine,
            round: _round,
          );
        }
      }
    }
    _bidderSeat = null;
    _bid = null;
    _akwins = false;
  }

  /// يبني الحصيلة النهائيّة. [winnerTeam] فريقُ المباراة الفائز (0|1).
  MatchInsights build({required int winnerTeam}) {
    final totalUnits = _units.reduce((a, b) => a + b);
    final totalTricks = _tricks.reduce((a, b) => a + b);

    final seats = <SeatPerformance>[];
    for (var s = 0; s < 4; s++) {
      final unitShare = totalUnits == 0 ? 0.25 : _units[s] / totalUnits;
      final trickShare = totalTricks == 0 ? 0.25 : _tricks[s] / totalTricks;
      // **الأوزان** — الوحداتُ أثقلُ من عدد الأبالي (أبليٌ فارغٌ ليس إنجازًا)،
      // والقراراتُ (ضمانةٌ · أكوينس · اتّهام) تدخل بمقاديرَ ثابتةٍ لأنّها أحداثٌ
      // تُعدّ لا حصصٌ تُقسَّم. مجموعُ حصص الأربعة = 1 ⇒ متوسّطُ الحصص 15 نقطة.
      final score = 40 * unitShare +
          20 * trickShare +
          12 * _bidsWon[s] -
          10 * (_bids[s] - _bidsWon[s]) +
          8 * _akwinsWon[s] +
          10 * _rightAccusations[s] -
          10 * _wrongAccusations[s] -
          12 * _foujasCaught[s];
      seats.add(SeatPerformance(
        seat: s,
        tricks: _tricks[s],
        units: _units[s],
        bids: _bids[s],
        bidsWon: _bidsWon[s],
        akwinsCalls: _akwinsCalls[s],
        akwinsWon: _akwinsWon[s],
        foujasCaught: _foujasCaught[s],
        rightAccusations: _rightAccusations[s],
        wrongAccusations: _wrongAccusations[s],
        bestTrickStreak: _bestStreak[s],
        score: score,
      ));
    }

    // **رجلُ المباراة حتميّ**: عند تساوي الأداء تحسم الوحداتُ ثمّ الأبالي ثمّ رقمُ
    // المقعد — كي يتّفق الخادمُ والعميلُ على اسمٍ واحد دائمًا.
    var mvp = 0;
    for (var s = 1; s < 4; s++) {
      final a = seats[s], b = seats[mvp];
      final better = a.score > b.score ||
          (a.score == b.score &&
              (a.units > b.units ||
                  (a.units == b.units && a.tricks > b.tricks)));
      if (better) mvp = s;
    }

    return MatchInsights(
      winnerTeam: winnerTeam,
      seats: seats,
      mvpSeat: mvp,
      rounds: _round,
      bestBid: _bestBid,
      strongestCard: _strongestCard,
      longestStreak: _longestStreak,
    );
  }

  /// ثقلُ الضمانة للمفاضلة: تو > صن > لون.
  static int _bidWeight(Bid bid) => switch (bid.type) {
        BidType.tout => 3,
        BidType.sans => 2,
        BidType.suit => 1,
      };

  static int _bidWeightOfCode(String code) => switch (code) {
        'A' => 3,
        'N' => 2,
        _ => 1,
      };

  /// وحداتُ ورقةٍ من ترميزها في ضمانةٍ من ترميزها — لمقارنة لقطةٍ محفوظة بجديدة.
  static int _unitsOfCode(String bidCode, String cardCode) {
    final bid = _bidOfCode(bidCode);
    final card = _cardOfCode(cardCode);
    return (bid == null || card == null) ? -1 : cardUnits(bid, card);
  }

  static Bid? _bidOfCode(String code) => switch (code) {
        'A' => const Bid.tout(),
        'N' => const Bid.sans(),
        _ => _suitOfCode(code) == null ? null : Bid.ofSuit(_suitOfCode(code)!),
      };

  static String? _suitOfCode(String code) => suitCode.entries
      .where((e) => e.value == code)
      .map((e) => e.key)
      .firstOrNull;

  static Card? _cardOfCode(String code) {
    if (code.length < 2) return null;
    final suit = _suitOfCode(code[0]);
    if (suit == null) return null;
    final rank = code.substring(1);
    if (!ranks.contains(rank)) return null;
    return Card(suit, rank);
  }
}
