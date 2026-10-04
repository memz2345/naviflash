# Vendored: onnxruntime_v2 (pure-Dart fork)

- **Upstream**: https://github.com/Persie0/onnxruntime_flutter_1_22_0
- **Version**: 1.23.2+2
- **License**: MIT（见 `LICENSE`，版权归 gtbluesky）
- **Vendored at**: `third_party/onnxruntime`

## 为什么要 fork

上游包通过 `flutter: plugin:` + `ffiPlugin: true` 把 ONNX Runtime 原生库
在**编译期**打进产物：

| 平台 | 载体 | 体积 |
|---|---|---|
| Windows | `windows/onnxruntime.dll`（CMake `bundled_libraries`） | 12.4 MB |
| Linux | `linux/libonnxruntime.so.1.22.0` | 21 MB |
| macOS | `macos/libonnxruntime.1.21.0.dylib` | 67 MB |
| Android | Gradle `com.microsoft.onnxruntime:onnxruntime-android` AAR | 每 ABI 数 MB |

「弹幕智能防遮挡」只是个可选功能，却让所有用户都背上这份体积。

## 改了什么

1. **删掉 plugin 声明**：`pubspec.yaml` 里不写 `flutter: plugin:`，
   只保留纯 Dart + `dart:ffi`。因此不会有任何原生库被打进产物。
2. **`lib/src/bindings/bindings.dart`**：上游把动态库路径写死成
   `DynamicLibrary.open('onnxruntime.dll')` 等平台默认名。改成
   `OrtLibrary.path` 可外部赋值（宿主 app 传入下载目录里的库文件绝对路径），
   并把 `_dylib` / `onnxRuntimeBinding` 从顶层 final 改成惰性缓存，
   便于卸载后重新加载。
3. 其余 `lib/` 内容（OrtEnv / OrtSession / OrtValue / ffigen 生成的
   `OrtApi` 结构体）**原样保留**，未做逻辑改动。

## 运行时契约

宿主必须在**任何** OrtEnv / OrtSession 调用之前设置：

```dart
OrtLibrary.path = '/path/to/onnxruntime.dll'; // 或 .so / .dylib
```

之后 `OrtEnv.instance.init()`、`OrtSession.fromBuffer(...)` 的用法与上游
完全一致。

上层 FFI 只需要动态库导出一个符号 `OrtGetApiBase`，其余全部走 OrtApi
函数指针表，所以换路径不会破坏任何调用。
