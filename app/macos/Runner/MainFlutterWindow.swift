import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// اسمُ حفظ الإطار — به يتذكّر النظامُ حجمَ النافذة وموضعها بين الجلسات.
  private static let frameName = "BeloteMainWindow"

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // **أصغرُ نافذةٍ مسموحة** — بلا حدٍّ أدنى يستطيع اللاعبُ تصغيرَ النافذة إلى
    // شريطٍ فتنهار الطاولة: مقاعدُ اللاعبين نِسَبٌ من العرض، ومسرحُ اللعب
    // (`AppStage`) لا يجد ما يقتطعه. الرقمان نظيرا ما في `win32_window.cpp`.
    // 640×560 كانت تعطي مسرحًا 448×560 — **أضيقَ من الهاتف نفسِه** (393×852).
    self.contentMinSize = NSSize(width: 720, height: 620)

    // **نافذةُ البدء: الارتفاعُ هو ما يكبّر اللعبة.** عرضُ المسرح تابعٌ للارتفاع
    // (`AppStage`: العرض = الارتفاع × 0.80) ⇒ توسيعُ النافذة أفقيًّا وحدَه يزيد
    // الهامشَ ولا يكبّر الطاولةَ بكسلًا واحدًا. لذلك نأخذ ارتفاعَ الشاشة المتاح
    // (بلا شريط القوائم والرصيف) حتى سقفِ المسرح (1180)، والعرضُ يتبعه بهامشِ
    // غرفةٍ معتدل. كانت 800×600 ثابتةً (مسرحٌ 480×600 = 22% من شاشة 1440×900)
    // — رقمٌ ورثناه من مطابقة حسابي أثناء التشخيص، لا من قرارِ تصميم.
    //
    // ويُستعاد آخرُ حجمٍ وموضعٍ إن وُجدا: تطبيقُ سطح المكتب يتذكّر نافذتَه،
    // وإعادةُ ضبطها في كلّ إقلاعٍ سلوكُ تطبيقٍ محمول.
    if !self.setFrameUsingName(Self.frameName) {
      let visible = (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame
        ?? NSRect(x: 0, y: 0, width: 1280, height: 800)
      let chrome: CGFloat = 52 // شريطُ العنوان + متنفَّسٌ حول النافذة
      let height = min(max(visible.height - chrome, 620), 1180) // 1180 = AppStage.maxHeight
      let width = min(max(height * 1.16, 860), visible.width - 48)
      self.setContentSize(NSSize(width: width, height: height))
      self.center()
    }
    self.setFrameAutosaveName(Self.frameName)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
