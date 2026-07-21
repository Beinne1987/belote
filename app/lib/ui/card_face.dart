import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/widgets.dart';

import 'card_art.dart';
import 'card_back.dart';
import 'card_shell.dart';

/// وجه الورقة — نقلٌ حرفي لرسم `reference/src/cards.js` (النمط الإنجليزي)،
/// **بلا عنصر `<text>`**: flutter_svg يرسمه صندوقًا ممتلئًا لا حروفًا (تحقّقنا).
/// الرتبة في الزوايا تُرسَم كنص Flutter فوق الـ SVG — وهذا أيضًا يضمن
/// الأرقام **لاتينية** (7 8 9 10) لا هندية.
///
/// الألوان هنا رسمٌ محض، ليست قاعدة.
const _ja = '#E8B923',
    _bl = '#1F4E9C',
    _ro = '#C8102E',
    _nr = '#16161D',
    _wh = '#FFF',
    _pa = '#F7F3E8';

/// الألوان الحمراء (لِحبر الزاوية والرتبة). قرار بصري لا قاعدة.
const _redSuits = {'coeur', 'carreau'};
const Color _inkRed = Color(0xFFC8102E);
const Color _inkBlack = Color(0xFF16161D);

const num _mi = 70; // MI في المرجع: عتبة القلب للنقوش السفلية

/// شكل رمز اللون (ens في المرجع).
String _ens(String c) => const {
      'pique':
          '<path d="M50 8C50 8 14 40 14 62c0 14 11 22 22 22 6 0 11-3 14-8-2 8-7 14-16 18h32c-9-4-14-10-16-18 3 5 8 8 14 8 11 0 22-8 22-22C86 40 50 8 50 8Z"/>',
      'coeur':
          '<path d="M50 92C14 62 8 42 8 32 8 16 20 8 32 8c9 0 15 5 18 12 3-7 9-12 18-12 12 0 24 8 24 24 0 10-6 30-42 60Z"/>',
      'carreau': '<path d="M50 4 90 50 50 96 10 50Z"/>',
      'trefle':
          '<circle cx="50" cy="30" r="19"/><circle cx="27" cy="62" r="19"/><circle cx="73" cy="62" r="19"/><path d="M44 60c0 16-4 26-11 32h34c-7-6-11-16-11-32Z"/>',
    }[c]!;

/// رمز لون مُصغَّر ومُترجَم إلى (x,y) بمقياس tt/100، مع قلب اختياري.
String _pip(String c, num x, num y, num tt, String fill, bool rot) {
  final s = tt / 100;
  final r = rot ? 'rotate(180 $x $y) ' : '';
  return '<g transform="${r}translate($x $y) scale($s) translate(-50 -50)" fill="$fill">${_ens(c)}</g>';
}

const _gx = 33, _cx = 50, _dx = 67;
const Map<String, List<List<num>>> _poses = {
  '7': [
    [_gx, 36], [_dx, 36], [_cx, 53], [_gx, _mi], [_dx, _mi], [_gx, 104], [_dx, 104], //
  ],
  '8': [
    [_gx, 36], [_dx, 36], [_cx, 53], [_gx, _mi], [_dx, _mi], [_cx, 87], [_gx, 104], [_dx, 104], //
  ],
  '9': [
    [_gx, 36], [_dx, 36], [_gx, 58], [_dx, 58], [_cx, _mi], [_gx, 82], [_dx, 82], [_gx, 104], [_dx, 104], //
  ],
  '10': [
    [_gx, 36], [_dx, 36], [_cx, 47], [_gx, 58], [_dx, 58], [_gx, 82], [_dx, 82], [_cx, 93], [_gx, 104], [_dx, 104], //
  ],
};

