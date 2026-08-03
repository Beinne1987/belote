import 'package:app/app_settings.dart';
import 'package:app/net/api_client.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/content_strip.dart';
import 'package:app/ui/home_bottom_bar.dart';
import 'package:app/ui/honor_board.dart';
import 'package:app/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// الشاشة الرئيسيّة — مداخلُها.
///
/// **قرار المالك (2026-07-15):** «زرّ ملفّي يفتح حساب اللاعب، وأنا أعتبره زرًّا زائدًا
/// يجب حذفه لأنّ ملف اللاعب يفتح بالضغط على الحساب وهذا يكفي.» ⇒ **مدخلٌ واحدٌ
/// للملفّ: بطاقةُ الحساب.** هذه الاختبارات تحرس القرار من عودةٍ سهوًا.
Widget _wrap(Widget child) {
  return ThemeScope(
    manager: ThemeManager(),
    child: AppSettingsScope(
      settings: AppSettings(),
      child: SessionScope(
        controller: SessionController(api: ApiClient()),
        child: MaterialApp(home: child),
      ),
    ),
  );
}

/// **شاشةُ هاتفٍ حقيقيّة** لا نافذةَ الاختبار الافتراضيّة (800×600): من 720 عرضًا
/// يحلّ الشريطُ الجانبيُّ محلَّ السفليّ ([AppLayout])، فقياسُ سلوكِ الهاتف على
/// نافذةٍ عرضُها 800 يقيس شاشةً لا يراها لاعبٌ بهاتف.
Future<void> _pumpPhone(WidgetTester t, Widget child) async {
  t.view.physicalSize = const Size(393, 852);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(_wrap(child));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('**لا زرّ «ملفّي» في الشبكة** — البطاقة تكفي', (t) async {
    await _pumpPhone(t, HomeScreen(onPlay: () {}, onProfile: () {}));
    expect(find.text('ملفّي'), findsNothing);
    expect(find.text('إحصائياتك وإنجازاتك'), findsNothing,
        reason: 'عنوانُ الزرّ المحذوف الفرعيّ');
  });

  testWidgets('بطاقة الحساب تفتح الملفّ — المدخل الوحيد يعمل', (t) async {
    var opened = 0;
    await _pumpPhone(t, HomeScreen(onPlay: () {}, onProfile: () => opened++));

    // بلا جلسةٍ تُعرَض البطاقة بنصّها الافتراضيّ؛ الضغط عليها يفتح الملفّ.
    await t.tap(find.byType(InkWell).first);
    await t.pumpAndSettle();
    expect(opened, 1, reason: 'حذفُ الزرّ لا يجوز أن يقطع الطريق الوحيد الباقي');
  });

  testWidgets('بقيّة المداخل باقية (لم يُحذف غير الزائد)', (t) async {
    await _pumpPhone(t, HomeScreen(onPlay: () {}, onProfile: () {}));
    // بطاقاتُ اللعب في القائمة، والوجهاتُ الأربع في الشريط السفليّ — **مرّةً واحدة
    // لكلٍّ**: مدخلان لشيءٍ واحدٍ هو ما نحرس منه.
    for (final title in [
      'لعب سريع',
      'اللعب أونلاين',
      'التصنيف',
      'المتجر',
      'الأصدقاء',
      'حول اللعبة',
    ]) {
      expect(find.text(title), findsOneWidget, reason: '$title مدخلٌ مستقلٌّ لا زائد');
    }
  });

  // **الشريطُ السفليّ يوصِّل فعلًا**: زرٌّ لا يفتح شيئًا أسوأُ من غيابه.
  testWidgets('الشريط السفليّ: كلُّ وجهةٍ تفتح شاشتها', (t) async {
    var rank = 0, store = 0, friends = 0, about = 0;
    await _pumpPhone(
        t,
        HomeScreen(
          onPlay: () {},
          onLeaderboard: () => rank++,
          onStore: () => store++,
          onFriends: () => friends++,
          onAbout: () => about++,
        ));
    for (final label in ['التصنيف', 'المتجر', 'الأصدقاء', 'حول اللعبة']) {
      await t.tap(find.text(label));
      await t.pumpAndSettle();
    }
    expect([rank, store, friends, about], [1, 1, 1, 1]);
  });

  // **اسمُ الزرّ اسمُ ما يفتحه.** كان «مع الأصدقاء · طاولة خاصّة بدعوة» وهو يفتح
  // قائمة الأصدقاء لا طاولة (بلاغ المالك) — والطاولةُ الخاصّة من «اللعب أونلاين».
  testWidgets('زرّ الأصدقاء يسمّي ما يفتحه — لا يَعِد بطاولةٍ خاصّة', (t) async {
    await _pumpPhone(t, HomeScreen(onPlay: () {}, onFriends: () {}));

    // يطابق عنوان الشاشة التي يفتحها (`SimpleTopBar(title: 'الأصدقاء')`).
    expect(find.text('الأصدقاء'), findsOneWidget);
    expect(find.text('مع الأصدقاء'), findsNothing);
    expect(find.text('طاولة خاصّة بدعوة'), findsNothing,
        reason: 'وعدٌ كاذب: الطاولة الخاصّة تُنشَأ من «اللعب أونلاين»');
  });

  /// **الرئيسيّةُ على الحاسوب واجهةُ حاسوب** (طلبُ المالك 2026-08-03) — لا
  /// عمودَ هاتفٍ مكبَّرًا ولا شريطَ إبهامٍ في قاع نافذةٍ عرضُها 1600.
  group('تخطيطُ الحاسوب', () {
    Future<void> pumpAt(WidgetTester t, Size size) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(_wrap(HomeScreen(
        onPlay: () {},
        onLeaderboard: () {},
        onStore: () {},
        onFriends: () {},
        onAbout: () {},
      )));
      await t.pumpAndSettle();
    }

    testWidgets('الشريطُ الجانبيُّ يحلّ محلَّ السفليّ — والوجهاتُ نفسُها',
        (t) async {
      await pumpAt(t, const Size(1440, 900));
      expect(find.byType(HomeSideNav), findsOneWidget);
      expect(find.byType(HomeBottomBar), findsNothing,
          reason: 'شريطُ إبهامٍ في قاع نافذةِ حاسوب');
      // **مرّةً واحدةً لكلّ وجهة**: شريطان معًا يعنيان مدخلين لشيءٍ واحد.
      for (final label in ['التصنيف', 'المتجر', 'الأصدقاء', 'حول اللعبة']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('كلُّ وجهةٍ في الشريط الجانبيّ تفتح شاشتها', (t) async {
      var rank = 0, store = 0, friends = 0, about = 0;
      t.view.physicalSize = const Size(1440, 900);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(_wrap(HomeScreen(
        onPlay: () {},
        onLeaderboard: () => rank++,
        onStore: () => store++,
        onFriends: () => friends++,
        onAbout: () => about++,
      )));
      await t.pumpAndSettle();
      for (final label in ['التصنيف', 'المتجر', 'الأصدقاء', 'حول اللعبة']) {
        await t.tap(find.text(label));
        await t.pumpAndSettle();
      }
      expect([rank, store, friends, about], [1, 1, 1, 1]);
    });

    /// **يُفحَص ترتيبُ الأبناء لا مواضعُهم على الشاشة**: اللافتةُ ولوحةُ الشرف
    /// تختفيان بلا محتوى (`SizedBox.shrink`)، و`SliverList` **لا يبني ابنًا
    /// بلا ارتفاع** أصلًا ⇒ لا رسمَ يُقاس. الترتيبُ في القائمة هو القرار نفسُه.
    List<Widget> childrenOf(WidgetTester t, Finder listView) =>
        (t.widget<ListView>(listView).childrenDelegate
                as SliverChildListDelegate)
            .children;

    testWidgets('الهاتف: **اللعبُ أوّلًا** واللافتاتُ ولوحةُ الشرف آخرًا',
        (t) async {
      await pumpAt(t, const Size(393, 852));
      final kids = childrenOf(t, find.byType(ListView));
      expect(kids[kids.length - 2], isA<ContentStrip>());
      expect(kids.last, isA<HonorBoardSection>());
      // وأوّلُ ما في القائمة بطاقةُ لعبٍ لا لافتة.
      expect(t.getRect(find.text('لعب سريع')).top,
          lessThan(t.getSize(find.byType(HomeScreen)).height / 2));
    });

    testWidgets('الحاسوب: اللعبُ في العمود الواسع والنشاطُ في لوحةٍ جانبيّة',
        (t) async {
      await pumpAt(t, const Size(1440, 900));
      final lists = find.byType(ListView);
      expect(t.widgetList(lists).length, 2, reason: 'عمودان: لعبٌ ونشاط');
      final main = childrenOf(t, lists.first);
      final side = childrenOf(t, lists.last);
      expect(main.any((w) => w is ContentStrip), isFalse,
          reason: 'الإعلانُ يزاحم اللعبَ في عموده');
      expect(side.first, isA<ContentStrip>());
      expect(side.last, isA<HonorBoardSection>());

      // والبطاقتان الكبيرتان صفًّا واحدًا يستغلّ العرض لا عمودًا كالهاتف.
      final play = t.getRect(find.text('لعب سريع'));
      final online = t.getRect(find.text('اللعب أونلاين'));
      expect((play.center.dy - online.center.dy).abs(), lessThan(40),
          reason: 'البطاقتان في عمودٍ كما على الهاتف');
      // ولا فراغَ جانبيٌّ كبير: العمودُ الرئيسُ يبدأ قرب حافّة الشريط الجانبيّ.
      final rail = t.getRect(find.byType(HomeSideNav));
      final mainRect = t.getRect(lists.first);
      expect(mainRect.width, greaterThan(600),
          reason: 'عمودُ اللعب محشورٌ في عرض هاتف');
      // (الجهةُ تتبع اتّجاه اللغة ⇒ يُفحَص عدمُ التراكب لا يمينٌ ويسار.)
      expect(mainRect.overlaps(rail), isFalse,
          reason: 'العمودُ يركب الشريطَ الجانبيّ');
    });

    testWidgets('الهاتفُ المقلوبُ عرضًا يبقى هاتفًا (لا شريطَ جانبيّ)',
        (t) async {
      await pumpAt(t, const Size(852, 393));
      expect(find.byType(HomeSideNav), findsNothing);
      expect(find.byType(HomeBottomBar), findsOneWidget);
    });
  });

  group('شارةُ العدد', _badgeDirectionTests);
}

/// **شارةُ العدد تتبع اتّجاه اللغة** (المهمّة ١٣): كانت `left: -6` بحجّة أنّ
/// الواجهة عربيّة — والواجهةُ فرنسيّةٌ أيضًا، فتقع الشارةُ هناك في الطرف
/// **الداخليّ** فوق جارتها. خطأٌ لا يراه من يقرأ لغةً واحدة.
void _badgeDirectionTests() {
  Widget bar(TextDirection dir) => ThemeScope(
        manager: ThemeManager(),
        child: MaterialApp(
          home: Directionality(
            textDirection: dir,
            child: Scaffold(
              body: HomeBottomBar(
                currentIndex: 0,
                items: const [
                  HomeBarItem(icon: Icons.home, label: 'أ'),
                  HomeBarItem(icon: Icons.group, label: 'ب', badge: 3),
                ],
                onTap: (_) {},
              ),
            ),
          ),
        ),
      );

  testWidgets('الشارةُ في الطرف الخارجيّ في الاتّجاهين', (t) async {
    for (final dir in TextDirection.values) {
      await t.pumpWidget(bar(dir));
      await t.pumpAndSettle();
      final icon = t.getRect(find.byIcon(Icons.group));
      final badge = t.getRect(find.text('3'));
      final outward = dir == TextDirection.rtl
          ? badge.center.dx < icon.center.dx // اليسارُ خارجٌ في العربيّة
          : badge.center.dx > icon.center.dx; // واليمينُ في الفرنسيّة
      expect(outward, isTrue, reason: '$dir: الشارةُ في الطرف الداخليّ');
    }
  });
}
