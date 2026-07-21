import 'dart:async';
import 'dart:convert';

import 'package:belote_engine/belote_engine.dart';
import 'package:meta/meta.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'player_rank.dart';

/// خريطة رمز الورقة → الورقة (من رزمةٍ كاملة) — لتحويل رموز الخادم إلى `Card` للعرض.
final Map<String, Card> _cardByCode = {for (final c in buildDeck()) c.code: c};
Card? cardFromCode(String code) => _cardByCode[code];

/// أطوارُ **لقطة المباراة** وحدها — تطابق `LivePhase.name` في الخادم
/// (`server/lib/game/live_session.dart`). قائمةٌ بيضاء لا سقوطٌ إليها: انظر [TableEvent.parse].
const _gameSnapshotPhases = {'bidding', 'playing', 'done'};

/// حدثٌ قادم من الخادم عبر WS: لوبي · لقطة مباراة · تصنيف · تفاعل · عبارة · هديّة · خطأ
/// · و[UnknownEvent] لما لا نعرفه.
sealed class TableEvent {
  const TableEvent();

  /// يحلّل رسالة JSON خامّة إلى الحدث المناسب.
  ///
  /// **لقطةُ المباراة قائمةٌ بيضاء ([_gameSnapshotPhases]) لا حالةٌ افتراضيّة.** كانت
  /// الدالّة تنتهي بـ`return GameEvent.fromJson(m)`، فكلُّ طورٍ يعرفه خادمٌ أحدث ولا
  /// يعرفه هذا التطبيق **يُفسَّر لقطةَ مباراة** لا يُتجاهَل: رسالةٌ فيها `seat` (كالعبارة)
  /// تُبنى لقطةً بيدٍ فارغةٍ ونقاطٍ أصفار **فتمسح طاولة اللاعب**، وأخرى بلا `seat`
  /// (كالهديّة) ترمي TypeError. ⇒ كان كلُّ بناءٍ يضيف طورًا **إلزاميًّا** بالضرورة.
  ///
  /// بالقائمة البيضاء يتجاهل العميلُ القديم كلَّ جديدٍ بأمان، فيسقط ذلك الشرط.
  /// **أضف طورًا جديدًا هنا وفي [_gameSnapshotPhases] معًا** — الطور المنسيّ يصير
  /// [UnknownEvent] صامتًا، وهو فشلٌ آمنٌ لكنّه صامت.
  static TableEvent parse(Map<String, dynamic> m) {
    if (m['error'] is String) return ServerError(m['error'] as String);
    final phase = m['phase'];
    return switch (phase) {
      'lobby' => LobbyEvent.fromJson(m),
      'rating' => RatingEvent.fromJson(m),
      'reaction' => ReactionEvent.fromJson(m),
      'chat' => ChatEvent.fromJson(m),
      'gift' => GiftEvent.fromJson(m),
      'invite' => InviteEvent.fromJson(m),
      'inviteSent' => InviteSentEvent.fromJson(m),
      // **صمّامُ الدعوة**: انضمّ صديقٌ دعوتَه ⇒ نلتَ لعبةً اليوم. رسالةٌ بلا حمولة —
      // العميلُ يُحدّث عدّادَه ويُخبر.
      'inviteReward' => const InviteRewardEvent(),
      // ── المشاهدة ([[spectator-system]]) ──
      'watchers' => WatchersEvent.fromJson(m),
      'spectatorGift' => SpectatorGiftEvent.fromJson(m),
      'spectateEnd' => const SpectateEndEvent(),
      final String p when _gameSnapshotPhases.contains(p) => GameEvent.fromJson(m),
      _ => UnknownEvent(phase is String ? phase : null),
    };
  }
}

/// تغيّر عدد مشاهدي الطاولة — طورٌ خفيفٌ مستقلٌّ عن اللقطة (لا يُحرّك طابور العرض).
class WatchersEvent extends TableEvent {
  final int count;
  const WatchersEvent(this.count);

