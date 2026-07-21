import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ذاكرة مؤقتة لرسوم الأوراق.
///
/// تصحيح رقم ٣ من صاحب المشروع: **لا تحليل SVG في كل إطار.** نص الـ SVG
/// يُحلَّل **مرة واحدة** إلى `ui.Picture` ويُخزَّن بمفتاح؛ الرسم بعدها مجرّد
/// `canvas.drawPicture` — تنزلق الورقة بلا فقد إطارات.
class CardArt {
  CardArt._();

  /// القياس المرجعي لكل الأوراق (viewBox في cards.js).
  static const Size viewBox = Size(100, 140);

  static final Map<String, ui.Picture> _cache = {};

  /// يُحلّل نص [svg] ويخزّنه تحت [key] إن لم يكن مخزّناً بعد.
  static Future<void> load(String key, String svg) async {
    if (_cache.containsKey(key)) return;
    final info = await vg.loadPicture(SvgStringLoader(svg), null);
    _cache[key] = info.picture;
  }

  static ui.Picture? of(String key) => _cache[key];
  static bool has(String key) => _cache.containsKey(key);
}

/// يرسم `ui.Picture` المخزَّن (بإحداثيات 100×140) مقيسًا إلى حجم الودجة،
/// مقصوصًا بزوايا مستديرة — يمنع أي تسرّب رسم خارج حدّ الورقة.
class CardArtPainter extends CustomPainter {
  final ui.Picture picture;
  const CardArtPainter(this.picture);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * 6 / CardArt.viewBox.width; // rx=6 في المرجع
    canvas.clipRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    canvas.scale(size.width / CardArt.viewBox.width,
        size.height / CardArt.viewBox.height);
    canvas.drawPicture(picture);
  }

  @override
  bool shouldRepaint(CardArtPainter old) => old.picture != picture;
}
