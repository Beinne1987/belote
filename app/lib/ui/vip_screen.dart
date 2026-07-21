import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'player_avatar.dart';
import 'simple_top_bar.dart';
import 'vip_room.dart';

/// **شاشةُ VIP** — «اعرض ما نقدّمه في شاشة الاشتراك: الإطار والغرفة وكلّ شيء
/// للتحفيز على الاشتراك» (نصُّ المالك 2026-07-16).
///
/// **تُري ولا تصف**: المزيّةُ التي تُوصَف بالكلام لا تُشترى — والإطارُ يظهر **على
/// صورة اللاعب نفسِه** فيرى نفسَه فيه قبل أن يدفع. وهذه هي **البديلُ الصادق** الذي
/// حلّ محلّ روبوتات VIP الملغاة: تُري المزايا حيّةً بدل أن تُوهم بزبائنَ مزيّفين
/// ([[economy-diamonds-only]]).
class VipScreen extends StatefulWidget {
  const VipScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  List<VipPlanView>? _plans;
  String? _error;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final p = await widget.session.api.vipPlans();
      // حالتُه تُجلَب معها — وقراءتُها تصرف ما استحقّ من دفعات.
      await widget.session.refreshVip();
      if (mounted) setState(() => _plans = p);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر جلب الاشتراك');
    }
  }

  Future<void> _subscribe(VipPlanView p) async {
    setState(() => _busy = p.id);
    try {
      await widget.session.subscribeVip(p.id);
      if (!mounted) return;
      _toast('أهلًا بك في VIP!');
    } on ApiException catch (e) {
      if (!mounted) return;
      _toast(e.status == 402
          ? 'ماسك لا يكفي — الاشتراك ${p.price}💎'
          : 'تعذّر الاشتراك');
    } catch (_) {
      if (mounted) _toast('تعذّر الاتّصال');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // **الغرفةُ تُرى من بابها**: شاشةُ الاشتراك تعرض ما يُشترى، فتقف
          // على جدار الغرفة نفسِه. التدرّجُ يبقى **فوقها** حجابًا للقراءة —
          // مزيّةٌ لا تُقرأ لا تُشترى.
          image: VipRoom.image(dim: 0.35),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              t.gradTop.withValues(alpha: 0.86),
              t.gradBottom.withValues(alpha: 0.94),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SimpleTopBar(title: 'VIP'),
              Expanded(child: _body(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BeloteTheme t) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: t.text3)),
            TextButton(onPressed: _load, child: const Text('إعادة')),
          ],
        ),
      );
    }
    if (_plans == null) return const Center(child: CircularProgressIndicator());

    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final vip = widget.session.isVip;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            if (vip) _activeBanner(t) else _frameHero(t),
            const SizedBox(height: 16),
            _perks(t),
            const SizedBox(height: 18),
            // **مشتركٌ حيٌّ لا يُباع له ما يملك** — بل يُقال له متى ينتهي، وله
            // أن يمدّد.
            Text(vip ? 'مدّد اشتراكك' : 'اختر اشتراكك',
                style: TextStyle(
                    color: t.text, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final p in _plans!) _planRow(t, p),
          ],
        );
      },
    );
  }

  /// **يرى نفسَه في الإطار قبل أن يدفع** — لا وصفًا لإطار.
  Widget _frameHero(BeloteTheme t) => Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PlayerAvatar(
                  url: widget.session.player?.avatarUrl ?? '',
                  fallback: (widget.session.player?.displayName ?? '؟')
                      .characters
                      .firstOrNull ??
                      '؟',
                  size: 96,
                ),
                Image.asset('assets/VIP/player_frame_vip.png',
                    height: 190, fit: BoxFit.contain),
              ],
            ),
          ),
          Text('إطارُك الخاصُّ يرافقك على كلّ طاولة',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.text2, fontSize: 13)),
        ],
      );

  Widget _activeBanner(BeloteTheme t) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.accent),
        ),
        child: Row(
          children: [
            Icon(Icons.workspace_premium, color: t.accent, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'أنت VIP — حتى ${_dateText(widget.session.vipUntil!)}',
                style: TextStyle(
                    color: t.text, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );

  /// المزايا — **بصورها لا بأسمائها**.
  Widget _perks(BeloteTheme t) {
    final gems = _plans!.isEmpty ? 50 : _plans!.first.monthlyDiamonds;
    return Column(
      children: [
        _perkImage(t, VipRoom.doorAsset, 'مجلسٌ خاصّ',
            'غرفتُك أنت وأصدقاؤك — لا يدخلها غريب.'),
        const SizedBox(height: 10),
        _perkGifts(t),
        const SizedBox(height: 10),
        _perkRow(t, Icons.all_inclusive, 'لعبٌ بلا حدود',
            'انسَ الخمسَ لعبات — العب ما شئت طوال اشتراكك.'),
        _perkRow(t, Icons.diamond, '$gems ماسةً كلَّ شهر',
            'تصلك دفعةً شهريّةً ما دام اشتراكُك قائمًا.'),
        _perkRow(t, Icons.workspace_premium, 'شارةُ VIP',
            'ترافق اسمَك أينما جلست.'),
      ],
    );
  }

  Widget _perkImage(BeloteTheme t, String asset, String title, String sub) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.line),
        ),
        child: Row(
          children: [
            Image.asset(asset, height: 78),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(sub, style: TextStyle(color: t.text3, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      );

  /// **الهدايا الحصريّة** — تُرى مصفوفةً: هي أكثرُ ما يُحسَد عليه.
  Widget _perkGifts(BeloteTheme t) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هدايا لا يملكها غيرُك',
                style: TextStyle(
                    color: t.text, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text('ثلاثٌ كلَّ يومٍ مجّانًا — تُرسلها فيراها كلُّ من على الطاولة.',
                style: TextStyle(color: t.text3, fontSize: 12.5)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final g in const [
                  'assets/VIP/gift_flower.png',
                  'assets/VIP/gift_box.png',
                  'assets/VIP/gift_pitcher.png',
                ])
                  Image.asset(g, height: 56),
              ],
            ),
          ],
        ),
      );

  Widget _perkRow(BeloteTheme t, IconData icon, String title, String sub) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Icon(icon, color: t.accentBright, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text(sub, style: TextStyle(color: t.text3, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _planRow(BeloteTheme t, VipPlanView p) {
    final busy = _busy == p.id;
    // **السنةُ أوفر — ويُقال بكم**: «أوفر» بلا رقمٍ دعوى.
    //
    // **يُبخَس لا يُبالَغ**: `100 − (2200×100 ÷ 6000)` يعطي **64%** والحقيقةُ 63.3
    // — لأنّ القسمةَ الصحيحةَ تبتر **المقسوم** فيكبر الفرق. وادّعاءُ خصمٍ أكبرَ من
    // الواقع كذبٌ يُقاس. الصيغةُ هنا تبتر **الوفرَ نفسَه** ⇒ 63، فيُبخَس ولا يُبالَغ.
    final monthly = _plans!.where((x) => !x.isYear).firstOrNull;
    final full = (monthly?.price ?? 0) * 12;
    final saved =
        (p.isYear && full > p.price) ? (full - p.price) * 100 ~/ full : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: p.isYear ? t.accent : t.line, width: p.isYear ? 1.4 : 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.isYear ? 'سنةٌ كاملة' : 'شهرٌ واحد',
                    style: TextStyle(
                        color: t.text, fontSize: 15, fontWeight: FontWeight.w800)),
                if (saved > 0)
                  Text('وفّر $saved% عن الشهريّ',
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
                backgroundColor: p.isYear ? t.accent : t.accent,
                foregroundColor: t.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              onPressed: _busy != null ? null : () => _subscribe(p),
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
                        // الأرقام لاتينيّةٌ دائمًا (CLAUDE.md)
                        Text('${p.price}', textDirection: TextDirection.ltr),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _dateText(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
