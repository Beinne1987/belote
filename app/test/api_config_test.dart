import 'package:app/net/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // حارسُ انحدارٍ حقيقيّ: **build 4039** خرج للناس مبنيًّا بلا
  // `--dart-define=BELOTE_SERVER` فأشار إلى مضيف المحاكي المحلّيّ — فظهرت قائمة
  // الأونلاين وأزرارها («لعب سريع»/«غرفة») لا تفتح شيئًا: تُرسل إلى قناةٍ ميّتة بصمت.
  // العلاج: الإنتاج هو الافتراض. هذا الاختبار يسقط إن عاد الافتراض محلّيًّا.
  test('الافتراضي بلا dart-define هو الإنتاج الحيّ لا مضيفٌ محلّيّ', () {
    expect(ApiConfig.production, 'https://hisabipro.com/belote');
    expect(ApiConfig.current.httpBase.host, 'hisabipro.com',
        reason: 'بناءٌ ناسٍ للمعامل يجب أن يعمل لا أن يخرج ميّتًا');
    expect(ApiConfig.current.httpBase.scheme, 'https');
    expect(ApiConfig.current.ws('/ws', {'token': 'x'}).toString(),
        'wss://hisabipro.com/belote/ws?token=x');
  });

  test('أساسٌ بلا بادئة ⇒ المسار كما هو', () {
    final c = ApiConfig.fromOrigin('http://10.0.2.2:8080');
    expect(c.http('/auth/login').toString(), 'http://10.0.2.2:8080/auth/login');
    expect(c.ws('/ws', {'token': 'x'}).toString(), 'ws://10.0.2.2:8080/ws?token=x');
  });

  test('أساسٌ ببادئة (reverse proxy) ⇒ تُحفَظ البادئة', () {
    final c = ApiConfig.fromOrigin('https://hisabipro.com/belote');
    expect(c.http('/auth/login').toString(),
        'https://hisabipro.com/belote/auth/login');
    expect(c.http('/me/wallet').toString(), 'https://hisabipro.com/belote/me/wallet');
    expect(c.ws('/ws', {'token': 'jwt'}).toString(),
        'wss://hisabipro.com/belote/ws?token=jwt');
  });
}
