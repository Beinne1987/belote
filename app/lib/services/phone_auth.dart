import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../boot.dart';
import '../l10n/app_text.dart';

/// واجهة مصادقة الهاتف بخطوتين — تعزل الشاشة عن Firebase مباشرةً (قابلة للحقن/الاختبار).
abstract class PhoneAuthenticator {
  bool get supported;

  Future<void> sendCode({
    required String phoneE164,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function(String idToken)? onAutoVerified,
    bool resend = false,
  });

  Future<String> verifyCode(String smsCode);
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
  bool get supported => isSupported;

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
    void Function(String idToken)? onAutoVerified,
    bool resend = false,
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
            if (token != null) onAutoVerified(token);
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
  Future<String> verifyCode(String smsCode) async {
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
      return token;
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
