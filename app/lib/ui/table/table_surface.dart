import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../vip_room.dart';
import 'premium_table_painter.dart';
import 'table_config.dart';

/// **سطحُ الطاولة** — الخشبُ واللبّادُ والإضاءة، طبقةً واحدةً تحت كلّ شيء.
///
/// يُوضَع أسفلَ مكدّس شاشة اللعب فيصير ما فوقه (الأوراقُ والبطاقاتُ والأزرار)
/// جالسًا على طاولةٍ حقيقيّة. لا يعرف شيئًا عن الجولة: يرسم السطحَ فقط.
///
/// **الأداء**: داخلَ `RepaintBoundary`، و`shouldRepaint` يعتمد `TableConfig ==`
/// ⇒ لا يُعاد رسمُ الخشبِ ولا اللبّادِ مع كلِّ ورقةٍ تُلعَب أو عدّادٍ يتحرّك.
class TableSurface extends StatefulWidget {
  final TableConfig config;

  const TableSurface({super.key, required this.config});

  /// طاولةُ القاعة العاديّة: لبّادُ علمِ موريتانيا في إطارِ جوزٍ، تملأ الشاشة.
  static const TableConfig hall = TableConfig(fill: true);

  /// **طاولةُ VIP**: آبنوسٌ لامعٌ وتطعيمٌ ذهبيٌّ فاتحٌ على لبّادٍ مزخرفٍ عميق.
  ///
  /// **اللبّادُ صورةٌ لا سادة** (طلبُ المالك): زخرفةُ المجلس نفسُها تُفرَش على
  /// السطح. وخشيةُ «ذوبان الطاولة في الغرفة» — التي أبقت اللبّادَ سادةً قبلُ —
  /// مدفوعةٌ بثلاثةِ فواصلَ لا واحد: **الغرفةُ حولها أعتمُ** من اللبّاد
  /// (`VipRoom.roomDim` مقابل تعتيمِ اللبّاد 0.28 في الرسّام) · إطارُ آبنوسٍ
  /// لامعٍ بينهما · خطُّ تطعيمٍ ذهبيٌّ فاتح. فالطاولةُ سطحٌ مضيءٌ في غرفةٍ
  /// غامقة، لا رقعةٌ من الجدار.
  static const TableConfig vip = TableConfig(
    fill: true,
    feltStyle: FeltStyle.image,
    feltImageAsset: VipRoom.asset,
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
  );

  /// ذهبُ الطاولة التي يجلس عليها اللاعب — تأخذه اللوحاتُ التي تُركَّب فوقها
  /// (النتيجةُ والضمانة) فتبدو من الطاولة نفسِها لا غريبةً عنها.
  static Color inlayFor({required bool vip}) =>
      (vip ? TableSurface.vip : TableSurface.hall).inlayColor;

  @override
  State<TableSurface> createState() => _TableSurfaceState();
}

class _TableSurfaceState extends State<TableSurface> {
  ui.Image? _felt;
  String? _loaded;

  @override
  void initState() {
    super.initState();
    _ensureFeltImage();
  }

  @override
  void didUpdateWidget(TableSurface old) {
    super.didUpdateWidget(old);
    if (old.config.feltImageAsset != widget.config.feltImageAsset) {
      _ensureFeltImage();
    }
  }

  /// يفكّ صورةَ اللبّاد (حين [FeltStyle.image]) إلى `ui.Image`. يبتلع فشلَه:
  /// أصلٌ مفقودٌ ⇒ يرتدّ الرسّامُ إلى لبّادٍ سادةٍ، لا طاولةَ فارغةٍ ولا انهيار.
  Future<void> _ensureFeltImage() async {
    final asset = widget.config.feltImageAsset;
    if (asset == _loaded) return;
    _loaded = asset;
    if (asset == null) {
      if (mounted) setState(() => _felt = null);
      return;
    }
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted && _loaded == asset) setState(() => _felt = frame.image);
    } catch (_) {
      /* أصلٌ مفقودٌ ⇒ لبّادٌ سادة */
    }
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: PremiumTablePainter(widget.config, feltImage: _felt),
        ),
      );
}
