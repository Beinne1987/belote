import 'package:flutter/material.dart';

import 'demo_card.dart';

/// يشغّل توزيعَ اليد من خارج الودجت (زرُّ اللوحة).
class HandFanController {
  VoidCallback? _deal;
  void deal() => _deal?.call();
}

/// **مروحةُ يدٍ احترافيّة** لبيلوت على الهاتف (أفقيًّا) — ٨ أوراق:
/// - **قوسٌ دائريّ** لا خطٌّ مستقيم: الوسطى أعلى وأوضح، والأطرافُ تنخفض وتتداخل.
/// - **زاويةُ كلّ ورقةٍ تتدرّج** حسب موضعها في القوس.
/// - **لمسٌ ⇒ ترتفع وتُحدَّد** بتوهّجٍ ذهبيّ.
/// - **سحبٌ وإفلاتٌ طبيعيّ**: اسحبها للأعلى فوق العتبة ⇒ تُلعَب؛ أفلتها دونها ⇒
///   تعود بسلاسة إلى مكانها.
/// - **توزيعٌ متدرّجٌ ناعم** عند البداية وعند إعادة التوزيع.
///
/// كلُّه بأبعادٍ نسبيّةٍ ⇒ يناسب أيَّ عرضٍ أفقيّ. الأوراقُ ترتيبُها ثابتٌ بمفاتيح
/// (`ValueKey`) فلا تقفز عند لعبِ واحدةٍ منها.
class InteractiveHandFan extends StatefulWidget {
  final HandFanController? controller;

  /// تُستدعى حين تُلعَب ورقةٌ (سُحبت للأعلى) — العرضُ يُظهر ملاحظة.
  final void Function(String label)? onPlay;

  const InteractiveHandFan({super.key, this.controller, this.onPlay});

  @override
  State<InteractiveHandFan> createState() => _InteractiveHandFanState();
}

class _Card {
  final int id;
  final String rank;
  final Suit suit;
  const _Card(this.id, this.rank, this.suit);
}

class _InteractiveHandFanState extends State<InteractiveHandFan> {
  // يدُ بيلوت: ٨ أوراق. ألوانٌ ورتبٌ متنوّعةٌ لتُقرأ الرموزُ بوضوح.
  static const _deck = [
    _Card(0, 'A', Suit.spades),
    _Card(1, '10', Suit.spades),
    _Card(2, 'K', Suit.hearts),
    _Card(3, 'Q', Suit.hearts),
    _Card(4, 'J', Suit.diamonds),
    _Card(5, '9', Suit.diamonds),
    _Card(6, 'A', Suit.clubs),
    _Card(7, '8', Suit.clubs),
  ];

  late List<_Card> _cards;
  int _dealt = 0; // كم ورقةً ظهرت (توزيعٌ متدرّج)
  int? _hover;
  int? _selected;
  int? _drag;
  Offset _dragPos = Offset.zero;
  final _playing = <int>{}; // معرّفاتُ أوراقٍ تُغادر الآن

  @override
  void initState() {
    super.initState();
    widget.controller?._deal = _redeal;
    _cards = List.of(_deck);
    _startDeal();
  }

  void _startDeal() {
    _dealt = 0;
    for (var k = 0; k < _cards.length; k++) {
      Future.delayed(Duration(milliseconds: 90 * k), () {
        if (mounted) setState(() => _dealt = k + 1);
      });
    }
  }

