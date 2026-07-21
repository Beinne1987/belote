import 'package:flutter/widgets.dart';

import '../game/seat_player.dart';
import '../theme/belote_theme.dart';
import 'player_card_square.dart';

/// شاشة معاينة لبطاقة اللاعب المربّعة **وحدها** — الرتب الأربع في الحالتين (عاديّة
/// ونشطة) — لفحص التصميم قبل ربطه بالطاولة. عرضٌ محض، لا منطق لعب.
class PlayerCardGallery extends StatelessWidget {
  const PlayerCardGallery({super.key});

  static const _demo = <(PlayerRank, String, String)>[
    (PlayerRank.beginner, 'أحمدو', '🐣'),
    (PlayerRank.pro, 'المختار', '🎩'),
    (PlayerRank.expert, 'سيدي أحمد', '🦅'),
    (PlayerRank.legend, 'بَبَّه', '🦁'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return _Screen(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('بطاقة اللاعب',
                  style: TextStyle(
                      color: t.text, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('عاديّة · نشطة (صاحب الدور)',
                  style: TextStyle(color: t.text2, fontSize: 13)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 28,
                runSpacing: 28,
                alignment: WrapAlignment.center,
                children: [
                  for (final (rank, name, emoji) in _demo)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerCardSquare(name: name, emoji: emoji, rank: rank),
                        const SizedBox(height: 14),
                        PlayerCardSquare(
                            name: name, emoji: emoji, rank: rank, active: true),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// خلفيّة متدرّجة داكنة موحّدة للمعاينة.
class _Screen extends StatelessWidget {
  final Widget child;
  const _Screen({required this.child});
  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.gradTop, t.gradBottom],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
