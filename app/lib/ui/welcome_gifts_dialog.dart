import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';
import 'gift_picker.dart';

/// **نافذةُ ترحيبٍ تُعرَض مرّةً واحدةً عند التسجيل** تُري اللاعبَ ما ناله
/// (طلب المالك 2026-07-15).
///
/// **مرّةً واحدةً بحقّ**: تُبنى على `isNew` من ردّ `/auth/register` وحدَه — وهو صادقٌ
/// من الخادم لا من علمٍ محلّيّ. `SessionStore` يُعيد `isNew: false` دائمًا (استعادةٌ
/// لا إنشاء) ⇒ إعادةُ فتح التطبيق لا تُعيدها، ولا نحتاج علمًا محفوظًا يُنسى محوُه.
///
/// [gifts] كما منحها الخادم. فارغةٌ ⇒ لا نافذة: لا نَعِد بما لم يقع.
Future<void> showWelcomeGifts(
  BuildContext context, {
  required Map<String, int> gifts,
}) {
  if (gifts.isEmpty) return Future<void>.value();
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // هديّةٌ تُقدَّم لا إعلانٌ يُنقَر جانبَه
    builder: (_) => _WelcomeDialog(gifts: gifts),
  );
}

class _WelcomeDialog extends StatelessWidget {
  const _WelcomeDialog({required this.gifts});

  final Map<String, int> gifts;

  /// اسمُ الهديّة ورمزُها من كتالوج الواجهة. **معرّفٌ لا نعرفه ⇒ يُتجاهَل**: خادمٌ
  /// أحدثُ من التطبيق يمنح هديّةً جديدة، وعرضُ معرّفها الخام أقبحُ من إسقاطها.
  ({String name, String emoji})? _meta(String id) {
    for (final g in giftCatalogUi) {
      if (g.id == id) return (name: g.name, emoji: g.emoji);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final items = [
      for (final e in gifts.entries)
        if (e.value > 0 && _meta(e.key) != null)
          (meta: _meta(e.key)!, count: e.value)
    ];
    if (items.isEmpty) {
      // كلُّ المعرّفات مجهولة ⇒ أغلِق بدل نافذةٍ فارغة.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    }

    return Dialog(
      backgroundColor: t.gradBottom,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎁', style: TextStyle(fontSize: 40, color: t.text)),
            const SizedBox(height: 8),
            Text('أهلًا بك',
                style: TextStyle(
                    color: t.text, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('هذه هديّتُنا لك — أهدِها لمن تلعب معه.',
                textAlign: TextAlign.center,
                style: TextStyle(color: t.text3, fontSize: 13)),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final it in items)
                  Container(
                    width: 84,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.accent, width: 1.4),
                    ),
                    child: Column(
                      children: [
                        Text(it.meta.emoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(height: 4),
                        Text(it.meta.name,
                            style: TextStyle(color: t.text, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text('×${it.count}',
                            // الأرقام لاتينيّةٌ دائمًا (قاعدة المشروع)
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                                color: t.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: t.accent, foregroundColor: t.onAccent),
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('شكرًا'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
