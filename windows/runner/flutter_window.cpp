// windows/runner/flutter_window.cpp
#include "flutter_window.h"

#include <optional>

#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <vector>
#include <memory>
#include <string>

#include <windows.h>
#include <objbase.h>

// ✅ WIC 图片解码
#include <wincodec.h>
#include <shlwapi.h>
#pragma comment(lib, "windowscodecs.lib")
#pragma comment(lib, "shlwapi.lib")

// ✅ Jump List 相关
#include <shobjidl.h>
#include <propvarutil.h>
#include <shlobj.h>
#include <shellapi.h>
#include <propsys.h>
#include <gdiplus.h>
#include <propkey.h>
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "propsys.lib")

#include "flutter/generated_plugin_registrant.h"

// ✅ SMTC（控制中心媒体控件）+ 任务栏缩略图工具栏
#include "smtc_controls.h"

// ✅ TaskDialog（播放器统计信息原生对话框，依赖 ComCtl32 v6）
#include <commctrl.h>
#pragma comment(lib, "comctl32.lib")

// ================= 全局状态管理 =================
static flutter::BinaryMessenger* g_messenger = nullptr;
static HWND g_hwnd = nullptr;
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_clipboard_channel;
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_jumplist_channel;
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_stats_channel;
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_smtc_channel;
static std::string g_pending_flash_action;   // JumpList 点击启动的动作（--flash-action=…）

// ✅ 剪贴板自定义格式（与浏览器 / 微信 / QQ / Discord 等一致的 PNG 格式）
static UINT g_cfPng = 0;
static UINT g_cfImagePng = 0;

// ✅ AppUserModelID 常量（全局统一，避免拼写不一致）
static const wchar_t* kAppUserModelID = L"com.memz2345.navi.flash";

// ================= 工具函数 =================
static std::wstring Utf8ToWide(const std::string& s) {
    if (s.empty()) return {};
    int len = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, NULL, 0);
    if (len <= 0) return {};
    std::wstring ws(len - 1, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, &ws[0], len);
    return ws;
}

static std::string WideToUtf8(const std::wstring& ws) {
    if (ws.empty()) return {};
    int len = WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), -1, NULL, 0, NULL, NULL);
    if (len <= 0) return {};
    std::string s(len - 1, '\0');
    WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), -1, &s[0], len, NULL, NULL);
    return s;
}

// ================= 剪贴板读取 =================
std::vector<uint8_t> GetClipboardImageBytes(HWND hwnd) {
    if (!OpenClipboard(hwnd)) return {};
    std::vector<uint8_t> result;

    // 1) 优先读取自定义 PNG 格式（浏览器 / 主流 IM 复制图片时都放 PNG）
    if (g_cfPng && IsClipboardFormatAvailable(g_cfPng)) {
        HANDLE hData = GetClipboardData(g_cfPng);
        if (hData) {
            LPVOID pGlobal = GlobalLock(hData);
            SIZE_T size = GlobalSize(hData);
            if (pGlobal && size > 0) {
                result.assign(static_cast<BYTE*>(pGlobal),
                              static_cast<BYTE*>(pGlobal) + size);
            }
            GlobalUnlock(hData);
        }
        if (!result.empty()) { CloseClipboard(); return result; }
    }

    // 2) DIB / DIBV5 → 包装成 BMP 文件
    if (IsClipboardFormatAvailable(CF_DIB)) {
        HANDLE hData = GetClipboardData(CF_DIB);
        if (hData) {
            LPVOID pGlobal = GlobalLock(hData);
            if (pGlobal) {
                SIZE_T size = GlobalSize(hData);
                if (size > 0) {
                    BITMAPINFOHEADER* bih = static_cast<BITMAPINFOHEADER*>(pGlobal);
                    BITMAPFILEHEADER bfh = {0};
                    bfh.bfType = 0x4D42;
                    bfh.bfSize = static_cast<DWORD>(size + sizeof(BITMAPFILEHEADER));
                    bfh.bfOffBits = sizeof(BITMAPFILEHEADER) + bih->biSize;
                    result.resize(sizeof(BITMAPFILEHEADER) + size);
                    memcpy(result.data(), &bfh, sizeof(BITMAPFILEHEADER));
                    memcpy(result.data() + sizeof(BITMAPFILEHEADER), pGlobal, size);
                }
                GlobalUnlock(hData);
            }
        }
        if (!result.empty()) { CloseClipboard(); return result; }
    }

    // 3) CF_BITMAP → 通过 GetDIBits 转为 DIB 并包装成 BMP 文件
    if (IsClipboardFormatAvailable(CF_BITMAP)) {
        HBITMAP hbmp = static_cast<HBITMAP>(GetClipboardData(CF_BITMAP));
        if (hbmp) {
            BITMAP bm = {};
            if (GetObject(hbmp, sizeof(bm), &bm) && bm.bmWidth > 0 && bm.bmHeight > 0) {
                BITMAPINFOHEADER bih = {};
                bih.biSize = sizeof(BITMAPINFOHEADER);
                bih.biWidth = bm.bmWidth;
                bih.biHeight = bm.bmHeight;
                bih.biPlanes = 1;
                bih.biBitCount = 32;
                bih.biCompression = BI_RGB;
                bih.biSizeImage = static_cast<DWORD>(bm.bmWidth * bm.bmHeight * 4);
                std::vector<BYTE> dib(sizeof(BITMAPINFOHEADER) + bih.biSizeImage);
                HDC hdc = GetDC(NULL);
                int got = GetDIBits(hdc, hbmp, 0, bm.bmHeight,
                                    dib.data() + sizeof(BITMAPINFOHEADER),
                                    reinterpret_cast<BITMAPINFO*>(&bih), DIB_RGB_COLORS);
                ReleaseDC(NULL, hdc);
                if (got > 0) {
                    BITMAPFILEHEADER bfh = {0};
                    bfh.bfType = 0x4D42;
                    bfh.bfSize = static_cast<DWORD>(dib.size() + sizeof(BITMAPFILEHEADER));
                    bfh.bfOffBits = sizeof(BITMAPFILEHEADER) + bih.biSize;
                    result.resize(dib.size() + sizeof(BITMAPFILEHEADER));
                    memcpy(result.data(), &bfh, sizeof(BITMAPFILEHEADER));
                    memcpy(result.data() + sizeof(BITMAPFILEHEADER), dib.data(), dib.size());
                }
            }
        }
    }

    CloseClipboard();
    return result;
}

