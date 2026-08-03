import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// **مقاسُ الواجهة** — لا اسمُ النظام.
///
/// الفرقُ بين هاتفٍ وحاسوبٍ في الواجهة **مساحةٌ لا منصّة**: هاتفٌ مقلوبٌ عرضًا
/// ونافذةُ حاسوبٍ مصغَّرةٌ يشتركان في الضيق، ولوحٌ كبيرٌ ونافذةٌ مكبَّرةٌ يشتركان
/// في السعة. لذلك يُشتقّ هذا من عرض النافذة وحدَه: يتغيّر التخطيطُ لحظةَ يجرّ
/// اللاعبُ حافّةَ النافذة، بلا إعادة تشغيل وبلا سؤالٍ عن `Platform.isX`.
enum AppSize {
  /// عمودٌ واحدٌ وتنقّلٌ سفليّ — سلوكُ الهاتف الذي **لا يتغيّر**.
  phone,

  /// شريطٌ جانبيٌّ ضيّقٌ (أيقوناتٌ بأسماء) وعمودُ محتوًى أوسع.
  tablet,

  /// شريطٌ جانبيٌّ كاملٌ + عمودان: اللعبُ في الأوّل، والنشاطُ في لوحةٍ جانبيّة.
  desktop,
}

/// عتباتُ التخطيط وقراراتُه — **صنفٌ خالصٌ يُفحَص بالأرقام** بلا رسم.
///
/// لماذا صنفٌ واحدٌ لا `MediaQuery.of(context).size.width > 900` منثورٌ في
/// الشاشات: الرقمُ المنثور يُنسى عند إضافة شاشةٍ جديدة، ويختلف من ملفٍّ لآخر،
/// فتصير الواجهةُ تنتقل عند 900 هنا و1000 هناك. هنا موضعٌ واحدٌ يُقرأ ويُختبَر.
class AppLayout {
  AppLayout._();

  /// أضيقُ عرضٍ يستحقّ شريطًا جانبيًّا. دونَه يبقى التنقّلُ السفليَّ كما هو.
  ///
  /// 720 لا 600: الهاتفُ المقلوبُ عرضًا (‎852×393) يبلغ 852 فيصير «لوحًا» بشريطٍ
  /// جانبيٍّ لا مكانَ له تحت الإبهام. لكنّ اللعبةَ **عموديّةٌ على الهاتف** أصلًا
  /// (لا دورانَ في شاشة اللعب)، فالعرضُ 720+ لا يبلغه إلّا لوحٌ أو نافذةُ حاسوب.
  static const double tabletMin = 720;

  /// أضيقُ عرضٍ يتّسع لعمودَين: محتوًى رئيسٌ ولوحةٌ جانبيّةٌ بعرض [sidePanel]
  /// بلا أن يضيق أحدُهما.
  static const double desktopMin = 1080;

  /// عرضُ لوحة النشاط الجانبيّة على الحاسوب (الشرفُ · اللافتات).
  static const double sidePanel = 340;

  /// أقصى عرضٍ لعمود المحتوى الرئيس. **بلا سقفٍ تصير البطاقةُ الواحدةُ شريطًا
  /// عرضُه مترٌ** على شاشة 4K — والعينُ لا تقرأ سطرًا بهذا الطول.
  static const double maxContent = 980;

  /// أقصى عرضٍ لبطاقةِ نموذجٍ (دخولٌ · تسجيلٌ · إدخالُ اسم) على الشاشات الواسعة.
  static const double maxForm = 520;

