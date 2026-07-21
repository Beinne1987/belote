import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';
import 'simple_top_bar.dart';

/// شاشة «كيف تلعب» — ملخّص قواعد بيلوت الموريتانية (من docs/RULES.md). عرضٌ محض.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  static const _sections = <(IconData, String, String)>[
    (
      Icons.groups,
      'الأساس',
      'أربعة لاعبين، فريقان (المقعدان 0 و2 ضدّ 1 و3). 32 ورقة (من 7 إلى الآس). '
          'اتجاه اللعب عكس عقارب الساعة — التالي هو من على يمينك.'
    ),
    (
      Icons.style,
      'التوزيع',
      'يوزَّع 3 ثم 2، ثم دور الضمانة، ثم 3 أخيرة (8 لكل لاعب). '
          'يمين الموزّع أوّل من يضمن ويلعب، وهو موزّع الجولة القادمة.'
    ),
    (
      Icons.campaign,
      'الضمانة',
      'دورة واحدة بالضبط (4 أدوار). اللاعب الأول لا يمرّ. الرفع فقط — لا فتح دورة جديدة بعد الرفع. '
          'اللون المضمون هو الحكم.'
    ),
    (
      Icons.flash_on,
      'الأكوينس',
      'للخصم فقط، في دوره فقط — يوقف الضمانة فورًا ويضاعف قيمة الجولة (32 للّون · 52 لصن/تو).'
    ),
    (
      Icons.rule,
      'اللعب',
      'إن ملكتَ لون الافتتاح فالْزَمه. إن لم تملكه فالعب أي ورقة — ولا تُجبر على القصّ بالحكم ولا على تجاوز أعلى حكم.'
    ),
    (
      Icons.calculate,
      'الوحدات',
      'في الحكم: J=20 و9=14. في اللون العادي: J=2 و9=0. الآس 11، العشرة 10، K=4، Q=3، و8/7 صفر. '
          'صن/تو: كل الألوان بسُلَّم الحكم.'
    ),
    (
      Icons.gavel,
      'الفوجة',
      'عدم اتباع اللون رغم امتلاكه. للخصم أن يعترض متى اكتشفها؛ إن ثبتت أخذ المعترِض قيمة الضمانة كاملة، '
          'وإن كان الاتهام خاطئًا أخذها الطرف الآخر. وتتوقف الجولة فورًا.'
    ),
    (
      Icons.emoji_events,
      'الفوز',
      'أوّل من يبلغ 100 نقطة والأعلى يفوز بالمباراة. عند التعادل عند 100 فأكثر تُلعب جولة فاصلة.'
    ),
  ];

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
              const SimpleTopBar(title: 'كيف تلعب'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [for (final s in _sections) _card(t, s)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BeloteTheme t, (IconData, String, String) s) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(s.$1, color: t.accent, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$2,
                      style: TextStyle(
                          color: t.text, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(s.$3,
                      style: TextStyle(color: t.text2, fontSize: 13.5, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      );
}
