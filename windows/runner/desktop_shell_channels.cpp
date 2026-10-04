                                            
  
                        
                            
                                          
                        
  
                                   
                 
#include "desktop_shell_channels.h"

#include "find_replace_window.h"
#include "task_dialog.h"

#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include <algorithm>
#include <cstdio>
#include <memory>
#include <string>
#include <vector>

#include <appmodel.h>
#include <objbase.h>
#include <shellapi.h>
#include <shlobj.h>
#include <shobjidl_core.h>
#include <windows.h>

                                               
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.UI.Notifications.h>

#pragma comment(lib, "advapi32.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "windowsapp.lib")                                        

namespace desktop_shell {
namespace {

                                                               
constexpr wchar_t kProgId[] = L"NaviFlash.Video";
constexpr wchar_t kProgIdDesc[] = L"NaviFlash 视频";
constexpr wchar_t kAppDisplayName[] = L"NaviFlash";
constexpr wchar_t kRegisteredAppName[] = L"NaviFlash";
constexpr wchar_t kClassesHive[] = L"Software\\Classes\\";
constexpr char kArgSeparator = '\x1e';

                                 
const wchar_t* const kSupportedExts[] = {
    L".mp4",  L".mkv", L".avi",  L".mov", L".wmv",  L".flv",  L".webm",
    L".m4v",  L".mpg", L".mpeg", L".ts",  L".m2ts", L".mts",  L".rmvb",
    L".rm",   L".3gp", L".vob",  L".ogv", L".asf",  L".divx", L".f4v",
    L".mp3",  L".flac", L".wav", L".aac", L".m4a",  L".ogg",  L".opus",
    L".wma",  L".aiff", L".ape",
};

                                                                 
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
    g_taskbar_channel;
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
    g_open_video_channel;
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
    g_toast_channel;
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
    g_find_replace_channel;
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
    g_task_dialog_channel;
std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
    g_power_channel;
HWND g_top_hwnd = nullptr;
ITaskbarList3* g_taskbar_list = nullptr;
std::string g_pending_path;                 
std::string g_pending_name;
std::vector<std::string> g_launch_args;                     

                                                                      
std::wstring Utf8ToWide(const std::string& s) {
  if (s.empty()) return {};
  int len = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, nullptr, 0);
  if (len <= 0) return {};
  std::wstring ws(len - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, &ws[0], len);
  return ws;
}

std::string WideToUtf8(const std::wstring& ws) {
  if (ws.empty()) return {};
  int len = WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), -1, nullptr, 0, nullptr,
                                nullptr);
  if (len <= 0) return {};
  std::string s(len - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), -1, s.data(), len, nullptr,
                      nullptr);
  return s;
}

std::wstring ToLower(std::wstring s) {
  for (auto& c : s) {
    if (c >= L'A' && c <= L'Z') c = static_cast<wchar_t>(c - L'A' + L'a');
  }
  return s;
}

std::wstring FileNameOf(const std::wstring& path) {
  const size_t slash = path.find_last_of(L"\\/");
  return slash == std::wstring::npos ? path : path.substr(slash + 1);
}

std::wstring ExtensionOf(const std::wstring& path) {
  const size_t dot = path.find_last_of(L'.');
  if (dot == std::wstring::npos) return {};
  return ToLower(path.substr(dot));
}

bool IsSupportedExt(const std::wstring& ext) {
  if (ext.empty()) return false;
  return std::any_of(std::begin(kSupportedExts), std::end(kSupportedExts),
                     [&ext](const wchar_t* e) { return ext == e; });
}

std::wstring GetExePath() {
  wchar_t buf[MAX_PATH] = {};
  const DWORD len = GetModuleFileNameW(nullptr, buf, MAX_PATH);
  return len ? std::wstring(buf, len) : std::wstring();
}

std::wstring GetExeName() { return FileNameOf(GetExePath()); }

                                                                   
                                              
                                        
void EnsureTaskbarList() {
  if (g_taskbar_list) return;
  if (FAILED(::CoCreateInstance(CLSID_TaskbarList, nullptr,
                               CLSCTX_INPROC_SERVER,
                               IID_PPV_ARGS(&g_taskbar_list)))) {
    g_taskbar_list = nullptr;
    return;
  }
  g_taskbar_list->HrInit();
}

