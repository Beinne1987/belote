import 'package:flutter/material.dart';

import '../app_settings.dart';
import '../theme/belote_theme.dart';

/// شاشة إدخال الاسم المحلّي — تُستعمل لـ**الدخول كضيف** (اسمٌ يُحفظ محلّيًّا بلا حساب).
/// عند [guest] تُفعّل وضع الضيف أيضًا. تُغلَق بعد الحفظ (الجذر يبني الرئيسية).
class NameEntryScreen extends StatefulWidget {
  final bool guest;
  const NameEntryScreen({super.key, this.guest = false});

  @override
  State<NameEntryScreen> createState() => _NameEntryScreenState();
}

class _NameEntryScreenState extends State<NameEntryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final settings = AppSettingsScope.of(context);
    settings.setName(name);
    if (widget.guest) settings.setGuest(true);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.gradTop, t.gradBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [t.accentBright, t.accent, t.accentDeep],
                    ).createShader(r),
                    child: const Text(
                      'Belote',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('أهلًا بك — اكتب اسمك للبدء',
                      style: TextStyle(color: t.text2, fontSize: 15)),
                  const SizedBox(height: 26),
                  TextField(
                    controller: _controller,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: t.text, fontSize: 18),
                    cursorColor: t.accent,
                    maxLength: 20,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'اسمك',
                      hintStyle: TextStyle(color: t.text3),
                      filled: true,
                      fillColor: t.surface,
                      counterText: '',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: t.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: t.accent, width: 1.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: t.accent,
                        foregroundColor: t.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('ابدأ',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
