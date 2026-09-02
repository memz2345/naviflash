#ifndef RUNNER_SMTC_CONTROLS_H_
#define RUNNER_SMTC_CONTROLS_H_

#include <windows.h>

#include <cstdint>
#include <functional>
#include <string>

// Windows 系统媒体控件原生实现（供 Flutter 平台通道调用）：
//   1. SMTC（SystemMediaTransportControls）——Win10/11 控制中心 / 音量浮层 /
//      媒体键的媒体卡片（标题、作者、封面、进度、播放状态）。
//   2. 任务栏缩略图工具栏（ITaskbarList3 ThumbBar）——鼠标悬停任务栏按钮时
//      预览窗口下方的 5 个操作按钮：上一集 / 回退20s / 播放暂停 / 快进20s / 下一集。
//
// 线程约定：除 Shutdown 外，所有函数必须在平台线程（Flutter 主线程）调用；
// 按钮事件（SMTC 事件来自 WinRT 线程池）内部已通过窗口消息编组回平台线程，
// 因此 on_action 回调也保证在平台线程触发。
namespace smtc {

// 初始化。main_hwnd：顶层窗口句柄（任务栏按钮所属窗口，也是消息编组目标）。
// on_action：按钮事件回调，action 取值：
//   "play" / "pause" / "playPause" / "next" / "previous" / "rewind" / "fastForward"
bool Init(HWND main_hwnd, std::function<void(const std::string&)> on_action);

// 释放全部原生资源（平台线程，窗口销毁时调用）。
void Shutdown();

// 激活媒体会话：显示控制中心卡片 + 任务栏缩略图按钮，并写入初始状态。
void Activate(const std::string& title, const std::string& artist,
              const std::string& art_uri, bool playing,
              int64_t position_ms, int64_t duration_ms);

// 更新元数据（标题 / 作者 / 封面地址，art_uri 支持 http(s):// 或本地路径）。
void UpdateMetadata(const std::string& title, const std::string& artist,
                    const std::string& art_uri);

// 更新播放状态（控制中心 Playing/Paused + 任务栏播放/暂停图标互换）。
void UpdatePlaybackState(bool playing);

// 更新进度（控制中心媒体卡片时间轴）。
void UpdatePosition(int64_t position_ms, int64_t duration_ms);

// 注销会话：关闭控制中心卡片并隐藏任务栏缩略图按钮。
void Deactivate();

// 窗口消息拦截（在 FlutterWindow::MessageHandler 顶部调用）。
// 消费 SMTC 事件编组消息与任务栏按钮的 WM_COMMAND(THBN_CLICKED)。
// 返回 true 表示消息已消费，调用方应直接 return 0。
bool HandleWindowMessage(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

}  // namespace smtc

#endif  // RUNNER_SMTC_CONTROLS_H_
