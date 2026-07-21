/// **بياناتُ العبارات الجاهزة** — بمعزلٍ عن الواجهة كي يستعملها الكنترولر (طبقةُ
/// منطق) بلا أن يستوردَ الواجهة. الودجت (`QuickChatPicker`, `ChatBubble`) في
/// `ui/quick_chat_picker.dart` تعيد تصدير هذا.
///
/// **المعرّفات يجب أن تطابق `quickChatIds`** في `server/lib/game/quick_chat.dart` —
/// الخادمُ هو المرجعُ وما لا يعرفه لا يُبثّ. النصُّ عربيٌّ هنا وحده (يُرسَل المعرّفُ
/// لا النصّ). يحرس التطابقَ `test/quick_chat_sync_test.dart`.
library;

const quickChatPhrases = <String, String>{
  'salam': 'سلامٌ عليكم',
  'nice': 'لعبةٌ جميلة',
  'bravo': 'أحسنت',
  'luck': 'بالتوفيق',
  'hurry': 'أسرِع قليلًا',
  'sorry': 'آسف',
  'thanks': 'شكرًا',
  'bye': 'إلى اللقاء',
};

/// نصُّ العبارة [id] للعرض، أو null إن كان معرّفًا لا نعرفه (خادمٌ أحدثُ من التطبيق
/// ⇒ لا نعرض معرّفًا خامًا).
String? quickChatText(String id) => quickChatPhrases[id];
