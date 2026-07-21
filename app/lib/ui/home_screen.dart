import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'content_strip.dart';
import 'home_bottom_bar.dart';
import 'honor_board.dart';
import 'player_avatar.dart';

/// الشاشة الرئيسية — واجهة الدخول بالهوية البصرية. بياناتٌ مبدئية محلّية (بلا خادم بعد).
/// «لعب سريع» يفتح الطاولة؛ بقيّة الأقسام أصداف تُوصَل تباعًا.
class HomeScreen extends StatelessWidget {
  /// يفتح الطاولة (يُمرَّر من `main` كي تبقى الشاشة عرضًا محضًا).
  final VoidCallback onPlay;
  final VoidCallback? onOnline;
  final VoidCallback? onProfile;
  final VoidCallback? onLeaderboard;
  final VoidCallback? onStore;
  final VoidCallback? onSettings;
  final VoidCallback? onMissions;
  final VoidCallback? onVip;
  final VoidCallback? onTournaments;
  final VoidCallback? onFriends;
  final VoidCallback? onNotifications;

  /// المباريات الحيّة — مدرّجات المشاهدة ([[spectator-system]]).
  final VoidCallback? onWatchLive;

  /// «حول اللعبة» — التعريفُ والمطوّرُ وإصدارُ الحزمة.
  final VoidCallback? onAbout;

