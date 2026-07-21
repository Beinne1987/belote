import 'dart:async';

import 'package:app/services/update_installer.dart';
import 'package:app/services/update_service.dart';
import 'package:app/ui/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// مثبِّت وهميّ يبثّ تقدّمًا مُتحكَّمًا فيه (بلا قنوات منصّة).
class _FakeInstaller extends UpdateInstaller {
  final List<InstallProgress> events;
  final _ctrl = StreamController<InstallProgress>();
  bool started = false;

  _FakeInstaller(this.events);

  @override
  Stream<InstallProgress> install(String apkUrl) {
    started = true;
    return _ctrl.stream;
  }

  void emit(InstallProgress p) => _ctrl.add(p);
  void done() => _ctrl.close();
}

const _info = UpdateInfo(
  version: '1.2.0',
  build: 5000,
  apkUrl: 'https://example.test/belote.apk',
  notes: 'تحسينات',
  mandatory: false,
);

Widget _host(Widget dialog) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showDialog<void>(context: ctx, builder: (_) => dialog),
            child: const Text('open'),
          ),
        ),
      ),
    );

void main() {
  testWidgets('تحديث الآن ⇒ ينزّل داخل التطبيق بشريط تقدّم ثمّ تثبيت (لا متصفّح)',
      (tester) async {
    final installer = _FakeInstaller(const []);
    await tester.pumpWidget(_host(UpdateDialog(info: _info, installer: installer)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // النافذة تعرض النسخة والملاحظات وزرّ التحديث.
    expect(find.text('نسخة جديدة 1.2.0'), findsOneWidget);
    expect(find.text('تحديث الآن'), findsOneWidget);

    await tester.tap(find.text('تحديث الآن'));
    await tester.pump();
    expect(installer.started, isTrue); // بدأ التنزيل داخل التطبيق

    installer.emit(const InstallProgress(InstallPhase.downloading, percent: 42));
    await tester.pump();
    expect(find.textContaining('جارٍ التنزيل'), findsOneWidget);
    expect(find.textContaining('42'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    installer.emit(const InstallProgress(InstallPhase.installing, percent: 100));
    await tester.pump();
    expect(find.text('جارٍ التثبيت…'), findsOneWidget);

    installer.done();
    await tester.pump();
  });

  testWidgets('خطأ التثبيت ⇒ رسالة عربيّة + زرّ إعادة المحاولة', (tester) async {
    final installer = _FakeInstaller(const []);
    await tester.pumpWidget(_host(UpdateDialog(info: _info, installer: installer)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تحديث الآن'));
    await tester.pump();
    installer.emit(const InstallProgress(InstallPhase.error, message: 'فشل التنزيل — تحقّق من الاتصال'));
    await tester.pump();

    expect(find.text('فشل التنزيل — تحقّق من الاتصال'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });

  testWidgets('إجباريّ ⇒ لا زرّ «لاحقًا»', (tester) async {
    final installer = _FakeInstaller(const []);
    const forced = UpdateInfo(
      version: '2.0.0',
      build: 6000,
      apkUrl: 'https://example.test/belote.apk',
      notes: '',
      mandatory: true,
    );
    await tester.pumpWidget(_host(UpdateDialog(info: forced, installer: installer)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('لاحقًا'), findsNothing);
    expect(find.text('تحديث الآن'), findsOneWidget);
  });
}