/// صورة الوجه (J·Q·K) — نقلٌ حرفي لـ buste في المرجع.
String _buste(String rank, String suit, String robe, String ink) {
  var coif = '', barbe = '', att = '', chev = '';
  if (rank == 'K') {
    coif =
        '<path d="M38 34 L40 23 L45 30 L50 21 L55 30 L60 23 L62 34 Z" fill="$_ja" stroke="$_nr" stroke-width=".8" stroke-linejoin="round"/><rect x="37.6" y="33.5" width="24.8" height="4" rx="1" fill="$_ja" stroke="$_nr" stroke-width=".8"/>';
    chev =
        '<path d="M39.5 44 C38 38 40 36 43 36 L57 36 C60 36 62 38 60.5 44 Z" fill="$_ja" stroke="$_nr" stroke-width=".7"/>';
    barbe =
        '<path d="M42.5 47 C43 58 57 58 57.5 47 C55 52 45 52 42.5 47 Z" fill="$_wh" stroke="$_nr" stroke-width=".8"/>';
    att =
        '<line x1="71" y1="70" x2="69" y2="26" stroke="$_nr" stroke-width="1.3"/><line x1="64.5" y1="41" x2="73.5" y2="40.6" stroke="$_ja" stroke-width="2.2" stroke-linecap="round"/>';
  } else if (rank == 'Q') {
    coif =
        '<path d="M40 34 L41.5 26 L45.5 32 L50 24 L54.5 32 L58.5 26 L60 34 Z" fill="$_ja" stroke="$_nr" stroke-width=".8" stroke-linejoin="round"/><rect x="39.6" y="33.5" width="20.8" height="3.6" rx="1" fill="$_ja" stroke="$_nr" stroke-width=".8"/>';
    chev =
        '<path d="M40 44 C38.5 38 41 36.5 44 36.5 L56 36.5 C59 36.5 61.5 38 60 44 Z" fill="$_ja" stroke="$_nr" stroke-width=".7"/><path d="M40 46 C37 51 37.5 56 39.5 59" fill="none" stroke="$_ja" stroke-width="2.2" stroke-linecap="round"/><path d="M60 46 C63 51 62.5 56 60.5 59" fill="none" stroke="$_ja" stroke-width="2.2" stroke-linecap="round"/>';
    att =
        '<line x1="29" y1="70" x2="30.5" y2="47" stroke="#2E7D4F" stroke-width="1.2"/><circle cx="31" cy="43" r="3.4" fill="$_ja" stroke="$_nr" stroke-width=".7"/><circle cx="27.6" cy="41" r="2.3" fill="$_ro" stroke="$_nr" stroke-width=".6"/><circle cx="34.4" cy="41" r="2.3" fill="$_ro" stroke="$_nr" stroke-width=".6"/><circle cx="31" cy="38" r="2.3" fill="$_ro" stroke="$_nr" stroke-width=".6"/>';
  } else {
    coif =
        '<path d="M39 37 C39 28 61 28 61 37 Z" fill="$robe" stroke="$_nr" stroke-width=".8"/><rect x="38.6" y="36" width="22.8" height="3.2" rx="1" fill="$_ja" stroke="$_nr" stroke-width=".7"/><path d="M61 35 C68 30 70 23 67 20.5 C62.5 25.5 61 30.5 61 35 Z" fill="$_ro" stroke="$_nr" stroke-width=".7"/>';
    chev =
        '<path d="M40 45 C38.5 52 40 57 42 59" fill="none" stroke="$_ja" stroke-width="2.2" stroke-linecap="round"/><path d="M60 45 C61.5 52 60 57 58 59" fill="none" stroke="$_ja" stroke-width="2.2" stroke-linecap="round"/>';
    att =
        '<line x1="71" y1="70" x2="71" y2="30" stroke="$_ja" stroke-width="1.4"/><path d="M71 30 L77 36.5 L71 40.5 Z" fill="$_nr"/>';
  }
  return '<g>'
      '<path d="M50 54 C37 54 24 61 21.5 70 L78.5 70 C76 61 63 54 50 54 Z" fill="$robe" stroke="$_nr" stroke-width=".9"/>'
      '<path d="M24 70 L62 55.6 L67.5 59.2 L32 70 Z" fill="$_nr"/>'
      '<path d="M23.5 70 C25 64 28.5 60 33 57.8 L37.5 70 Z" fill="$_ja" stroke="$_nr" stroke-width=".7"/>'
      '<path d="M76.5 70 C75 64 71.5 60 67 57.8 L62.5 70 Z" fill="$_ja" stroke="$_nr" stroke-width=".7"/>'
      '<path d="M43 55.4 L50 62.5 L57 55.4 Z" fill="$_wh" stroke="$_nr" stroke-width=".7"/>'
      '<rect x="46.6" y="48.5" width="6.8" height="7.5" fill="$_wh" stroke="$_nr" stroke-width=".7"/>'
      '<circle cx="50" cy="43" r="8.6" fill="$_wh" stroke="$_nr" stroke-width=".9"/>'
      '<circle cx="46.7" cy="42" r=".95" fill="$_nr"/><circle cx="53.3" cy="42" r=".95" fill="$_nr"/>'
      '$barbe$chev$coif$att${_pip(suit, 28.5, 31, 11, ink, false)}'
      '</g>';
}