std::string GetClipboardText(HWND hwnd) {
    if (!OpenClipboard(hwnd)) return "";
    std::string result;
    if (IsClipboardFormatAvailable(CF_UNICODETEXT)) {
        HANDLE hData = GetClipboardData(CF_UNICODETEXT);
        if (hData) {
            LPCWSTR pwsz = static_cast<LPCWSTR>(GlobalLock(hData));
            if (pwsz) {
                int len = WideCharToMultiByte(CP_UTF8, 0, pwsz, -1, NULL, 0, NULL, NULL);
                if (len > 0) {
                    result.resize(len - 1);
                    WideCharToMultiByte(CP_UTF8, 0, pwsz, -1, &result[0], len, NULL, NULL);
                }
                GlobalUnlock(hData);
            }
        }
    }
    CloseClipboard();
    return result;
}

void SendClipboardToDart(const std::string& type, const flutter::EncodableValue& data) {
    if (!g_clipboard_channel) return;
    flutter::EncodableMap map;
    map[flutter::EncodableValue("type")] = flutter::EncodableValue(type);
    map[flutter::EncodableValue("data")] = data;
    g_clipboard_channel->InvokeMethod("onClipboardPasted",
        std::make_unique<flutter::EncodableValue>(map));
}

// ================= 剪贴板写入 (CF_PNG + CF_DIB + CF_DIBV5 + CF_BITMAP) =================
// 把已解码的 BGRA 像素编码为 PNG，返回 HGLOBAL（失败返回 NULL，调用者负责 GlobalFree）
static HGLOBAL EncodePngToGlobal(IWICImagingFactory* pFactory,
                                 IWICBitmapSource* pSource,
                                 UINT width, UINT height) {
    if (!pFactory || !pSource || width == 0 || height == 0) return NULL;

    IStream* pStream = NULL;
    if (FAILED(CreateStreamOnHGlobal(NULL, FALSE, &pStream))) return NULL;

    IWICBitmapEncoder* pEncoder = NULL;
    if (FAILED(pFactory->CreateEncoder(GUID_ContainerFormatPng, NULL, &pEncoder))) {
        pStream->Release();
        return NULL;
    }
    if (FAILED(pEncoder->Initialize(pStream, WICBitmapEncoderNoCache))) {
        pEncoder->Release();
        pStream->Release();
        return NULL;
    }
    IWICBitmapFrameEncode* pFrame = NULL;
    if (FAILED(pEncoder->CreateNewFrame(&pFrame, NULL))) {
        pEncoder->Release();
        pStream->Release();
        return NULL;
    }
    if (FAILED(pFrame->Initialize(NULL))) {
        pFrame->Release();
        pEncoder->Release();
        pStream->Release();
        return NULL;
    }
    pFrame->SetSize(width, height);
    WICPixelFormatGUID fmt = GUID_WICPixelFormat32bppBGRA;
    pFrame->SetPixelFormat(&fmt);
    pFrame->WriteSource(pSource, NULL);
    pFrame->Commit();
    pEncoder->Commit();
    pFrame->Release();
    pEncoder->Release();

    HGLOBAL hSrc = NULL;
    if (FAILED(GetHGlobalFromStream(pStream, &hSrc)) || !hSrc) {
        pStream->Release();
        return NULL;
    }

    SIZE_T size = GlobalSize(hSrc);
    HGLOBAL hClip = NULL;
    if (size > 0) {
        hClip = GlobalAlloc(GMEM_MOVEABLE, size);
        if (hClip) {
            LPVOID pDst = GlobalLock(hClip);
            LPVOID pSrc = GlobalLock(hSrc);
            if (pDst && pSrc) memcpy(pDst, pSrc, size);
            if (pSrc) GlobalUnlock(hSrc);
            if (pDst) GlobalUnlock(hClip);
            if (!pDst || !pSrc) { GlobalFree(hClip); hClip = NULL; }
        }
    }

    // 流以 FALSE 所有权创建：释放流不释放 hSrc，需手动释放
    pStream->Release();
    GlobalFree(hSrc);
    return hClip;
}