  factory WatchersEvent.fromJson(Map<String, dynamic> j) =>
      WatchersEvent(j['count'] as int? ?? 0);
}

/// هديّةٌ رماها **مشاهدٌ** من المدرّجات إلى مقعد [to]. تصل باسم راميها ([name])
/// لا بمقعده — ليس على مقعد. المال حُسم على الخادم قبل البثّ.
class SpectatorGiftEvent extends TableEvent {
  final String name;
  final int to;
  final String gift;
  final bool vip;
  const SpectatorGiftEvent(
      {required this.name, required this.to, required this.gift, this.vip = false});

  factory SpectatorGiftEvent.fromJson(Map<String, dynamic> j) =>
      SpectatorGiftEvent(
        name: j['name'] as String? ?? '',
        to: j['to'] as int? ?? 0,
        gift: j['gift'] as String? ?? '',
        vip: j['vip'] as bool? ?? false,
      );
}

/// انتهى العرض: أُزيلت الطاولة المُشاهدَة (انتهت المباراة غالبًا). آخرُ لقطةٍ تبقى
/// معروضةً (لوحةُ النتيجة) — هذا خبرُ «لا مزيدَ بعدها».
class SpectateEndEvent extends TableEvent {
  const SpectateEndEvent();
}

/// رسالةٌ من خادمٍ **أحدث من هذا التطبيق**: طورٌ لا نعرفه. تُتجاهَل بأمان — لا تمسّ
/// الطاولة ولا تُسقط الاتصال. وجودُها هو ما يسمح بنشر ميزةٍ خادميّةٍ جديدة بلا تحديثٍ
/// إلزاميّ. [phase] محفوظٌ للتشخيص (أو null إن جاءت رسالةٌ بلا طورٍ نصّيّ أصلًا).
class UnknownEvent extends TableEvent {
  final String? phase;
  const UnknownEvent(this.phase);
}

/// تفاعلٌ (رمزٌ تعبيريّ) أرسله لاعبٌ على الطاولة، يبثّه الخادم للجميع.
/// [seat] بإحداثيّات **الخادم** — يحوّلها الكنترولر إلى إحداثيّات العرض.
/// الخادم يُثبّت الرمز من قائمةٍ مغلقة، فما يصل هنا مسموحٌ دائمًا.
class ReactionEvent extends TableEvent {
  final int seat;
  final String emoji;
  const ReactionEvent({required this.seat, required this.emoji});

  factory ReactionEvent.fromJson(Map<String, dynamic> j) => ReactionEvent(
        seat: j['seat'] as int,
        emoji: j['emoji'] as String,
      );
}

/// عبارةٌ سريعة أرسلها لاعب. تصل **بمعرّفها لا بنصّها** (قائمةٌ مغلقة على الخادم)،
/// فيعرضها العميل بلغته. [seat] بإحداثيّات **الخادم**.
class ChatEvent extends TableEvent {
  final int seat;

  /// معرّفُ عبارةٍ جاهزةٍ من `quickChatIds` — **أو** [text] للنصّ الحرّ. أحدُهما فقط.
  final String? phrase;

  /// نصٌّ حرٌّ حرفيٌّ (قرار المالك 2026-07-15). null ⇒ عبارةٌ جاهزة.
  final String? text;

  const ChatEvent({required this.seat, this.phrase, this.text});

  factory ChatEvent.fromJson(Map<String, dynamic> j) => ChatEvent(
        seat: j['seat'] as int,
        phrase: j['phrase'] as String?,
        text: j['text'] as String?,
      );
}

/// هديّةٌ طارت من مقعدٍ إلى مقعد. المال حُسم على الخادم قبل البثّ — هذا خبرٌ للعرض.
/// [from] و[to] بإحداثيّات **الخادم**.
class GiftEvent extends TableEvent {
  final int from;
  final int to;
  final String gift; // معرّف من كتالوج الخادم

  const GiftEvent({required this.from, required this.to, required this.gift});

