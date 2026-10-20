import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../boot.dart';
import '../l10n/app_text.dart';
import '../net/api_client.dart';

/// قناةُ إرسال الرمز. واتساب للأرقام الموريتانيّة فقط (ChinqIT).
enum OtpChannel { sms, whatsapp }

/// غرضُ الرمز — يُخبر الخادمَ فيرفض قبل الإرسال رقمًا مأخوذًا/مجهولًا.
enum OtpPurpose { register, reset }

/// أرقامُ +222 تمرّ بخادمنا (ChinqIT)، وكلُّ ما عداها بـ Firebase كما كان.
bool isMauritanian(String phoneE164) => phoneE164.startsWith('+222');

/// واجهة مصادقة الهاتف بخطوتين — تعزل الشاشة عن المزوّد (قابلة للحقن/الاختبار).
abstract class PhoneAuthenticator {
  /// هل يُمكن إرسالُ رمزٍ لهذا الرقم على هذه المنصّة؟
  bool supportsPhone(String phoneE164);

  /// هل يُعرض زرّ «أرسل عبر واتساب» لهذا الرقم؟
  bool supportsWhatsApp(String phoneE164);

  Future<void> sendCode({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function(PhoneCredential credential)? onAutoVerified,
    bool resend = false,
    OtpChannel channel = OtpChannel.sms,
  });

  Future<PhoneCredential> verifyCode(String smsCode);
}

/// يوجّه حسب الرقم: +222 ⇒ [ServerOtpAuth] (ChinqIT عبر خادمنا)، غيره ⇒ [PhoneAuthService] (Firebase).
/// التحقّقُ يذهب إلى المزوّد الذي أرسل آخرَ رمز.
class RoutedPhoneAuth implements PhoneAuthenticator {
  final PhoneAuthenticator mauritania;
  final PhoneAuthenticator others;
  PhoneAuthenticator? _last;

  RoutedPhoneAuth({required this.mauritania, required this.others});

  /// الإعدادُ الافتراضيّ للشاشات.
  factory RoutedPhoneAuth.standard(ApiClient api, OtpPurpose purpose) => RoutedPhoneAuth(
        mauritania: ServerOtpAuth(api: api, purpose: purpose),
        others: PhoneAuthService(),
      );

  PhoneAuthenticator _for(String phone) => isMauritanian(phone) ? mauritania : others;

  @override
  bool supportsPhone(String phoneE164) => _for(phoneE164).supportsPhone(phoneE164);

  @override
  bool supportsWhatsApp(String phoneE164) => _for(phoneE164).supportsWhatsApp(phoneE164);

  @override
  Future<void> sendCode({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function(PhoneCredential credential)? onAutoVerified,
    bool resend = false,
    OtpChannel channel = OtpChannel.sms,
  }) {
    final p = _for(phoneE164);
    _last = p;
    return p.sendCode(
      phoneE164: phoneE164,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerified: onAutoVerified,
      resend: resend,
      channel: channel,
    );
  }

  @override
  Future<PhoneCredential> verifyCode(String smsCode) {
    final p = _last;
    if (p == null) throw PhoneAuthException(AppText.s.errNoCodeSent);
    return p.verifyCode(smsCode);
  }
}

/// OTP الأرقام الموريتانيّة عبر خادمنا (`/otp/send` · `/otp/verify` ⇐ ChinqIT).
/// يعمل على **كلّ المنصّات** (طلبُ HTTP عاديّ) ⇒ إنشاءُ حسابٍ موريتانيٍّ ممكنٌ من الحاسوب أيضًا.
class ServerOtpAuth implements PhoneAuthenticator {
  final ApiClient api;
  final OtpPurpose purpose;
  final Future<String> Function() _deviceId;
  final String Function() _lang;

  ServerOtpAuth({
    required this.api,
    required this.purpose,
    Future<String> Function()? deviceId,
    String Function()? lang,
  })  : _deviceId = deviceId ?? otpDeviceId,
        _lang = lang ?? (() => AppText.s.localeName == 'fr' ? 'fr' : 'ar');

