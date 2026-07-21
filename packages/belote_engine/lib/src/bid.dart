/// الضمانة وإجراءاتها — نقل حرفي من `reference/src/engine.js`.
library;

import 'card.dart' show suitCode;

/// نوع الضمانة.
enum BidType { suit, sans, tout }

/// ضمانة: لون (مع تحديد اللون) أو صن أو تو.
class Bid {
  final BidType type;

  /// اللون — فقط عندما `type == BidType.suit`.
  final String? suit;

  const Bid._(this.type, this.suit);
  const Bid.ofSuit(String this.suit) : type = BidType.suit;
  const Bid.sans() : this._(BidType.sans, null);
  const Bid.tout() : this._(BidType.tout, null);

  /// ترميز golden.json: `T`/`C`/`H`/`S` للون · `N` لصن · `A` لتو.
  String get code => switch (type) {
        BidType.suit => suitCode[suit]!,
        BidType.sans => 'N',
        BidType.tout => 'A',
      };

  @override
  bool operator ==(Object other) =>
      other is Bid && other.type == type && other.suit == suit;

  @override
  int get hashCode => Object.hash(type, suit);

  @override
  String toString() => code;
}

/// نوع إجراء الضمانة.
enum BidKind { pass, bid, akwins }

/// إجراء في دور اللاعب: تمرير، أو رفع بضمانة، أو أكوينس.
class BidAction {
  final BidKind kind;

  /// الضمانة — فقط عندما `kind == BidKind.bid`.
  final Bid? bid;

  const BidAction.pass()
      : kind = BidKind.pass,
        bid = null;
  const BidAction.ofBid(Bid this.bid) : kind = BidKind.bid;
  const BidAction.akwins()
      : kind = BidKind.akwins,
        bid = null;

  /// ترميز golden.json: `P` تمرير · `K` أكوينس · `B?` ضمانة (مثال `BS`).
  String get code => switch (kind) {
        BidKind.pass => 'P',
        BidKind.akwins => 'K',
        BidKind.bid => 'B${bid!.code}',
      };

  @override
  bool operator ==(Object other) =>
      other is BidAction && other.kind == kind && other.bid == bid;

  @override
  int get hashCode => Object.hash(kind, bid);

  @override
  String toString() => code;
}