  factory GiftEvent.fromJson(Map<String, dynamic> j) => GiftEvent(
        from: j['from'] as int,
        to: j['to'] as int,
        gift: j['gift'] as String,
      );
}

/// تغيّر تصنيف اللاعب بعد مباراةٍ **مصنّفة** (٤ بشر). رسالةٌ مستقلّةٌ عن اللقطة
/// يبثّها الخادم مرّةً عند النهاية؛ لا تصل في مباريات الذكاء.
class RatingEvent extends TableEvent {
  final int rating; // التقييم الجديد بعد المباراة
  final int delta; // تغيّره (موجبٌ للفائز)

  /// رتبتُه بعد هذه المباراة — الترقيةُ تُرى في اللحظة التي استُحقّت فيها.
  /// `null` ⇒ خادمٌ أقدمُ من نظام الرتب.
  final PlayerRankView? skill;

  const RatingEvent({required this.rating, required this.delta, this.skill});

  factory RatingEvent.fromJson(Map<String, dynamic> j) => RatingEvent(
        rating: j['rating'] as int,
        delta: j['delta'] as int,
        skill: PlayerRankView.fromJson(j['rank'] as Map<String, dynamic>?),
      );
}

/// خطأٌ من الخادم: `server_full` · `join_failed` · `no_seat` · `unauthorized`.
class ServerError extends TableEvent {
  final String code;
  const ServerError(this.code);
}

class LobbySeat {
  final int seat;
  final bool ai;
  final String? playerId;
  final String? name;

  /// رابط صورته النسبيّ (`/avatars/…`). **فارغٌ هو الطبيعيّ**: من لا صورةَ له، أو
  /// خادمٌ قديمٌ قبل الحقل (لا يرسله أصلًا) ⇒ تُعرَض الأحرف/الإيموجي.
  final String avatarUrl;

  final bool connected;

  /// **أهو VIP؟** يصل من الخادم ⇒ يُرسَم بإطاره وشارته على الطاولة.
  final bool isVip;

  /// **مستوى الذكاء الفعليّ** لمقعد الروبوت (`beginner|pro|expert|legend`) —
  /// الخادم يعايره من متوسّط تصنيف الجالسين، وبه تُشتقّ رتبةُ العرض الصادقة
  /// بدل رتبةٍ عشوائيّةٍ تكذب. null ⇒ بشريّ، أو خادمٌ قديمٌ قبل الحقل.
  final String? aiLevel;

  /// رتبةُ مهارته من الخادم — `null` للذكاء أو خادمٍ أقدمَ من الميزة.
  final PlayerRankView? skill;

  const LobbySeat({
    required this.seat,
    required this.ai,
    this.isVip = false,
    this.playerId,
    this.name,
    this.avatarUrl = '',
    this.connected = false,
    this.skill,
    this.aiLevel,
  });

  factory LobbySeat.fromJson(Map<String, dynamic> j) => LobbySeat(
        seat: j['seat'] as int,
        ai: j['ai'] as bool? ?? false,
        playerId: j['playerId'] as String?,
        name: j['name'] as String?,
        avatarUrl: j['avatar'] as String? ?? '',
        connected: j['connected'] as bool? ?? false,
        // **حقلٌ زائدٌ غائبٌ في الخادم القديم** ⇒ false بلا انهيار.
        isVip: j['vip'] as bool? ?? false,
        aiLevel: j['aiLevel'] as String?,
        skill: PlayerRankView.fromJson(j['rank'] as Map<String, dynamic>?),
      );
}

/// حالة اللوبي قبل بدء المباراة: المقاعد ورمز الطاولة (إن خاصّة).
class LobbyEvent extends TableEvent {
  final String tableId;
  final String? code;
  final List<LobbySeat> seats;

