                                   
  
                      
                                                                             
                                                                   
                                                                           
                                             
                                                   
  
                                                                      
                                                           

#include "smtc_controls.h"

#include <objbase.h>
#include <shellapi.h>                 
#include <shobjidl.h>                                
#include <shlwapi.h>

#include <gdiplus.h>
#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "windowsapp.lib")                                         

                                               
#include <SystemMediaTransportControlsInterop.h>

                                                    
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Media.h>
#include <winrt/Windows.Storage.Streams.h>

namespace smtc {
namespace {

using namespace winrt;
using namespace winrt::Windows::Foundation;
using namespace winrt::Windows::Media;
using namespace winrt::Windows::Storage::Streams;

                           
                                  
constexpr UINT kMsgSmtcButton = WM_APP + 0x5B1;

                                              
constexpr int kThumbFirst = 4200;
enum ThumbButtonId {
  kThumbPrev = kThumbFirst,        
  kThumbRewind,                        
  kThumbPlayPause,                              
  kThumbFastForward,                   
  kThumbNext,                      
};
constexpr int kThumbLast = kThumbNext;

                        
constexpr const char* kActionPlay = "play";
constexpr const char* kActionPause = "pause";
constexpr const char* kActionPlayPause = "playPause";
constexpr const char* kActionNext = "next";
constexpr const char* kActionPrevious = "previous";
constexpr const char* kActionRewind = "rewind";
constexpr const char* kActionFastForward = "fastForward";

                                         
struct State {
  HWND hwnd = nullptr;
  std::function<void(const std::string&)> onAction;

         
  SystemMediaTransportControls controls{nullptr};
  SystemMediaTransportControls::ButtonPressed_revoker buttonRevoker;
  bool smtcReady = false;
  bool active = false;
  bool playing = false;

              
  ITaskbarList3* taskbar = nullptr;
  HICON iconPrev = nullptr;
  HICON iconRewind = nullptr;
  HICON iconPlay = nullptr;
  HICON iconPause = nullptr;
  HICON iconFastForward = nullptr;
  HICON iconNext = nullptr;
  bool thumbbarAdded = false;

         
  ULONG_PTR gdiplusToken = 0;
};

State g_state;

                           
std::wstring Utf8ToWide(const std::string& s) {
  if (s.empty()) return {};
  int len = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, nullptr, 0);
  if (len <= 0) return {};
  std::wstring ws(len - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, &ws[0], len);
  return ws;
}

                                
TimeSpan TicksFromMs(int64_t ms) {
  if (ms < 0) ms = 0;
  return TimeSpan{ms * 10000};
}

                               
                                                        
bool IsLightSystemTheme() {
  HKEY key = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER,
                    L"Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
                    0, KEY_READ, &key) == ERROR_SUCCESS) {
    DWORD value = 0, size = sizeof(value), type = REG_DWORD;
    LSTATUS status = RegQueryValueExW(key, L"SystemUsesLightTheme", nullptr,
                                      &type, reinterpret_cast<LPBYTE>(&value),
                                      &size);
    RegCloseKey(key);
    if (status == ERROR_SUCCESS) return value != 0;
  }
  return false;
}

                                  
enum class Glyph { kPrev, kRewind, kPlay, kPause, kFastForward, kNext };

