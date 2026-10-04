# llamadart（vendored，含 Hexagon NPU 补丁）

来源：`llamadart` 0.8.23（pub），仅复制 `lib/`、`hook/`、`pubspec.yaml`、LICENSE、CHANGELOG。
对应原生运行时：leehack/llamadart-native **v0.4.0**（llama.cpp commit `5266f24`）。

## 为什么 vendor

Qwen3-TTS 要上高通 Hexagon NPU（HTP），需要：

1. 用高通 Snapdragon toolchain 容器（`GGML_HEXAGON=ON`）自编译
   `native/llamadart-native` 的 android-arm64 产物（libggml-hexagon.so +
   libggml-htp-v73/75/79/81.so skel），经 pubspec `hooks.user_defines`
   的 `llamadart_native_path` 本地覆写打进包；
2. Dart 层能按名选择 ggml 后端注册表 **"HTP"**——上游枚举没有该档位。

故在本副本做最小补丁，上游若原生支持 Hexagon 设备选择即可整体删除回退 pub 版。

## 补丁清单（搜索 `Vendored patch` 可定位）

- `lib/src/core/models/config/gpu_backend.dart`
  - `GpuBackend` 增加 `hexagon`。
- `lib/src/backends/llama_cpp/llama_cpp_service.dart`
  - Android 上 `auto→cpu` 的保守降级不再吞掉显式 `hexagon` 请求；
  - `hexagon` 经 ggml 注册表名 `HTP` 枚举设备（HTP0…）；
  - 加载后端模块时同时装载 cpu + hexagon；
  - HTP 设备枚举为空（非高通 / FastRPC 不可用 / skel 被拒）时强制回退 CPU，
    不会落到 Vulkan 或裸 auto；
  - 后端名展示识别 hexagon/htp 标记。
- `lib/src/backends/litert_lm/litert_lm_service.dart`
- `lib/src/backends/litert_lm/litert_lm_backend_web.dart`
  - 仅为穷举 switch 补 case（LiteRT-LM/Web 路径不会收到 hexagon）。

## 升级上游版本时

1. 重新从 pub 复制 0.8.x 对应文件；
2. 重新应用上述 4 处补丁；
3. 同步在 `native/llamacpp-native` 切新 tag 重编原生库；
4. Apple 侧仍由 `llamadart_llama_cpp_flutter` 0.0.18+ SwiftPM 伴侣提供，
   本补丁只影响 GGUF/llama.cpp 路径。
