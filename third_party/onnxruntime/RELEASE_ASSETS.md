# 需要上传到 Release 的附件清单

内置默认下载源（`kDefaultOnnxBaseUrl`，见
`lib/services/onnx_dependency_service.dart`）：

```
https://github.com/memz2345/naviflash/releases/download/onnx-v1/<文件名>
```

在仓库里发一个 tag 为 `onnx-v1` 的 Release，把下面这些文件作为附件传上去。
**必须是解压后的单个文件**，不能传 zip / tgz —— 客户端不做解包。

| 文件名 | 体积 | 用途 | 从哪拿 |
|---|---|---|---|
| `u2netp.onnx` | 4.5 MB | 弹幕智能防遮挡模型（U²-Netp，Apache-2.0） | 仓库里现成的 `assets/models/u2netp.onnx` |
| `onnxruntime.dll` | 12.4 MB | Windows x64 | 官方 `onnxruntime-win-x64-1.22.0.zip` 里的 `lib/onnxruntime.dll` |
| `libonnxruntime.so.1.22.0` | 21 MB | Linux x64 | 官方 `onnxruntime-linux-x64-1.22.0.tgz` 里的 `lib/libonnxruntime.so.1.22.0` |
| `libonnxruntime.1.22.0.dylib` | ~55 MB | macOS（universal2，arm64+x86_64 合一） | 官方 `onnxruntime-osx-universal2-1.22.0.tgz` 里的 `lib/libonnxruntime.1.22.0.dylib` |
| `libonnxruntime_arm64-v8a.so` | ~10 MB | 安卓 arm64 | Maven AAR `onnxruntime-android-1.23.2.aar` → `jni/arm64-v8a/libonnxruntime.so` |
| `libonnxruntime_armeabi-v7a.so` | ~7 MB | 安卓 32 位 ARM（可选） | 同上 `jni/armeabi-v7a/` |
| `libonnxruntime_x86_64.so` | ~12 MB | 安卓 x86_64（可选） | 同上 `jni/x86_64/` |
| `libonnxruntime_x86.so` | ~8 MB | 安卓 x86（可选） | 同上 `jni/x86/` |

官方下载地址（已验证可用）：

```
https://github.com/microsoft/onnxruntime/releases/download/v1.22.0/onnxruntime-win-x64-1.22.0.zip
https://github.com/microsoft/onnxruntime/releases/download/v1.22.0/onnxruntime-linux-x64-1.22.0.tgz
https://github.com/microsoft/onnxruntime/releases/download/v1.22.0/onnxruntime-osx-universal2-1.22.0.tgz
https://repo1.maven.org/maven2/com/microsoft/onnxruntime/onnxruntime-android/1.23.2/onnxruntime-android-1.23.2.aar
```

AAR 就是个 zip，改名解压即可取 `jni/<abi>/libonnxruntime.so`。

## 换源

用户可在「设置 → 存储 → 智能防遮挡依赖 → 下载源」填自己的地址（会存进
SharedPreferences，键 `onnxDepBaseUrl`）。填的是**目录**，末尾有没有 `/`
都行，客户端会按 `<目录>/<文件名>` 拼。留空恢复内置默认源。

## 校验

客户端装完会做两件事，失败就删掉重来：

1. `DynamicLibrary.open()` 打开运行库（架构/位数不对会直接在这里挂）；
2. 模型与运行库文件大小都 >= 1MB。

没有做 sha256 校验——Release 附件本身走 HTTPS，够用了。
