/// GPU backend selection for runtime device preference.
enum GpuBackend {
  /// Automatically select the best available backend (recommended).
  auto,

  /// Force CPU-only inference (no GPU acceleration).
  cpu,

  /// Use Vulkan backend (cross-platform GPU support).
  vulkan,

  /// Use Apple Metal backend (macOS/iOS only).
  metal,

  /// Use CUDA backend (NVIDIA GPUs).
  cuda,

  /// Use BLAS backend (CPU acceleration).
  blas,

  /// Use OpenCL backend.
  opencl,

  /// Use HIP backend (AMD ROCm).
  hip,

  /// Use Qualcomm Hexagon NPU (HTP) backend via llama.cpp GGML_HEXAGON.
  ///
  /// Vendored patch: selects devices from the ggml backend registry named
  /// "HTP" (devices HTP0…). Only present in custom-built native bundles that
  /// ship libggml-hexagon.so + libggml-htp-v*.so skels.
  hexagon,
}
