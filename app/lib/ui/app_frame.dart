import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';

/// **مسرحُ اللعب** — الصندوقُ الذي تُرسَم فيه كلُّ شاشات التطبيق.
///
/// على الهاتف هو الشاشةُ نفسُها بلا زيادةٍ ولا نقصان. وعلى الحاسوب — حيث النافذةُ
/// عريضةٌ قد تبلغ 3840 بكسلًا — **لا تُمطّ الطاولةُ على العرض كلِّه**: مقاعدُ
/// الخصمين مرساهما ‎±0.99 من العرض، فنافذةٌ بعرض 2000 تضع اللاعبَين على بُعد
/// مترٍ من بعضهما وتترك الوسطَ خواءً. بدلَ ذلك يُقتطَع **مسرحٌ متمركزٌ** بنسبةٍ
/// قريبةٍ من نسبة الهاتف، ويكبر بكبر النافذة حتى سقف، وما حولَه خلفيّةُ المجلس.
///
/// **كلُّ الحساب هنا خالصٌ في [AppStage]** ⇒ يُفحَص بالأرقام بلا رسم.
class AppStage {
  /// أقصى نسبةِ عرضٍ إلى ارتفاع للمسرح. الهاتفُ ‎≈0.46، وهذا سقفٌ أوسعُ منه
  /// يستفيد من الشاشة العريضة ولا يبلغ التربيع (حيث تتباعد المقاعد).
  static const double maxAspect = 0.80;

  /// سقفُ ارتفاع المسرح. بلا سقفٍ تبتلع شاشةُ 4K المسرحَ فتصير الأوراقُ —
  /// وأحجامُها مقيّدةٌ بسقوفٍ مطلقة — نقاطًا في بحر.
  static const double maxHeight = 1180.0;

  /// حجمُ المسرح داخل نافذةٍ حجمُها [window].
  ///
  /// على الهاتف يردّ [window] نفسَه (النسبةُ أضيقُ من [maxAspect] والارتفاعُ دون
  /// السقف) ⇒ **لا فرقَ بكسلًا واحدًا عمّا كان**، وهو شرطُ ألّا تتغيّر تجربةُ
  /// الهاتف بإضافة الحاسوب.
  static Size of(Size window) {
    final h = math.min(window.height, maxHeight);
    final w = math.min(window.width, h * maxAspect);
    return Size(w, h);
  }

  /// هل يظهر إطارُ المجلس حول المسرح؟ (أي: النافذةُ أكبرُ من المسرح فعلًا)
  static bool framed(Size window) {
    final s = of(window);
    return window.width - s.width > 1 || window.height - s.height > 1;
  }
}

/// يلفّ شجرةَ التطبيق كلَّها: يقتطع [AppStage] في الوسط، ويُصلح `MediaQuery`
/// ليطابقه.
///
/// **إصلاحُ `MediaQuery` ليس تفصيلًا**: شاشاتٌ تقيس بـ`MediaQuery.sizeOf`
/// (لوحةُ النتيجة · فقاعاتُ الدردشة · الأوراقُ في الرسائل) — لو بقيت ترى عرضَ
/// النافذة لَقاست على شاشةٍ لا ترسم فيها، فتفيض فقاعةٌ عرضُها 0.75 من 2000 بكسل
/// خارجَ مسرحٍ عرضُه 800.
class AppFrame extends StatelessWidget {
  final Widget child;
  const AppFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final media = MediaQuery.of(context);
    final stage = AppStage.of(media.size);
    if (!AppStage.framed(media.size)) return child;

    return ColoredBox(
      // **خلفيّةُ المجلس حول المسرح** لا أشرطةً سوداء: العينُ تقرأ الطاولةَ
      // قائمةً في غرفةٍ معتمة، وهو نفسُ منطق حاشية غرفة VIP حول الطاولة.
      color: t.bg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.9,
            colors: [t.surface.withValues(alpha: 0.55), t.bg],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: stage.width,
            height: stage.height,
            child: ClipRect(
              child: MediaQuery(
                // المساحاتُ الآمنة (نتوءُ الكاميرا · شريطُ الإيماءات) شأنُ
                // الهاتف؛ داخل مسرحٍ متمركزٍ على الحاسوب لا معنى لها.
                data: media.copyWith(
                  size: stage,
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// **الفأرةُ تسحب كما يسحب الإصبع.**
///
/// افتراضُ Flutter على سطح المكتب: القوائمُ تُمرَّر بالعجلة وحدها، والسحبُ
/// بالفأرة **لا يمرّر شيئًا** — فمن يمسك قائمةَ الأصدقاء ويجرّها لا يحدث شيء،
/// وهو سلوكٌ يقرأ عطبًا لا اختيارًا. وسحبُ الورقة نفسُه (`onPanUpdate` في اليد)
/// يعمل بالفأرة أصلًا؛ هذا للقوائم.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.invertedStylus,
      };
}

/// **مؤشّرُ اليد على ما يُضغَط.**
///
/// على الهاتف لا مؤشّرَ أصلًا فلا أثرَ لها؛ وعلى الحاسوب هي الفرقُ بين واجهةٍ
/// تبدو حيّةً وأخرى تبدو صورة. تُلَفُّ بها الأوراقُ وأزرارُ المقعد وأدواتُ
/// الطاولة — لا كلُّ شيءٍ: مؤشّرٌ على ما لا يُضغَط يكذب.
class Clickable extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const Clickable({super.key, required this.child, this.enabled = true});

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: child,
      );
}