HICON CreateGlyphIcon(Glyph glyph, int size, const Gdiplus::Color& color) {
  Gdiplus::Bitmap bitmap(size, size, PixelFormat32bppARGB);
  Gdiplus::Graphics g(&bitmap);
  g.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
  Gdiplus::SolidBrush brush(color);

  const double s = static_cast<double>(size);
  auto px = [s](double v) { return static_cast<Gdiplus::REAL>(v * s); };
  auto fillTriangle = [&](double x1, double y1, double x2, double y2, double x3,
                          double y3) {
    Gdiplus::PointF pts[3] = {{px(x1), px(y1)},
                              {px(x2), px(y2)},
                              {px(x3), px(y3)}};
    g.FillPolygon(&brush, pts, 3);
  };
  auto fillRect = [&](double x, double y, double w, double h) {
    g.FillRectangle(&brush, Gdiplus::RectF(px(x), px(y), px(w), px(h)));
  };

  switch (glyph) {
    case Glyph::kPrev:           
      fillRect(0.18, 0.26, 0.10, 0.48);
      fillTriangle(0.72, 0.24, 0.72, 0.76, 0.34, 0.50);
      break;
    case Glyph::kNext:           
      fillTriangle(0.28, 0.24, 0.28, 0.76, 0.66, 0.50);
      fillRect(0.72, 0.26, 0.10, 0.48);
      break;
    case Glyph::kRewind:               
      fillTriangle(0.78, 0.26, 0.78, 0.74, 0.46, 0.50);
      fillTriangle(0.54, 0.26, 0.54, 0.74, 0.22, 0.50);
      break;
    case Glyph::kFastForward:               
      fillTriangle(0.22, 0.26, 0.22, 0.74, 0.54, 0.50);
      fillTriangle(0.46, 0.26, 0.46, 0.74, 0.78, 0.50);
      break;
    case Glyph::kPlay:      
      fillTriangle(0.30, 0.22, 0.30, 0.78, 0.78, 0.50);
      break;
    case Glyph::kPause:      
      fillRect(0.30, 0.24, 0.13, 0.52);
      fillRect(0.57, 0.24, 0.13, 0.52);
      break;
  }

  HICON icon = nullptr;
  if (bitmap.GetHICON(&icon) == Gdiplus::Ok) return icon;
  return nullptr;
}

void CreateAllIcons() {
  int size = GetSystemMetrics(SM_CXSMICON);
  if (size < 16) size = 16;
  const Gdiplus::Color color =
      IsLightSystemTheme() ? Gdiplus::Color(255, 25, 25, 25)
                           : Gdiplus::Color(255, 250, 250, 250);
  g_state.iconPrev = CreateGlyphIcon(Glyph::kPrev, size, color);
  g_state.iconRewind = CreateGlyphIcon(Glyph::kRewind, size, color);
  g_state.iconPlay = CreateGlyphIcon(Glyph::kPlay, size, color);
  g_state.iconPause = CreateGlyphIcon(Glyph::kPause, size, color);
  g_state.iconFastForward = CreateGlyphIcon(Glyph::kFastForward, size, color);
  g_state.iconNext = CreateGlyphIcon(Glyph::kNext, size, color);
}

void DestroyAllIcons() {
  struct Item {
    HICON& icon;
  } items[] = {{g_state.iconPrev},       {g_state.iconRewind},
               {g_state.iconPlay},       {g_state.iconPause},
               {g_state.iconFastForward}, {g_state.iconNext}};
  for (auto& item : items) {
    if (item.icon) {
      DestroyIcon(item.icon);
      item.icon = nullptr;
    }
  }
}

