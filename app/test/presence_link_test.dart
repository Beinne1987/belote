import 'dart:async';
import 'dart:convert';

import 'package:app/net/presence_link.dart';
import 'package:app/net/table_client.dart';
import 'package:flutter_test/flutter_test.dart';

/// **قناةُ الحضور في العميل** — الوجهُ الآخر من `presence_channel_test` الخادميّ.
///
/// العطبُ الذي وُلدت منه: الخادمُ كان يعرف الحضور بدقّة، والعميلُ لا يفتح قناةً
/// إلّا في شاشة اللعب ⇒ صاحبُك يتصفّح اللوبي وأنت تراه رماديًّا فلا تدعوه.
///
/// وما يُفحَص هنا هو **متى تُفتَح ومتى تُغلَق** لا محتواها: كلُّ حالةِ إغلاقٍ منها
/// قرارٌ (خروجٌ · خلفيّةٌ · شاشةُ لعبٍ مفتوحة)، وكسرُ أيٍّ منها يُعيد إمّا النقطةَ
/// الرماديّةَ الكاذبة أو الدعوةَ المعروضةَ مرّتين.
void main() {
  late List<Uri> opened;
  late List<StreamController<String>> feeds;

  PresenceLink build() {
    opened = [];
    feeds = [];
    return PresenceLink(clientFactory: (uri) {
      opened.add(uri);
      final feed = StreamController<String>.broadcast();
      feeds.add(feed);
      return LiveTableClient(incoming: feed.stream, send: (_) {});
    });
  }

  test('التوكن يفتح القناة، ومسحُه يغلقها', () {
    final link = build();
    expect(link.isLinked, isFalse, reason: 'لا حضورَ قبل الدخول');

    link.setToken('jwt');
    expect(link.isLinked, isTrue);
    expect(opened.single.queryParameters['token'], 'jwt');
    expect(opened.single.queryParameters['mode'], 'presence',
        reason: 'خاملةٌ صراحةً — وإلّا سرقت لقطاتِ الطاولة من شاشة اللعب');

    link.setToken(null); // خروج
    expect(link.isLinked, isFalse);
  });

  test('الذهابُ إلى الخلفيّة يُغلقها، والعودةُ تفتحها من جديد', () {
    final link = build()..setToken('jwt');
    link.setForeground(false);
    expect(link.isLinked, isFalse,
        reason: '«متّصل» تعني «يراك الآن» — ومن أغلق الشاشة لا يراك');
    link.setForeground(true);
    expect(link.isLinked, isTrue);
    expect(opened, hasLength(2));
  });

  test('شاشةُ اللعب توقفها — قناتُها تكفي، وقناتان تعنيان دعوةً مرّتين', () {
    final link = build()..setToken('jwt');
    link.pause();
    expect(link.isLinked, isFalse);
    link.resume();
    expect(link.isLinked, isTrue);
  });

  test('**عدّادٌ لا رايةٌ**: شاشتا لعبٍ متراكمتان لا تفكّ إحداهما إيقافَ الأخرى',
      () {
    final link = build()..setToken('jwt');
    link.pause();
    link.pause();
    link.resume();
    expect(link.isLinked, isFalse, reason: 'ما تزال واحدةٌ مفتوحة');
    link.resume();
    expect(link.isLinked, isTrue);
  });

  test('الدعوةُ الواردة تُبثّ لمن يعرضها', () async {
    final link = build()..setToken('jwt');
    final got = <InviteEvent>[];
    link.invites.listen(got.add);

    feeds.single.add(jsonEncode({
      'phase': 'invite',
      'from': {'id': 'B', 'displayName': 'بلال', 'avatarUrl': '/avatars/b.jpg'},
      'code': 'XYZ12',
      'seat': 2,
    }));
    await Future<void>.delayed(Duration.zero);

    expect(got.single.fromName, 'بلال');
    expect(got.single.code, 'XYZ12');
    expect(got.single.fromAvatarUrl, '/avatars/b.jpg',
        reason: 'وجهُ الداعي في النافذة — يعرفه قبل أن يقرأ اسمه');
  });

  test('ما ليس دعوةً يُهمَل بهدوء (القناةُ خاملة)', () async {
    final link = build()..setToken('jwt');
    final got = <InviteEvent>[];
    link.invites.listen(got.add);

    feeds.single.add(jsonEncode({'phase': 'طورٌ لم يُخلَق بعد'}));
    feeds.single.add(jsonEncode({'error': 'شيءٌ ما'}));
    await Future<void>.delayed(Duration.zero);

    expect(got, isEmpty);
  });

  test('نداءان بنفس التوكن ⇒ قناةٌ واحدة (تحديثُ الجلسة لا يُعيد الاتّصال)', () {
    final link = build()
      ..setToken('jwt')
      ..setToken('jwt');
    expect(opened, hasLength(1));
  });
}
