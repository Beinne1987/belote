import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../services/avatar_picker.dart';
import '../theme/belote_theme.dart';
import 'rank_badge.dart';
import 'gift_picker.dart';
import 'honor_badge.dart';
import 'player_avatar.dart';
import 'player_tag_chip.dart';
import 'simple_top_bar.dart';

/// مفتاح صورة الملفّ — **للاختبار وحده**: شجرة الدلالات مُطفأةٌ في بيئة الاختبار
/// فلا تُبلَغ الصورة بوسمها (`Semantics` يبقى للمستخدم الحقيقيّ، لا للاختبار).
@visibleForTesting
const profileAvatarKey = Key('profile-avatar');

/// شاشة الملف الشخصي — بيانات الحساب الحقيقيّة من الخادم (`/me` · `/me/stats`).
/// غير مصادَق ⇒ دعوةٌ لتسجيل الدخول (لا أرقام وهميّة). [onSignIn] يفتح المصادقة.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onSignIn;

  /// ملتقِط الصورة — يُحقَن في الاختبار (`image_picker` يحتاج منصّةً حيّة).
  final AvatarPicker? picker;

  const ProfileScreen({super.key, this.onSignIn, this.picker});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// رفعٌ/حذفٌ جارٍ ⇒ الصورة تحت دوّامة ولا تُنقَر (لا رفعان متزامنان يتسابقان).
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // تحديث الإحصائيات عند فتح الشاشة (لا يحجب؛ يفشل بصمت مُبقيًا آخر معلوم).
    WidgetsBinding.instance.addPostFrameCallback((_) => SessionScope.of(context).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    final session = SessionScope.of(context);
    return Scaffold(
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
              const SimpleTopBar(title: 'ملفّي'),
              Expanded(
                child: session.isSignedIn
                    ? _signedIn(t, session)
                    : _signedOut(t),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _signedOut(BeloteTheme t) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_circle_outlined, color: t.text3, size: 64),
              const SizedBox(height: 14),
              Text('سجّل الدخول لعرض ملفّك وإحصائياتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.text2, fontSize: 15)),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: widget.onSignIn,
                style: FilledButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.onAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: const Text('تسجيل الدخول',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );

  Widget _signedIn(BeloteTheme t, SessionController s) {
    final p = s.player!;
    final stats = s.stats;
    final name = p.displayName.isNotEmpty ? p.displayName : 'اللاعب';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _header(t, name, p, stats, s.diamonds),
        const SizedBox(height: 16),
        _wallet(t, s),
        const SizedBox(height: 16),
        if (stats == null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator(color: t.accent)),
          )
        else
          _statsGrid(t, stats),
        const SizedBox(height: 24),
        _accountActions(t, s, p),
      ],
    );
  }

  Widget _header(BeloteTheme t, String name, AccountPlayer p, PlayerStatsView? stats,
      int diamonds) {
    final place = [
      if (p.countryCode.isNotEmpty) _flag(p.countryCode),
      if (p.city.isNotEmpty) p.city,
    ].join('  ');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.line),
        boxShadow: [BoxShadow(color: t.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          _avatar(t, name, p, SessionScope.of(context).isVip),
          const SizedBox(height: 10),
          Text(name, style: TextStyle(color: t.text, fontSize: 20, fontWeight: FontWeight.w800)),
          if (place.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(place, style: TextStyle(color: t.text2, fontSize: 13)),
          ],
          // رمز اللاعب — يُخفى إن كان الخادم أقدم من الميزة (لا خانةٌ فارغة).
          // **هذا هو الرمزُ نفسُه الذي في بطاقة اللوبي** — كانت تعرض معرّفًا داخليًّا
          // مختلفًا حتى بلاغ المالك 2026-07-15 ([[player-tag]]).
          if (p.tag.isNotEmpty) ...[
            const SizedBox(height: 8),
            PlayerTagChip(tag: p.tag),
          ],
          // **ألقابُ الأسبوع كلُّها هنا** — الطاولةُ تعرض الأعلى وحدَه
          // ([[honors-weekly]]). بلا لقبٍ ⇒ لا صفَّ ولا فراغ.
          const SizedBox(height: 8),
          AllHonorBadges(playerId: p.id),
          // **VIP يظهر في كلّ مكان** (نصُّ المالك 2026-07-16) — وصفحتُه أولى المواضع.
          if (SessionScope.of(context).isVip) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: t.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, size: 14, color: t.onAccent),
                  const SizedBox(width: 4),
                  Text('VIP',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                          color: t.onAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
          // **رصيدُ الماس** (بلاغ المالك 2026-07-15): كان يظهر في بطاقة اللوبي
          // ويختفي عند فتحها — وهذه شاشةُ الحساب، فرصيدُه أولى بها.
          const SizedBox(height: 10),
          _diamonds(t, diamonds),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pill(t, 'التصنيف', '${stats?.rating ?? '—'}', accent: true),
              const SizedBox(width: 10),
              _pill(t, 'نسبة الفوز', stats == null ? '—' : '${stats.winRatePct}%'),
              const SizedBox(width: 10),
              _pill(t, 'المباريات', '${stats?.matches ?? '—'}'),
            ],
          ),
          // **الرتبة** — المهارةُ باسمها وشريطُ تقدّمها نحو التالية. تُخفى إن كان
          // الخادم أقدمَ من الميزة (null): لا رتبةَ تُخترَع في العميل.
          if (stats?.skill != null) ...[
            const SizedBox(height: 14),
            RankProgress(rank: stats!.skill!, rating: stats.rating),
          ],
          // **المستوى** — يُخفى إن كان الخادم أقدمَ من الميزة (level == 0): لا مستوًى
          // مخترَعٌ ولا شريطٌ فارغ.
          if (stats != null && stats.level > 0) ...[
            const SizedBox(height: 14),
            _level(t, stats),
          ],
        ],
      ),
    );
  }

  /// صورة الملفّ: تُنقَر فتُبدَّل. **الشارةُ هي الدعوة** — الدائرةُ وحدها لا تقول
  /// إنّها تُنقَر، فيبقى نصفُ اللاعبين لا يعرفون أنّ لهم صورةً أصلًا (نفسُ ما حدث
  /// لزرّ الهديّة — [[gift-button-visibility]]).
  Widget _avatar(BeloteTheme t, String name, AccountPlayer p, bool vip) =>
      Semantics(
        // عقدةٌ مستقلّة (`container`) لا تُدمَج في حرف الاسم تحتها: قارئ الشاشة
        // يقول «صورة الملفّ، زرّ» لا «م».
        container: true,
        button: true,
        label: 'صورة الملفّ',
        child: GestureDetector(
          key: profileAvatarKey,
          onTap: _busy ? null : () => _editAvatar(t, p),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // **إطارُ VIP الدائريُّ هنا** (نصُّ المالك): المشتركُ يرى إطارَه في
              // ملفّه، وغيرُه يرى الحدَّ الذهبيَّ المعتاد.
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: vip ? const Color(0x00000000) : t.accent, width: 3),
                  boxShadow: [
                    BoxShadow(color: t.accent.withValues(alpha: 0.35), blurRadius: 16)
                  ],
                ),
                child: ClipOval(
                  child: PlayerAvatar(
                    url: p.avatarUrl,
                    // بلا صورة ⇒ أوّل حرفٍ من اسمه (كما كان قبل الميزة) لا إيموجي
                    // عامّ: هذا **ملفُّه هو**، والحرف يخصّه.
                    fallback: name.characters.first,
                    size: 88,
                    borderColor: t.surface2,
                  ),
                ),
              ),
              if (vip)
                Positioned.fill(
                  child: IgnorePointer(
                    child: OverflowBox(
                      maxWidth: 132,
                      maxHeight: 132,
                      child: Image.asset('assets/VIP/frame_gold_round.png',
                          width: 132, height: 132),
                    ),
                  ),
                ),
              // أثناء الرفع: حجابٌ ودوّامة فوق الصورة نفسها — الخبر عند مصدره.
              if (_busy)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.bg.withValues(alpha: 0.6),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(color: t.accent, strokeWidth: 2.4),
                      ),
                    ),
                  ),
                ),
              PositionedDirectional(
                bottom: -2,
                end: -2,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: t.accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: t.surface, width: 2),
                  ),
                  child: Icon(Icons.photo_camera, size: 15, color: t.onAccent),
                ),
              ),
            ],
          ),
        ),
      );

  /// ورقةُ اختيار: معرض · كاميرا · حذف (إن كانت له صورة).
  Future<void> _editAvatar(BeloteTheme t, AccountPlayer p) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: t.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: t.line, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_library, color: t.text2),
              title: Text('اختر من الصور', style: TextStyle(color: t.text)),
              onTap: () => Navigator.pop(c, 'gallery'),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: t.text2),
              title: Text('التقط صورة', style: TextStyle(color: t.text)),
              onTap: () => Navigator.pop(c, 'camera'),
            ),
            if (p.avatarUrl.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete_outline, color: t.error),
                title: Text('احذف الصورة', style: TextStyle(color: t.error)),
                onTap: () => Navigator.pop(c, 'delete'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'delete') return _removeAvatar();
    await _uploadAvatar(
        choice == 'camera' ? AvatarSource.camera : AvatarSource.gallery);
  }

  /// يلتقط ويرفع. **الجلسة تُحدَّث بما يعيده الخادم** لا بما رفعناه: الرابط يصنعه
  /// الخادم من تجزئة المحتوى، فلا يعرفه العميل قبل ردّه.
  Future<void> _uploadAvatar(AvatarSource source) async {
    final s = SessionScope.of(context);
    final picker = widget.picker ?? DeviceAvatarPicker();
    setState(() => _busy = true);
    try {
      final bytes = await picker.pick(source);
      if (bytes == null) return; // ألغى — لا رسالة
      final player = await s.api.uploadAvatar(s.session!.token, bytes);
      await s.updatePlayer(player);
    } on ApiException catch (e) {
      _toast(avatarErrorText(e.message));
    } catch (_) {
      // إذنٌ مرفوض أو عطبُ منصّة — رسالةٌ واحدةٌ صادقة بلا تفاصيل لا تعنيه.
      _toast('تعذّر فتح الصور. تحقّق من الأذونات.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeAvatar() async {
    final s = SessionScope.of(context);
    setState(() => _busy = true);
    try {
      await s.updatePlayer(await s.api.deleteAvatar(s.session!.token));
    } on ApiException catch (e) {
      _toast(avatarErrorText(e.message));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
      ));
  }

  /// **الخروج والحذف — إلزامُ المتاجر.** جوجل بلاي وآبل يشترطان مسارَ حذفٍ **داخل
  /// التطبيق**؛ بلا هذا يُرفض النشر.
  ///
  /// الحذف **لا يُشبه الخروج**: أحمرُ منفصلٌ أسفل الشاشة بفاصلٍ ومسافة، لا زرٌّ
  /// مجاورٌ يُنقَر سهوًا. والخروجُ فوقه لأنّه ما يريده أكثرُ الناس.
  Widget _accountActions(BeloteTheme t, SessionController s, AccountPlayer p) => Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(t, s),
              icon: Icon(Icons.logout, color: t.text2, size: 18),
              label: Text('تسجيل الخروج', style: TextStyle(color: t.text)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: t.line),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Divider(color: t.line),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _confirmDelete(t, s, p),
            icon: Icon(Icons.delete_forever, color: t.error, size: 18),
            label: Text('حذف الحساب نهائيًّا',
                style: TextStyle(color: t.error, fontWeight: FontWeight.w700)),
          ),
        ],
      );

  Future<void> _confirmSignOut(BeloteTheme t, SessionController s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('تسجيل الخروج', style: TextStyle(color: t.text)),
        content: Text('يبقى حسابك كما هو، وتعود إليه بهاتفك وكلمة سرّك.',
            style: TextStyle(color: t.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('تراجع', style: TextStyle(color: t.text2))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('اخرج', style: TextStyle(color: t.accentBright))),
        ],
      ),
    );
    if (ok == true) await s.signOut();
  }

  /// **تأكيدٌ حقيقيّ: يكتب رمزه بيده.** نقرةٌ واحدةٌ على فعلٍ لا رجعة فيه ليست
  /// تأكيدًا — والكتابةُ تُجبر على التمهّل. (رمزُه معروضٌ فوق في الشاشة نفسها،
  /// فلا يُطالَب بما لا يملك.)
  Future<void> _confirmDelete(
      BeloteTheme t, SessionController s, AccountPlayer p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => _DeleteDialog(tag: p.tag),
    );
    if (ok != true || !mounted) return;
    try {
      await s.api.deleteAccount(s.session!.token);
      await s.signOut(); // الحساب زال ⇒ لا جلسةَ تبقى على الجهاز
      if (mounted) Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('تعذّر الحذف: ${e.message}', textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  /// **المستوى وشريطُ تقدّمه.**
  ///
  /// الرقمُ وحده ليس تقدّمًا — **الشريطُ هو التقدّم**: يقول أين هو ممّا يليه، وكم
  /// بقي بالضبط. ومستوًى بلا خطوةٍ تاليةٍ ظاهرةٍ رقمٌ جامد.
  ///
  /// **كلُّ أرقامه من الخادم** ولا يُحسَب المنحنى هنا: نسخةٌ ثانيةٌ منه تجعل حزمةً
  /// قديمةً تعرض مستوًى غيرَ الذي يراه الخادم، وهو ما لا يُصدَّق ولا يُشتكى منه بوضوح.
  Widget _level(BeloteTheme t, PlayerStatsView s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('المستوى ',
                  style: TextStyle(color: t.text2, fontSize: 12.5)),
              Text('${s.level}',
                  // الأرقام لاتينيّةٌ دائمًا (CLAUDE.md)
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      color: t.accent, fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${s.xpToNext} خبرة للتالي',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: t.text3, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              // `clamp` حارسُ عرضٍ لا تجميل: قيمةٌ خارج المدى من خادمٍ أحدثَ تُلقي
              // استثناءً يُسقط الشاشةَ كلَّها لأجل شريط.
              value: s.levelProgress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: t.surface2,
              valueColor: AlwaysStoppedAnimation<Color>(t.accent),
            ),
          ),
        ],
      );

  /// **محفظتي** — ما يملكه: ماسٌ وهدايا (طلب المالك 2026-07-15).
  ///
  /// **الأسكناتُ ليست هنا وهي قادمة.** لم أرسم لها صندوقًا فارغًا مكتوبًا فيه
  /// «قريبًا»: مكانُها في **المعمار** لا في الشاشة — المحفظةُ خريطةُ عملاتٍ يميّز
  /// الصنفَ بادئتُها، فالأسكنُ `skin:<id>` يظهر بقارئٍ كـ`ownedGifts` وقسمٍ مثل هذا،
  /// بلا مسارٍ ولا جدولٍ ولا إعادةِ تصميم. وصندوقُ «قريبًا» وعدٌ يبلى ويبدو نقصًا.
  Widget _wallet(BeloteTheme t, SessionController s) {
    final gifts = s.ownedGifts;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('محفظتي',
              style: TextStyle(
                  color: t.text, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.diamond, color: Color(0xFF5BC6F0), size: 18),
              const SizedBox(width: 8),
              Text('الماس', style: TextStyle(color: t.text2, fontSize: 13)),
              const Spacer(),
              Text('${s.diamonds}',
                  // الأرقام لاتينيّةٌ دائمًا (CLAUDE.md)
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                      color: t.text, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: t.line, height: 1),
          const SizedBox(height: 12),
          Text('هداياي', style: TextStyle(color: t.text2, fontSize: 13)),
          const SizedBox(height: 8),
          if (gifts.isEmpty)
            // **حالةٌ تشرح نفسها وتدلّ**: «لا هدايا» وحدها تُحبِط ولا تُرشد.
            Text('لا هدايا بعد — اشترِ باقةً من المتجر.',
                style: TextStyle(color: t.text3, fontSize: 12.5))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in gifts.entries)
                  if (_giftEmojiOf(e.key) != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: t.surface2,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: t.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_giftEmojiOf(e.key)!,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 5),
                          Text('×${e.value}',
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                  color: t.text,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
              ],
            ),
        ],
      ),
    );
  }

  /// رمزُ الهديّة، أو null لمعرّفٍ لا نعرفه (خادمٌ أحدثُ من الحزمة) ⇒ يُسقَط بدل
  /// عرضِ معرّفٍ خامٍ في محفظته.
  String? _giftEmojiOf(String id) => giftEmoji(id);

  /// رصيدُ الماس — **عملةُ التطبيق الوحيدة** (قرار المالك 2026-07-15).
  Widget _diamonds(BeloteTheme t, int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF5BC6F0).withValues(alpha: .12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF5BC6F0).withValues(alpha: .5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.diamond, color: Color(0xFF5BC6F0), size: 16),
            const SizedBox(width: 6),
            // الأرقام لاتينيّةٌ دائمًا حتى في الواجهة العربيّة (CLAUDE.md).
            Text('$n',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    color: t.text, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _pill(BeloteTheme t, String k, String v, {bool accent = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent ? t.accent : t.line),
        ),
        child: Column(children: [
          Text(v,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: accent ? t.accent : t.text, fontSize: 17, fontWeight: FontWeight.w800)),
          Text(k, style: TextStyle(color: t.text3, fontSize: 11)),
        ]),
      );

  Widget _statsGrid(BeloteTheme t, PlayerStatsView s) {
    final stats = <(String, String)>[
      ('نسبة الفوز', '${s.winRatePct}%'),
      ('المباريات', '${s.matches}'),
      ('الفوز', '${s.wins}'),
      ('الخسارة', '${s.losses}'),
      ('أفضل سلسلة', '${s.bestStreak}'),
      ('السلسلة الحالية', '${s.winStreak}'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [
        for (final (k, v) in stats)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(v,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: t.text, fontSize: 22, fontWeight: FontWeight.w800)),
                Text(k, style: TextStyle(color: t.text2, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  /// علم من رمز دولةٍ ثنائيّ (ISO) عبر حروف المؤشّر الإقليميّ.
  String _flag(String code) {
    if (code.length != 2) return code;
    final up = code.toUpperCase();
    return String.fromCharCodes(
        [0x1F1E6 + (up.codeUnitAt(0) - 65), 0x1F1E6 + (up.codeUnitAt(1) - 65)]);
  }
}

/// نافذةُ حذفٍ **لا تُقبَل حتى يُكتَب الرمز**. تسرد ما يُفقَد صراحةً: من لا يعرف ما
/// يخسره لم يُؤخَذ إذنُه حقًّا.
class _DeleteDialog extends StatefulWidget {
  final String tag;
  const _DeleteDialog({required this.tag});

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _ctrl = TextEditingController();
  bool get _matches =>
      widget.tag.isNotEmpty &&
      _ctrl.text.trim().replaceAll('#', '').toUpperCase() == widget.tag;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return AlertDialog(
      backgroundColor: t.surface,
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: t.error),
          const SizedBox(width: 8),
          Expanded(
              child: Text('حذف الحساب نهائيًّا',
                  style: TextStyle(color: t.text, fontSize: 17))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'يزول اسمك ورمزك وماسك وتصنيفك وأصدقاؤك. لا رجعة في هذا.\n'
            'يبقى رقمك متاحًا لحسابٍ جديدٍ إن أردت العودة.',
            style: TextStyle(color: t.text2, fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 14),
          Text('اكتب رمزك للتأكيد:', style: TextStyle(color: t.text2, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textDirection: TextDirection.ltr, // الرمز لاتينيٌّ دائمًا
            textAlign: TextAlign.left,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: t.text, letterSpacing: 3, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: widget.tag,
              hintStyle: TextStyle(color: t.text3, letterSpacing: 3),
              filled: true,
              fillColor: t.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('تراجع', style: TextStyle(color: t.text2))),
        TextButton(
          // معطّلٌ حتى يطابق: الزرُّ الرماديّ يقول «تمهّل» بلا كلام.
          onPressed: _matches ? () => Navigator.pop(context, true) : null,
          child: Text('احذف حسابي',
              style: TextStyle(
                  color: _matches ? t.error : t.text3, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
