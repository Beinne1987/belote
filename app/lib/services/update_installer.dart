import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// طور تثبيت التحديث داخل التطبيق.
enum InstallPhase { downloading, installing, error }

/// حدث تقدّمٍ موحَّد: طورٌ + نسبة تنزيل + رسالة خطأ عربيّة.
class InstallProgress {
  final InstallPhase phase;
  final int percent; // 0..100 أثناء التنزيل
  final String? message; // رسالة خطأ عربيّة عند [InstallPhase.error]

  const InstallProgress(this.phase, {this.percent = 0, this.message});
}

/// **مثبِّت داخل التطبيق (أندرويد):** ينزّل الـ APK إلى مجلّد التطبيق الخاصّ ثمّ
/// يُسلّمه لمثبِّت النظام (`OpenFilex`) — لا متصفّح. التنزيل مُتحكَّم فيه (نتأكّد من
/// اكتماله قبل التثبيت)، والملف في مجلّدٍ لا يحتاج إذن تخزين (يعمل على أندرويد 13+).
///
/// iOS لا يسمح بتثبيتٍ خارج App Store ⇒ [supported] = false هناك.
class UpdateInstaller {
  const UpdateInstaller();

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// ينزّل [apkUrl] ويثبّته. يبثّ التقدّم؛ عند [InstallPhase.installing] يفتح مثبّت
  /// النظام. يُغلق البثّ عند تسليم المثبّت أو عند خطأٍ نهائيّ.
  Stream<InstallProgress> install(String apkUrl) async* {
    if (!supported) {
      yield const InstallProgress(InstallPhase.error,
          message: 'التثبيت داخل التطبيق مدعوم على أندرويد فقط');
      return;
    }
    // أندرويد ٨+ يطلب إذن «تثبيت تطبيقات غير معروفة» لهذا التطبيق (يفتح شاشة الإعداد).
    if (!await _ensureInstallPermission()) {
      yield const InstallProgress(InstallPhase.error,
          message: 'فعّل «السماح من هذا المصدر» ثمّ اضغط إعادة المحاولة');
      return;
    }

    final http.Client client = http.Client();
    IOSink? sink;
    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationSupportDirectory();
      final file = File('${dir.path}/belote-update.apk');
      if (await file.exists()) await file.delete(); // لا نُبقِ ملفًّا تالفًا من محاولةٍ سابقة

      final res = await client.send(http.Request('GET', Uri.parse(apkUrl)));
      if (res.statusCode != 200) {
        yield InstallProgress(InstallPhase.error,
            message: 'فشل التنزيل (رمز ${res.statusCode})');
        return;
      }
      final total = res.contentLength ?? 0;
      var received = 0;
      var lastPct = -1;
      sink = file.openWrite();
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        final pct = total > 0 ? (received * 100 ~/ total) : 0;
        if (pct != lastPct) {
          lastPct = pct;
          yield InstallProgress(InstallPhase.downloading, percent: pct);
        }
      }
      await sink.close();
      sink = null;

      // تأكّد من اكتمال التنزيل — ملفٌّ ناقص يفشل التثبيت بصمت.
      if (total > 0 && received < total) {
        yield const InstallProgress(InstallPhase.error,
            message: 'التنزيل غير مكتمل — حاول لاحقًا');
        return;
      }

      yield const InstallProgress(InstallPhase.installing, percent: 100);
      final open = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      if (open.type != ResultType.done) {
        yield InstallProgress(InstallPhase.error,
            message: 'تعذّر فتح المثبّت (${open.message})');
      }
    } catch (e) {
      debugPrint('UpdateInstaller فشل: $e');
      yield const InstallProgress(InstallPhase.error,
          message: 'تعذّر التحديث — تحقّق من الاتصال وحاول لاحقًا');
    } finally {
      await sink?.close();
      client.close();
    }
  }

  /// يضمن إذن تثبيت الحزم: يطلبه إن لم يُمنَح (يفتح شاشة الإعداد للمستخدم).
  Future<bool> _ensureInstallPermission() async {
    if (await Permission.requestInstallPackages.isGranted) return true;
    final status = await Permission.requestInstallPackages.request();
    return status.isGranted;
  }
}
