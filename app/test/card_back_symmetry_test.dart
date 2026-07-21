import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/ui/card_back.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// حارس القيد الملزِم: أي ظهر ورقة يجب أن يكون **متماثلًا عند القلب 180°**،
/// وإلا أمكن تعليم الأوراق. نُنقّط الظهر، ونُنقّطه مقلوبًا 180°، ونقارن بكسلًا
/// بكسل. الفرق المسموح ضئيل جدًّا (تنعيم الحواف فقط).
Future<Uint8List> _rasterRgba(String svg, int w, int h) async {
  final info = await vg.loadPicture(SvgStringLoader(svg), null);
  final image = await info.picture.toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  info.picture.dispose();
  image.dispose();
  return bytes!.buffer.asUint8List();
}

String _rotated180(String svg) {
  const head = '<svg viewBox="0 0 100 140" xmlns="http://www.w3.org/2000/svg">';
  final inner = svg.replaceFirst(head, '').replaceFirst(RegExp(r'</svg>$'), '');
  return '$head<g transform="rotate(180 50 70)">$inner</g></svg>';
}

void main() {
  testWidgets('كل أسكن ظهر متماثل عند 180°', (tester) async {
    await tester.runAsync(() async {
      for (final skin in availableSkins) {
        final svg = cardBackSvg(skin: skin);
        final normal = await _rasterRgba(svg, 200, 280);
        final rotated = await _rasterRgba(_rotated180(svg), 200, 280);
        var diff = 0;
        for (var i = 0; i < normal.length; i++) {
          if (normal[i] != rotated[i]) diff++;
        }
        expect(diff, lessThan(60),
            reason: 'أسكن "$skin": يجب أن يتطابق مع نفسه مقلوبًا 180° '
                '(فرق $diff بكسل — تجاوز حدّ التنعيم)');
      }
    });
  });
}