bool SetClipboardImageFromBytes(HWND hwnd, const std::vector<uint8_t>& bytes) {
    if (bytes.empty()) return false;

    HRESULT hrCom = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    // 只有 S_OK 表示本次真正初始化了 COM，才需要 CoUninitialize
    //（S_FALSE = 线程已初始化过；RPC_E_CHANGED_MODE = 已是 MTA，直接可用）
    bool needUninit = (hrCom == S_OK);

    IWICImagingFactory* pFactory = NULL;
    HRESULT hr = CoCreateInstance(CLSID_WICImagingFactory, NULL,
        CLSCTX_INPROC_SERVER, IID_IWICImagingFactory, (LPVOID*)&pFactory);
    if (FAILED(hr) || !pFactory) {
        if (needUninit) CoUninitialize();
        return false;
    }

    IStream* pStream = SHCreateMemStream(bytes.data(), static_cast<UINT>(bytes.size()));
    if (!pStream) {
        pFactory->Release();
        if (needUninit) CoUninitialize();
        return false;
    }

    IWICBitmapDecoder* pDecoder = NULL;
    hr = pFactory->CreateDecoderFromStream(pStream, NULL,
        WICDecodeMetadataCacheOnDemand, &pDecoder);
    if (FAILED(hr) || !pDecoder) {
        pStream->Release(); pFactory->Release();
        if (needUninit) CoUninitialize();
        return false;
    }

    IWICBitmapFrameDecode* pFrame = NULL;
    hr = pDecoder->GetFrame(0, &pFrame);
    if (FAILED(hr) || !pFrame) {
        pDecoder->Release(); pStream->Release(); pFactory->Release();
        if (needUninit) CoUninitialize();
        return false;
    }

    IWICBitmapSource* pConverted = NULL;
    WICPixelFormatGUID pixelFormat;
    pFrame->GetPixelFormat(&pixelFormat);
    if (pixelFormat != GUID_WICPixelFormat32bppBGRA) {
        hr = WICConvertBitmapSource(GUID_WICPixelFormat32bppBGRA, pFrame, &pConverted);
        if (FAILED(hr) || !pConverted) {
            pFrame->Release(); pDecoder->Release(); pStream->Release(); pFactory->Release();
            if (needUninit) CoUninitialize();
            return false;
        }
    } else {
        pConverted = pFrame;
        pConverted->AddRef();
    }

    UINT width = 0, height = 0;
    pConverted->GetSize(&width, &height);
    if (width == 0 || height == 0) {
        pConverted->Release(); pFrame->Release(); pDecoder->Release();
        pStream->Release(); pFactory->Release();
        if (needUninit) CoUninitialize();
        return false;
    }

    UINT stride = width * 4;
    UINT imageSize = stride * height;
    std::vector<BYTE> pixels(imageSize);
    hr = pConverted->CopyPixels(NULL, stride, imageSize, pixels.data());
    if (FAILED(hr)) {
        pConverted->Release(); pFrame->Release(); pDecoder->Release();
        pStream->Release(); pFactory->Release();
        if (needUninit) CoUninitialize();
        return false;
    }

    // ---------- 1) CF_DIB ----------
    HGLOBAL hGlobalDib = NULL;
    {
        HGLOBAL h = GlobalAlloc(GMEM_MOVEABLE, sizeof(BITMAPINFOHEADER) + imageSize);
        if (h) {
            LPVOID p = GlobalLock(h);
            if (p) {
                BITMAPINFOHEADER* bih = static_cast<BITMAPINFOHEADER*>(p);
                ZeroMemory(bih, sizeof(BITMAPINFOHEADER));
                bih->biSize = sizeof(BITMAPINFOHEADER);
                bih->biWidth = width;
                bih->biHeight = -static_cast<LONG>(height);
                bih->biPlanes = 1;
                bih->biBitCount = 32;
                bih->biCompression = BI_RGB;
                bih->biSizeImage = imageSize;
                memcpy(static_cast<BYTE*>(p) + sizeof(BITMAPINFOHEADER),
                       pixels.data(), imageSize);
                hGlobalDib = h;
            }
            GlobalUnlock(h);
            if (!hGlobalDib) GlobalFree(h);
        }
    }

    // ---------- 2) CF_DIBV5 ----------
    HGLOBAL hGlobalV5 = NULL;
    {
        HGLOBAL h = GlobalAlloc(GMEM_MOVEABLE, sizeof(BITMAPV5HEADER) + imageSize);
        if (h) {
            LPVOID p = GlobalLock(h);
            if (p) {
                BITMAPV5HEADER* biv5 = static_cast<BITMAPV5HEADER*>(p);
                ZeroMemory(biv5, sizeof(BITMAPV5HEADER));
                biv5->bV5Size = sizeof(BITMAPV5HEADER);
                biv5->bV5Width = width;
                biv5->bV5Height = -static_cast<LONG>(height);
                biv5->bV5Planes = 1;
                biv5->bV5BitCount = 32;
                biv5->bV5Compression = BI_RGB;
                biv5->bV5SizeImage = imageSize;
                biv5->bV5CSType = LCS_WINDOWS_COLOR_SPACE;
                memcpy(static_cast<BYTE*>(p) + sizeof(BITMAPV5HEADER),
                       pixels.data(), imageSize);
                hGlobalV5 = h;
            }
            GlobalUnlock(h);
            if (!hGlobalV5) GlobalFree(h);
        }
    }

    // ---------- 3) CF_BITMAP (GDI 兼容) ----------
    HBITMAP hbmp = NULL;
    {
        BITMAPINFO bi = {};
        bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
        bi.bmiHeader.biWidth = width;
        bi.bmiHeader.biHeight = -static_cast<LONG>(height);
        bi.bmiHeader.biPlanes = 1;
        bi.bmiHeader.biBitCount = 32;
        bi.bmiHeader.biCompression = BI_RGB;
        void* pBits = NULL;
        HBITMAP h = CreateDIBSection(NULL, &bi, DIB_RGB_COLORS, &pBits, NULL, 0);
        if (h && pBits) {
            memcpy(pBits, pixels.data(), imageSize);
            hbmp = h;
        } else if (h) {
            DeleteObject(h);
        }
    }

    // ---------- 4) CF_PNG (高质量、正确文件名) ----------
    HGLOBAL hPng = NULL;
    if (g_cfPng) hPng = EncodePngToGlobal(pFactory, pConverted, width, height);

    pConverted->Release(); pFrame->Release(); pDecoder->Release();
    pStream->Release(); pFactory->Release();

    if (!OpenClipboard(hwnd)) {
        if (hGlobalDib) GlobalFree(hGlobalDib);
        if (hGlobalV5) GlobalFree(hGlobalV5);
        if (hbmp) DeleteObject(hbmp);
        if (hPng) GlobalFree(hPng);
        if (needUninit) CoUninitialize();
        return false;
    }

    bool ok = false;
    if (EmptyClipboard()) {
        ok = true;
        if (hGlobalDib) {
            if (!SetClipboardData(CF_DIB, hGlobalDib)) { GlobalFree(hGlobalDib); hGlobalDib = NULL; }
        }
        if (hGlobalV5) {
            if (!SetClipboardData(CF_DIBV5, hGlobalV5)) { GlobalFree(hGlobalV5); hGlobalV5 = NULL; }
        }
        if (hbmp) {
            if (!SetClipboardData(CF_BITMAP, hbmp)) { DeleteObject(hbmp); hbmp = NULL; }
        }
        if (hPng) {
            // image/png 别名需要独立的一份拷贝（SetClipboardData 成功后剪贴板拥有句柄）
            if (g_cfImagePng) {
                SIZE_T sz = GlobalSize(hPng);
                HGLOBAL hPng2 = GlobalAlloc(GMEM_MOVEABLE, sz);
                if (hPng2) {
                    LPVOID p2 = GlobalLock(hPng2);
                    LPVOID p1 = GlobalLock(hPng);
                    if (p1 && p2) memcpy(p2, p1, sz);
                    if (p1) GlobalUnlock(hPng);
                    if (p2) GlobalUnlock(hPng2);
                    if (!SetClipboardData(g_cfImagePng, hPng2)) GlobalFree(hPng2);
                }
            }
            if (!SetClipboardData(g_cfPng, hPng)) { GlobalFree(hPng); hPng = NULL; }
        }
    }
    CloseClipboard();
    if (needUninit) CoUninitialize();
    return ok;
}

