import 'dart:async';

import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart' hide Card;

import '../../game/seat_player.dart';
import '../../game/view_model.dart';
import '../../net/api_client.dart';
import '../../theme/theme_manager.dart';
import '../../ui/gift_picker.dart';
import '../../ui/gifts/gift_flight.dart';
import '../../ui/table_screen.dart';
import '../../voice/voice_controller.dart';
import 'phone_preview.dart';

/// **معاينةُ شاشة اللعب الحقيقيّة** داخل إطار هاتف — **تفاعليّةٌ لا صورة**.
///
/// تبني `TableScreen` **نفسَها** (الودجت التي تعمل في التطبيق) وتُشغّلها بحالةٍ
/// محلّيّةٍ صغيرة: اللمسُ يلعب الورقةَ فتغادر يدَك إلى الطاولة، والهديّةُ تطير من
/// مقعدٍ إلى مقعد. لا خادمَ ولا حساب — المنطقُ وحدَه مُصطنَع.
///
/// **لماذا تفاعليّة:** معاينةٌ ساكنةٌ لا تُثبت أنّ اللمسَ يصل؛ والمالكُ يجرّب
/// اللعبَ والإهداءَ بنفسه قبل أن يُبنى APK.
class RealTablePreview extends StatefulWidget {
  const RealTablePreview({super.key});

  @override
  State<RealTablePreview> createState() => _RealTablePreviewState();
}

class _RealTablePreviewState extends State<RealTablePreview> {
  static const _fullHand = [
    Card('pique', 'A'),
    Card('pique', '10'),
    Card('coeur', 'K'),
    Card('coeur', 'Q'),
    Card('carreau', 'J'),
    Card('carreau', '9'),
    Card('trefle', 'A'),
    Card('trefle', '8'),
  ];

  // الرتبةُ تُشتقّ من التصنيف (`SeatPlayer.rank`) — تصنيفاتٌ تُعطي الأربع.
  static const _seats = [
    SeatPlayer(name: 'أنت', emoji: '🙂', rating: 1000, playerId: 'me'),
    SeatPlayer(
        name: 'سالم', emoji: '😎', rating: 1220, playerId: 'p1', isVip: true),
    SeatPlayer(name: 'مريم', emoji: '💃', rating: 1460, playerId: 'p2'),
    SeatPlayer(name: 'خالد', emoji: '🧔', rating: 880, playerId: 'p3'),
  ];

  bool _vip = false;
  List<Card> _hand = List.of(_fullHand);
  List<Play> _trick = const [
    (seat: 2, card: Card('trefle', 'K')),
    (seat: 3, card: Card('trefle', '9')),
  ];

  /// الهديّةُ الطائرةُ الآن + طابورُ ما ينتظر (هديّةُ «الجميع» ثلاثُ رحلات).
  GiftFlight? _flight;
  final _queue = <GiftFlight>[];
  Timer? _timer;

  /// الفقاعاتُ فوق المقاعد — كما تفعل الصفحةُ الحقيقيّة بعد وصول حدث الخادم.
  List<String?> _giftBubbles = List.filled(4, null);

  /// `VoiceController` **الحقيقيّ** بغرفةٍ وخادمٍ مصطنَعَين: زرُّ الميكروفون يصل
  /// ويفتح (أخضر) ويقطع (رمادي) والكتمُ يعمل — بلا لايف كيت ولا شبكة. لو حُقن
  /// `ApiClient` الحقيقيُّ لَفشلت المنحةُ في المعاينة فاحمرَّ الزرُّ بلا ذنب.
  late final _voice = VoiceController(
    api: _PreviewApi(),
    authToken: 'preview',
    roomFactory: _PreviewRoom.new,
  );

  @override
  void dispose() {
    _timer?.cancel();
    _voice.dispose();
    super.dispose();
  }

  TableView get _view => TableView(
        myHand: _hand,
        handCounts: [_hand.length, 6, 6, 6],
        usScore: 42,
        themScore: 37,
        bid: const Bid.ofSuit('coeur'),
        bidderSeat: 1,
        akwins: false,
        dealerSeat: 3,
        seatBids: const [null, null, null, null],
        turn: 0,
        trick: _trick,
        legalCards: _hand.toSet(),
        phase: GamePhase.playing,
        humanCanPlay: true,
      );