  /// مقعدي أنا **بإحداثيّات الخادم** (`you`). به وحده يُدوَّر اللوبي فأجلس أسفل
  /// الشاشة وشريكي مقابلي — وهو ما يجعل «ادعُ إلى المقعد المقابل» تعني «ادعُ شريكًا».
  /// null ⇒ خادمٌ قديمٌ قبل الحقل (لا تدوير: تُعرَض المقاعد بإحداثيّات الخادم).
  final int? you;

  /// أضغط المضيفُ «ابدأ» فصارت تبحث عن بشرٍ لفراغها؟ بعد المهلة تبدأ بالذكاء.
  final bool searching;

  /// **غرفةُ VIP** — مضيفُها مشترك ⇒ تُرسَم بخلفيّته الخاصّة، **ويراها كلُّ**
  /// الجالسين. غائبٌ في الخادم القديم ⇒ false.
  final bool vipRoom;

  const LobbyEvent({
    required this.tableId,
    this.code,
    required this.seats,
    this.you,
    this.searching = false,
    this.vipRoom = false,
  });

  factory LobbyEvent.fromJson(Map<String, dynamic> j) => LobbyEvent(
        tableId: j['tableId'] as String,
        code: j['code'] as String?,
        you: j['you'] as int?,
        searching: j['searching'] as bool? ?? false,
        vipRoom: j['vipRoom'] as bool? ?? false,
        seats: [
          for (final s in (j['seats'] as List))
            LobbySeat.fromJson(s as Map<String, dynamic>)
        ],
      );
}

/// دعوةٌ من صديقٍ إلى **مقعدٍ بعينه** على طاولته الخاصّة. [seat] بإحداثيّات الخادم
/// (طاولتُه هو، ولستُ عليها بعدُ فلا تدويرَ لي).
class InviteEvent extends TableEvent {
  final String fromId;
  final String fromName;
  final String fromTag;

  /// صورةُ الداعي — فارغةٌ إن لم يرفع (أو خادمٌ أقدم لا يبثّها).
  final String fromAvatarUrl;
  final String code;
  final int seat;

  const InviteEvent({
    required this.fromId,
    required this.fromName,
    required this.fromTag,
    this.fromAvatarUrl = '',
    required this.code,
    required this.seat,
  });

  factory InviteEvent.fromJson(Map<String, dynamic> j) {
    final from = (j['from'] as Map?)?.cast<String, dynamic>() ?? const {};
    return InviteEvent(
      fromId: from['id'] as String? ?? '',
      fromName: from['displayName'] as String? ?? 'صديقك',
      fromTag: from['tag'] as String? ?? '',
      fromAvatarUrl: from['avatarUrl'] as String? ?? '',
      code: j['code'] as String? ?? '',
      seat: j['seat'] as int? ?? 0,
    );
  }
}

/// تأكيدُ وصولِ دعوةٍ أرسلتُها (للداعي وحده).
class InviteSentEvent extends TableEvent {
  final String playerId;
  final int seat;
  const InviteSentEvent({required this.playerId, required this.seat});

  factory InviteSentEvent.fromJson(Map<String, dynamic> j) => InviteSentEvent(
        playerId: j['playerId'] as String? ?? '',
        seat: j['seat'] as int? ?? 0,
      );
}

/// **صمّامُ الدعوة**: صديقٌ دعوتَه انضمّ ⇒ نلتَ لعبةً اليوم. بلا حمولة — الحدث نفسُه
/// هو الخبر، والعميلُ يُحدّث العدّادَ ويُظهر ملاحظة.
class InviteRewardEvent extends TableEvent {
  const InviteRewardEvent();
}

/// ورقةٌ في الأخذة الجارية.
class TrickCard {
  final int seat;
  final String card;
  const TrickCard(this.seat, this.card);
}

/// نيّة ضمانةٍ قانونية معروضة (فهرسها هو ما يُرسَل للخادم).
class LegalBid {
  final String kind; // pass | bid | akwins
  final String? bid; // رمز الضمانة إن وُجد
  const LegalBid(this.kind, this.bid);
}

/// نتيجة الجولة المنتهية.
class RoundResultView {
  final int us;
  final int them;
  final String reason;

