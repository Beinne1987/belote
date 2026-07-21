import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';

/// **عرضُ «افتح يومًا كاملًا»** — يظهر حين تنفد لعباتُ اليوم (طلبُ المالك 2026-07-16:
/// «عند انتهاء لعبات اللاعب الخمس أظهر له رسالة منبثقة تعرض عليه تفعيل اللعب 24 ساعة،
/// وتكون فيها زرّ يقود إلى مكان الدفع»).
///
/// **يبيع رغبةً لا يرفع عقوبة** ([[conversion-strategy]]): «انتهت لعباتُك» عقابٌ
/// يُغلق البابَ، و«افتح يومًا كاملًا مع أصدقائك» دعوةٌ تفتحه. نفسُ الشيء، ونتيجةٌ
/// مختلفة — لذلك العنوانُ عرضٌ والخبرُ تحته.
///
/// **ولا يكذب**: يقول إنّ الأوفلاين حرٌّ ومتى تعود لعباتُه. لاعبٌ يُحاصَر بلا مخرجٍ
/// يحذف التطبيق، ولا يشتري.
///
/// يُعيد `true` إن اشترى ⇒ يمضي المُنادي إلى اللعب فورًا (لا يُعيده إلى نقطة الصفر
/// بعد أن دفع).
Future<bool> showPlayLimitOffer(
  BuildContext context, {
  required SessionController session,

  /// يفتح المتجرَ — يُنادى حين لا يكفي ماسُه.
  required VoidCallback onStore,
}) async {
  final bought = await showDialog<bool>(
    context: context,
    builder: (_) => _PlayLimitOffer(session: session, onStore: onStore),
  );
  return bought ?? false;
}

class _PlayLimitOffer extends StatefulWidget {
  const _PlayLimitOffer({required this.session, required this.onStore});

  final SessionController session;
  final VoidCallback onStore;

  @override
  State<_PlayLimitOffer> createState() => _PlayLimitOfferState();
}

class _PlayLimitOfferState extends State<_PlayLimitOffer> {
  TicketView? _day;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await widget.session.api.tickets();
      // **تذكرةُ اليوم وحدَها هنا**: عرضٌ واحدٌ يُقرَّر في ثانية. سلّمُ التذاكر كلُّه
      // في المتجر لمن أراد الأسبوع.
      final day = all.where((t) => t.hours == 24).firstOrNull;
      if (mounted) setState(() => _day = day);
    } catch (_) {
      // تعذّر الجلبُ ⇒ لا عرضَ ولا ثمنٌ مخترَع؛ تبقى الرسالةُ خبرًا صادقًا.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// **يستلم الهديّة** — أوّلُ نفادٍ في العمر. بلا ثمنٍ فبلا 402.
  Future<void> _claimTrial() async {
    setState(() => _busy = true);
    try {
      await widget.session.claimTrial();
      if (!mounted) return;
      Navigator.pop(context, true); // نالها ⇒ يمضي إلى اللعب فورًا
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      // 409 ⇒ نالها من جهازٍ آخرَ سلفًا: أعِد الرسمَ بالشراء بدل «تعذّر».
      if (e.status == 409) {
        await widget.session.refreshPlayLimit();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الاستلام — حاول ثانيةً')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذّر الاتّصال')));
    }
  }

  Future<void> _buy(TicketView k) async {
    setState(() => _busy = true);
    try {
      await widget.session.buyTicket(k.id);
      if (!mounted) return;
      Navigator.pop(context, true); // اشترى ⇒ يمضي إلى اللعب
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 402) {
        // **يقود إلى مكان الدفع** (نصُّ المالك): ينقصه ماسٌ ⇒ المتجر.
        Navigator.pop(context, false);
        widget.onStore();
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر التفعيل — حاول ثانيةً')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذّر الاتّصال')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final k = _day;
    // **أوّلُ نفادٍ في العمر ⇒ هديّةٌ لا فاتورة** ([[conversion-strategy]]): يذوق
    // «بلا حدود» مرّةً فيعرف في الثانية *ما* يشتري — لا يشتري وصفًا.
    final gift = widget.session.allowance?.trialAvailable ?? false;
    return AlertDialog(
      backgroundColor: t.surface,
      title: Row(
        children: [
          Icon(gift ? Icons.card_giftcard : Icons.all_inclusive,
              color: gift ? t.premium : t.accentBright, size: 22),
          const SizedBox(width: 8),
          // **العنوانُ عرضٌ لا نعي**: يبيع ما يريده لا يُعلن ما فقده.
          Expanded(
            child: Text(gift ? 'هديّةٌ منّا: يومٌ كامل' : 'افتح يومًا كاملًا',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                    color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            gift
                ? 'انتهت لعباتُك الخمسُ اليوم — وهذه أوّلُ مرّة. خذ 24 ساعةً بلا '
                    'حدودٍ منّا، والعب ما شئت مع أصدقائك.'
                : k == null
                    ? 'انتهت لعباتُك اليوم — تعود غدًا.'
                    : 'انتهت لعباتُك الخمسُ اليوم. فعّل اللعب بلا حدودٍ 24 ساعةً '
                        'والعب ما شئت مع أصدقائك.',
            textDirection: TextDirection.rtl,
            style: TextStyle(color: t.text2, fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 10),
          // **لا يُحاصَر بلا مخرج**: الأوفلاين حرٌّ بلا حدّ — وهو المخرجُ الصادقُ
          // لمن لا يدفع اليوم.
          Text('واللعبُ مع الذكاء يبقى مجّانيًّا بلا حدود.',
              textDirection: TextDirection.rtl,
              style: TextStyle(color: t.text3, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('لاحقًا'),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        // **الهديّةُ لا تنتظر السلّم**: بلا ثمنٍ فلا حاجةَ إلى `/store/tickets`
        // — تُعرَض ولو تعذّر جلبُه.
        else if (gift)
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: t.premium, foregroundColor: t.onAccent),
            onPressed: _busy ? null : _claimTrial,
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('استلم الهديّة'),
          )
        else if (k != null)
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: t.accent, foregroundColor: t.onAccent),
            onPressed: _busy ? null : () => _buy(k),
            child: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('فعّل الآن'),
                      const SizedBox(width: 6),
                      const Icon(Icons.diamond, size: 14),
                      const SizedBox(width: 3),
                      // الأرقام لاتينيّةٌ دائمًا (CLAUDE.md)
                      Text('${k.price}', textDirection: TextDirection.ltr),
                    ],
                  ),
          ),
      ],
    );
  }
}
