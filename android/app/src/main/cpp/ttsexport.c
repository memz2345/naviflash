// android/app/src/main/cpp/ttsexport.c
//
// TTS 导出编码器：SILK v3（复刻 kn007/silk-v3-decoder 的 test/Encoder.c，
// 含 -tencent 微信/QQ 兼容模式）与 MP3（LAME 3.100）。
//
// 输入统一为 16bit 单声道 PCM（上层从缓存 WAV 解析得到，Qwen3-TTS 恒为
// 24kHz/mono/s16）。返回 malloc 缓冲，Dart 侧拷贝后调 tts_free。
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "ttsexport.h"
#include "SKP_Silk_SDK_API.h"
#include "lame.h"

// 这两个常量在上游 test/Encoder.c 里由测试程序自己定义（不属于 SDK 公开头），
// 数值照抄：MAX_BYTES_PER_FRAME=250（100kbps 峰值），每包最多 5 帧。
#ifndef TTS_SILK_MAX_BYTES_PER_FRAME
#define TTS_SILK_MAX_BYTES_PER_FRAME 250
#define TTS_SILK_MAX_INPUT_FRAMES 5
#endif
#define MAX_BYTES_PER_FRAME TTS_SILK_MAX_BYTES_PER_FRAME
#define MAX_INPUT_FRAMES TTS_SILK_MAX_INPUT_FRAMES

// ---------------------------------------------------------------------------
// 动态增长字节缓冲
// ---------------------------------------------------------------------------

typedef struct {
  uint8_t *p;
  int len;
  int cap;
} tts_buf;

static void tb_seterr(char *err, int err_len, const char *msg) {
  if (err == NULL || err_len <= 0) return;
  strncpy(err, msg, (size_t)err_len - 1);
  err[err_len - 1] = '\0';
}

#include <stdarg.h>
static void tb_fmterr(char *err, int err_len, const char *fmt, ...) {
  if (err == NULL || err_len <= 0) return;
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(err, (size_t)err_len, fmt, ap);
  va_end(ap);
  err[err_len - 1] = '\0';
}

static int tb_reserve(tts_buf *b, int extra) {
  int need = b->len + extra;
  if (need <= b->cap) return 0;
  int cap = b->cap ? b->cap : 4096;
  while (cap < need) {
    if (cap > (256 * 1024 * 1024)) return -1; // 单文件 >256MB 视为异常
    cap *= 2;
  }
  uint8_t *np = (uint8_t *)realloc(b->p, (size_t)cap);
  if (np == NULL) return -1;
  b->p = np;
  b->cap = cap;
  return 0;
}

static int tb_append(tts_buf *b, const void *data, int n) {
  if (n <= 0) return 0;
  if (tb_reserve(b, n) != 0) return -1;
  memcpy(b->p + b->len, data, (size_t)n);
  b->len += n;
  return 0;
}

static void tb_put_u8(tts_buf *b, uint8_t v) { (void)tb_append(b, &v, 1); }

// Android 全 ABI 均小端，直接 memcpy int16（与上游 Encoder.c 一致）。
static void tb_put_le16(tts_buf *b, int16_t v) {
  (void)tb_append(b, &v, 2);
}

// ---------------------------------------------------------------------------
// SILK v3
// ---------------------------------------------------------------------------

// 与 test/Encoder.c 相同的默认参数。
#define TTS_SILK_PACKET_MS 20
#define TTS_SILK_DEFAULT_RATE 25000

