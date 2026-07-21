/// عنوان خادم Belote.
///
/// **الافتراضي هو الإنتاج** (`https://hisabipro.com/belote`) عمدًا: النقطة منشورةٌ وحيّة،
/// والبناء الناسي للمعامل يجب أن يعمل لا أن يخرج للناس ميّتًا. وقد حدث ذلك فعلًا في
/// **build 4039**: بُنِيَ بلا `--dart-define` فأشار إلى مضيف المحاكي المحلّيّ ⇒ ظهرت قائمة
/// الأونلاين وأزرارها لا تفتح شيئًا (الأزرار تُرسل إلى قناةٍ ميّتة بصمت). يحرسه اليوم
/// `test/api_config_test.dart`.
///
/// **للتطوير المحلّيّ** مرّر العنوان صراحةً:
/// `flutter run --dart-define=BELOTE_SERVER=http://10.0.2.2:8080`
/// (`10.0.2.2` = مضيفُك من محاكي أندرويد · على iOS/سطح المكتب `localhost`).
class ApiConfig {
  final Uri httpBase; // http(s)://host:port
  final Uri wsBase; // ws(s)://host:port — مشتقّ من httpBase

  const ApiConfig({required this.httpBase, required this.wsBase});

  /// يبني الإعداد من أصلٍ واحد ويشتقّ مخطّط WS منه (https⇒wss، غيره⇒ws).
  factory ApiConfig.fromOrigin(String origin) {
    final u = Uri.parse(origin);
    return ApiConfig(
      httpBase: u,
      wsBase: u.replace(scheme: u.scheme == 'https' ? 'wss' : 'ws'),
    );
  }

  /// عنوان الإنتاج — الافتراض حين لا يُمرَّر `--dart-define=BELOTE_SERVER`.
  static const production = 'https://hisabipro.com/belote';

  /// الإعداد الفعّال للتطبيق (من `--dart-define` أو الإنتاج).
  static final ApiConfig current = ApiConfig.fromOrigin(
    const String.fromEnvironment('BELOTE_SERVER', defaultValue: production),
  );

  Uri http(String path) => httpBase.replace(path: _join(httpBase.path, path));

  /// مسار WS مع معاملات استعلام (مثل التوكن): `ws://host/ws?token=…`.
  Uri ws(String path, [Map<String, String>? query]) =>
      wsBase.replace(path: _join(wsBase.path, path), queryParameters: query);

  /// يضمّ بادئة الأساس (إن وُجدت، مثل `/belote` خلف reverse proxy) إلى مسار النقطة.
  /// أساسٌ بلا بادئة ⇒ المسار كما هو (`/auth/...`).
  static String _join(String base, String path) {
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$b$path';
  }
}
