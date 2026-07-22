import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'table_config.dart';

/// **هندسةُ الطاولة** — مصدرٌ واحدٌ لأبعادها ومواقعها.
///
/// يشاركه الرسّامُ (اللبّاد والإطار) وطبقةُ العناصر (المقاعد · الأوراق · الهدايا)،
/// فلا ينحرف ما يُرسَم عمّا يُوضَع فوقه مهما تغيّر المقاس. كلُّ الحساب من [Size]
/// المتاح و[TableConfig] وحدَهما ⇒ **قابلٌ للقياس لأيّ شاشة** بلا أرقامٍ مطلقة.
class TableGeometry {
  final Rect outer; // الطاولة كاملةً (بالإطار)
  final Rect felt; // سطحُ اللبّاد وحده
  final double rail;
  final double radius;
  final double minSide;

  const TableGeometry._({
    required this.outer,
    required this.felt,
    required this.rail,
    required this.radius,
    required this.minSide,
  });

  factory TableGeometry.of(Size avail, TableConfig cfg) {
    final Rect outer;
    if (cfg.fill) {
      outer = Offset.zero & avail;
    } else {
      var w = avail.width;
      var h = w / cfg.aspectRatio;
      if (h > avail.height) {
        h = avail.height;
        w = h * cfg.aspectRatio;
      }
      outer = Rect.fromLTWH(
          (avail.width - w) / 2, (avail.height - h) / 2, w, h);
    }
    final w = outer.width;
    final h = outer.height;
    final minSide = math.min(w, h);
    final rail = cfg.railThickness * minSide;
    return TableGeometry._(
      outer: outer,
      felt: outer.deflate(rail),
      rail: rail,
      radius: cfg.cornerRadius * minSide,
      minSide: minSide,
    );
  }

  /// عرضُ ورقةٍ يتناسب مع الطاولة — كلُّ شيءٍ يُقاس منه.
  double get cardWidth => minSide * 0.16;

  /// سُمكُ شريطِ العلم الأحمر نسبةً إلى ارتفاعِ اللبّاد (أعلاه وأسفلَه).
  static const flagBandRatio = 0.15;

  /// **حدُّ الشريط الأحمر السفليّ**: حيث ينتهي الأحمرُ ويبدأ الأخضر.
  /// مصدرٌ واحدٌ يشاركه الرسّامُ ومَن يصفُّ عناصرَه على هذا الخطّ.
  double get flagBottomBandTop => felt.bottom - felt.height * flagBandRatio;

  /// مركزُ مقعدٍ [i] على الإطار: 0 أسفل · 1 يمين · 2 أعلى · 3 يسار
  /// (اتّجاهُ اللعب عكسَ عقارب الساعة كالبيلوت).
  Offset seatCenter(int i) {
    final c = outer.center;
    final inset = rail * 0.5;
    switch (i) {
      case 0:
        return Offset(c.dx, outer.bottom - inset);
      case 1:
        return Offset(outer.right - inset, c.dy);
      case 2:
        return Offset(c.dx, outer.top + inset);
      default:
        return Offset(outer.left + inset, c.dy);
    }
  }

  /// موضعُ ورقةِ اللاعب [i] في الأخذة الوسطى (منزاحةٌ نحو مقعده).
  Offset trickSlot(int i) {
    final c = felt.center;
    final off = felt.shortestSide * 0.17;
    switch (i) {
      case 0:
        return Offset(c.dx, c.dy + off);
      case 1:
        return Offset(c.dx + off, c.dy);
      case 2:
        return Offset(c.dx, c.dy - off);
      default:
        return Offset(c.dx - off, c.dy);
    }
  }

  /// **مروحةٌ احترافيّة**: كلُّ أوراقِ اللاعب [seat] تدور حول **نقطةٍ واحدةٍ
  /// عند القاعدة** (تُجمَع من تحت) وتنفرج عند القمّة (تُفتَح من فوق) — فلا تأخذ
  /// اليدُ مساحةً كبيرة. الناتجُ **محورٌ مشترَك** (`pivot`) لكلّ أوراق المقعد
  /// و**زاويةٌ** لكلّ ورقةٍ حولَه؛ يضعُ العارضُ أسفلَ الورقةِ على المحور ويُديرها.
  ///
  /// لكلّ مقعدٍ اتّجاهُ انفراجٍ نحو الوسط: السفليُّ للأعلى · العلويُّ للأسفل ·
  /// اليساريُّ لليمين · اليمينيُّ لليسار.
  ({Offset pivot, double angle}) handFan(int seat, int i, int n) {
    final mid = (n - 1) / 2;
    const step = 0.19; // زاويةُ الانفراج بين ورقةٍ وأخرى
    final spread = (i - mid) * step;
    final f = felt;
    switch (seat) {
      case 0: // سفليّ — القاعدةُ أسفل، تنفرج للأعلى (وجهُها لنا)
        return (
          pivot: Offset(f.center.dx, f.bottom - f.height * 0.04),
          angle: spread,
        );
      case 2: // علويّ — القاعدةُ أعلى، تنفرج للأسفل
        return (
          pivot: Offset(f.center.dx, f.top + f.height * 0.04),
          angle: math.pi + spread,
        );
      case 3: // يساريّ — القاعدةُ عند اليسار، تنفرج لليمين
        return (
          pivot: Offset(f.left + f.width * 0.05, f.center.dy),
          angle: math.pi / 2 + spread,
        );
      default: // 1 يمينيّ — القاعدةُ عند اليمين، تنفرج لليسار
        return (
          pivot: Offset(f.right - f.width * 0.05, f.center.dy),
          angle: -math.pi / 2 + spread,
        );
    }
  }
}