void ApplyTaskbarProgress(ProgressMode mode, int value) {
  if (!g_top_hwnd) return;
  EnsureTaskbarList();
  if (!g_taskbar_list) return;

  TBPFLAG flag = TBPF_NOPROGRESS;
  switch (mode) {
    case ProgressMode::kIndeterminate:
      flag = TBPF_INDETERMINATE;
      break;
    case ProgressMode::kDeterminate:
      flag = TBPF_NORMAL;
      break;
    case ProgressMode::kPaused:
      flag = TBPF_PAUSED;
      break;
    case ProgressMode::kError:
      flag = TBPF_ERROR;
      break;
    case ProgressMode::kNone:
    default:
      flag = TBPF_NOPROGRESS;
      break;
  }
  g_taskbar_list->SetProgressState(g_top_hwnd, flag);
  if (flag == TBPF_NORMAL || flag == TBPF_PAUSED || flag == TBPF_ERROR) {
    const int clamped = std::min(100, std::max(0, value));
    g_taskbar_list->SetProgressValue(g_top_hwnd, static_cast<ULONGLONG>(clamped),
                                     100);
  }
}

                                                                 
void PushVideoIntent(const std::string& path, const std::string& name) {
  if (!g_open_video_channel || path.empty()) return;
  flutter::EncodableMap map;
  map[flutter::EncodableValue("path")] = flutter::EncodableValue(path);
  map[flutter::EncodableValue("name")] = flutter::EncodableValue(name);
  g_open_video_channel->InvokeMethod(
      "onVideoIntent", std::make_unique<flutter::EncodableValue>(map));
}

                          
bool OpenMediaFile(const std::wstring& raw_path) {
  if (raw_path.empty()) return false;
  if (!IsSupportedExt(ExtensionOf(raw_path))) return false;

                                                  
  wchar_t full[MAX_PATH] = {};
  if (GetFullPathNameW(raw_path.c_str(), MAX_PATH, full, nullptr) == 0) {
    return false;
  }
  const DWORD attr = GetFileAttributesW(full);
  if (attr == INVALID_FILE_ATTRIBUTES ||
      (attr & FILE_ATTRIBUTE_DIRECTORY) != 0) {
    return false;
  }

  g_pending_path = WideToUtf8(full);
  g_pending_name = WideToUtf8(FileNameOf(full));
  OutputDebugStringW(
      (std::wstring(L"[OpenVideo] 外部视频: ") + full + L"\n").c_str());
  PushVideoIntent(g_pending_path, g_pending_name);
  return true;
}

                                 
void DigestLaunchArgs(const std::vector<std::string>& args) {
  for (const auto& arg : args) {
    if (arg.empty()) continue;
    if (arg[0] == '-') continue;                            
    if (OpenMediaFile(Utf8ToWide(arg))) break;           
  }
}

std::vector<std::string> SplitArgs(const std::string& payload) {
  std::vector<std::string> out;
  size_t start = 0;
  while (start <= payload.size()) {
    const size_t pos = payload.find(kArgSeparator, start);
    if (pos == std::string::npos) {
      if (start < payload.size()) out.push_back(payload.substr(start));
      break;
    }
    out.push_back(payload.substr(start, pos - start));
    start = pos + 1;
  }
  return out;
}

                                                                            
                                              
                                                                     
                                                                      
                                                                         
                                                          
                                                                 
                                                     
bool RegSetString(HKEY root, const std::wstring& sub_key,
                  const wchar_t* value_name, const std::wstring& data) {
  HKEY key = nullptr;
  if (RegCreateKeyExW(root, sub_key.c_str(), 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &key,
                      nullptr) != ERROR_SUCCESS) {
    return false;
  }
  const DWORD bytes = static_cast<DWORD>((data.size() + 1) * sizeof(wchar_t));
  const LONG ok = RegSetValueExW(key, value_name, 0, REG_SZ,
                                 reinterpret_cast<const BYTE*>(data.c_str()),
                                 bytes);
  RegCloseKey(key);
  return ok == ERROR_SUCCESS;
}

bool RegSetMultiString(HKEY root, const std::wstring& sub_key,
                       const wchar_t* value_name,
                       const std::vector<std::wstring>& items) {
  std::wstring blob;
  for (const auto& item : items) {
    blob += item;
    blob += L'\0';
  }
  blob += L'\0';                 
  HKEY key = nullptr;
  if (RegCreateKeyExW(root, sub_key.c_str(), 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &key,
                      nullptr) != ERROR_SUCCESS) {
    return false;
  }
  const LONG ok = RegSetValueExW(
      key, value_name, 0, REG_SZ, reinterpret_cast<const BYTE*>(blob.data()),
      static_cast<DWORD>(blob.size() * sizeof(wchar_t)));
  RegCloseKey(key);
  return ok == ERROR_SUCCESS;
}

                                            
                              
bool RegSetEmptyValue(HKEY root, const std::wstring& sub_key,
                      const wchar_t* value_name) {
  HKEY key = nullptr;
  if (RegCreateKeyExW(root, sub_key.c_str(), 0, nullptr,
                      REG_OPTION_NON_VOLATILE, KEY_SET_VALUE, nullptr, &key,
                      nullptr) != ERROR_SUCCESS) {
    return false;
  }
  const LONG ok =
      RegSetValueExW(key, value_name, 0, REG_NONE, nullptr, 0);
  RegCloseKey(key);
  return ok == ERROR_SUCCESS;
}

