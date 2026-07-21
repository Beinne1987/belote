import 'package:flutter/material.dart';

import '../theme/belote_theme.dart';

/// شريط علويّ بسيط (رجوع + عنوان) — مشترك بين شاشات الشكل.
class SimpleTopBar extends StatelessWidget {
  final String title;

  /// فعلٌ في أقصى الشريط (مثل «تعليم الكلّ») — null ⇒ عنوانٌ ورجوعٌ كما كان.
  final Widget? trailing;

  const SimpleTopBar({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = BeloteTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: t.text2),
            onPressed: () => Navigator.maybePop(context),
          ),
          Text(title,
              style: TextStyle(
                  color: t.text, fontSize: 18, fontWeight: FontWeight.w800)),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
