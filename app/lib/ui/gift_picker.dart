import 'package:flutter/material.dart';

import '../game/seat_player.dart';
import '../theme/belote_theme.dart';

/// هديّةٌ كما تُعرَض. **يجب أن تطابق `giftCatalog`** في `server/lib/game/gifts.dart`
/// (المعرّف والرمز والثمن) — الخادم هو المرجع: هو من يخصم ويرفض. الاسم عربيٌّ هنا
/// وحده. يحرس التطابقَ `test/gift_sync_test.dart`.
class GiftItem {
  final String id;
  final String emoji;
  final String name;
  final int price;
  const GiftItem(this.id, this.emoji, this.name, this.price);
}

const giftCatalogUi = <GiftItem>[
  GiftItem('rose', '🌹', 'وردة', 5),
  GiftItem('tea', '🫖', 'أتاي', 10),
  GiftItem('sweet', '🍬', 'حلوى', 20),
  GiftItem('crown', '👑', 'تاج', 50),
  GiftItem('camel', '🐪', 'جمل', 100),
  GiftItem('car', '🚗', 'سيّارة', 200),
];

/// **هديّةُ VIP الحصريّة** — أصلٌ فنّيٌّ لا إيموجي: الحصريّةُ تُرى بالعين، وإيموجيٌّ
/// يملكه كلُّ هاتفٍ ليس حصريًّا. **يجب أن تطابق `vipGiftCatalog` في الخادم** معرّفًا
/// وترتيبًا — يحرسه `vip_gift_sync_test`.
class VipGiftItem {
  final String id;
  final String name;
  final String asset;
  const VipGiftItem(this.id, this.name, this.asset);
}

const vipGiftCatalogUi = <VipGiftItem>[
  VipGiftItem('vip_flower', 'وردةُ VIP', 'assets/VIP/gift_flower.png'),
  VipGiftItem('vip_box', 'صندوقُ VIP', 'assets/VIP/gift_box.png'),
  VipGiftItem('vip_pitcher', 'بَراد VIP', 'assets/VIP/gift_pitcher.png'),
];

/// أصلُ هديّة VIP [id]، أو null إن لم تكن منها.
String? vipGiftAsset(String id) {
  for (final g in vipGiftCatalogUi) {
    if (g.id == id) return g.asset;
  }
  return null;
}

/// رمز الهديّة [id] للعرض في الفقاعة، أو null إن كان معرّفًا لا نعرفه.
String? giftEmoji(String id) {
  for (final g in giftCatalogUi) {
    if (g.id == id) return g.emoji;
  }
  return null;
}

/// **مقعدُ «للجميع»** — قيمةٌ اصطلاحيّة تُرسَل مكان رقم المقعد، يفهمها الخادم
/// أنّها كلُّ الجالسين البشر غير المُرسِل. `-1` لأنّه ليس مقعدًا صالحًا أبدًا.
const int kGiftAll = -1;

/// لوحة الهدايا: تختار **من** ثمّ **ماذا**. أونلاين فقط.
///
/// [targets] فارغةٌ ⇒ **حالةٌ تشرح نفسها** لا لوحةٌ مغلقة: الذكاء لا محفظة له فلا
/// يُهدى، وإخفاءُ الزرّ حينها جعل الميزة غير مكتشَفة أصلًا (بلاغ المالك على 4041).
/// [stock] كم يملك من كلّ هديّةٍ (مخزونُ ما اشتراه في باقة). الافتراضُ صفرٌ لكلٍّ
/// ⇒ الثمنُ يُعرَض كما كان، فلا تنكسر أيُّ شاشةٍ لا تعرف المخزون.
Future<void> showGiftSheet(
  BuildContext context, {
  required List<({int viewSeat, SeatPlayer player})> targets,
  required void Function(int viewSeat, String giftId) onSend,
  int Function(String giftId)? stock,

  /// رصيدُ هدايا VIP المشترك (3 يوميًّا حتى 10). صفرٌ أو null ⇒ لا يُعرَض قسمُها.
  int vipStock = 0,
}) {
  final t = BeloteTheme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: t.gradBottom,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _GiftSheet(
        targets: targets, onSend: onSend, stock: stock, vipStock: vipStock),
  );
}

class _GiftSheet extends StatefulWidget {
  final List<({int viewSeat, SeatPlayer player})> targets;
  final void Function(int viewSeat, String giftId) onSend;
  final int Function(String giftId)? stock;
  final int vipStock;
  const _GiftSheet(
      {required this.targets,
      required this.onSend,
      this.stock,
      this.vipStock = 0});

  @override
  State<_GiftSheet> createState() => _GiftSheetState();
}

