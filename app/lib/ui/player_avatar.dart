import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../net/api_config.dart';
import '../theme/belote_theme.dart';

/// **صورة لاعبٍ دائرية** — الصورة إن وُجدت، وإلّا [fallback] (إيموجي المقعد أو حرف).
///
/// موضعٌ واحدٌ يعرف: كيف يُركَّب الرابط النسبيّ على عنوان الخادم · ماذا يحدث حين تفشل
/// الصورة · كيف تُقصّ في الدائرة. البطاقة واللوبي والأصدقاء يستدعونه ولا يكرّرونه.
///
/// **الفشل يعود إلى [fallback] بلا ضجّة**: الصورة زينةٌ لا خبر — لاعبٌ حذف صورته،
/// أو شبكةٌ ضعيفة، أو ملفٌّ مفقود ⇒ يُعرَض ما كان يُعرَض قبل الميزة. أيقونةُ عطبٍ
/// حمراء في وجه شريكك أسوأُ من غياب صورته.
class PlayerAvatar extends StatelessWidget {
  /// الرابط **النسبيّ** من الخادم (`/avatars/…`). فارغٌ ⇒ [fallback] مباشرةً بلا شبكة.
  final String url;

  /// ما يُعرَض بلا صورة: إيموجي المقعد أو أوّل حرفٍ من الاسم.
  final String fallback;

  final double size;

  /// لون الحدّ (صاحب الدور يُبرَز بحدٍّ ذهبيّ من البطاقة الحاوية).
  final Color? borderColor;

  /// سُمك الحدّ — بطاقة الحساب تُبرزه (2) وغيرُها يكتفي بخيطٍ رفيع.
  final double borderWidth;

  const PlayerAvatar({
    super.key,
    required this.url,
    required this.fallback,
    required this.size,
    this.borderColor,
    this.borderWidth = 1.2,
  });

  /// الرابط المطلق لصورةٍ نسبيّة، أو null إن كانت فارغة. **الخادم يخزّن نسبيًّا**
  /// (النطاق يتغيّر والقاعدة تبقى) فالتركيب هنا، على عنوان الخادم المُهيّأ.
  static String? absolute(String url) =>
      url.isEmpty ? null : ApiConfig.current.http(url).toString();

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final border = borderColor ?? t.line;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.surface2,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: borderWidth),
      ),
      child: ClipOval(child: _inner(t)),
    );
  }

  Widget _inner(BeloteTheme t) {
    final src = absolute(url);
    if (src == null) return _fallbackText(t);
    return CachedNetworkImage(
      imageUrl: src,
      width: size,
      height: size,
      // **cover لا contain**: الصورة قد تأتي بأيّ نسبة (الهاتف يصغّر ولا يقصّ)،
      // وcontain يترك أشرطةً فارغةً داخل الدائرة. cover يملؤها ويقصّ الأطراف.
      fit: BoxFit.cover,
      // أثناء التحميل والفشل: ما كان يُعرَض قبل الميزة — لا دوّامةٌ ولا أيقونة عطب.
      placeholder: (_, __) => _fallbackText(t),
      errorWidget: (_, __, ___) => _fallbackText(t),
      fadeInDuration: const Duration(milliseconds: 180),
    );
  }

  /// الحرف/الإيموجي البديل. **بلونٍ ووزنٍ صريحين**: الدوائر الثلاث التي وحّدها هذا
  /// الودجت (الملفّ · الأصدقاء · اللوبي) كانت ترسم الحرف ذهبيًّا عريضًا، وتركُ النمط
  /// للافتراض يجعله رماديًّا رفيعًا — الإيموجي لا يتأثّر باللون فتمرّ البطاقة سليمةً
  /// ويبهت الحرف وحده.
  Widget _fallbackText(BeloteTheme t) => Center(
        child: Text(
          fallback,
          style: TextStyle(
            fontSize: size * 0.46,
            color: t.accentBright,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}
