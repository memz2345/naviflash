// android/app/src/main/cpp/ttsexport.h
//
// TTS 导出编码器对外 C API（Dart FFI 调用）。
//
// 两个 encode 函数均返回 malloc 的字节缓冲，Dart 拷贝后必须用
// [tts_free] 释放；失败返回 NULL 并向 err 写入 UTF-8 错误信息。
#ifndef TTS_EXPORT_H
#define TTS_EXPORT_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define TTS_EXPORT __attribute__((visibility("default")))

/// 把 16bit 单声道 PCM 编成 SILK v3（容器格式与 silk-v3-decoder 的
/// test/Encoder.c 完全一致）。
///
/// [tencent] != 0 即其 -tencent 模式（微信/QQ 兼容）：
///   文件头 = 0x02 + "#!SILK_V3"，结尾不写 0xFFFF 哨兵包；
/// [tencent] == 0 时无 0x02、结尾写 int16 -1。
/// [bitrate_bps] <= 0 用上游默认 25000bps；20ms/包，尾帧不足补零。
TTS_EXPORT uint8_t *tts_silk_encode(
    const int16_t *pcm,
    int32_t n_samples,
    int32_t sample_rate,
    int32_t tencent,
    int32_t bitrate_bps,
    int32_t *out_size,
    char *err,
    int32_t err_len);

/// 把 16bit 单声道 PCM 编成 MP3（LAME，mono / ABR 64kbps / 无 ID3）。
TTS_EXPORT uint8_t *tts_mp3_encode(
    const int16_t *pcm,
    int32_t n_samples,
    int32_t sample_rate,
    int32_t *out_size,
    char *err,
    int32_t err_len);

/// 释放 encode 函数返回的缓冲。
TTS_EXPORT void tts_free(void *p);

#ifdef __cplusplus
}
#endif

#endif // TTS_EXPORT_H