class _GiftSheetState extends State<_GiftSheet> {
  // `first` على قائمةٍ فارغةٍ ترمي ⇒ -1 حين لا هدف (لا تُبنى الشبكة أصلًا حينها).
  late int _to =
      widget.targets.isEmpty ? -1 : widget.targets.first.viewSeat;

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: t.accentBright),
                const SizedBox(width: 8),
                Text('إهداء',
                    style: TextStyle(
                        color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.targets.isEmpty) ...[
              // **يشرح ويدلّ**: لماذا تعذّرت، وما الذي يجعلها ممكنة.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: t.text3, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الهدايا للاعبين البشر — ولا يجلس معك الآن غير الذكاء.\n'
                      'ادعُ صاحبك إلى طاولةٍ خاصّة لتُهديه.',
                      style: TextStyle(color: t.text2, fontSize: 13, height: 1.6),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text('إلى مَن؟', style: TextStyle(color: t.text2, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final target in widget.targets)
                  ChoiceChip(
                    label: Text(target.player.name),
                    selected: _to == target.viewSeat,
                    onSelected: (_) => setState(() => _to = target.viewSeat),
                    selectedColor: t.accent.withValues(alpha: 0.28),
                    backgroundColor: t.surface,
                    labelStyle: TextStyle(color: t.text, fontSize: 13),
                    side: BorderSide(
                        color: _to == target.viewSeat ? t.accent : t.line),
                  ),
                // **«للجميع»** — اختصارٌ لا تخفيض: الثمن ×عددِ الجالسين، معروضًا
                // صراحةً على كلّ هديّةٍ قبل الضغط. يُخفى إن كان الهدفُ واحدًا:
                // «للجميع» ومعها اسمٌ واحدٌ خياران لفعلٍ واحد.
                if (widget.targets.length > 1)
                  ChoiceChip(
                    avatar: Icon(Icons.groups,
                        size: 17, color: _to == kGiftAll ? t.accent : t.text2),
                    label: const Text('للجميع'),
                    selected: _to == kGiftAll,
                    onSelected: (_) => setState(() => _to = kGiftAll),
                    selectedColor: t.accent.withValues(alpha: 0.28),
                    backgroundColor: t.surface,
                    labelStyle: TextStyle(color: t.text, fontSize: 13),
                    side:
                        BorderSide(color: _to == kGiftAll ? t.accent : t.line),
                  ),
              ],
            ),
            ],
            if (widget.targets.isNotEmpty) ...[
            const SizedBox(height: 16),
            // **هدايا VIP أوّلًا وبصورها**: حصريّةٌ لا تُباع، ورصيدُها يتجدّد
            // ثلاثًا كلَّ يوم. تُخفى لغير المشترك — عرضُ ما لا يُنال إغاظة.
            if (widget.vipStock > 0) ...[
              Row(
                children: [
                  Icon(Icons.workspace_premium, color: t.accent, size: 16),
                  const SizedBox(width: 6),
                  Text('هدايا VIP',
                      style: TextStyle(
                          color: t.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                  Text('بقيت ${widget.vipStock}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: t.text3, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final g in vipGiftCatalogUi)
                    InkWell(
                      onTap: () {
                        widget.onSend(_to, g.id);
                        Navigator.of(context).maybePop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 84,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: t.accent, width: 1.4),
                        ),
                        child: Column(
                          children: [
                            Image.asset(g.asset, height: 34),
                            const SizedBox(height: 6),
                            Text(g.name,
                                style: TextStyle(color: t.text, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            Text('ماذا تُهدي؟', style: TextStyle(color: t.text2, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final g in giftCatalogUi)
                  () {
                    final owned = widget.stock?.call(g.id) ?? 0;
                    // **الحسابُ نظيرُ الخادم حرفًا**: المخزونُ يُستنفَد أوّلًا ثمّ
                    // يُكمَّل بالماس. لو اختلفا لرأى اللاعبُ ثمنًا وخُصم غيرُه.
                    final n = _to == kGiftAll ? widget.targets.length : 1;
                    final fromStock = owned >= n ? n : owned;
                    final gems = (n - fromStock) * g.price;
                    return InkWell(
                      onTap: () {
                        widget.onSend(_to, g.id);
                        Navigator.of(context).maybePop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 84,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(12),
                          // المملوكةُ تُميَّز بحافّةٍ: العينُ تلتقطها قبل أن تقرأ.
                          border: Border.all(
                              color: owned > 0 ? t.accent : t.line,
                              width: owned > 0 ? 1.4 : 1),
                        ),
                        child: Column(
                          children: [
                            Text(g.emoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(g.name,
                                style: TextStyle(color: t.text, fontSize: 12)),
                            const SizedBox(height: 2),
                            // **ما تملكه لا ثمنَ له**: عرضُ الثمن على هديّةٍ ستخرج
                            // من المخزون كذبٌ — لن يُخصَم منه شيء. ومع «للجميع»
                            // يُعرَض **ما سيُخصَم فعلًا** لا ثمنُ الواحدة.
                            if (gems == 0)
                              Text(
                                '×${n > 1 ? n : owned}',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                    color: t.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800),
                              )
                            else
                              Text(
                                '$gems',
                                // الأرقام لاتينيّة دائمًا (قاعدة المشروع)
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                    color: t.accentBright,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800),
                              ),
                          ],
                        ),
                      ),
                    );
                  }(),
              ],
            ),
            const SizedBox(height: 10),
            // لا تَعِد بما لا يقع: المستقبِل لا يقبض شيئًا (الهديّة إنفاقٌ لا تحويل).
            // كان هنا «يقبض صاحبك أغلبه» — وعدٌ صار كذبًا بعد تغيّر الاقتصاد.
            Text(
                _to == kGiftAll
                    ? 'تصل الهديّةُ إلى ${widget.targets.length} لاعبين — ويُخصم ثمنُها لكلٍّ منهم.'
                    : 'يُخصم الثمن من ماسك.',
                style: TextStyle(color: t.text3, fontSize: 12.5)),
            ],
          ],
        ),
      ),
    );
  }
}
