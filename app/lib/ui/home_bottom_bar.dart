import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';
import 'layout.dart';

/// عنصرٌ في الشريط السفليّ: أيقونةٌ واسمٌ، وشارةُ عددٍ اختياريّة.
@immutable
class HomeBarItem {
  final IconData icon;
  final String label;

  /// عددٌ غير مقروء (رسائل الأصدقاء مثلًا). صفرٌ ⇒ بلا شارة.
  final int badge;

  const HomeBarItem({required this.icon, required this.label, this.badge = 0});
}

/// الشريطُ السفليّ للرئيسيّة: وجهاتٌ ثابتةٌ تحت الإبهام، لا تختفي بتمرير القائمة.
///
/// **زرٌّ واحدٌ لكلّ وجهة**: ما دخل الشريطَ خرج من قائمة البطاقات — مدخلان لشيءٍ
/// واحدٍ يجعلان اللاعب يظنّ أنّه ضغط الخطأ.
class HomeBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HomeBarItem> items;

  const HomeBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : assert(items.length >= 2 && items.length <= 5);

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    // SafeArea تُبقيه فوق شريط الإيماءات؛ بدونها يُقصّ نصفُ الأسماء.
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.line),
          boxShadow: [
            BoxShadow(color: t.shadow, blurRadius: 18, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _BarButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// **الشريطُ الجانبيّ** — بديلُ التنقّل السفليّ على اللوح والحاسوب.
///
/// شريطٌ سفليٌّ على شاشةٍ عرضُها 1600 بكسلًا يقرأ «تطبيقَ هاتفٍ مكبَّرًا»: خمسةُ
/// أزرارٍ ممطوطةٍ في قاع نافذةٍ عريضة، بعيدةٌ عن الفأرة التي تسكن الوسطَ والأعلى.
/// وعلى الحاسوب لا إبهامَ تحت الشاشة أصلًا — العُرفُ هناك جانبيّ.
///
/// **والهاتفُ لا يراه أبدًا**: يُبنى فقط حين [AppLayout.railOf]، فيبقى
/// [HomeBottomBar] كما هو بكسلًا بكسل دون [AppLayout.tabletMin].
///
/// وسيطٌ واحدٌ ([items]) للشريطين ⇒ وجهةٌ تُضاف مرّةً تظهر في التخطيطين معًا،
/// ولا يفترقان يومَ يُعدَّل أحدُهما.
class HomeSideNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HomeBarItem> items;

  /// أيقوناتٌ بلا أسماء (اللوحُ الضيّق): الاسمُ يظهر تلميحًا عند التحويم.
  final bool compact;

  const HomeSideNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.compact = false,
  });

  /// عرضُ الشريط — يقرؤه التخطيطُ ليحسب ما بقي للمحتوى.
  static const double wide = 208;
  static const double narrow = 88;

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      width: compact ? narrow : wide,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.line),
        boxShadow: [
          BoxShadow(color: t.shadow, blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _RailButton(
                  item: items[i],
                  selected: i == currentIndex,
                  compact: compact,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// صفٌّ في الشريط الجانبيّ: أيقونةٌ (وشارتُها) واسمٌ، وقرصٌ مميَّزٌ حين يكون
/// المكانَ الذي نحن فيه. **تلميحٌ دائمًا** — على الحاسوب فأرةٌ تحوم، والاسمُ
/// المخفيُّ في الوضع الضيّق لا يُعرَف إلّا به.
class _RailButton extends StatelessWidget {
  final HomeBarItem item;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _RailButton({
    required this.item,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final color = selected ? t.accent : t.text2;
    final icon = _BadgedIcon(item: item, color: color, size: 24);
    return Tooltip(
      message: item.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected ? t.accent.withValues(alpha: 0.12) : null,
                border: Border.all(
                  color: selected ? t.accent.withValues(alpha: 0.5) : Colors.transparent,
                ),
              ),
              child: compact
                  ? Center(child: icon)
                  : Row(
                      children: [
                        icon,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// أيقونةٌ بشارةِ عددٍ فوقها — يشترك فيها الشريطان فلا تُرسَم الشارةُ مرّتين
/// بقاعدتين تنحرفان.
class _BadgedIcon extends StatelessWidget {
  final HomeBarItem item;
  final Color color;
  final double size;
  const _BadgedIcon(
      {required this.item, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Stack(
      clipBehavior: Clip.none, // الشارةُ تتجاوز حدَّ الأيقونة عمدًا
      children: [
        Icon(item.icon, color: color, size: size),
        if (item.badge > 0)
          // **الطرفُ الخارجيّ يتبع اللغة**: كان `left: -6` بحجّة أنّ الواجهة
          // عربيّة — وهي فرنسيّةٌ أيضًا، وهناك يصير اليسارُ الطرفَ **الداخليّ**
          // فتقفز الشارةُ فوق جارتها. `end` يعني الخارجَ في الاتّجاهين.
          PositionedDirectional(
            top: -4,
            end: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 15),
              decoration: BoxDecoration(
                color: t.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.surface, width: 1.4),
              ),
              child: Text(
                item.badge > 99 ? '+99' : '${item.badge}',
                textAlign: TextAlign.center,
                // الأرقام لاتينيّةٌ دائمًا، والعزلُ يمنع قلبَ «+99».
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  final HomeBarItem item;
  final bool selected;
  final VoidCallback onTap;

  const _BarButton(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final color = selected ? t.accent : t.text3;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? t.accent.withValues(alpha: 0.12) : null,
        ),
        // FittedBox يمنع فيض الأسماء العربية على الشاشات الضيّقة (خمسةُ عناصر).
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BadgedIcon(item: item, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
