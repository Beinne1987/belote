import 'package:test/test.dart';
import 'package:belote_engine/belote_engine.dart';

List<String> codes(List<BidAction> acts) => acts.map((a) => a.code).toList();

void main() {
  test('createBidding: الدور لأول مضمّن = يمين الموزّع', () {
    expect(createBidding(3).turn, 0);
    expect(createBidding(0).turn, 1);
    expect(createBidding(2).turn, 3);
  });

  test('الأول: لا pass، والترتيب الأضعف→الأقوى بلا أكوينس', () {
    final st = createBidding(3);
    expect(codes(legalBidActions(st)), ['BT', 'BC', 'BH', 'BS', 'BN', 'BA']);
  });

  test('الأول لا يستطيع Pass → FIRST_BIDDER_CANNOT_PASS', () {
    final st = createBidding(3);
    expect(
      () => applyBidAction(st, const BidAction.pass()),
      throwsA(isA<StateError>().having((e) => e.message, 'message', 'FIRST_BIDDER_CANNOT_PASS')),
    );
  });

  test('الرفع فقط: بعد coeur تبقى pique/sans/tout + pass + akwins(للخصم)', () {
    final st = createBidding(3); // turn 0
    applyBidAction(st, const BidAction.ofBid(Bid.ofSuit('coeur'))); // مقعد 0 يضمن كير
    // الدور الآن للمقعد 1 (خصم للمقعد 0)
    expect(st.turn, 1);
    expect(codes(legalBidActions(st)), ['P', 'BS', 'BN', 'BA', 'K']);
  });

  test('الشريك لا يعلن أكوينس (لا K في قائمته)', () {
    final st = createBidding(3); // turn 0
    applyBidAction(st, const BidAction.ofBid(Bid.ofSuit('coeur'))); // 0 يضمن
    applyBidAction(st, const BidAction.pass()); // 1 يمرّ
    // الدور الآن للمقعد 2 (شريك المقعد 0) → لا أكوينس
    expect(st.turn, 2);
    expect(codes(legalBidActions(st)).contains('K'), isFalse);
  });

  test('ضمانة ليست أعلى → BID_MUST_BE_HIGHER', () {
    final st = createBidding(3);
    applyBidAction(st, const BidAction.ofBid(Bid.ofSuit('coeur')));
    expect(
      () => applyBidAction(st, const BidAction.ofBid(Bid.ofSuit('coeur'))), // مساواة
      throwsA(isA<StateError>().having((e) => e.message, 'message', 'BID_MUST_BE_HIGHER')),
    );
    expect(
      () => applyBidAction(st, const BidAction.ofBid(Bid.ofSuit('trefle'))), // أضعف
      throwsA(isA<StateError>().having((e) => e.message, 'message', 'BID_MUST_BE_HIGHER')),
    );
  });

  test('الأكوينس: الخصم فقط، ويوقف الضمانة فورًا', () {
    final st = createBidding(3); // turn 0
    applyBidAction(st, const BidAction.ofBid(Bid.ofSuit('coeur'))); // 0 يضمن
    applyBidAction(st, const BidAction.akwins()); // 1 (خصم) أكوينس
    expect(st.finished, isTrue);
    expect(st.akwins, isTrue);
    expect(st.akwinsBySeat, 1);
    expect(legalBidActions(st), isEmpty);
  });

  test('دورة واحدة بالضبط: تنتهي بعد 4 أدوار، حتى لو رفع الرابع', () {
    final st = createBidding(3); // 0,1,2,3
    applyBidAction(st, const BidAction.ofBid(Bid.ofSuit('coeur'))); // 0
    applyBidAction(st, const BidAction.pass()); // 1
    applyBidAction(st, const BidAction.pass()); // 2
    expect(st.finished, isFalse);
    applyBidAction(st, const BidAction.ofBid(Bid.ofSuit('pique'))); // 3 يرفع
    expect(st.finished, isTrue); // لا دورة جديدة
    expect(st.currentBid, const Bid.ofSuit('pique'));
    expect(st.bidderSeat, 3);
  });

  test('بعد الانتهاء → BIDDING_FINISHED', () {
    final st = createBidding(3);
    applyBidAction(st, const BidAction.ofBid(Bid.ofSuit('coeur')));
    applyBidAction(st, const BidAction.pass());
    applyBidAction(st, const BidAction.pass());
    applyBidAction(st, const BidAction.pass());
    expect(st.finished, isTrue);
    expect(
      () => applyBidAction(st, const BidAction.pass()),
      throwsA(isA<StateError>().having((e) => e.message, 'message', 'BIDDING_FINISHED')),
    );
  });
}
