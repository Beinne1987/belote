import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// معلومات نسخة متوفّرة على الخادم (من `belote-version.json`).
class UpdateInfo {
  final String version; // اسم النسخة، مثل 1.0.3
  final int build; // رقم البناء (versionCode لبناء arm64)
  final String apkUrl; // رابط تنزيل الـ APK
  final String notes; // ملاحظات النسخة (تُعرض للاعب)
  final bool mandatory; // إجباري ⇒ لا يُغلَق دون تحديث

  const UpdateInfo({
    required this.version,
    required this.build,
    required this.apkUrl,
    required this.notes,
    required this.mandatory,
  });
}

/// فحص التحديثات: يجلب `belote-version.json` ويقارن رقم بنائه برقم بناء التطبيق الحالي.
///
/// **مانع تعطّل:** أي فشل (لا شبكة، JSON تالف، مهلة…) يُعيد null بلا رمي — لا يُسقط التطبيق.
/// المقارنة برقم البناء (versionCode) لا اسم النسخة؛ نوزّع arm64 دائمًا فيبقى متسقًا.
class UpdateService {
  UpdateService._();

  static const versionUrl = 'https://hisabipro.com/downloads/belote-version.json';

  static Future<UpdateInfo?> check() async {
    try {
      final res = await http
          .get(Uri.parse(versionUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final remote = UpdateInfo(
        version: (j['version'] as String?) ?? '',
        build: (j['build'] as num?)?.toInt() ?? 0,
        apkUrl: (j['apk_url'] as String?) ?? '',
        notes: (j['notes'] as String?) ?? '',
        mandatory: (j['mandatory'] as bool?) ?? false,
      );
      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      if (remote.apkUrl.isNotEmpty && remote.build > current) return remote;
      return null;
    } catch (e) {
      debugPrint('UpdateService.check فشل (يُتجاهل): $e');
      return null;
    }
  }
}
