/// آلة حالة الضمانة — نقل حرفي من `reference/src/engine.js`.
///
/// دورة واحدة بالضبط (4 أدوار)، تتوقف فورًا عند الأكوينس. الأول لا يمرّ.
/// الرفع فقط. الأكوينس للخصم في دوره فقط.
library;

import 'bid.dart';
import 'seats.dart';

/// ترتيب الضمانات من الأضعف للأقوى — **مُلزِم** (يحدّد فهارس legalBidActions).
const bids = <String>['trefle', 'carreau', 'coeur', 'pique', 'sans', 'tout'];

/// رتبة الضمانة في [bids]. للّون يُستخدم اللون، ولغيره يُستخدم النوع.
int bidRank(Bid b) => bids.indexOf(
      b.type == BidType.suit ? b.suit! : (b.type == BidType.sans ? 'sans' : 'tout'),
    );

/// حالة الضمانة القابلة للتغيير (كما في JS — `applyBidAction` يعدّلها).
class BiddingState {
  final int dealer;
  int turn;
  int turnsTaken;
  Bid? currentBid;
  int? bidderSeat;
  bool akwins;
  int? akwinsBySeat;
  bool finished;
  final List<({int seat, BidAction action})> history;

  BiddingState({
    required this.dealer,
    required this.turn,
    this.turnsTaken = 0,
    this.currentBid,
    this.bidderSeat,
    this.akwins = false,
    this.akwinsBySeat,
    this.finished = false,
    List<({int seat, BidAction action})>? history,
  }) : history = history ?? [];
}

/// يبدأ الضمانة: الدور لأول مضمّن (يمين الموزّع).
BiddingState createBidding(int dealer) =>
    BiddingState(dealer: dealer, turn: firstBidder(dealer));

/// الإجراءات القانونية في الدور الحالي — **الترتيب مُلزِم**:
///   1. pass (إن جاز — ليس للأول)
///   2. الضمانات الأقوى من الحالية: trefle → carreau → coeur → pique → sans → tout
///   3. akwins (إن جاز — للخصم فقط، وبعد وجود ضمانة)
List<BidAction> legalBidActions(BiddingState st) {
  if (st.finished) return const <BidAction>[];
  final out = <BidAction>[];

  if (st.turnsTaken > 0) out.add(const BidAction.pass()); // الأول لا يمرّ

  final floor = st.currentBid != null ? bidRank(st.currentBid!) : -1; // الرفع فقط
  for (var i = floor + 1; i < bids.length; i++) {
    final b = bids[i];
    out.add(BidAction.ofBid(
      i < 4
          ? Bid.ofSuit(b)
          : (b == 'sans' ? const Bid.sans() : const Bid.tout()),
    ));
  }

  // الأكوينس: الخصم فقط، في دوره فقط
  if (st.currentBid != null && teamOf(st.bidderSeat!) != teamOf(st.turn)) {
    out.add(const BidAction.akwins());
  }
  return out;
}

/// يطبّق الإجراء ويعدّل الحالة. يرمي بأسماء الأخطاء نفسها في JS.
BiddingState applyBidAction(BiddingState st, BidAction action) {
  if (st.finished) throw StateError('BIDDING_FINISHED');
  final seat = st.turn;

  switch (action.kind) {
    case BidKind.pass:
      if (st.turnsTaken == 0) throw StateError('FIRST_BIDDER_CANNOT_PASS');
    case BidKind.bid:
      if (st.currentBid != null && bidRank(action.bid!) <= bidRank(st.currentBid!)) {
        throw StateError('BID_MUST_BE_HIGHER');
      }
      st.currentBid = action.bid;
      st.bidderSeat = seat;
    case BidKind.akwins:
      if (st.currentBid == null) throw StateError('NO_BID_TO_AKWINS');
      if (teamOf(st.bidderSeat!) == teamOf(seat)) {
        throw StateError('AKWINS_BY_OPPONENT_ONLY');
      }
      st.akwins = true;
      st.akwinsBySeat = seat;
      st.history.add((seat: seat, action: action));
      st.finished = true;
      return st;
  }

  st.history.add((seat: seat, action: action));
  st.turnsTaken++;
  st.turn = nextSeat(seat);
  if (st.turnsTaken >= 4) st.finished = true; // دورة واحدة فقط
  return st;
}
