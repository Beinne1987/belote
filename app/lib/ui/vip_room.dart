import 'package:flutter/material.dart';

/// **غرفةُ VIP — أصلٌ واحدٌ وقرارُ تعتيمٍ واحد.**
///
/// الغرفةُ تظهر على ثلاثة أسطح: طاولةُ اللعب (خلفَ الطاولة) · لوبي الطاولة
/// الخاصّة · شاشةُ الاشتراك. لو نُسخ اسمُ الأصل وقيمةُ التعتيم في كلٍّ منها
/// لَاختلفت الغرفةُ عن نفسها عند أوّل تبديلِ صورة، فصار المشترِكُ يرى ثلاثَ
/// غرفٍ لا غرفةً واحدة.
///
/// **التعتيمُ ليس زينة**: فوقها أوراقٌ وبطاقاتٌ ونصّ، وخلفيّةٌ صارخةٌ تبتلعها؛
/// فلكلّ سطحٍ قدرُه — الطاولةُ تحتاج أقلَّه (الطاولةُ نفسُها تغطّي وسطَها)
/// والنصُّ يحتاج أكثرَه.
class VipRoom {
  const VipRoom._();

  /// الجدارُ المزخرف — الأخضرُ والذهب. هو نفسُه لبّادُ الطاولة الفاخرة
  /// (`TableConfig.vipRoyale`) قصدًا: غرفةٌ وطاولةٌ من عالمٍ واحد.
  static const asset = 'assets/VIP/room_game_table.jpg';

  /// بابُ «مجلسٌ خاصّ» — صورةٌ شفّافةُ الخلفيّة تصلح شعارًا للغرفة.
  static const doorAsset = 'assets/VIP/VIP_room.png';

  /// **تعتيمُ الجدار حولَ طاولة اللعب.**
  ///
  /// أعمقُ من تعتيمِ اللبّاد (0.28 في `PremiumTablePainter._paintImageField`)
  /// **قصدًا**: الزخرفةُ نفسُها على السطح وعلى الجدار، ففارقُ السطوعِ وحدَه هو
  /// ما يجعل الطاولةَ سطحًا مضيئًا في غرفةٍ غامقةٍ لا رقعةً من الجدار.
  /// لا تُقارِبْ بينهما.
  static const roomDim = 0.58;

  /// خلفيّةُ الغرفة بتعتيمٍ [dim] (0 = بلا تعتيم · 1 = أسود).
  static DecorationImage image({double dim = 0.4}) => DecorationImage(
        image: const AssetImage(asset),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          Color.fromRGBO(0, 0, 0, dim.clamp(0.0, 1.0)),
          BlendMode.darken,
        ),
      );

  /// عرضُ الغرفة **خلفَ** محتوًى ما، مع تعتيمٍ يناسبه.
  static Widget behind({required Widget child, double dim = 0.4}) =>
      DecoratedBox(decoration: BoxDecoration(image: image(dim: dim)), child: child);

  /// الهامشُ الذي تُترَك فيه الغرفةُ ظاهرةً حول طاولة اللعب، نسبةً إلى أصغر
  /// بُعدٍ في الشاشة. **صغيرٌ عمدًا**: المقاعدُ واليدُ توضَع على حوافّ الشاشة
  /// (انظر `TableConfig.fill`)، فهامشٌ عريضٌ يُخرجها عن اللبّاد.
  static double inset(double shortestSide) =>
      (shortestSide * 0.045).clamp(10.0, 28.0);
}