// ================= ✅ Jump List：构建（最近观看 + 固定任务） =================
// Dart → setJumpList([{name, action}…])：name=视频标题，action=video:<bvid>；
// 原生固定追加「任务」区：搜索(--flash-action=search)、离线视频(--flash-action=offline)、
// 推荐(--flash-action=recommend)。点击任一项后以新进程携带 --flash-action=… 启动，
// Dart 侧通过 consumeLaunchArgs() 取回并导航。
static const wchar_t* kRecentWatchedCategory = L"\x6700\x8fd1\x89c2\x770b";  // 最近观看

static IShellLinkW* MakeFlashShellLink(const std::wstring& exePath,
                                       const std::string& action,
                                       const std::wstring& title) {
    IShellLinkW* pLink = NULL;
    if (FAILED(CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER,
                                IID_IShellLinkW, (void**)&pLink)) || !pLink) {
        return NULL;
    }
    pLink->SetPath(exePath.c_str());

    std::wstring exeDir(exePath);
    size_t slash = exeDir.find_last_of(L"\\/");
    if (slash != std::wstring::npos) exeDir = exeDir.substr(0, slash);
    pLink->SetWorkingDirectory(exeDir.c_str());

    std::wstring args = L"--flash-action=" + Utf8ToWide(action);
    pLink->SetArguments(args.c_str());
    pLink->SetDescription(title.c_str());

    // 右键/跳转列表显示的标题 + 所属 AppID（必须与列表一致，否则不显示）
    IPropertyStore* pProps = NULL;
    if (SUCCEEDED(pLink->QueryInterface(IID_IPropertyStore, (void**)&pProps)) && pProps) {
        PROPVARIANT pvTitle;
        InitPropVariantFromString(title.c_str(), &pvTitle);
        pProps->SetValue(PKEY_Title, pvTitle);
        PropVariantClear(&pvTitle);

        PROPVARIANT pvAumid;
        InitPropVariantFromString(kAppUserModelID, &pvAumid);
        pProps->SetValue(PKEY_AppUserModel_ID, pvAumid);
        PropVariantClear(&pvAumid);

        pProps->Commit();
        pProps->Release();
    }
    return pLink;
}

static bool BuildFlashJumpList(const flutter::EncodableList& recents) {
    HRESULT hrCom = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
    bool needUninit = SUCCEEDED(hrCom);

    wchar_t exePath[MAX_PATH] = {};
    GetModuleFileNameW(NULL, exePath, MAX_PATH);

    ICustomDestinationList* pcdl = NULL;
    HRESULT hr = CoCreateInstance(CLSID_DestinationList, NULL, CLSCTX_INPROC_SERVER,
                                  IID_ICustomDestinationList, (void**)&pcdl);
    if (FAILED(hr) || !pcdl) {
        if (needUninit) CoUninitialize();
        return false;
    }
    pcdl->SetAppID(kAppUserModelID);

    UINT minSlots = 0;
    IObjectArray* pRemoved = NULL;
    hr = pcdl->BeginList(&minSlots, IID_IObjectArray, (void**)&pRemoved);
    if (FAILED(hr) || !pRemoved) {
        pcdl->Release();
        if (needUninit) CoUninitialize();
        return false;
    }

    // 用户手动移除过的项目（按启动参数匹配），不再加入
    std::vector<std::wstring> removedArgs;
    UINT removedCount = 0;
    pRemoved->GetCount(&removedCount);
    for (UINT ri = 0; ri < removedCount; ri++) {
        IUnknown* pUnk = NULL;
        if (SUCCEEDED(pRemoved->GetAt(ri, IID_IUnknown, (void**)&pUnk)) && pUnk) {
            IShellLinkW* pLink = NULL;
            if (SUCCEEDED(pUnk->QueryInterface(IID_IShellLinkW, (void**)&pLink)) && pLink) {
                wchar_t argsBuf[MAX_PATH] = {};
                pLink->GetArguments(argsBuf, MAX_PATH);
                if (argsBuf[0]) removedArgs.push_back(argsBuf);
                pLink->Release();
            }
            pUnk->Release();
        }
    }

    // —— 最近观看类别（最多 5 条，来自 Dart 下发的观看历史） ——
    IObjectCollection* pRecentCol = NULL;
    CoCreateInstance(CLSID_EnumerableObjectCollection, NULL, CLSCTX_INPROC_SERVER,
                     IID_IObjectCollection, (void**)&pRecentCol);
    int recentAdded = 0;
    if (pRecentCol) {
        for (size_t idx = 0; idx < recents.size() && recentAdded < 5; idx++) {
            const auto* map = std::get_if<flutter::EncodableMap>(&recents[idx]);
            if (!map) continue;
            auto getStr = [&](const char* key) -> std::string {
                auto it = map->find(flutter::EncodableValue(key));
                if (it != map->end()) {
                    if (auto* s = std::get_if<std::string>(&it->second)) return *s;
                }
                return "";
            };
            std::string action = getStr("action");
            std::string name = getStr("name");
            if (action.empty()) continue;
            if (name.empty()) name = action;
            std::wstring expectedArgs = L"--flash-action=" + Utf8ToWide(action);
            bool wasRemoved = false;
            for (const auto& ra : removedArgs) {
                if (ra == expectedArgs) { wasRemoved = true; break; }
            }
            if (wasRemoved) continue;

            IShellLinkW* pLink = MakeFlashShellLink(exePath, action, Utf8ToWide(name));
            if (!pLink) continue;
            pRecentCol->AddObject(pLink);
            pLink->Release();
            recentAdded++;
        }
        if (recentAdded > 0) {
            hr = pcdl->AppendCategory(kRecentWatchedCategory, pRecentCol);
            if (FAILED(hr)) {
                OutputDebugStringW(L"[JumpList] ⚠️ 最近观看类别添加失败\n");
            }
        }
        pRecentCol->Release();
    }

    // —— 任务区（固定三项，始终显示在跳转列表顶部） ——
    {
        IObjectCollection* pTaskCol = NULL;
        CoCreateInstance(CLSID_EnumerableObjectCollection, NULL, CLSCTX_INPROC_SERVER,
                         IID_IObjectCollection, (void**)&pTaskCol);
        if (pTaskCol) {
            struct TaskSpec { const wchar_t* title; const char* action; };
            static const TaskSpec tasks[] = {
                { L"\x641c\x7d22", "search" },             // 搜索
                { L"\x79bb\x7ebf\x89c6\x9891", "offline" },  // 离线视频
                { L"\x63a8\x8350", "recommend" },            // 推荐
            };
            for (const auto& t : tasks) {
                IShellLinkW* pLink = MakeFlashShellLink(exePath, t.action, t.title);
                if (pLink) {
                    pTaskCol->AddObject(pLink);
                    pLink->Release();
                }
            }
            hr = pcdl->AddUserTasks(pTaskCol);
            pTaskCol->Release();
            if (FAILED(hr)) {
                OutputDebugStringW(L"[JumpList] ⚠️ AddUserTasks 失败\n");
            }
        }
    }

    hr = pcdl->CommitList();
    bool success = SUCCEEDED(hr);
    if (!success) {
        OutputDebugStringW(L"[JumpList] ❌ CommitList 失败\n");
        pcdl->AbortList();
    } else {
        OutputDebugStringW(L"[JumpList] ✅ CommitList OK\n");
    }

    pRemoved->Release();
    pcdl->Release();
    if (needUninit) CoUninitialize();
    return success;
}
// ================= ✅ Jump List：解析启动命令行 =================
static std::string ParseFlashActionArg() {
    LPWSTR cmdLine = GetCommandLineW();
    int argc = 0;
    LPWSTR* argv = CommandLineToArgvW(cmdLine, &argc);
    std::string result;
    if (argv) {
        for (int i = 1; i < argc; i++) {
            std::wstring arg(argv[i]);
            const std::wstring prefix = L"--flash-action=";
            if (arg.find(prefix) == 0) {
                result = WideToUtf8(arg.substr(prefix.length()));
                break;
            }
        }
        LocalFree(argv);
    }
    return result;
}

