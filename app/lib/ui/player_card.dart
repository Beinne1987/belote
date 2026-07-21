import 'package:flutter/material.dart';

import '../game/seat_player.dart';
import '../theme/belote_theme.dart';

/// بطاقة لاعبٍ على الطاولة: صورة رمزيّة + اسم + تصنيف + مستوى + شارة VIP + مؤشّر
/// اتصال، مع توهّجٍ حين يكون الدور له وشارة الموزّع. عرضٌ محض — لا تعرف قاعدة.
/// بديلٌ أغنى لـ`SeatTag` في مكانه نفسه (نفس مواضع المقاعد).
class PlayerCard extends StatelessWidget {
  final SeatPlayer player;
  final Color teamColor;
  final bool active;
  final bool dealer;

  /// إظهار أيقونة كتم/تخفيف صوت هذا اللاعب (لغير نفسك) — تصميمٌ، تُربَط بـLiveKit لاحقًا.
  final bool showMute;

  const PlayerCard({
    super.key,
    required this.player,
    required this.teamColor,
    this.active = false,
    this.dealer = false,
    this.showMute = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final initial = player.name.trim().isEmpty ? '?' : player.name.characters.first;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: active ? 0.58 : 0.34),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: active ? t.accentBright : Colors.white24,
          width: active ? 1.8 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: t.accentBright.withValues(alpha: 0.5), blurRadius: 12)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _avatar(t, initial),
          const SizedBox(width: 7),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (player.isVip) ...[
                    Icon(Icons.workspace_premium, size: 12, color: t.accentBright),
                    const SizedBox(width: 3),
                  ],
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 116),
                    child: Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.feltInk, fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (dealer) ...[
                    const SizedBox(width: 5),
                    _dealerBadge(t),
                  ],
                ],
              ),
              const SizedBox(height: 1),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: player.connected ? t.success : t.text3,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  if (player.rating != null) ...[
                    Icon(Icons.military_tech, size: 11, color: teamColor),
                    const SizedBox(width: 2),
                    Text('${player.rating}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                            color: t.feltInk2, fontSize: 10.5, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                  ],
                  Text('Lv ${player.level}',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(color: t.feltInk2, fontSize: 10)),
                ],
              ),
            ],
          ),
          if (showMute) ...[
            const SizedBox(width: 4),
            _MuteToggle(color: teamColor),
          ],
        ],
      ),
    );
  }

  Widget _avatar(BeloteTheme t, String initial) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.surface2,
          border: Border.all(color: active ? t.accentBright : teamColor, width: 2),
        ),
        child: Text(initial,
            style: TextStyle(
                color: t.accentBright, fontWeight: FontWeight.w800, fontSize: 15)),
      );

  Widget _dealerBadge(BeloteTheme t) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: t.accent.withValues(alpha: 0.22),
          shape: BoxShape.circle,
          border: Border.all(color: t.accent, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.style, size: 9, color: t.accent),
      );
}

/// أيقونة كتم صوت لاعبٍ على بطاقته (تصميم — لا صوت فعليّ بعد).
class _MuteToggle extends StatefulWidget {
  final Color color;
  const _MuteToggle({required this.color});
  @override
  State<_MuteToggle> createState() => _MuteToggleState();
}

class _MuteToggleState extends State<_MuteToggle> {
  bool _muted = false;
  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return InkWell(
      onTap: () => setState(() => _muted = !_muted),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
          _muted ? Icons.volume_off : Icons.volume_up,
          size: 16,
          color: _muted ? t.error : t.feltInk2,
        ),
      ),
    );
  }
}