  /// عند `reason == 'fouja'`: هل ثبتت الفوجة (المتّهَم فوّج فعلًا)؟ للرسالة في اللوحة.
  final bool? proven;
  const RoundResultView(this.us, this.them, this.reason, {this.proven});
}

/// **لقطة مباراة مخصّصة لمقعد اللاعب** — كما يبثّها الخادم بعد كل تغيّر.
/// أوراق الغير مُخفاة (`handCounts` فقط)؛ `legalCards`/`legalBids` جاهزة (لا حساب في الواجهة).
/// هويّةُ صاحب مقعدٍ أثناء اللعب — بها تُفتَح لوحتُه عند الضغط على بطاقته.
///
/// [playerId] فارغٌ للذكاء والمقعد الفارغ: **لا حسابَ فلا ملفّ**، والبطاقةُ لا
/// تُضغَط. هو المعرّفُ الداخليّ لا الرمزَ المعروض ([[player-tag]]) — الرمزُ يأتي
/// من نقطة الملفّ العامّ عند الفتح، فلا نبثّ ما لا يُعرَض في اللقطة.
class SeatIdentity {
  final int seat; // إحداثيّات الخادم
  final String playerId;
  final String name;
  final String avatarUrl;
  final bool isVip;
  final bool isAI;
  final bool connected;

  /// رتبةُ مهارته كما حسبها الخادم — `null` لمقعد الذكاء أو خادمٍ أقدمَ من الميزة.
  final PlayerRankView? skill;

  const SeatIdentity({
    required this.seat,
    this.playerId = '',
    this.name = '',
    this.avatarUrl = '',
    this.isVip = false,
    this.isAI = false,
    this.connected = true,
    this.skill,
  });

  factory SeatIdentity.fromJson(Map<String, dynamic> j) => SeatIdentity(
        seat: j['seat'] as int,
        playerId: j['playerId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        avatarUrl: j['avatar'] as String? ?? '',
        isVip: j['vip'] as bool? ?? false,
        isAI: j['ai'] as bool? ?? false,
        connected: j['connected'] as bool? ?? true,
        skill: PlayerRankView.fromJson(j['rank'] as Map<String, dynamic>?),
      );
}

class GameEvent extends TableEvent {
  final String phase; // bidding | playing | done
  final int seat;
  final List<String> myHand;
  final List<int> handCounts;
  final int usScore;
  final int themScore;
  final int dealerSeat;
  final String? bid;
  final int? bidderSeat;
  final bool akwins;
  final int turn;
  final List<TrickCard> trick;
  final bool yourTurn;
  final List<String> legalCards;
  final List<LegalBid> legalBids;
  final RoundResultView? roundResult;
  final bool matchOver;

  /// الفريق الفائز بالمباراة (0|1) صراحةً، أو null. يُبثّ لأنّ الفوز بالجولة البيضاء
  /// قد يكون برصيدٍ أقلّ فلا يُشتقّ من مقارنة النقاط.
  final int? matchWinner;

  /// هل يجوز الآن الاعتراض بفوجة (طور اللعب)؟ يُظهر زرّ الفوجة.
  final bool canAccuseFouja;

  /// مقعد الخادم (0..3) للاعبٍ بدأ اعتراض فوجة **ولمّا يُحسم بعد** — الطاولة مجمّدة
  /// عند الجميع حتى يختار الخصم أو يُلغي. null ⇒ لا اعتراض جارٍ.
  final int? foujaClaimBy;

  /// **لقطةُ مشاهد** ([[spectator-system]]): `seat == -1` ولا يدَ ولا نيّات.
  final bool isSpectator;

  /// عددُ مشاهدي الطاولة لحظةَ اللقطة (يصل في لقطات المشاهد؛ وبين اللقطات يحدّثه
  /// طور `watchers` المستقلّ). null ⇒ خادمٌ قديمٌ أو لا مشاهدين.
  final int? watchers;