// ================= Flutter Window 生命周期 =================
FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

// ================= ✅ 播放器统计信息：原生 TaskDialog（实时刷新 + 复制 + 关闭） =================
// Dart 侧通过 com.memz2345.navi.flash/stats_dialog 通信：
//   - showStats(title, entries)：弹出对话框（entries 作为首屏内容即时显示）
//   - getStats()：原生定时回调，Dart 返回最新 List<List<String>> 用于实时刷新内容
// 对话框提供「复制(&C)」按钮（写入剪贴板）与「关闭」按钮 + 标题栏关闭(X)，
// 标题固定为 "Player"（更符合平台逻辑；原 OSD 浮层在 Windows 不渲染）。
static const UINT_PTR kStatsTimerId = 9528;
static const DWORD kStatsRefreshMs = 500;
static DWORD g_stats_last_tick = 0;
static std::wstring g_stats_last_content;

// 将 entries（List<List<String>>）拼成多行 "label: value" 文本
static std::wstring BuildStatsContent(const flutter::EncodableList& entries) {
    std::wstring content;
    bool first = true;
    for (const auto& entry : entries) {
        const auto* pair = std::get_if<flutter::EncodableList>(&entry);
        if (!pair || pair->size() < 2) continue;
        std::wstring label, value;
        if (auto* l = std::get_if<std::string>(&(*pair)[0])) label = Utf8ToWide(*l);
        if (auto* v = std::get_if<std::string>(&(*pair)[1])) value = Utf8ToWide(*v);
        if (!first) content += L"\n";
        first = false;
        content += label + L": " + value;
    }
    if (content.empty()) content = L"\uff08\u65e0\u6570\u636e\uff09";  // （无数据）
    return content;
}

// 异步向 Dart 拉取最新统计。InvokeMethod 无同步返回值（返回 void），
// 结果只能通过 MethodResult 回调拿；回复同样派发在平台线程（即
// TaskDialogIndirect 模态消息循环所在线程），因此回调里可直接更新 UI。
// 失败 / 未实现 / 超时则保留旧内容。
static HWND g_stats_dlg_hwnd = nullptr;
static bool g_stats_fetch_pending = false;
static DWORD g_stats_fetch_sent_tick = 0;

static void RequestStatsUpdate(flutter::MethodChannel<flutter::EncodableValue>* channel) {
    if (!channel || !g_stats_dlg_hwnd) return;
    if (g_stats_fetch_pending) return;  // 上一轮请求尚未回复
    g_stats_fetch_pending = true;
    g_stats_fetch_sent_tick = GetTickCount();

    channel->InvokeMethod(
        "getStats", nullptr,
        std::make_unique<flutter::MethodResultFunctions<flutter::EncodableValue>>(
            [](const flutter::EncodableValue* result) {
                g_stats_fetch_pending = false;
                if (!result) return;
                const auto* list = std::get_if<flutter::EncodableList>(result);
                if (!list) return;
                g_stats_last_content = BuildStatsContent(*list);
                if (g_stats_dlg_hwnd) {
                    SendMessage(g_stats_dlg_hwnd, TDM_SET_ELEMENT_TEXT, TDE_CONTENT,
                                reinterpret_cast<LPARAM>(g_stats_last_content.c_str()));
                }
            },
            [](const std::string&, const std::string&, const flutter::EncodableValue*) {
                g_stats_fetch_pending = false;  // 出错：保留旧内容
            },
            []() {
                g_stats_fetch_pending = false;  // Dart 未注册 handler：保留旧内容
            }));
}

