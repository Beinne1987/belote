import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'demo_card.dart';
import 'interactive_hand_fan.dart';
import '../../ui/table/premium_table_painter.dart';
import '../../ui/table/table_config.dart';
import '../../ui/table/table_geometry.dart';

/// يشغّل حركاتِ العرض من خارج الودجت (أزرارُ اللوحة). الحالةُ تسجّل نفسَها فيه.
class PremiumTableController {
  VoidCallback? _deal;
  VoidCallback? _slide;
  void Function(int from, int to)? _gift;

  void deal() => _deal?.call();
  void slide() => _slide?.call();
  void gift({int from = 2, int to = 0}) => _gift?.call(from, to);
}

/// **الطاولةُ الفاخرة كاملةً**: اللبّادُ والإطارُ (رسّامٌ ساكن) + أربعةُ مقاعد +
/// أوراقُ عيّنةٍ + ثلاثُ حركات.
///
/// **الأداء**: الطاولةُ الساكنةُ في `RepaintBoundary` فلا تُعاد أثناء الحركة؛
/// العناصرُ المتحرّكةُ في طبقةٍ فوقها تُبنى وحدَها. المقاعدُ والأوراقُ محسوبةٌ من
/// [TableGeometry] ⇒ تتبع أيَّ مقاس.
class PremiumTable extends StatefulWidget {
  final TableConfig config;
  final PremiumTableController? controller;

  /// حين true: يدُ اللاعب السفليّ هي **المروحةُ الاحترافيّةُ التفاعليّة** (يرى
  /// يدَه ويلعبها بالسحب) بدل المروحةِ الساكنة، ولا يُرسَم مقعدُه (يحملُ ورقَه).
  final bool interactiveBottomHand;

  /// وحدةُ تحكّمِ اليدِ التفاعليّة (لزرِّ التوزيع). تُستعمَل مع
  /// [interactiveBottomHand].
  final HandFanController? handController;

  /// تُستدعى حين يلعب اللاعبُ ورقةً من يده التفاعليّة.
  final void Function(String label)? onPlayCard;

  const PremiumTable({
    super.key,
    required this.config,
    this.controller,
    this.interactiveBottomHand = false,
    this.handController,
    this.onPlayCard,
  });

  @override
  State<PremiumTable> createState() => _PremiumTableState();
}

