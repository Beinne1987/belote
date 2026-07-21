import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final FirebaseAuth _auth;

  PhoneAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

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
      onError('الدخول بالهاتف غير مدعوم على هذه المنصّة');
      return;
    }
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneE164,
        forceResendingToken: resend ? _resendToken : null,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          // أندرويد فقط: قراءة الرمز تلقائيًّا. نُكمل الدخول إن طُلب.
          if (onAutoVerified == null) return;
          try {
            final cred = await _auth.signInWithCredential(credential);
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
      throw const PhoneAuthException('لم يُرسَل رمزٌ بعد');
    }
    try {
      final credential =
          PhoneAuthProvider.credential(verificationId: vid, smsCode: smsCode);
      final cred = await _auth.signInWithCredential(credential);
      final token = await cred.user?.getIdToken();
      if (token == null) throw const PhoneAuthException('تعذّر إصدار توكن الدخول');
      return token;
    } on FirebaseAuthException catch (e) {
      throw PhoneAuthException(_msg(e));
    }
  }

  /// يُسجّل الخروج من جلسة Firebase (جلستنا مستقلّة؛ هذا تنظيفٌ فقط).
  Future<void> signOut() => _auth.signOut();

  /// رسائل عربيّة لأكواد أخطاء Firebase الشائعة.
  String _msg(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'رقم الهاتف غير صحيح';
      case 'invalid-verification-code':
        return 'الرمز غير صحيح';
      case 'session-expired':
      case 'code-expired':
        return 'انتهت صلاحية الرمز — اطلب رمزًا جديدًا';
      case 'too-many-requests':
        return 'محاولاتٌ كثيرة — حاول لاحقًا';
      case 'quota-exceeded':
        return 'تجاوزتَ الحصّة المسموحة — حاول لاحقًا';
      case 'network-request-failed':
        return 'تعذّر الاتصال بالشبكة';
      default:
        return e.message ?? 'فشل التحقّق';
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
