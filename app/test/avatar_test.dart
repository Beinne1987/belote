import 'dart:convert';
import 'dart:typed_data';

import 'package:app/app_settings.dart';
import 'package:app/net/api_client.dart';
import 'package:app/net/api_config.dart';
import 'package:app/net/session_controller.dart';
import 'package:app/net/session_store.dart';
import 'package:app/game/seat_player.dart';
import 'package:app/net/table_client.dart';
import 'package:app/services/avatar_picker.dart';
import 'package:app/theme/theme_manager.dart';
import 'package:app/ui/home_screen.dart';
import 'package:app/ui/player_avatar.dart';
import 'package:app/ui/player_card_square.dart';
import 'package:app/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **صورة الملفّ** في الواجهة (مهمّة ٢ من الإبيك الاجتماعيّ).
///
/// ما يُفحَص هنا هو ما تكسره الشيفرة بصمت: أنّ الرفع يُحدّث الجلسة **بردّ الخادم**
/// لا بما رُفع · أنّ الإلغاء ليس خطأً · أنّ الخطأ يُعرَض بالعربيّة لا برمزٍ خام ·
/// أنّ الرابط النسبيّ يُركَّب على عنوان الخادم.
final _config = ApiConfig.fromOrigin('http://test.local/belote');

http.Response _json(Object o) => http.Response(jsonEncode(o), 200,
    headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, dynamic> _player({String avatar = ''}) => {
      'id': 'p1',
      'tag': 'BC2345',
      'phone': '+22200000000',
      'displayName': 'محمد',
      'countryCode': 'MR',
      'city': 'نواكشوط',
      'avatarUrl': avatar,
    };

/// ملتقِطٌ مزيّف: `image_picker` يحتاج منصّةً حيّة.
class _FakePicker implements AvatarPicker {
  final Uint8List? result;
  final Object? error;
  AvatarSource? asked;
  _FakePicker({this.result, this.error});

  @override
  Future<Uint8List?> pick(AvatarSource source) async {
    asked = source;
    if (error != null) throw error!;
    return result;
  }
}

SessionController _controller(MockClient m) => SessionController(
    api: ApiClient(config: _config, httpClient: m), store: SessionStore());

AuthSession _sess({String avatar = ''}) => AuthSession(
      token: 'tok',
      player: AccountPlayer.fromJson(_player(avatar: avatar)),
      isNew: false,
    );

Widget _wrap(SessionController c, AvatarPicker picker) => ThemeScope(
      manager: ThemeManager(),
      child: SessionScope(
        controller: c,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ProfileScreen(picker: picker),
          ),
        ),
      ),
    );

