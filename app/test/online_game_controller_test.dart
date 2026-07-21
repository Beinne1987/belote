import 'dart:async';
import 'dart:convert';

import 'package:app/game/online_game_controller.dart';
import 'package:app/game/view_model.dart';
import 'package:app/net/table_client.dart';
import 'package:app/ui/gift_picker.dart' show kGiftAll;
import 'package:belote_engine/belote_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// كنترولر فوق عميلٍ وهميّ: [feed] يحقن لقطة الخادم، و[sent] يلتقط نيّات العميل.
(OnlineGameController, void Function(Map<String, dynamic>), List<Map<String, dynamic>>)
    _harness() {
  final incoming = StreamController<String>.broadcast();
  final sent = <Map<String, dynamic>>[];
  final client = LiveTableClient(
    incoming: incoming.stream,
    send: (s) => sent.add(jsonDecode(s) as Map<String, dynamic>),
  );
  final c = OnlineGameController(client);
  void feed(Map<String, dynamic> m) => incoming.add(jsonEncode(m));
  return (c, feed, sent);
}

/// لقطة لعبٍ بسيطة لمقعدٍ [seat]. الأكواد الحقيقية من [buildDeck].
Map<String, dynamic> _playingSnapshot({required int seat}) {
  final codes = [for (final c in buildDeck()) c.code];
  return {
    'phase': 'playing',
    'seat': seat,
    'myHand': [codes[0], codes[1], codes[2]],
    'handCounts': [8, 7, 6, 5],
    'usScore': 12,
    'themScore': 30,
    'dealerSeat': 0,
    'bid': 'T',
    'bidderSeat': 2,
    'akwins': false,
    'turn': 1,
    'trick': [
      {'seat': 2, 'card': codes[10]},
    ],
    'yourTurn': seat == 1,
    'legalCards': [codes[0], codes[1]],
    'legalBids': const [],
    'roundResult': null,
    'matchOver': false,
  };
}

