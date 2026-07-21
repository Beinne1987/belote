import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';

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
              Stack(
                clipBehavior: Clip.none, // الشارةُ تتجاوز حدَّ الأيقونة عمدًا
                children: [
                  Icon(item.icon, color: color, size: 24),
                  if (item.badge > 0)
                    Positioned(
                      top: -4,
                      left: -6, // الواجهة RTL ⇒ «left» هو الطرف الخارجيّ
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
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
              ),
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
