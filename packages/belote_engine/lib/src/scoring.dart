/// احتساب النقاط — منقول حرفياً من `reference/src/engine.js`.
library;

import 'bid.dart';

/// كل 10 وحدات = نقطة واحدة.
const unitsPerPoint = 10;

/// هدف المباراة: أول من يبلغه (ثم الأعلى) يفوز.
const target = 100;

/// اسم الثغرة المفتوحة: تعادل تام في الوحدات مع إعلان الأكوينس.
/// تُرمى كنص الرسالة نفسه في JS — لا تخمين.
const openRuleAkwinsTie = 'OPEN_RULE_AKWINS_TIE';

/// استثناء الثغرة #1: أكوينس + تعادل الوحدات. رسالتها = [openRuleAkwinsTie].
class AkwinsTieException implements Exception {
  const AkwinsTieException();
  @override
  String toString() => openRuleAkwinsTie;
}

/// نتيجة تسجيل جولة: نقاط الضامن والخصم، وسبب الحسم.
/// `reason` ∈ { 'akwins', 'chute', 'ok' }.
typedef RoundScore = ({int bidder, int opponent, String reason});

/// المفتاح الموحّد للضمانة في جداول القيم: 'suit' لكل الألوان.
bool _isSuit(Bid bid) => bid.type == BidType.suit;

/// قيمة الجولة بالنقاط: لون 16/32 · صن-تو 26/52 (الأكوينس يضاعف تقريباً).
int roundValue(Bid bid, bool akwins) => _isSuit(bid)
    ? (akwins ? 32 : 16)
    : (akwins ? 52 : 26);

/// مجموع وحدات الجولة: لون 162 · صن-تو 258.
int roundTotalUnits(Bid bid) => _isSuit(bid) ? 162 : 258;

/// عتبة النجاح: نصف مجموع الوحدات — 81 (لون) · 129 (صن-تو). النصف يكفي.
int successThreshold(Bid bid) => roundTotalUnits(bid) ~/ 2;

/// تسجيل الجولة — الترتيب مُلزِم:
///   1. أكوينس → الأكثر وحدات يأخذ كل القيمة (reason 'akwins')؛
///      تعادل الوحدات → [AkwinsTieException] (الثغرة #1، لا تخمين).
///   2. لم يبلغ الضامن العتبة → الخصم يأخذ كل القيمة (reason 'chute').
///   3. وإلّا → توزيع النقاط بحسم النقطة العالقة (reason 'ok').
RoundScore scoreRound({
  required Bid bid,
  required bool akwins,
  required int unitsBidder,
  required int unitsOpp,
}) {
  final value = roundValue(bid, akwins);

  if (akwins) {
    if (unitsBidder > unitsOpp) {
      return (bidder: value, opponent: 0, reason: 'akwins');
    }
    if (unitsOpp > unitsBidder) {
      return (bidder: 0, opponent: value, reason: 'akwins');
    }
    // OPEN RULE #1 — تعادل الوحدات مع الأكوينس
    throw const AkwinsTieException();
  }

  if (unitsBidder < successThreshold(bid)) {
    return (bidder: 0, opponent: value, reason: 'chute');
  }

  final d = distributePoints(unitsBidder, unitsOpp, value);
  return (bidder: d.bidder, opponent: d.opponent, reason: 'ok');
}

/// الفوجة: تتوقف الجولة، والمستحق يأخذ كل قيمة الجولة (بعد المضاعفة).
/// `winner` ∈ { 'claimant', 'accused' }.
({String winner, int value}) scoreFouja({
  required Bid bid,
  required bool akwins,
  required bool proven,
}) =>
    (winner: proven ? 'claimant' : 'accused', value: roundValue(bid, akwins));

/// **الجولة البيضاء (الكابوت):** فريقٌ يأخذ **كل** الأبالي الثمانية والخصم بلا أخذة.
/// (قاعدة موريتانيّة موثّقة في `docs/RULES.md` §الجولة البيضاء — ليست في المحرّك المرجعيّ
/// المجمّد لأنّها تعتمد عدد الأبالي لا الوحدات، فمكانها طبقة تنظيم الجولة.)
///
/// [tricksWon] عدد الأبالي لكل فريق `[فريق0, فريق1]` (مجموعها 8 عند اكتمال الجولة).
/// يعيد الفريق الرابح وقيمة الجولة البيضاء، أو `null` إن لم تكن بيضاء (كلا الفريقين أخذ).
///
/// القيمة: **لون 26 · صن/تو 35**. أمّا الأكوينس فتبقى قيمته 32/52 — لكنّ جولةً بيضاء
/// أكوينس **تحسم المباراة** (قرارٌ فوق الجولة، يتّخذه المنظِّم لا هذه الدالّة).
({int team, int value})? scoreWhiteRound({
  required Bid bid,
  required bool akwins,
  required List<int> tricksWon,
}) {
  final int? team = tricksWon[0] == 0 ? 1 : (tricksWon[1] == 0 ? 0 : null);
  if (team == null) return null; // كلا الفريقين أخذ أبليًا ⇒ ليست بيضاء
  final value = akwins ? roundValue(bid, true) : (_isSuit(bid) ? 26 : 35);
  return (team: team, value: value);
}

/// نتيجة المباراة عند رصيدَي الفريقين:
///   `0` أو `1` الفائز · `'tiebreak'` تعادل تام عند/فوق الهدف · `null` لم تنتهِ.
Object? matchResult(int t0, int t1) {
  final a = t0 >= target, b = t1 >= target;
  if (!a && !b) return null;
  if (a && !b) return 0;
  if (b && !a) return 1;
  if (t0 > t1) return 0;
  if (t1 > t0) return 1;
  return 'tiebreak';
}

/// تحويل الوحدات إلى نقاط، وحسم النقاط العالقة.
///
/// نقلٌ حرفي لـ `distributePoints` في المحرك المرجعي. الترتيب مُلزِم:
///   1. الأعلى في البقية (`units % 10`).
///   2. عند التساوي → الأعلى في مجموع الوحدات.
///   3. عند تساوي الاثنين، أو لأي نقطة إضافية → الضامن.
///
/// الوحدات دائماً ≥ 0، فـ `~/` (قسمة مبتورة) يطابق `Math.floor` في JS.
({int bidder, int opponent}) distributePoints(
  int unitsBidder,
  int unitsOpp,
  int totalPoints,
) {
  var pB = unitsBidder ~/ unitsPerPoint;
  var pO = unitsOpp ~/ unitsPerPoint;
  var leftover = totalPoints - pB - pO;

  if (leftover > 0) {
    final rB = unitsBidder % unitsPerPoint;
    final rO = unitsOpp % unitsPerPoint;
    String first;
    if (rB != rO) {
      first = rB > rO ? 'B' : 'O';
    } else if (unitsBidder != unitsOpp) {
      first = unitsBidder > unitsOpp ? 'B' : 'O';
    } else {
      first = 'B';
    }

    if (first == 'B') {
      pB++;
    } else {
      pO++;
    }
    leftover--;
    pB += leftover; // ما تبقّى → الضامن
  }

  return (bidder: pB, opponent: pO);
}
