import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/table_client.dart';
import '../theme/belote_theme.dart';
import 'player_avatar.dart';
import 'vip_room.dart';

/// **لوبي الطاولة الخاصّة — معروضًا كالطاولة.**
///
/// متطلّب المالك: «توزّع المقاعد بشكل طاولة اللعب بحيث يمكنك دعوة شخص إلى مقعد
/// معيّن — بهذه الطريقة يمكن اختيار الشريك والخصم.»
///
/// **الشكل هو الميزة**: قائمةٌ رأسيّة («مقعد ١ · مقعد ٢…») تُخفي ما يهمّ فعلًا —
/// مَن يقابلني (شريكي) ومَن يجاورني (خصماي). فالمقاعد تُرسَم كما تُرى على الطاولة:
/// أنا أسفل · شريكي مقابلي · خصماي يمينًا ويسارًا. الدعوةُ إلى موضعٍ **هي** اختيارُ
/// الدور، بلا شرحٍ ولا تسمية.
///
/// إحداثيّات **العرض** (0 = أنا) — الكنترولر يدوّرها عن الخادم بـ`you`.
class LobbyTable extends StatelessWidget {
  /// المقاعد بترتيب العرض 0..3 (null ⇒ فارغ).
  final List<LobbySeat?> seats;

  /// دعوةٌ إلى مقعد عرضٍ فارغ.
  final void Function(int viewSeat) onInvite;

