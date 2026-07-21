import 'package:flutter/material.dart';

import '../../ui/card_face.dart';
import 'real_table_preview.dart';

/// **مدخلٌ مستقلٌّ للعرض** — لا Firebase ولا شبكة ولا أيّ من إضافات التطبيق.
///
/// يُبنى وحدَه: `flutter build web -t lib/experimental/table_demo/table_demo_main.dart`
/// فتخرج حزمةُ ويبٍ صغيرةٌ للمعاينة في المتصفّح، معزولةٌ تمامًا عن كود الإنتاج.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // رسومُ الأوراق تُفكّ مرّةً كما في `main.dart` — بدونها تُرسَم الأوراقُ فارغة.
  await preloadCardArt();
  runApp(const _DemoApp());
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Belote — طاولة تجريبيّة',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Roboto',
        ),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const ColoredBox(
            color: Color(0xFF0E1013), child: RealTablePreview()),
      );
}
