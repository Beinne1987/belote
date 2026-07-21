import 'package:flutter/material.dart';

/// نمطُ سطحِ اللبّاد: أخضرُ فاخرٌ سادةٌ · **علمُ موريتانيا** (أخضرُ بشريطين
/// أحمرين وهلالٍ ونجمةٍ ذهبيّة) · أو **صورةٌ** داخل الطاولة (خلفيّةُ VIP).
enum FeltStyle { plain, mauritaniaFlag, image }

/// **إعدادُ الطاولة** — كلُّ ما يُرسَم قابلٌ للضبط من هنا.
///
/// معزولٌ عن ثيم التطبيق (`BeloteTheme`) عمدًا: الطاولةُ سطحٌ ماديٌّ (خشبٌ ولبّادٌ
/// وضوء) لا لوحةُ ألوانِ واجهة، ولأنّ العرضَ التجريبيَّ في `lib/experimental/`
/// يبنيها للويب وحدَها. مَن يريد ربطَها بالثيم يمرّر الألوانَ عند الإنشاء.
///
/// **immutable + copyWith**: لوحةُ التحكّم تولّد نسخةً جديدةً عند كلّ تعديل، فلا
/// حالةَ خفيّةٌ تتسرّب، ويعيد `CustomPainter` الرسمَ فقط حين تتغيّر القيم فعلًا.
@immutable
class TableConfig {
  // ── إطار الخشب (rail) ──
  /// لونُ قلبِ الخشب — منه يُشتقّ التدرّجُ إلى الأفتح (إضاءة) والأغمق (ظلّ).
  final Color woodColor;

  /// درجةُ لمعان الخشب (0..1): كم يُبرزه الضوء العلويّ.
  final double woodGloss;

  /// سُمكُ الإطار نسبةً إلى أصغر بُعدٍ للطاولة (0.04..0.18).
  final double railThickness;

  // ── سطح اللبّاد (felt) ──
  /// نمطُ السطح: سادةٌ أم علمُ موريتانيا.
  final FeltStyle feltStyle;
  final Color feltCenter;
  final Color feltEdge;

  // ألوانُ العلم (تُستعمَل حين [feltStyle] = mauritaniaFlag).
  final Color flagGreen;
  final Color flagRed;
  final Color flagGold;

  /// أصلُ الصورةِ على اللبّاد (حين [feltStyle] = image) — خلفيّةُ VIP.
  final String? feltImageAsset;

  /// طباعةٌ ذهبيّةٌ في وسط الطاولة (مثال: `VIP`). فارغةٌ ⇒ بلا طباعة.
  final String centerLabel;

  /// شدّةُ الظلّ الداخليّ عند حافّة اللبّاد (vignette) — عمقُ الحوض.
  final double feltVignette;

  // ── الإضاءة المحيطة ──
  /// موضعُ بؤرةِ الضوء على السطح (بإحداثيّات -1..1، الأعلى سالب).
  final Alignment lightSource;

  /// شدّةُ بقعةِ الضوء على اللبّاد (0..1).
  final double ambientLight;

  // ── الشكل ──
  /// نصفُ قطرِ الزوايا نسبةً إلى أصغر بُعد (0=مستطيل حادّ .. 0.5=حَلَقيّ).
  final double cornerRadius;

  /// نسبةُ العرض إلى الارتفاع للطاولة نفسِها (بلا الإطار). تُتجاهَل حين [fill].
  final double aspectRatio;

  /// **تملأ الطاولةُ المساحةَ المتاحةَ كلَّها** بدل التقيّد بـ[aspectRatio].
  ///
  /// شاشةُ اللعب الحقيقيّة تضع المقاعدَ والأيدي على حوافّ الشاشة، فطاولةٌ
  /// بنسبةٍ ثابتةٍ تترك عناصرَ خارجَ اللبّاد. مع الملء يصير الإطارُ الخشبيُّ
  /// حافّةَ الشاشة واللبّادُ ما بينها ⇒ كلُّ ما يُوضَع فوقها يقع داخلها.
  final bool fill;

  // ── لمسات فاخرة ──
  /// خطُّ التطعيم الذهبيّ بين الخشب واللبّاد.
  final bool showInlay;
  final Color inlayColor;

  /// انعكاسٌ زجاجيٌّ ناعمٌ أعلى الإطار (لمعةٌ عريضة).
  final bool showReflection;

  /// شعارٌ باهتٌ في وسط اللبّاد (حَلَقتان + نجمة).
  final bool showEmblem;

  const TableConfig({
    this.woodColor = const Color(0xFF5A3620),
    this.woodGloss = 0.55,
    this.railThickness = 0.085,
    this.feltStyle = FeltStyle.mauritaniaFlag,
    this.feltCenter = const Color(0xFF1B6B4A),
    this.feltEdge = const Color(0xFF0A2E20),
    this.flagGreen = const Color(0xFF00853F),
    this.flagRed = const Color(0xFFD01C1F),
    this.flagGold = const Color(0xFFFFD100),
    this.feltImageAsset,
    this.centerLabel = '',
    this.feltVignette = 0.55,
    this.lightSource = const Alignment(0, -0.65),
    this.ambientLight = 0.5,
    this.cornerRadius = 0.14,
    this.aspectRatio = 1.5,
    this.fill = false,
    this.showInlay = true,
    this.inlayColor = const Color(0xFFD9B45B),
    this.showReflection = true,
    this.showEmblem = false, // أُزيلت النجمةُ الوسطى بطلب المالك؛ علمُ اللبّاد يكفي
  });

