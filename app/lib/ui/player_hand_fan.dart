import 'dart:math' as math;

import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;

import '../theme/belote_theme.dart';
import 'card_face.dart';
import 'app_frame.dart';
import 'card_shell.dart';

/// **يدُ اللاعب كما تُمسَك في الواقع** — مروحةٌ بقوسٍ منخفضٍ ومحورٍ واحدٍ تحتها،
/// لا صفًّا أفقيًّا ولا توزيعًا على دائرةٍ كاملة.
///
/// ودجتٌ مستقلّةٌ عن شاشة الطاولة عمدًا: هندستُها في [HandFanMetrics] (صنفٌ خالصٌ
/// يُحسَب ويُختبَر **بلا رسم**)، وسلوكُها هنا. فمن أراد يدًا في شاشةٍ أخرى (معاينةٌ ·
/// مشاهدةٌ · إعادةُ عرض) يبنيها بسطرٍ واحدٍ ولا ينسخ حسابًا.
///
/// **ما تُبقيه من اليد السابقة** (سلوكٌ مُقرٌّ من المالك، لا يُسقَط بحجّة إعادة
/// التصميم): لمسُ ورقةٍ في غير دورك يُجهّزها مرفوعةً متوهّجة · لمسُها في دورك
/// يلعبها · سحبُها للأعلى فوق العتبة يلعبها · دخولٌ متتابعٌ عند توزيع اليد.
class PlayerHandFan extends StatefulWidget {
  final List<Card> cards;

  /// عرضُ الورقة المفضَّل. يُصغَّر **عند الضرورة وحدَها** كي تبقى اليدُ كاملةً
  /// داخل [maxWidth] — انظر [HandFanMetrics.fit].
  final double cardWidth;

  /// العرضُ المتاح على الشاشة. **حدٌّ لا يُتجاوَز**: ما خرج عن صندوق المروحة
  /// يُرسَم ولا يُلمَس (`Clip.none` لا يفحص لمسَ ما فاض) ⇒ ورقةٌ خارجةٌ = ورقةٌ ميّتة.
  final double maxWidth;

  /// دورك ⇒ اللمسُ يلعب فورًا. وإلّا فاللمسُ تجهيزٌ (رفعٌ وتوهّج) لا أكثر.
  final bool interactive;

  final void Function(Card card) onPlay;

  const PlayerHandFan({
    super.key,
    required this.cards,
    required this.cardWidth,
    required this.maxWidth,
    required this.interactive,
    required this.onPlay,
  });

  @override
  State<PlayerHandFan> createState() => _PlayerHandFanState();
}

/// هندسةُ المروحة — **حسابٌ خالصٌ بلا ودجت**: يُستدعى في الاختبار مباشرةً فتُفحَص
/// النِّسبُ (القوس · التداخل · الميل) بالأرقام لا بالنظر إلى لقطة.
class HandFanMetrics {
  /// نسبةُ تغطية الورقة لجارتها. **مدى المالك: 35–60%** — تُختار الأوسعُ (أي
  /// الأقلُّ تداخلًا) التي تسع الشاشةَ، فاليدُ تنفرج ما وسعها المكان.
  ///
  /// رُفع الحدُّ الأعلى مرّتين بطلب المالك (2026-07-21): 45% ⇒ 50% («قرّبهم
  /// قليلًا») ثمّ 50% ⇒ 60% («ورقةٌ أكبرُ وتداخلٌ أشدّ»). **وهي مقايضةٌ لا
  /// تحسينٌ مجّانيّ**: الشريطُ الظاهرُ من كلّ ورقةٍ مبنيّةٍ = [step] بالضبط، وهو
  /// نفسُه مساحةُ لمسها ⇒ كلَّما عَمُق التداخلُ ضاق ما تلمسه إصبعُك.
  static const double minOverlap = 0.35;
  static const double maxOverlap = 0.60;

  /// نسبةُ ارتفاع الورقة إلى عرضها (نسبةُ شدّةِ الورق الحقيقيّة).
  static const double aspect = 1.4;

  /// **حِمى حافّة الشاشة**: ما بقي من كلّ جانبٍ خارجَ اليد.
  ///
  /// شكوى المالك (2026-07-21): «الورقةُ اليسرى لا تستجيب للضغط». والمروحةُ كانت
  /// تملأ العرضَ إلّا 12 بكسلًا، فيقع الجزءُ المكشوفُ من الطرفيّة في **شريط إيماءات
  /// النظام** (رجوعٌ بالسحب من الحافّة، ≈20dp) — والنظامُ يبتلع اللمسةَ قبل أن
  /// تصل التطبيقَ أصلًا. لا عطبَ في الودجت يظهر في اختبار: العطبُ في مكانها.
  static const double edgeGuard = 26.0;