bool RegGetString(HKEY root, const std::wstring& sub_key,
                  const wchar_t* value_name, std::wstring* out) {
  HKEY key = nullptr;
  if (RegOpenKeyExW(root, sub_key.c_str(), 0, KEY_QUERY_VALUE, &key) !=
      ERROR_SUCCESS) {
    return false;
  }
  wchar_t buf[1024] = {};
  DWORD size = sizeof(buf);
  DWORD type = 0;
  const LONG ok = RegQueryValueExW(key, value_name, nullptr, &type,
                                   reinterpret_cast<LPBYTE>(buf), &size);
  RegCloseKey(key);
  if (ok != ERROR_SUCCESS || (type != REG_SZ && type != REG_EXPAND_SZ)) {
    return false;
  }
  *out = buf;
  return true;
}

void RegDeleteTreeIfExists(HKEY root, const std::wstring& sub_key) {
  RegDeleteTreeW(root, sub_key.c_str());
}

                                         
void RegDeleteValueIfEquals(HKEY root, const std::wstring& sub_key,
                            const wchar_t* value_name,
                            const std::wstring& expected) {
  std::wstring current;
  if (!RegGetString(root, sub_key, value_name, &current)) return;
  if (_wcsicmp(current.c_str(), expected.c_str()) != 0) return;
  HKEY key = nullptr;
  if (RegOpenKeyExW(root, sub_key.c_str(), 0, KEY_SET_VALUE, &key) !=
      ERROR_SUCCESS) {
    return;
  }
  RegDeleteValueW(key, value_name);
  RegCloseKey(key);
}

std::wstring QuotedExeCommand() {
  return L"\"" + GetExePath() + L"\" \"%1\"";
}

std::vector<std::wstring> AllExtensions() {
  return std::vector<std::wstring>(std::begin(kSupportedExts),
                                   std::end(kSupportedExts));
}

                                    
void NotifyAssocChanged() {
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST | SHCNF_FLUSH, nullptr,
                 nullptr);
}

bool RegisterFileAssociations(bool as_default) {
  const std::wstring exe_path = GetExePath();
  const std::wstring exe_name = GetExeName();
  if (exe_path.empty() || exe_name.empty()) return false;

  const std::wstring command = QuotedExeCommand();
  const std::wstring icon = L"\"" + exe_path + L"\",0";
  const std::wstring progid_key = std::wstring(kClassesHive) + kProgId;
  const std::wstring app_key = std::wstring(kClassesHive) +
                               L"Applications\\" + exe_name;
  const std::wstring caps_key = app_key + L"\\Capabilities";
  const std::vector<std::wstring> exts = AllExtensions();

                            
  RegSetString(HKEY_CURRENT_USER, progid_key, nullptr, kProgIdDesc);
  RegSetString(HKEY_CURRENT_USER, progid_key, L"FriendlyTypeName", kProgIdDesc);
  RegSetString(HKEY_CURRENT_USER, progid_key + L"\\DefaultIcon", nullptr, icon);
  RegSetString(HKEY_CURRENT_USER, progid_key + L"\\shell\\open", nullptr,
               kAppDisplayName);
  RegSetString(HKEY_CURRENT_USER, progid_key + L"\\shell\\open",
               L"FriendlyAppName", kAppDisplayName);
  RegSetString(HKEY_CURRENT_USER, progid_key + L"\\shell\\open\\command",
               nullptr, command);

                                                
  RegSetString(HKEY_CURRENT_USER, app_key, L"ApplicationName",
               kAppDisplayName);
  RegSetString(HKEY_CURRENT_USER, app_key, L"ApplicationDescription",
               L"用 NaviFlash 播放本地视频");
  RegSetString(HKEY_CURRENT_USER, app_key, L"ApplicationCompany",
               L"memz2345");
  RegSetString(HKEY_CURRENT_USER, app_key, L"FriendlyAppName", kAppDisplayName);
  RegSetString(HKEY_CURRENT_USER, app_key + L"\\DefaultIcon", nullptr, icon);
  RegSetString(HKEY_CURRENT_USER, app_key + L"\\shell\\open", nullptr,
               kAppDisplayName);
  RegSetString(HKEY_CURRENT_USER, app_key + L"\\shell\\open",
               L"FriendlyAppName", kAppDisplayName);
  RegSetString(HKEY_CURRENT_USER, app_key + L"\\shell\\open\\command", nullptr,
               command);
  RegSetMultiString(HKEY_CURRENT_USER, app_key, L"SupportedTypes", exts);

                                                          
  RegSetString(HKEY_CURRENT_USER, caps_key, L"ApplicationName",
               kAppDisplayName);
  RegSetString(HKEY_CURRENT_USER, caps_key, L"ApplicationDescription",
               L"用 NaviFlash 播放本地视频");
  for (const auto& ext : exts) {
    RegSetString(HKEY_CURRENT_USER, caps_key + L"\\FileAssociations", ext.c_str(),
                 kProgId);
  }
  RegSetString(HKEY_CURRENT_USER,
               L"Software\\RegisteredApplications", kRegisteredAppName,
               L"Software\\Classes\\Applications\\" + exe_name +
                   L"\\Capabilities");

                                         
  for (const auto& ext : exts) {
    const std::wstring ext_key = std::wstring(kClassesHive) + ext;
    RegSetEmptyValue(HKEY_CURRENT_USER, ext_key + L"\\OpenWithProgids",
                     kProgId);
    if (as_default) {
      RegSetString(HKEY_CURRENT_USER, ext_key, nullptr, kProgId);
    } else {
                                        
      RegDeleteValueIfEquals(HKEY_CURRENT_USER, ext_key, nullptr, kProgId);
    }
  }

  NotifyAssocChanged();
  return true;
}

