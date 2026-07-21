/// **محرّكُ حركة الهدايا** — طبقةٌ واحدةٌ فوق الطاولة تطيّر أيَّ هديّةٍ بين أيِّ
/// مقعدَين.
///
/// **لا يعرف هديّةً بعينها.** يقرأ [GiftFlight] (نقطتان واسمان و[GiftVisuals])
/// ويرسم. ⇒ هديّةٌ جديدةٌ = صفٌّ في `gift_spec.dart`، ولا سطرَ هنا.
///
/// **الأداء** — الطاولةُ تتحرّك أثناء اللعب، فالحركةُ لا تحقّ لها إسقاطُ إطار:
///   • **مؤقّتٌ واحد** لكل الطبقة (`AnimationController`)، لا مؤقّتَ لكلّ جُسيم.
///   • **الجُسيماتُ رسمٌ لا ودجت**: عشراتُ الشظايا في `CustomPainter` واحدٍ —
///     لو كانت ودجتاتٍ لَبنت شجرةً من ٣٠ عنصرًا في كلّ إطار.
///   • **مواضعُ الذيل تُشتقّ من `t`** بدالّةٍ خالصة، فلا حالةَ تتراكم ولا تخصيصَ
///     في الإطار — وإعادةُ البناء بعد توقّفٍ لا تُظهر ذيلًا «قديمًا».
///   • `RepaintBoundary` يعزل الطبقةَ عن الطاولة: الأوراقُ والبطاقاتُ **لا تُعاد
///     رسمًا** ستّين مرّةً في الثانية لأنّ وردةً تطير فوقها.
///   • **الطمسُ (blur) بالندرة**: أغلى مرشِّحٍ في الإطار، يُشترى حيث يُرى فقط.
///   • الهندسةُ تُحسَب مرّةً لكلّ رحلةٍ ومقاس، لا في كلّ إطار.
///
/// **التزامنُ بين الأجهزة**: لا يقرّر هذا الملفُّ متى تطير هديّة. الخادمُ يبثّ
/// الحدثَ للجميع (جالسِين ومشاهدين) في اللحظة نفسها، والوصفةُ حتميّةٌ من المعرّف
/// ⇒ الكلُّ يرى **الحركةَ نفسَها في الوقت نفسه**، كلٌّ بدوران مقاعده.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../theme/belote_theme.dart';
import 'gift_flight.dart';
import 'gift_spec.dart';

/// طبقةُ الحركة. تُوضع **في أعلى** `Stack` الطاولة (فوق الأوراق والبطاقات) وتملأها.
/// [flight] فارغةٌ ⇒ الطبقةُ لا شيء: بلا مؤقّتٍ يدور وبلا رسم.
class GiftFlightLayer extends StatefulWidget {
  final GiftFlight? flight;

  const GiftFlightLayer({super.key, required this.flight});

  @override
  State<GiftFlightLayer> createState() => _GiftFlightLayerState();
}