  /// أيدي المقاعد الأربعة (بإحداثيّات الخادم) مكشوفةً — تصل فقط في لقطة نتيجة الفوجة.
  final List<List<String>>? revealedHands;

  /// **هويّةُ الجالسين** بإحداثيّات الخادم — تصل مع كلّ لقطة لعب.
  ///
  /// كانت الأسماءُ تُقرأ من لقطة اللوبي وحدها، ومَن جلس على مقعدٍ محجوز (بطولة) أو
  /// أعاد الوصلَ في منتصف المباراة لا يمرّ بلوبيٍّ أصلًا ⇒ طاولةٌ بلا هويّة. فارغةٌ
  /// ⇒ خادمٌ أقدمُ من الميزة، ويبقى اللوبي مصدرًا احتياطيًّا.
  final List<SeatIdentity> players;

  /// **ملخّصُ المباراة** — يصل في اللقطة الأخيرة وحدَها (`matchOver`)، لا في طورٍ
  /// مستقلّ: حقلٌ زائدٌ في لقطةٍ معروفةٍ يتجاهله كلُّ عميلٍ لا يعرفه.
  /// `null` ⇒ المباراةُ لم تنتهِ، أو خادمٌ أقدمُ من الميزة.
  final MatchInsights? insights;

  const GameEvent({
    required this.phase,
    required this.seat,
    required this.myHand,
    required this.handCounts,
    required this.usScore,
    required this.themScore,
    required this.dealerSeat,
    required this.bid,
    required this.bidderSeat,
    required this.akwins,
    required this.turn,
    required this.trick,
    required this.yourTurn,
    required this.legalCards,
    required this.legalBids,
    required this.roundResult,
    required this.matchOver,
    this.matchWinner,
    this.canAccuseFouja = false,
    this.foujaClaimBy,
    this.revealedHands,
    this.isSpectator = false,
    this.watchers,
    this.players = const [],
    this.insights,
  });

  factory GameEvent.fromJson(Map<String, dynamic> j) {
    final rr = j['roundResult'] as Map<String, dynamic>?;
    final rev = j['revealedHands'] as List?;
    return GameEvent(
      phase: j['phase'] as String,
      seat: j['seat'] as int,
      myHand: [for (final c in (j['myHand'] as List? ?? const [])) c as String],
      handCounts: [for (final n in (j['handCounts'] as List? ?? const [])) n as int],
      usScore: j['usScore'] as int? ?? 0,
      themScore: j['themScore'] as int? ?? 0,
      dealerSeat: j['dealerSeat'] as int? ?? 0,
      bid: j['bid'] as String?,
      bidderSeat: j['bidderSeat'] as int?,
      akwins: j['akwins'] as bool? ?? false,
      turn: j['turn'] as int? ?? 0,
      trick: [
        for (final t in (j['trick'] as List? ?? const []))
          TrickCard((t as Map<String, dynamic>)['seat'] as int, t['card'] as String)
      ],
      yourTurn: j['yourTurn'] as bool? ?? false,
      legalCards: [for (final c in (j['legalCards'] as List? ?? const [])) c as String],
      legalBids: [
        for (final b in (j['legalBids'] as List? ?? const []))
          LegalBid((b as Map<String, dynamic>)['kind'] as String, b['bid'] as String?)
      ],
      roundResult: rr == null
          ? null
          : RoundResultView(rr['us'] as int, rr['them'] as int, rr['reason'] as String,
              proven: rr['proven'] as bool?),
      matchOver: j['matchOver'] as bool? ?? false,
      matchWinner: j['matchWinner'] as int?,
      insights: j['insights'] == null
          ? null
          : MatchInsights.fromJson(j['insights'] as Map<String, dynamic>),
      canAccuseFouja: j['canAccuseFouja'] as bool? ?? false,
      foujaClaimBy: j['foujaClaimBy'] as int?,
      isSpectator: j['spectator'] as bool? ?? false,
      watchers: j['watchers'] as int?,
      players: [
        for (final p in (j['players'] as List? ?? const []))
          SeatIdentity.fromJson(p as Map<String, dynamic>)
      ],
      revealedHands: rev == null
          ? null
          : [
              for (final h in rev) [for (final c in (h as List)) c as String]
            ],
    );
  }
}

/// حالة اتصال العميل الحيّ — لعرض «إعادة الاتصال…» عند انقطاعٍ مؤقّت.
enum ConnStatus { connected, reconnecting }

/// قناةٌ مجرّدة (تيّار وارد + إرسال + إغلاق) — تفصل حلقة إعادة الاتصال عن
/// `web_socket_channel` فتُختبَر بقناةٍ وهميّة يُتحكَّم بانقطاعها.
typedef WsChannel = ({Stream<String> stream, void Function(String) send, void Function() close});

/// **عميل الطاولة الحيّة.** يغلّف قناة WS: يبثّ [events] (لقطات مُحلَّلة) و[status]
/// (اتصال/إعادة اتصال) ويرسل النيّات.
///
/// البنّاء الأساسيّ يقبل `Stream<String>` + دالّة إرسال ⇒ قابل للاختبار بقناةٍ وهميّة
/// (بلا إعادة اتصال). [LiveTableClient.connect] للإنتاج: **يعيد الاتصال تلقائيًّا**
/// عند الانقطاع غير المقصود، والخادم يستأنف بلقطةٍ فورًا.
class LiveTableClient {
  final _events = StreamController<TableEvent>.broadcast();
  final _status = StreamController<ConnStatus>.broadcast();
  void Function(String message)? _send;
  void Function()? _closeCurrent;
  StreamSubscription? _sub;
  bool _disposed = false;

