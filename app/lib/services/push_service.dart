import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

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
class FirebasePushTokens implements PushTokens {
  final FirebaseMessaging _fm;
  FirebasePushTokens([FirebaseMessaging? fm])
      : _fm = fm ?? FirebaseMessaging.instance;

  @override
  Future<String?> requestToken() async {
    final settings = await _fm.requestPermission();
    // **الرفض ليس عطبًا**: من لا يريد إشعاراتٍ يلعب كما كان، وتُقال لداعيه الحقيقة
    // («غير متّصل») لأنّ الخادم لا يجد له توكنًا.
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
    return _fm.getToken();
  }

  @override
  Stream<String> get onRefresh => _fm.onTokenRefresh;

  @override
  Future<void> delete() => _fm.deleteToken();

  @override
  Stream<Map<String, String>> get onTap =>
      FirebaseMessaging.onMessageOpenedApp.map((m) => _data(m));

  @override
  Future<Map<String, String>?> initialTap() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : _data(m);
  }

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
