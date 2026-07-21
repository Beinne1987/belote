import 'package:app/ui/missions_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// **حارسُ الانجراف بين كتالوجَي المهامّ.**
///
/// القائمتان مكرّرتان **عمدًا** (لا حزمةَ مشتركة — `belote_engine` للقواعد وحدَها):
/// الخادمُ يحمل المعرّفَ والهدفَ والجائزة، والعميلُ يحمل الاسمَ العربيَّ والأيقونة.
/// وتكرارٌ بلا حارسٍ يتباعد صامتًا: مهمّةٌ جديدةٌ في الخادم تُعرَض بلا اسمٍ فتُسقَط
/// من الشاشة، فيُنجزها اللاعبُ ولا يراها.
///
/// **المصدر** — `server/lib/missions/missions.dart` (`missionCatalog` بترتيبه).
/// نسخةٌ يدويّةٌ من معرّفات الخادم: لو تغيّرت هناك ولم تُحدَّث هنا سقط هذا الاختبار
/// وهو ما نريد — يُمسك الانجرافَ عند الإيداع لا عند شكوى لاعب. **وقد أمسكه فعلًا**
/// عند توسيع الكتالوج 2026-07-16.
const _serverMissionIds = [
  // اليوميّة
  'daily_play',
  'daily_win',
  'daily_friend',
  'daily_gift',
  'daily_fouja',
  // الأسبوعيّة
  'weekly_play',
  'weekly_win',
  'weekly_friend',
  'weekly_invite',
  'weekly_gifts',
  'weekly_room',
  'weekly_clean',
];

void main() {
  test('كتالوجُ الواجهة يطابق كتالوجَ الخادم — معرّفًا وترتيبًا', () {
    expect([for (final m in missionCatalogUi) m.id], _serverMissionIds);
  });

  test('لكلّ مهمّةٍ اسمٌ عربيٌّ غيرُ فارغ', () {
    for (final m in missionCatalogUi) {
      expect(m.title.trim(), isNotEmpty, reason: m.id);
      expect(m.title, isNot(contains(m.id)), reason: 'لا معرّفَ خامًا في الاسم');
    }
  });

  test('المعرّفات فريدة', () {
    final ids = [for (final m in missionCatalogUi) m.id];
    expect(ids.toSet().length, ids.length);
  });

  test('missionMeta يجد كلَّ معرّفٍ ويردّ null لِما لا يعرف', () {
    for (final id in _serverMissionIds) {
      expect(missionMeta(id), isNotNull, reason: id);
    }
    // خادمٌ أحدثُ يضيف مهمّةً ⇒ null ⇒ تُسقَط بهدوءٍ لا تُعرَض خامًا.
    expect(missionMeta('daily_dance'), isNull);
    expect(missionMeta(''), isNull);
  });
}