  String? _phone;
  OtpChannel _channel = OtpChannel.sms;

  @override
  bool supportsPhone(String phoneE164) => isMauritanian(phoneE164);

  @override
  bool supportsWhatsApp(String phoneE164) => isMauritanian(phoneE164);

  @override
  Future<void> sendCode({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function(PhoneCredential credential)? onAutoVerified,
    bool resend = false,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    try {
      await api.otpSend(
        phone: phoneE164,
        channel: channel.name,
        purpose: purpose.name,
        lang: _lang(),
        deviceId: await _deviceId(),
      );
      _phone = phoneE164;
      _channel = channel; // القناةُ في التحقّق يجب أن تطابق قناةَ الإرسال
      onCodeSent();
    } on ApiException catch (e) {
      onError(otpErrorMessage(e));
    }
  }

  @override
  Future<PhoneCredential> verifyCode(String smsCode) async {
    final phone = _phone;
    if (phone == null) throw PhoneAuthException(AppText.s.errNoCodeSent);
    try {
      final proof = await api.otpVerify(
        phone: phone,
        otp: smsCode,
        channel: _channel.name,
        deviceId: await _deviceId(),
      );
      return PhoneCredential.proof(proof);
    } on ApiException catch (e) {
      throw PhoneAuthException(otpErrorMessage(e));
    }
  }
}

/// رسالةٌ للمستخدم من رمز خطأ OTP الثابت. **تعطّلُ الخدمة/الشبكة رسالةٌ مستقلّة** لا «رمزٌ خاطئ».
String otpErrorMessage(ApiException e) {
  final s = AppText.s;
  if (e.status == 0) return e.message; // لا شبكة — ليست محاولةً خاطئة
  switch (e.code) {
    case 'otp_invalid':
      final left = (e.body['retriesLeft'] as num?)?.toInt();
      return left == null ? s.errCodeInvalid : s.errCodeInvalidLeft(left);
    case 'otp_expired':
      return s.errCodeExpired;
    case 'otp_rate_limited':
      final after = (e.body['retryAfter'] as num?)?.toInt();
      return after == null || after <= 0 ? s.errTooManyAttempts : s.errOtpRetryAfter(after);
    case 'otp_unavailable':
      return s.errOtpUnavailable;
    case 'invalid_phone':
    case 'not_mauritanian':
      return s.errPhoneInvalid;
    case 'phone_taken':
      return s.errPhoneTaken;
    case 'phone_unknown':
      return s.errPhoneUnknown;
  }
  return e.message;
}

/// معرّفُ تثبيتٍ عشوائيّ (لا بيانات شخصيّة) — يحدّ به الخادمُ الإرسالَ لكلّ جهاز.
Future<String> otpDeviceId() async {
  const key = 'otp_device_id';
  try {
    final p = await SharedPreferences.getInstance();
    final got = p.getString(key);
    if (got != null && got.isNotEmpty) return got;
    final r = Random.secure();
    final id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await p.setString(key, id);
    return id;
  } catch (_) {
    return 'unknown';
  }
}

/// تغليف Firebase Phone Auth بخطوتين: إرسال الرمز (SMS) ثمّ التحقّق منه.
/// النتيجة النهائيّة **توكن هويّة Firebase** يُرسَل إلى خادمنا (`/auth/firebase`)
/// ليُصدر جلستنا. لا يخزّن شيئًا ولا يلمس واجهةً — قابل للحقن والاختبار.
class PhoneAuthService implements PhoneAuthenticator {
  final FirebaseAuth? _injected;
  final Future<void> Function() _ready;

  PhoneAuthService({FirebaseAuth? auth, Future<void> Function()? ready})
      : _injected = auth,
        _ready = ready ?? AppBoot.instance.firebaseReady;

