import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game/view_model.dart';

/// مشغّل الأصوات القصيرة لحركة الورق. **الملف الوحيد** الذي يلمس `audioplayers`،
/// كي يبقى الكنترولر والواجهة خاليَين منه. يُوصَل في `main.dart` عبر [play]،
/// ويترجم [GameSound] إلى ملف WAV مضمّن في `assets/sfx/`.
///
/// حوض صغير من المشغّلات (round-robin) كي لا يقطع صوتٌ سابقُه عند التوزيع السريع.
/// كل شيء fire-and-forget ومحاط بحماية: فشل الصوت لا يُسقط اللعبة أبدًا.
class Sfx {
  Sfx._();
  static final Sfx instance = Sfx._();

  // خريطة الحدث → ملف. القائمة النهائيّة ٧ أصوات، كلّها من تسجيلات صاحب المشروع.
  //
  // الـ mp3 مرفوعةٌ منه جاهزةً للاستعمال. أمّا الـ wav فمقصوصةٌ من تسجيلاتٍ خامٍ طويلة
  // في `sfx_src/` (حلقةُ تكتكات · مكتبةُ محاولات · تسجيلٌ متّصلٌ خافت) — القصّ ووصفتُه
  // وأرقام المحاولات التي اختارها بأذنه كلّها في `tools/cut_sfx.py`.
  static const _assets = <GameSound, String>{
    GameSound.cardPlay: 'sfx/card_play.mp3', // 0.62ث — يُطلَق لحظةَ هبوط الورقة
    GameSound.cardCollect: 'sfx/collect_trick.mp3', // 0.50ث — مع بداية حركة الجمع
    GameSound.win: 'sfx/game_win.mp3', // 5ث — الفوز بالمباراة
    GameSound.roundEnd: 'sfx/round_win.mp3', // 3.9ث — نهاية الجولة
    GameSound.fouja: 'sfx/round_win.mp3', // نفس صوت نهاية الجولة (قرار المالك)
    GameSound.shuffle: 'sfx/shuffle.wav', // 1.3ث — مرّةً واحدة قبل التوزيع
    GameSound.deal: 'sfx/deal_card.wav', // 0.28ث — مع كلّ ورقةٍ تُوزَّع (٣٢ مرّة)
    GameSound.turnTick: 'sfx/turn_tick.wav', // 1.0ث — دورةُ تكتكةٍ كلَّ ثانيةٍ في آخر ٥ث
    // ثانويّة (لم يطلب المالك لها ملفّات — مُعارةٌ من صوت الورقة/الفوز):
    GameSound.cardFlip: 'sfx/card_play.mp3',
    GameSound.pointWin: 'sfx/game_win.mp3',
    GameSound.buttonClick: 'sfx/card_play.mp3',
    // ── الهدايا ── **مُعارةٌ مؤقّتًا** ريثما يسجّل المالكُ أربعةَ أصوات (لا يسجّل
    // غيرُه). المفاتيحُ نهائيّةٌ والملفّاتُ وحدَها تتبدّل ⇒ يومَ تصل التسجيلاتُ
    // يتغيّر هذا الجدولُ ولا سطرَ في المحرّك ولا في الكتالوج.
    GameSound.giftLaunch: 'sfx/card_play.mp3', // نقرةٌ قصيرةٌ للانطلاق
    GameSound.giftArrive: 'sfx/collect_trick.mp3', // وصولٌ خفيف
    GameSound.giftArriveEpic: 'sfx/collect_trick.mp3',
    GameSound.giftArriveLegendary: 'sfx/round_win.mp3', // حصريّةٌ ⇒ نغمةٌ كاملة
  };

  final List<AudioPlayer> _pool = [];
  int _next = 0;
  bool _ready = false;

  /// الأحداث الطويلة (نغمات الفوز/نهاية الجولة/الفوجة): وضع `lowLatency` (SoundPool على
  /// أندرويد) يبترها (~أطول من ٣ث)، فتُشغَّل عبر مشغّلٍ **مؤقّتٍ** بوضع mediaPlayer يُنشأ
  /// لكل نغمة ويُتلَف عند انتهائها — أضمن من مشغّلٍ دائمٍ قد يعلق في حالةٍ لا يعيد التشغيل.
  static const _long = <GameSound>{
    GameSound.win,
    GameSound.roundEnd,
    GameSound.fouja,
    GameSound.giftArriveLegendary, // نغمةٌ كاملةٌ (3.9ث) — `lowLatency` يبترها
  };

  /// إيقاف/تشغيل الصوت (لزرّ كتم لاحقًا). يُعطَّل تلقائيًا إن فشلت التهيئة.
  bool enabled = true;

  /// تهيئة مرة واحدة من `main`. آمنة: أي فشل يُعطّل الصوت بلا ضجيج.
  Future<void> init({int voices = 4}) async {
    if (_ready) return;
    try {
      for (var i = 0; i < voices; i++) {
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(p);
      }
      _ready = true;
    } catch (e) {
      enabled = false;
      debugPrint('Sfx.init فشل، الصوت معطّل: $e');
    }
  }

  /// يُطلق نغمة [sound]. لا ينتظر، ولا يرمي: مناسب للاستدعاء من داخل حلقة اللعب.
  void play(GameSound sound) {
    if (!enabled || !_ready) return;
    final asset = _assets[sound];
    if (asset == null) return;
    if (_long.contains(sound)) {
      _playLong(asset);
      return;
    }
    if (_pool.isEmpty) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    // fire-and-forget مع ابتلاع الأخطاء (منصّة بلا صوت، إذن مرفوض… إلخ).
    p.stop().then((_) => p.play(AssetSource(asset))).catchError((_) {});
  }

  /// نغمةٌ طويلة عبر مشغّلٍ جديدٍ (mediaPlayer) يُطلَق مرّةً ويُتلَف عند الانتهاء.
  void _playLong(String asset) {
    try {
      final p = AudioPlayer(); // الوضع الافتراضيّ mediaPlayer (بلا بتر)
      p.setReleaseMode(ReleaseMode.release);
      p.onPlayerComplete.listen((_) => p.dispose());
      p.play(AssetSource(asset)).catchError((_) => p.dispose());
    } catch (_) {/* منصّة بلا صوت… */}
  }
}
