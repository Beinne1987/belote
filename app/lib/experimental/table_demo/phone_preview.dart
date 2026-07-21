import 'package:flutter/material.dart';

/// **إطارُ هاتف** — يعرض ما بداخله بمقاس شاشةٍ حقيقيّة (390×844، مقاسُ هاتفٍ
/// شائع) لا بمقاس نافذة المتصفّح.
///
/// **لماذا:** معاينةٌ عريضةٌ تكذب — تبدو فيها العناصرُ متباعدةً مريحةً ثمّ تزدحم
/// على الهاتف. ما يُرى هنا هو ما يراه اللاعب.
class PhonePreview extends StatelessWidget {
  final Widget child;
  final String label;

  /// مقاسُ الشاشة داخل الإطار (بالبكسل المنطقيّ) — افتراضُه هاتفٌ شائع.
  final Size screen;

  const PhonePreview({
    super.key,
    required this.child,
    required this.label,
    this.screen = const Size(390, 844),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFFE8E2D4),
                fontSize: 15,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF15171B),
            borderRadius: BorderRadius.circular(44),
            border: Border.all(color: const Color(0xFF3A3F47), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x99000000), blurRadius: 30, offset: Offset(0, 12)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: SizedBox(
              width: screen.width,
              height: screen.height,
              // **قياسُ الجهاز محقونٌ** كي تحسب `LayoutBuilder` والـSafeArea داخل
              // الشاشة كما تحسب على الهاتف، لا على نافذة المتصفّح.
              child: MediaQuery(
                data: MediaQueryData(
                  size: screen,
                  devicePixelRatio: 3,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                  textScaler: TextScaler.noScaling,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