  /// هامشُ الميل يمنةً ويسرةً: الورقةُ الطرفيّةُ تدور حول **قاعدتها**، فتدفع
  /// زاويتُها قمّتَها خارجًا بمقدار `cardH·sin(θ)`. بلا هذا الهامش يُقصّ الطرف.
  static const double tiltPad = 0.5;

  /// ميلُ كلّ ورقةٍ عن جارتها (راديان). ثمانيةُ أوراقٍ ⇒ فتحةٌ كاملةٌ ≈ 40°:
  /// مروحةُ يدٍ ممسوكة، لا قطاعُ دائرة.
  static const double tiltPerCard = 0.10;

  /// **ارتفاعُ الورقة المحدَّدة** (بكسل مستقلٌّ عن الكثافة) — طلبُ المالك ≈30.
  static const double selectedLift = 30.0;

  /// تكبيرُ المحدَّدة — طلبُ المالك: تكبيرٌ **بسيط** يُحسّ ولا يُقحم.
  static const double selectedScale = 1.08;

  final int count;
  final double cardWidth;
  final double step; // التباعدُ الأفقيّ بين مركزَي ورقتين متجاورتين
  final double arcDepth; // كم تنخفض الطرفيّةُ عن الوسطى لكلّ خطوةٍ تربيعيّة

  const HandFanMetrics._({
    required this.count,
    required this.cardWidth,
    required this.step,
    required this.arcDepth,
  });

  /// **يسع أو يُصغّر — ولا يقصّ أبدًا.**
  ///
  /// التداخلُ المطلوب (35–45%) بعرضِ ورقةٍ كاملٍ يتجاوز عرضَ الهاتف بثمانِ أوراق،
  /// وقصُّ الطرف عطبٌ سبق أن اشتكى منه المالك. فالترتيب:
  /// 1. جرّب أوسعَ انفراجٍ يسع (تداخل 35% ⇒ 40% ⇒ 45%) بعرض الورقة المفضَّل.
  /// 2. إن لم يسع أضيقُها (45%) ⇒ **صغّر الورقةَ بالقدر اللازم وحدَه** وابقَ عند 45%.
  factory HandFanMetrics.fit({
    required int count,
    required double maxWidth,
    required double preferredCardWidth,
  }) {
    // **عرضُ الورقة نفسِها + هامشُ الميل على الجانبين + خطوات الباقي.**
    // إسقاطُ حدِّ `cw` (خطأٌ وقعتُ فيه) يجعل الصندوقَ أضيقَ من محتواه بعرض ورقة،
    // فتخرج الطرفيّةُ عنه: تُرسَم (`Clip.none`) **ولا تُلمَس** — ورقةٌ ميّتة.
    double widthFor(double cw, double spread) =>
        cw * (1 + 2 * tiltPad) + (count - 1) * cw * spread;

    // spread = 1 − overlap. الأوسعُ أوّلًا: يدٌ منفرجةٌ أسهلُ قراءةً ولمسًا.
    for (final overlap in const [
      minOverlap,
      0.40,
      0.45,
      0.50,
      0.55,
      maxOverlap
    ]) {
      final spread = 1 - overlap;
      if (count < 2 || widthFor(preferredCardWidth, spread) <= maxWidth) {
        return HandFanMetrics._raw(count, preferredCardWidth, spread);
      }
    }
    const spread = 1 - maxOverlap;
    final cw = math.min(
      preferredCardWidth,
      maxWidth / (1 + 2 * tiltPad + (count - 1) * spread),
    );
    return HandFanMetrics._raw(count, cw, spread);
  }

  factory HandFanMetrics._raw(int count, double cardWidth, double spread) {
    return HandFanMetrics._(
      count: count,
      cardWidth: cardWidth,
      step: cardWidth * spread,
      // **قوسٌ منخفض**: عمقٌ يجعل فرقَ الطرف عن الوسط ≈ ثُمنَ ارتفاع الورقة —
      // انحناءةُ راحةِ اليد، لا نصفَ دائرة.
      arcDepth: cardWidth * aspect * 0.022,
    );
  }

  double get cardHeight => cardWidth * aspect;
  double get _center => (count - 1) / 2.0;

  /// أقصى ارتفاعٍ في القوس (عند الورقة الوسطى).
  double get arcRise => arcDepth * _center * _center;

  double get width => cardWidth * (1 + 2 * tiltPad) + (count - 1) * step;

  /// الارتفاعُ يشمل القوسَ **ورفعَ التحديد وتكبيرَه**: ما فاض عن الصندوق لا يُلمَس.
  double get height =>
      cardHeight * selectedScale + arcRise + selectedLift + cardWidth * 0.12;

