import 'dart:async';

import 'package:flutter/material.dart';

import '../services/update_installer.dart';
import '../services/update_service.dart';

/// نافذة التحديث: تعرض النسخة والملاحظات، وعند الضغط على «تحديث الآن» تنزّل الـ APK
/// **داخل التطبيق** بشريط تقدّم ثمّ تُطلق مثبّت النظام — بلا مغادرةٍ للمتصفّح.
///
/// إجباريّ ([UpdateInfo.mandatory]) ⇒ لا زرّ «لاحقًا» ولا إغلاق باللمس الخارجيّ.
class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  final UpdateInstaller installer;

  const UpdateDialog({super.key, required this.info, UpdateInstaller? installer})
      : installer = installer ?? const _DefaultInstaller();

  /// يعرض النافذة. لا تُغلَق بلمسٍ خارجيّ إن كان التحديث إجباريًّا.
  static Future<void> show(BuildContext context, UpdateInfo info,
          {UpdateInstaller? installer}) =>
      showDialog<void>(
        context: context,
        barrierDismissible: !info.mandatory,
        builder: (_) => UpdateDialog(info: info, installer: installer),
      );

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  StreamSubscription<InstallProgress>? _sub;
  InstallProgress? _progress;
  bool _started = false;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _startUpdate() {
    setState(() {
      _started = true;
      _progress = const InstallProgress(InstallPhase.downloading);
    });
    _sub?.cancel();
    _sub = widget.installer.install(widget.info.apkUrl).listen((p) {
      if (mounted) setState(() => _progress = p);
    });
  }

  bool get _isError => _progress?.phase == InstallPhase.error;
  bool get _downloading => _started && !_isError;

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return PopScope(
      canPop: !info.mandatory,
      child: AlertDialog(
        title: Text('نسخة جديدة ${info.version}', textDirection: TextDirection.rtl),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              info.notes.isEmpty ? 'تتوفّر نسخة أحدث من اللعبة.' : info.notes,
              textDirection: TextDirection.rtl,
            ),
            if (_downloading) ...[
              const SizedBox(height: 20),
              _progressView(),
            ],
            if (_isError) ...[
              const SizedBox(height: 14),
              Text(_progress!.message ?? 'تعذّر التحديث',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13.5)),
            ],
          ],
        ),
        actions: _actions(context),
      ),
    );
  }

  Widget _progressView() {
    final p = _progress!;
    final installing = p.phase == InstallPhase.installing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: installing || p.percent <= 0 ? null : p.percent / 100,
          minHeight: 6,
        ),
        const SizedBox(height: 8),
        Text(
          installing ? 'جارٍ التثبيت…' : 'جارٍ التنزيل… ${p.percent}%',
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  List<Widget> _actions(BuildContext context) {
    // أثناء التنزيل: لا أزرار (المثبّت سيفتح تلقائيًّا).
    if (_downloading) return const [];
    return [
      if (!widget.info.mandatory && !_started)
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('لاحقًا'),
        ),
      FilledButton(
        onPressed: _startUpdate,
        child: Text(_isError ? 'إعادة المحاولة' : 'تحديث الآن'),
      ),
    ];
  }
}

/// المثبّت الحقيقيّ (const حتى يكون افتراضًا للـ widget).
class _DefaultInstaller extends UpdateInstaller {
  const _DefaultInstaller();
}