bool UnregisterFileAssociations() {
  const std::wstring exe_name = GetExeName();
  const std::vector<std::wstring> exts = AllExtensions();

  for (const auto& ext : exts) {
    const std::wstring ext_key = std::wstring(kClassesHive) + ext;
                                
    RegDeleteValueIfEquals(HKEY_CURRENT_USER, ext_key, nullptr, kProgId);
    HKEY progids = nullptr;
    const std::wstring progids_key = ext_key + L"\\OpenWithProgids";
    if (RegOpenKeyExW(HKEY_CURRENT_USER, progids_key.c_str(), 0, KEY_SET_VALUE,
                      &progids) == ERROR_SUCCESS) {
      RegDeleteValueW(progids, kProgId);
      RegCloseKey(progids);
    }
  }

  RegDeleteTreeIfExists(HKEY_CURRENT_USER, std::wstring(kClassesHive) + kProgId);
  if (!exe_name.empty()) {
    RegDeleteTreeIfExists(HKEY_CURRENT_USER,
                          std::wstring(kClassesHive) + L"Applications\\" +
                              exe_name);
  }
  HKEY registered = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, L"Software\\RegisteredApplications", 0,
                    KEY_SET_VALUE, &registered) == ERROR_SUCCESS) {
    RegDeleteValueW(registered, kRegisteredAppName);
    RegCloseKey(registered);
  }

  NotifyAssocChanged();
  return true;
}

bool IsFileAssociationRegistered() {
  const std::wstring exe_name = GetExeName();
  if (exe_name.empty()) return false;
  std::wstring command;
  return RegGetString(HKEY_CURRENT_USER,
                      std::wstring(kClassesHive) + L"Applications\\" +
                          exe_name + L"\\shell\\open\\command",
                      nullptr, &command) &&
         !command.empty();
}

                                                                 
void HandleTaskbarCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "setProgress") {
    int mode = 0;
    int value = 0;
    if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
      if (auto it = args->find(flutter::EncodableValue("mode"));
          it != args->end()) {
        if (const auto* v = std::get_if<int32_t>(&it->second)) mode = *v;
      }
      if (auto it = args->find(flutter::EncodableValue("value"));
          it != args->end()) {
        if (const auto* v = std::get_if<int32_t>(&it->second)) {
          value = *v;
        } else if (const auto* d = std::get_if<double>(&it->second)) {
          value = static_cast<int>(*d);
        }
      }
    }
    ApplyTaskbarProgress(static_cast<ProgressMode>(mode), value);
    result->Success();
    return;
  }
  result->NotImplemented();
}

void HandleOpenVideoCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& name = call.method_name();

  if (name == "consumePendingVideo") {
    if (g_pending_path.empty()) {
      result->Success(flutter::EncodableValue());
      return;
    }
    flutter::EncodableMap map;
    map[flutter::EncodableValue("path")] =
        flutter::EncodableValue(g_pending_path);
    map[flutter::EncodableValue("name")] =
        flutter::EncodableValue(g_pending_name);
    g_pending_path.clear();
    g_pending_name.clear();
    result->Success(flutter::EncodableValue(map));
    return;
  }

  if (name == "openPaths") {
                                          
    bool opened = false;
    if (const auto* args = std::get_if<flutter::EncodableList>(call.arguments())) {
      for (const auto& item : *args) {
        if (const auto* path = std::get_if<std::string>(&item)) {
          if (OpenMediaFile(Utf8ToWide(*path))) {
            opened = true;
            break;
          }
        }
      }
    }
    result->Success(flutter::EncodableValue(opened));
    return;
  }

  if (name == "registerFileAssociations") {
    bool as_default = false;
    if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
      if (auto it = args->find(flutter::EncodableValue("asDefault"));
          it != args->end()) {
        if (const auto* v = std::get_if<bool>(&it->second)) as_default = *v;
      }
    }
    result->Success(
        flutter::EncodableValue(RegisterFileAssociations(as_default)));
    return;
  }

  if (name == "unregisterFileAssociations") {
    result->Success(flutter::EncodableValue(UnregisterFileAssociations()));
    return;
  }

  if (name == "isFileAssociationRegistered") {
    result->Success(flutter::EncodableValue(IsFileAssociationRegistered()));
    return;
  }

  if (name == "finishExternalSession") {
                                          
    result->Success();
    return;
  }

  result->NotImplemented();
}

}              

                                                                 
                                                                 
                                                                
                                           
                       
                                                             
                                                
bool IsWin10OrGreater() {
  using RtlGetVersionPtr = LONG(WINAPI*)(OSVERSIONINFOW*);
  HMODULE ntdll = ::GetModuleHandleW(L"ntdll.dll");
  if (!ntdll) return false;
  auto rtl_get_version = reinterpret_cast<RtlGetVersionPtr>(
      ::GetProcAddress(ntdll, "RtlGetVersion"));
  if (!rtl_get_version) return false;
  OSVERSIONINFOW vi = {};
  vi.dwOSVersionInfoSize = sizeof(vi);
  if (rtl_get_version(&vi) != 0) return false;
  return vi.dwMajorVersion >= 10;
}

std::wstring EscapeXml(const std::wstring& s) {
  std::wstring out;
  out.reserve(s.size());
  for (const wchar_t c : s) {
    switch (c) {
      case L'&': out += L"&amp;"; break;
      case L'<': out += L"&lt;"; break;
      case L'>': out += L"&gt;"; break;
      case L'"': out += L"&quot;"; break;
      case L'\'': out += L"&apos;"; break;
      default: out += c; break;
    }
  }
  return out;
}

                               
                                                           
                                          
std::wstring PercentEncodeUtf8(const std::string& utf8) {
  static const std::string kKeep =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~:/";
  std::string out;
  out.reserve(utf8.size() * 3);
  for (unsigned char c : utf8) {
    if (kKeep.find(static_cast<char>(c)) != std::string::npos) {
      out += static_cast<char>(c);
    } else {
      char buf[4];
      std::snprintf(buf, sizeof(buf), "%%%02X", c);
      out += buf;
    }
  }
  return Utf8ToWide(out);
}

                                                   
                                                                 
                                                            
            
                                                            
                                                       
                                      
                   
std::wstring ToastAumid() {
  PWSTR raw = nullptr;
  if (SUCCEEDED(::GetCurrentProcessExplicitAppUserModelID(&raw)) && raw) {
    std::wstring id(raw);
    ::CoTaskMemFree(raw);
    if (!id.empty()) return id;
  }
  return kAppDisplayName;
}

                                                   
                                              
std::wstring FileUriFromPath(const std::wstring& path) {
  std::wstring p = path;
  std::replace(p.begin(), p.end(), L'\\', L'/');
  return L"file:///" + PercentEncodeUtf8(WideToUtf8(p));
}

                                               
bool ShowToastWithImage(const std::wstring& title, const std::wstring& body,
                        const std::wstring& image_path) {
  if (!IsWin10OrGreater()) {
    OutputDebugStringW(L"[toast] 系统 < Windows 10，跳过大图 toast\n");
    return false;
  }
  try {
    using namespace winrt::Windows::Data::Xml::Dom;
    using namespace winrt::Windows::UI::Notifications;

    std::wstring xml =
        L"<toast><visual><binding template=\"ToastGeneric\">"
        L"<text>" + EscapeXml(title) + L"</text>"
        L"<text>" + EscapeXml(body) + L"</text>";
    if (!image_path.empty()) {
      xml += L"<image src=\"" + EscapeXml(FileUriFromPath(image_path)) +
             L"\" placement=\"inline\" hint-crop=\"none\"/>";
    }
    xml += L"</binding></visual></toast>";

    XmlDocument doc;
    doc.LoadXml(xml);
    ToastNotification toast(doc);
                                                       
                                                   
    OutputDebugStringW((std::wstring(L"[toast] xml: ") + xml + L"\n").c_str());
    ToastNotificationManager::CreateToastNotifier(
        winrt::hstring(ToastAumid()))
        .Show(toast);
    return true;
  } catch (const winrt::hresult_error& e) {
    OutputDebugStringW((std::wstring(L"[toast] show failed: ") +
                        e.message().c_str())
                           .c_str());
    return false;
  } catch (...) {
    return false;
  }
}

void HandleToastCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "showImage") {
    std::string title, body, image_path;
    if (const auto* args =
            std::get_if<flutter::EncodableMap>(call.arguments())) {
      auto read = [args](const char* key, std::string& out) {
        if (auto it = args->find(flutter::EncodableValue(key));
            it != args->end()) {
          if (const auto* v = std::get_if<std::string>(&it->second)) {
            out = *v;
          }
        }
      };
      read("title", title);
      read("body", body);
      read("imagePath", image_path);
    }
    const bool shown = ShowToastWithImage(
        Utf8ToWide(title), Utf8ToWide(body), Utf8ToWide(image_path));
    result->Success(flutter::EncodableValue(shown));
    return;
  }
  result->NotImplemented();
}

                                                    
                                                
void HandleTaskDialogCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() != "show") {
    result->NotImplemented();
    return;
  }

  task_dialog::Options options;
  if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
    auto read = [args](const char* key, std::wstring& out) {
      if (auto it = args->find(flutter::EncodableValue(key)); it != args->end()) {
        if (const auto* v = std::get_if<std::string>(&it->second)) {
          out = Utf8ToWide(*v);
        }
      }
    };
    read("title", options.title);
    read("heading", options.heading);
    read("content", options.content);

    if (auto it = args->find(flutter::EncodableValue("links"));
        it != args->end()) {
      if (const auto* list = std::get_if<flutter::EncodableList>(&it->second)) {
        for (const auto& item : *list) {
          const auto* link = std::get_if<flutter::EncodableMap>(&item);
          if (link == nullptr) continue;
          task_dialog::CommandLink entry;
          if (auto t = link->find(flutter::EncodableValue("text"));
              t != link->end()) {
            if (const auto* v = std::get_if<std::string>(&t->second)) {
              entry.text = Utf8ToWide(*v);
            }
          }
          if (auto sub = link->find(flutter::EncodableValue("subtitle"));
              sub != link->end()) {
            if (const auto* v = std::get_if<std::string>(&sub->second)) {
              entry.subtitle = Utf8ToWide(*v);
            }
          }
          if (!entry.text.empty()) options.links.push_back(std::move(entry));
        }
      }
    }
  }

  const int selected = task_dialog::Show(g_top_hwnd, options);
  result->Success(flutter::EncodableValue(selected));
}

                                                  
                                                
void HandleFindReplaceCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() != "show") {
    result->NotImplemented();
    return;
  }

  find_replace::Labels labels;
  std::vector<std::wstring> rules_in;
  if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
    auto read = [args](const char* key, std::string& out) {
      if (auto it = args->find(flutter::EncodableValue(key)); it != args->end()) {
        if (const auto* v = std::get_if<std::string>(&it->second)) out = *v;
      }
    };
    std::string v;
    read("title", v);            labels.title = Utf8ToWide(v);
    read("find", v);             labels.find = Utf8ToWide(v);
    read("replace", v);          labels.replace = Utf8ToWide(v);
    read("resultPrefix", v);     labels.result_prefix = Utf8ToWide(v);
    read("caseSensitive", v);    labels.case_sensitive = Utf8ToWide(v);
    read("wholeWord", v);        labels.whole_word = Utf8ToWide(v);
    read("regex", v);            labels.regex = Utf8ToWide(v);
    read("prev", v);             labels.prev = Utf8ToWide(v);
    read("next", v);             labels.next = Utf8ToWide(v);
    read("replaceOne", v);       labels.replace_one = Utf8ToWide(v);
    read("replaceAll", v);       labels.replace_all = Utf8ToWide(v);
    read("deleteMatches", v);    labels.delete_matches = Utf8ToWide(v);
    read("ok", v);               labels.ok = Utf8ToWide(v);
    read("cancel", v);           labels.cancel = Utf8ToWide(v);

    if (auto it = args->find(flutter::EncodableValue("rules"));
        it != args->end()) {
      if (const auto* list = std::get_if<flutter::EncodableList>(&it->second)) {
        for (const auto& item : *list) {
          if (const auto* str = std::get_if<std::string>(&item)) {
            rules_in.push_back(Utf8ToWide(*str));
          }
        }
      }
    }
  }

  std::vector<std::wstring> rules_out;
  const bool saved =
      find_replace::Show(g_top_hwnd, labels, rules_in, &rules_out);
  if (!saved) {
    result->Success(flutter::EncodableValue());              
    return;
  }

  flutter::EncodableList out;
  out.reserve(rules_out.size());
  for (const std::wstring& r : rules_out) {
    out.push_back(flutter::EncodableValue(WideToUtf8(r)));
  }
  result->Success(flutter::EncodableValue(out));
}

                                                                         
  
                                                 
                                           
                                      
                              
  
                                                                   
                                                   
                                   