class _GiftFlightLayerState extends State<GiftFlightLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(GiftFlightLayer old) {
    super.didUpdateWidget(old);
    // **الرقمُ لا المحتوى**: هديّتان متطابقتان متتاليتان رحلتان، ولو قارنّا الحقولَ
    // لَظنّتهما الطبقةُ واحدةً فلم تُعِد الحركة.
    if (old.flight?.id != widget.flight?.id) _restart();
  }

  void _restart() {
    final f = widget.flight;
    if (f == null) {
      _c.stop();
      return;
    }
    _c
      ..duration = f.total
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.flight;
    if (f == null) return const SizedBox.shrink();
    final t = BeloteTheme.of(context);

    // **الأصلُ يُبنى مرّةً** ويُمرَّر إلى `AnimatedBuilder` عبر `child`: الإطارُ يحرّكه
    // ولا يعيد بناءه. صورةُ VIP خاصّةً — إعادةُ بنائها ستّين مرّةً في الثانية عبث.
    final art = switch (f.visuals.art) {
      GiftEmoji(:final emoji) => Text(
          emoji,
          style: TextStyle(fontSize: 36 * f.visuals.scale, height: 1),
          textAlign: TextAlign.center,
        ),
      GiftImage(:final asset) => Image.asset(
          asset,
          height: 52 * f.visuals.scale,
          filterQuality: FilterQuality.medium,
        ),
    };

    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, cons) {
            final size = Size(cons.maxWidth, cons.maxHeight);
            final g = _Geometry.of(f, size);
            return AnimatedBuilder(
              animation: _c,
              child: art,
              builder: (context, child) =>
                  _frame(context, f, g, size, child!, t),
            );
          },
        ),
      ),
    );
  }

  /// إطارٌ واحد: يحسب الموضعَ والحجمَ والميلَ، ثمّ يركّب الرسمَ فوق الأصل.
  Widget _frame(BuildContext context, GiftFlight f, _Geometry g, Size size,
      Widget art, BeloteTheme theme) {
    final v = _c.value;
    final tf = f.travelFraction;
    final flying = v < tf;
    // زمنُ العبور 0..1، وزمنُ أثر الوصول 0..1 — طوران لا يتداخلان.
    final tt = flying ? (tf <= 0 ? 1.0 : v / tf) : 1.0;
    final bt = flying ? 0.0 : ((v - tf) / (1 - tf)).clamp(0.0, 1.0);

    final pos = g.at(tt);
    final vel = g.velocityAt(tt);

    // **الحجمُ يحكي عمقًا**: تصغر عند الانطلاق، تكبر في وسط القوس (كأنّها اقتربت من
    // العين)، ثمّ تستقرّ عند الوصول — وتنبض نبضةً واحدةً مع الأثر.
    final shownScale = flying
        ? 0.62 + 0.52 * math.sin(math.pi * tt) + 0.33 * tt
        : 1.47 + 0.42 * math.sin(math.pi * bt);

    // الدوران: دوراتٌ كاملةٌ لمن يدور، وإلّا ميلٌ خفيفٌ مع اتّجاه الحركة (السيّارةُ
    // تميل حيث تتّجه، والجملُ لا يشقلب).
    final rotation = f.visuals.fx.spin != 0
        ? f.visuals.fx.spin * 2 * math.pi * tt
        : math.atan2(vel.dy, vel.dx) * 0.14;

    // طمسُ الحركة من **السرعة الفعليّة** لا من زمنٍ ثابت: الأسرعُ أكثرُ طمسًا،
    // ويخفت عند الوصول من تلقاء نفسه.
    final speed = vel.distance / math.max(f.travel.inMilliseconds, 1) * 16;
    final blur = f.visuals.fx.motionBlur && flying
        ? (speed * 0.5).clamp(0.0, 6.0)
        : 0.0;
    final vn = vel.distance < 1 ? const Offset(1, 0) : vel / vel.distance;

    Widget glyph = Transform.rotate(angle: rotation, child: art);
    if (blur > 0.4) {
      // طمسٌ **اتّجاهيّ**: على محور الحركة لا دائريّ — الدائريُّ يبدو ضبابًا لا سرعة.
      glyph = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: (blur * vn.dx).abs() + 0.1,
          sigmaY: (blur * vn.dy).abs() + 0.1,
          tileMode: TileMode.decal,
        ),
        child: glyph,
      );
    }

    final opacity = flying
        ? (tt < 0.08 ? tt / 0.08 : 1.0) // تظهر من البطاقة لا من العدم
        : (bt > 0.65 ? (1 - (bt - 0.65) / 0.35) : 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── الأثر كلُّه في رسّامٍ واحد: ظلٌّ · ذيلٌ · هالةٌ · حلقةٌ · شظايا ──
        Positioned.fill(
          child: CustomPaint(
            painter: _GiftFxPainter(
              t: v,
              tt: tt,
              bt: bt,
              flying: flying,
              geo: g,
              fx: f.visuals.fx,
              unit: 22 * f.visuals.scale,
            ),
          ),
        ),

        // ── الهديّةُ نفسُها ──
        Positioned(
          left: pos.dx - 60,
          top: pos.dy - 60,
          width: 120,
          height: 120,
          child: Center(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(scale: shownScale, child: glyph),
            ),
          ),
        ),

        // ── اسمُ المُرسِل عند نقطة الانطلاق ──
        // **هذه هي المشكلةُ التي بُني لها كلُّ ما سبق**: المستقبِلُ كان يرى هديّةً
        // بلا مُهدٍ. الاسمُ يخرج مع الهديّة من مقعده ويخفت وقد صارت في الطريق.
        _NameChip(
          at: g.p0,
          size: size,
          text: f.senderName,
          // يبقى ظاهرًا في أوّل الطريق ثمّ يخفت — ولا يعود في طور الوصول.
          opacity: flying ? (1 - (tt / 0.42)).clamp(0.0, 1.0) : 0.0,
          scale: 1,
          bg: theme.surface,
          ink: theme.text,
          accent: f.visuals.fx.glow,
          above: f.fromSeat != 2, // المقعدُ الأعلى: اللافتةُ تحته وإلّا خرجت
        ),

        // ── اسمُ المستقبِل مع أثر الوصول ──
        _NameChip(
          at: g.p2,
          size: size,
          text: f.receiverName,
          opacity: flying ? 0.0 : (bt < 0.7 ? 1.0 : (1 - (bt - 0.7) / 0.3)),
          // تقفز إلى مكانها قفزةً واحدةً — الوصولُ حدثٌ يُعلَن لا يُدسّ.
          scale: flying ? 0.8 : 0.8 + 0.2 * Curves.easeOutBack.transform(bt.clamp(0.0, 1.0)),
          bg: theme.surface,
          ink: theme.text,
          accent: f.visuals.fx.glow,
          above: f.toSeat != 2,
        ),
      ],
    );
  }
}

