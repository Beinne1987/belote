import 'package:flutter/animation.dart';

/// كل توقيتات الحركة ومنحنياتها — **المصدر الوحيد**.
///
/// لا يُكتب رقم توقيت مباشرةً في أي ملف آخر. إن احتجت زمناً أو منحنى، خذه من هنا.
///
/// فلسفة الأرقام (من صاحب المشروع):
/// - تحت ١٥٠ms العين لا تلحق الحركة؛ فوق ٤٠٠ms تشعر أنك تنتظر. ٢٨٠ نقطة التوازن.
/// - `easeOutCubic` لا `linear`: الأشياء الحقيقية تنطلق بسرعة ثم يوقفها الاحتكاك.
class Motion {
  const Motion._();

  /// انزلاق الورقة من اليد إلى الطاولة — الحركة الأهم. أبطأ قليلاً كي «تُحَسّ».
  static const Duration slideCard = Duration(milliseconds: 340);
  static const Curve slideCardCurve = Curves.easeOutCubic;

  /// ارتفاع الورقة قليلاً عند التمرير/الاختيار.
  static const Duration liftCard = Duration(milliseconds: 140);
  static const Curve liftCardCurve = Curves.easeOutBack;

  /// وقفة بعد اكتمال الأبلي (أربع أوراق) لترى **الورقة الأخيرة** قبل الجمع.
  static const Duration pliPause = Duration(milliseconds: 1300);

  /// جمع الأبلي نحو الفائز — أبطأ وأنعم (تتجمّع وتخفت تدريجيًّا).
  static const Duration pliCollect = Duration(milliseconds: 480);
  static const Curve pliCollectCurve = Curves.easeInOutCubic;

  /// استقرارٌ قصير بعد جمع الأبلي وقبل أن يبدأ الدور التالي — كي لا ينطلق فجأة.
  static const Duration pliSettle = Duration(milliseconds: 320);

  /// «تفكير» الذكاء الآلي (أساسٌ) قبل أن يلعب أو يضمن. يُضاف إليه تشويشٌ عشوائيّ
  /// في الكنترولر (`aiThinkJitter`) كي يبدو بشريًّا لا آليًّا مُنتظمًا.
  static const Duration aiThink = Duration(milliseconds: 1000);

  /// أقصى تشويشٍ عشوائيّ يُضاف إلى تفكير الذكاء (0..هذا) — إيقاعٌ بشريّ متغيّر.
  static const Duration aiThinkJitter = Duration(milliseconds: 700);

  /// توزيع الورق الافتتاحي من مقعد الموزّع (٥ لكل لاعب): مدّة النافذة كاملةً.
  static const Duration deal = Duration(milliseconds: 1700);
  static const Curve dealCurve = Curves.easeOutCubic;

  /// نافذة التوزيع الثانية بعد الضمانة (الثلاث الباقية ⇒ ٨ لكل لاعب). أقصر لأنها أقلّ ورقاً.
  static const Duration dealRest = Duration(milliseconds: 1000);

  /// كم تبقى فقاعة ضمانة اللاعب ظاهرة قبل أن تخفت (لا علاقة لها بإيقاع الذكاء).
  static const Duration bidBubbleHold = Duration(milliseconds: 1100);

  /// أونلاين فقط: أدنى مسافةٍ بين ظهور ورقةِ لعبٍ وأخرى. لقطات لعب الذكاء تصل متراكمةً
  /// عبر الشبكة أثناء الوقفات فتُطبَّق دفعةً؛ هذه تفرّقها لتظهر متتابعةً كالأوفلاين.
  static const Duration onlinePlayStagger = Duration(milliseconds: 450);

  /// أونلاين فقط: كم تبقى فقاعة التفاعل (الإيموجي) فوق بطاقة اللاعب. طويلةٌ بما
  /// يكفي لتُرى، قصيرةٌ بما يكفي ألّا تزاحم اللعب.
  static const Duration reactionHold = Duration(milliseconds: 2600);
}
