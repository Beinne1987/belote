import 'package:app/ui/table/table_config.dart';
import 'package:app/ui/table/table_geometry.dart';
import 'package:app/ui/table/table_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('هندسةُ الطاولة', () {
    test('مع الملء تغطّي الطاولةُ المساحةَ المتاحةَ كلَّها', () {
      const avail = Size(400, 860); // هاتفٌ طوليّ: النسبةُ الثابتةُ تترك فراغًا
      final g = TableGeometry.of(avail, const TableConfig(fill: true));
      expect(g.outer, Offset.zero & avail);
      // اللبّادُ داخلَ الإطار، والإطارُ محسوبٌ من أصغر بُعد.
      expect(g.felt.width, lessThan(avail.width));
      expect(g.rail, closeTo(0.085 * 400, 0.001));
    });

    test('بلا الملء تبقى النسبةُ محفوظةً وممركزة', () {
      const avail = Size(400, 860);
      final g = TableGeometry.of(avail, const TableConfig());
      expect(g.outer.width / g.outer.height, closeTo(1.5, 0.001));
      expect(g.outer.center,
          offsetMoreOrLessEquals(avail.center(Offset.zero), epsilon: 0.001));
    });

    test('الأطُرُ الجاهزةُ لشاشة اللعب تملأ كلُّها', () {
      expect(TableSurface.hall.fill, isTrue);
      expect(TableSurface.vip.fill, isTrue);
      // **لبّادُ VIP صورةٌ لا سادة** (طلبُ المالك 2026-07-21): زخرفةُ المجلس
      // تُفرَش على السطح أيضًا؛ وما يمنع ذوبانَ الطاولة في الغرفة هو فارقُ
      // السطوع (`VipRoom.roomDim` أعتمُ) والإطارُ والتطعيم — يحرسه
      // `vip_room_test.dart`.
      expect(TableSurface.vip.feltStyle, FeltStyle.image);
      expect(TableSurface.vip.feltImageAsset, isNotNull);
    });
  });

  testWidgets('سطحُ الطاولة يُبنى ويرسم بلا أصولٍ خارجيّة', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: TableSurface(config: TableSurface.hall)),
    ));
    expect(find.byType(TableSurface), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
