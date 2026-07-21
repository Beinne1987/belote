import 'package:app/game/seat_player.dart';
import 'package:app/game/view_model.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/table_screen.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// وصلُ الدردشة والهدايا بالشاشة — نظيرُ `table_screen_reactions_test.dart`.
///
/// جوهرُ ما يُفحص: **أداةٌ بلا مُعالِجٍ تُخفى** (الأوفلاين: لا وجودَ لها أصلًا)، أمّا
/// أداةٌ لها مُعالِجٌ وتعذّر استعمالُها الآن **فتبقى ظاهرةً وتشرح نفسها** — وهذا ما
/// أخطأتُ فيه في 4041 فبلّغ المالك أنّ «الهدايا لم تظهر». وأنّ الفقاعات تصل بطاقاتِ
/// أصحابها.
const _view = TableView(
  myHand: [],
  handCounts: [0, 0, 0, 0],
  usScore: 0,
  themScore: 0,
  bid: null,
  bidderSeat: null,
  akwins: false,
  dealerSeat: 0,
  seatBids: [null, null, null, null],
  turn: 0,
  trick: [],
  legalCards: {},
  phase: GamePhase.playing,
);

Widget _screen({
  List<String?>? chats,
  List<String?>? gifts,
  VoidCallback? onOpenChat,
  void Function(int, String)? onGift,
  List<String?>? seatPlayerIds,
  List<SeatPlayer>? seats,
}) =>
    ThemeScope(
      manager: ThemeManager(),
      child: MaterialApp(
        home: TableScreen(
          view: _view,
          chats: chats,
          gifts: gifts,
          onOpenChat: onOpenChat,
          onGift: onGift,
          seatPlayerIds: seatPlayerIds,
          seats: seats,
        ),
      ),
    );

/// **لا قائمةَ بعد الآن**: الأدواتُ ظاهرةٌ مباشرةً (صوتٌ ورسائل على الجانب،
/// وخروجٌ أعلى اليسار)، والهديّةُ زرٌّ تحت كلّ صورة — `Icons.redeem`.
/// زرُّ هديّتي (تحت صورتي) يُهدي **الجميع**، وزرُّ لاعبٍ يُهديه وحدَه.
Finder _myGiftButton() => find.byTooltip('هديّة للجميع');

void main() {
  testWidgets('أوفلاين (بلا onOpenChat/onGift) ⇒ لا زرّ رسائلَ ولا هديّة', (t) async {
    await t.pumpWidget(_screen());
    expect(find.byIcon(Icons.chat_bubble_outline), findsNothing);
    expect(find.byIcon(Icons.redeem), findsNothing);
    expect(find.byIcon(Icons.logout), findsOneWidget, reason: 'الخروج يبقى دائمًا');
  });

  testWidgets('أونلاين ⇒ زرّ الرسائل يفتح اللوحة (فتحُها شأنُ الصفحة لا الشاشة)',
      (t) async {
    var opened = 0;
    await t.pumpWidget(_screen(onOpenChat: () => opened++));

    await t.tap(find.byIcon(Icons.chat_bubble_outline));
    await t.pumpAndSettle();
    expect(opened, 1, reason: 'الشاشة تُبلّغ ولا تعرف اللوحة');
  });

  // **بلاغ المالك على 4041: «الهدايا لم تظهر».** كان الزرّ مشروطًا بوجود هدفٍ بشريّ،
  // وفي القاعدة حسابٌ واحد ⇒ لم يظهر أبدًا، بعد أن أُعلنت الميزة في تحديثٍ إلزاميّ.
  // الإخفاء هو ما خيّب. [[gift-button-visibility]]
  testWidgets('**الزرّ ظاهرٌ ولو لم يجلس بشريٌّ آخر** — لا يُخفى ما أُعلن', (t) async {
    await t.pumpWidget(_screen(onGift: (_, __) {}, seatPlayerIds: [null, null, null, null]));
    expect(find.byIcon(Icons.redeem), findsOneWidget,
        reason: 'زرُّ هديّتي (للجميع) تحت صورتي — ولا زرَّ فوق مقعدِ ذكاء');
  });

  testWidgets('لا هدفَ بشريّ ⇒ اللوحة **تشرح وتدلّ** لا تصمت', (t) async {
    await t.pumpWidget(_screen(onGift: (_, __) {}, seatPlayerIds: [null, null, null, null]));
    await t.tap(_myGiftButton());
    await t.pumpAndSettle();

    expect(find.textContaining('الهدايا للاعبين البشر'), findsOneWidget);
    expect(find.textContaining('ادعُ صاحبك'), findsOneWidget, reason: 'يدلّ على الحلّ');
    // لا كتالوجَ بلا من تُهديه: اختيارُ هديّةٍ حينها عبث.
    expect(find.text('وردة'), findsNothing);
    expect(find.text('ماذا تُهدي؟'), findsNothing);
  });

  testWidgets('بشريٌّ على الطاولة ⇒ زرّ الهديّة يفتح اللوحة بمن يصحّ إهداؤه وحدَهم',
      (t) async {
    final sent = <(int, String)>[];
    await t.pumpWidget(_screen(
      onGift: (seat, gift) => sent.add((seat, gift)),
      // المقعد 2 (شريكي) بشريّ، و1 و3 ذكاء ⇒ هو وحده هدفٌ صالح.
      seatPlayerIds: ['me', null, 'p2', null],
      seats: const [
        SeatPlayer(name: 'أنا'),
        SeatPlayer(name: 'ذكاءٌ يمينًا'),
        SeatPlayer(name: 'سالم'),
        SeatPlayer(name: 'ذكاءٌ يسارًا'),
      ],
    ));
    await t.tap(_myGiftButton());
    await t.pumpAndSettle();

    // الأسماء تظهر على بطاقات الطاولة أيضًا ⇒ ابحث في رقائق الاختيار وحدها.
    Finder chip(String name) => find.widgetWithText(ChoiceChip, name);
    expect(chip('سالم'), findsOneWidget, reason: 'البشريّ هدفٌ');
    expect(chip('ذكاءٌ يمينًا'), findsNothing, reason: 'الذكاء لا يُهدى');
    expect(chip('أنا'), findsNothing, reason: 'لا يُهدي نفسه');

    await t.tap(find.text('وردة'));
    await t.pumpAndSettle();
    expect(sent, [(2, 'rose')], reason: 'مقعد العرض 2 — الترجمة شأن الكنترولر');
  });

  testWidgets('فقاعتا الدردشة والهديّة تظهران فوق بطاقتَي صاحبيهما', (t) async {
    await t.pumpWidget(_screen(
      // `chats` **نصوصٌ محسومة** (الترجمة/الإسقاط شأنُ الكنترولر) ⇒ تُعرَض حرفيًّا.
      chats: [null, 'سلامٌ عليكم', null, null],
      gifts: [null, null, 'rose', null],
    ));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('سلامٌ عليكم'), findsOneWidget);
    expect(find.text('🌹'), findsOneWidget);
  });

  testWidgets('هديّةٌ لا يعرفها التطبيق (خادمٌ أحدث) ⇒ لا فقاعةَ ولا معرّفٌ خام',
      (t) async {
    // نظيرُ الدردشة (إسقاطُ المجهول) في الكنترولر — `online_chat_test.dart`.
    await t.pumpWidget(_screen(
      gifts: [null, null, 'yacht', null],
    ));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('yacht'), findsNothing);
  });
}
