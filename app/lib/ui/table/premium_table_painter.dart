import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'table_config.dart';
import 'table_geometry.dart';

/// **رسّامُ الطاولة الفاخرة** — كلُّ شيءٍ متجهاتٌ وتدرّجاتٌ وظلال، لا صورةَ واحدة.
///
/// الطبقاتُ من الأسفل إلى الأعلى (كلُّ واحدةٍ تبني على ما تحتها):
/// 1. ظلٌّ أرضيٌّ ناعمٌ تحت الطاولة (تطفو لا تلتصق).
/// 2. **الإطارُ الخشبيّ** كأنبوبٍ مستدير: تدرّجٌ رأسيّ + حَلَقاتٌ تُحاكي الانحناء +
///    عروقٌ + لمعةٌ علويّة.
/// 3. تطعيمٌ ذهبيٌّ رفيعٌ عند حدّ اللبّاد.
/// 4. **اللبّادُ**: تدرّجٌ شعاعيّ + ظلٌّ داخليٌّ عند الحافّة (حوض) + بقعةُ ضوءٍ محيطة.
/// 5. شعارٌ باهتٌ + انعكاسٌ زجاجيٌّ أعلى الإطار.
///
/// **الأداء**: `shouldRepaint` يُعيد الرسمَ فقط حين يتغيّر الإعداد؛ والأوراقُ
/// والهدايا المتحرّكة فوق طبقةٍ منفصلةٍ لا تمسّ هذه (انظر `PremiumTable`).
class PremiumTablePainter extends CustomPainter {
  final TableConfig cfg;

  /// صورةُ اللبّاد المفكوكةُ (حين [FeltStyle.image]). تُحمَّل في الودجت وتُمرَّر
  /// هنا؛ null ⇒ لم تُحمَّل بعدُ فنرتدّ إلى لبّادٍ سادةٍ لا فراغ.
  final ui.Image? feltImage;

  const PremiumTablePainter(this.cfg, {this.feltImage});

  @override
  void paint(Canvas canvas, Size size) {
    // نفسُ الهندسةِ التي تضع المقاعدَ والأوراق ⇒ لا انحرافَ بين ما يُرسَم وما يُوضَع.
    final g = TableGeometry.of(size, cfg);
    final outer = g.outer;
    final minSide = g.minSide;
    final rail = g.rail;
    final radius = g.radius;

    final outerRRect =
        RRect.fromRectAndRadius(outer, Radius.circular(radius));
    final feltRect = g.felt;
    final feltRadius = math.max(2.0, radius - rail * 0.7);
    final feltRRect =
        RRect.fromRectAndRadius(feltRect, Radius.circular(feltRadius));

    _paintGroundShadow(canvas, outerRRect, minSide);
    _paintWoodRail(canvas, outerRRect, feltRRect, rail, minSide);
    if (cfg.showInlay) _paintInlay(canvas, feltRRect, rail);
    _paintFelt(canvas, feltRRect, feltRect, minSide);
    if (cfg.showEmblem) _paintEmblem(canvas, feltRect, minSide);
    if (cfg.centerLabel.isNotEmpty) {
      _paintCenterLabel(canvas, feltRect, minSide);
    }
    if (cfg.showReflection) _paintReflection(canvas, outerRRect, rail);
  }