  TableConfig copyWith({
    Color? woodColor,
    double? woodGloss,
    double? railThickness,
    FeltStyle? feltStyle,
    Color? feltCenter,
    Color? feltEdge,
    Color? flagGreen,
    Color? flagRed,
    Color? flagGold,
    String? feltImageAsset,
    String? centerLabel,
    double? feltVignette,
    Alignment? lightSource,
    double? ambientLight,
    double? cornerRadius,
    double? aspectRatio,
    bool? fill,
    bool? showInlay,
    Color? inlayColor,
    bool? showReflection,
    bool? showEmblem,
  }) =>
      TableConfig(
        woodColor: woodColor ?? this.woodColor,
        woodGloss: woodGloss ?? this.woodGloss,
        railThickness: railThickness ?? this.railThickness,
        feltStyle: feltStyle ?? this.feltStyle,
        feltCenter: feltCenter ?? this.feltCenter,
        feltEdge: feltEdge ?? this.feltEdge,
        flagGreen: flagGreen ?? this.flagGreen,
        flagRed: flagRed ?? this.flagRed,
        flagGold: flagGold ?? this.flagGold,
        feltImageAsset: feltImageAsset ?? this.feltImageAsset,
        centerLabel: centerLabel ?? this.centerLabel,
        feltVignette: feltVignette ?? this.feltVignette,
        lightSource: lightSource ?? this.lightSource,
        ambientLight: ambientLight ?? this.ambientLight,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        aspectRatio: aspectRatio ?? this.aspectRatio,
        fill: fill ?? this.fill,
        showInlay: showInlay ?? this.showInlay,
        inlayColor: inlayColor ?? this.inlayColor,
        showReflection: showReflection ?? this.showReflection,
        showEmblem: showEmblem ?? this.showEmblem,
      );

  /// أطُرٌ جاهزةٌ للمقارنة السريعة في اللوحة.
  static const TableConfig walnutEmerald = TableConfig();

  static const TableConfig mahoganyRuby = TableConfig(
    feltStyle: FeltStyle.plain,
    woodColor: Color(0xFF6B2A20),
    feltCenter: Color(0xFF7A1F2B),
    feltEdge: Color(0xFF2E0A10),
    inlayColor: Color(0xFFE0C069),
  );

  static const TableConfig ebonySapphire = TableConfig(
    feltStyle: FeltStyle.plain,
    woodColor: Color(0xFF2A2620),
    woodGloss: 0.7,
    feltCenter: Color(0xFF1E4E7A),
    feltEdge: Color(0xFF081A2E),
    inlayColor: Color(0xFFC8CEDA),
    railThickness: 0.075,
  );

  static const TableConfig oakMidnight = TableConfig(
    feltStyle: FeltStyle.plain,
    woodColor: Color(0xFF7A5A32),
    woodGloss: 0.5,
    feltCenter: Color(0xFF243244),
    feltEdge: Color(0xFF0C1119),
    cornerRadius: 0.2,
  );

  /// **طاولةُ VIP** — الأفخم: آبنوسٌ داكنٌ عالي اللمعان · تطعيمٌ ذهبيٌّ فاتح ·
  /// لبّادٌ زمرّديٌّ عميقٌ بحوضٍ أعمق وإضاءةٍ أقوى · ميداليّةٌ ذهبيّة · انعكاسٌ
  /// أوضح. تُعرَض فوق خلفيّة غرفة VIP الحاليّة.
  static const TableConfig vipRoyale = TableConfig(
    feltStyle: FeltStyle.image,
    feltImageAsset: 'assets/VIP/room_game_table.jpg',
    centerLabel: 'VIP',
    woodColor: Color(0xFF241309),
    woodGloss: 0.85,
    railThickness: 0.095,
    feltCenter: Color(0xFF0E6242),
    feltEdge: Color(0xFF03251A),
    feltVignette: 0.72,
    ambientLight: 0.7,
    lightSource: Alignment(0, -0.6),
    cornerRadius: 0.17,
    inlayColor: Color(0xFFF2D486),
    showInlay: true,
    showReflection: true,
    showEmblem: true,
  );

  bool sameShapeAs(TableConfig o) =>
      railThickness == o.railThickness &&
      cornerRadius == o.cornerRadius &&
      aspectRatio == o.aspectRatio &&
      fill == o.fill;

  // قيمةٌ لا مرجع: `shouldRepaint` يعتمد `!=` ⇒ بلا هذا يُعيد الرسمَ كلَّ إطار.
  @override
  bool operator ==(Object other) =>
      other is TableConfig &&
      other.woodColor == woodColor &&
      other.woodGloss == woodGloss &&
      other.railThickness == railThickness &&
      other.feltStyle == feltStyle &&
      other.feltCenter == feltCenter &&
      other.feltEdge == feltEdge &&
      other.flagGreen == flagGreen &&
      other.flagRed == flagRed &&
      other.flagGold == flagGold &&
      other.feltImageAsset == feltImageAsset &&
      other.centerLabel == centerLabel &&
      other.feltVignette == feltVignette &&
      other.lightSource == lightSource &&
      other.ambientLight == ambientLight &&
      other.cornerRadius == cornerRadius &&
      other.aspectRatio == aspectRatio &&
      other.fill == fill &&
      other.showInlay == showInlay &&
      other.inlayColor == inlayColor &&
      other.showReflection == showReflection &&
      other.showEmblem == showEmblem;

  @override
  int get hashCode => Object.hashAll([
        woodColor,
        woodGloss,
        railThickness,
        feltStyle,
        feltCenter,
        feltEdge,
        flagGreen,
        flagRed,
        flagGold,
        feltImageAsset,
        centerLabel,
        feltVignette,
        lightSource,
        ambientLight,
        cornerRadius,
        aspectRatio,
        fill,
        showInlay,
        inlayColor,
        showReflection,
        showEmblem,
      ]);
}
