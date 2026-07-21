import 'package:belote_engine/belote_engine.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'card_back.dart';
import 'card_face.dart';

/// شاشة معاينة (مؤقتة، خطوة ٣): كل الـ٣٢ وجهًا + الظهر، لفحص الرسم بصريًا.
/// تُستبدل بـ TableScreen في الخطوة ٤.
class CardGallery extends StatelessWidget {
  const CardGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final deck = buildDeck();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Palette.feltGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 8,
                    childAspectRatio: 100 / 140,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: [for (final c in deck) CardFace(card: c)],
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(
                  height: 90,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CardBack(skin: 'zellij'),
                      SizedBox(width: 12),
                      CardBack(skin: 'zellij'),
                      SizedBox(width: 12),
                      CardBack(skin: 'zellij'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
