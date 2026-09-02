# NaviFlash

NaviFlash（`com.memz2345.navi.flash`）是基于 Navi v2（原仓库 `memz2345/navi`）裁剪出来的分支：

- 只保留 **B 站部分**（推荐 / 搜索 / 热门 / 番剧 / 分区 / 直播 / 视频播放器 / 弹幕 / 评论 / 稍后再看 / 缓存 / 观看历史 / 播放列表 / 本地收藏夹 / 云同步等）与 **WebDAV** 能力（账号、远程文件浏览、播放列表 / 弹幕 / 字幕云端同步）。
- **已移除局域网聊天部分**：设备连接与消息、语音通话（RTC）、一起看、远程控制（含 Shizuku 原生侧）、LocalSend、扫码/二维码配对、验证请求、Jump List 等。
- **已移除 Metro（Windows Phone 风格）组件**：磁贴开始屏幕、Charm 栏、Metro 锁屏/登录、m_* Metro 页面、图片切片器及其入口；页面交互按压缩放（`MetroTileInteraction`）等仍保留，与 Navi v2 一致。
- 主题、显示、平台通道与 Navi v2 保持一致；主页改为 **B 站推荐流**（窄屏直接为根页面，宽屏为侧边栏 Shell 的 home 区块）。
- **Windows 跳转列表（JumpList）**：「最近观看」显示最近观看的 5 条视频（可点击直达）；
  「任务」区固定为 搜索 / 离线视频 / 推荐。点击 JumpList 项时若已有实例在运行，
  会通过 WM_COPYDATA 把动作转发给现有实例**在当前窗口内跳转**（不另开进程），
  无运行实例时才冷启动直达对应页面。
- **Android / iOS 桌面长按菜单（App Shortcuts）**：搜索 / 离线视频 / 推荐 三个快捷入口，
  冷启动与热启动均可直达对应页面（动作协议与 Windows JumpList 一致）。
- Dart 包名：`naviflash`；Android 包名 / iOS·macOS bundle id / Windows AUMID / Linux application id：`com.memz2345.navi.flash`；应用显示名 **NaviFlash**。

## 构建

```sh
flutter pub get
flutter run          # 或 flutter build apk / build windows / ...
```

> 说明：iOS / macOS 工程配置已同步改名，但需在 macOS + Xcode 环境构建；
> Windows 可执行文件名仍为 `navi.exe`（CMake target 未改），如需可自行将
> `windows/runner` 目标改名为 `naviflash`。

## 目录

```
lib/main.dart         # 入口：主页 = B站推荐流（窄屏根页面 / 宽屏 SideBarShell）
lib/screens/          # B站页面与设置（accounts = B站 + WebDAV 账号）
lib/services/         # B站/WebDAV/播放/云同步等服务（无 chat 服务）
android/ios/macos/windows/linux/web   # 平台工程（包名已改 flash）
third_party/          # webview_windows（本地 path 依赖）等
```
