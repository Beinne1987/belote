import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // **أصغرُ نافذةٍ مسموحة** — بلا حدٍّ أدنى يستطيع اللاعبُ تصغيرَ النافذة إلى
    // شريطٍ فتنهار الطاولة: مقاعدُ اللاعبين نِسَبٌ من العرض، ومسرحُ اللعب
    // (`AppStage`) لا يجد ما يقتطعه. الرقمان نظيرا ما في `win32_window.cpp`.
    self.contentMinSize = NSSize(width: 640, height: 560)

    // نافذةُ بدءٍ طوليّةُ الميل متمركزةٌ على الشاشة — نظيرُ حجم بدء ويندوز.
    self.setContentSize(NSSize(width: 1000, height: 820))
    self.center()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