class _PremiumTableState extends State<PremiumTable>
    with TickerProviderStateMixin {
  late final AnimationController _deal = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1700));
  late final AnimationController _slide = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 360));
  late final AnimationController _gift = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));

  // بطاقةُ الأخذةِ المنزلقةُ تظهر فقط أثناء تشغيل _slide.
  int _giftFrom = 2, _giftTo = 0;

  // صورةُ اللبّاد المفكوكة (VIP) — تُحمَّل مرّةً وتُمرَّر للرسّام.
  ui.Image? _feltImage;
  String? _loadedAsset;

  @override
  void initState() {
    super.initState();
    _bind(widget.controller);
    _ensureFeltImage();
  }

  @override
  void didUpdateWidget(PremiumTable old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) _bind(widget.controller);
    if (old.config.feltImageAsset != widget.config.feltImageAsset) {
      _ensureFeltImage();
    }
  }

  /// يفكّ صورةَ اللبّاد (إن طُلبت) إلى `ui.Image`. يبتلع فشلَه: أصلٌ مفقودٌ ⇒
  /// يرتدّ الرسّامُ إلى لبّادٍ سادةٍ لا انهيار.
  Future<void> _ensureFeltImage() async {
    final asset = widget.config.feltImageAsset;
    if (asset == _loadedAsset) return;
    _loadedAsset = asset;
    if (asset == null) {
      if (mounted) setState(() => _feltImage = null);
      return;
    }
    try {
      final data = await rootBundle.load(asset);
      final codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted && _loadedAsset == asset) {
        setState(() => _feltImage = frame.image);
      }
    } catch (_) {
      /* أصلٌ مفقودٌ ⇒ لبّادٌ سادة */
    }
  }

  void _bind(PremiumTableController? c) {
    c?._deal = () => _deal.forward(from: 0);
    c?._slide = () => _slide.forward(from: 0);
    c?._gift = (from, to) {
      setState(() {
        _giftFrom = from;
        _giftTo = to;
      });
      _gift.forward(from: 0);
    };
  }

  @override
  void dispose() {
    _deal.dispose();
    _slide.dispose();
    _gift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      final g = TableGeometry.of(size, widget.config);
      final cw = g.cardWidth;

      return Stack(
        children: [
          // ── الطبقةُ الساكنة (لا تُعاد أثناء الحركة) ──
          RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter:
                  PremiumTablePainter(widget.config, feltImage: _feltImage),
            ),
          ),

          // أوراقُ الأخذةِ الوسطى (عيّنةٌ) — تختفي أثناء التوزيع وحدَه.
          // `AnimatedBuilder` على _deal ⇒ يتفاعل هذا الجزءُ الصغيرُ فقط، لا
          // المقاعدُ ولا الرسّامُ (المحميُّ بـ RepaintBoundary).
          AnimatedBuilder(
            animation: _deal,
            builder: (context, _) {
              if (_deal.status != AnimationStatus.dismissed) {
                return const SizedBox.shrink();
              }
              return Stack(children: [
                _place(g.trickSlot(2), cw,
                    DemoCard(rank: 'A', suit: Suit.spades, width: cw)),
                _place(g.trickSlot(1), cw,
                    DemoCard(rank: '10', suit: Suit.hearts, width: cw)),
              ]);
            },
          ),

          // أيدي اللاعبين مراوحَ كأنّهم يمسكونها. مع اليدِ التفاعليّة يُستثنى
          // السفليُّ (يحلُّ محلَّه المروحةُ التفاعليّةُ أدناه).
          ..._hands(g, cw, skipBottom: widget.interactiveBottomHand),

          // ── المقاعد ── (مع اليدِ التفاعليّة لا نرسم مقعدَ اللاعب — يحملُ ورقَه)
          for (var i = 0; i < 4; i++)
            if (!(widget.interactiveBottomHand && i == 0)) _seat(g, i),

          // ── طبقاتُ الحركة ──
          _dealLayer(g, cw),
          _slideLayer(g, cw),
          _giftLayer(g),

          // ── يدُ اللاعب التفاعليّة (على الطاولة، عند الحافّة القريبة) ──
          if (widget.interactiveBottomHand) _interactiveHand(g),
        ],
      );
    });
  }

  /// شريطُ اليدِ التفاعليّة أسفلَ الطاولة (الحافّةُ القريبةُ من اللاعب).
  Widget _interactiveHand(TableGeometry g) {
    final handW = g.felt.width * 0.92;
    final handH = g.minSide * 0.66;
    return Positioned(
      left: g.outer.center.dx - handW / 2,
      top: g.outer.bottom - handH,
      width: handW,
      height: handH,
      child: InteractiveHandFan(
        controller: widget.handController,
        onPlay: widget.onPlayCard,
      ),
    );
  }

  // ── المقاعد ───────────────────────────────────────────────────────────
  static const _names = ['أنت', 'سالم', 'مريم', 'خالد'];
  static const _emoji = ['🙂', '😎', '💃', '🧔'];

  Widget _seat(TableGeometry g, int i) {
    final c = g.seatCenter(i);
    final d = g.minSide * 0.13;
    final active = i == 0;
    return Positioned(
      left: c.dx - d,
      top: c.dy - d * 0.62,
      width: d * 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A4A5A), Color(0xFF1E2731)],
              ),
              border: Border.all(
                color: active
                    ? const Color(0xFFD9B45B)
                    : Colors.white.withValues(alpha: 0.3),
                width: active ? d * 0.06 : d * 0.03,
              ),
              boxShadow: [
                if (active)
                  BoxShadow(
                      color: const Color(0xFFD9B45B).withValues(alpha: 0.5),
                      blurRadius: d * 0.4),
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: d * 0.2,
                    offset: Offset(0, d * 0.08)),
              ],
            ),
            child: Center(
                child: Text(_emoji[i], style: TextStyle(fontSize: d * 0.5))),
          ),
          SizedBox(height: d * 0.12),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: d * 0.22, vertical: d * 0.06),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(d),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.5),
            ),
            child: Text(_names[i],
                style: TextStyle(
                    color: Colors.white,
                    fontSize: d * 0.24,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // أوراقُ يدِ اللاعب السفليّ (مكشوفة).
  static const _myRanks = ['7', '8', 'J', 'Q', 'K', 'A'];
  static const _mySuits = [
    Suit.hearts,
    Suit.hearts,
    Suit.spades,
    Suit.clubs,
    Suit.diamonds,
    Suit.spades
  ];

  /// المراوحُ الأربع. المقاعدُ البعيدةُ أوّلًا (2 ثمّ 1/3 ثمّ 0) ⇒ يدُك تعلو
  /// الجميع، والعمقُ صحيحٌ بلا فرزٍ يدويّ.
  ///
  /// **المروحةُ محورُها القاعدة**: كلُّ أوراقِ المقعد أسفلُها على نقطةٍ واحدة
  /// (`pivot`) وتُدار حولَها (`Transform` بمحاذاة `bottomCenter`) ⇒ تُجمَع من
  /// تحتُ وتُفتَح من فوق، فلا تأخذ اليدُ مساحةً كبيرة.
  List<Widget> _hands(TableGeometry g, double cw, {bool skipBottom = false}) {
    const n = 6;
    final w = <Widget>[];
    for (final seat in [2, 1, 3, 0]) {
      if (skipBottom && seat == 0) continue;
      final own = seat == 0;
      final size = own ? cw * 0.62 : cw * 0.85;
      final h = size * 1.4; // ارتفاعُ الورقة (نسبةُ DemoCard)
      for (var i = 0; i < n; i++) {
        final f = g.handFan(seat, i, n);
        w.add(Positioned(
          left: f.pivot.dx - size / 2,
          top: f.pivot.dy - h, // أسفلُ الورقةِ على المحور
          child: Transform(
            alignment: Alignment.bottomCenter, // الدورانُ حولَ نقطةِ الجمع
            transform: Matrix4.rotationZ(f.angle),
            child: own
                ? DemoCard(rank: _myRanks[i], suit: _mySuits[i], width: size)
                : DemoCard(
                    rank: '', suit: Suit.clubs, width: size, faceDown: true),
          ),
        ));
      }
    }
    return w;
  }

  // ── حركةُ التوزيع ─────────────────────────────────────────────────────
  Widget _dealLayer(TableGeometry g, double cw) {
    return AnimatedBuilder(
      animation: _deal,
      builder: (context, _) {
        if (_deal.status == AnimationStatus.dismissed) {
          return const SizedBox.shrink();
        }
        final from = g.felt.center;
        // مع اليدِ التفاعليّة يوزّعُ الجدولُ للخصوم فقط؛ يدُ اللاعب توزّع نفسَها.
        final seats = widget.interactiveBottomHand ? [1, 2, 3] : [0, 1, 2, 3];
        const perSeat = 2;
        final total = perSeat * seats.length;
        final children = <Widget>[];
        for (var k = 0; k < total; k++) {
          final start = k / total * 0.6;
          final t = ((_deal.value - start) / 0.4).clamp(0.0, 1.0);
          if (t <= 0) continue;
          final seat = seats[k % seats.length];
          final target = g.seatCenter(seat);
          final e = Curves.easeOutCubic.transform(t);
          final p = Offset.lerp(from, target, e)!;
          final w = cw * (0.62 + 0.0 * e);
          children.add(Positioned(
            left: p.dx - w / 2,
            top: p.dy - w * 0.7,
            child: Transform.rotate(
              angle: (1 - e) * (seat.isEven ? 0.4 : -0.4),
              child: Opacity(
                opacity: t < 1 ? 1 : (1 - (_deal.value - 0.85).clamp(0, 0.15) / 0.15),
                child: DemoCard(
                    rank: '', suit: Suit.clubs, width: w, faceDown: true),
              ),
            ),
          ));
        }
        return Stack(children: children);
      },
    );
  }

  // ── حركةُ الانزلاق ────────────────────────────────────────────────────
  Widget _slideLayer(TableGeometry g, double cw) {
    return AnimatedBuilder(
      animation: _slide,
      builder: (context, _) {
        if (_slide.status == AnimationStatus.dismissed) {
          return const SizedBox.shrink();
        }
        // من يدِك السفليّة (منطقةُ الجمع) إلى مقعدِ الأخذة — مركزًا إلى مركز.
        final ch = cw * 1.4;
        final from = Offset(
            g.felt.center.dx, g.felt.bottom - g.felt.height * 0.26);
        final to = g.trickSlot(0);
        final e = Curves.easeOutCubic.transform(_slide.value);
        final p = Offset.lerp(from, to, e)!;
        return Positioned(
          left: p.dx - cw / 2,
          top: p.dy - ch / 2,
          child: DemoCard(rank: 'J', suit: Suit.spades, width: cw),
        );
      },
    );
  }

  // ── حركةُ الهديّة ─────────────────────────────────────────────────────
  Widget _giftLayer(TableGeometry g) {
    return AnimatedBuilder(
      animation: _gift,
      builder: (context, _) {
        if (_gift.status == AnimationStatus.dismissed) {
          return const SizedBox.shrink();
        }
        final v = _gift.value;
        final a = g.seatCenter(_giftFrom);
        final b = g.seatCenter(_giftTo);
        // قوسٌ: يرتفع عن خطِّ المستقيم في المنتصف.
        final mid = Offset.lerp(a, b, 0.5)! - Offset(0, g.minSide * 0.35);
        final p = _quad(a, mid, b, v);
        final scale = 0.6 + math.sin(v * math.pi) * 1.1;
        final opacity = v < 0.85 ? 1.0 : (1 - (v - 0.85) / 0.15);
        final s = g.minSide * 0.12;
        return Positioned(
          left: p.dx - s / 2,
          top: p.dy - s / 2,
          child: Opacity(
            opacity: opacity.clamp(0, 1),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: s,
                height: s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFE0C069).withValues(alpha: 0.6),
                        blurRadius: s * 0.5),
                  ],
                ),
                child: Text('🎁', style: TextStyle(fontSize: s * 0.7)),
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _quad(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return a * (u * u) + c * (2 * u * t) + b * (t * t);
  }

  // [w] عرضُ الورقةِ نفسِها (تُبنى به) — يُستعمَل هنا للممركزة فقط.
  Widget _place(Offset center, double w, Widget card) => Positioned(
        left: center.dx - w / 2,
        top: center.dy - w * 0.7,
        child: card,
      );
}
