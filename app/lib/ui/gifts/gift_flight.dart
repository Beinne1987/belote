/// **رحلةُ هديّةٍ واحدة** — الوصفُ الذي يبثّه الكنترولرُ ويستهلكه المحرّك.
///
/// لا حركةَ هنا ولا رسم: نقطةُ بدءٍ ونقطةُ وصولٍ واسمان ووصفةٌ بصريّة. الزمنُ يملكه
/// الكنترولر (طابورٌ واحدٌ لكلّ الطاولة) والرسمُ يملكه `gift_flight_layer.dart`.
library;

import 'package:flutter/widgets.dart';

import 'gift_spec.dart';

/// **مراسي المقاعد الأربعة** بترتيب العرض (0 = أنا أسفل، 1 يمين، 2 أعلى، 3 يسار).
///
/// **مصدرُ حقيقةٍ واحد**: `table_screen.dart` يضع بطاقاتِ اللاعبين بهذه القيم نفسِها،
/// والمحرّكُ يطيّر إليها. لو نُسخت في الملفّين لَانزاحت الهديّةُ عن البطاقة عند أوّل
/// تعديلٍ للتخطيط — وهو خطأٌ لا يُرى في اختبارٍ بل في يد اللاعب.
const kSeatAnchors = <Alignment>[
  // **أنا أدنى من الجميع**: بطاقتي كانت تلامس دائرةَ اللعب وتزاحم الورقةَ التي
  // ألعبها فيها. النزولُ هنا يفتح فرجةً بيني وبين الدائرة، ولا يبلغ اليدَ:
  // أعلى صندوقِ المروحة مساحةُ رفعِ الورقة المحدَّدة لا أوراقًا مستقرّة.
  Alignment(0, 0.56), // 0 — أنا

  Alignment(0.99, -0.04), // 1 — الخصم يمينًا (لصيقُ الحافّة)
  Alignment(0, -0.68), // 2 — الشريك أعلى
  Alignment(-0.99, -0.04), // 3 — الخصم يسارًا (لصيقُ الحافّة)
];

/// مرسى **المدرّجات**: من أسفل الشاشة تمامًا. المشاهدُ لا مقعدَ له، فهديّتُه تصعد
/// من خارج الطاولة — والفرقُ مقصود: يُرى أنّها من الجمهور لا من جليس.
const kStandsAnchor = Alignment(0, 1.06);

/// زمنُ أثر الوصول بعد ملامسة البطاقة (الحلقةُ والشظايا وبطاقةُ الاسم).
const kGiftBurst = Duration(milliseconds: 460);

/// رحلةٌ واحدةٌ في الطابور.
@immutable
class GiftFlight {
  /// رقمٌ متزايدٌ يميّز الرحلة — به يعرف المحرّكُ أنّ رحلةً **جديدة** بدأت فيُعيد
  /// المؤقّت. بلا هذا تُدمَج هديّتان متتاليتان من نفس المقعد إلى نفس المقعد في
  /// حركةٍ واحدةٍ لا تُعاد.
  final int id;

  /// مقعدُ المُرسِل بترتيب العرض، أو **null ⇒ من المدرّجات** (مشاهدٌ لا مقعدَ له).
  final int? fromSeat;

  /// مقعدُ المستقبِل بترتيب العرض.
  final int toSeat;

  final String senderName;
  final String receiverName;

  /// وصفةُ الهديّة البصريّة — تُحلّ مرّةً عند الإنشاء لا في كلّ إطار.
  final GiftVisuals visuals;

  GiftFlight({
    required this.id,
    required this.fromSeat,
    required this.toSeat,
    required this.senderName,
    required this.receiverName,
    required String giftId,
  }) : visuals = giftVisualsFor(giftId);

  String get giftId => visuals.id;

  Alignment get origin =>
      fromSeat == null ? kStandsAnchor : kSeatAnchors[fromSeat!];
  Alignment get target => kSeatAnchors[toSeat];

  Duration get travel => visuals.fx.travel;

  /// الزمنُ الكلّيّ للحركة: عبورٌ ثمّ أثرُ وصول.
  Duration get total => travel + kGiftBurst;

  /// أينَ تقع لحظةُ الوصول من الحركة الكلّيّة (0..1) — يقسمها المحرّكُ إلى طورَين.
  double get travelFraction =>
      travel.inMicroseconds / total.inMicroseconds.clamp(1, 1 << 62);
}
