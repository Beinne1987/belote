import 'package:flutter/material.dart';

import 'interactive_hand_fan.dart';
import 'premium_table.dart';
import '../../ui/table/table_config.dart';

/// **شاشةُ العرض** — تعرض **طاولتين في صفحةٍ واحدة** للمقارنة:
/// 1. **طاولةُ VIP** الأفخم فوق خلفيّة غرفة VIP الحاليّة (`assets/VIP/room_game_table.jpg`).
/// 2. **الطاولةُ الكلاسيكيّة** بلبّادِ علمِ موريتانيا، مع لوحةِ تحكّمٍ حيّةٍ تضبطها.
///
/// الهدف: الحكمُ على الأجمل قبل أيّ دمج. لا شيءَ من هذا في الإنتاج.
class TableDemoScreen extends StatefulWidget {
  const TableDemoScreen({super.key});

  @override
  State<TableDemoScreen> createState() => _TableDemoScreenState();
}

class _TableDemoScreenState extends State<TableDemoScreen> {
  // الكلاسيكيّةُ قابلةٌ للضبط؛ VIP عرضٌ نهائيٌّ ثابت.
  TableConfig _cfg = TableConfig.walnutEmerald;
  final _classic = PremiumTableController();
  final _vip = PremiumTableController();
  final _classicHand = HandFanController();
  final _vipHand = HandFanController();
  final _fan = HandFanController();
  String? _lastPlayed;

