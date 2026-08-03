#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // **نافذةُ بدءٍ بحجم الشاشة لا رقمًا ثابتًا** — نظيرُ ما في
  // `macos/Runner/MainFlutterWindow.swift` حرفيًّا، ولنفس السبب: مسرحُ الطاولة
  // (`AppStage`) عرضُه تابعٌ لارتفاعه، فالارتفاعُ وحدَه هو ما يكبّر اللعبة.
  // 1000×820 كانت رقمًا ثابتًا يعطي — على شاشة 1920×1080 — لعبةً في ثلث الشاشة
  // ونافذةَ «تطبيقِ هاتفٍ» على سطح مكتب.
  //
  // منطقةُ العمل (`SPI_GETWORKAREA`) لا الشاشةُ كلُّها: شريطُ المهامّ يقتطع
  // منها، ونافذةٌ أطولُ منه تُفتَح مقصوصةً تحته.
  //
  // **بالبكسل المنطقيّ لا الفيزيائيّ**: `Win32Window::Create` يضرب ما يُمرَّر
  // إليه في معامل الشاشة (DPI)، ومنطقةُ العمل تأتي بالبكسل الفيزيائيّ ⇒ بلا
  // القسمة تُفتَح النافذةُ ضِعفَ الشاشة على عرضٍ بمعامل 200%.
  RECT work{0, 0, 1280, 800};
  SystemParametersInfoW(SPI_GETWORKAREA, 0, &work, 0);
  HDC screen_dc = GetDC(nullptr);
  const double scale =
      screen_dc ? GetDeviceCaps(screen_dc, LOGPIXELSX) / 96.0 : 1.0;
  if (screen_dc) ReleaseDC(nullptr, screen_dc);
  const int work_w = static_cast<int>((work.right - work.left) / scale);
  const int work_h = static_cast<int>((work.bottom - work.top) / scale);
  const int chrome = 56; // شريطُ العنوان + متنفَّسٌ حول النافذة
  int height = work_h - chrome;
  if (height < 620) height = 620;
  if (height > 1180) height = 1180; // = AppStage.maxHeight
  int width = static_cast<int>(height * 1.16);
  if (width < 860) width = 860;
  if (width > work_w - 48) width = work_w - 48;
  // **بلا سالبٍ**: `Point` يأخذ `unsigned` ⇒ فرقٌ سالبٌ (شاشةٌ أقصرُ من أدنى
  // نافذة) ينقلب رقمًا هائلًا فتُفتَح النافذةُ خارج الشاشة.
  int left = static_cast<int>(work.left / scale) + (work_w - width) / 2;
  int top = static_cast<int>(work.top / scale) + (work_h - height - chrome) / 2;
  if (left < 0) left = 0;
  if (top < 0) top = 0;
  Win32Window::Point origin(static_cast<unsigned int>(left),
                            static_cast<unsigned int>(top));
  Win32Window::Size size(static_cast<unsigned int>(width),
                         static_cast<unsigned int>(height));
  if (!window.Create(L"Belote", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
