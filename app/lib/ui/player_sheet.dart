import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../theme/belote_theme.dart';
import 'rank_badge.dart';
import 'player_avatar.dart';
import 'honor_badge.dart';
import 'player_tag_chip.dart';

/// **لوحةُ لاعبٍ على الطاولة** — تُفتَح بالضغط على بطاقته: مَن هو، وكم تصنيفُه،
/// وهل تصادقه.
///
/// **تُفتَح فورًا وتُحمّل داخلها**: انتظارُ الشبكة قبل الفتح يجعل الضغطةَ تبدو
/// ضائعة، فيضغط اللاعبُ ثانيةً وثالثة. تفتح اللوحةُ باسمه وصورته (نعرفهما من
/// الطاولة) ثمّ يملأ الباقي متى وصل.
///
/// **لا تُفتَح لذكاءٍ ولا لمقعدٍ فارغ** — المُنادي يفحص `playerId` قبل النداء:
/// لوحةُ ملفٍّ لروبوتٍ وعدٌ كاذب.
Future<void> showPlayerSheet(
  BuildContext context, {
  required ApiClient api,
  required String token,
  required String playerId,

  /// ما نعرفه من الطاولة — يُعرَض ريثما يصل الملفّ.
  required String name,
  String avatarUrl = '',

  /// يفتح لوحةَ الهدايا على هذا اللاعب. null ⇒ لا يُعرَض الزرّ (أوفلاين/مشاهد
  /// بلا إذن) — **أداةٌ بلا مُعالِجٍ تُخفى**.
  final VoidCallback? onGift,

  /// كتمُ صوته / رفعُه. null ⇒ الصوت مُطفأٌ أو غيرُ متاح ⇒ لا يُعرَض الزرّ.
  /// **الكتمُ هنا لا في لوحةٍ أخرى**: من يزعجك تراه أمامك على الطاولة، فيدُك
  /// تذهب إلى بطاقته لا إلى قائمةٍ تبحث فيها عن اسمه.
  final bool Function()? isMuted,
  final VoidCallback? onToggleMute,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BeloteTheme.of(context).gradBottom,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PlayerSheet(
        api: api,
        token: token,
        playerId: playerId,
        name: name,
        avatarUrl: avatarUrl,
        onGift: onGift,
        isMuted: isMuted,
        onToggleMute: onToggleMute,
      ),
    );

class _PlayerSheet extends StatefulWidget {
  final ApiClient api;
  final String token;
  final String playerId;
  final String name;
  final String avatarUrl;
  final VoidCallback? onGift;
  final bool Function()? isMuted;
  final VoidCallback? onToggleMute;

  const _PlayerSheet({
    required this.api,
    required this.token,
    required this.playerId,
    required this.name,
    required this.avatarUrl,
    this.onGift,
    this.isMuted,
    this.onToggleMute,
  });

  @override
  State<_PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<_PlayerSheet> {
  PublicPlayer? _player;
  String? _error;
  bool _busy = false;

  /// حالةُ الصداقة المحلّيّة بعد فعلٍ ناجح — كي يتغيّر الزرّ فورًا بلا إعادة جلب.
  String? _friendship;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await widget.api.playerProfile(widget.token, widget.playerId);
      if (mounted) setState(() => _player = p);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _act(Future<void> Function() run, String nextState) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await run();
      if (mounted) setState(() => _friendship = nextState);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final p = _player;
    final rel = _friendship ?? p?.friendship ?? 'none';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                PlayerAvatar(
                  url: p?.avatarUrl ?? widget.avatarUrl,
                  fallback: widget.name.characters.first,
                  size: 56,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p?.displayName.isNotEmpty ?? false
                                  ? p!.displayName
                                  : widget.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (p?.isVip ?? false) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.workspace_premium,
                                size: 18, color: t.accent),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // **الرمزُ المعروض لا المعرّف الداخليّ** — به يُضيفه أصحابُه.
                      if (p != null && p.tag.isNotEmpty)
                        PlayerTagChip(tag: p.tag)
                      else
                        Text('…', style: TextStyle(color: t.text3)),
                      // ألقابُ أسبوعه كلُّها — كملفّي سواء ([[honors-weekly]]).
                      if (p != null) ...[
                        const SizedBox(height: 6),
                        AllHonorBadges(playerId: p.id),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // **الأرقام لاتينيّةٌ دائمًا** (قاعدة المشروع).
            if (p != null && p.stats.skill != null) ...[
              // رتبتُه باسمها قبل الأرقام — «محترف» يُقرأ قبل أن يُقرَأ 1287.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: RankBadge(rank: p.stats.skill, size: 13, showUnplaced: true),
              ),
              const SizedBox(height: 12),
            ],
            if (p != null)
              Row(
                children: [
                  _stat(t, 'التصنيف', '${p.stats.rating}'),
                  _stat(t, 'المباريات', '${p.stats.matches}'),
                  _stat(t, 'الفوز', '${p.stats.winRatePct}%'),
                ],
              )
            else if (_error == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: t.accent),
                ),
              ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.error, fontSize: 13)),
            ],

            const SizedBox(height: 18),

            // **الكتمُ لا ينتظر الشبكة**: إزعاجٌ يقع الآن، وزرُّه يجب أن يعمل
            // ولو تعثّر جلبُ الملفّ. فهو خارج شرط `p != null` عمدًا.
            if (widget.onToggleMute != null) ...[
              _muteButton(t),
              const SizedBox(height: 10),
            ],

            // **لا أزرارَ على نفسي**: «أضِف صديقًا» على ملفّي عبثٌ يُربك.
            if (p != null && !p.isMe) ...[
              _friendButton(t, rel),
              if (widget.onGift != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          widget.onGift!();
                        },
                  icon: Icon(Icons.card_giftcard, color: t.accentBright),
                  label: Text('أهدِه',
                      style: TextStyle(
                          color: t.text, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    side: BorderSide(color: t.line),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// كتمُ صوته على هذه الطاولة — محلّيٌّ لجهازك، لا يعلمه هو ولا يُبلَّغ به.
  Widget _muteButton(BeloteTheme t) {
    final muted = widget.isMuted?.call() ?? false;
    return OutlinedButton.icon(
      onPressed: () {
        widget.onToggleMute!();
        setState(() {}); // الأيقونةُ تنقلب فورًا
      },
      icon: Icon(muted ? Icons.volume_off : Icons.volume_up,
          color: muted ? t.error : t.text2),
      label: Text(muted ? 'إلغاء كتم ${widget.name}' : 'اكتم ${widget.name}',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: muted ? t.error : t.text, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        side: BorderSide(color: muted ? t.error : t.line),
      ),
    );
  }

  /// الزرُّ يتبع حالةَ العلاقة — أربعُ حالاتٍ لا زرٌّ واحدٌ يكذب.
  Widget _friendButton(BeloteTheme t, String rel) {
    final (label, icon, onTap) = switch (rel) {
      'friends' => ('صديقك', Icons.how_to_reg, null),
      'outgoing' => ('بانتظار ردّه', Icons.hourglass_empty, null),
      'incoming' => (
          'اقبل صداقته',
          Icons.person_add_alt_1,
          () => _act(
              () => widget.api.acceptFriend(widget.token, widget.playerId),
              'friends'),
        ),
      _ => (
          'أضِف صديقًا',
          Icons.person_add_alt_1,
          () => _act(
              () => widget.api
                  .requestFriendById(widget.token, widget.playerId)
                  .then((_) {}),
              'outgoing'),
        ),
    };

    return FilledButton.icon(
      onPressed: (_busy || onTap == null) ? null : onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        disabledBackgroundColor: t.surface2,
        disabledForegroundColor: t.text3,
      ),
    );
  }

  Widget _stat(BeloteTheme t, String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value,
                // الأرقام لاتينيّةٌ دائمًا، و`ltr` يمنع النسبة من الانقلاب.
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    color: t.accentBright,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: t.text2, fontSize: 12)),
          ],
        ),
      );
}
