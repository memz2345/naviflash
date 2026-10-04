import 'dart:ffi';
import 'dart:io';
import 'package:onnxruntime_v2/src/bindings/onnxruntime_bindings_generated.dart';

// ── 上游改动点（vendored fork）──────────────────────────────────────────
//
// 上游把动态库路径写死成平台默认名（'onnxruntime.dll' 等），库由 flutter
// plugin 在编译期打进产物。本 fork 去掉了 plugin 声明，改为由宿主 app 传入
// 下载目录里的库文件绝对路径（OrtLibrary.path），实现「按需下载 / 可卸载」。
//
// 上层 FFI 只依赖动态库导出的一个符号 OrtGetApiBase，其余全部走 OrtApi
// 函数指针表，因此换路径不影响任何调用。

/// ONNX Runtime 原生库的加载入口。
///
/// 注意：本包按 Dart 2.17 语言版本解析（为了兼容 ffigen 生成的没有
/// base/final 修饰的 ffi.Struct 子类），因此这里**不能**用 `abstract final
/// class` 这类 Dart 3 语法，改成私有构造 + 全静态成员。
class OrtLibrary {
  OrtLibrary._();

  /// 宿主 app 指定的库文件绝对路径。必须在任何 OrtEnv / OrtSession 调用
  /// 之前赋值；为 null 时回退到上游的平台默认名（保持兼容）。
  static String? path;

  static DynamicLibrary? _dylib;
  static OnnxRuntimeBindings? _bindings;

  /// 当前使用的动态库（惰性打开 + 缓存）。
  static DynamicLibrary get dylib => _dylib ??= _open();

  static DynamicLibrary _open() {
    final p = path;
    if (p != null && p.isNotEmpty) {
      return DynamicLibrary.open(p);
    }
    // 回退：上游行为（库由 plugin 随包打进 exe 同目录）
    if (Platform.isAndroid) return DynamicLibrary.open('libonnxruntime.so');
    if (Platform.isIOS) return DynamicLibrary.process();
    if (Platform.isMacOS) {
      return DynamicLibrary.open('libonnxruntime.1.21.0.dylib');
    }
    if (Platform.isWindows) return DynamicLibrary.open('onnxruntime.dll');
    if (Platform.isLinux) return DynamicLibrary.open('libonnxruntime.so.1.22.0');
    throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
  }

  /// 丢弃已缓存的动态库与绑定（卸载 / 重装依赖后调用）。
  static void reset() {
    _bindings = null;
    _dylib = null;
  }
}

/// OnnxRuntime Bindings
OnnxRuntimeBindings get onnxRuntimeBinding =>
    OrtLibrary._bindings ??= OnnxRuntimeBindings(OrtLibrary.dylib);