  /// نسبةُ التداخل الفعليّة — يفحصها الاختبار مباشرةً.
  double get overlap => 1 - step / cardWidth;

  /// يسارُ الورقة [i] داخل الصندوق.
  double left(int i) => cardWidth * tiltPad + i * step;

  /// ارتفاعُ قاعدةِ الورقة [i] عن قاع الصندوق — **الوسطى أعلى، والأطرافُ أخفض**.
  double bottom(int i) {
    final d = i - _center;
    return arcRise - arcDepth * d * d;
  }

  /// زاويةُ الورقة [i] (راديان، موجبٌ = ميلٌ يمينًا). الوسطى قائمة.
  double angle(int i) => (i - _center) * tiltPerCard;

  /// موضعُ كومةِ الدخول: كلُّ الأوراق فوق منتصف المروحة حيث انتهى التوزيع.
  double get stackLeft => cardWidth * tiltPad + _center * step;
}

class _PlayerHandFanState extends State<PlayerHandFan>
    with SingleTickerProviderStateMixin {
  /// **انفتاحُ المروحة**: كومةٌ فوق المنتصف ⇒ يدٌ مفتوحة. مُتحكّمٌ واحدٌ لكلّ اليد،
  /// وتتابعُ الأوراق من [Interval] لكلٍّ منها ⇒ ورقةٌ تلو ورقةٍ بمُتحكّمٍ واحدٍ
  /// يُتلَف مع الودجت (لا مؤقّتاتٍ معلّقة خلف الاختبارات).
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  /// آخرُ تأخيرٍ لورقة (كسرًا من مدّة المُتحكّم) — الباقي مدّةُ حركتها.
  static const double _stagger = 0.06;
  static const double _cardSpan = 0.52;

  Card? _armed; // مُجهَّزةٌ (لمسٌ في غير دورك) أو مرفوعةٌ أثناء السحب
  Card? _drag;
  Offset _dragDelta = Offset.zero;

  @override
  void initState() {
    super.initState();
    _entry.forward();
  }

  @override
  void didUpdateWidget(PlayerHandFan old) {
    super.didUpdateWidget(old);
    // غادرت الورقةُ اليدَ (لُعِبت) ⇒ لا تبقَ مُجهَّزةً ولا مسحوبة.
    if (_armed != null && !widget.cards.contains(_armed)) _armed = null;
    if (_drag != null && !widget.cards.contains(_drag)) {
      _drag = null;
      _dragDelta = Offset.zero;
    }
    // يدٌ جديدةٌ بعد فراغ (جولةٌ تالية) ⇒ تنفتح من جديد.
    if (old.cards.isEmpty && widget.cards.isNotEmpty) {
      _entry
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  void _tap(Card card) {
    if (widget.interactive) {
      setState(() => _armed = null);
      widget.onPlay(card);
    } else {
      setState(() => _armed = _armed == card ? null : card);
    }
  }

  void _endDrag(Card card, double cardHeight) {
    // **سحبٌ للأعلى فوق نصف ارتفاع الورقة ⇒ لعبٌ** (في دورك)؛ وإلّا عودةٌ بسلاسة.
    final play = widget.interactive && -_dragDelta.dy > cardHeight * 0.5;
    setState(() {
      _drag = null;
      _dragDelta = Offset.zero;
      if (play) _armed = null;
    });
    if (play) widget.onPlay(card);
  }

  /// تقدّمُ انفتاح الورقة [i]: 0 كومةً، 1 في مكانها من المروحة.
  ///
  /// يُحسَب مباشرةً من قيمة المُتحكّم لا بـ`CurvedAnimation` — تلك كائنٌ يُنشأ
  /// **في كلّ إطارٍ لكلّ ورقة** ويحتاج إتلافًا، وهذا حسابٌ خالصٌ بلا ذيل.
  double _progress(int i) {
    final begin = math.min(i * _stagger, 1 - _cardSpan);
    final raw = ((_entry.value - begin) / _cardSpan).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) return const SizedBox.shrink();

    final m = HandFanMetrics.fit(
      count: cards.length,
      maxWidth: widget.maxWidth,
      preferredCardWidth: widget.cardWidth,
    );

    // **كلُّ الشجرة داخل الـbuilder**: لو بُنيت البطاقاتُ خارجَه لَالتقطت تقدّمَ
    // الانفتاح مرّةً واحدةً (صفرًا) وبقيت اليدُ **كومةً لا تنفتح أبدًا** —
    // و`AnimatedBuilder` يُعيد بناءَ الصندوق وحدَه بأطفالٍ محفوظين.
    Widget slot(int i) {
      final card = cards[i];
      final dragging = card == _drag;
      final lifted = card == _armed || dragging;
      final p = _progress(i);

      // الانفتاح: من كومةِ المنتصف (قائمةً، شفّافة) إلى موضعها وميلِها.
      final left = m.stackLeft + (m.left(i) - m.stackLeft) * p;
      final angle = m.angle(i) * p;

      return Positioned(
        key: ValueKey(card.code),
        left: left + (dragging ? _dragDelta.dx : 0),
        bottom: m.bottom(i) - (dragging ? _dragDelta.dy : 0),
        child: Opacity(
          opacity: p,
          child: Transform.rotate(
            // **المحورُ عند القاعدة**: أوراقٌ تخرج من قبضةٍ واحدةٍ تحتها، وهو
            // الفرقُ بين يدٍ مُمسَكةٍ وأوراقٍ موزّعةٍ على قوس.
            angle: lifted ? 0 : angle,
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              // **رفعُ التحديد بمُتحكّمٍ خاصٍّ به**: يبدأ من حيث بلغ لا من الصفر،
              // فتبديلُ الورقة المحدَّدة سلسٌ لا قفزة.
              tween: Tween(begin: 0, end: lifted ? 1 : 0),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              builder: (context, lift, child) => Transform.translate(
                offset: Offset(0, -HandFanMetrics.selectedLift * lift),
                child: Transform.scale(
                  scale: 1 + (HandFanMetrics.selectedScale - 1) * lift,
                  alignment: Alignment.bottomCenter,
                  child: child,
                ),
              ),
              // **اللمسُ ملتصقٌ بالورقة نفسِها** (تحت التحويلات لا فوقها): فنطاقُ
              // اللمس يدور ويرتفع معها، ولا تبتلع ورقةٌ لمسةَ جارتها.
              //
              // **جُرّب تضييقُه إلى الشريط الظاهر وحدَه** (2026-07-21) طمعًا في
              // نطاقاتٍ منفصلةٍ لا يحكمها ترتيبُ الرسم — فخسرت كلُّ ورقةٍ نصفَ
              // مساحة لمسها (136 خليّةً بدل 308 في القياس): الجارةُ المائلةُ لا
              // تغطّي مستطيلًا قائمًا، فما بين الشريط وحافّة الجارة **مرئيٌّ
              // ومُلمَسٌ** وكان يُهدر. الصندوقُ الكاملُ يكسبه.
              child: Clickable(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _tap(card),
                  onPanStart: (_) => setState(() {
                    _drag = card;
                    _dragDelta = Offset.zero;
                  }),
                  onPanUpdate: (d) => setState(() => _dragDelta += d.delta),
                  onPanEnd: (_) => _endDrag(card, m.cardHeight),
                  child:
                      _FanCard(card: card, width: m.cardWidth, armed: lifted),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // المرفوعةُ تُرسَم فوق جاراتها (تُؤخَّر في المكدّس) بلا تغيّرِ موضعها.
    bool onTop(Card c) => c == _drag || c == _armed;

    return AnimatedBuilder(
      animation: _entry,
      builder: (context, _) => SizedBox(
        width: m.width,
        height: m.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // **اليمنى فوق اليسرى — لأنّ الرمزَ في الزاوية العليا اليسرى.**
            // الورقةُ المبنيّةُ لا يظهر منها إلّا شريطُها الأيسر، وفيه الرمزُ
            // معتدلًا. جرّبتُ العكسَ (2026-07-21) لأكسب مساحةَ لمسٍ للطرف
            // الأيسر، فأخفى العكسُ الرمزَ ولم يبقَ ظاهرًا إلّا نظيرُه **المقلوبُ
            // 180°** في الزاوية السفلى: «تُجبرنا على قراءتها من تحت» — وهي
            // مقايضةٌ خاسرة، فاليدُ تُقرأ قبل أن تُلمَس. اللمسُ حُلّ بنطاقاتٍ
            // منفصلة (`_TouchStrip`) لا بترتيب الرسم.
            for (var i = 0; i < cards.length; i++)
              if (!onTop(cards[i])) slot(i),
            for (var i = 0; i < cards.length; i++)
              if (onTop(cards[i])) slot(i),
          ],
        ),
      ),
    );
  }
}

/// ورقةٌ في اليد: وجهُها، وتوهّجٌ ذهبيٌّ خفيفٌ حين تُحدَّد.
class _FanCard extends StatelessWidget {
  final Card card;
  final double width;
  final bool armed;

  const _FanCard({required this.card, required this.width, this.armed = false});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      width: width,
      decoration: armed
          ? BoxDecoration(
              // نفسُ نصفِ قطرِ الورقة ⇒ التوهّجُ يتبع حافّتَها لا حافّةً أعرض.
              borderRadius: CardShell.radiusFor(width),
              boxShadow: [
                BoxShadow(
                  color: t.accent.withValues(alpha: 0.55),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: CardFace(card: card),
    );
  }
}
