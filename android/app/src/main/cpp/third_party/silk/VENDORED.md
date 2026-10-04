# Vendored: SILK SDK (fixed-point) via kn007/silk-v3-decoder

来源：https://github.com/kn007/silk-v3-decoder
抓取时间：2026-09-15（master，tree sha `507be6bcae`）

## 内容

- `interface/`、`src/` 原样保留（Skype SILK SDK 定点版，BSD 三条款风格许可，
  版权头在每个源文件内；仓库根 LICENSE-kn007.txt 是 kn007 的 MIT 打包许可）。
- **未包含** `src/*_arm.S`（22 个老式 ARM32 汇编，上游 Makefile 仅在
  TOOLCHAIN_PREFIX 交叉编译时编入；C 版本自足，arm64/x86_64 也无法汇编）。
- **未包含** `test/Encoder.c` / `test/Decoder.c` 命令行程序；编码行为由
  上层 `../../ttsexport.c` 复刻（参数、容器格式逐行对照 Encoder.c）。

## 与上游的差异

- 容器格式（`#!SILK_V3`、每包 int16 LE 长度、`-tencent` 的 0x02 头与
  无 0xFFFF 尾包）在 `ttsexport.c` 实现，语义与 test/Encoder.c 完全一致。
- 上游测试程序丢弃最后不足 20ms 的尾帧；wrapper 改为补零编码，避免短句
  丢失结尾。
- 默认参数照抄：Fs_API=24000、maxInternal=24000、20ms/包、25000bps、
  complexity=2、FEC/DTX 关。

构建见上层 `../../CMakeLists.txt`（全量 `src/*.c`，`-w -O2`，gc-sections
裁剪未引用的解码代码）。