// 把文本写入系统剪贴板（CF_UNICODETEXT）
static void CopyStatsToClipboard(const std::wstring& text) {
    if (text.empty()) return;
    if (!OpenClipboard(g_hwnd)) return;
    EmptyClipboard();
    const SIZE_T bytes = (text.size() + 1) * sizeof(wchar_t);
    HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, bytes);
    if (hMem) {
        LPVOID p = GlobalLock(hMem);
        if (p) {
            memcpy(p, text.c_str(), bytes);
            GlobalUnlock(hMem);
            if (!SetClipboardData(CF_UNICODETEXT, hMem)) {
                GlobalFree(hMem);
            }
        } else {
            GlobalFree(hMem);
        }
    }
    CloseClipboard();
}

static HRESULT CALLBACK StatsDialogCallback(HWND hwnd, UINT uNotification,
                                            WPARAM wParam, LPARAM /*lParam*/,
                                            LONG_PTR dwRefData) {
    auto* channel = reinterpret_cast<flutter::MethodChannel<flutter::EncodableValue>*>(dwRefData);
    switch (uNotification) {
        case TDN_CREATED:
            g_stats_dlg_hwnd = hwnd;
            g_stats_fetch_pending = false;
            g_stats_last_tick = 0;
            SetTimer(hwnd, kStatsTimerId, kStatsRefreshMs, NULL);
            break;
        case TDN_TIMER: {
            DWORD now = static_cast<DWORD>(wParam);
            // 看门狗：Dart 长时间未回复（或 handler 已注销）时解除挂起，允许下一轮请求
            if (g_stats_fetch_pending &&
                GetTickCount() - g_stats_fetch_sent_tick >= 3 * kStatsRefreshMs) {
                g_stats_fetch_pending = false;
            }
            if (now - g_stats_last_tick >= kStatsRefreshMs) {
                g_stats_last_tick = now;
                RequestStatsUpdate(channel);  // 回复到达时由回调刷新内容
            }
            break;
        }
        case TDN_BUTTON_CLICKED: {
            int btn = static_cast<int>(wParam);
            if (btn == 100) {        // 复制(&C)
                CopyStatsToClipboard(g_stats_last_content);
                return S_FALSE;      // 不关闭对话框
            }
            return S_OK;             // 关闭按钮(101) / X(IDCANCEL) → 关闭
        }
        case TDN_DESTROYED:
            KillTimer(hwnd, kStatsTimerId);
            g_stats_dlg_hwnd = nullptr;       // 迟到的回复不再刷新 UI
            g_stats_fetch_pending = false;
            break;
        default:
            break;
    }
    return S_OK;
}

static void ShowStatsTaskDialog(const flutter::EncodableMap& args) {
    // ✅ 确保 ComCtl32 v6 已加载（TaskDialog 依赖此版本）
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_STANDARD_CLASSES };
    InitCommonControlsEx(&icc);

    // 首屏内容：优先用 Dart 传入的 entries 即时显示
    std::wstring initialContent = L"\uff08\u65e0\u6570\u636e\uff09";  // （无数据）
    auto itEntries = args.find(flutter::EncodableValue("entries"));
    if (itEntries != args.end()) {
        if (const auto* list = std::get_if<flutter::EncodableList>(&itEntries->second)) {
            initialContent = BuildStatsContent(*list);
        }
    }
    g_stats_last_content = initialContent;
    g_stats_last_tick = 0;

    TASKDIALOG_BUTTON buttons[2];
    buttons[0].nButtonID = 100;
    buttons[0].pszButtonText = L"\x590d\x5236(&C)";  // 复制(&C)
    buttons[1].nButtonID = 101;
    buttons[1].pszButtonText = L"\x5173\x95ed";       // 关闭

    TASKDIALOGCONFIG config = { sizeof(config) };
    config.hwndParent = g_hwnd;
    config.dwFlags = TDF_ALLOW_DIALOG_CANCELLATION | TDF_CALLBACK_TIMER | TDF_SIZE_TO_CONTENT;
    config.pszWindowTitle = L"Player";
    config.pszMainInstruction = L"\x7edf\x8ba1\x4fe1\x606f";  // 统计信息
    config.pszContent = initialContent.c_str();
    config.pszMainIcon = TD_INFORMATION_ICON;
    config.pButtons = buttons;
    config.cButtons = 2;
    config.nDefaultButton = 101;
    config.pfCallback = StatsDialogCallback;
    config.lpCallbackData = reinterpret_cast<LONG_PTR>(g_stats_channel.get());

    int button = 0;
    TaskDialogIndirect(&config, &button, NULL, NULL);
}

// ================= ✅ SMTC（控制中心媒体控件）+ 任务栏缩略图工具栏 =================
// Dart 侧通过 com.memz2345.navi.flash/smtc 通信：
//   Dart → 原生：activate / updateMetadata / updatePlaybackState / updatePosition / deactivate
//   原生 → Dart：onButtonPressed {action}（SMTC 按钮与任务栏缩略图按钮统一走这里）
//   action ∈ play / pause / playPause / next / previous / rewind / fastForward
static void SendSmtcActionToDart(const std::string& action) {
    if (!g_smtc_channel || action.empty()) return;
    flutter::EncodableMap map;
    map[flutter::EncodableValue("action")] = flutter::EncodableValue(action);
    g_smtc_channel->InvokeMethod("onButtonPressed",
        std::make_unique<flutter::EncodableValue>(map));
}

static void HandleSmtcMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    auto getStr = [&](const char* key) -> std::string {
        if (!args) return "";
        auto it = args->find(flutter::EncodableValue(key));
        if (it != args->end()) {
            if (auto* s = std::get_if<std::string>(&it->second)) return *s;
        }
        return "";
    };
    auto getInt = [&](const char* key, int64_t fallback) -> int64_t {
        if (!args) return fallback;
        auto it = args->find(flutter::EncodableValue(key));
        if (it != args->end()) {
            if (auto* v = std::get_if<int64_t>(&it->second)) return *v;
            if (auto* v = std::get_if<int32_t>(&it->second)) return *v;
        }
        return fallback;
    };
    auto getBool = [&](const char* key, bool fallback) -> bool {
        if (!args) return fallback;
        auto it = args->find(flutter::EncodableValue(key));
        if (it != args->end()) {
            if (auto* v = std::get_if<bool>(&it->second)) return *v;
        }
        return fallback;
    };

    if (call.method_name() == "activate") {
        smtc::Activate(getStr("title"), getStr("artist"), getStr("artUri"),
                       getBool("playing", false),
                       getInt("positionMs", 0), getInt("durationMs", 0));
        result->Success(flutter::EncodableValue(true));
    } else if (call.method_name() == "updateMetadata") {
        smtc::UpdateMetadata(getStr("title"), getStr("artist"), getStr("artUri"));
        result->Success(flutter::EncodableValue(true));
    } else if (call.method_name() == "updatePlaybackState") {
        smtc::UpdatePlaybackState(getBool("playing", false));
        result->Success(flutter::EncodableValue(true));
    } else if (call.method_name() == "updatePosition") {
        smtc::UpdatePosition(getInt("positionMs", 0), getInt("durationMs", 0));
        result->Success(flutter::EncodableValue(true));
    } else if (call.method_name() == "deactivate") {
        smtc::Deactivate();
        result->Success(flutter::EncodableValue(true));
    } else {
        result->NotImplemented();
    }
}