  LiveTableClient({
    required Stream<String> incoming,
    required void Function(String) send,
    void Function()? close,
  })  : _send = send,
        _closeCurrent = close {
    _sub = incoming.listen(
      _ingest,
      onError: (_) {},
      onDone: () {
        if (!_disposed && !_events.isClosed) _events.close();
      },
    );
  }

  LiveTableClient._reconnecting();

  /// اتصالٌ حقيقيّ بمسار الخادم `ws(s)://host/ws?token=<jwt>` مع **إعادة اتصالٍ تلقائيّة**:
  /// عند انقطاع القناة (غير مقصود) يعيد فتحها كل [retry] حتى تنجح أو يُستدعى [dispose].
  /// [channelFactory] للاختبار فقط (يحقن قناةً وهميّة يُتحكَّم بانقطاعها).
  factory LiveTableClient.connect(
    Uri wsUri, {
    Duration retry = const Duration(seconds: 2),
    @visibleForTesting WsChannel Function(Uri)? channelFactory,
  }) {
    final c = LiveTableClient._reconnecting();
    c._factory = channelFactory ?? _wsChannel;
    c._openChannel(wsUri, retry);
    return c;
  }

  WsChannel Function(Uri) _factory = _wsChannel;

  static WsChannel _wsChannel(Uri uri) {
    final ch = WebSocketChannel.connect(uri);
    return (
      stream: ch.stream.map((e) => e as String),
      send: (s) => ch.sink.add(s),
      close: () => ch.sink.close(),
    );
  }

  /// يُستدعى عند **إعادة فتح** القناة بعد انقطاع (لا عند الفتح الأوّل — يُسنَد بعده).
  /// به يُعيد المشاهدُ نيّةَ `spectate`: الخادم أزاله عند الانقطاع (لا مقعدَ يُحفَظ
  /// له) فلن تصله لقطةٌ تلقائيًّا كالجالس — بلا هذا يعلق على «إعادة الاتصال…» للأبد.
  void Function()? onReopen;