void main() {
  test('المراحل: قائمة → لوبي → لعب', () async {
    final (c, feed, _) = _harness();
    expect(c.stage, OnlineStage.menu);

    feed({
      'phase': 'lobby',
      'tableId': 't1',
      'seats': [
        {'seat': 0, 'ai': false, 'playerId': 'p1', 'connected': true},
      ],
    });
    await Future<void>.delayed(Duration.zero);
    expect(c.stage, OnlineStage.lobby);

    feed(_playingSnapshot(seat: 0));
    await Future<void>.delayed(Duration.zero);
    expect(c.stage, OnlineStage.playing);
  });

  test('تدوير المقاعد: مقعدي الحقيقيّ يصبح 0 (أسفل)، والباقي يدور', () async {
    final (c, feed, _) = _harness();
    feed(_playingSnapshot(seat: 1)); // مقعدي الحقيقيّ = 1
    await Future<void>.delayed(Duration.zero);

    final v = c.tableView!;
    // handCounts الخادم [8,7,6,5] بالمقاعد؛ view(s)=(s-1)%4 ⇒ [7,6,5,8].
    expect(v.handCounts, [7, 6, 5, 8]);
    expect(v.dealerSeat, 3); // 0 → (0-1+4)%4
    expect(v.turn, 0); // 1 → مقعدي أسفل
    expect(v.bidderSeat, 1); // 2 → (2-1)%4
    expect(v.trick.single.seat, 1); // ورقة المقعد 2 تُرسَم في view 1
    expect(v.phase, GamePhase.playing);
    expect(v.myHand.length, 3);
    expect(v.legalCards.length, 2);
    expect(v.humanCanPlay, true); // yourTurn=true للمقعد 1
  });

  test('placeBid يُرسِل فهرس الضمانة في قائمة الخادم القانونية', () async {
    final (c, feed, sent) = _harness();
    feed({
      'phase': 'bidding',
      'seat': 0,
      'myHand': const [],
      'handCounts': [8, 8, 8, 8],
      'usScore': 0,
      'themScore': 0,
      'dealerSeat': 0,
      'bid': null,
      'bidderSeat': null,
      'akwins': false,
      'turn': 0,
      'trick': const [],
      'yourTurn': true,
      'legalCards': const [],
      'legalBids': const [
        {'kind': 'pass', 'bid': null},
        {'kind': 'bid', 'bid': 'T'},
        {'kind': 'bid', 'bid': 'N'},
        {'kind': 'akwins', 'bid': null},
      ],
      'roundResult': null,
      'matchOver': false,
    });
    await Future<void>.delayed(Duration.zero);

    // شريط الضمانة مبنيّ ومفعّل للقانونيّ فقط.
    final bar = c.bidBar!;
    expect(bar.options.first.enabled, true); // pass قانونيّ

    c.placeBid(const BidAction.ofBid(Bid.sans())); // 'N' ⇒ الفهرس 2
    c.placeBid(const BidAction.pass()); // الفهرس 0
    c.placeBid(const BidAction.akwins()); // الفهرس 3
    expect(sent, [
      {'type': 'bid', 'index': 2},
      {'type': 'bid', 'index': 0},
      {'type': 'bid', 'index': 3},
    ]);

    // ضمانة غير قانونية الآن (غير موجودة) ⇒ تُتجاهَل.
    c.placeBid(const BidAction.ofBid(Bid.tout()));
    expect(sent.length, 3);
  });

  test('playCard يُرسِل رمز الورقة', () async {
    final (c, feed, sent) = _harness();
    feed(_playingSnapshot(seat: 1));
    await Future<void>.delayed(Duration.zero);
    final card = c.tableView!.myHand.first;
    c.playCard(card);
    expect(sent.single, {'type': 'play', 'card': card.code});
  });

  test('roundResult يُشتقّ من اللقطة، ونتيجة المباراة عند الانتهاء', () async {
    final (c, feed, _) = _harness();
    final snap = _playingSnapshot(seat: 0)
      ..['phase'] = 'done'
      ..['usScore'] = 105
      ..['themScore'] = 60
      ..['matchOver'] = true
      ..['roundResult'] = {'us': 16, 'them': 0, 'reason': 'ok'};
    feed(snap);
    await Future<void>.delayed(Duration.zero);

    final r = c.roundResult!;
    expect(r.usPoints, 16);
    expect(r.roundValue, 16);
    expect(r.usTotal, 105);
    expect(r.matchOutcome, 0); // نحن الأعلى ⇒ فزنا
  });

  test('الفوجة: بدء المطالبة يُرسل للخادم، ولقطة foujaClaimBy=مقعدي تفتح اللوحة، والاعتراض يُرسل مقعد الخادم', () async {
    final (c, feed, sent) = _harness();
    feed(_playingSnapshot(seat: 1)..['canAccuseFouja'] = true);
    await Future<void>.delayed(Duration.zero);
    expect(c.tableView!.canAccuseFouja, true);

    // بدء المطالبة الآن يبثّها للخادم (تجميدٌ عند الجميع) بلا فتحٍ محلّيّ متسرّع.
    c.startFoujaClaim();
    expect(sent.single, {'type': 'foujaClaim'});
    expect(c.tableView!.claimingFouja, false); // لم تُفتح بعد — ننتظر لقطة الخادم

    // الخادم يبثّ لقطةً بمقعد المعترِض = مقعدي ⇒ تُفتح لوحة الاختيار ويُخفى الزرّ.
    feed(_playingSnapshot(seat: 1)
      ..['canAccuseFouja'] = true
      ..['foujaClaimBy'] = 1);
    await Future<void>.delayed(Duration.zero);
    expect(c.tableView!.claimingFouja, true);
    expect(c.tableView!.canAccuseFouja, false);
    expect(c.tableView!.foujaClaimBy, 0); // مقعدي بترتيب العرض = 0

    c.accuseFouja(1); // مقعد العرض 1 (يمينك)؛ mySeat=1 ⇒ serverSeat=(1+1)%4=2
    expect(sent.last, {'type': 'accuse', 'seat': 2});
  });

  test('الفوجة: اعتراض خصمٍ آخر يُظهر لافتة التجميد (لا لوحة اختيار) بترتيب العرض', () async {
    final (c, feed, _) = _harness();
    // مقعدي 1؛ المعترِض هو المقعد 3 (الخصم الآخر).
    feed(_playingSnapshot(seat: 1)
      ..['canAccuseFouja'] = true
      ..['foujaClaimBy'] = 3);
    await Future<void>.delayed(Duration.zero);
    final v = c.tableView!;
    expect(v.claimingFouja, false); // لستُ المعترِض ⇒ لا لوحة اختيار
    expect(v.canAccuseFouja, false); // الطاولة مجمّدة ⇒ يُخفى زرّي أيضًا
    expect(v.foujaClaimBy, 2); // view(3)=(3-1)%4=2
  });

  test('cancelFoujaClaim يُرسِل نيّة الإلغاء للخادم', () async {
    final (c, feed, sent) = _harness();
    feed(_playingSnapshot(seat: 1)..['canAccuseFouja'] = true..['foujaClaimBy'] = 1);
    await Future<void>.delayed(Duration.zero);
    c.cancelFoujaClaim();
    expect(sent.single, {'type': 'foujaCancel'});
  });

  test('نتيجة الفوجة: الأيدي مكشوفةٌ بترتيب العرض والإثبات يظهر', () async {
    final (c, feed, _) = _harness();
    feed(_playingSnapshot(seat: 0)); // لقطةٌ سابقة
    await Future<void>.delayed(Duration.zero);

    final codes = [for (final cc in buildDeck()) cc.code];
    final foujaSnap = _playingSnapshot(seat: 0)
      ..['roundResult'] = {'us': 0, 'them': 16, 'reason': 'fouja', 'proven': true}
      ..['revealedHands'] = [
        [codes[0]],
        [codes[1]],
        [codes[2]],
        [codes[3]],
      ];
    feed(foujaSnap);
    await Future<void>.delayed(Duration.zero);

    final r = c.roundResult!;
    expect(r.reason, 'fouja');
    expect(r.foujaProven, true);
    expect(r.themPoints, 16);

    final rh = c.tableView!.revealedHands!;
    expect(rh.length, 4);
    // mySeat=0 ⇒ view==server؛ الخصم يمينك (view 1) = يد المقعد 1.
    expect(rh[1].single.code, codes[1]);
  });

  test('خطأ الخادم القاتل ⇒ مرحلة خطأ', () async {
    final (c, feed, _) = _harness();
    feed({'error': 'server_full'});
    await Future<void>.delayed(Duration.zero);
    expect(c.stage, OnlineStage.error);
    expect(c.errorCode, 'server_full');
  });

  // **بلاغ المالك (2026-07-15): «لم أستطع دعوة شخصٍ خارج التطبيق».** كان الخادم يردّ
  // `invite_offline` (وهو خبرٌ صحيح: الدعوة تصل للمتّصلين وحدهم حتى تُبنى الإشعارات)،
  // فيرفعه العميل إلى `OnlineStage.error` **فوق اللوبي** ⇒ تختفي الطاولة كلُّها ويُطرَد
  // الداعي برسالة «حدث خطأ غير متوقّع». فشلُ دعوةٍ ليس موتَ طاولة.
  group('الأخطاء العابرة لا تهدم الطاولة', () {
    test('دعوةٌ لصديقٍ غائبٍ ⇒ خبرٌ عابر واللوبي باقٍ كما هو', () async {
      final (c, feed, _) = _harness();
      feed({'phase': 'lobby', 'tableId': 't1', 'code': 'ABCD', 'you': 0, 'seats': []});
      await Future<void>.delayed(Duration.zero);
      expect(c.stage, OnlineStage.lobby, reason: 'تمهيد');

      feed({'error': 'invite_offline'});
      await Future<void>.delayed(Duration.zero);

      expect(c.stage, OnlineStage.lobby, reason: 'اللوبي لا يُهدَم لأنّ صديقًا نائم');
      expect(c.errorCode, isNull, reason: 'ليس خطأً قاتلًا');
      expect(c.notice, 'invite_offline', reason: 'بل خبرٌ يُقال ويمضي');
    });

    test('هديّةٌ بلا رصيدٍ وسط مباراة ⇒ المباراة تُكمَل', () async {
      final (c, feed, _) = _harness();
      feed(_playingSnapshot(seat: 1));
      await Future<void>.delayed(Duration.zero);
      expect(c.stage, OnlineStage.playing, reason: 'تمهيد');

      feed({'error': 'gift_insufficient'});
      await Future<void>.delayed(Duration.zero);

      expect(c.stage, OnlineStage.playing,
          reason: 'لا يُطرَد لاعبٌ من مباراةٍ سليمة لأنّ رقائقه لم تكفِ هديّة');
      expect(c.notice, 'gift_insufficient');
    });

    // نظير `UnknownEvent`: خادمٌ أحدثُ يبثّ رمزًا لا نعرفه ⇒ لا نهدم طاولةً حيّة
    // لأجله. القائمةُ البيضاء تجعل هذا هو السلوك الافتراضيّ لا استثناءً.
    test('رمزٌ مجهولٌ من خادمٍ أحدث ⇒ خبرٌ عابر لا شاشةُ موت', () async {
      final (c, feed, _) = _harness();
      feed({'phase': 'lobby', 'tableId': 't1', 'code': 'ABCD', 'you': 0, 'seats': []});
      await Future<void>.delayed(Duration.zero);

      feed({'error': 'something_we_have_never_heard_of'});
      await Future<void>.delayed(Duration.zero);

      expect(c.stage, OnlineStage.lobby);
      expect(c.notice, 'something_we_have_never_heard_of');
    });

    test('القاتل يبقى قاتلًا ولو كنّا في لوبي', () async {
      final (c, feed, _) = _harness();
      feed({'phase': 'lobby', 'tableId': 't1', 'code': 'ABCD', 'you': 0, 'seats': []});
      await Future<void>.delayed(Duration.zero);

      feed({'error': 'unauthorized'});
      await Future<void>.delayed(Duration.zero);

      expect(c.stage, OnlineStage.error,
          reason: 'انتهاء الجلسة لا طاولةَ بعده — الشاشة الكاملة صادقة');
    });

    test('لمسةُ الشريط تُخفيه', () async {
      final (c, feed, _) = _harness();
      feed({'error': 'invite_seatTaken'});
      await Future<void>.delayed(Duration.zero);
      expect(c.notice, isNotNull);

      c.dismissNotice();
      expect(c.notice, isNull);
    });
  });

  /// **العطبُ الذي كان يبتلع الهديّة الجماعيّة** (وُجد 2026-07-20): تدويرُ مقعد
  /// العرض إلى مقعد الخادم `(view + mySeat) % 4` كان يبتلع ‎-1 — وهو ليس مقعدًا —
  /// فيصير `(mySeat + 3) % 4`: **لاعبًا واحدًا حقيقيًّا**. الشاشةُ تقول «للجميع»
  /// والخادمُ يسلّم لواحد، وفرعُ الجميع في الخادم لا يُبلَغ أبدًا.
  test('«للجميع» (‎-1) يمرّ كما هو، والمقعدُ الحقيقيّ يُدار', () async {
    for (var mySeat = 0; mySeat < 4; mySeat++) {
      final (c, feed, sent) = _harness();
      feed(_playingSnapshot(seat: mySeat));
      await Future<void>.delayed(Duration.zero); // اللقطةُ تصل عبر تدفّقٍ لا فورًا
      sent.clear();

      c.sendGift(kGiftAll, 'rose');
      expect(sent.single['seat'], kGiftAll,
          reason: 'mySeat=$mySeat: ‎-1 لا يُدار');

      sent.clear();
      c.sendGift(1, 'rose');
      expect(sent.single['seat'], (1 + mySeat) % 4,
          reason: 'mySeat=$mySeat: مقعدٌ حقيقيٌّ يُدار كما كان');
    }
  });
}
