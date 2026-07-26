/// **بياناتُ العبارات الجاهزة** — بمعزلٍ عن الواجهة كي يستعملها الكنترولر (طبقةُ
/// منطق) بلا أن يستوردَ الواجهة. الودجت (`QuickChatPicker`, `ChatBubble`) في
/// `ui/quick_chat_picker.dart` تعيد تصدير هذا.
///
/// **المعرّفات يجب أن تطابق `quickChatIds`** في `server/lib/game/quick_chat.dart` —
/// الخادمُ هو المرجعُ وما لا يعرفه لا يُبثّ. النصُّ عربيٌّ هنا وحده (يُرسَل المعرّفُ
/// لا النصّ). يحرس التطابقَ `test/quick_chat_sync_test.dart`.
library;

import '../l10n/app_text.dart';

/// المعرّفُ يعبر الشبكةَ والنصُّ يُختار عند العرض ⇒ **كلٌّ يقرأ العبارةَ بلغته**:
/// عربيٌّ يكتب «سلامٌ عليكم» فيقرأها الفرنسيُّ «Salam aleikoum».
Map<String, String> quickChatPhrasesFor(AppLocalizations l) => {
      'salam': l.chatSalam,
      'nice': l.chatNice,
      'bravo': l.chatBravo,
      'luck': l.chatLuck,
      'hurry': l.chatHurry,
      'sorry': l.chatSorry,
      'thanks': l.chatThanks,
      'bye': l.chatBye,
    };

/// النصوصُ باللغة النشطة — لمن لا `context` عنده (الكنترولر).
Map<String, String> get quickChatPhrases => quickChatPhrasesFor(AppText.s);

/// نصُّ العبارة [id] للعرض، أو null إن كان معرّفًا لا نعرفه (خادمٌ أحدثُ من التطبيق
/// ⇒ لا نعرض معرّفًا خامًا).
String? quickChatText(String id) => quickChatPhrases[id];
