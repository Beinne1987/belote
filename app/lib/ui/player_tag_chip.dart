import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/belote_theme.dart';

/// **رمز اللاعب** المعروض مع نسخةٍ بلمسة. هذا ما يُشارَك (صداقات/دعوات/إبلاغ)،
/// لا المعرّف الداخليّ.
///
/// الرمز **لاتينيّ الخانات ومعزول الاتّجاه** (`TextDirection.ltr`) كي لا يقلبه
/// محرّك BiDi داخل واجهةٍ عربيّة — قاعدة CLAUDE.md نفسها المطبّقة على أرقام الورق.
class PlayerTagChip extends StatefulWidget {
  final String tag;

  /// ما يُنسَخ فعليًّا. افتراضًا نفس المعروض (بالمُبادِئة `#`) — ما يراه المستخدم
  /// هو ما يلصقه.
  final String? copyText;

  const PlayerTagChip({super.key, required this.tag, this.copyText});

  @override
  State<PlayerTagChip> createState() => _PlayerTagChipState();
}

class _PlayerTagChipState extends State<PlayerTagChip> {
  bool _copied = false;

  String get _display => '#${widget.tag}';

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.copyText ?? _display));
    if (!mounted) return;
    // تأكيدٌ في مكان اللمس نفسه: أوضح من SnackBar يظهر في طرفٍ آخر من الشاشة.
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copy,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _copied ? t.accent : t.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _display,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: _copied ? t.accent : t.text2,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Icon(_copied ? Icons.check : Icons.copy_rounded,
                  size: 14, color: _copied ? t.accent : t.text3),
            ],
          ),
        ),
      ),
    );
  }
}