  /// أقصرُ ارتفاعٍ يقبل شريطًا جانبيًّا.
  ///
  /// **الهاتفُ المقلوبُ عرضًا فخُّ هذا الحساب**: 852×393 يتجاوز [tabletMin] عرضًا
  /// وهو هاتفٌ في يدٍ لا لوح — شريطٌ جانبيٌّ هناك يأكل ثلثَ العرض ويترك التنقّلَ
  /// بعيدًا عن الإبهام. ولا دورانَ مقفلًا في التطبيق ⇒ الحالةُ واقعةٌ لا نظريّة.
  /// 480 يفصل: أطولُ هاتفٍ مقلوبٍ دونها، وأقصرُ نافذةِ حاسوبٍ فوقها.
  static const double railMinHeight = 480;

  static AppSize of(Size window) {
    if (window.height < railMinHeight) return AppSize.phone;
    if (window.width >= desktopMin) return AppSize.desktop;
    if (window.width >= tabletMin) return AppSize.tablet;
    return AppSize.phone;
  }

  static AppSize sizeOf(BuildContext context) =>
      of(MediaQuery.sizeOf(context));

  /// هل نستبدل التنقّلَ السفليَّ بشريطٍ جانبيّ؟ (لوحٌ فما فوق)
  static bool railOf(BuildContext context) =>
      sizeOf(context) != AppSize.phone;

  /// هل تتّسع الشاشةُ للوحة النشاط الجانبيّة؟ (حاسوبٌ وحدَه)
  static bool sideOf(BuildContext context) =>
      sizeOf(context) == AppSize.desktop;

  /// عرضُ عمود المحتوى داخل [available] — يكبر بالنافذة حتى [maxContent].
  ///
  /// **ولا يترك فراغًا على الهاتف**: هناك [available] دون السقف فيُردّ كما هو
  /// (بكسلًا بكسل)، وهو شرطُ ألّا تتغيّر تجربةُ الهاتف بإضافة الحاسوب.
  static double contentWidth(double available) =>
      available < maxContent ? available : maxContent;

  /// **سهمُ الرجوع في اتّجاه اللغة.**
  ///
  /// «رجوع» في العربيّة يمضي يمينًا وفي الفرنسيّة يسارًا. أيقونةٌ مثبَّتةٌ تشير
  /// في إحدى اللغتين إلى **عكس** ما تفعل — وهو خطأٌ لا يراه من يقرأ لغةً واحدة.
  static IconData backArrow(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
          ? Icons.arrow_forward
          : Icons.arrow_back;

  /// كم بطاقةً في صفٍّ واحدٍ من شبكة الأقسام الثانويّة.
  ///
  /// الهاتفُ عمودٌ واحدٌ كما كان دائمًا؛ ومن 720 فصاعدًا عمودان — لا ثلاثةَ ولو
  /// اتّسعت الشاشة: بطاقةُ القسم صفٌّ فيه أيقونةٌ وعنوانٌ ووصف، وثلاثةٌ منها في
  /// سطرٍ تضغط الوصفَ إلى سطرين.
  static int cardColumns(AppSize size) => size == AppSize.phone ? 1 : 2;
}

/// **عمودُ نموذجٍ متمركزٌ مسقوفُ العرض** — دخولٌ · تسجيلٌ · إدخالُ اسم.
///
/// هذه الشاشاتُ حقولٌ وأزرارٌ بعرضٍ كامل (`width: double.infinity`)، وعلى نافذةِ
/// حاسوبٍ تصير الحقولُ أشرطةً بعرض مترٍ وزرًّا لا يُصدَّق أنّه زرّ. **وليس هذا
/// «عمودَ هاتفٍ في وسط شاشة»**: النموذجُ سطرٌ يُقرأ، وسقفُ عرضه عُرفُ كلّ واجهةِ
/// حاسوب. أمّا اللوبي فيأخذ النافذةَ ويوزّعها ([AppLayout]).
///
/// وعلى الهاتف: [AppLayout.maxForm] أوسعُ من أيّ هاتفٍ ⇒ **بلا أثرٍ بكسلًا واحدًا**.
class FormPane extends StatelessWidget {
  final Widget child;
  const FormPane({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.maxForm),
          child: child,
        ),
      );
}