  // ── 1. ظلّ الطاولة على الأرض ──────────────────────────────────────────
  void _paintGroundShadow(Canvas canvas, RRect r, double minSide) {
    final shadow = r.outerRect.translate(0, minSide * 0.045);
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, minSide * 0.06);
    canvas.drawRRect(
        RRect.fromRectAndRadius(shadow, r.tlRadius), paint);
  }

  // ── 2. الإطار الخشبيّ ─────────────────────────────────────────────────
  void _paintWoodRail(
      Canvas canvas, RRect outer, RRect felt, double rail, double minSide) {
    final base = HSLColor.fromColor(cfg.woodColor);
    final light = base
        .withLightness((base.lightness + 0.22 * cfg.woodGloss).clamp(0, 1))
        .toColor();
    final dark = base
        .withLightness((base.lightness - 0.28).clamp(0, 1))
        .toColor();
    final mid = cfg.woodColor;

    // الحوضُ الخشبيّ كلُّه: تدرّجٌ رأسيّ (ضوءٌ من الأعلى ⇒ أعلاه أفتح).
    canvas.save();
    canvas.clipRRect(outer);
    final bounds = outer.outerRect;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = ui.Gradient.linear(
          bounds.topCenter,
          bounds.bottomCenter,
          [light, mid, dark],
          [0.0, 0.5, 1.0],
        ),
    );

    // انحناءُ الأنبوب: حَلَقاتٌ مستطيلةٌ مطروحةٌ من الخارج نحو الداخل، من الغامق
    // (الحافّةُ الخارجيّة) إلى الفاتح (قمّةُ الأنبوب) ثمّ الغامق (عند اللبّاد).
    const rings = 14;
    for (var i = 0; i < rings; i++) {
      final f = i / (rings - 1); // 0 خارج .. 1 داخل
      final inset = rail * f;
      final rr = RRect.fromRectAndRadius(
        bounds.deflate(inset),
        Radius.circular(math.max(0, outer.tlRadius.x - inset)),
      );
      // قوسُ الإضاءة: قمّةُ الأنبوب نحو الثلث الخارجيّ.
      final curve = math.sin(f * math.pi); // 0..1..0
      final tint = Color.lerp(dark, light, curve * cfg.woodGloss)!;
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = rail / rings * 1.6
          ..color = tint.withValues(alpha: 0.5),
      );
    }

    // عروقُ الخشب: أقواسٌ رفيعةٌ باهتةٌ تتبع الإطار.
    _paintWoodGrain(canvas, bounds, outer.tlRadius.x, rail, dark);
    canvas.restore();

    // حزُّ الميلِ الداخليّ حيث يلتقي الخشبُ باللبّاد (ظلٌّ حادّ ⇒ عمق).
    canvas.drawRRect(
      felt,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rail * 0.18
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rail * 0.12),
    );
  }

  void _paintWoodGrain(
      Canvas canvas, Rect bounds, double radius, double rail, Color dark) {
    final rnd = math.Random(7); // ثابتٌ ⇒ العروقُ لا ترقص عند إعادة الرسم
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = dark.withValues(alpha: 0.18)
      ..strokeWidth = math.max(0.5, rail * 0.03);
    for (var i = 0; i < 22; i++) {
      final inset = rail * (0.1 + 0.8 * rnd.nextDouble());
      final wobble = rail * 0.06 * (rnd.nextDouble() - 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bounds.deflate(inset + wobble),
          Radius.circular(math.max(0, radius - inset)),
        ),
        paint,
      );
    }
  }

  // ── 3. التطعيم الذهبيّ ────────────────────────────────────────────────
  void _paintInlay(Canvas canvas, RRect felt, double rail) {
    final band = felt.inflate(rail * 0.16);
    // خطٌّ ذهبيٌّ مضيءٌ مع ظلٍّ خفيفٍ تحته ⇒ يبرز كسلكٍ معدنيّ.
    canvas.drawRRect(
      band.shift(Offset(0, rail * 0.03)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rail * 0.05
        ..color = Colors.black.withValues(alpha: 0.4),
    );
    canvas.drawRRect(
      band,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rail * 0.055
        ..shader = ui.Gradient.linear(
          band.outerRect.topCenter,
          band.outerRect.bottomCenter,
          [
            _lighten(cfg.inlayColor, 0.25),
            cfg.inlayColor,
            _darken(cfg.inlayColor, 0.3),
          ],
          // **المواقفُ إلزاميّةٌ بأكثرَ من لونين**: بدونها يرمي `Gradient.linear`
          // (ArgumentError) عند الرسم لا عند الترجمة ⇒ شاشةٌ سوداء.
          [0.0, 0.5, 1.0],
        ),
    );
  }

  // ── 4. اللبّاد ────────────────────────────────────────────────────────
  void _paintFelt(Canvas canvas, RRect felt, Rect rect, double minSide) {
    canvas.save();
    canvas.clipRRect(felt);

    // بؤرةُ الضوءِ تُزيح مركزَ التدرّج الشعاعيّ نحو مصدر الإضاءة.
    final lx = rect.center.dx + cfg.lightSource.x * rect.width * 0.3;
    final ly = rect.center.dy + cfg.lightSource.y * rect.height * 0.3;

    if (cfg.feltStyle == FeltStyle.image && feltImage != null) {
      _paintImageField(canvas, rect);
    } else if (cfg.feltStyle == FeltStyle.mauritaniaFlag) {
      _paintFlagField(canvas, rect, minSide);
    } else {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(lx, ly),
            rect.longestSide * 0.72,
            [
              _lighten(cfg.feltCenter, 0.06 * cfg.ambientLight),
              cfg.feltCenter,
              cfg.feltEdge,
            ],
            [0.0, 0.45, 1.0],
          ),
      );
    }

    // بقعةُ الضوءِ المحيطة: إهليلجٌ مضيءٌ ناعمٌ عند المصدر.
    if (cfg.ambientLight > 0) {
      final glow = Rect.fromCenter(
        center: Offset(lx, ly),
        width: rect.width * 0.8,
        height: rect.height * 0.6,
      );
      canvas.drawOval(
        glow,
        Paint()
          ..shader = ui.Gradient.radial(
            glow.center,
            glow.longestSide * 0.5,
            [
              Colors.white.withValues(alpha: 0.10 * cfg.ambientLight),
              Colors.white.withValues(alpha: 0.0),
            ],
          )
          ..maskFilter = MaskFilter.blur(
              BlurStyle.normal, minSide * 0.03),
      );
    }

    // الحوضُ (vignette): ظلٌّ داخليٌّ يتبع الحافّة ⇒ اللبّادُ منخفضٌ عن الإطار.
    canvas.drawRRect(
      felt.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = minSide * 0.08
        ..color = Colors.black.withValues(alpha: 0.5 * cfg.feltVignette)
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, minSide * 0.045),
    );
    canvas.restore();
  }

  // ── علم موريتانيا على اللبّاد ─────────────────────────────────────────
  // أخضرُ الحقلِ بشريطين أحمرين (أعلى/أسفل) وهلالٍ ونجمةٍ ذهبيّة، الهلالُ يفتح
  // نحو الأعلى والنجمةُ في حضنه — بطلبِ المالك. يبقى إحساسُ اللبّاد لأنّ بقعةَ
  // الضوءِ والحوضَ (vignette) يُرسمان فوقه بعدُ.
  void _paintFlagField(Canvas canvas, Rect rect, double minSide) {
    // الحقلُ الأخضر بتدرّجٍ خفيفٍ يمنحه عمقَ اللبّاد لا سطحًا مسطّحًا.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          rect.longestSide * 0.7,
          [_lighten(cfg.flagGreen, 0.05), cfg.flagGreen],
        ),
    );

    // الشريطان الأحمران — يمتدّان بعرض اللبّاد كاملًا (القصُّ يقصّهما بالحافّة).
    final band = rect.height * TableGeometry.flagBandRatio;
    final red = Paint()..color = cfg.flagRed;
    canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, band), red);
    canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.bottom - band, rect.width, band), red);

    // الهلالُ والنجمةُ ذهبيّان في القلب الأخضر.
    final c = rect.center;
    final r = minSide * 0.155;
    final gold = Paint()
      ..color = cfg.flagGold
      ..isAntiAlias = true;

    // الهلال: دائرةٌ ذهبيّةٌ تُقتطَع منها أخرى مزاحةٌ للأعلى ⇒ فتحتُه نحو الأعلى.
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
      Path()
        ..addOval(Rect.fromCircle(
            center: c.translate(0, -r * 0.42), radius: r * 0.88)),
    );
    canvas.drawPath(crescent, gold);

    // النجمةُ الخماسيّةُ في حضن الهلال (أعلى المركز قليلًا).
    canvas.drawPath(_star(c.translate(0, -r * 0.05), r * 0.52, r * 0.21), gold);
  }

  Path _star(Offset c, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * rad;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  // ── صورةٌ داخل الطاولة (خلفيّةُ VIP على اللبّاد) ───────────────────────
  // تُملأُ بأسلوب cover (بلا تشويهِ نسبة) وتُعتَّم قليلًا كي تبرزَ طباعةُ VIP فوقها.
  void _paintImageField(Canvas canvas, Rect rect) {
    final img = feltImage!;
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final scale = math.max(rect.width / iw, rect.height / ih);
    final sw = rect.width / scale, sh = rect.height / scale;
    final src = Rect.fromLTWH((iw - sw) / 2, (ih - sh) / 2, sw, sh);
    canvas.drawImageRect(img, src, rect, Paint()..isAntiAlias = true);
    canvas.drawRect(
        rect, Paint()..color = Colors.black.withValues(alpha: 0.28));
  }

  // ── طباعةُ VIP الذهبيّة في وسط الطاولة ────────────────────────────────
  void _paintCenterLabel(Canvas canvas, Rect rect, double minSide) {
    final style = TextStyle(
      fontSize: minSide * 0.17,
      fontWeight: FontWeight.w900,
      letterSpacing: minSide * 0.02,
      color: cfg.inlayColor,
    );
    final tp = TextPainter(
      text: TextSpan(text: cfg.centerLabel, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final origin = rect.center - Offset(tp.width / 2, tp.height / 2);
    // ظلٌّ غائرٌ يمنح الحروفَ بروزًا (emboss) على السطح.
    TextPainter(
      text: TextSpan(
          text: cfg.centerLabel,
          style: style.copyWith(color: Colors.black.withValues(alpha: 0.45))),
      textDirection: TextDirection.ltr,
    )
      ..layout()
      ..paint(canvas, origin + Offset(0, minSide * 0.006));
    tp.paint(canvas, origin);
  }

  // ── الميداليّة (اختياريّة) — حَلَقتان ذهبيّتان باهتتان، **بلا نجمة** ───────
  // (أُزيلت النجمةُ بطلب المالك؛ تبقى الحَلَقتان لمسةً فاخرةً لطاولة VIP.)
  void _paintEmblem(Canvas canvas, Rect rect, double minSide) {
    final c = rect.center;
    final r = minSide * 0.16;
    final ink = cfg.inlayColor.withValues(alpha: 0.14);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = minSide * 0.006
      ..color = ink;
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(c, r * 0.82, paint);
  }

  // ── 5. الانعكاس الزجاجيّ ──────────────────────────────────────────────
  void _paintReflection(Canvas canvas, RRect outer, double rail) {
    canvas.save();
    canvas.clipRRect(outer);
    final b = outer.outerRect;
    // لمعةٌ عريضةٌ ناعمةٌ تجتاح الربعَ العلويّ الأيسر (ضوءُ نافذةٍ على الورنيش).
    final glare = Path()
      ..moveTo(b.left, b.top)
      ..lineTo(b.left + b.width * 0.55, b.top)
      ..lineTo(b.left + b.width * 0.30, b.top + b.height * 0.5)
      ..lineTo(b.left, b.top + b.height * 0.42)
      ..close();
    canvas.drawPath(
      glare,
      Paint()
        ..shader = ui.Gradient.linear(
          b.topLeft,
          Offset(b.left + b.width * 0.4, b.top + b.height * 0.4),
          [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.0),
          ],
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rail * 0.6),
    );
    canvas.restore();
  }

  static Color _lighten(Color c, double amt) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amt).clamp(0, 1)).toColor();
  }

  static Color _darken(Color c, double amt) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - amt).clamp(0, 1)).toColor();
  }

  @override
  bool shouldRepaint(PremiumTablePainter old) =>
      old.cfg != cfg || old.feltImage != feltImage;
}
