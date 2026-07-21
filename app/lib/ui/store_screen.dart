import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'gift_picker.dart';
import 'vip_upsell.dart';
import 'simple_top_bar.dart';

/// نوعُ الباقات المعروض. **شريطٌ لا أقسامٌ متتالية**: كان القسمان تحت بعضهما في
/// `ListView` واحدٍ ⇒ باقاتُ الماس في القاع تحت الطيّة، ومَن لا يعلم بوجودها لا
/// يمرّر إليها. الشريطُ يجعل الأنواعَ كلَّها **مرئيّةً دفعةً واحدة**.
enum _StoreTab { tickets, gifts, diamonds }

/// بندٌ في الشريط. القائمةُ تُبنى من **البيانات الموجودة فعلًا** لا من ثابتٍ مكتوب:
/// قسمٌ لا بضاعةَ فيه لا يُعرَض له زرٌّ يفتح فراغًا.
class _TabSpec {
  final _StoreTab tab;
  final String label;
  final IconData icon;
  const _TabSpec(this.tab, this.label, this.icon);
}

/// **المتجر** — نوعان: باقاتُ هدايا تُشترى بالماس وتدخل المخزون فتُرسَل متى شاء،
/// وسلّمُ باقات الماس (يُخبر ولا يبيع — بنكيلي آخرُ خطوة).
///
/// كانت هذه الشاشةُ ستّةَ منتجاتٍ وهميّةٍ ببياناتٍ محلّيّة (فيها «باقة 100 Diamonds»
/// ثمنُها رقائق). حلّ محلَّها ما يعمل فعلًا.
///
/// **كلُّ الأرقام من الخادم.** لا معادلةَ خصمٍ هنا: نسخةٌ ثانيةٌ منها تنجرف أوّلَ ما
/// يتغيّر السعرُ فيرى اللاعبُ ثمنًا ويُخصَم غيرُه.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<GiftBundleView>? _bundles;
  List<DiamondPackView>? _packs;
  List<TicketView>? _tickets;
  String? _error;
  String? _buying; // معرّفُ الباقة قيد الشراء ⇒ زرُّها وحدَه يدور
  // **التذاكرُ أوّلًا**: هي ما يبيعه المتجرُ فعلًا اليوم، والقادمُ إليه غالبًا
  // جاءه من «انتهت لعباتُك».
  _StoreTab _tab = _StoreTab.tickets;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = widget.session.api;
      final r = await Future.wait(
          [api.giftBundles(), api.diamondPacks(), api.tickets()]);
      if (mounted) {
        setState(() {
          _bundles = r[0] as List<GiftBundleView>;
          _packs = r[1] as List<DiamondPackView>;
          _tickets = r[2] as List<TicketView>;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر جلب المتجر');
    }
  }

  Future<void> _buy(GiftBundleView b) async {
    setState(() => _buying = b.id);
    try {
      await widget.session.buyGiftBundle(b.id);
      if (!mounted) return;
      _toast('نالك ${b.qty}× ${_nameOf(b.gift)}');
    } on ApiException catch (e) {
      if (!mounted) return;
      // 402 حالةٌ تُشرَح لا عطبٌ يُبلَّغ: قُل له كم ينقصه بدل «فشل الشراء».
      _toast(e.status == 402
          ? 'ماسك لا يكفي — الباقة ${b.price}💎'
          : 'تعذّر الشراء');
    } catch (_) {
      if (mounted) _toast('تعذّر الاتّصال');
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  Future<void> _buyTicket(TicketView k) async {
    setState(() => _buying = k.id);
    try {
      final suggestVip = await widget.session.buyTicket(k.id);
      if (!mounted) return;
      _toast('لعبٌ بلا حدودٍ — استمتع!');
      // **اشترى تذاكرَ كثيرة ⇒ اعرض VIP**: التذكرةُ بابٌ إليه. الخادمُ قرّر المتى.
      if (suggestVip) await showVipUpsell(context, widget.session);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 402) {
        // **402 يقود إلى مخرجٍ لا إلى حائط**: ينقصه ماسٌ ⇒ افتح صفحتَه بدل
        // «تعذّر الشراء» التي تتركه واقفًا.
        _toast('ماسك لا يكفي — التذكرة ${k.price}💎');
        setState(() => _tab = _StoreTab.diamonds);
      } else {
        _toast('تعذّر الشراء');
      }
    } catch (_) {
      if (mounted) _toast('تعذّر الاتّصال');
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  String _nameOf(String giftId) {
    for (final g in giftCatalogUi) {
      if (g.id == giftId) return g.name;
    }
    return giftId; // خادمٌ أحدثُ من التطبيق ⇒ المعرّف خيرٌ من فراغ
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.gradTop, t.gradBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SimpleTopBar(title: 'المتجر'),
              _balance(t),
              Expanded(child: _body(t)),
            ],
          ),
        ),
      ),
    );
  }

  /// رصيدُه أمامه وهو يتسوّق — وإلّا اشترى ثمّ اكتشف أنّه لا يملك.
  Widget _balance(BeloteTheme t) => ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) => Container(
          margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.diamond, size: 17, color: Color(0xFF5BC6F0)),
              const SizedBox(width: 6),
              Text('${widget.session.diamonds}',
                  textDirection: TextDirection.ltr, // الأرقام لاتينيّةٌ دائمًا
                  style: TextStyle(
                      color: t.text, fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ),
      );

  Widget _body(BeloteTheme t) {
    if (_error != null) {
      return _center(t, _error!, action: TextButton(onPressed: _load, child: const Text('إعادة')));
    }
    if (_bundles == null || _packs == null || _tickets == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // مجموعةٌ لكلّ هديّةٍ — يبحث عن الوردة لا عن «×10».
    final byGift = <String, List<GiftBundleView>>{};
    for (final b in _bundles!) {
      byGift.putIfAbsent(b.gift, () => []).add(b);
    }

    final tabs = <_TabSpec>[
      if (_tickets!.isNotEmpty)
        const _TabSpec(_StoreTab.tickets, 'اللعب', Icons.all_inclusive),
      if (byGift.isNotEmpty)
        const _TabSpec(_StoreTab.gifts, 'الهدايا', Icons.card_giftcard),
      if (_packs!.isNotEmpty)
        const _TabSpec(_StoreTab.diamonds, 'الماس', Icons.diamond),
    ];
    if (tabs.isEmpty) return _center(t, 'لا بضاعةَ في المتجر الآن.');

    // النوعُ المختارُ قد يغيب (خادمٌ أطفأ قسمًا) ⇒ نقع على أوّل موجودٍ بدل صفحةٍ فارغة.
    final tab = tabs.any((x) => x.tab == _tab) ? _tab : tabs.first.tab;

    return Column(
      children: [
        // نوعٌ واحدٌ لا يحتاج شريطًا — زرٌّ لا بديلَ له زينةٌ تأكل من الشاشة.
        if (tabs.length > 1) _strip(t, tabs, tab),
        Expanded(
          child: switch (tab) {
            _StoreTab.tickets => _ticketsPage(t),
            _StoreTab.gifts => _giftsPage(t, byGift),
            _StoreTab.diamonds => _diamondsPage(t),
          },
        ),
      ],
    );
  }

  /// **شريطُ الأنواع** — تحت الرصيد مباشرةً، فيرى ما يُباع قبل أن يمرّر.
  Widget _strip(BeloteTheme t, List<_TabSpec> tabs, _StoreTab sel) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            for (final x in tabs) ...[
              Expanded(child: _tabChip(t, x, x.tab == sel)),
              if (x != tabs.last) const SizedBox(width: 8),
            ],
          ],
        ),
      );

  Widget _tabChip(BeloteTheme t, _TabSpec x, bool on) => InkWell(
        // المختارُ لا يُنقَر: إعادةُ بناءٍ بلا تغييرٍ تُفقد موضعَ التمرير بلا سبب.
        onTap: on ? null : () => setState(() => _tab = x.tab),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: on ? t.accent : t.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: on ? t.accent : t.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(x.icon, size: 16, color: on ? t.onAccent : t.text3),
              const SizedBox(width: 6),
              Text(x.label,
                  style: TextStyle(
                      color: on ? t.onAccent : t.text2,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );

  /// **صفحةُ التذاكر** — النوعُ الوحيد الذي **يُباع فعلًا** اليوم بزرٍّ يعمل:
  /// `1💎 = 1 أوقية` ⇒ تُشترى بالماس الذي يملكه، وبنكيلي ليس شرطًا لها.
  Widget _ticketsPage(BeloteTheme t) => ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          final a = widget.session.allowance;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text('العب بلا حدودٍ طوال المدّة — أنت وأصدقاؤك.',
                  style: TextStyle(color: t.text3, fontSize: 12.5)),
              const SizedBox(height: 12),
              // **مَن عنده تذكرةٌ حيّةٌ يُقال له** — وشراؤه الثاني يمدّد لا يُهدَر.
              if (a != null && a.unlimited) ...[
                _notice(t, Icons.all_inclusive,
                    'لديك لعبٌ بلا حدودٍ الآن. أيُّ شراءٍ يمدّده من نهايته.'),
                const SizedBox(height: 12),
              ],
              for (final k in _tickets!) _ticketRow(t, k),
            ],
          );
        },
      );

  Widget _ticketRow(BeloteTheme t, TicketView k) {
    final busy = _buying == k.id;
    final best = k.hours >= 168; // الأسبوعُ أوفر
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: best ? t.accent : t.line, width: best ? 1.4 : 1),
      ),
      child: Row(
        children: [
          Icon(Icons.all_inclusive, size: 20, color: t.accentBright),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_ticketName(k),
                    style: TextStyle(
                        color: t.text, fontSize: 15, fontWeight: FontWeight.w800)),
                if (best)
                  Text('أوفرُ من سبع تذاكرِ يوم',
                      style: TextStyle(
                          color: t.accent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              onPressed: _buying != null ? null : () => _buyTicket(k),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond, size: 13),
                        const SizedBox(width: 4),
                        Text('${k.price}', textDirection: TextDirection.ltr),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// الاسمُ العربيُّ محلّيٌّ — الخادمُ لا يحمل نصًّا (كالهدايا والمهامّ).
  /// **مشتقٌّ من ساعات الخادم** لا مكتوبٌ بيدٍ: تغييرُ المدّة خادميًّا لا يُكذّب النصّ.
  String _ticketName(TicketView k) => switch (k.hours) {
        24 => 'يومٌ كامل — 24 ساعة',
        168 => 'أسبوعٌ كامل — 7 أيّام',
        final h when h % 24 == 0 => '${h ~/ 24} أيّام',
        final h => '$h ساعة',
      };

  Widget _notice(BeloteTheme t, IconData icon, String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: t.text3),
            const SizedBox(width: 8),
            Expanded(
                child: Text(msg,
                    style: TextStyle(color: t.text3, fontSize: 12.5))),
          ],
        ),
      );

  /// صفحةُ الهدايا. **لا عنوانَ يكرّر الشريط** — الزرُّ المضيءُ فوقها يقولها.
  Widget _giftsPage(BeloteTheme t, Map<String, List<GiftBundleView>> byGift) =>
      ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('اشترِ الآن، وأهدِ متى شئت.',
              style: TextStyle(color: t.text3, fontSize: 12.5)),
          const SizedBox(height: 12),
          for (final e in byGift.entries) _giftGroup(t, e.key, e.value),
        ],
      );

  /// **صفحةُ الماس** — تُخبر ولا تكذب.
  ///
  /// لا زرَّ شراءٍ هنا: بنكيلي آخرُ خطوةٍ في المشروع، ولا مسارَ دفعٍ أصلًا. وزرٌّ
  /// يُنقَر فلا يحدث شيءٌ أسوأُ من غيابه — لكنّ السلّمَ نفسَه **معلومةٌ حقيقيّة**
  /// يريدها اللاعب: كم يدفع وكم ينال وكم يوفّر. فنعرضه ونقول متى يُشترى.
  Widget _diamondsPage(BeloteTheme t) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text('كلُّ ماسةٍ بأوقيّة. والباقةُ الأكبر تُعطيك أكثر.',
              style: TextStyle(color: t.text3, fontSize: 12.5)),
          const SizedBox(height: 12),
          for (final p in _packs!) _packRow(t, p),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: t.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.line),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: t.text3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('الشراء عبر بنكيلي — قريبًا.',
                      style: TextStyle(color: t.text3, fontSize: 12.5)),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _packRow(BeloteTheme t, DiamondPackView p) {
    final best = p.bonusPct > 0 && p == _packs!.last;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: best ? t.accent : t.line, width: best ? 1.4 : 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.diamond, size: 20, color: Color(0xFF5BC6F0)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${p.total}',
                      // الأرقام لاتينيّةٌ دائمًا (CLAUDE.md)
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          color: t.text, fontSize: 16, fontWeight: FontWeight.w800)),
                  if (p.bonus > 0) ...[
                    const SizedBox(width: 6),
                    Text('(${p.base} + ${p.bonus})',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: t.text3, fontSize: 11.5)),
                  ],
                ],
              ),
              if (p.bonus > 0)
                Text('هديّة ${p.bonusPct}%',
                    style: TextStyle(
                        color: t.accent, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Text('${p.price} أوقية',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: t.text2, fontSize: 13.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _center(BeloteTheme t, String msg, {Widget? action}) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg, style: TextStyle(color: t.text3)),
            if (action != null) action,
          ],
        ),
      );

  Widget _giftGroup(BeloteTheme t, String giftId, List<GiftBundleView> tiers) {
    final emoji = tiers.first.emoji;
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final owned = widget.session.giftStock(giftId);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(_nameOf(giftId),
                      style: TextStyle(
                          color: t.text, fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  // **ما يملكه ظاهرٌ عند الشراء**: يمنع شراءَ ما عنده منه عشرون.
                  if (owned > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.surface2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: t.line),
                      ),
                      child: Text('تملك $owned',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(color: t.text2, fontSize: 11.5)),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final b in tiers) ...[
                    Expanded(child: _tierButton(t, b)),
                    if (b != tiers.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tierButton(BeloteTheme t, GiftBundleView b) {
    final busy = _buying == b.id;
    return InkWell(
      onTap: _buying != null ? null : () => _buy(b),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: t.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.accent.withValues(alpha: 0.5)),
        ),
        child: busy
            ? const SizedBox(
                height: 44, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : Column(
                children: [
                  Text('×${b.qty}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          color: t.text, fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond, size: 13, color: Color(0xFF5BC6F0)),
                      const SizedBox(width: 3),
                      Text('${b.price}',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              color: t.text, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // الثمنُ الكامل مشطوبًا: الوفرُ لا يُصدَّق ما لم يُرَ ما تركه.
                  Text('${b.fullPrice}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: t.text3,
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                      )),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('وفّر ${b.discountPct}%',
                        style: TextStyle(
                            color: t.onAccent, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
      ),
    );
  }
}
