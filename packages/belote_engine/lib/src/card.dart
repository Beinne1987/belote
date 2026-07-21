/// الورقة والثوابت الأساسية — منقولة حرفياً من `reference/src/engine.js`.
library;

/// ترتيب الألوان — **مُلزِم**. الحلقة الخارجية في `buildDeck`.
/// أي تغيير يعطي شدّة مختلفة تماماً بعد الخلط.
const suits = <String>['trefle', 'carreau', 'coeur', 'pique'];

/// ترتيب الرُّتب — **مُلزِم**. الحلقة الداخلية في `buildDeck`.
const ranks = <String>['7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

/// حروف الألوان في ترميز `fixtures/golden.json`. يشاركها [Card] و`Bid`.
const suitCode = <String, String>{
  'trefle': 'T', // أتريف ♣
  'carreau': 'C', // كارو ♦
  'coeur': 'H', // كير ♥
  'pique': 'S', // أبيك ♠
};

/// ورقة لعب: لون + رتبة. غير قابلة للتغيير، ولها مساواة بالقيمة.
class Card {
  final String suit;
  final String rank;

  const Card(this.suit, this.rank);

  /// ترميز مطابق لـ golden.json: حرف اللون + الرتبة (مثال: `SJ` · `H10`).
  String get code => '${suitCode[suit]}$rank';

  @override
  bool operator ==(Object other) =>
      other is Card && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => code;
}
