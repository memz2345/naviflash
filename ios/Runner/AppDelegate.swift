import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let actionChannelName = "com.memz2345.navi.flash/action"
  private var actionChannel: FlutterMethodChannel?
  private var pendingShortcutActions: [String] = []
  private var launchedByShortcut = false

  /// 快捷项 type → 应用内统一动作串（与 Windows JumpList 一致）
  private static func actionValue(for shortcutType: String) -> String? {
    switch shortcutType {
    case "com.memz2345.navi.flash.action.search": return "search"
    case "com.memz2345.navi.flash.action.offline": return "offline"
    case "com.memz2345.navi.flash.action.recommend": return "recommend"
    default: return nil
    }
  }

  /// 动态注册桌面长按快捷入口（标题随系统语言）
  private func setupShortcutItems() {
    let isZh = Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") ?? false
    func makeItem(_ type: String, _ zh: String, _ en: String, _ icon: String) -> UIApplicationShortcutItem {
      let uiIcon: UIApplicationShortcutIcon?
      if #available(iOS 13.0, *) {
        uiIcon = UIApplicationShortcutIcon(systemImageName: icon)
      } else {
        uiIcon = nil
      }
      return UIApplicationShortcutItem(
        type: type,
        localizedTitle: isZh ? zh : en,
        localizedSubtitle: nil,
        icon: uiIcon,
        userInfo: nil
      )
    }
    UIApplication.shared.shortcutItems = [
      makeItem("com.memz2345.navi.flash.action.search", "搜索", "Search", "magnifyingglass"),
      makeItem("com.memz2345.navi.flash.action.offline", "离线视频", "Offline videos", "arrow.down.circle"),
      makeItem("com.memz2345.navi.flash.action.recommend", "推荐", "Recommend", "play.circle"),
    ]
  }

  /// 把暂存的动作通过通道推给 Dart（仅用于应用已在运行的「热启动」场景；
  /// 冷启动动作必须保留在队列里，等 Dart 注册后经 consumePendingAction 取回）
  private func flushPendingActionsToFlutter() {
    guard let channel = actionChannel, !pendingShortcutActions.isEmpty else { return }
    for action in pendingShortcutActions {
      channel.invokeMethod("onAction", arguments: action)
    }
    pendingShortcutActions.removeAll()
  }

  private func enqueueShortcut(_ shortcutItem: UIApplicationShortcutItem) {
    guard let action = AppDelegate.actionValue(for: shortcutItem.type) else { return }
    pendingShortcutActions.append(action)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let superResult = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // 桌面长按快捷入口（动态注册）
    setupShortcutItems()

    // 冷启动由快捷项拉起：先暂存动作，等 Dart 注册后消费
    if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
      launchedByShortcut = true
      enqueueShortcut(shortcutItem)
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      // 动作通道：Dart → 原生 consumePendingAction；原生 → Dart onAction
      let channel = FlutterMethodChannel(
        name: actionChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      actionChannel = channel
      channel.setMethodCallHandler { [weak self] call, result in
        if call.method == "consumePendingAction" {
          let action: String? =
            (self?.pendingShortcutActions.isEmpty == false)
            ? self!.pendingShortcutActions.removeFirst()
            : nil
          result(action)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      // 存储空间通道：iOS FileManager 真实磁盘总/可用（需在 super 之后 window 已创建）
      let storageChannel = FlutterMethodChannel(
        name: "com.memz2345.navi.flash/storage",
        binaryMessenger: controller.binaryMessenger
      )
      storageChannel.setMethodCallHandler { call, result in
        if call.method == "getStorageInfo" {
          do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let total = (attrs[.systemSize] as? NSNumber)?.int64Value ?? 0
            let free = (attrs[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
            let used = total > free ? total - free : 0
            result([
              "totalBytes": total,
              "freeBytes": free,
              "usedBytes": used,
            ])
          } catch {
            result(FlutterError(code: "STORAGE_ERROR", message: error.localizedDescription, details: nil))
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      // 设备屏幕圆角通道：iOS 风格页面切换的新页面圆角贴合屏幕实际圆角。
      // 与 Android 侧同名同协议（见 DeviceCornerChannel.kt）。
      let cornerChannel = FlutterMethodChannel(
        name: "com.memz2345.navi.flash/device_corners",
        binaryMessenger: controller.binaryMessenger
      )
      cornerChannel.setMethodCallHandler { call, result in
        if call.method == "getCornerRadius" {
          let (radius, source) = DeviceCornerRadius.detect()
          result(["radiusDp": radius, "source": source])
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return superResult
  }

  override func performAction(
    for shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    // 冷启动由快捷项拉起时，didFinishLaunching 已暂存过该动作，
    // iOS 在应用激活后仍会调用本方法一次 → 去重跳过
    if launchedByShortcut {
      launchedByShortcut = false
      completionHandler(false)
      return
    }
    // 热启动：应用已在运行，直接入队并推送（Dart 已注册 handler）
    enqueueShortcut(shortcutItem)
    flushPendingActionsToFlutter()
    completionHandler(true)
  }
}

/// 设备**物理屏幕**四角的圆角半径探测（iOS 侧）。
///
/// iOS 没有公开 API 能读到屏幕圆角；业界通行做法是 KVC 取 `UIScreen` 的私有
/// 属性 `_displayCornerRadius`（单位 pt，与 Flutter 的逻辑像素一致）。
/// 取不到（属性被移除 / 未来系统改名）就返回 0，Dart 侧会回退到用户手动值，
/// 不会出现「比现在还差」的结果。
///
/// ⚠️ 私有属性仅读取、不写入。上架 App Store 存在被判私有 API 的风险；
/// 本项目的 iOS 侧主要用于自行构建，如需规避可把本方法直接返回 0。
enum DeviceCornerRadius {
  private static let kDisplayCornerRadiusKey = "_displayCornerRadius"

  static func detect() -> (radius: Double, source: String) {
    guard let value = displayCornerRadius(), value > 0 else {
      return (0, "none")
    }
    return (value, "displayCornerRadius")
  }

  private static func displayCornerRadius() -> Double? {
    let screen = UIScreen.main
    let selector = NSSelectorFromString(kDisplayCornerRadiusKey)
    // 先确认 getter 存在，再走 KVC —— 属性缺失时 value(forKey:) 会抛
    // ObjC 异常（Swift 接不住，直接崩），responds(to:) 是必须的前置检查。
    guard screen.responds(to: selector) else { return nil }
    guard let number = screen.value(forKey: kDisplayCornerRadiusKey) as? NSNumber else {
      return nil
    }
    let radius = number.doubleValue
    return radius > 0 ? radius : nil
  }
}