uint8_t *tts_silk_encode(
    const int16_t *pcm,
    int32_t n_samples,
    int32_t sample_rate,
    int32_t tencent,
    int32_t bitrate_bps,
    int32_t *out_size,
    char *err,
    int32_t err_len) {
  if (pcm == NULL || n_samples <= 0 || out_size == NULL) {
    tb_seterr(err, err_len, "bad arguments");
    return NULL;
  }
  // 上游 Encoder.c 接受 8000~48000；内部采样率取 min(API, 24000)。
  if (sample_rate < 8000 || sample_rate > 48000) {
    tb_seterr(err, err_len, "sample rate out of range (8000-48000)");
    return NULL;
  }
  if (bitrate_bps <= 0) bitrate_bps = TTS_SILK_DEFAULT_RATE;

  int32_t enc_size = 0;
  if (SKP_Silk_SDK_Get_Encoder_Size(&enc_size) != 0 || enc_size <= 0) {
    tb_seterr(err, err_len, "Get_Encoder_Size failed");
    return NULL;
  }
  void *enc = malloc((size_t)enc_size);
  if (enc == NULL) {
    tb_seterr(err, err_len, "malloc encoder state failed");
    return NULL;
  }

  SKP_SILK_SDK_EncControlStruct ctrl;
  SKP_SILK_SDK_EncControlStruct status;
  int ret = SKP_Silk_SDK_InitEncoder(enc, &status);
  if (ret != 0) {
    tb_fmterr(err, err_len, "InitEncoder failed: %d", ret);
    free(enc);
    return NULL;
  }

  const int32_t max_internal =
      sample_rate < 24000 ? sample_rate : 24000;
  ctrl.API_sampleRate = sample_rate;
  ctrl.maxInternalSampleRate = max_internal;
  ctrl.packetSize =
      (TTS_SILK_PACKET_MS * sample_rate) / 1000;
  ctrl.packetLossPercentage = 0;
  ctrl.useInBandFEC = 0;
  ctrl.useDTX = 0;
  ctrl.complexity = 2;
  ctrl.bitRate = bitrate_bps;

  const int frame_samples =
      (TTS_SILK_PACKET_MS * sample_rate) / 1000; // 20ms 采样数

  // test/Encoder.c 的 in/payload 容量（FRAME_LENGTH_MS * MAX_API_FS_KHZ *
  // MAX_INPUT_FRAMES），直接沿用其宏。
  int16_t *frame = (int16_t *)calloc((size_t)frame_samples, sizeof(int16_t));
  uint8_t *payload =
      (uint8_t *)malloc(MAX_BYTES_PER_FRAME * MAX_INPUT_FRAMES);
  if (frame == NULL || payload == NULL) {
    tb_seterr(err, err_len, "malloc frame buffer failed");
    free(frame);
    free(payload);
    free(enc);
    return NULL;
  }

  tts_buf out = {0};
  int ok = 1;

  // 头：tencent 模式先写 0x02（已字节级核对上游 Encoder.c 的
  // Tencent_break），随后统一是 "#!SILK_V3"。
  if (tencent) tb_put_u8(&out, 0x02);
  if (tb_append(&out, "#!SILK_V3", 9) != 0) {
    ok = 0;
    tb_seterr(err, err_len, "out of memory");
  }

  int32_t pos = 0;
  while (ok && pos < n_samples) {
    int32_t take = n_samples - pos;
    if (take > frame_samples) take = frame_samples;

    // 关键差异：test/Encoder.c 丢弃最后不足 20ms 的尾巴，TTS 短句（缓存命中
    // 的评论语音可能只有几百毫秒）不能丢尾——不足一帧补零，仍按整帧编码。
    memset(frame, 0, (size_t)frame_samples * sizeof(int16_t));
    memcpy(frame, pcm + pos, (size_t)take * sizeof(int16_t));

    int16_t n_bytes = MAX_BYTES_PER_FRAME * MAX_INPUT_FRAMES;
    ret = SKP_Silk_SDK_Encode(
        enc, &ctrl, frame, (SKP_int16)frame_samples, payload, &n_bytes);
    if (ret != 0) {
      tb_fmterr(err, err_len, "SDK_Encode failed: %d", ret);
      ok = 0;
      break;
    }
    tb_put_le16(&out, n_bytes);
    if (tb_append(&out, payload, n_bytes) != 0) {
      ok = 0;
      tb_seterr(err, err_len, "out of memory");
    }
    pos += take;
  }

  // 非 tencent 模式写 int16 -1 哨兵（文件不能以 0 长度包结束）。
  if (ok && !tencent) tb_put_le16(&out, (int16_t)-1);

  free(payload);
  free(frame);
  free(enc);

  if (!ok) {
    free(out.p);
    return NULL;
  }
  *out_size = out.len;
  return out.p;
}

// ---------------------------------------------------------------------------
// MP3（LAME）
// ---------------------------------------------------------------------------

uint8_t *tts_mp3_encode(
    const int16_t *pcm,
    int32_t n_samples,
    int32_t sample_rate,
    int32_t *out_size,
    char *err,
    int32_t err_len) {
  if (pcm == NULL || n_samples <= 0 || out_size == NULL) {
    tb_seterr(err, err_len, "bad arguments");
    return NULL;
  }
  if (sample_rate < 8000 || sample_rate > 48000) {
    tb_seterr(err, err_len, "sample rate out of range (8000-48000)");
    return NULL;
  }

  lame_global_flags *gf = lame_init();
  if (gf == NULL) {
    tb_seterr(err, err_len, "lame_init failed");
    return NULL;
  }
  lame_set_in_samplerate(gf, sample_rate);
  lame_set_num_channels(gf, 1);
  lame_set_mode(gf, MONO);
  // 语音：ABR 64kbps，质量档 5（0 最慢 9 最快），不写任何标签。
  lame_set_brate(gf, 64);
  lame_set_quality(gf, 5);
  lame_set_bWriteVbrTag(gf, 0);
  lame_set_write_id3tag_automatic(gf, 0);

  if (lame_init_params(gf) < 0) {
    tb_seterr(err, err_len, "lame_init_params failed");
    lame_close(gf);
    return NULL;
  }

  tts_buf out = {0};
  const int chunk = 8192;
  // LAME 要求输出缓冲 >= 1.25*nsamples + 7200。
  int mp3_cap = (int)(1.25 * chunk) + 7200;
  unsigned char *mp3buf = (unsigned char *)malloc((size_t)mp3_cap);
  if (mp3buf == NULL) {
    tb_seterr(err, err_len, "malloc mp3 buffer failed");
    lame_close(gf);
    return NULL;
  }

  int ok = 1;
  int32_t pos = 0;
  while (ok && pos < n_samples) {
    int32_t take = n_samples - pos;
    if (take > chunk) take = chunk;
    int n = lame_encode_buffer_interleaved(
        gf, (short int *)(pcm + pos), take, mp3buf, mp3_cap);
    if (n < 0) {
      tb_fmterr(err, err_len, "lame_encode failed: %d", n);
      ok = 0;
      break;
    }
    if (n > 0 && tb_append(&out, mp3buf, n) != 0) {
      ok = 0;
      tb_seterr(err, err_len, "out of memory");
    }
    pos += take;
  }

  if (ok) {
    int n = lame_encode_flush(gf, mp3buf, mp3_cap);
    if (n < 0) {
      tb_fmterr(err, err_len, "lame_flush failed: %d", n);
      ok = 0;
    } else if (n > 0 && tb_append(&out, mp3buf, n) != 0) {
      ok = 0;
      tb_seterr(err, err_len, "out of memory");
    }
  }

  free(mp3buf);
  lame_close(gf);

  if (!ok) {
    free(out.p);
    return NULL;
  }
  *out_size = out.len;
  return out.p;
}

void tts_free(void *p) { free(p); }