  /// **لا `FirebaseAuth.instance` في الباني** — تهيئةُ Firebase تقع بعد
  /// `runApp` ([AppBoot.firebaseReady])، ونداءُ `.instance` قبلها يرمي
  /// `[core/no-app]`. يُحلُّ المرجعُ هنا: بعد البوّابة، عند أوّل استعمال.
  Future<FirebaseAuth> _fa() async {
    final a = _injected;
    if (a != null) return a;
    await _ready();
    return FirebaseAuth.instance;
  }

  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  bool supportsPhone(String phoneE164) => isSupported;

  @override
  bool supportsWhatsApp(String phoneE164) => false;

  String? _verificationId;
  int? _resendToken;

  /// يرسل رمز OTP إلى [phoneE164] (صيغة E.164: `+2223xxxxxx`).
  /// يستدعي [onCodeSent] عند وصول الرمز، أو [onError] برسالةٍ عربيّة عند الفشل.
  /// على أندرويد قد يكتمل التحقّق تلقائيًّا (قراءة SMS) ⇒ [onAutoVerified] بالتوكن مباشرة.
  @override
  Future<void> sendCode({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function(PhoneCredential credential)? onAutoVerified,
    bool resend = false,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    if (!isSupported) {
      onError(AppText.s.phoneAuthUnsupported);
      return;
    }
    try {
      final auth = await _fa();
      await auth.verifyPhoneNumber(
        phoneNumber: phoneE164,
        forceResendingToken: resend ? _resendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          // أندرويد فقط: قراءة الرمز تلقائيًّا. نُكمل الدخول إن طُلب.
          if (onAutoVerified == null) return;
          try {
            final cred = await auth.signInWithCredential(credential);
            final token = await cred.user?.getIdToken();
            if (token != null) onAutoVerified(PhoneCredential.firebase(token));
          } catch (_) {/* يُكمِل المستخدم يدويًّا */}
        },
        verificationFailed: (e) => onError(_msg(e)),
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (verificationId) => _verificationId = verificationId,
      );
    } catch (e) {
      onError('خطأ غير متوقّع: $e');
    }
  }

  /// يتحقّق من الرمز [smsCode] المُدخَل يدويًّا ويُعيد **توكن هويّة Firebase**.
  /// يرمي [PhoneAuthException] برسالةٍ عربيّة عند الفشل.
  @override
  Future<PhoneCredential> verifyCode(String smsCode) async {
    final vid = _verificationId;
    if (vid == null) {
      throw PhoneAuthException(AppText.s.errNoCodeSent);
    }
    try {
      final credential =
          PhoneAuthProvider.credential(verificationId: vid, smsCode: smsCode);
      final cred = await (await _fa()).signInWithCredential(credential);
      final token = await cred.user?.getIdToken();
      if (token == null) throw PhoneAuthException(AppText.s.errTokenFailed);
      return PhoneCredential.firebase(token);
    } on FirebaseAuthException catch (e) {
      throw PhoneAuthException(_msg(e));
    }
  }

  /// يُسجّل الخروج من جلسة Firebase (جلستنا مستقلّة؛ هذا تنظيفٌ فقط).
  Future<void> signOut() async => (await _fa()).signOut();

  /// رسائل عربيّة لأكواد أخطاء Firebase الشائعة.
  String _msg(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return AppText.s.errPhoneInvalid;
      case 'invalid-verification-code':
        return AppText.s.errCodeInvalid;
      case 'session-expired':
      case 'code-expired':
        return AppText.s.errCodeExpired;
      case 'too-many-requests':
        return AppText.s.errTooManyAttempts;
      case 'quota-exceeded':
        return AppText.s.errQuotaExceeded;
      case 'network-request-failed':
        return AppText.s.errNetwork;
      default:
        return e.message ?? AppText.s.errVerifyFailed;
    }
  }
}

/// خطأ مصادقة الهاتف برسالةٍ عربيّة جاهزة للعرض.
class PhoneAuthException implements Exception {
  final String message;
  const PhoneAuthException(this.message);
  @override
  String toString() => 'PhoneAuthException: $message';
}
