# Vendored: LAME 3.100 (encoder subset)

来源：LAME 3.100 官方发行 tarball（`lame_3.100.orig.tar.gz`，
经 http://deb.debian.org/debian/pool/main/l/lame/ 获取，与 sourceforge
官方包同源）。

许可证：LGPL-2.1（见 `COPYING.LGPL`），另见 `LICENSE.txt` 的商用说明。

## 内容

- `libmp3lame/`：仅保留编码所需 19 个 .c + 全部内部 .h，以及
  `vector/lame_intrin.h`（SSE 函数声明，仅在 HAVE_XMMINTRIN_H 下被引用，
  我们不启用，纯标量 C 路径）。
- **未包含** `mpglib_interface.c`（MP3 解码）、
  `vector/xmm_quantize_sub.c`（x86 SIMD）、`i386/`、`vector/` 里的 .c。
  注意 `takehiro.c` 虽然名字像解码器，实际是编码器的 Huffman 位计数
  （count_bits/best_huffman_divide…），quantize_pvt 依赖它，必须编入。
- `include-lame/lame.h`：公开 API 头（上游 `include/lame.h`）。
- `config/config.h`：替代 autoconf 生成的 config.h（Android bionic/小端，
  不启用 NASM/SSE/NEON）。

## 参数

mono / 输入采样率透传（Qwen3-TTS 为 24kHz，LAME 输出 MPEG-2 Layer III）/
ABR 64kbps / quality 5 / 不写 ID3 与 VBR Info 标签。封装见
`../../ttsexport.c`，构建见 `../../CMakeLists.txt`。