bool FlutterWindow::OnCreate() {
    if (!Win32Window::OnCreate()) return false;

    // ===== ✅ 设置进程级 AppUserModelID =====
    SetCurrentProcessExplicitAppUserModelID(kAppUserModelID);

    RECT frame = GetClientArea();

    flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
        frame.right - frame.left, frame.bottom - frame.top, project_);
    if (!flutter_controller_->engine() || !flutter_controller_->view()) return false;

    RegisterPlugins(flutter_controller_->engine());

    SetChildContent(flutter_controller_->view()->GetNativeWindow());

    g_messenger = flutter_controller_->engine()->messenger();
    g_hwnd = flutter_controller_->view()->GetNativeWindow();

    // ===== ✅ 设置窗口级 AppUserModelID（双保险） =====
    // ===== ✅ 窗口级 AUMID：必须钉在【顶层窗口】上（任务栏按钮只认它） =====
    HWND topHwnd = GetHandle();   // Win32Window 的顶层 HWND（非 flutter 子窗口）

    auto setAumidOn = [](HWND h) {
        IPropertyStore* pps = nullptr;
        if (SUCCEEDED(SHGetPropertyStoreForWindow(h, IID_PPV_ARGS(&pps))) && pps) {
            PROPVARIANT pv;
            InitPropVariantFromString(kAppUserModelID, &pv);
            pps->SetValue(PKEY_AppUserModel_ID, pv);
            PropVariantClear(&pv);
            pps->Commit();        // 窗口 store 必须 Commit 才落地
            pps->Release();
        }
    };
    setAumidOn(topHwnd);                              // 关键
    if (g_hwnd && g_hwnd != topHwnd) setAumidOn(g_hwnd);  // 子窗口双保险

    // 🔬 读回 进程 / 顶层窗口 / 子窗口 三者实际 AUMID（定位关联问题的唯一办法）
    {
        wchar_t dbg[512];
        PWSTR pProc = nullptr;
        HRESULT hrP = GetCurrentProcessExplicitAppUserModelID(&pProc);
        if (SUCCEEDED(hrP) && pProc) {
            swprintf_s(dbg, L"[JumpList] 🔬 进程 AUMID = %s\n", pProc);
            OutputDebugStringW(dbg);
            CoTaskMemFree(pProc);
        } else {
            swprintf_s(dbg, L"[JumpList] 🔬 进程 AUMID = (none) hr=0x%08X\n", (unsigned)hrP);
            OutputDebugStringW(dbg);
        }
        auto readAumid = [&](HWND h, const wchar_t* label) {
            IPropertyStore* pps = nullptr;
            if (SUCCEEDED(SHGetPropertyStoreForWindow(h, IID_PPV_ARGS(&pps))) && pps) {
                PROPVARIANT pv; PropVariantInit(&pv);
                HRESULT hrG = pps->GetValue(PKEY_AppUserModel_ID, &pv);
                if (SUCCEEDED(hrG) && pv.vt == VT_LPWSTR && pv.pwszVal) {
                    swprintf_s(dbg, L"[JumpList] 🔬 %s AUMID = %s\n", label, pv.pwszVal);
                    OutputDebugStringW(dbg);
                } else {
                    swprintf_s(dbg, L"[JumpList] 🔬 %s AUMID = (none) vt=%d hr=0x%08X\n",
                        label, (int)pv.vt, (unsigned)hrG);
                    OutputDebugStringW(dbg);
                }
                PropVariantClear(&pv);
                pps->Release();
            }
        };
        readAumid(topHwnd, L"顶层窗口");
        if (g_hwnd && g_hwnd != topHwnd) readAumid(g_hwnd, L"子窗口");
    }

    // ========== 剪贴板 Channel ==========
    // ✅ 注册自定义 PNG 剪贴板格式（浏览器 / 微信 / QQ / Discord 等都优先读它，
    //    保证粘贴出的图片质量与文件名正确）
    g_cfPng = RegisterClipboardFormatW(L"PNG");
    g_cfImagePng = RegisterClipboardFormatW(L"image/png");

    g_clipboard_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        g_messenger, "com.memz2345.navi.flash/clipboard",
        &flutter::StandardMethodCodec::GetInstance());
    g_clipboard_channel->SetMethodCallHandler(
        [](const flutter::MethodCall<flutter::EncodableValue>& call,
           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
            if (call.method_name() == "getClipboardData") {
                auto imgBytes = GetClipboardImageBytes(g_hwnd);
                if (!imgBytes.empty()) {
                    flutter::EncodableMap map;
                    map[flutter::EncodableValue("type")] = flutter::EncodableValue("image");
                    map[flutter::EncodableValue("data")] = flutter::EncodableValue(std::move(imgBytes));
                    result->Success(map);
                    return;
                }
                std::string text = GetClipboardText(g_hwnd);
                if (!text.empty()) {
                    flutter::EncodableMap map;
                    map[flutter::EncodableValue("type")] = flutter::EncodableValue("text");
                    map[flutter::EncodableValue("data")] = flutter::EncodableValue(text);
                    result->Success(map);
                    return;
                }
                result->Success(flutter::EncodableValue());
            }
            else if (call.method_name() == "copyImage") {
                const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
                if (args) {
                    auto it = args->find(flutter::EncodableValue("data"));
                    if (it != args->end()) {
                        const auto* bytes = std::get_if<std::vector<uint8_t>>(&it->second);
                        if (bytes && !bytes->empty()) {
                            bool success = SetClipboardImageFromBytes(g_hwnd, *bytes);
                            result->Success(flutter::EncodableValue(success));
                            return;
                        }
                    }
                }
                result->Success(flutter::EncodableValue(false));
            }
            else {
                result->NotImplemented();
            }
        });

    // ========== ✅ Jump List Channel ==========
    g_jumplist_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        g_messenger, "com.memz2345.navi.flash/jumplist",
        &flutter::StandardMethodCodec::GetInstance());
    g_jumplist_channel->SetMethodCallHandler(
        [](const flutter::MethodCall<flutter::EncodableValue>& call,
           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
            if (call.method_name() == "setJumpList") {
                const auto* args = std::get_if<flutter::EncodableList>(call.arguments());
                bool ok = false;
                if (args) {
                    ok = BuildFlashJumpList(*args);
                } else {
                    OutputDebugStringW(L"[JumpList] ❌ setJumpList: arguments is not EncodableList\n");
                }
                result->Success(flutter::EncodableValue(ok));
            }
            else if (call.method_name() == "clearJumpList") {
                ICustomDestinationList* pcdl = NULL;
                HRESULT hr = CoCreateInstance(CLSID_DestinationList, NULL,
                    CLSCTX_INPROC_SERVER, IID_ICustomDestinationList, (void**)&pcdl);
                if (SUCCEEDED(hr) && pcdl) {
                    pcdl->SetAppID(kAppUserModelID);
                    pcdl->DeleteList(kAppUserModelID);
                    pcdl->Release();
                }
                result->Success(flutter::EncodableValue(true));
            }
            else if (call.method_name() == "consumeLaunchArgs") {
                // JumpList 点击启动的新进程：返回动作并清除，只消费一次
                flutter::EncodableMap payload;
                payload[flutter::EncodableValue("action")] =
                    flutter::EncodableValue(g_pending_flash_action);
                g_pending_flash_action.clear();
                result->Success(flutter::EncodableValue(payload));
            }
            else {
                result->NotImplemented();
            }
        });

    // ========== ✅ 播放器统计信息 TaskDialog Channel ==========
    g_stats_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        g_messenger, "com.memz2345.navi.flash/stats_dialog",
        &flutter::StandardMethodCodec::GetInstance());
    g_stats_channel->SetMethodCallHandler(
        [](const flutter::MethodCall<flutter::EncodableValue>& call,
           std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
            if (call.method_name() == "showStats") {
                if (const auto* args = std::get_if<flutter::EncodableMap>(call.arguments())) {
                    ShowStatsTaskDialog(*args);
                }
                result->Success(flutter::EncodableValue());
            } else {
                result->NotImplemented();
            }
        });

    // ========== ✅ SMTC（控制中心媒体控件）+ 任务栏缩略图工具栏 Channel ==========
    // 注意：SMTC / 缩略图按钮必须挂在【顶层窗口】上（任务栏按钮只认它），
    // 按钮事件经 WM_COMMAND(THBN_CLICKED) / PostMessage 编组回平台线程后
    // 统一由 SendSmtcActionToDart 转发到 Dart。
    g_smtc_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
        g_messenger, "com.memz2345.navi.flash/smtc",
        &flutter::StandardMethodCodec::GetInstance());
    g_smtc_channel->SetMethodCallHandler(HandleSmtcMethodCall);
    smtc::Init(topHwnd, SendSmtcActionToDart);

    // ========== ✅ 检测 Jump List 点击启动 ==========
    g_pending_flash_action = ParseFlashActionArg();

    flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });

    flutter_controller_->ForceRedraw();
    return true;
}

