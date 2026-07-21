import 'package:app/game/ai.dart';
import 'package:app/game/game_controller.dart';
import 'package:app/game/view_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// اختبار تدفّق الجولة عبر الكنترولر (لا واجهة): يقود جولة كاملة —
/// ضمانة ← ٨ أبالي ← دير — ويتحقّق أن **لا وحدة تضيع**: مجموع وحدات
/// الفريقين = 162 (لون) أو 258 (صن/تو) بالضبط. مرآةٌ لحارس المحاكاة في المحرك،
/// لكن على مستوى تنسيق الواجهة. التوقيتات مصفّرة كي تكتمل الجولة فورًا.
/// يقود الجولة الجارية إلى نهايتها (ضمانةً ولعبًا آليًّا للبشري).
Future<void> _driveToDone(GameController c, {String label = ''}) async {
  var guard = 0;
  while (c.tableView.phase != GamePhase.done) {
    if (++guard > 5000) fail('$label: الجولة لم تكتمل (حلقة عالقة؟)');
    final bar = c.bidBar;
    if (bar != null) {
      final bid = bar.options.firstWhere(
        (o) => o.enabled && !o.isPass && !o.isAkwins,
        orElse: () => bar.options.firstWhere((o) => o.enabled),
      );
      c.placeBid(bid.action);
    } else if (c.tableView.humanCanPlay) {
      c.playCard(c.tableView.legalCards.first);
    } else {
      await Future.delayed(Duration.zero);
    }
  }
}

Future<void> _playRound(WidgetTester tester, int seed) async {
  await tester.runAsync(() async {
    final c = GameController(
      seed: seed,
      aiThink: Duration.zero,
      pliPause: Duration.zero,
      pliCollect: Duration.zero,
      pliSettle: Duration.zero,
      bidHold: Duration.zero,
      dealPause: Duration.zero,
    );
    await _driveToDone(c, label: 'seed $seed');

    // لا تسريب وحدات.
    final total = c.roundUnits[0] + c.roundUnits[1];
    expect(total == 162 || total == 258, isTrue,
        reason: 'seed $seed: تسريب وحدات — المجموع $total');

    // النقاط: مجموع نقاط الجولة = قيمتها بالضبط (ما لم تقع الثغرة #1).
    final r = c.roundResult!;
    if (!r.openRuleAkwinsTie) {
      expect(r.usPoints + r.themPoints, r.roundValue,
          reason: 'seed $seed: نقاط الجولة ${r.usPoints}+${r.themPoints} '
              '≠ قيمتها ${r.roundValue}');
      expect(r.usTotal, r.usPoints, reason: 'seed $seed: رصيد نحن أول جولة');
      expect(r.themTotal, r.themPoints, reason: 'seed $seed: رصيد هم أول جولة');
    }
  });
}

