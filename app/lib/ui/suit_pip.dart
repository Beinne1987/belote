import 'package:flutter/widgets.dart';

/// **رمزُ اللون وحدَه** — بيك · كير · كارو · أتريف.
///
/// نفسُ أشكالِ الأوراق حرفيًّا (مسارات `ens` في `card_face.dart` المنقولةِ عن
/// `reference/src/cards.js`)، لكن **مبنيّةً `Path` في دارت لا نصَّ SVG**: هذه
/// الرموزُ تظهر في أزرارٍ تُبنى قبل أن يسخن مخزنُ `CardArt` (وفي الاختبارات بلا
/// تحميلٍ أصلًا)، فرسمٌ متزامنٌ يضمن ألّا يظهر زرٌّ فارغ. ولا حرفَ يونيكود
/// (♠♥) لأنّ النظامَ قد يستبدله برموزٍ تعبيريّةٍ ملوّنةٍ فيختلف الشكلُ عن الورق.
///
/// كلُّ المسارات في فضاء 100×100 ⇒ تُقاس إلى أيّ [size].
class SuitPip extends StatelessWidget {
  final String suit; // 'pique' · 'coeur' · 'carreau' · 'trefle'
  final double size;
  final Color color;

  const SuitPip({
    super.key,
    required this.suit,
    required this.size,
    required this.color,
  });

  /// الألوانُ الحمراء — قرارٌ بصريٌّ لا قاعدة (كالورق).
  static const redSuits = {'coeur', 'carreau'};

  /// حبرُ الرمز على خلفيّةٍ داكنة: الأحمرُ أفتحُ من حبرِ الورق كي يُقرأ على
  /// اللبّاد، والأسودُ يصير [onDarkInk] وإلّا اختفى.
  static Color inkOnDark(String suit, Color onDarkInk) =>
      redSuits.contains(suit) ? const Color(0xFFFF5A62) : onDarkInk;

  /// مسارُ الرمز في فضاء 100×100 — يُفحَص بالأرقام في الاختبار.
  static Path pathOf(String suit) {
    final p = Path();
    switch (suit) {
      case 'carreau':
        p
          ..moveTo(50, 4)
          ..lineTo(90, 50)
          ..lineTo(50, 96)
          ..lineTo(10, 50)
          ..close();
      case 'coeur':
        p
          ..moveTo(50, 92)
          ..cubicTo(14, 62, 8, 42, 8, 32)
          ..cubicTo(8, 16, 20, 8, 32, 8)
          ..cubicTo(41, 8, 47, 13, 50, 20)
          ..cubicTo(53, 13, 59, 8, 68, 8)
          ..cubicTo(80, 8, 92, 16, 92, 32)
          ..cubicTo(92, 42, 86, 62, 50, 92)
          ..close();
      case 'pique':
        p
          ..moveTo(50, 8)
          ..cubicTo(50, 8, 14, 40, 14, 62)
          ..cubicTo(14, 76, 25, 84, 36, 84)
          ..cubicTo(42, 84, 47, 81, 50, 76)
          ..cubicTo(48, 84, 43, 90, 34, 94)
          ..lineTo(66, 94)
          ..cubicTo(57, 90, 52, 84, 50, 76)
          ..cubicTo(53, 81, 58, 84, 64, 84)
          ..cubicTo(75, 84, 86, 76, 86, 62)
          ..cubicTo(86, 40, 50, 8, 50, 8)
          ..close();
      case 'trefle':
        p
          ..addOval(Rect.fromCircle(center: const Offset(50, 30), radius: 19))
          ..addOval(Rect.fromCircle(center: const Offset(27, 62), radius: 19))
          ..addOval(Rect.fromCircle(center: const Offset(73, 62), radius: 19))
          ..moveTo(44, 60)
          ..cubicTo(44, 76, 40, 86, 33, 92)
          ..lineTo(67, 92)
          ..cubicTo(60, 86, 56, 76, 56, 60)
          ..close();
      default:
        throw ArgumentError('لونٌ غير معروف: $suit');
    }
    return p;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PipPainter(suit: suit, color: color)),
      );
}

class _PipPainter extends CustomPainter {
  final String suit;
  final Color color;
  const _PipPainter({required this.suit, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    canvas.drawPath(
      SuitPip.pathOf(suit),
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_PipPainter old) =>
      old.suit != suit || old.color != color;
}
