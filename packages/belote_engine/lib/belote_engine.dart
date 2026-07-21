/// محرك Belote الموريتاني — واجهة الحزمة العامة.
///
/// منطق خالص مترجَم من `reference/src/engine.js`، يُثبَّت بمتجهات JS الذهبية.
/// لا يعتمد على Flutter ولا على أي إدخال/إخراج — يصلح للتطبيق وللخادم معاً.
library belote_engine;

export 'src/lcg.dart';
export 'src/card.dart';
export 'src/deck.dart';
export 'src/seats.dart';
export 'src/bid.dart';
export 'src/bidding.dart';
export 'src/tables.dart';
export 'src/play.dart';
export 'src/scoring.dart';
export 'src/insights.dart';