  void _set(TableConfig c) => setState(() => _cfg = c);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E12),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth > 900;
          final vipCard = _tableCard(
            title: 'طاولة VIP — الأفخم',
            subtitle: 'يدُك التفاعليّةُ على الطاولة · اسحب ورقةً لِلعبها',
            config: TableConfig.vipRoyale,
            controller: _vip,
            handController: _vipHand,
            vipBackground: true,
          );
          final classicCard = _tableCard(
            title: 'الطاولة الكلاسيكيّة — لبّاد علم موريتانيا',
            subtitle: 'يدُك التفاعليّةُ على الطاولة · اضبطها من اللوحة أسفلُ',
            config: _cfg,
            controller: _classic,
            handController: _classicHand,
            vipBackground: false,
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _Header(),
              const SizedBox(height: 14),
              _fanSection(),
              const SizedBox(height: 24),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: vipCard),
                      const SizedBox(width: 16),
                      Expanded(child: classicCard),
                    ],
                  ),
                )
              else ...[
                vipCard,
                const SizedBox(height: 24),
                classicCard,
              ],
              const SizedBox(height: 24),
              _panelHeader(),
              _panel(),
            ],
          );
        }),
      ),
    );
  }

  // ── مروحةُ اليد الاحترافيّة (تفاعليّة) ────────────────────────────────
  Widget _fanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('مروحة اليد الاحترافيّة — تفاعليّة (٨ أوراق)',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        const Text(
            'مرّر فوق ورقةٍ أو المسها فترتفع · اسحب ورقةً للأعلى فتُلعَب · «توزيع» يعيد اليد',
            style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 0.6),
                radius: 1.1,
                colors: [Color(0xFF15533D), Color(0xFF08241B)],
              ),
            ),
            child: AspectRatio(
              aspectRatio: 2.7, // شريطٌ أفقيٌّ كوضع الهاتف landscape
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: InteractiveHandFan(
                  controller: _fan,
                  onPlay: (label) =>
                      setState(() => _lastPlayed = label),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _action('توزيع', Icons.style, _fan.deal),
            const SizedBox(width: 12),
            if (_lastPlayed != null)
              Text('لُعبت: $_lastPlayed',
                  style: const TextStyle(
                      color: Color(0xFFD9B45B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  // ── بطاقةُ طاولةٍ (معاينة + أزرارُ حركة) ──────────────────────────────
  Widget _tableCard({
    required String title,
    required String subtitle,
    required TableConfig config,
    required PremiumTableController controller,
    required HandFanController handController,
    required bool vipBackground,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0D11),
              image: vipBackground
                  ? const DecorationImage(
                      image: AssetImage('assets/VIP/room_game_table.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Color(0x59000000), BlendMode.darken),
                    )
                  : null,
              border: Border.all(
                  color: vipBackground
                      ? const Color(0xFFD9B45B).withValues(alpha: 0.5)
                      : Colors.white12),
            ),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: PremiumTable(
                  config: config,
                  controller: controller,
                  interactiveBottomHand: true,
                  handController: handController,
                  onPlayCard: (label) =>
                      setState(() => _lastPlayed = label),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _action('توزيع', Icons.style, () {
              controller.deal();
              handController.deal(); // يدُ اللاعب توزّع أيضًا
            }),
            _action('انزلاق ورقة', Icons.swipe_up, controller.slide),
            _action('هديّة', Icons.card_giftcard, () => controller.gift()),
          ],
        ),
      ],
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap) =>
      FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD9B45B),
          foregroundColor: const Color(0xFF1A1200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13)),
      );

  Widget _panelHeader() => const Row(
        children: [
          Icon(Icons.tune, color: Color(0xFFD9B45B), size: 18),
          SizedBox(width: 6),
          Text('ضبطُ الطاولة الكلاسيكيّة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
        ],
      );

  // ── لوحة التحكّم (تضبط الكلاسيكيّة) ───────────────────────────────────
  Widget _panel() => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF12161C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            _section('أطُرٌ جاهزة'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _preset('جوز · علم', TableConfig.walnutEmerald),
                _preset('ماهوجني · ياقوت', TableConfig.mahoganyRuby),
                _preset('آبنوس · أزرق', TableConfig.ebonySapphire),
                _preset('سنديان · ليل', TableConfig.oakMidnight),
              ],
            ),
            _section('الخشب'),
            _swatches('لون الإطار', const [
              Color(0xFF5A3620),
              Color(0xFF6B2A20),
              Color(0xFF2A2620),
              Color(0xFF7A5A32),
              Color(0xFF241309),
            ], _cfg.woodColor, (c) => _set(_cfg.copyWith(woodColor: c))),
            _slider('لمعان الخشب', _cfg.woodGloss, 0, 1,
                (v) => _set(_cfg.copyWith(woodGloss: v))),
            _slider('سُمك الإطار', _cfg.railThickness, 0.04, 0.16,
                (v) => _set(_cfg.copyWith(railThickness: v))),
            _section('اللبّاد'),
            _toggle(
                'علم موريتانيا على اللبّاد',
                _cfg.feltStyle == FeltStyle.mauritaniaFlag,
                (v) => _set(_cfg.copyWith(
                    feltStyle:
                        v ? FeltStyle.mauritaniaFlag : FeltStyle.plain))),
            _swatches('قلب اللبّاد', const [
              Color(0xFF1B6B4A),
              Color(0xFF7A1F2B),
              Color(0xFF1E4E7A),
              Color(0xFF243244),
              Color(0xFF4A2A6B),
            ], _cfg.feltCenter, (c) => _set(_cfg.copyWith(feltCenter: c))),
            _swatches('حافّة اللبّاد', const [
              Color(0xFF0A2E20),
              Color(0xFF2E0A10),
              Color(0xFF081A2E),
              Color(0xFF0C1119),
              Color(0xFF1E0E2E),
            ], _cfg.feltEdge, (c) => _set(_cfg.copyWith(feltEdge: c))),
            _slider('عمق الحوض', _cfg.feltVignette, 0, 1,
                (v) => _set(_cfg.copyWith(feltVignette: v))),
            _section('الإضاءة'),
            _slider('شدّة الضوء', _cfg.ambientLight, 0, 1,
                (v) => _set(_cfg.copyWith(ambientLight: v))),
            _slider('مصدر الضوء ↔', _cfg.lightSource.x, -1, 1,
                (v) => _set(_cfg.copyWith(
                    lightSource: Alignment(v, _cfg.lightSource.y)))),
            _slider('مصدر الضوء ↕', _cfg.lightSource.y, -1, 1,
                (v) => _set(_cfg.copyWith(
                    lightSource: Alignment(_cfg.lightSource.x, v)))),
            _section('الشكل'),
            _slider('نصف قطر الزوايا', _cfg.cornerRadius, 0, 0.4,
                (v) => _set(_cfg.copyWith(cornerRadius: v))),
            _slider('نسبة الأبعاد', _cfg.aspectRatio, 1.0, 2.0,
                (v) => _set(_cfg.copyWith(aspectRatio: v))),
            _section('لمسات'),
            _swatches('لون التطعيم', const [
              Color(0xFFD9B45B),
              Color(0xFFE0C069),
              Color(0xFFC8CEDA),
              Color(0xFFF2D486),
            ], _cfg.inlayColor, (c) => _set(_cfg.copyWith(inlayColor: c))),
            _toggle('تطعيم ذهبيّ', _cfg.showInlay,
                (v) => _set(_cfg.copyWith(showInlay: v))),
            _toggle('انعكاس زجاجيّ', _cfg.showReflection,
                (v) => _set(_cfg.copyWith(showReflection: v))),
            _toggle('ميداليّة ذهبيّة', _cfg.showEmblem,
                (v) => _set(_cfg.copyWith(showEmblem: v))),
            const SizedBox(height: 16),
          ],
        ),
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(t,
              style: const TextStyle(
                  color: Color(0xFFD9B45B),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5)),
        ),
      );

  Widget _preset(String label, TableConfig c) => GestureDetector(
        onTap: () => _set(c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2026),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      );

  Widget _slider(String label, double v, double min, double max,
          ValueChanged<double> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                Text(v.toStringAsFixed(2),
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
            SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: Color(0xFFD9B45B),
                thumbColor: Color(0xFFD9B45B),
                inactiveTrackColor: Colors.white12,
                overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                trackHeight: 3,
              ),
              child: Slider(
                  value: v.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: onChanged),
            ),
          ],
        ),
      );

  Widget _swatches(String label, List<Color> colors, Color selected,
          ValueChanged<Color> onPick) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final c in colors)
                  GestureDetector(
                    onTap: () => onPick(c),
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c == selected
                              ? const Color(0xFFD9B45B)
                              : Colors.white24,
                          width: c == selected ? 3 : 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _toggle(String label, bool v, ValueChanged<bool> onChanged) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
            Switch(
              value: v,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFFD9B45B),
            ),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Text('🎴', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('طاولاتٌ تجريبيّة — رسمٌ بالكود بلا صور',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD9B45B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('عرضٌ فقط — غير مدموج',
                style: TextStyle(
                    color: Color(0xFFD9B45B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      );
}
