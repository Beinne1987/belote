/// **سِجلُّ الهدايا البصريّ** — العقدُ بين *ما هي الهديّة* و*كيف تطير*.
///
/// هذا الملفُّ **بيانٌ لا منطق**. محرّكُ الحركة (`gift_flight_layer.dart`) لا يعرف
/// وردةً من سيّارة: يقرأ [GiftVisuals] ويرسم. ⇒ **إضافةُ هديّةٍ جديدةٍ سطرٌ هنا
/// ولا سطرَ هناك**، وهذا شرطُ المالك الصريح (2026-07-19).
///
/// وكلُّ هديّةٍ تُعرّف **نفسَها فقط**: أصلَها ([art]) وندرتَها ([rarity]) وحجمَها
/// ([scale]) وصوتَها وأثرَها. أمّا *كيف* تُرسَم القوسُ والذيلُ والانفجار فمشتركٌ
/// للجميع — يأتي من [GiftRarity] الافتراضيّ، ولا يُكرَّر في كلّ صفّ.
///
/// **الطبقاتُ الثلاث** (الأخصُّ يغلب):
///   1. `_overrides` — ما تفرّدت به هديّةٌ بعينها.
///   2. افتراضُ ندرتِها — القوسُ والسرعةُ والجُسيمات والصوت.
///   3. [_unknownFallback] — **هديّةٌ من خادمٍ أحدثَ من هذا التطبيق**: تطير بأثرٍ
///      محترمٍ بدل أن تختفي. بلا هذه الطبقة يصير كلُّ إثراءٍ للكتالوج تحديثَ حزمة
///      ([[ws-event-forward-compat]]).
library;

import 'package:flutter/widgets.dart';

import '../../game/view_model.dart';
import '../gift_picker.dart';

/// درجةُ الهديّة. **الندرةُ تُحدَّد بالثمن** لا بيدٍ (انظر [_rarityForPrice]): كتالوجُ
/// الخادم هو المرجع، ولو كُتبت يدويًّا لَتناقض السعرُ والمظهرُ عند أوّل تعديلِ ثمن.
enum GiftRarity { common, rare, epic, legendary }

// ── الأصل الفنّيّ ─────────────────────────────────────────────────────────────

/// ما يُرسَم وهو يطير: إيموجي أو صورة. مغلقٌ (`sealed`) كي يُجبر المحرّكُ على
/// معالجة كلّ نوعٍ يُضاف — نوعٌ جديدٌ (Lottie مثلًا) يكسر البناءَ لا العرض.
sealed class GiftArt {
  const GiftArt();
}

/// إيموجي — **بلا وزنٍ في الحزمة وبلا تنزيل** (نفس منطق كتالوج الخادم).
class GiftEmoji extends GiftArt {
  final String emoji;
  const GiftEmoji(this.emoji);
}

/// صورةٌ من `assets/` — للحصريّات (VIP) وما يأتي من رسّامٍ لاحقًا.
class GiftImage extends GiftArt {
  final String asset;
  const GiftImage(this.asset);
}

// ── وصفةُ الأثر ───────────────────────────────────────────────────────────────

/// **وصفةُ الحركة والأثر.** أرقامٌ خالصة: لا ودجت ولا رسمَ هنا — المحرّكُ يستهلكها.
@immutable
class GiftFx {
  /// زمنُ العبور من مقعدٍ إلى مقعد. الأندرُ **أبطأ**: البطءُ يُشعر بالثقل، والسرعةُ
  /// تُشعر بالرخص.
  final Duration travel;

  /// ارتفاعُ القوس نسبةً إلى المسافة بين المقعدين. صفرٌ ⇒ خطٌّ مستقيم (لا نستعمله).
  final double arc;

  /// دوراتٌ كاملةٌ حول نفسها أثناء الطيران. صفرٌ ⇒ تميل مع اتّجاه الحركة فقط.
  final double spin;

  /// عددُ جُسيمات الذيل، وعددُ شظايا الوصول.
  final int trail;
  final int burst;

  /// لونُ الهالة والذيل. الوصولُ يستعمل [glow] نفسَه فتبقى الهديّةُ «شخصيّةً» واحدة.
  final Color glow;

  /// طمسُ الحركة (motion blur). **مُطفأٌ للشائع** عمدًا: `ImageFilter.blur` أغلى ما
  /// في الإطار، ولا يُشترى إلّا حيث يُرى — والوردةُ تمرّ سريعًا فلا يلحظه أحد.
  final bool motionBlur;

  /// حلقةُ صدمةٍ تتمدّد عند الوصول (للأندر وحده — وإلّا صارت ضوضاءَ بصريّة).
  final bool shockRing;