  /// لعبُ ورقة: تغادر اليدَ وتظهر على الطاولة — كما يفعل الكنترولر الحقيقيّ.
  void _play(Card c) {
    setState(() {
      _hand = [..._hand]..remove(c);
      _trick = _trick.length >= 4
          ? [(seat: 0, card: c)]
          : [..._trick, (seat: 0, card: c)];
    });
  }

  /// إهداء: مقعدٌ بعينه، أو [kGiftAll] ⇒ **رحلةٌ لكلّ جالسٍ غيري** واحدةً تلو
  /// الأخرى — نفسُ ما يفعله الخادمُ حين تُهدي الجميع.
  int _flightId = 0;
  void _gift(int viewSeat, String giftId) {
    for (final to in viewSeat == kGiftAll ? const [1, 2, 3] : [viewSeat]) {
      _queue.add(GiftFlight(
        id: ++_flightId,
        giftId: giftId,
        fromSeat: 0,
        toSeat: to,
        senderName: _seats[0].name,
        receiverName: _seats[to].name,
      ));
    }
    _pump();
  }

  void _pump() {
    if (_flight != null || _queue.isEmpty) return;
    final f = _queue.removeAt(0);
    setState(() {
      _flight = f;
      _giftBubbles = List.filled(4, null)..[f.toSeat] = f.giftId;
    });
    _timer = Timer(f.total, () {
      if (!mounted) return;
      setState(() => _flight = null);
      _pump();
      // الفقاعةُ تبقى لحظةً بعد الوصول ثمّ تذهب (إن لم تبدأ رحلةٌ جديدة).
      Timer(const Duration(milliseconds: 1200), () {
        if (mounted && _flight == null) {
          setState(() => _giftBubbles = List.filled(4, null));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      manager: ThemeManager(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              const Text(
                'شاشةُ اللعب الحقيقيّة — جرّبها',
                style: TextStyle(
                    color: Color(0xFFF3EAD6),
                    fontSize: 20,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'المسْ ورقةً لتلعبها · 🎁 تحت صورةِ لاعبٍ تُهديه وحدَه، و🎁 تحت '
                'صورتك تُهدي الجميع · 🎤 تحت صورتك: ضغطةٌ تفتح صوتك وضغطةٌ تقطعه '
                '· 🔊 عند بطاقةِ من يزعجك: كتمُه وحدَه',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0x99F3EAD6), fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _toggle('غرفة VIP', _vip, () => setState(() => _vip = !_vip)),
                  _toggle('أعِد توزيع اليد', false, () {
                    setState(() {
                      _hand = List.of(_fullHand);
                      _trick = const [];
                    });
                  }),
                ],
              ),
              const SizedBox(height: 20),
              PhonePreview(
                label: _vip ? 'غرفة VIP' : 'القاعة العاديّة',
                child: TableScreen(
                  view: _view,
                  seats: _seats,
                  seatPlayerIds: const ['me', 'p1', 'p2', 'p3'],
                  vipRoom: _vip,
                  playerName: 'أنت',
                  gifts: _giftBubbles,
                  giftFlight: _flight,
                  voice: _voice,
                  onPlayCard: _play,
                  onGift: _gift,
                  onPlayerTap: (_) {},
                  onOpenChat: () {},
                  onReact: (_) {},
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFD9B45B) : const Color(0xFF23262C),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x66D9B45B)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: on ? const Color(0xFF1A1A1A) : const Color(0xFFE8E2D4),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      );
}

/// غرفةُ صوتٍ مصطنَعة للمعاينة: تقبل كلَّ شيءٍ ولا تتّصل بشبكة.
class _PreviewRoom implements VoiceRoom {
  final _speaking = StreamController<Set<String>>.broadcast();

  @override
  Future<void> connect(String url, String token) async {}
  @override
  Future<void> setMicEnabled(bool enabled) async {}
  @override
  Future<void> applyPolicy(bool Function(String identity) allow) async {}
  @override
  Stream<Set<String>> get speaking => _speaking.stream;
  @override
  Future<void> disconnect() async => _speaking.close();
}

/// خادمٌ مصطنَع يمنح توكن صوتٍ فورًا — المعاينةُ تُري السلوك لا الشبكة.
class _PreviewApi implements ApiClient {
  @override
  Future<VoiceGrant> voiceToken(String token) async =>
      const VoiceGrant(url: 'wss://preview', room: 'preview', token: 'tk');

  @override
  noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
