import 'package:flutter/widgets.dart';

import 'card_art.dart';
import 'card_shell.dart';

/// ظهر الورقة — دالة تُرجِع نص SVG، تُختار بمعرّف الأسكن.
///
/// **قيد ملزِم لأي ظهر:** متماثل تمامًا عند القلب 180°، وإلا أمكن تعليم الأوراق.
/// نضمنه هنا **بالبناء**: كل عنصر زخرفي متمركز على (50,70) أو ضمن مجموعة
/// إزاحات متماثلة حول المركز. (فحص بكسليّ في الاختبار يتحقق diff==0.)
///
/// إضافة أسكن جديد = مفتاح واحد في [_skins]، بلا لمس بقية الواجهة.
typedef CardBackBuilder = String Function();

const Map<String, CardBackBuilder> _skins = {'zellij': _zellijSvg};

/// نص ظهر الورقة للأسكن المطلوب (الافتراضي zellij).
String cardBackSvg({String skin = 'zellij'}) => (_skins[skin] ?? _zellijSvg)();

/// أسماء الأسكنات المتاحة (للمتجر لاحقًا).
Iterable<String> get availableSkins => _skins.keys;

// ── ألوان زليج (رسم محض) ──
const _bg0 = '#0E3B47'; // خلفية عميقة
const _bg1 = '#0A2C36';
const _gold = '#C9A24B';
const _goldSoft = '#8A6E2E';
const _cream = '#EAD9A0';

String _zellijSvg() {
  final b = StringBuffer();

  // خلفية + لوحة داخلية
  b.write(
      '<rect x=".6" y=".6" width="98.8" height="138.8" rx="6" fill="$_bg0"/>');
  b.write(
      '<rect x="5" y="5" width="90" height="130" rx="4" fill="$_bg1" stroke="$_goldSoft" stroke-width="1"/>');
  b.write(
      '<rect x="8" y="8" width="84" height="124" rx="3" fill="none" stroke="$_gold" stroke-width=".6"/>');

  // تصفيح قطري متعامد — الإزاحات متماثلة حول 0 ⇒ الشبكة متماثلة عند 180°.
  // خط ميل +1 المركزي: y=x+20 ؛ خط ميل −1 المركزي: y=−x+120.
  for (var d = -160; d <= 160; d += 16) {
    b.write(
        '<line x1="-40" y1="${-20 + d}" x2="140" y2="${160 + d}" stroke="$_gold" stroke-width=".5" opacity=".33"/>');
    b.write(
        '<line x1="-40" y1="${160 + d}" x2="140" y2="${-20 + d}" stroke="$_gold" stroke-width=".5" opacity=".33"/>');
  }

  // معيّنات ذهبية على شبكة متمركزة (متماثلة عند 180°).
  for (final x in const [10, 30, 50, 70, 90]) {
    for (final y in const [10, 30, 50, 70, 90, 110, 130]) {
      b.write(
          '<rect x="${x - 2.4}" y="${y - 2.4}" width="4.8" height="4.8" transform="rotate(45 $x $y)" fill="$_goldSoft" opacity=".55"/>');
    }
  }

  // ميدالية مركزية: نجمة ثمانية (مربّعان متراكبان) على (50,70).
  b.write('<circle cx="50" cy="70" r="15" fill="$_bg0" stroke="$_gold" stroke-width=".8"/>');
  b.write(
      '<rect x="40" y="60" width="20" height="20" fill="none" stroke="$_cream" stroke-width="1"/>');
  b.write(
      '<rect x="40" y="60" width="20" height="20" transform="rotate(45 50 70)" fill="none" stroke="$_cream" stroke-width="1"/>');
  b.write('<circle cx="50" cy="70" r="3.2" fill="$_gold"/>');

  return '<svg viewBox="0 0 100 140" xmlns="http://www.w3.org/2000/svg">${b.toString()}</svg>';
}

/// ودجة ظهر الورقة.
class CardBack extends StatelessWidget {
  final String skin;
  const CardBack({super.key, this.skin = 'zellij'});

  @override
  Widget build(BuildContext context) {
    final picture = CardArt.of('B:$skin');
    return AspectRatio(
      aspectRatio: CardArt.viewBox.aspectRatio,
      child: picture == null
          ? const SizedBox.shrink()
          // نفسُ غلافِ الوجه ([CardShell]): حوافُّ وظلٌّ ولمعة. الزخرفةُ الذهبيّة
          // كانت تُرسَم مسطّحةً حادّةَ الزوايا فتبدو مطبوعةً على اللبّاد.
          : CardShell(child: CustomPaint(painter: CardArtPainter(picture))),
    );
  }
}