/// ردٌّ افتراضيّ للمحفظة/الإحصاء كي لا تفشل `refresh` في كل اختبار.
http.Response? _common(http.Request req) {
  if (req.url.path.endsWith('/me/wallet')) return _json({'diamonds': 10});
  if (req.url.path.endsWith('/me/stats')) {
    return _json({
      'rating': 1000,
      'matches': 0,
      'wins': 0,
      'losses': 0,
      'winStreak': 0,
      'bestStreak': 0,
      'winRate': 0,
    });
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PlayerAvatar.absolute', () {
    test('الرابط النسبيّ يُركَّب على عنوان الخادم — والفارغ يبقى null', () {
      // بادئة `/belote` (خلف nginx) جزءٌ من العنوان ⇒ يجب أن تبقى.
      expect(PlayerAvatar.absolute('/avatars/abc.jpg'),
          contains('/belote/avatars/abc.jpg'));
      expect(PlayerAvatar.absolute(''), isNull,
          reason: 'بلا صورة ⇒ لا طلبَ شبكةٍ أصلًا');
    });
  });

  group('LobbySeat', () {
    test('يقرأ `avatar` من اللقطة، وغيابُه ⇒ فارغٌ لا عطب', () {
      final withA = LobbySeat.fromJson({
        'seat': 1,
        'ai': false,
        'name': 'سيدي',
        'avatar': '/avatars/x.jpg',
      });
      expect(withA.avatarUrl, '/avatars/x.jpg');

      // خادمٌ قديمٌ قبل الحقل — يجب ألّا ترمي ([[ws-event-forward-compat]]).
      final without = LobbySeat.fromJson({'seat': 2, 'ai': false, 'name': 'اعل'});
      expect(without.avatarUrl, '');
    });
  });

  group('PlayerCardSquare', () {
    Widget card(String avatarUrl) => ThemeScope(
          manager: ThemeManager(),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: PlayerCardSquare(
                  name: 'محمد',
                  emoji: '🙂',
                  avatarUrl: avatarUrl,
                  rank: PlayerRank.expert,
                  size: 78,
                ),
              ),
            ),
          ),
        );

    testWidgets('بلا صورة ⇒ الإيموجي كما كان قبل الميزة', (t) async {
      await t.pumpWidget(card(''));
      await t.pump(const Duration(milliseconds: 250));
      expect(find.text('🙂'), findsOneWidget);
    });

    testWidgets('بصورة ⇒ لا تُرسَم شبكةٌ ولا يفيض التخطيط', (t) async {
      // شبكةُ الاختبار تردّ 400 دائمًا ⇒ هذا هو **مسار الفشل** بعينه: يجب أن يعود
      // إلى الإيموجي بهدوء لا أن يرمي أو يرسم أيقونة عطبٍ في وجه الشريك.
      await t.pumpWidget(card('/avatars/${'a' * 32}.jpg'));
      await t.pump(const Duration(milliseconds: 250));
      expect(TestWidgetsFlutterBinding.instance.takeException(), isNull);
      expect(find.byType(PlayerAvatar), findsOneWidget);
    });
  });

  // **بلاغ المالك (2026-07-15): «صورة اللاعب لا تظهر على ملفه في اللوبي»** — بطاقة
  // الحساب أعلى الشاشة الرئيسيّة كانت وحدها بلا صورة (تعليقُها نفسُه يَعِد بـ«صورتُك»).
  // أظهرُ صورةٍ في التطبيق: تُرى كلّما فُتح. غابت لأنّي وصلتُ الطاولة والأصدقاء واللوبي
  // والملفّ ونسيتُها — فهذا اختبارُها.
  group('HomeScreen — بطاقة الحساب', () {
    Widget home(SessionController c) => ThemeScope(
          manager: ThemeManager(),
          child: AppSettingsScope(
            settings: AppSettings(),
            child: SessionScope(
              controller: c,
              child: MaterialApp(
                home: Directionality(
                  textDirection: TextDirection.rtl,
                  child: HomeScreen(onPlay: () {}),
                ),
              ),
            ),
          ),
        );

    testWidgets('لصاحب الصورة ⇒ تُعرَض صورتُه لا حرفُ اسمه', (t) async {
      final c = _controller(MockClient((req) async => _common(req) ?? _json(_player())));
      await c.signIn(_sess(avatar: '/avatars/${'b' * 32}.jpg'));
      await t.pumpWidget(home(c));
      await t.pump(const Duration(milliseconds: 200));

      final av = t.widget<PlayerAvatar>(find.byType(PlayerAvatar).first);
      expect(av.url, '/avatars/${'b' * 32}.jpg',
          reason: 'البطاقة تمرّر رابط صورته — لا تكتفي بالحرف');
    });

    testWidgets('بلا صورة ⇒ حرفُ اسمه كما كان قبل الميزة', (t) async {
      final c = _controller(MockClient((req) async => _common(req) ?? _json(_player())));
      await c.signIn(_sess());
      await t.pumpWidget(home(c));
      await t.pump(const Duration(milliseconds: 200));

      final av = t.widget<PlayerAvatar>(find.byType(PlayerAvatar).first);
      expect(av.url, '');
      expect(av.fallback, 'م', reason: 'أوّل حرفٍ من «محمد»');
    });
  });

  group('avatarErrorText', () {
    test('يترجم رموز الخادم ولا يُظهر رمزًا خامًّا', () {
      expect(avatarErrorText('avatar_tooLarge'), contains('كبيرة'));
      expect(avatarErrorText('avatar_badType'), contains('صورة'));
    });
  });

  group('ApiClient', () {
    test('الرفع يرسل البايتات خامّةً إلى /me/avatar بتوكن', () async {
      late http.Request seen;
      final api = ApiClient(
        config: _config,
        httpClient: MockClient((req) async {
          seen = req;
          return _json(_player(avatar: '/avatars/new.jpg'));
        }),
      );
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 3]);
      final p = await api.uploadAvatar('tok', bytes);

      expect(seen.url.path, '/belote/me/avatar');
      expect(seen.headers['authorization'], 'Bearer tok');
      expect(seen.bodyBytes, bytes, reason: 'خامّةً لا base64 ولا multipart');
      expect(p.avatarUrl, '/avatars/new.jpg');
    });

    test('413 ⇒ ApiException برمزٍ يترجمه العميل', () async {
      final api = ApiClient(
        config: _config,
        httpClient: MockClient((_) async => http.Response(
            jsonEncode({'error': 'avatar_tooLarge'}), 413,
            headers: {'content-type': 'application/json'})),
      );
      expect(
        () => api.uploadAvatar('tok', Uint8List.fromList([1])),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 413)),
      );
    });
  });

  group('SessionController.updatePlayer', () {
    test('يستبدل اللاعب ويحفظ الجلسة — لا يعود القديم بعد الإقلاع', () async {
      final c = _controller(MockClient((req) async => _common(req) ?? _json({})));
      await c.signIn(_sess());
      await c.updatePlayer(AccountPlayer.fromJson(_player(avatar: '/avatars/n.jpg')));

      expect(c.player!.avatarUrl, '/avatars/n.jpg');
      expect(c.session!.token, 'tok', reason: 'الملفّ تغيّر لا الهويّة');

      // الجلسة **المحفوظة** تحمل الصورة: بلا الحفظ يعود الملفّ القديم عند الإقلاع.
      final reloaded = await SessionStore().load();
      expect(reloaded!.player.avatarUrl, '/avatars/n.jpg');
    });
  });

  group('ProfileScreen', () {
    testWidgets('اختيار صورةٍ من المعرض ⇒ ترفع وتُحدّث الجلسة بردّ الخادم',
        (tester) async {
      var uploads = 0;
      final c = _controller(MockClient((req) async {
        final common = _common(req);
        if (common != null) return common;
        if (req.url.path.endsWith('/me/avatar')) {
          uploads++;
          return _json(_player(avatar: '/avatars/uploaded.jpg'));
        }
        return _json(_player());
      }));
      await c.signIn(_sess());

      final picker = _FakePicker(result: Uint8List.fromList([0xFF, 0xD8, 0xFF, 9]));
      await tester.pumpWidget(_wrap(c, picker));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(profileAvatarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اختر من الصور'));
      await tester.pumpAndSettle();

      expect(picker.asked, AvatarSource.gallery);
      expect(uploads, 1);
      expect(c.player!.avatarUrl, '/avatars/uploaded.jpg',
          reason: 'الرابط من ردّ الخادم — العميل لا يعرفه قبله');
    });

    testWidgets('«التقط صورة» يسأل الكاميرا لا المعرض', (tester) async {
      final c = _controller(MockClient((req) async =>
          _common(req) ?? _json(_player(avatar: '/avatars/cam.jpg'))));
      await c.signIn(_sess());

      final picker = _FakePicker(result: Uint8List.fromList([0xFF, 0xD8, 0xFF, 9]));
      await tester.pumpWidget(_wrap(c, picker));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(profileAvatarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('التقط صورة'));
      await tester.pumpAndSettle();

      expect(picker.asked, AvatarSource.camera);
    });

    testWidgets('الإلغاء ليس خطأً: لا رفعَ ولا رسالة', (tester) async {
      var uploads = 0;
      final c = _controller(MockClient((req) async {
        if (req.url.path.endsWith('/me/avatar')) uploads++;
        return _common(req) ?? _json(_player());
      }));
      await c.signIn(_sess());

      await tester.pumpWidget(_wrap(c, _FakePicker(result: null))); // ألغى
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(profileAvatarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اختر من الصور'));
      await tester.pumpAndSettle();

      expect(uploads, 0);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('رفضُ الخادم يُعرَض **بالعربيّة** لا برمزٍ خام', (tester) async {
      final c = _controller(MockClient((req) async {
        final common = _common(req);
        if (common != null) return common;
        return http.Response(jsonEncode({'error': 'avatar_tooLarge'}), 413,
            headers: {'content-type': 'application/json'});
      }));
      await c.signIn(_sess());

      await tester.pumpWidget(
          _wrap(c, _FakePicker(result: Uint8List.fromList([0xFF, 0xD8, 0xFF]))));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(profileAvatarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اختر من الصور'));
      await tester.pumpAndSettle();

      expect(find.text(avatarErrorText('avatar_tooLarge')), findsOneWidget);
      expect(find.textContaining('avatar_'), findsNothing, reason: 'لا رمزَ خامّ');
    });

    testWidgets('إذنٌ مرفوض (عطب منصّة) ⇒ رسالةٌ مفهومة لا انهيار', (tester) async {
      final c = _controller(MockClient((req) async => _common(req) ?? _json(_player())));
      await c.signIn(_sess());

      await tester.pumpWidget(_wrap(c, _FakePicker(error: Exception('no permission'))));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(profileAvatarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('اختر من الصور'));
      await tester.pumpAndSettle();

      expect(find.textContaining('الأذونات'), findsOneWidget);
    });

    testWidgets('بلا صورة ⇒ لا خيارَ حذفٍ أصلًا (لا فعلَ بلا معنى)', (tester) async {
      final c = _controller(MockClient((req) async => _common(req) ?? _json(_player())));
      await c.signIn(_sess()); // بلا صورة
      await tester.pumpWidget(_wrap(c, _FakePicker()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(profileAvatarKey));
      await tester.pumpAndSettle();
      expect(find.text('احذف الصورة'), findsNothing);
    });

    testWidgets('له صورة ⇒ الحذف يُفرغها في الجلسة', (tester) async {
      var deletes = 0;
      final c = _controller(MockClient((req) async {
        final common = _common(req);
        if (common != null) return common;
        if (req.method == 'DELETE' && req.url.path.endsWith('/me/avatar')) {
          deletes++;
          return _json(_player()); // الخادم يُعيد اللاعب بلا صورة
        }
        return _json(_player());
      }));
      await c.signIn(_sess(avatar: '/avatars/old.jpg'));
      await tester.pumpWidget(_wrap(c, _FakePicker()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(profileAvatarKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('احذف الصورة'));
      await tester.pumpAndSettle();

      expect(deletes, 1);
      expect(c.player!.avatarUrl, '');
    });
  });
}
