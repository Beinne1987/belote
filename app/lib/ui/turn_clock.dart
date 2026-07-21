import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';

/// مؤشّر الدور: قوسٌ مكثّفٌ على حافة دائرة اللعب **مع رأس سهمٍ** يشير نحو صاحب الدور
/// (ضمانةً أو لعبًا أو توزيعًا). عرضٌ محضٌ ساكن — خفيف على الأداء.
///
/// [activeSeat] بترتيب العرض (0 أسفل · 1 يمين · 2 أعلى · 3 يسار)، و[color] لون فريقه.
class TurnClock extends StatelessWidget {
  final double size;
  final int activeSeat;
  final Color color;

  const TurnClock({
    super.key,
    required this.size,
    required this.activeSeat,
    required this.color,
  });

  /// اتجاه المقعد على الشاشة (y للأسفل): 0 أسفل · 1 يمين · 2 أعلى · 3 يسار.
  double _seatAngle(int seat) => switch (seat) {
        0 => math.pi / 2,
        1 => 0,
        2 => -math.pi / 2,
        _ => math.pi,
      };

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _ArcPainter(
            angle: _seatAngle(activeSeat),
            color: color,
            ring: t.feltInk2.withValues(alpha: 0.22),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double angle; // اتجاه صاحب الدور
  final Color color;
  final Color ring;

  _ArcPainter({required this.angle, required this.color, required this.ring});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // حلقةٌ خافتة كاملة.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );

    // قوسٌ مكثّفٌ متوهّج عند اتجاه صاحب الدور.
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    const half = 0.5; // نصف امتداد القوس (راديان)
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), angle - half, half * 2, false, arc);

    // رأس سهمٍ يشير للخارج نحو صاحب الدور (عند منتصف القوس).
    final dir = Offset(math.cos(angle), math.sin(angle));
    final perp = Offset(-dir.dy, dir.dx);
    final tip = c + dir * (r + 7);
    final b1 = c + dir * (r - 3) + perp * 6;
    final b2 = c + dir * (r - 3) - perp * 6;
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(b1.dx, b1.dy)
      ..lineTo(b2.dx, b2.dy)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.angle != angle || old.color != color || old.ring != ring;
}