// ── الهندسة ──────────────────────────────────────────────────────────────────

/// مسارُ الرحلة على مقاسٍ بعينه — **يُحسَب مرّةً**، وكلُّ إطارٍ يستعلمه فقط.
class _Geometry {
  final Offset p0; // المُرسِل
  final Offset p2; // المستقبِل
  final Offset ctrl; // نقطةُ تحكّم بيزييه (فوق الطاولة)
  final double dist;

  const _Geometry(this.p0, this.p2, this.ctrl, this.dist);

  factory _Geometry.of(GiftFlight f, Size s) {
    final p0 = _resolve(f.origin, s);
    final p2 = _resolve(f.target, s);
    final d = (p2 - p0).distance;
    final mid = (p0 + p2) / 2;
    // القوسُ **فوق** الطاولة دائمًا (y سالب = أعلى): الهديّةُ ترتفع عن اللبّاد
    // فتُرى فوق الأوراق، ولو انحنت لأسفلَ لَاختفت تحت اليد.
    // وانزياحٌ جانبيٌّ خفيفٌ يمنع مسارَين متعاكسَين من أن يكونا خطًّا واحدًا.
    final lateral = (p2.dx - p0.dx) * 0.10;
    final ctrl = Offset(mid.dx + lateral, mid.dy - d * f.visuals.fx.arc);
    return _Geometry(p0, p2, ctrl, d);
  }

  static Offset _resolve(Alignment a, Size s) =>
      Offset((a.x + 1) / 2 * s.width, (a.y + 1) / 2 * s.height);

  /// بيزييه تربيعيّة — **منحنًى لا انتقالٌ آنيّ**.
  Offset at(double t) {
    final u = 1 - t;
    return p0 * (u * u) + ctrl * (2 * u * t) + p2 * (t * t);
  }

  /// المشتقّة — منها الميلُ واتّجاهُ الطمس ومقدارُهما.
  Offset velocityAt(double t) =>
      (ctrl - p0) * (2 * (1 - t)) + (p2 - ctrl) * (2 * t);

  /// «الأرض» تحت الهديّة عند [t]: الخطُّ المستقيم بين المقعدين — الفرقُ بينه وبين
  /// المنحنى هو **الارتفاع**، وبه يُحسَب الظلّ.
  Offset groundAt(double t) => Offset.lerp(p0, p2, t)!;
}

