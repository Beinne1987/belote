import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../boot.dart';

/// **توكن الجهاز عند FCM** — عنوانُ إشعارات هذا الهاتف.
///
/// واجهةٌ (لا دالّةٌ ساكنة) كي تُستبدَل في الاختبار: `firebase_messaging` يحتاج
/// منصّةً حيّة — نظير [AvatarPicker].
abstract class PushTokens {
  /// يطلب إذن الإشعارات ويُعيد التوكن، أو **null** إن رفض المستخدم أو تعذّر.
  /// أندرويد 13+ يوجب الطلب صراحةً؛ ما قبله يمنحه بالتثبيت.
  Future<String?> requestToken();

  /// يبثّ التوكن الجديد حين تُدوّره Google. **بلا الإنصات له تموت إشعارات
  /// اللاعب بلا سبب ظاهر**: الخادم يحمل عنوانًا لم يعد لأحد.
  Stream<String> get onRefresh;

  /// يمحو التوكن من الجهاز (خروجٌ من الحساب).
  Future<void> delete();

  /// حمولة الإشعار الذي فُتح التطبيق بلمسه، أو null. تشمل **الحالتين**: التطبيق
  /// نائمٌ في الخلفيّة، أو ميّتٌ تمامًا (`getInitialMessage`).
  Stream<Map<String, String>> get onTap;
  Future<Map<String, String>?> initialTap();
}

/// التنفيذ الحقيقيّ فوق `firebase_messaging`.
///
/// **لا يلمس Firebase في بانيه.** كان `_fm = FirebaseMessaging.instance` في
/// مُهيّئ الحقل، وحين انتقلت تهيئةُ Firebase إلى ما بعد `runApp` صار هذا السطرُ
/// يرمي `[core/no-app]` **أثناء إنشاء حالة التطبيق** ⇒ شاشةٌ بيضاءُ عند الفتح
/// (شاشةُ خطأ فلاتر في الإصدار رماديّةٌ فاتحةٌ بلا نصّ). الآن يُحلّ المرجعُ
/// **عند الاستعمال** وبعد [AppBoot.firebaseReady] لا قبله.
class FirebasePushTokens implements PushTokens {
  final FirebaseMessaging? _injected;
  final Future<void> Function() _ready;

  FirebasePushTokens({FirebaseMessaging? fm, Future<void> Function()? ready})
      : _injected = fm,
        _ready = ready ?? AppBoot.instance.firebaseReady;

  /// المرجعُ بعد اكتمال التهيئة. يرمي إن فشلت — وكلُّ نداءٍ هنا يبتلع الرميَ
  /// ويردّ «لا توكن»، وهو نفسُ ما يحدث حين يرفض اللاعبُ الإذن.
  Future<FirebaseMessaging> _messaging() async {
    final fm = _injected;
    if (fm != null) return fm;
    await _ready();
    return FirebaseMessaging.instance;
  }

  @override
  Future<String?> requestToken() async {
    try {
      final fm = await _messaging();
      final settings = await fm.requestPermission();
      // **الرفض ليس عطبًا**: من لا يريد إشعاراتٍ يلعب كما كان، وتُقال لداعيه الحقيقة
      // («غير متّصل») لأنّ الخادم لا يجد له توكنًا.
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      return await fm.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> get onRefresh =>
      _afterReady((fm) => fm.onTokenRefresh);

  @override
  Future<void> delete() async {
    try {
      await (await _messaging()).deleteToken();
    } catch (_) {/* لا توكنَ أصلًا ⇒ لا شيءَ يُمحى */}
  }

  @override
  Stream<Map<String, String>> get onTap =>
      _afterReady((_) => FirebaseMessaging.onMessageOpenedApp).map(_data);

  @override
  Future<Map<String, String>?> initialTap() async {
    try {
      final m = await (await _messaging()).getInitialMessage();
      return m == null ? null : _data(m);
    } catch (_) {
      return null;
    }
  }

  /// بثٌّ لا يبدأ إلّا بعد التهيئة — وينتهي صامتًا إن فشلت، فلا يقتل المستمعَ
  /// خطأٌ في منصّةٍ لا دفعَ فيها.
  Stream<T> _afterReady<T>(Stream<T> Function(FirebaseMessaging fm) source) =>
      Stream<FirebaseMessaging>.fromFuture(_messaging())
          .asyncExpand(source)
          .handleError((_) {});

  static Map<String, String> _data(RemoteMessage m) =>
      {for (final e in m.data.entries) e.key: '${e.value}'};
}

/// **لا دفعَ على هذه المنصّة** — ويندوز وماك: `firebase_messaging` غيرُ مسجَّلٍ
/// هناك، ونداؤه يرمي `MissingPluginException` عند أوّل دخول.
///
/// **صمتٌ لا عطب**: لا توكنَ ⇒ لا يجد الخادمُ عنوانًا فيقول لداعيك «غير متّصل»،
/// وهو الصدقُ نفسُه الذي يقوله حين يرفض لاعبُ هاتفٍ الإذن. وصندوقُ الإشعارات
/// داخل التطبيق (الجرس) يعمل كما هو: يجلب من الخادم لا من FCM.
class NoPushTokens implements PushTokens {
  const NoPushTokens();

  @override
  Future<String?> requestToken() async => null;

  @override
  Stream<String> get onRefresh => const Stream.empty();

  @override
  Future<void> delete() async {}

  @override
  Stream<Map<String, String>> get onTap => const Stream.empty();

  @override
  Future<Map<String, String>?> initialTap() async => null;
}