  const HomeScreen({
    super.key,
    required this.onPlay,
    this.onOnline,
    this.onProfile,
    this.onLeaderboard,
    this.onStore,
    this.onSettings,
    this.onMissions,
    this.onVip,
    this.onTournaments,
    this.onFriends,
    this.onNotifications,
    this.onWatchLive,
    this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final localName = AppSettingsScope.of(context).name;
    final session = SessionScope.of(context);
    final signedIn = session.isSignedIn;
    final serverName = session.player?.displayName ?? '';
    final display =
        (signedIn && serverName.isNotEmpty) ? serverName : (localName.isEmpty ? 'اللاعب' : localName);
    return Scaffold(
      // **وجهاتٌ ثابتةٌ تحت الإبهام**: التصنيفُ والمتجرُ والأصدقاءُ وحول اللعبة
      // خرجت من قائمة البطاقات إلى هنا — بطاقةٌ وزرٌّ لشيءٍ واحدٍ مدخلان.
      bottomNavigationBar: HomeBottomBar(
        currentIndex: 0, // نحن في الرئيسيّة؛ البقيّةُ شاشاتٌ تُفتَح فوقها
        items: [
          const HomeBarItem(icon: Icons.home, label: 'الرئيسية'),
          const HomeBarItem(icon: Icons.leaderboard, label: 'التصنيف'),
          const HomeBarItem(icon: Icons.shopping_cart, label: 'المتجر'),
          // شارةُ الرسائل غير المقروءة تلزم الأصدقاءَ أينما ذهب زرُّهم.
          HomeBarItem(
              icon: Icons.group,
              label: 'الأصدقاء',
              badge: session.unreadMessages),
          const HomeBarItem(icon: Icons.info_outline, label: 'حول اللعبة'),
        ],
        onTap: (i) {
          final go = switch (i) {
            0 => null, // نحن فيها ⇒ لا شيء
            1 => onLeaderboard,
            2 => onStore,
            3 => onFriends,
            _ => onAbout,
          };
          if (i == 0) return;
          (go ?? () => _soon(context))();
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.gradTop, t.gradBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _PlayerBar(
                name: display,
                signedIn: signedIn,
                isVip: session.isVip,
                avatarUrl: session.player?.avatarUrl ?? '',
                tag: session.player?.tag ?? '',
                rating: session.stats?.rating,
                diamonds: session.diamonds,
                unread: session.unreadNotifications,
                onSignIn: onOnline,
                onSettings: onSettings,
                onProfile: onProfile,
                onNotifications: onNotifications,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // لافتاتُ المالك وأخبارُه (من لوحة التحكّم) — لا محتوى ⇒ لا أثر.
                    const ContentStrip(),
                    // **لوحةُ الشرف فوق أزرار اللعب**: أوّلُ ما تقع عليه العينُ
                    // وجوهُ المتصدّرين — وهي المحرّك: من رآه هناك أراد مكانه.
                    // فارغةٌ (بلا فائزٍ أو خادمٍ أقدم) ⇒ تختفي بلا أثر.
                    HonorBoardSection(board: session.honors),
                    _CategoryCard(
                      title: 'لعب سريع',
                      subtitle: 'ضدّ الذكاء — بلا اتصال',
                      icon: Icons.style, // مروحة أوراق (لا نرد)
                      big: true,
                      onTap: onPlay,
                    ),
                    _CategoryCard(
                      title: 'اللعب أونلاين',
                      subtitle: _onlineSubtitle(signedIn, session.allowance),
                      icon: Icons.public,
                      big: true,
                      badge: _PlayCounter(allowance: session.allowance),
                      onTap: onOnline ?? () => _soon(context),
                    ),
                    // **المشتركُ يرى «اشتراكي» لا عرضًا لما يملك.**
                    _CategoryCard(
                      title: 'VIP',
                      subtitle: session.isVip
                          ? 'اشتراكُك قائم — مزاياك كلُّها معك'
                          : 'مجلسٌ خاصّ · إطارٌ · هدايا · لعبٌ بلا حدود',
                      icon: Icons.workspace_premium,
                      badge: session.isVip
                          ? Icon(Icons.check_circle, size: 18, color: t.accent)
                          : null,
                      onTap: onVip ?? () => _soon(context),
                    ),
                    _CategoryCard(
                      title: 'المهامّ',
                      subtitle: 'يوميّة وأسبوعيّة — خبرةٌ وماس',
                      icon: Icons.checklist,
                      onTap: onMissions ?? () => _soon(context),
                    ),
                    _CategoryCard(
                      title: 'البطولات',
                      subtitle: 'بطولة اليوم · فعاليات بجوائز',
                      icon: Icons.emoji_events,
                      onTap: onTournaments ?? () => _soon(context),
                    ),
                    // مشاهدةٌ مجّانيّة ([[spectator-system]]): تُبقي من نفدت
                    // لعباتُه داخل اللعبة، وهداياها ماسٌ خالصٌ للبيت.
                    _CategoryCard(
                      title: 'مباريات حيّة',
                      subtitle: 'شاهد الجاري الآن · شجّع بالهدايا',
                      icon: Icons.connected_tv,
                      onTap: onWatchLive ?? () => _soon(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('قريبًا', textAlign: TextAlign.center),
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ));
  }
}

/// شريط اللاعب العلويّ. مصادَقًا: اسم الخادم + تقييم + Chips/Diamonds حقيقيّة.
/// غير مصادَق: الاسم المحلّي + زرّ «دخول» (لا أرقام وهميّة).
/// **جرسُ الإشعارات** بشارةِ عددٍ — مدخلُ الصندوق ([[fcm-push]]).
class _BellButton extends StatelessWidget {
  final int unread;
  final VoidCallback? onTap;
  const _BellButton({required this.unread, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Stack(
      clipBehavior: Clip.none, // الشارةُ تتجاوز حدَّ الزرّ عمدًا
      children: [
        IconButton(
          icon: Icon(unread > 0 ? Icons.notifications_active : Icons.notifications_none,
              color: unread > 0 ? t.accent : t.text2),
          tooltip: 'الإشعارات',
          onPressed: onTap,
        ),
        if (unread > 0)
          Positioned(
            top: 6,
            left: 4, // الواجهة RTL ⇒ «left» هو الطرف الخارجيّ للأيقونة
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 17),
                decoration: BoxDecoration(
                  color: t.error,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: t.surface, width: 1.5),
                ),
                child: Text(
                  // **يُقصّ عند ٩٩**: عددٌ من أربع خاناتٍ يمطّ الشارةَ فوق الشريط.
                  unread > 99 ? '+99' : '$unread',
                  textAlign: TextAlign.center,
                  // الأرقام لاتينيّةٌ دائمًا (عُرف المشروع) — والعزلُ يمنع BiDi من
                  // قلب «+99» إلى «99+».
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final String name;
  final bool signedIn;

  /// **أهو VIP؟** ⇒ إطارُه الدائريُّ حول صورته وشارتُه الذهبيّةُ مع اسمه.
  final bool isVip;

  /// رمزُ اللاعب المعروض (`ABC123`) — **لا [id] الداخليّ**. فارغٌ ⇒ لا يُعرَض.
  final String tag;
  final int? rating;

  /// **الماس وحده** هو عملةُ التطبيق (قرار المالك 2026-07-15). كانت البطاقة تعرض
  /// رقائقَ وماسًا معًا — عملتان تُربكان، وواحدةٌ منهما لا تُستعمَل. (أُلغيت الرقائق.)
  final int diamonds;
  final VoidCallback? onSignIn;
  final VoidCallback? onSettings;
  final VoidCallback? onProfile;
  final VoidCallback? onNotifications;

  /// عددُ ما لم يُقرأ — شارةُ الجرس. صفرٌ ⇒ جرسٌ بلا شارة.
  final int unread;

  /// رابط صورته النسبيّ (`/avatars/…`) — فارغٌ ⇒ أوّل حرفٍ من اسمه.
  final String avatarUrl;

  const _PlayerBar({
    required this.name,
    required this.signedIn,
    this.isVip = false,
    required this.diamonds,
    this.avatarUrl = '',
    this.tag = '',
    this.rating,
    this.unread = 0,
    this.onSignIn,
    this.onSettings,
    this.onProfile,
    this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line),
        boxShadow: [BoxShadow(color: t.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              // **المدخل الوحيد للملفّ** (قرار المالك 2026-07-15): كان في الشبكة
              // زرُّ «ملفّي» يفتح الشاشة نفسها ⇒ مدخلان لشيءٍ واحد. البطاقةُ أوضح:
              // اسمُك وصورتُك وماسك أمامك، والضغطُ عليها بديهيّ. **لا تُعِد الزرّ.**
              onTap: onProfile,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  // صورتُه الحقيقيّة إن رفعها — وإلّا أوّلُ حرفٍ من اسمه كما كان.
                  // هذه أظهرُ «صورةٍ» في التطبيق: تُرى في كل مرّةٍ يُفتَح فيها.
                  // **بطاقةُ حسابك في اللوبي** — الموضعُ الثاني للإطار الدائريّ
                  // (نصُّ المالك 2026-07-16). أوّلُ ما تراه عن نفسك حين تفتح
                  // التطبيق: يجب أن تجد اشتراكَك فيه.
                  isVip
                      ? SizedBox(
                          width: 68,
                          height: 68,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PlayerAvatar(
                                url: avatarUrl,
                                fallback: name.characters.first,
                                size: 44,
                                borderColor: const Color(0x00000000),
                              ),
                              IgnorePointer(
                                child: Image.asset(
                                    'assets/VIP/frame_gold_round.png',
                                    width: 68,
                                    height: 68),
                              ),
                            ],
                          ),
                        )
                      : PlayerAvatar(
                          url: avatarUrl,
                          fallback: name.characters.first,
                          size: 46,
                          borderColor: t.accent,
                          borderWidth: 2,
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: t.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                            ),
                            // **شارةٌ ذهبيّةٌ مع اسمه** — الموضعُ الثاني في اللوبي.
                            if (isVip) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: t.accent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text('VIP',
                                    textDirection: TextDirection.ltr,
                                    style: TextStyle(
                                        color: t.onAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900)),
                              ),
                            ],
                          ],
                        ),
                        if (signedIn)
                          Row(children: [
                            if (rating != null) _ratingChip(t, rating!),
                            if (rating != null) const SizedBox(width: 6),
                            // **رمزُه المعروض لا معرّفُه الداخليّ** (بلاغ المالك
                            // 2026-07-15): كانت البطاقة تعرض أوّلَ ٦ خاناتٍ من `id`
                            // فيرى اللاعب `#4EECFE` هنا و`#ABC123` في ملفّه — رمزان
                            // لشخصٍ واحد، ولا أحدَ يعرف أيَّهما يُملي على صاحبه.
                            // البطاقةُ سبقت ميزةَ الرمز ولم تُحدَّث معها ([[player-tag]]).
                            // فارغٌ ⇒ خادمٌ أقدمُ من الميزة: لا نعرض شيئًا بدل رمزٍ مخترَع.
                            if (tag.isNotEmpty)
                              Text('#$tag',
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(color: t.text3, fontSize: 11)),
                          ])
                        else
                          Text('غير متصل',
                              style: TextStyle(color: t.text3, fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (signedIn)
            _purse(t, Icons.diamond, const Color(0xFF5BC6F0), diamonds)
          else
            FilledButton(
              onPressed: onSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: t.accent,
                foregroundColor: t.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('دخول', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          // الجرس **للمسجَّلين وحدهم**: بلا حسابٍ لا صندوقَ في الخادم أصلًا،
          // وجرسٌ فارغٌ أبدًا زينةٌ تُربك.
          if (signedIn)
            _BellButton(unread: unread, onTap: onNotifications),
          IconButton(
            icon: Icon(Icons.settings, color: t.text2),
            tooltip: 'الإعدادات',
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }

  Widget _ratingChip(BeloteTheme t, int rating) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(999)),
        child: Text('★ $rating',
            textDirection: TextDirection.ltr,
            style: TextStyle(color: t.onAccent, fontSize: 10, fontWeight: FontWeight.w800)),
      );

  Widget _purse(BeloteTheme t, IconData icon, Color color, int value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text('$value',
              textDirection: TextDirection.ltr,
              style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );
}

/// بطاقة قسم في الرئيسية — عنوان + وصف + أيقونة، ولمسة توهّج ذهبيّ.
/// وصفُ بطاقة الأونلاين — يتبع ما نعرفه لا ما نتمنّاه.
///
/// **`allowance == null` ⇒ الوصفُ الأصليّ**: الحدُّ مُطفأٌ خادميًّا أو لم يُجلَب بعد،
/// و«بقيت لك 5» رقمٌ مخترَعٌ يُكذَّب عند أوّل ضغطة.
String _onlineSubtitle(bool signedIn, PlayAllowanceView? a) {
  if (!signedIn) return 'مع لاعبين حقيقيّين — يتطلّب دخولًا';
  if (a == null) return 'مع لاعبين حقيقيّين';
  // **مَن دفع يرى ما اشتراه**: «0/5» لصاحب تذكرةٍ إهانةٌ لزبون.
  // **ومَن أُهدي لا يُقال له إنّه اشترى**: الجديدُ في سماحه يُرحَّب به لا يُذكَّر
  // بتذكرةٍ لم يشترها — وهي أوّلُ ثلاثة أيّامٍ يقرّر فيها أيبقى أم يذهب.
  if (a.isGrace) {
    return 'أهلًا بك! لعبٌ بلا حدود — الباقي: ${_passLeft(a.graceUntil!)}';
  }
  if (a.unlimited) {
    return 'لعبٌ بلا حدود — الباقي: ${_passLeft(a.unlimitedUntil!)}';
  }
  // **المكتسَبُ يُشكَر عليه**: مَن دعا أصدقاءً يُقال له إنّ لعباتِه الزائدةَ منهم —
  // فيعرف أنّ الدعوةَ نفعت، فيدعو أكثر.
  final earned = a.bonus > 0 ? ' (منها ${a.bonus} من دعوة أصدقائك)' : '';
  return switch (a.remaining) {
    // **يقول ما العمل لا «انتهت» وحدَها**: الأوفلاين حرٌّ بلا حدّ، وهو المخرجُ
    // الصادقُ اليوم (والتذكرةُ تأتي).
    0 => 'انتهت لعباتُك اليوم — تعود غدًا',
    1 => 'بقيت لك لعبةٌ واحدةٌ اليوم$earned',
    2 => 'بقيت لك لعبتان اليوم$earned',
    _ => 'بقيت لك ${a.remaining} لعباتٍ اليوم$earned',
  };
}

/// ما بقي من نافذة «بلا حدود» — **صيغةٌ اسميّةٌ** («الباقي: ساعتان») لا فعليّة:
/// «يبقى ساعتان» يُخطئ التذكيرَ، و«باقٍ 6 يومًا» يُخطئ التمييز. والمثنّى والجمعُ
/// مضبوطان — ركاكةٌ يراها **كلُّ من دفع، كلَّ يوم**.
String _passLeft(DateTime until) {
  final d = until.difference(DateTime.now());
  if (d.isNegative) return 'انتهت';
  if (d.inHours >= 24) {
    return switch (d.inDays) {
      1 => 'يومٌ واحد',
      2 => 'يومان',
      final n => '$n أيّام',
    };
  }
  return switch (d.inHours) {
    0 => 'أقلُّ من ساعة',
    1 => 'ساعةٌ واحدة',
    2 => 'ساعتان',
    final h => '$h ساعات',
  };
}

/// **عدّادُ اللعبات** — «مع عدّاد يظهر له كم من لعبة بقيت له» (نصُّ المالك).
///
/// يُخفى إن جُهل الحدُّ (مُطفأٌ خادميًّا · أو لم يُجلَب بعد · أو غيرُ مصادَق):
/// عدّادٌ يخترع رقمًا أسوأُ من غيابه.
class _PlayCounter extends StatelessWidget {
  const _PlayCounter({required this.allowance});

  final PlayAllowanceView? allowance;

  @override
  Widget build(BuildContext context) {
    final a = allowance;
    if (a == null) return const SizedBox.shrink();
    final t = BeloteTheme.of(context);
    // **صاحبُ التذكرة يرى ما اشترى**: ∞ لا «0/5».
    if (a.unlimited) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: t.accent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.accent),
        ),
        child: Icon(Icons.all_inclusive, size: 15, color: t.accent),
      );
    }
    final out = a.remaining == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: out ? t.error.withValues(alpha: 0.16) : t.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: out ? t.error : t.accent),
      ),
      // الأرقام لاتينيّةٌ دائمًا (CLAUDE.md) — و`ltr` يمنع البادئ من الانقلاب.
      child: Text('${a.remaining}/${a.limit}',
          textDirection: TextDirection.ltr,
          style: TextStyle(
              color: out ? t.error : t.accentBright,
              fontSize: 12.5,
              fontWeight: FontWeight.w800)),
    );
  }
}

/// بطاقةُ قسمٍ في الرئيسيّة — بارزةٌ وتستجيب للمسّ.
///
/// **`big` ليس حجمًا بل رتبة.** البطاقتان الكبيرتان (لعبٌ سريع · أونلاين) تُملأان
/// بتدرّج `accent` كاملًا فتقودان الشاشة؛ والبقيّةُ سطحٌ مرتفعٌ بحافّةٍ ذهبيّة.
/// تسعُ بطاقاتٍ ذهبيّةٍ متساوية = جدارٌ يصرخ كلُّه فلا يقود شيءٌ منه.
///
/// **كلُّ لونٍ مشتقٌّ من الثيم**، فتصير ذهبيّةً في Dark Gold وخشبيّةً في Wood
/// وهادئةً في Marble. لا لونَ مثبَّتًا في الكود — وإلّا ماتت الثيماتُ الخمس.
class _CategoryCard extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final bool big;
  final VoidCallback onTap;

  /// شارةٌ قبل السهم (عدّادُ اللعبات مثلًا). null ⇒ لا شيء.
  final Widget? badge;
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.big = false,
    this.badge,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final big = widget.big;

    // لمعةُ الحافّة العليا: `accentBright` مبيَّضةً — هي ما يعطي الإحساس المعدنيّ.
    // تدرّجٌ بمحطّتين يعطي بلاستيكًا؛ الأربعُ تعطي معدنًا.
    final sheen = Color.lerp(t.accentBright, const Color(0xFFFFFFFF), 0.55)!;

    // على البطاقة الممتلئة يصير `onAccent` لونَ الحبر (هو نقيضُ `accent` في الثيم).
    final ink = big ? t.onAccent : t.text;
    final inkSoft = big ? t.onAccent.withValues(alpha: 0.72) : t.text2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.97 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: big
                  ? [sheen, t.accentBright, t.accent, t.accentDeep]
                  : [t.surface2, t.surface],
              stops: big ? const [0, 0.34, 0.7, 1] : null,
            ),
            border: Border.all(
              color: big ? sheen : t.lineStrong,
              width: big ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(color: t.shadow, blurRadius: 14, offset: const Offset(0, 6)),
              // توهّجٌ حول البطاقة القائدة — يرفعها عن الخلفيّة بلا تكبيرِ حجمها.
              if (big)
                BoxShadow(
                  color: t.accent.withValues(alpha: 0.30),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(18),
              splashColor: ink.withValues(alpha: 0.10),
              highlightColor: Colors.transparent,
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              child: Padding(
                padding: EdgeInsets.all(big ? 22 : 16),
                child: Row(
                  children: [
                    Container(
                      width: big ? 56 : 46,
                      height: big ? 56 : 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: big
                            ? t.onAccent.withValues(alpha: 0.13)
                            : t.accent.withValues(alpha: 0.16),
                        border: Border.all(
                          color: big
                              ? t.onAccent.withValues(alpha: 0.26)
                              : t.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(widget.icon,
                          color: big ? t.onAccent : t.accentBright,
                          size: big ? 28 : 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                              style: TextStyle(
                                  color: ink,
                                  fontSize: big ? 20 : 16,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(widget.subtitle,
                              style: TextStyle(color: inkSoft, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    if (widget.badge != null) ...[
                      // **الشارةُ مرسومةٌ بألوان `accent`** (عدّادُ اللعبات، علامةُ VIP)
                      // وهي تختفي فوق تدرّجٍ ذهبيّ. الحُقُّ الداكن يُعيد لها خلفيّةَ
                      // `onAccent` التي صُمِّمت عليها — بلا لمسِ الشارات نفسها.
                      if (big)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: t.onAccent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: widget.badge!,
                        )
                      else
                        widget.badge!,
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.chevron_left,
                        color: big ? t.onAccent.withValues(alpha: 0.55) : t.text3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