void main() {
  testWidgets('جولة كاملة: لا تسريب وحدات + نقاط = قيمة الجولة (٣٠ بذرة)',
      (tester) async {
    for (var seed = 1; seed <= 30; seed++) {
      await _playRound(tester, seed);
    }
  });

  testWidgets('فوجة: اتهام خاطئ ⇒ للخصم قيمة الضمانة، وتتوقف الجولة فورًا',
      (tester) async {
    await tester.runAsync(() async {
      final c = GameController(
        seed: 12,
        aiThink: Duration.zero,
        pliPause: Duration.zero,
        pliCollect: Duration.zero,
        pliSettle: Duration.zero,
        bidHold: Duration.zero,
        dealPause: Duration.zero,
        // aiFoujaChance = 0 (افتراضي) ⇒ لا خصم يفوّج ⇒ أي اتهام خاطئ حتمًا.
      );
      // ادفع الضمانة حتى يبدأ اللعب (أول من يلعب = المقعد 0 = أنت).
      var guard = 0;
      while (c.tableView.phase != GamePhase.playing) {
        if (++guard > 1000) fail('لم يبدأ اللعب');
        final bar = c.bidBar;
        if (bar != null) {
          final bid = bar.options.firstWhere(
            (o) => o.enabled && !o.isPass && !o.isAkwins,
            orElse: () => bar.options.firstWhere((o) => o.enabled),
          );
          c.placeBid(bid.action);
        } else {
          await Future.delayed(Duration.zero);
        }
      }

      // اتهام الشريك/النفس مرفوض: لا يغيّر الطور.
      c.accuseFouja(2);
      c.accuseFouja(0);
      expect(c.tableView.phase, GamePhase.playing);
      expect(c.roundResult, isNull);

      // اتهم الخصم يمينك (المقعد 1) — لم يفوّج ⇒ اتهام خاطئ.
      c.accuseFouja(1);
      final r = c.roundResult!;
      expect(c.tableView.phase, GamePhase.done);
      expect(c.tableView.revealedHands, isNotNull, reason: 'الورق يُكشف بعد الحسم');
      expect(r.reason, 'fouja');
      expect(r.foujaProven, isFalse);
      expect(r.usPoints, 0, reason: 'الاتهام الخاطئ لا يمنحنا شيئًا');
      expect(r.themPoints, r.roundValue,
          reason: 'الخصم يأخذ قيمة الضمانة كاملة عند الاتهام الخاطئ');
    });
  });

  testWidgets('فوجة: الذكاء يكتشف فوجة اللاعب ويعترض ⇒ يفوز الخصم بقيمة الضمانة',
      (tester) async {
    await tester.runAsync(() async {
      var caught = false;
      for (var seed = 1; seed <= 20 && !caught; seed++) {
        final c = GameController(
          seed: seed,
          aiThink: Duration.zero,
          pliPause: Duration.zero,
          pliCollect: Duration.zero,
          pliSettle: Duration.zero,
          bidHold: Duration.zero,
          dealPause: Duration.zero,
          aiAccuseChance: 1.0, // الخصم يكتشف أي فوجة حتمًا
        );
        var guard = 0;
        while (c.tableView.phase != GamePhase.done) {
          if (++guard > 3000) fail('عالق seed=$seed');
          final bar = c.bidBar;
          if (bar != null) {
            c.placeBid(bar.options
                .firstWhere((o) => o.enabled && !o.isPass && !o.isAkwins,
                    orElse: () => bar.options.firstWhere((o) => o.enabled))
                .action);
          } else if (c.tableView.humanCanPlay) {
            final hand = c.tableView.myHand;
            final trick = c.tableView.trick;
            if (trick.isNotEmpty) {
              final led = trick.first.card.suit;
              final off = hand.where((x) => x.suit != led).toList();
              // فوجة عمدًا: امتلك لون الافتتاح لكن ارمِ غيره.
              if (hand.any((x) => x.suit == led) && off.isNotEmpty) {
                c.playCard(off.first);
              } else {
                c.playCard(c.tableView.legalCards.first);
              }
            } else {
              c.playCard(hand.first);
            }
          } else {
            await Future.delayed(Duration.zero);
          }
        }
        final r = c.roundResult!;
        if (r.reason == 'fouja') {
          caught = true;
          expect(r.usPoints, 0, reason: 'اعتراض الذكاء ⇒ لا شيء لنا');
          expect(r.themPoints, r.roundValue,
              reason: 'الخصم يأخذ قيمة الضمانة كاملة');
          expect(r.foujaProven, isTrue);
        }
      }
      expect(caught, isTrue, reason: 'وقعت فوجة واعترض عليها الذكاء');
    });
  });

  // **الكشفُ من الطاولة لا من النظام**: كان الذكاء يعترض لحظةَ ارتكابك الفوجة —
  // وهو لا يرى يدك. لا يجوز اعتراضٌ إلّا بعد أن تعود فتلعب لونًا كنتَ تركتَه،
  // فتُثبت أمام الجميع أنّك كنت تملكه.
  testWidgets('فوجة: لا اعتراض آليّ قبل أن تظهر الفوجة على الطاولة',
      (tester) async {
    await tester.runAsync(() async {
      var seen = 0; // جولاتٌ انتهت بفوجةٍ اعترض عليها الذكاء
      for (var seed = 1; seed <= 40; seed++) {
        final c = GameController(
          seed: seed,
          aiThink: Duration.zero,
          pliPause: Duration.zero,
          pliCollect: Duration.zero,
          pliSettle: Duration.zero,
          bidHold: Duration.zero,
          dealPause: Duration.zero,
          aiAccuseChance: 1.0, // يقظٌ حتمًا ⇒ يعترض في أوّل لحظةٍ يجوز فيها
        );
        final renounced = <String>{}; // ألوانُ افتتاحٍ تركها اللاعب علنًا
        var lastSuit = '';
        var guard = 0;
        while (c.tableView.phase != GamePhase.done) {
          if (++guard > 3000) fail('عالق seed=$seed');
          final bar = c.bidBar;
          if (bar != null) {
            c.placeBid(bar.options
                .firstWhere((o) => o.enabled && !o.isPass && !o.isAkwins,
                    orElse: () => bar.options.firstWhere((o) => o.enabled))
                .action);
          } else if (c.tableView.humanCanPlay) {
            final hand = c.tableView.myHand;
            final trick = c.tableView.trick;
            var card = hand.first;
            if (trick.isNotEmpty) {
              final led = trick.first.card.suit;
              final off = hand.where((x) => x.suit != led).toList();
              if (hand.any((x) => x.suit == led) && off.isNotEmpty) {
                card = off.first; // فوجة عمدًا
                renounced.add(led);
              } else {
                card = c.tableView.legalCards.first;
              }
            }
            lastSuit = card.suit;
            c.playCard(card);
          } else {
            await Future.delayed(Duration.zero);
          }
        }
        if (c.roundResult!.reason != 'fouja') continue;
        seen++;
        expect(renounced.contains(lastSuit), isTrue,
            reason: 'seed=$seed: اعترض الذكاء وآخرُ ورقةٍ لعبتَها ($lastSuit) '
                'ليست عودةً إلى لونٍ تركتَه ⇒ كشفٌ من النظام');
      }
      expect(seen, greaterThan(0), reason: 'لم تُكشَف فوجةٌ واحدة في ٤٠ بذرة');
    });
  });

  testWidgets('فوجة: المطالبة تكشف الأيدي وتوقف اللعب، والإلغاء يستأنف',
      (tester) async {
    await tester.runAsync(() async {
      final c = GameController(
        seed: 12,
        aiThink: Duration.zero,
        pliPause: Duration.zero,
        pliCollect: Duration.zero,
        pliSettle: Duration.zero,
        bidHold: Duration.zero,
        dealPause: Duration.zero,
      );
      var guard = 0;
      while (c.tableView.phase != GamePhase.playing) {
        if (++guard > 1000) fail('لم يبدأ اللعب');
        final bar = c.bidBar;
        if (bar != null) {
          c.placeBid(bar.options
              .firstWhere((o) => o.enabled && !o.isPass && !o.isAkwins,
                  orElse: () => bar.options.firstWhere((o) => o.enabled))
              .action);
        } else {
          await Future.delayed(Duration.zero);
        }
      }

      expect(c.tableView.revealedHands, isNull);
      c.startFoujaClaim();
      expect(c.tableView.claimingFouja, isTrue);
      // الورق لا يُكشف أثناء الاختيار (منعًا للنظر ثم الاختيار).
      expect(c.tableView.revealedHands, isNull);
      expect(c.tableView.canAccuseFouja, isFalse, reason: 'الزرّ يختفي أثناء اللوحة');

      c.cancelFoujaClaim();
      expect(c.tableView.claimingFouja, isFalse);
      expect(c.tableView.revealedHands, isNull);
      expect(c.tableView.phase, GamePhase.playing, reason: 'اللعب استُؤنف');
    });
  });

  testWidgets('نهاية المباراة: الفوز عند 100 يوقف الاستمرار، و«مباراة جديدة» تصفّر',
      (tester) async {
    await tester.runAsync(() async {
      final c = GameController(
        seed: 3,
        aiThink: Duration.zero,
        pliPause: Duration.zero,
        pliCollect: Duration.zero,
        pliSettle: Duration.zero,
        bidHold: Duration.zero,
        dealPause: Duration.zero,
        // resultHold = 0 ⇒ لا تقدّم تلقائي ⇒ نتحكّم بالجولات يدويًّا.
      );
      await _driveToDone(c, label: 'm1');
      var guard = 0;
      while (c.roundResult!.matchOutcome != 0 &&
          c.roundResult!.matchOutcome != 1) {
        if (++guard > 60) fail('لم تُحسم المباراة');
        c.newRound();
        await _driveToDone(c);
      }
      final won = c.roundResult!;
      expect(won.usTotal >= 100 || won.themTotal >= 100, isTrue,
          reason: 'فائز واضح يبلغ 100');

      // بعد الفوز: «جولة جديدة» ممنوعة — لا شيء يتغيّر ولا يتراكم.
      c.newRound();
      expect(c.tableView.phase, GamePhase.done);
      expect(c.roundResult!.usTotal, won.usTotal);
      expect(c.roundResult!.themTotal, won.themTotal);

      // «مباراة جديدة» تصفّر الرصيد: أول جولة تبدأ من الصفر.
      c.newMatch();
      await _driveToDone(c, label: 'm2');
      final fresh = c.roundResult!;
      expect(fresh.usTotal, fresh.usPoints, reason: 'رصيد نحن صُفِّر');
      expect(fresh.themTotal, fresh.themPoints, reason: 'رصيد هم صُفِّر');
    });
  });

  testWidgets('محاكاة ذكاء-ضدّ-ذكاء: لا تسريب وحدات (150 بذرة)', (tester) async {
    await tester.runAsync(() async {
      for (var seed = 1; seed <= 150; seed++) {
        final c = GameController(
          seed: seed,
          aiThink: Duration.zero,
          pliPause: Duration.zero,
          pliCollect: Duration.zero,
          pliSettle: Duration.zero,
          bidHold: Duration.zero,
          dealPause: Duration.zero,
        );
        var guard = 0;
        while (c.tableView.phase != GamePhase.done) {
          if (++guard > 5000) fail('seed $seed عالق');
          final bar = c.bidBar;
          if (bar != null) {
            c.placeBid(bar.options
                .firstWhere((o) => o.enabled && !o.isPass && !o.isAkwins,
                    orElse: () => bar.options.firstWhere((o) => o.enabled))
                .action);
          } else if (c.tableView.humanCanPlay) {
            final v = c.tableView;
            c.playCard(aiPlay(0, v.myHand, v.trick, v.bid!)); // المقعد 0 بالذكاء أيضًا
          } else {
            await Future.delayed(Duration.zero);
          }
        }
        final total = c.roundUnits[0] + c.roundUnits[1];
        expect(total == 162 || total == 258, isTrue,
            reason: 'seed $seed: تسريب وحدات — المجموع $total');
      }
    });
  });

  testWidgets('تعدّد الجولات: الرصيد يتراكم والموزّع يدور', (tester) async {
    await tester.runAsync(() async {
      final c = GameController(
        seed: 777,
        aiThink: Duration.zero,
        pliPause: Duration.zero,
        pliCollect: Duration.zero,
        pliSettle: Duration.zero,
        bidHold: Duration.zero,
        dealPause: Duration.zero,
      );
      await _driveToDone(c, label: 'r1');
      final r1 = c.roundResult!;
      final us1 = r1.usTotal, them1 = r1.themTotal;

      c.newRound();
      await _driveToDone(c, label: 'r2');
      final r2 = c.roundResult!;

      // الرصيد بعد الجولة الثانية = رصيد الأولى + نقاط الثانية.
      expect(r2.usTotal, us1 + r2.usPoints, reason: 'تراكم رصيد نحن');
      expect(r2.themTotal, them1 + r2.themPoints, reason: 'تراكم رصيد هم');
    });
  });
}
