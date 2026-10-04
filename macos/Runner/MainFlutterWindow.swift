import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 存储空间通道：macOS FileManager 真实磁盘总/可用
    let storageChannel = FlutterMethodChannel(
      name: "com.memz2345.navi.flash/storage",
      binaryMessenger: flutterViewController.engine.binaryMessenger
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

    super.awakeFromNib()
  }
}
