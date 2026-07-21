import 'package:flutter/material.dart';

/// **ورقةُ لعبٍ عيّنة** — مرسومةٌ بالكود لا بصورة، كي يبقى العرضُ مكتفيًا بذاته.
///
/// ليست بطاقةَ الإنتاج (تلك SVG): هنا مستطيلٌ أبيضُ لامعٌ برتبةٍ ورمزٍ Unicode
/// (♠♥♦♣ حروفُ خطٍّ لا صور) — يكفي لتقييم كيف تجلس الأوراقُ على اللبّاد.
class DemoCard extends StatelessWidget {
  final String rank; // مثال: A · K · 10 · 7
  final Suit suit;
  final double width;

  /// وجهُها للأسفل (ظهرُ الورقة) — لليدِ الخفيّة وكومةِ التوزيع.
  final bool faceDown;

  const DemoCard({
    super.key,
    required this.rank,
    required this.suit,
    this.width = 64,
    this.faceDown = false,
  });

  @override
  Widget build(BuildContext context) {
    final h = width * 1.4;
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: width * 0.18,
            offset: Offset(0, width * 0.08),
          ),
        ],
        gradient: faceDown
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C4C8C), Color(0xFF16264C)],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFEDEFF2)],
              ),
        border: Border.all(
          color: faceDown
              ? const Color(0xFF4468B0)
              : Colors.white.withValues(alpha: 0.9),
          width: width * 0.02,
        ),
      ),
      child: faceDown ? _back(width) : _face(width),
    );
  }

  Widget _face(double w) {
    final color = suit.isRed ? const Color(0xFFC62031) : const Color(0xFF1A1A22);
    return Padding(
      padding: EdgeInsets.all(w * 0.08),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(rank,
                    style: TextStyle(
                        color: color,
                        fontSize: w * 0.3,
                        height: 1,
                        fontWeight: FontWeight.w800)),
                Text(suit.glyph,
                    style: TextStyle(color: color, fontSize: w * 0.24, height: 1)),
              ],
            ),
          ),
          Center(
            child: Text(suit.glyph,
                style: TextStyle(color: color, fontSize: w * 0.62)),
          ),
        ],
      ),
    );
  }

  Widget _back(double w) => Center(
        child: Container(
          margin: EdgeInsets.all(w * 0.1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.08),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: w * 0.015),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.10),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Center(
            child: Text('♦',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.28),
                    fontSize: w * 0.5)),
          ),
        ),
      );
}

enum Suit {
  spades('♠', false),
  hearts('♥', true),
  diamonds('♦', true),
  clubs('♣', false);

  const Suit(this.glyph, this.isRed);
  final String glyph;
  final bool isRed;
}