constexpr ULONG kPowerThrottlingExecutionSpeed = 0x1;
constexpr ULONG kPowerThrottlingIgnoreTimerResolution = 0x4;
constexpr ULONG kPowerThrottlingStateVersion = 1;

struct PowerThrottlingState {
  ULONG Version;
  ULONG ControlMask;
  ULONG StateMask;
};

using SetProcessInformationFn =
    BOOL(WINAPI*)(HANDLE, PROCESS_INFORMATION_CLASS, LPVOID, DWORD);
using GetProcessInformationFn =
    BOOL(WINAPI*)(HANDLE, PROCESS_INFORMATION_CLASS, LPVOID, DWORD);

                                                               
                     
constexpr PROCESS_INFORMATION_CLASS kPowerThrottlingClass =
    static_cast<PROCESS_INFORMATION_CLASS>(4);

SetProcessInformationFn ResolveSetProcessInformation() {
  static SetProcessInformationFn fn = []() -> SetProcessInformationFn {
    const HMODULE kernel32 = GetModuleHandleW(L"kernel32.dll");
    if (kernel32 == nullptr) return nullptr;
    return reinterpret_cast<SetProcessInformationFn>(
        GetProcAddress(kernel32, "SetProcessInformation"));
  }();
  return fn;
}

GetProcessInformationFn ResolveGetProcessInformation() {
  static GetProcessInformationFn fn = []() -> GetProcessInformationFn {
    const HMODULE kernel32 = GetModuleHandleW(L"kernel32.dll");
    if (kernel32 == nullptr) return nullptr;
    return reinterpret_cast<GetProcessInformationFn>(
        GetProcAddress(kernel32, "GetProcessInformation"));
  }();
  return fn;
}

                                    
bool QueryThrottlingState(PowerThrottlingState* out) {
  const GetProcessInformationFn get = ResolveGetProcessInformation();
  if (get == nullptr) return false;
  PowerThrottlingState state{};
  state.Version = kPowerThrottlingStateVersion;
  if (get(GetCurrentProcess(), kPowerThrottlingClass, &state,
          sizeof(state)) == FALSE) {
    return false;
  }
  if (out != nullptr) *out = state;
  return true;
}

                              
                                                                           
                                                 
                                                  
                       
   
                                                       
                                                        
                                         
   
                                                        
                           
void ReleaseWakeRequests() { SetThreadExecutionState(ES_CONTINUOUS); }

                                             
bool ApplyThrottlingState(bool enable) {
  const SetProcessInformationFn set = ResolveSetProcessInformation();
  if (set == nullptr) return false;
  if (enable) ReleaseWakeRequests();
  PowerThrottlingState state{};
  state.Version = kPowerThrottlingStateVersion;
                              
  state.ControlMask =
      kPowerThrottlingExecutionSpeed | kPowerThrottlingIgnoreTimerResolution;
                                   
  state.StateMask = enable ? state.ControlMask : 0;
  return set(GetCurrentProcess(), kPowerThrottlingClass, &state,
             sizeof(state)) != FALSE;
}

                                       
bool GetEfficiencyMode() {
  PowerThrottlingState state{};
  if (!QueryThrottlingState(&state)) return false;
  return (state.StateMask & kPowerThrottlingExecutionSpeed) != 0;
}

                                          
   
                                         
                                              
flutter::EncodableMap PowerSnapshot(bool ok, DWORD error) {
  PowerThrottlingState state{};
  const bool queried = QueryThrottlingState(&state);
  flutter::EncodableMap out;
  out[flutter::EncodableValue("ok")] = flutter::EncodableValue(ok);
  out[flutter::EncodableValue("queried")] = flutter::EncodableValue(queried);
  out[flutter::EncodableValue("active")] =
      flutter::EncodableValue(queried &&
                              (state.StateMask & kPowerThrottlingExecutionSpeed) !=
                                  0);
  out[flutter::EncodableValue("control")] = flutter::EncodableValue(
      static_cast<int32_t>(queried ? state.ControlMask : 0));
  out[flutter::EncodableValue("state")] = flutter::EncodableValue(
      static_cast<int32_t>(queried ? state.StateMask : 0));
  out[flutter::EncodableValue("error")] =
      flutter::EncodableValue(static_cast<int32_t>(error));
  return out;
}

void HandlePowerCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  if (method == "isSupported") {
    result->Success(flutter::EncodableValue(
        ResolveSetProcessInformation() != nullptr &&
        ResolveGetProcessInformation() != nullptr));
    return;
  }
  if (method == "getEfficiencyMode") {
                                                   
    result->Success(flutter::EncodableValue(PowerSnapshot(true, 0)));
    return;
  }
  if (method == "setEfficiencyMode") {
    bool enable = true;
    if (const auto* args =
            std::get_if<flutter::EncodableMap>(call.arguments())) {
      if (auto it = args->find(flutter::EncodableValue("enabled"));
          it != args->end()) {
        if (const auto* v = std::get_if<bool>(&it->second)) enable = *v;
      }
    }
    const BOOL ok = ApplyThrottlingState(enable);
    const DWORD error = ok != FALSE ? 0 : GetLastError();
    result->Success(flutter::EncodableValue(PowerSnapshot(ok != FALSE, error)));
    return;
  }
  result->NotImplemented();
}

void Register(flutter::BinaryMessenger* messenger, HWND top_hwnd,
              HWND view_hwnd) {
  g_top_hwnd = top_hwnd;

  g_taskbar_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.memz2345.navi.flash/taskbar",
      &flutter::StandardMethodCodec::GetInstance());
  g_taskbar_channel->SetMethodCallHandler(HandleTaskbarCall);

  g_open_video_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.memz2345.navi.flash/open_video",
      &flutter::StandardMethodCodec::GetInstance());
  g_open_video_channel->SetMethodCallHandler(HandleOpenVideoCall);

  g_toast_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.memz2345.navi.flash/toast",
      &flutter::StandardMethodCodec::GetInstance());
  g_toast_channel->SetMethodCallHandler(HandleToastCall);

  g_find_replace_channel = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.memz2345.navi.flash/find_replace",
      &flutter::StandardMethodCodec::GetInstance());
  g_find_replace_channel->SetMethodCallHandler(HandleFindReplaceCall);

  g_task_dialog_channel = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.memz2345.navi.flash/task_dialog",
      &flutter::StandardMethodCodec::GetInstance());
  g_task_dialog_channel->SetMethodCallHandler(HandleTaskDialogCall);

  g_power_channel = std::make_unique<
      flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.memz2345.navi.flash/power",
      &flutter::StandardMethodCodec::GetInstance());
  g_power_channel->SetMethodCallHandler(HandlePowerCall);

  (void)view_hwnd;

                                           
  DigestLaunchArgs(g_launch_args);
  g_launch_args.clear();
}

void SetTaskbarProgress(ProgressMode mode, int value) {
  ApplyTaskbarProgress(mode, value);
}

void Unregister() {
  if (g_taskbar_list && g_top_hwnd) {
    g_taskbar_list->SetProgressState(g_top_hwnd, TBPF_NOPROGRESS);
  }
  if (g_taskbar_list) {
    g_taskbar_list->Release();
    g_taskbar_list = nullptr;
  }
  g_open_video_channel.reset();
  g_toast_channel.reset();
  g_find_replace_channel.reset();
  g_task_dialog_channel.reset();
  g_power_channel.reset();
  g_taskbar_channel.reset();
  g_top_hwnd = nullptr;
}

void SetLaunchArgs(const std::vector<std::string>& args) {
  g_launch_args = args;
}

bool IsHandledLaunchArg(const std::string& arg) {
  if (arg.empty()) return false;
  if (arg[0] != '-') {
                                      
    const std::wstring wide = Utf8ToWide(arg);
    if (!IsSupportedExt(ExtensionOf(wide))) return false;
    wchar_t full[MAX_PATH] = {};
    if (GetFullPathNameW(wide.c_str(), MAX_PATH, full, nullptr) == 0) {
      return false;
    }
    const DWORD attr = GetFileAttributesW(full);
    return attr != INVALID_FILE_ATTRIBUTES &&
           (attr & FILE_ATTRIBUTE_DIRECTORY) == 0;
  }
  return arg.rfind("--flash-action=", 0) == 0;
}

bool HandleForwardedArgs(const std::string& payload) {
  const std::vector<std::string> args = SplitArgs(payload);
  if (args.empty()) return false;
  const bool had_pending = !g_pending_path.empty();
  DigestLaunchArgs(args);
                                                    
  return !had_pending && !g_pending_path.empty();
}

void EnableFileDrop(HWND hwnd) {
  if (hwnd) DragAcceptFiles(hwnd, TRUE);
}

bool HandleDropFiles(HDROP drop) {
  if (!drop) return false;
  const UINT count = DragQueryFileW(drop, 0xFFFFFFFF, nullptr, 0);
  bool handled = false;
  wchar_t buf[MAX_PATH] = {};
  for (UINT i = 0; i < count; i++) {
    if (DragQueryFileW(drop, i, buf, MAX_PATH) == 0) continue;
    if (OpenMediaFile(buf)) {
      handled = true;
      break;                      
    }
  }
  return handled;
}

}                            
