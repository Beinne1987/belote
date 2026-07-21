import 'package:app/game/seat_player.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/player_seat_round.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// أزرارُ المقعد: هديّةٌ وكتمٌ لغيري، وميكروفونٌ وهديّةٌ للجميع لمقعدي.
Widget _wrap(Widget child) => ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );

void main() {
  testWidgets('مقعدُ لاعبٍ آخر ⇒ هديّةٌ وكتم، بلا ميكروفون', (t) async {
    var gifts = 0, mutes = 0;
    await t.pumpWidget(_wrap(PlayerSeatRound(
      name: 'سالم',
      emoji: '😎',
      rank: PlayerRank.pro,
      onGift: () => gifts++,
      onMute: () => mutes++,
    )));

    expect(find.byIcon(Icons.mic), findsNothing, reason: 'الميكروفونُ لمقعدي وحدي');
    await t.tap(find.byIcon(Icons.redeem));
    await t.tap(find.byIcon(Icons.volume_up));
    expect((gifts, mutes), (1, 1));
  });

  testWidgets('الكتمُ يُقرأ من شكل الزرّ', (t) async {
    await t.pumpWidget(_wrap(PlayerSeatRound(
      name: 'سالم',
      emoji: '😎',
      rank: PlayerRank.pro,
      onMute: () {},
      muted: true,
    )));
    expect(find.byIcon(Icons.volume_off), findsOneWidget);
    expect(find.byIcon(Icons.volume_up), findsNothing);
  });

  testWidgets('مقعدي ⇒ ميكروفونٌ وهديّةٌ للجميع، بلا كتم', (t) async {
    var mics = 0;
    await t.pumpWidget(_wrap(PlayerSeatRound(
      name: 'أنا',
      emoji: '🙂',
      rank: PlayerRank.expert,
      mine: true,
      onMic: () => mics++,
      voiceState: SeatVoice.live,
      onGift: () {},
      // يُمرَّر ويُتجاهَل: لا أكتم نفسي.
      onMute: () {},
    )));

    expect(find.byIcon(Icons.volume_up), findsNothing);
    expect(find.byIcon(Icons.redeem), findsOneWidget);
    await t.tap(find.byIcon(Icons.mic));
    expect(mics, 1);
  });

  /// **العطبُ الذي أسقط اللوحة** (لاحظه المالك 2026-07-20): كان الزرُّ يقرأ `micOn`
  /// وابتداؤها `true`، فيفتح اللاعبُ الطاولةَ فيرى ميكروفونًا **أخضرَ مفتوحًا**
  /// والصوتُ مقطوعٌ أصلًا (لا غرفةَ ولا إذنَ ميكروفون). الحالُ الآن من الاتّصال
  /// نفسِه: لا خُضرةَ إلّا و`VoiceStatus.live`.
  testWidgets('الحالُ الابتدائيّ مقطوعٌ ⇒ أيقونةٌ مشطوبةٌ لا خضراءُ كاذبة', (t) async {
    await t.pumpWidget(_wrap(PlayerSeatRound(
      name: 'أنا',
      emoji: '🙂',
      rank: PlayerRank.pro,
      mine: true,
      onMic: () {},
    )));
    expect(find.byIcon(Icons.mic_off), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);
  });

  testWidgets('كلُّ حالٍ أيقونتُها: يتّصل · حيٌّ · تعذّر', (t) async {
    for (final (state, icon) in [
      (SeatVoice.connecting, Icons.mic_none),
      (SeatVoice.live, Icons.mic),
      (SeatVoice.failed, Icons.mic_off),
    ]) {
      await t.pumpWidget(_wrap(PlayerSeatRound(
        name: 'أنا',
        emoji: '🙂',
        rank: PlayerRank.pro,
        mine: true,
        onMic: () {},
        voiceState: state,
      )));
      expect(find.byIcon(icon), findsOneWidget, reason: '$state');
    }
  });

  testWidgets('الاسمُ فوق الصورة لا تحتها', (t) async {
    await t.pumpWidget(_wrap(const PlayerSeatRound(
      name: 'مريم',
      emoji: '💃',
      rank: PlayerRank.legend,
    )));
    final name = t.getCenter(find.text('مريم'));
    final avatar = t.getCenter(find.text('💃'));
    expect(name.dy, lessThan(avatar.dy));
  });
}
