import 'package:app/game/view_model.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/lobby_table.dart';
import 'package:app/ui/table/table_config.dart';
import 'package:app/ui/table/table_surface.dart';
import 'package:app/ui/table_screen.dart';
import 'package:app/ui/vip_room.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';

/// **غرفةُ VIP تُرى فعلًا.**
///
/// كانت الخلفيّةُ موصولةً في الكود ومغطّاةً في الشاشة: `TableSurface.vip` فيه
/// `fill: true` فتملأ الطاولةُ الشاشةَ كلَّها ولا يبقى من الغرفة بكسلٌ واحد —
/// حتّى بلّغ المالكُ أنّ الغرفةَ «لم تُضف لها خلفيّتها». الدرسُ نفسُه المكتوبُ في
/// [[dead-fields-and-shipped-claims]]: **ما لا يُرى لم يُبنَ**. هذه الاختباراتُ
/// تحرس الرؤيةَ لا الوصل: صورةُ الغرفة موجودة، **وحولها هامشٌ** يُظهرها.

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

Widget _wrap(Widget child) =>
    ThemeScope(manager: ThemeManager(), child: MaterialApp(home: child));

/// كلُّ صور الخلفيّة المعروضة في الشجرة (من `DecoratedBox`/`Container`).
Iterable<String> _backgroundAssets(WidgetTester t) => t
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((d) => d.decoration)
    .whereType<BoxDecoration>()
    .map((d) => d.image?.image)
    .whereType<AssetImage>()
    .map((a) => a.assetName);

void main() {
  testWidgets('طاولةُ VIP: الغرفةُ خلفيّةً **وهامشٌ يُظهرها** حول الطاولة',
      (t) async {
    await t.pumpWidget(_wrap(const TableScreen(view: _view, vipRoom: true)));

    expect(_backgroundAssets(t), contains(VipRoom.asset),
        reason: 'خلفيّةُ الغرفة غائبةٌ عن شاشة VIP');

    // الطاولةُ لا تلامس حوافَّ الشاشة ⇒ الغرفةُ تُرى حولها.
    final screen = t.getSize(find.byType(TableScreen));
    final table = t.getRect(find.byType(TableSurface));
    expect(table.left, greaterThan(0));
    expect(table.top, greaterThan(0));
    expect(table.width, lessThan(screen.width));
    expect(table.height, lessThan(screen.height));
  });

  testWidgets('طاولةُ القاعة: بلا غرفةٍ، والطاولةُ تملأ المساحة', (t) async {
    await t.pumpWidget(_wrap(const TableScreen(view: _view)));

    expect(_backgroundAssets(t), isNot(contains(VipRoom.asset)));
    final table = t.getRect(find.byType(TableSurface));
    expect(table.left, 0);
  });

  testWidgets('لوبي الطاولة الخاصّة: يُنتظَر في الغرفة نفسِها', (t) async {
    await t.pumpWidget(_wrap(Scaffold(
      body: LobbyTable(
        seats: const [null, null, null, null],
        onInvite: (_) {},
      ),
    )));

    expect(_backgroundAssets(t), contains(VipRoom.asset));
  });

  test('لبّادُ طاولة VIP هو زخرفةُ الغرفة نفسُها', () {
    expect(TableSurface.vip.feltStyle, FeltStyle.image);
    expect(TableSurface.vip.feltImageAsset, VipRoom.asset);
  });

  test('الجدارُ أعتمُ من اللبّاد ⇒ الطاولةُ لا تذوب في الغرفة', () {
    // تعتيمُ اللبّاد 0.28 مثبَّتٌ في `PremiumTablePainter._paintImageField`.
    expect(VipRoom.roomDim, greaterThan(0.28 + 0.15));
  });

  test('الهامشُ محدودٌ مهما صغُرت الشاشةُ أو كبُرت', () {
    expect(VipRoom.inset(120), 10.0); // أصغرُ حدٍّ: يبقى مرئيًّا
    expect(VipRoom.inset(400), 18.0);
    expect(VipRoom.inset(2000), 28.0); // أكبرُ حدٍّ: لا يبتلع اللبّاد
  });

  test('التعتيمُ مقيَّدٌ بين 0 و1', () {
    final d = VipRoom.image(dim: 2).colorFilter;
    expect(d, const ColorFilter.mode(Color(0xFF000000), BlendMode.darken));
  });
}
