import 'package:flutter/material.dart';

import '../net/api_client.dart';
import '../net/session_controller.dart';
import '../theme/belote_theme.dart';
import 'simple_top_bar.dart';

/// اسمُ المهمّة عربيًّا. **يجب أن يطابق `missionCatalog`** في
/// `server/lib/missions/missions.dart` معرّفًا — الخادمُ لا يحمل نصًّا (كالهدايا).
/// يحرس التطابقَ `test/mission_sync_test.dart`.
class MissionItem {
  final String id;
  final String title;
  final IconData icon;
  const MissionItem(this.id, this.title, this.icon);
}

const missionCatalogUi = <MissionItem>[
  MissionItem('daily_play', 'العب ثلاث مباريات', Icons.sports_esports),
  MissionItem('daily_win', 'فُزْ بمباراة', Icons.emoji_events),
  MissionItem('daily_friend', 'العب مع صديق', Icons.people),
  MissionItem('daily_gift', 'أهدِ هديّة', Icons.card_giftcard),
  MissionItem('daily_fouja', 'اكشِف فوجةً واحدة', Icons.gavel),
  MissionItem('weekly_play', 'العب عشرين مباراة', Icons.sports_esports),
  MissionItem('weekly_win', 'فُزْ بعشر مباريات', Icons.emoji_events),
  MissionItem('weekly_friend', 'العب ثلاث مباريات مع صديق', Icons.people),
  MissionItem('weekly_invite', 'ادعُ صديقًا إلى طاولتك', Icons.person_add),
  MissionItem('weekly_gifts', 'أهدِ عشرَ هدايا', Icons.card_giftcard),
  MissionItem('weekly_room', 'أنشئ غرفةً خاصّة', Icons.meeting_room),
  MissionItem('weekly_clean', 'العب عشرَ مبارياتٍ بلا فوجة', Icons.verified),
];

MissionItem? missionMeta(String id) {
  for (final m in missionCatalogUi) {
    if (m.id == id) return m;
  }
  return null;
}

/// **شاشة المهامّ** — يوميّةٌ وأسبوعيّة، لكلٍّ خبرتُها وماسُها.
///
/// **كلُّ قرارٍ من الخادم**: التقدّمُ والجائزةُ ومتى تُقبَض. حسابٌ ثانٍ هنا يجعل
/// الزرَّ يُضيء لِما يرفضه الخادم — فيلمسه اللاعبُ ويخيب.
class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  List<MissionView>? _missions;
  String? _error;
  String? _claiming;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final s = widget.session.session;
    if (s == null) return;
    try {
      final m = await widget.session.api.missions(s.token);
      if (mounted) setState(() => _missions = m);
    } on ApiException catch (e) {
      // 503 = المهامّ مُطفأةٌ خادميًّا: حالةٌ تُشرَح لا عطبٌ يُبلَّغ.
      if (mounted) {
        setState(() => _error =
            e.status == 503 ? 'المهامّ غير متاحةٍ الآن.' : 'تعذّر جلب المهامّ');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر الاتّصال');
    }
  }

  Future<void> _claim(MissionView m) async {
    setState(() => _claiming = m.id);
    try {
      await widget.session.claimMission(m.id);
      if (!mounted) return;
      _toast('نلت ${m.diamonds}💎 و${m.xp} خبرة');
      await _load(); // الحالةُ تغيّرت ⇒ نُعيد جلبها من مصدرها
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409 ⇒ الشاشةُ متأخّرةٌ عن الحقيقة (قُبضت في جهازٍ آخر · انقضى اليوم)
      // ⇒ أعِد الجلبَ بدل أن تُلقي باللوم على اللاعب.
      _toast(e.status == 409 ? 'تغيّرت حالةُ المهمّة' : 'تعذّر القبض');
      if (e.status == 409) await _load();
    } catch (_) {
      if (mounted) _toast('تعذّر الاتّصال');
    } finally {
      if (mounted) setState(() => _claiming = null);
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
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
              const SimpleTopBar(title: 'المهامّ'),
              Expanded(child: _body(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BeloteTheme t) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: t.text3)),
            TextButton(onPressed: _load, child: const Text('إعادة')),
          ],
        ),
      );
    }
    if (_missions == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final daily = [for (final m in _missions!) if (m.daily) m];
    final weekly = [for (final m in _missions!) if (!m.daily) m];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (daily.isNotEmpty) ...[
            _sectionTitle(t, 'يوميّة', 'تُصفَّر كلَّ يوم'),
            for (final m in daily) _tile(t, m),
            const SizedBox(height: 16),
          ],
          if (weekly.isNotEmpty) ...[
            _sectionTitle(t, 'أسبوعيّة', 'تُصفَّر كلَّ اثنين'),
            for (final m in weekly) _tile(t, m),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BeloteTheme t, String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(title,
                style: TextStyle(
                    color: t.text, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text(sub, style: TextStyle(color: t.text3, fontSize: 11.5)),
          ],
        ),
      );

  Widget _tile(BeloteTheme t, MissionView m) {
    final meta = missionMeta(m.id);
    // **معرّفٌ لا نعرفه يُسقَط**: خادمٌ أحدثُ يضيف مهمّةً ⇒ عرضُ معرّفها الخام أقبحُ
    // من إسقاطها، ولا نخترع لها اسمًا.
    if (meta == null) return const SizedBox.shrink();

    final busy = _claiming == m.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: m.claimable ? t.accent : t.line, width: m.claimable ? 1.4 : 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(meta.icon,
                  size: 20, color: m.claimed ? t.text3 : t.accentBright),
              const SizedBox(width: 10),
              Expanded(
                child: Text(meta.title,
                    style: TextStyle(
                        color: m.claimed ? t.text3 : t.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
              ),
              _reward(t, m),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: m.ratio,
                    minHeight: 6,
                    backgroundColor: t.surface2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        m.claimed ? t.text3 : t.accent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${m.progress}/${m.target}',
                  // الأرقام لاتينيّةٌ دائمًا (CLAUDE.md)
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: t.text2, fontSize: 12)),
              const SizedBox(width: 10),
              _action(t, m, busy),
            ],
          ),
        ],
      ),
    );
  }

  /// الجائزةُ ظاهرةٌ **قبل** الإنجاز: مهمّةٌ لا يُعرَف ثمنُها لا تُحفّز.
  Widget _reward(BeloteTheme t, MissionView m) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${m.xp}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: t.text3, fontSize: 11.5, fontWeight: FontWeight.w700)),
          Text(' خبرة', style: TextStyle(color: t.text3, fontSize: 11.5)),
          const SizedBox(width: 8),
          const Icon(Icons.diamond, size: 12, color: Color(0xFF5BC6F0)),
          const SizedBox(width: 3),
          Text('${m.diamonds}',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  color: t.text2, fontSize: 11.5, fontWeight: FontWeight.w800)),
        ],
      );

  /// **الزرُّ يتبع الخادم**: `claimable` قرارُه لا حسابُنا.
  Widget _action(BeloteTheme t, MissionView m, bool busy) {
    if (m.claimed) {
      return Icon(Icons.check_circle, size: 20, color: t.accent);
    }
    if (!m.claimable) {
      // غيرُ مكتملةٍ ⇒ لا زرَّ يُلمَس فلا يحدث شيء (نظيرُ درس زرّ الهديّة).
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 30,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
        ),
        onPressed: busy ? null : () => _claim(m),
        child: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('اقبض'),
      ),
    );
  }
}