bool IconsReady() {
  return g_state.iconPrev && g_state.iconRewind && g_state.iconPlay &&
         g_state.iconPause && g_state.iconFastForward && g_state.iconNext;
}

                                  
void EnsureTaskbar() {
  if (g_state.taskbar) return;
  HRESULT hr = CoCreateInstance(CLSID_TaskbarList, nullptr,
                                CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&g_state.taskbar));
  if (SUCCEEDED(hr) && g_state.taskbar) {
    g_state.taskbar->HrInit();
  } else {
    g_state.taskbar = nullptr;
  }
}

                                                        
                                 
                                               
void ApplyThumbbar(bool visible) {
  if (!g_state.taskbar || !g_state.hwnd || !IconsReady()) return;

  struct Def {
    int id;
    HICON icon;
    const wchar_t* tip;
  };
  Def defs[5] = {
      {kThumbPrev, g_state.iconPrev, L"\x4e0a\x4e00\x96c6"},                
      {kThumbRewind, g_state.iconRewind, L"\x56de\x9000 20\x79d2"},             
      {kThumbPlayPause, g_state.playing ? g_state.iconPause : g_state.iconPlay,
       g_state.playing ? L"\x6682\x505c" : L"\x64ad\x653e"},                    
      {kThumbFastForward, g_state.iconFastForward,
       L"\x5feb\x8fdb 20\x79d2"},                                               
      {kThumbNext, g_state.iconNext, L"\x4e0b\x4e00\x96c6"},                
  };

  THUMBBUTTON buttons[5] = {};
  for (int i = 0; i < 5; i++) {
    buttons[i].dwMask = THB_ICON | THB_TOOLTIP | THB_FLAGS;
    buttons[i].iId = static_cast<UINT>(defs[i].id);
    buttons[i].hIcon = defs[i].icon;
    buttons[i].dwFlags = visible ? THBF_ENABLED : THBF_HIDDEN;
    wcscpy_s(buttons[i].szTip, defs[i].tip);
  }

  if (!g_state.thumbbarAdded) {
    HRESULT hr = g_state.taskbar->ThumbBarAddButtons(g_state.hwnd, 5, buttons);
    if (SUCCEEDED(hr)) g_state.thumbbarAdded = true;
  } else {
    g_state.taskbar->ThumbBarUpdateButtons(g_state.hwnd, 5, buttons);
  }
}

                             
void EnsureSmtc() {
  if (g_state.smtcReady || !g_state.hwnd) return;
  try {
                                                    
                                                                               
    auto factory =
        get_activation_factory<Windows::Media::SystemMediaTransportControls>();
    auto interop = factory.as<ISystemMediaTransportControlsInterop>();

    Windows::Media::SystemMediaTransportControls controls{nullptr};
    check_hresult(interop->GetForWindow(
        g_state.hwnd, guid_of<Windows::Media::SystemMediaTransportControls>(),
        put_abi(controls)));

    controls.IsEnabled(true);
    controls.IsPlayEnabled(true);
    controls.IsPauseEnabled(true);
    controls.IsNextEnabled(true);
    controls.IsPreviousEnabled(true);
    controls.IsFastForwardEnabled(true);
    controls.IsRewindEnabled(true);
    controls.PlaybackStatus(MediaPlaybackStatus::Closed);

    HWND hwnd = g_state.hwnd;
    g_state.buttonRevoker = controls.ButtonPressed(
        winrt::auto_revoke,
        [hwnd](SystemMediaTransportControls const&           ,
               SystemMediaTransportControlsButtonPressedEventArgs const& args) {
                                                  
          const char* action = nullptr;
          switch (args.Button()) {
            case SystemMediaTransportControlsButton::Play:
              action = kActionPlay;
              break;
            case SystemMediaTransportControlsButton::Pause:
              action = kActionPause;
              break;
            case SystemMediaTransportControlsButton::Next:
              action = kActionNext;
              break;
            case SystemMediaTransportControlsButton::Previous:
              action = kActionPrevious;
              break;
            case SystemMediaTransportControlsButton::Rewind:
              action = kActionRewind;
              break;
            case SystemMediaTransportControlsButton::FastForward:
              action = kActionFastForward;
              break;
            default:
              return;
          }
          PostMessageW(hwnd, kMsgSmtcButton, 0,
                       reinterpret_cast<LPARAM>(action));
        });

    g_state.controls = controls;
    g_state.smtcReady = true;
  } catch (...) {
                                          
    g_state.controls = nullptr;
    g_state.smtcReady = false;
  }
}

void SetSmtcMetadata(const std::string& title, const std::string& artist,
                     const std::string& artUri) {
  if (!g_state.smtcReady) return;
  try {
    auto updater = g_state.controls.DisplayUpdater();
    updater.Type(MediaPlaybackType::Music);
    auto props = updater.MusicProperties();
    if (!title.empty()) props.Title(to_hstring(title));
    if (!artist.empty()) props.Artist(to_hstring(artist));

                                                          
    std::wstring wArt = Utf8ToWide(artUri);
    if (!wArt.empty()) {
      try {
        std::wstring uri = wArt;
        if (wArt.rfind(L"http://", 0) != 0 && wArt.rfind(L"https://", 0) != 0 &&
            wArt.rfind(L"file:///", 0) != 0) {
          uri = L"file:///" + wArt;
        }
        updater.Thumbnail(RandomAccessStreamReference::CreateFromUri(
            Uri(hstring(uri))));
      } catch (...) {
                        
      }
    }
    updater.Update();
  } catch (...) {
  }
}

void SetSmtcStatus(bool playing) {
  if (!g_state.smtcReady) return;
  try {
    g_state.controls.PlaybackStatus(
        playing ? MediaPlaybackStatus::Playing : MediaPlaybackStatus::Paused);
  } catch (...) {
  }
}