void FlutterWindow::OnDestroy() {
    // ✅ 先释放 SMTC（撤销事件订阅），再回收通道
    smtc::Shutdown();
    g_smtc_channel.reset();
    g_jumplist_channel.reset();
    g_clipboard_channel.reset();
    g_stats_channel.reset();
    g_messenger = nullptr;
    g_hwnd = nullptr;
    if (flutter_controller_) {
        flutter_controller_ = nullptr;
    }
    Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                                      WPARAM const wparam,
                                      LPARAM const lparam) noexcept {
    // ✅ SMTC / 任务栏缩略图工具栏按钮事件（平台线程，优先消费）
    if (smtc::HandleWindowMessage(hwnd, message, wparam, lparam)) {
        return 0;
    }

    // 剪贴板粘贴
    if (message == WM_PASTE) {
        auto imgBytes = GetClipboardImageBytes(hwnd);
        if (!imgBytes.empty()) {
            SendClipboardToDart("image", flutter::EncodableValue(std::move(imgBytes)));
            return 0;
        }
        std::string text = GetClipboardText(hwnd);
        if (!text.empty()) {
            SendClipboardToDart("text", flutter::EncodableValue(text));
            return 0;
        }
    }

    if (flutter_controller_) {
        std::optional<LRESULT> result =
            flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
        if (result) return *result;
    }

    switch (message) {
        // ✅ 单实例 JumpList 动作转发：main.cpp 把 --flash-action=… 用
        //   WM_COPYDATA 发到现有实例 → 推给 Dart 在当前窗口内跳转
        case WM_COPYDATA: {
            const COPYDATASTRUCT* pcds =
                reinterpret_cast<const COPYDATASTRUCT*>(lparam);
            if (pcds && pcds->dwData == 0x464C5348 && pcds->lpData &&
                pcds->cbData > 0) {
                std::string action(static_cast<const char*>(pcds->lpData),
                                   pcds->cbData);
                while (!action.empty() && action.back() == '\0') {
                    action.pop_back();
                }
                if (!action.empty()) {
                    g_pending_flash_action = action;
                    if (g_jumplist_channel) {
                        g_jumplist_channel->InvokeMethod(
                            "onAction",
                            std::make_unique<flutter::EncodableValue>(action));
                    }
                    return TRUE;
                }
            }
            break;
        }
        case WM_FONTCHANGE:
            flutter_controller_->engine()->ReloadSystemFonts();
            break;
    }

    return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}