/// نص وجه الورقة الكامل (بلا رتبة نصّية — تُرسَم كـ Flutter Text في [CardFace]).
String cardFaceSvg(Card c) {
  final ink = _redSuits.contains(c.suit) ? _ro : _nr;
  final robe = (c.suit == 'pique' || c.suit == 'carreau') ? _bl : _ro;

  // الزاوية: نُبقي رمز اللون فقط (الرتبة نص Flutter).
  String coin(bool f) {
    final open = f ? '<g transform="rotate(180 50 70)">' : '<g>';
    return '$open${_pip(c.suit, 11, 30, 11, ink, false)}</g>';
  }

  String body;
  if (c.rank == 'J' || c.rank == 'Q' || c.rank == 'K') {
    body =
        '<rect x="17" y="21" width="66" height="98" rx="2" fill="none" stroke="$_bl" stroke-width=".9"/>'
        '${_buste(c.rank, c.suit, robe, ink)}'
        '<g transform="rotate(180 50 70)">${_buste(c.rank, c.suit, robe, ink)}</g>';
  } else if (c.rank == 'A') {
    body = '${_pip(c.suit, 50, 70, 48, ink, false)}'
        '<g opacity=".85"><circle cx="50" cy="64" r="9.5" fill="none" stroke="$_pa" stroke-width="1.6"/>${_pip(c.suit, 50, 64, 8, _pa, false)}</g>';
  } else {
    body = _poses[c.rank]!
        .map((p) => _pip(c.suit, p[0], p[1], 19, ink, p[1] > _mi))
        .join();
  }

  // **أبيضُ ناصعٌ** (لمسةُ الديمو التي اختارها المالك) بدل الكريميّ القديم، بحدٍّ
  // رماديٍّ رفيع. الرسومُ (الملوك · الآص · النقوش) تبقى كما هي فوقه.
  return '<svg viewBox="0 0 100 140" xmlns="http://www.w3.org/2000/svg">'
      '<rect x=".6" y=".6" width="98.8" height="138.8" rx="6" fill="#FFFFFF" stroke="#E6E6EC" stroke-width="1.2"/>'
      '${coin(false)}${coin(true)}$body</svg>';
}

/// يُحمّل رسوم الـ٣٢ ورقة + الظهر إلى الذاكرة المؤقتة. يُستدعى مرة عند الإقلاع.
Future<void> preloadCardArt() async {
  for (final c in buildDeck()) {
    await CardArt.load('F:${c.code}', cardFaceSvg(c));
  }
  await CardArt.load('B:zellij', cardBackSvg());
}

/// ودجة وجه الورقة: رسم SVG مخزَّن + رتبتان في الزاويتين (نص Flutter لاتيني).
class CardFace extends StatelessWidget {
  final Card card;
  const CardFace({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final picture = CardArt.of('F:${card.code}');
    final ink = _redSuits.contains(card.suit) ? _inkRed : _inkBlack;

    return AspectRatio(
      aspectRatio: CardArt.viewBox.aspectRatio,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          final two = card.rank.length > 1;
          // sz المرجعي: 16 لحرف واحد، 13 لاثنين (من cards.js) على ارتفاع 140.
          final fs = h * (two ? 13 : 16) / 140;
          Widget rank() => Text(
                card.rank,
                textDirection: TextDirection.ltr, // أرقام لاتينية دائمًا
                style: TextStyle(
                  fontSize: fs,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              );
          // **الغلافُ المشترك** ([CardShell]): الحوافُّ والظلُّ واللمعة — نفسُها
          // للظهر، فلا تبدو يدُك محمولةً وأيدي الخصوم مطبوعةً على اللبّاد.
          return CardShell(
            child: Stack(
              children: [
                if (picture != null)
                  Positioned.fill(
                      child: CustomPaint(painter: CardArtPainter(picture))),
                // الزاوية العليا (المرجع: x≈11, baseline≈19)
                Positioned(left: w * 0.055, top: h * 0.012, child: rank()),
                // الزاوية السفلى، مقلوبة 180°
                Positioned(
                  right: w * 0.055,
                  bottom: h * 0.012,
                  child: RotatedBox(quarterTurns: 2, child: rank()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
