import 'package:flutter/widgets.dart';

/// **غلافُ الورقة** — الحوافُّ المدوّرةُ والظلُّ واللمعةُ العلويّة، في مكانٍ واحد.
///
/// يلبسه الوجهُ ([CardFace]) والظهرُ ([CardBack]) معًا. قبلَه كان الوجهُ وحدَه
/// مدوّرًا ومُظلَّلًا والظهرُ مسطّحًا حادَّ الزوايا ⇒ يدُك تبدو محمولةً وأيدي
/// الخصوم مطبوعةً على اللبّاد. غلافٌ واحدٌ يعني أنّ أيَّ تعديلٍ لاحقٍ على إحساس
/// الورقة يمسّ الاثنين، فلا ينحرف أحدهما عن الآخر.
///
/// **اللمعةُ من فوق** — نفسُ اتّجاهِ ضوءِ الطاولة (`TableConfig.lightSource`):
/// الورقةُ تعكس ضوءَ الغرفةِ لا ضوءًا خاصًّا بها. وهي **واحدةٌ لكلّ الأوراق**
/// (لا تعتمد الرتبةَ ولا اللون) ⇒ لا تُعلَّم بها ورقة، والظهرُ يبقى بريئًا.
class CardShell extends StatelessWidget {
  /// المحتوى: رسمُ الوجه أو الظهر (وما فوقَه من رتبٍ في الزوايا).
  final Widget child;

  const CardShell({super.key, required this.child});

  /// نصفُ قطرِ الزاوية لعرضِ ورقةٍ [w] — يشاركه القاصُّ والظلّ.
  static BorderRadius radiusFor(double w) => BorderRadius.circular(w * 0.055);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final radius = radiusFor(w);
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: const Color(0x33000000),
              blurRadius: w * 0.11,
              offset: Offset(0, w * 0.045),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child,
              // لمعةٌ علويّةٌ خفيفةٌ + قتامٌ أخفُّ عند القاعدة: تُجلس الورقةَ في
              // الضوء بدل ورقٍ مسطّح. `IgnorePointer` كي لا تبتلع لمسةَ اللعب.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x24FFFFFF),
                          Color(0x00FFFFFF),
                          Color(0x0D000000),
                        ],
                        stops: [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