void SetSmtcTimeline(int64_t positionMs, int64_t durationMs) {
  if (!g_state.smtcReady) return;
  try {
    SystemMediaTransportControlsTimelineProperties props;
    props.StartTime(TicksFromMs(0));
    props.MinSeekTime(TicksFromMs(0));
    props.Position(TicksFromMs(positionMs));
    if (durationMs > 0) {
      props.EndTime(TicksFromMs(durationMs));
      props.MaxSeekTime(TicksFromMs(durationMs));
    }
    g_state.controls.UpdateTimelineProperties(props);
  } catch (...) {
  }
}

                             
void DispatchAction(const char* action) {
  if (g_state.onAction && action) g_state.onAction(action);
}

}              

                                   
bool Init(HWND main_hwnd, std::function<void(const std::string&)> on_action) {
  if (!main_hwnd) return false;
  g_state.hwnd = main_hwnd;
  g_state.onAction = std::move(on_action);

  Gdiplus::GdiplusStartupInput input;
  if (Gdiplus::GdiplusStartup(&g_state.gdiplusToken, &input, nullptr) ==
      Gdiplus::Ok) {
    CreateAllIcons();
  }
  EnsureTaskbar();
  return true;
}

void Shutdown() {
                                        
  g_state.buttonRevoker = {};
  g_state.controls = nullptr;
  g_state.smtcReady = false;
  g_state.active = false;
  if (g_state.taskbar) {
    g_state.taskbar->Release();
    g_state.taskbar = nullptr;
  }
  g_state.thumbbarAdded = false;
  DestroyAllIcons();
  if (g_state.gdiplusToken) {
    Gdiplus::GdiplusShutdown(g_state.gdiplusToken);
    g_state.gdiplusToken = 0;
  }
  g_state.onAction = nullptr;
  g_state.hwnd = nullptr;
}

void Activate(const std::string& title, const std::string& artist,
              const std::string& art_uri, bool playing, int64_t position_ms,
              int64_t duration_ms) {
  EnsureSmtc();
  g_state.active = true;
  g_state.playing = playing;
  SetSmtcMetadata(title, artist, art_uri);
  SetSmtcStatus(playing);
  SetSmtcTimeline(position_ms, duration_ms);
  EnsureTaskbar();
  ApplyThumbbar(true);
}

void UpdateMetadata(const std::string& title, const std::string& artist,
                    const std::string& art_uri) {
  if (!g_state.active) return;
  SetSmtcMetadata(title, artist, art_uri);
}

void UpdatePlaybackState(bool playing) {
  if (!g_state.active) return;
  g_state.playing = playing;
  SetSmtcStatus(playing);
                                 
  ApplyThumbbar(true);
}

void UpdatePosition(int64_t position_ms, int64_t duration_ms) {
  if (!g_state.active) return;
  SetSmtcTimeline(position_ms, duration_ms);
}

void Deactivate() {
  g_state.active = false;
  if (g_state.smtcReady) {
    try {
      auto updater = g_state.controls.DisplayUpdater();
      updater.ClearAll();
      updater.Update();
      g_state.controls.PlaybackStatus(MediaPlaybackStatus::Closed);
    } catch (...) {
    }
  }
  ApplyThumbbar(false);
}

bool HandleWindowMessage(HWND         , UINT message, WPARAM wparam,
                         LPARAM lparam) {
  if (message == kMsgSmtcButton) {
    DispatchAction(reinterpret_cast<const char*>(lparam));
    return true;
  }
  if (message == WM_COMMAND && HIWORD(wparam) == THBN_CLICKED) {
    const int id = LOWORD(wparam);
    if (id >= kThumbFirst && id <= kThumbLast) {
      switch (id) {
        case kThumbPrev:
          DispatchAction(kActionPrevious);
          break;
        case kThumbRewind:
          DispatchAction(kActionRewind);
          break;
        case kThumbPlayPause:
          DispatchAction(kActionPlayPause);
          break;
        case kThumbFastForward:
          DispatchAction(kActionFastForward);
          break;
        case kThumbNext:
          DispatchAction(kActionNext);
          break;
      }
      return true;
    }
  }
  return false;
}

}                   
