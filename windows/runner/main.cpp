#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <psapi.h>                                          
#include <shobjidl.h>                                                             
#include <shellapi.h>
#include <string>
#include <vector>
#pragma comment(lib, "shell32.lib")                                         
#pragma comment(lib, "psapi.lib")                            
#include "desktop_shell_channels.h"
#include "flutter_window.h"
#include "utils.h"

                                                 
static const wchar_t* kAppUserModelID = L"com.memz2345.navi.flash";

                                                  
                                                  
                                                          
                               
                                           
                                    
  
                                                              
                                       
static const wchar_t* kFlashWindowClass = L"FLUTTER_RUNNER_WIN32_WINDOW";

struct FlashTargetCtx {
  const wchar_t* exePath;
  DWORD selfPid;
  HWND found;
};

static BOOL CALLBACK FindFlashWindowProc(HWND hwnd, LPARAM lparam) {
  auto* ctx = reinterpret_cast<FlashTargetCtx*>(lparam);
  if (ctx->found) return FALSE;             

  DWORD pid = 0;
  GetWindowThreadProcessId(hwnd, &pid);
  if (!pid || pid == ctx->selfPid) return TRUE;
  if (!IsWindowVisible(hwnd)) return TRUE;

  wchar_t cls[128] = {};
  if (GetClassNameW(hwnd, cls, 128) == 0) return TRUE;
  if (wcscmp(cls, kFlashWindowClass) != 0) return TRUE;          

  HANDLE hProc = OpenProcess(
      PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_VM_READ, FALSE, pid);
  if (!hProc) return TRUE;
  wchar_t path[MAX_PATH] = {};
  DWORD len = GetModuleFileNameExW(hProc, NULL, path, MAX_PATH);
  CloseHandle(hProc);
  if (len == 0) return TRUE;
                                          
  if (_wcsicmp(path, ctx->exePath) != 0) return TRUE;

  ctx->found = hwnd;
  return FALSE;
}

static bool ForwardLaunchArgsToRunningInstance(
    const std::vector<std::string>& args) {
                                     
  std::string payload;
  for (const auto& arg : args) {
    if (!desktop_shell::IsHandledLaunchArg(arg)) continue;
    if (!payload.empty()) payload += desktop_shell::kLaunchArgSeparator;
    payload += arg;
  }
  if (payload.empty()) return false;                 

  wchar_t exePath[MAX_PATH] = {};
  GetModuleFileNameW(NULL, exePath, MAX_PATH);

  FlashTargetCtx ctx{exePath, GetCurrentProcessId(), NULL};
  EnumWindows(FindFlashWindowProc, reinterpret_cast<LPARAM>(&ctx));
  if (!ctx.found) return false;                   

  COPYDATASTRUCT cds;
  cds.dwData = 0x4E465631;           
  cds.cbData = static_cast<DWORD>(payload.size());              
  cds.lpData = payload.data();
  DWORD_PTR result = 0;
  LRESULT sent = SendMessageTimeoutW(ctx.found, WM_COPYDATA, 0,
                                     reinterpret_cast<LPARAM>(&cds),
                                     SMTO_ABORTIFHUNG, 2000, &result);
  if (!sent) return false;                            

                   
  ShowWindow(ctx.found, SW_RESTORE);
  SetForegroundWindow(ctx.found);
  return true;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
                                                                     
                                              
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

                                                                          
             
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

                                       
                                               
                                                      
                                        
  ::SetCurrentProcessExplicitAppUserModelID(kAppUserModelID);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

                                          
                                                 
  desktop_shell::SetLaunchArgs(command_line_arguments);

                                    
  if (ForwardLaunchArgsToRunningInstance(command_line_arguments)) {
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }

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