  void _openChannel(Uri uri, Duration retry) {
    if (_disposed) return;
    final ch = _factory(uri);
    _send = ch.send;
    _closeCurrent = ch.close;
    // `web_socket_channel` يخزّن الرسائل حتى يكتمل الاتصال ⇒ الإرسال هنا آمن.
    onReopen?.call();
    var announced = false;
    _sub = ch.stream.listen(
      (raw) {
        if (!announced) {
          announced = true;
          _status.add(ConnStatus.connected); // أول لقطةٍ ⇒ الاتصال حيّ
        }
        _ingest(raw);
      },
      onError: (_) {},
      onDone: () {
        if (_disposed) return;
        _status.add(ConnStatus.reconnecting);
        Timer(retry, () => _openChannel(uri, retry));
      },
    );
  }

  void _ingest(String raw) {
    try {
      _events.add(TableEvent.parse(jsonDecode(raw) as Map<String, dynamic>));
    } catch (_) {/* رسالة تالفة تُتجاهل */}
  }

  Stream<TableEvent> get events => _events.stream;
  Stream<ConnStatus> get status => _status.stream;

  void _emit(Map<String, dynamic> intent) => _send?.call(jsonEncode(intent));

  // ── نيّات اللاعب (بروتوكول الخادم) ──
  void quickMatch() => _emit({'type': 'quick'});
  void createPrivate() => _emit({'type': 'create'});
  /// [seat] لقبول دعوةٍ إلى مقعدٍ بعينه؛ بدونه ⇒ أوّل مقعدٍ فارغ.
  void joinByCode(String code, {int? seat}) =>
      _emit({'type': 'join', 'code': code, if (seat != null) 'seat': seat});
  void start() => _emit({'type': 'start'});
  void bid(int legalIndex) => _emit({'type': 'bid', 'index': legalIndex});
  void play(String cardCode) => _emit({'type': 'play', 'card': cardCode});
  void accuse(int serverSeat) => _emit({'type': 'accuse', 'seat': serverSeat});
  void startFoujaClaim() => _emit({'type': 'foujaClaim'});
  void cancelFoujaClaim() => _emit({'type': 'foujaCancel'});
  void react(String emoji) => _emit({'type': 'reaction', 'emoji': emoji});
  void chat(String phraseId) => _emit({'type': 'chat', 'phrase': phraseId});

  /// نصٌّ حرّ (قرار المالك 2026-07-15). الخادمُ ينظّفه ويقصّه.
  void chatText(String text) => _emit({'type': 'chat', 'text': text});

  /// يدعو [playerId] إلى [seat] (إحداثيّات الخادم) على طاولتي الخاصّة. الخادم
  /// يُنشئها إن لم أكن على واحدة، ويتحقّق أنّه **صديقٌ مقبول** ومتّصل.
  void invite(String playerId, int seat) =>
      _emit({'type': 'invite', 'playerId': playerId, 'seat': seat});

  /// [serverSeat] مقعد المستقبِل بإحداثيّات الخادم — لا معرّف لاعب: الخادم يترجم
  /// المقعد من طاولة المُرسِل (جالسًا كان أم مشاهدًا)، فلا يُهدى لأحدٍ خارجها.
  void gift(int serverSeat, String giftId) =>
      _emit({'type': 'gift', 'seat': serverSeat, 'gift': giftId});

  /// يدخل مشاهدًا على مباراةٍ حيّة ([[spectator-system]]). الخادم يتثبّت (عامّة/
  /// بطولة · جارية · لا حظرَ مع جالس) ويردّ لقطةَ مشاهدٍ أو `spectate_unavailable`.
  void spectate(String tableId) =>
      _emit({'type': 'spectate', 'tableId': tableId});

  /// يغادر المشاهدة (الخادم يحدّث العدّاد عند الجميع فورًا — لا انتظارَ لإغلاق القناة).
  void spectateStop() => _emit({'type': 'spectateStop'});

  Future<void> dispose() async {
    _disposed = true;
    await _sub?.cancel();
    _closeCurrent?.call();
    if (!_events.isClosed) await _events.close();
    if (!_status.isClosed) await _status.close();
  }
}