  const GiftFx({
    required this.travel,
    required this.arc,
    required this.spin,
    required this.trail,
    required this.burst,
    required this.glow,
    required this.motionBlur,
    required this.shockRing,
  });

  /// نسخةٌ معدَّلة — بها تُفرِّد هديّةٌ واحدةٌ نفسَها بلا إعادة كتابة الوصفة كاملة.
  GiftFx copyWith({
    Duration? travel,
    double? arc,
    double? spin,
    int? trail,
    int? burst,
    Color? glow,
    bool? motionBlur,
    bool? shockRing,
  }) =>
      GiftFx(
        travel: travel ?? this.travel,
        arc: arc ?? this.arc,
        spin: spin ?? this.spin,
        trail: trail ?? this.trail,
        burst: burst ?? this.burst,
        glow: glow ?? this.glow,
        motionBlur: motionBlur ?? this.motionBlur,
        shockRing: shockRing ?? this.shockRing,
      );
}

/// كلُّ ما يحتاجه المحرّكُ ليطيّر هديّةً — **العقدُ الوحيد** بينه وبين الكتالوج.
@immutable
class GiftVisuals {
  final String id;
  final GiftArt art;
  final GiftRarity rarity;

  /// حجمٌ نسبيٌّ فوق حجم الأساس (1.0). الأندرُ أكبر: الحضورُ جزءٌ من الثمن.
  final double scale;

  final GiftFx fx;
  final GameSound launchSound;
  final GameSound arriveSound;

  const GiftVisuals({
    required this.id,
    required this.art,
    required this.rarity,
    required this.scale,
    required this.fx,
    required this.launchSound,
    required this.arriveSound,
  });
}

// ── الافتراضاتُ بالندرة ───────────────────────────────────────────────────────

/// وصفةُ كلِّ درجة. **هنا تُضبط الروحُ العامّة** — تعديلُ سطرٍ هنا يغيّر كلَّ هدايا
/// الدرجة دفعةً واحدة، وهذا هو المقصود من «إطارٍ مشترك».
const _fxByRarity = <GiftRarity, GiftFx>{
  GiftRarity.common: GiftFx(
    travel: Duration(milliseconds: 760),
    arc: 0.30,
    spin: 0,
    trail: 10,
    burst: 8,
    glow: Color(0xFF8FE3C0),
    motionBlur: false,
    shockRing: false,
  ),
  GiftRarity.rare: GiftFx(
    travel: Duration(milliseconds: 920),
    arc: 0.36,
    spin: 0,
    trail: 15,
    burst: 14,
    glow: Color(0xFF7FC4FF),
    motionBlur: true,
    shockRing: false,
  ),
  GiftRarity.epic: GiftFx(
    travel: Duration(milliseconds: 1180),
    arc: 0.44,
    spin: 1,
    trail: 21,
    burst: 22,
    glow: Color(0xFFC79BFF),
    motionBlur: true,
    shockRing: true,
  ),
  GiftRarity.legendary: GiftFx(
    travel: Duration(milliseconds: 1450),
    arc: 0.52,
    spin: 1.5,
    trail: 27,
    burst: 30,
    glow: Color(0xFFFFD277),
    motionBlur: true,
    shockRing: true,
  ),
};

/// حجمُ الأساس بالندرة.
const _scaleByRarity = <GiftRarity, double>{
  GiftRarity.common: 1.0,
  GiftRarity.rare: 1.15,
  GiftRarity.epic: 1.32,
  GiftRarity.legendary: 1.5,
};

/// صوتُ الوصول بالندرة. الإطلاقُ واحدٌ للجميع (نقرةٌ خفيفة) — **الوصولُ هو الحدث**.
///
/// ⚠ الملفّاتُ الآن **مُعارةٌ** من السبعة المسجَّلة (انظر `sfx.dart`): لا يسجّل
/// الأصواتَ إلّا المالك ([[audio-sync-plan]]). النغماتُ مربوطةٌ بالاسم لا بالملفّ،
/// فيوم يصل تسجيلٌ خاصٌّ للهدايا يتغيّر سطرٌ في `Sfx._assets` ولا شيءَ هنا.
const _arriveSoundByRarity = <GiftRarity, GameSound>{
  GiftRarity.common: GameSound.giftArrive,
  GiftRarity.rare: GameSound.giftArrive,
  GiftRarity.epic: GameSound.giftArriveEpic,
  GiftRarity.legendary: GameSound.giftArriveLegendary,
};

// ── التفريدُ لهديّةٍ بعينها ───────────────────────────────────────────────────