  const LobbyTable({super.key, required this.seats, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        // مربّعٌ يتّسع لما أُعطي — الطاولة دائريّةٌ فلا معنى لنسبةٍ غير متساوية.
        final side = c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            // **الغرفةُ قبل الطاولة**: الطاولةُ الخاصّةُ مزيّةُ VIP («مجلسٌ
            // خاصّ»)، فمن ينتظر أصحابَه ينتظرهم في الغرفة نفسِها التي سيلعب
            // فيها — لا على تدرّجٍ محايدٍ لا مكانَ له.
            child: VipRoom.behind(
              dim: 0.45,
              child: Stack(
              children: [
                // جوخُ الطاولة — نفس تدرّج شاشة اللعب كي يعرف اللاعب أين هو.
                Center(
                  child: Container(
                    width: side * 0.62,
                    height: side * 0.62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [t.feltCenter, t.feltEdge]),
                      border: Border.all(color: t.line),
                    ),
                    child: Center(
                      child: Text('طاولتك',
                          style: TextStyle(
                              color: t.feltInk.withValues(alpha: 0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                _at(0, Alignment.bottomCenter, side), // أنا
                _at(1, Alignment.centerRight, side), // خصمي (يميني)
                _at(2, Alignment.topCenter, side), // شريكي (مقابلي)
                _at(3, Alignment.centerLeft, side), // خصمي (يساري)
              ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _at(int viewSeat, Alignment a, double side) => Align(
        alignment: a,
        child: _LobbySeatSlot(
          seat: viewSeat < seats.length ? seats[viewSeat] : null,
          isMe: viewSeat == 0,
          isPartner: viewSeat == 2,
          size: side * 0.30,
          onInvite: () => onInvite(viewSeat),
        ),
      );
}

class _LobbySeatSlot extends StatelessWidget {
  final LobbySeat? seat;
  final bool isMe;
  final bool isPartner;
  final double size;
  final VoidCallback onInvite;

  const _LobbySeatSlot({
    required this.seat,
    required this.isMe,
    required this.isPartner,
    required this.size,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final s = seat;
    final taken = s != null && !s.ai;
    // دورُه يُسمّى صراحةً: «شريكك» و«خصمك» هما ما يقرّره المقعد.
    final role = isMe ? 'أنت' : (isPartner ? 'شريكك' : 'خصمك');

    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(role,
              style: TextStyle(
                  color: isPartner ? t.accentBright : t.text3,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          if (taken)
            _filled(t, s.name?.trim().isNotEmpty == true ? s.name! : 'لاعب',
                s.avatarUrl, s.isVip)
          else
            _empty(t),
        ],
      ),
    );
  }

  /// **VIP يُرى هنا أيضًا** (نصُّ المالك: «لاعبُ VIP تظهر له في كلّ مكان»): حدٌّ
  /// ذهبيٌّ وشارةٌ — الغرفةُ أوّلُ ما يراه زملاؤه قبل أن تبدأ المباراة.
  Widget _filled(BeloteTheme t, String name, String avatarUrl, bool isVip) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isVip ? t.accent : (isMe ? t.accent : t.line),
              width: (isVip || isMe) ? 2 : 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // بلا صورة ⇒ أوّل حرفٍ من اسمه، لا أيقونةُ الشخص العامّة: الحرف يميّز
            // الجالسين بعضَهم من بعض، والأيقونة تجعلهم أربعةَ أشباحٍ متطابقة.
            // **الإطارُ الدائريُّ للّوبي** (نصُّ المالك 2026-07-16: «الإطارُ الآخر
            // دائريٌّ يناسب اللوبي والملفّ الشخصيّ»). وسطُه شفّافٌ فتظهر الصورةُ
            // خلاله، وهو أكبرُ منها ليحيط لا ليغطّي.
            isVip
                ? SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PlayerAvatar(
                          url: avatarUrl,
                          fallback: name.characters.first,
                          size: 28,
                          borderColor: const Color(0x00000000),
                        ),
                        IgnorePointer(
                          child: Image.asset('assets/VIP/frame_gold_round.png',
                              width: 44, height: 44),
                        ),
                      ],
                    ),
                  )
                : PlayerAvatar(
                    url: avatarUrl,
                    fallback: name.characters.first,
                    size: 30,
                    borderColor: t.line,
                  ),
            if (isVip) ...[
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: t.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('VIP',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                        color: t.onAccent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900)),
              ),
            ],
            const SizedBox(height: 4),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.text, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  /// مقعدٌ فارغ: **زرُّ دعوةٍ لا لافتةُ انتظار**. الفراغ هنا فعلٌ متاحٌ لا خبر.
  Widget _empty(BeloteTheme t) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onInvite,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.lineStrong, style: BorderStyle.solid),
              color: t.surface.withValues(alpha: 0.35),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_alt, color: t.text3, size: 22),
                const SizedBox(height: 4),
                Text('ادعُ',
                    style: TextStyle(
                        color: t.text2, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
}

/// منتقي الصديق لمقعدٍ بعينه.
///
/// **كلُّهم قابلون للدعوة — متّصلين وغيرَ متّصلين.** كان غيرُ المتّصل معطَّلًا لأنّ
/// الدعوة لم تكن تُسلَّم إلّا عبر القناة الحيّة؛ ثمّ صارت تصل إشعارًا إلى الهاتف
/// (`NotificationService.inviteToTable`) ⇒ تعطيلُه اليوم منعٌ بلا سبب.
///
/// والنقطةُ تبقى: **من هو متّصلٌ الآن يُقدَّم** ويُقال لمن ليس كذلك أنّ دعوته
/// ستصله إشعارًا — فيعرف الداعي أنّ الردّ قد يتأخّر، ولا يظنّ صمتَه تجاهلًا.
///
/// [seatRole] **بلا علامة استفهام** — القالب يضيفها.
Future<FriendPlayer?> pickFriendForSeat(
  BuildContext context, {
  required List<FriendPlayer> friends,
  required String seatRole,
}) {
  final t = BeloteTheme.of(context);
  final online = [for (final f in friends) if (f.online) f];
  final offline = [for (final f in friends) if (!f.online) f];

  return showModalBottomSheet<FriendPlayer>(
    context: context,
    backgroundColor: t.gradBottom,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: t.accentBright),
                const SizedBox(width: 8),
                Text('من يجلس $seatRole؟',
                    style: TextStyle(
                        color: t.text, fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 12),
            if (friends.isEmpty)
              _note(t, 'لا أصدقاء بعد. أضِف صاحبك برمزه من شاشة الأصدقاء.')
            else if (online.isEmpty)
              _note(t, 'لا صديق متّصلٌ الآن — ادعُه على أيّ حال، يصله إشعارٌ على هاتفه.'),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final f in online) _row(ctx, t, f),
                  if (offline.isNotEmpty && online.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('غير متّصلين',
                        style: TextStyle(color: t.text3, fontSize: 12)),
                    const SizedBox(height: 6),
                  ],
                  for (final f in offline) _row(ctx, t, f),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _note(BeloteTheme t, String msg) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(msg, style: TextStyle(color: t.text2, fontSize: 13, height: 1.5)),
    );

Widget _row(BuildContext ctx, BeloteTheme t, FriendPlayer f) {
  final name = f.displayName.trim().isEmpty ? 'لاعب' : f.displayName;
  return ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: () => Navigator.pop(ctx, f),
    leading: PlayerAvatar(
      url: f.avatarUrl,
      fallback: name.characters.first,
      size: 40,
      borderColor: f.online ? t.success : t.surface2,
    ),
    title: Text(name,
        style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 14)),
    // **ما يقع لا ما هو**: «غير متصل» وصفٌ يترك الداعي حائرًا أيدعوه أم لا؛
    // «يصله إشعار» جوابٌ عن سؤاله.
    subtitle: Text(f.online ? 'متصل' : 'غير متصل — يصله إشعار',
        style: TextStyle(
            color: f.online ? t.success : t.text3, fontSize: 12)),
    trailing: Icon(Icons.send, color: f.online ? t.accent : t.text3, size: 18),
  );
}
