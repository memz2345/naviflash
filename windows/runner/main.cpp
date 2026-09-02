#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <psapi.h>                   // GetModuleFileNameExW
#include <shobjidl.h>                 // ✅ SetCurrentProcessExplicitAppUserModelID
#include <shellapi.h>                 // CommandLineToArgvW
#include <string>
#pragma comment(lib, "shell32.lib")   // ✅ 确保链接（flutter_window.cpp 已加，这里双保险）
#pragma comment(lib, "psapi.lib")     // GetModuleFileNameExW
#include "flutter_window.h"
#include "utils.h"

// ✅ 必须与 flutter_window.cpp / Jump List 写入端【完全一致】
static const wchar_t* kAppUserModelID = L"com.memz2345.navi.flash";

// ================= ✅ 单实例 JumpList 动作转发 =================
// JumpList 点击（启动参数 --flash-action=…）时，若已有本应用实例在运行，
// 则把动作通过 WM_COPYDATA 转发给现有实例（由 flutter_window.cpp 推给
// Dart 在当前窗口内跳转），本进程随即退出——不再创建第二个进程实例。
// 没有运行实例时返回 false，走正常的冷启动（新进程自带参数）。
static const wchar_t* kFlashWindowClass = L"FLUTTER_RUNNER_WIN32_WINDOW";
static const DWORD kFlashCopyDataMagic = 0x464C5348;  // 'FLSH'

static std::string FlashUtf8FromWide(const std::wstring& ws) {
  if (ws.empty()) return {};
  int len = WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), -1, NULL, 0, NULL, NULL);
  if (len <= 0) return {};
  std::string s(len - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), -1, s.data(), len, NULL, NULL);
  return s;
}

struct FlashTargetCtx {
  const wchar_t* exePath;
  DWORD selfPid;
  HWND found;
};

static BOOL CALLBACK FindFlashWindowProc(HWND hwnd, LPARAM lparam) {
  auto* ctx = reinterpret_cast<FlashTargetCtx*>(lparam);
  if (ctx->found) return FALSE;  // 已找到，停止枚举

  DWORD pid = 0;
  GetWindowThreadProcessId(hwnd, &pid);
  if (!pid || pid == ctx->selfPid) return TRUE;
  if (!IsWindowVisible(hwnd)) return TRUE;

  wchar_t cls[128] = {};
  if (GetClassNameW(hwnd, cls, 128) == 0) return TRUE;
  if (wcscmp(cls, kFlashWindowClass) != 0) return TRUE;  // 只认主窗口

  HANDLE hProc = OpenProcess(
      PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_VM_READ, FALSE, pid);
  if (!hProc) return TRUE;
  wchar_t path[MAX_PATH] = {};
  DWORD len = GetModuleFileNameExW(hProc, NULL, path, MAX_PATH);
  CloseHandle(hProc);
  if (len == 0) return TRUE;
  // 只匹配同一份可执行文件（避免误发给 Navi v2 等其他目录的同名实例）
  if (_wcsicmp(path, ctx->exePath) != 0) return TRUE;

  ctx->found = hwnd;
  return FALSE;
}

static bool ForwardFlashActionToRunningInstance() {
  LPWSTR cmdLine = GetCommandLineW();
  int argc = 0;
  LPWSTR* argv = CommandLineToArgvW(cmdLine, &argc);
  std::string action;
  if (argv) {
    for (int i = 1; i < argc; i++) {
      std::wstring arg(argv[i]);
      const std::wstring prefix = L"--flash-action=";
      if (arg.find(prefix) == 0) {
        action = FlashUtf8FromWide(arg.substr(prefix.length()));
        break;
      }
    }
    LocalFree(argv);
  }
  if (action.empty()) return false;  // 普通启动，不做单实例处理

  wchar_t exePath[MAX_PATH] = {};
  GetModuleFileNameW(NULL, exePath, MAX_PATH);

  FlashTargetCtx ctx{exePath, GetCurrentProcessId(), NULL};
  EnumWindows(FindFlashWindowProc, reinterpret_cast<LPARAM>(&ctx));
  if (!ctx.found) return false;  // 没有运行中的实例 → 冷启动

  COPYDATASTRUCT cds;
  cds.dwData = kFlashCopyDataMagic;
  cds.cbData = static_cast<DWORD>(action.size());  // UTF-8 字节数
  cds.lpData = action.data();
  DWORD_PTR result = 0;
  LRESULT sent = SendMessageTimeoutW(ctx.found, WM_COPYDATA, 0,
                                     reinterpret_cast<LPARAM>(&cds),
                                     SMTO_ABORTIFHUNG, 2000, &result);
  if (!sent) return false;  // 转发失败 → 冷启动兜底（新进程自行处理动作）

  // 转发成功：把已有实例带到前台
  ShowWindow(ctx.found, SW_RESTORE);
  SetForegroundWindow(ctx.found);
  return true;
}

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

  // ✅✅✅ 关键修复：必须在创建【任何窗口】之前设置进程级 AUMID。
  //   否则 window.Create() 创建的顶层窗口会拿到「默认 AUMID」，
  //   右键任务栏图标时 Windows 用默认 AUMID 去查 Jump List → 永远空白。
  //   设置后，本进程创建的所有窗口（含顶层窗口）默认继承此 AUMID。
  ::SetCurrentProcessExplicitAppUserModelID(kAppUserModelID);

  // ✅ JumpList 点击：已有实例时转发动作到该实例，本进程直接退出
  if (ForwardFlashActionToRunningInstance()) {
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"NaviFlash", origin, size)) {
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