  void _redeal() {
    setState(() {
      _cards = List.of(_deck);
      _selected = _hover = _drag = null;
      _playing.clear();
    });
    _startDeal();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      // حجمُ الورقةِ محدودٌ بالارتفاعِ **والعرض** معًا ⇒ لا تفيضُ اليدُ خارجَ
      // الشريط مهما ضاق (مهمٌّ حين تجلس على الطاولة لا في شريطٍ عريض).
      final cardW = (h * 0.52 < w * 0.165) ? h * 0.52 : w * 0.165;
      final cardH = cardW * 1.4;
      final n = _cards.length;

      // ترتيبُ الرسم: المحدّدةُ/المسحوبةُ فوق الجميع؛ الباقي يسارًا فيمينًا.
      final order = List.generate(n, (i) => i)
        ..sort((a, b) {
          int rank(int i) {
            final c = _cards[i];
            if (_drag == i) return 3;
            if (_playing.contains(c.id)) return 2;
            if (_selected == i || _hover == i) return 1;
            return 0;
          }

          final r = rank(a) - rank(b);
          return r != 0 ? r : a - b;
        });

      return Stack(
        clipBehavior: Clip.none,
        children: [
          for (final i in order) _card(i, n, w, h, cardW, cardH),
        ],
      );
    });
  }

  Widget _card(
      int i, int n, double w, double h, double cardW, double cardH) {
    final card = _cards[i];
    final revealed = i < _dealt;
    final playing = _playing.contains(card.id);
    final isDrag = _drag == i;
    final lifted = _selected == i || _hover == i;

    // ── موضعُ القوس ──
    final mid = (n - 1) / 2;
    final t = i - mid; // ‎-3.5..3.5
    const angleStep = 0.10; // تدرّجُ زاوية الدوران
    final angle = t * angleStep;
    final spacingX = cardW * 0.6; // تداخلٌ (< عرض الورقة)
    final baseX = w / 2 + t * spacingX;
    // قطعٌ مكافئ: الوسطى أعلى (y أصغر)، الأطرافُ أخفض.
    final baseY = h * 0.60 + (t * t) * (cardH * 0.028);

    // الهدف: قبل التوزيع من كومةٍ يمين أعلى؛ بعده موضعُ القوس؛ عند اللعب للأعلى.
    Offset center;
    double drawAngle = angle;
    double scale = 1;
    if (isDrag) {
      center = _dragPos;
      drawAngle = angle * 0.25; // تعتدل قليلًا أثناء السحب
      scale = 1.12;
    } else if (playing) {
      center = Offset(w / 2, h * 0.16); // تنطلق نحو الطاولة
      scale = 1.05;
    } else if (!revealed) {
      center = Offset(w * 0.92, -cardH * 0.3); // كومةُ التوزيع
      drawAngle = 0.6;
    } else {
      final lift = lifted ? cardH * 0.16 : 0.0;
      center = Offset(baseX, baseY - lift);
    }

    final left = center.dx - cardW / 2;
    final top = center.dy - cardH / 2;
    // السحبُ فوريّ (بلا تأخّر)؛ ما عداه ينتقل بسلاسة.
    final dur = isDrag
        ? Duration.zero
        : const Duration(milliseconds: 300);

    return AnimatedPositioned(
      key: ValueKey(card.id),
      duration: dur,
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: cardW,
      height: cardH,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: playing ? 0 : 1,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = i),
          onExit: (_) => setState(() => _hover = _hover == i ? null : _hover),
          child: GestureDetector(
            onTap: () => setState(
                () => _selected = _selected == i ? null : i),
            onPanStart: (d) => setState(() {
              _drag = i;
              _selected = i;
              _dragPos = _toLocal(d.globalPosition);
            }),
            onPanUpdate: (d) =>
                setState(() => _dragPos = _toLocal(d.globalPosition)),
            onPanEnd: (_) => _endDrag(i, h),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: scale,
              child: Transform.rotate(
                angle: drawAngle,
                child: _CardVisual(
                  rank: card.rank,
                  suit: card.suit,
                  width: cardW,
                  highlighted: lifted || isDrag,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _toLocal(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    return box?.globalToLocal(global) ?? global;
  }

  void _endDrag(int i, double h) {
    final playThreshold = h * 0.34; // فوقها ⇒ لُعبت
    final played = _dragPos.dy < playThreshold;
    final card = _cards[i];
    setState(() => _drag = null);
    if (!played) return; // تعود إلى مكانها (AnimatedPositioned)
    setState(() {
      _selected = _hover = null;
      _playing.add(card.id);
    });
    widget.onPlay?.call('${card.rank}${card.suit.glyph}');
    Future.delayed(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _cards.removeWhere((c) => c.id == card.id));
    });
  }
}

/// وجهُ الورقة مع توهّجٍ ذهبيٍّ حين تُحدَّد — يبني على [DemoCard] ويضيف الإطار.
class _CardVisual extends StatelessWidget {
  final String rank;
  final Suit suit;
  final double width;
  final bool highlighted;

  const _CardVisual({
    required this.rank,
    required this.suit,
    required this.width,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        boxShadow: highlighted
            ? [
                BoxShadow(
                    color: const Color(0xFFD9B45B).withValues(alpha: 0.75),
                    blurRadius: width * 0.35,
                    spreadRadius: width * 0.02),
              ]
            : null,
      ),
      child: DemoCard(rank: rank, suit: suit, width: width),
    );
  }
}