/// ما تفرّدت به هديّةٌ واحدةٌ عن درجتها. **اتركه فارغًا ما لم يكن للتفرّد معنى** —
/// كثرةُ الاستثناءات تُعيد المنطقَ الذي أخرجناه.
final _overrides = <String, GiftFx Function(GiftFx base)>{
  // الوردةُ تتهادى: قوسٌ أعلى ودورانٌ بطيءٌ كورقةٍ تسقط.
  'rose': (b) => b.copyWith(arc: 0.40, spin: 0.5, glow: const Color(0xFFFF8FB1)),
  // الأتاي ثقيلٌ يُسكب: قوسٌ منخفضٌ وذيلٌ دافئ.
  'tea': (b) => b.copyWith(arc: 0.24, glow: const Color(0xFFE0B072)),
  'sweet': (b) => b.copyWith(glow: const Color(0xFFFF9ED8)),
  // التاجُ ذهبٌ وإن كان درجةً أدنى من الأسطوريّ — اللونُ هويّةٌ لا درجة.
  'crown': (b) => b.copyWith(glow: const Color(0xFFFFD277), shockRing: true),
  // الجملُ لا يدور (مضحكٌ لو دار) — يمشي في قوسٍ واسعٍ متمهّل.
  'camel': (b) => b.copyWith(spin: 0, arc: 0.50, glow: const Color(0xFFE8C79A)),
  // السيّارةُ تنطلق: قوسٌ منخفضٌ وسرعةٌ وطمسٌ — أفقيّةٌ لا متهادية.
  'car': (b) => b.copyWith(
      spin: 0,
      arc: 0.22,
      travel: const Duration(milliseconds: 900),
      glow: const Color(0xFF8FD8FF)),
};

// ── الحلّ ─────────────────────────────────────────────────────────────────────

/// الندرةُ من الثمن. الحدودُ مضبوطةٌ على كتالوجٍ ثمنُه 5..200، وتبقى صحيحةً لما
/// يُضاف: هديّةٌ بـ400 تصير أسطوريّةً بلا لمس هذا الملفّ.
GiftRarity _rarityForPrice(int price) {
  if (price >= 100) return GiftRarity.epic;
  if (price >= 20) return GiftRarity.rare;
  return GiftRarity.common;
}

/// هديّةٌ لا نعرف معرّفها — **خادمٌ أحدثُ من الحزمة**. تطير كنادرةٍ برمزِ هديّةٍ
/// عامّ: تُرى ولا تكذب على أحدٍ بندرةٍ لا تعرفها.
GiftVisuals _unknownFallback(String id) => GiftVisuals(
      id: id,
      art: const GiftEmoji('🎁'),
      rarity: GiftRarity.rare,
      scale: _scaleByRarity[GiftRarity.rare]!,
      fx: _fxByRarity[GiftRarity.rare]!,
      launchSound: GameSound.giftLaunch,
      arriveSound: _arriveSoundByRarity[GiftRarity.rare]!,
    );

/// ذاكرةٌ صغيرة: الحلُّ يقع مرّةً لكلّ معرّف. الرحلةُ تُبنى في `notifyListeners`
/// وسط اللعب، فلا نُعيد المرورَ على الكتالوجَين في كلّ مرّة.
final _cache = <String, GiftVisuals>{};

/// **المدخلُ الوحيد للمحرّك**: وصفةُ الهديّة [id] كاملةً، أيًّا كان مصدرُها.
GiftVisuals giftVisualsFor(String id) => _cache.putIfAbsent(id, () {
      // ١) حصريّاتُ VIP — أصلٌ فنّيٌّ وأسطوريّةٌ دائمًا: هي أغلى ما يُهدى.
      final vipAsset = vipGiftAsset(id);
      if (vipAsset != null) {
        const r = GiftRarity.legendary;
        final base = _fxByRarity[r]!;
        return GiftVisuals(
          id: id,
          art: GiftImage(vipAsset),
          rarity: r,
          scale: _scaleByRarity[r]!,
          fx: _overrides[id]?.call(base) ?? base,
          launchSound: GameSound.giftLaunch,
          arriveSound: _arriveSoundByRarity[r]!,
        );
      }

      // ٢) الكتالوج العاديّ — الندرةُ من الثمن.
      for (final g in giftCatalogUi) {
        if (g.id != id) continue;
        final r = _rarityForPrice(g.price);
        final base = _fxByRarity[r]!;
        return GiftVisuals(
          id: id,
          art: GiftEmoji(g.emoji),
          rarity: r,
          scale: _scaleByRarity[r]!,
          fx: _overrides[id]?.call(base) ?? base,
          launchSound: GameSound.giftLaunch,
          arriveSound: _arriveSoundByRarity[r]!,
        );
      }

      // ٣) لا نعرفها.
      return _unknownFallback(id);
    });
