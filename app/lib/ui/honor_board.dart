import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../theme/belote_theme.dart';
import 'honor_badge.dart';
import 'player_avatar.dart';

/// **لوحةُ الشرف الأسبوعيّة** — قسمٌ في الرئيسيّة يفتح شاشةً كاملة.
///
/// التصميمُ يخدم غايتَه: **أن يُرى الفائزُ فيُحسَد**. فالملكُ وحدَه في منصّةٍ عريضة
/// بصورته الكبيرة وتاجِه، والفئاتُ الأربعُ الباقية صفٌّ من بطاقاتٍ تحته. مصفوفةٌ
/// من خمسةِ صفوفٍ متساوية كانت ستجعل الجميع سواءً، ولا أحدَ يتنافس على «سواء».
///
/// **لا قسمَ بلا فائز**: أسبوعٌ لم يلعب فيه أحدٌ ⇒ اللوحةُ تختفي من الرئيسيّة بدل
/// أن تعرض خمسةَ صناديقَ فارغة ([[gift-button-visibility]]: أداةٌ بلا معنًى تُخفى).
class HonorBoardSection extends StatelessWidget {
  final HonorsBoard board;

  const HonorBoardSection({super.key, required this.board});

  /// الفئاتُ التي لها فائزٌ فعلًا — عليها يقوم القرارُ بالعرض أو الإخفاء.
  List<HonorCategoryBoard> get _live =>
      [for (final c in board.categories) if (c.entries.isNotEmpty) c];

  @override
  Widget build(BuildContext context) {
    final live = _live;
    if (live.isEmpty) return const SizedBox.shrink();
    final t = BeloteTheme.of(context);
    // الملكُ أوّلُ الفئات من الخادم — فإن لم يتأهّل أحدٌ له تصدّرت أوّلُ فئةٍ حيّة.
    final head = live.first;
    final rest = live.skip(1).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.surface2, t.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.accent.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(color: t.accent.withValues(alpha: 0.10), blurRadius: 18),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'لوحة الشرف — هذا الأسبوع',
                  style: TextStyle(
                      color: t.text, fontSize: 15.5, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HonorBoardScreen(board: board))),
                child: Text('الكلّ', style: TextStyle(color: t.accentBright)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _Champion(category: head),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 106,
              // **يمرّر أفقيًّا لا يُكدَّس**: أربعُ بطاقاتٍ على عرض هاتفٍ ضيّق
              // تصير أعمدةً لا تُقرأ؛ والتمريرُ يُبقي حجمَ البطاقة كما صُمِّم.
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rest.length,
                separatorBuilder: (_, __) => const SizedBox(width: 9),
                itemBuilder: (_, i) => _CategoryTile(category: rest[i]),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'الأوّلُ في كلّ فئةٍ يحمل لقبَها طوال الأسبوع القادم — يراه كلُّ من يجلس معه.',
            style: TextStyle(color: t.text3, fontSize: 11.5, height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// المتصدّر: صورةٌ كبيرةٌ في إطارٍ ذهبيّ، اللقبُ فوق الاسم، والرقمُ إلى جانبه.
class _Champion extends StatelessWidget {
  final HonorCategoryBoard category;
  const _Champion({required this.category});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final w = category.entries.first;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          PlayerAvatar(
            url: w.avatarUrl,
            fallback: w.name.isEmpty ? '؟' : w.name.characters.first,
            size: 56,
            borderColor: t.accent,
            borderWidth: 2,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                HonorBadge(category: category, size: 14, showText: true),
                const SizedBox(height: 5),
                Text(
                  w.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: t.text, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                Text(
                  '${w.value} ${category.unit}',
                  // **لاتينيّةٌ دائمًا** ([[latin-digits-ui]]) — لا `toLocaleString`.
                  style: TextStyle(color: t.text2, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// فئةٌ مختصرة: عنوانُها، ثمّ صورةُ الأوّل واسمُه ورقمُه.
class _CategoryTile extends StatelessWidget {
  final HonorCategoryBoard category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final w = category.entries.first;
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: t.text2, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              PlayerAvatar(
                url: w.avatarUrl,
                fallback: w.name.isEmpty ? '؟' : w.name.characters.first,
                size: 30,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      w.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800),
                    ),
                    Text('${w.value} ${category.unit}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: t.text3, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// الشاشةُ الكاملة: الفئاتُ الخمسُ وأوائلُها الثلاثة.
class HonorBoardScreen extends StatelessWidget {
  final HonorsBoard board;
  const HonorBoardScreen({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final live = [
      for (final c in board.categories)
        if (c.entries.isNotEmpty) c
    ];
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.text,
        title: const Text('لوحة الشرف'),
      ),
      body: live.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'لم يبدأ أحدٌ المنافسةَ هذا الأسبوع بعد.\nأوّلُ من يلعب يتصدّر.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.text2, fontSize: 14, height: 1.5),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: live.length,
              itemBuilder: (_, i) => _FullCategory(category: live[i]),
            ),
    );
  }
}

class _FullCategory extends StatelessWidget {
  final HonorCategoryBoard category;
  const _FullCategory({required this.category});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HonorBadge(category: category, size: 13, showText: true),
              const SizedBox(width: 8),
              Text(category.label,
                  style: TextStyle(
                      color: t.text2,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in category.entries) _Row(entry: e, unit: category.unit),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final HonorRow entry;
  final String unit;
  const _Row({required this.entry, required this.unit});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    // **الأوّلُ ذهبيٌّ بارز**: منصّةٌ لا قائمة — الفرقُ بين الأوّل والثاني يجب أن يُرى.
    final gold = entry.rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: gold ? t.accentBright : t.text3,
                fontSize: gold ? 15 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          PlayerAvatar(
            url: entry.avatarUrl,
            fallback: entry.name.isEmpty ? '؟' : entry.name.characters.first,
            size: gold ? 38 : 30,
            borderColor: gold ? t.accent : null,
            borderWidth: gold ? 2 : 1,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.text,
                fontSize: gold ? 14.5 : 13,
                fontWeight: gold ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${entry.value} $unit',
            style: TextStyle(
                color: gold ? t.accentBright : t.text2,
                fontSize: 12.5,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