// ── الرسّام ──────────────────────────────────────────────────────────────────

/// كلُّ الأثر في رسّامٍ واحد. **بلا حالة**: كلُّ شيءٍ دالّةٌ في `t`.
class _GiftFxPainter extends CustomPainter {
  final double t, tt, bt;
  final bool flying;
  final _Geometry geo;
  final GiftFx fx;

  /// وحدةُ القياس بالبكسل (نصفُ قطرٍ مرجعيّ) — كلُّ الأحجام مضاعفاتُها، فيكبر الأثرُ
  /// مع الهديّة الأندر بلا رقمٍ ثانٍ.
  final double unit;

  const _GiftFxPainter({
    required this.t,
    required this.tt,
    required this.bt,
    required this.flying,
    required this.geo,
    required this.fx,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pos = geo.at(tt);
    final p = Paint()..isAntiAlias = true;

    if (flying) {
      _shadow(canvas, p, pos);
      _trail(canvas, p);
      _halo(canvas, p, pos);
    } else {
      _arrival(canvas, p, geo.p2);
    }
  }

  /// **ظلٌّ على اللبّاد** — يربط الهديّةَ بالطاولة فتطير *فوقها* لا *أمام الشاشة*.
  /// كلّما ارتفعت اتّسع الظلُّ وخفت: نفس ما تفعله الشمس.
  void _shadow(Canvas canvas, Paint p, Offset pos) {
    final ground = geo.groundAt(tt);
    final height = (ground.dy - pos.dy).abs();
    final maxH = math.max(geo.dist * fx.arc, 1);
    final k = (1 - height / maxH).clamp(0.12, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx, ground.dy + unit * 0.5),
        width: unit * 2.0 * k,
        height: unit * 0.62 * k,
      ),
      p
        ..color = const Color(0xFF000000).withValues(alpha: 0.28 * k)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.28),
    );
    p.maskFilter = null;
  }

  /// **ذيلُ الجُسيمات** — مواضعُه نقاطٌ سابقةٌ على المنحنى نفسِه، فيلتفّ مع القوس
  /// كذيل مذنَّبٍ بدل أن يكون خطًّا مستقيمًا خلف الهديّة.
  void _trail(Canvas canvas, Paint p) {
    const step = 0.030;
    final fadeIn = (tt / 0.12).clamp(0.0, 1.0); // لا ذيلَ قبل أن تتحرّك
    for (var i = 1; i <= fx.trail; i++) {
      final ti = tt - i * step;
      if (ti <= 0) continue;
      final f = 1 - i / fx.trail; // قوّةُ الجُسيم: الأقربُ أقوى
      final base = geo.at(ti);
      // اهتزازٌ عموديٌّ على المسار — **حتميٌّ من `i` و`ti`** لا عشوائيّ: بلا حالةٍ
      // تُحفَظ، ومع ذلك يبدو الذيلُ حيًّا لا مسطرة.
      final v = geo.velocityAt(ti);
      final n = v.distance < 1
          ? Offset.zero
          : Offset(-v.dy, v.dx) / v.distance;
      final wobble = math.sin(i * 2.1 + ti * 11) * unit * 0.34 * (1 - f);
      final at = base + n * wobble;

      canvas.drawCircle(
        at,
        unit * 0.34 * f + 1.2,
        p..color = fx.glow.withValues(alpha: 0.50 * f * fadeIn),
      );
      // شرارةٌ بيضاءُ كلَّ ثالثةٍ: القلبُ الساخن للذيل — تكسر رتابةَ اللون الواحد.
      if (i % 3 == 0) {
        canvas.drawCircle(
          at,
          unit * 0.13 * f + 0.6,
          p..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55 * f * fadeIn),
        );
      }
    }
  }

  /// هالةٌ حول الهديّة أثناء الطيران — بها تُقرأ فوق أيّ خلفيّة (لبّادٌ أو غرفةُ VIP).
  void _halo(Canvas canvas, Paint p, Offset pos) {
    canvas.drawCircle(
      pos,
      unit * 1.5,
      p
        ..color = fx.glow.withValues(alpha: 0.34)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.85),
    );
    p.maskFilter = null;
  }

  /// **أثرُ الوصول**: ومضةٌ ثمّ حلقةُ صدمةٍ تتمدّد ثمّ شظايا تتطاير. هذا ما يجعل
  /// الوصولَ حدثًا يستحقّ النظر — وهو ما يشتريه المُهدي في الحقيقة.
  void _arrival(Canvas canvas, Paint p, Offset at) {
    final e = Curves.easeOutCubic.transform(bt);

    // ومضةٌ قصيرةٌ في أوّل الأثر.
    if (bt < 0.3) {
      final k = 1 - bt / 0.3;
      canvas.drawCircle(
        at,
        unit * (1.0 + 1.4 * (1 - k)),
        p
          ..color = fx.glow.withValues(alpha: 0.55 * k)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, unit * 0.9),
      );
      p.maskFilter = null;
    }

    // حلقةُ الصدمة — للأندر وحده: على كلّ هديّةٍ تصير ضجيجًا لا حدثًا.
    if (fx.shockRing) {
      canvas.drawCircle(
        at,
        unit * (0.5 + 3.0 * e),
        p
          ..color = fx.glow.withValues(alpha: 0.75 * (1 - bt))
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.6, 5.5 * (1 - bt))
          ..maskFilter = null,
      );
      p.style = PaintingStyle.fill;
    }

    // شظايا تتطاير وتسقط قليلًا (جاذبيّةٌ خفيفةٌ تمنعها من أن تبدو آليّة).
    for (var i = 0; i < fx.burst; i++) {
      final ang = i * 2 * math.pi / fx.burst + (i % 3) * 0.31;
      final r = unit * (0.4 + 2.6 * e) * (0.75 + (i % 4) * 0.12);
      final gravity = unit * 0.9 * bt * bt;
      final at2 = at + Offset(math.cos(ang) * r, math.sin(ang) * r + gravity);
      canvas.drawCircle(
        at2,
        math.max(0.4, unit * 0.20 * (1 - bt)),
        p
          ..color = (i.isEven ? fx.glow : const Color(0xFFFFFFFF))
              .withValues(alpha: 0.85 * (1 - bt)),
      );
    }
  }

  @override
  bool shouldRepaint(_GiftFxPainter old) =>
      old.t != t || old.geo != geo || old.fx != fx;
}

