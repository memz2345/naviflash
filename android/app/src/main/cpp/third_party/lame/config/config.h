/* android/app/src/main/cpp/third_party/lame/config/config.h
 *
 * 最小化 autoconf config.h（替代 ./configure 生成的版本），面向
 * Android NDK bionic（arm64/armv7/x86_64，均为小端 IEEE754）。
 * 只保留 libmp3lame 编码子集实际检查的宏；不启用 NASM / SSE / NEON，
 * 全部走标量 C 路径。
 */
#ifndef LAME_TTS_CONFIG_H
#define LAME_TTS_CONFIG_H

#define PACKAGE "lame"
#define PACKAGE_NAME "LAME"
#define PACKAGE_VERSION "3.100"
#define VERSION "3.100"

#define STDC_HEADERS 1

#define HAVE_STDINT_H 1
#define HAVE_INTTYPES_H 1
#define HAVE_STDLIB_H 1
#define HAVE_STRING_H 1
#define HAVE_STRINGS_H 1
#define HAVE_MEMORY_H 1
#define HAVE_ERRNO_H 1
#define HAVE_FCNTL_H 1
#define HAVE_LIMITS_H 1
#define HAVE_MATH_H 1
#define HAVE_UNISTD_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TIME_H 1

#define HAVE_STRCHR 1
#define HAVE_MEMCPY 1
#define HAVE_GETTIMEOFDAY 1
#define HAVE_STRUCT_TIMEVAL 1

/* 小端目标：不定义 WORDS_BIGENDIAN */
/* 不定义 HAVE_XMMINTRIN_H / HAVE_NASM / HAVE_NEON：纯标量 C */

/* autoconf 模板 config.h.in 里自带的类型兜底 */
#ifndef HAVE_IEEE754_FLOAT32_T
typedef float ieee754_float32_t;
#endif
#ifndef HAVE_IEEE754_FLOAT64_T
typedef double ieee754_float64_t;
#endif
#ifndef HAVE_IEEE854_FLOAT80_T
typedef long double ieee854_float80_t;
#endif

#endif /* LAME_TTS_CONFIG_H */
