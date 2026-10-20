import 'package:flutter/material.dart';

import '../l10n/app_text.dart';
import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import '../services/store_purchase.dart';
import '../platform/app_platform.dart';
import 'bankily_sheet.dart';
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
/// وسلّمُ باقات الماس تُشترى ببنكيلي ([showBankilySheet]) — «قريبًا» صادقةٌ ما لم
/// يعمل الدفعُ في الخادم.
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
  // رمزُ التاجر وحالةُ بنكيلي من الخادم — يتبدّلان من اللوحة بلا بناء.
  BankilyConfig _bankily = BankilyConfig.fallback;

  /// أسعارُ App Store (متاجر Apple وحدها) — فارغةٌ ⇒ العرضُ بالأوقية.
  Map<String, String> _storePrices = const {};
  String? _error;
  String? _buying; // معرّفُ الباقة قيد الشراء ⇒ زرُّها وحدَه يدور
  // **التذاكرُ أوّلًا**: هي ما يبيعه المتجرُ فعلًا اليوم، والقادمُ إليه غالبًا
  // جاءه من «انتهت لعباتُك».
  // On Apple platforms, open directly to the purchasable content so reviewers can find IAPs.
  _StoreTab _tab =
      AppPlatform.appleStore ? _StoreTab.diamonds : _StoreTab.tickets;

  late final StorePurchaseService _storeBuy =
      StorePurchaseService(widget.session);

  @override
  void initState() {
    super.initState();
    _storeBuy.listen(); // يعالج ما بقي معلّقًا من عمليّاتٍ سابقة
    _load();
  }

  @override
  void dispose() {
    _storeBuy.dispose();
    super.dispose();
  }

  /// **اختيارُ طريقة الدفع**: المتجرُ متاحٌ (يقرّره الخادم) ⇒ خياران؛ وإلّا
  /// بنكيلي مباشرةً كما كان.
  Future<void> _pay(DiamondPackView p) async {
    if (AppPlatform.appleStore) return _buyFromStore(p);
    if (!StorePurchaseService.available(_bankily)) {
      return showBankilySheet(context,
          session: widget.session, pack: p, config: _bankily);
    }
    final t = BeloteTheme.of(context);
    final l = context.l10n;
    final apple = StorePurchaseService.platformName == 'ios';
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.storeBuyChoose,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _payOption(t,
                  icon: apple ? Icons.apple : Icons.shop,
                  title: apple ? l.storeBuyViaApple : l.storeBuyViaGoogle,
                  sub: l.storeBuyViaStoreSub,
                  onTap: () => Navigator.pop(ctx, 'store')),
              const SizedBox(height: 10),
              _payOption(t,
                  icon: Icons.account_balance_wallet,
                  title: l.bankilyBuy,
                  sub: l.storeBuyViaBankilySub,
                  badge: _bankily.live ? null : l.bankilySoonBadge,
                  onTap: () => Navigator.pop(ctx, 'bankily')),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'bankily') {
      return showBankilySheet(context,
          session: widget.session, pack: p, config: _bankily);
    }
    return _buyFromStore(p);
  }

  /// شراءٌ مباشرٌ من المتجر. على متاجر Apple هو الطريقُ الوحيد؛ وقبل أن يفعّله الخادم
  /// (`store.ios`) يقول «غير متاح الآن» صادقًا بدل أيّ بديلٍ خارج المتجر.
  Future<void> _buyFromStore(DiamondPackView p) async {
    final l = context.l10n;
    if (!StorePurchaseService.available(_bankily)) {
      _toast(l.storeBuyUnavailable);
      return;
    }
    setState(() => _buying = p.id);
    final r = await _storeBuy.buy(p.id);
    if (!mounted) return;
    setState(() => _buying = null);
    _toast(switch (r) {
      StoreBuyResult.done => l.bankilySuccess(p.total),
      StoreBuyResult.cancelled => l.storeBuyCancelled,
      StoreBuyResult.unavailable => l.storeBuyUnavailable,
      StoreBuyResult.failed => l.storeBuyFailed,
    });
  }

  Widget _payOption(BeloteTheme t,
          {required IconData icon,
          required String title,
          required String sub,
          String? badge,
          required VoidCallback onTap}) =>
      InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.lineStrong),
          ),
          child: Row(
            children: [
              Icon(icon, color: t.accent, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: t.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5)),
                    Text(sub, style: TextStyle(color: t.text3, fontSize: 12)),
                  ],
                ),
              ),
              if (badge != null)
                Text(badge,
                    style: TextStyle(
                        color: t.warning,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = widget.session.api;
      final r = await Future.wait([
        api.giftBundles(),
        api.diamondPacks(),
        api.tickets(),
        api.bankilyConfig(), // لا يرمي: يفشل ⇒ «قريبًا»
      ]);
      if (mounted) {
        setState(() {
          _bundles = r[0] as List<GiftBundleView>;
          _packs = r[1] as List<DiamondPackView>;
          _tickets = r[2] as List<TicketView>;
          _bankily = r[3] as BankilyConfig;
        });
        if (AppPlatform.appleStore &&
            StorePurchaseService.available(_bankily)) {
          final prices = await _storeBuy.storePrices(_packs!.map((p) => p.id));
          if (mounted && prices.isNotEmpty) {
            setState(() => _storePrices = prices);
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.storeFetchFailed);
    }
  }

  Future<void> _buy(GiftBundleView b) async {
    setState(() => _buying = b.id);
    try {
      await widget.session.buyGiftBundle(b.id);
      if (!mounted) return;
      _toast(context.l10n.bundlePurchased(b.qty, _nameOf(b.gift)));
    } on ApiException catch (e) {
      if (!mounted) return;
      // 402 حالةٌ تُشرَح لا عطبٌ يُبلَّغ: قُل له كم ينقصه بدل «فشل الشراء».
      _toast(e.status == 402
          ? context.l10n.notEnoughForBundle(b.price)
          : context.l10n.purchaseFailed);
    } catch (_) {
      if (mounted) _toast(context.l10n.connectionFailed);
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  Future<void> _buyTicket(TicketView k) async {
    setState(() => _buying = k.id);
    try {
      final suggestVip = await widget.session.buyTicket(k.id);
      if (!mounted) return;
      _toast(context.l10n.unlimitedEnjoy);
      // **اشترى تذاكرَ كثيرة ⇒ اعرض VIP**: التذكرةُ بابٌ إليه. الخادمُ قرّر المتى.
      if (suggestVip) await showVipUpsell(context, widget.session);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 402) {
        // **402 يقود إلى مخرجٍ لا إلى حائط**: ينقصه ماسٌ ⇒ افتح صفحتَه بدل
        // «تعذّر الشراء» التي تتركه واقفًا.
        _toast(context.l10n.notEnoughForTicket(k.price));
        setState(() => _tab = _StoreTab.diamonds);
      } else {
        _toast(context.l10n.purchaseFailed);
      }
    } catch (_) {
      if (mounted) _toast(context.l10n.connectionFailed);
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  String _nameOf(String giftId) {
    final l = context.l10n;
    for (final g in giftCatalogUi) {
      if (g.id == giftId) return g.name(l);
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
              SimpleTopBar(title: context.l10n.storeTitle),
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
                      color: t.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ],
          ),
        ),
      );

  Widget _body(BeloteTheme t) {
    if (_error != null) {
      return _center(t, _error!,
          action: TextButton(
              onPressed: _load, child: Text(context.l10n.retryShort)));
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
        _TabSpec(_StoreTab.tickets, context.l10n.tabPlay, Icons.all_inclusive),
      if (byGift.isNotEmpty)
        _TabSpec(_StoreTab.gifts, context.l10n.tabGifts, Icons.card_giftcard),
      if (_packs!.isNotEmpty)
        _TabSpec(_StoreTab.diamonds, context.l10n.tabDiamonds, Icons.diamond),
    ];
    if (tabs.isEmpty) return _center(t, context.l10n.storeEmpty);

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
              Text(context.l10n.ticketsIntro,
                  style: TextStyle(color: t.text3, fontSize: 12.5)),
              const SizedBox(height: 12),
              // **مَن عنده تذكرةٌ حيّةٌ يُقال له** — وشراؤه الثاني يمدّد لا يُهدَر.
              if (a != null && a.unlimited) ...[
                _notice(
                    t, Icons.all_inclusive, context.l10n.unlimitedActiveNotice),
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
                        color: t.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                if (best)
                  Text(context.l10n.cheaperThanSevenDays,
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
        24 => context.l10n.ticketFullDay,
        168 => context.l10n.ticketFullWeek,
        final h when h % 24 == 0 => context.l10n.ticketDays(h ~/ 24),
        final h => context.l10n.ticketHours(h),
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
          Text(context.l10n.giftsIntro,
              style: TextStyle(color: t.text3, fontSize: 12.5)),
          const SizedBox(height: 12),
          for (final e in byGift.entries) _giftGroup(t, e.key, e.value),
        ],
      );

  /// **صفحةُ الماس** — تُخبر ولا تكذب.
  ///
  /// كلُّ باقةٍ تفتح خطواتِ بنكيلي. ما لم يعمل الدفعُ في الخادم يحمل كلُّ زرٍّ شارةَ
  /// «قريبًا» وتُعرَض الخطواتُ بزرِّ تأكيدٍ معطّل — ظاهرٌ كما هو، لا مخفيٌّ يظهر
  /// لاحقًا (طلب المالك 2026-09-29: «لا تخدع المتجر»).
  Widget _diamondsPage(BeloteTheme t) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // «كلّ ماسةٍ بأوقيّة» وصفٌ لبنكيلي؛ على متاجر Apple السعرُ سعرُ App Store.
          if (!AppPlatform.appleStore)
            Text(context.l10n.diamondsIntro,
                style: TextStyle(color: t.text3, fontSize: 12.5)),
          const SizedBox(height: 12),
          for (final p in _packs!) _packRow(t, p),
          if (!StorePurchaseService.available(_bankily) &&
              (AppPlatform.appleStore || !_bankily.live)) ...[
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
                    child: Text(
                        AppPlatform.appleStore
                            ? context.l10n.appStoreBuySoon
                            : context.l10n.bankilySoon,
                        style: TextStyle(color: t.text3, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          ],
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
        border:
            Border.all(color: best ? t.accent : t.line, width: best ? 1.4 : 1),
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
                          color: t.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  if (p.bonus > 0) ...[
                    const SizedBox(width: 6),
                    Text('(${p.base} + ${p.bonus})',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(color: t.text3, fontSize: 11.5)),
                  ],
                ],
              ),
              if (p.bonus > 0)
                Text(context.l10n.bonusPct(p.bonusPct),
                    style: TextStyle(
                        color: t.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          _bankilyButton(t, p),
        ],
      ),
    );
  }

  /// زرُّ الباقة: الثمنُ بالأوقية وتحته «بنكيلي» أو «قريبًا» — يفتح الخطواتِ دائمًا.
  Widget _bankilyButton(BeloteTheme t, DiamondPackView p) {
    final store = StorePurchaseService.available(_bankily);
    final live = store || (!AppPlatform.appleStore && _bankily.live);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _buying != null ? null : () => _pay(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: live ? t.accent : t.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: live ? t.accent : t.lineStrong),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_storePrices[p.id] ?? context.l10n.priceOuguiya(p.price),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    color: live ? t.onAccent : t.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800)),
            Text(
                AppPlatform.appleStore
                    ? (store ? 'App Store' : context.l10n.bankilySoonBadge)
                    : store
                        ? context.l10n.storeBuyChoose
                        : live
                            ? 'Bankily'
                            : context.l10n.bankilySoonBadge,
                style: TextStyle(
                    color: live ? t.onAccent : t.warning,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
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
                          color: t.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const Spacer(),
                  // **ما يملكه ظاهرٌ عند الشراء**: يمنع شراءَ ما عنده منه عشرون.
                  if (owned > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.surface2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: t.line),
                      ),
                      child: Text(context.l10n.ownedCount(owned),
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
                height: 44,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : Column(
                children: [
                  Text('×${b.qty}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          color: t.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond,
                          size: 13, color: Color(0xFF5BC6F0)),
                      const SizedBox(width: 3),
                      Text('${b.price}',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                              color: t.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(context.l10n.savePct(b.discountPct),
                        style: TextStyle(
                            color: t.onAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
      ),
    );
  }
}