// ── لافتةُ الاسم ─────────────────────────────────────────────────────────────

/// اسمٌ في لافتةٍ صغيرةٍ فوق مقعد (أو تحته). **المُرسِل عند الانطلاق والمستقبِل عند
/// الوصول** — بها يعرف كلُّ من على الطاولة *من* أهدى *مَن*.
class _NameChip extends StatelessWidget {
  final Offset at;
  final Size size;
  final String text;
  final double opacity;
  final double scale;
  final Color bg, ink, accent;

  /// اللافتةُ فوق المرسى أم تحته — المقعدُ الأعلى تُوضَع لافتتُه تحته وإلّا خرجت
  /// من الشاشة.
  final bool above;

  const _NameChip({
    required this.at,
    required this.size,
    required this.text,
    required this.opacity,
    required this.scale,
    required this.bg,
    required this.ink,
    required this.accent,
    required this.above,
  });

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.01 || text.isEmpty) return const SizedBox.shrink();
    const w = 190.0;
    final dy = above ? -62.0 : 62.0;
    // تُقصَّ داخل الشاشة: مقعدا اليمين واليسار قريبان من الحافّة، ولافتةٌ نصفُها
    // خارجَ الشاشة تُظهر نصفَ اسم.
    final left =
        (at.dx - w / 2).clamp(4.0, math.max(4.0, size.width - w - 4)).toDouble();
    return Positioned(
      left: left,
      top: at.dy + dy,
      width: w,
      child: Center(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bg.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.9), width: 1.6),
                boxShadow: [
                  BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1),
                ],
              ),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
