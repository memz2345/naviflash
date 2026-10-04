# android/app/src/main/cpp/CMakeLists.txt
#
# TTS 导出原生库 libttsexport.so：
#   - silk：kn007/silk-v3-decoder 内的 Skype SILK SDK 定点版（.c 全量，
#     不编老式 *_arm.S；纯 C 版本自足），含微信/QQ -tencent 容器格式；
#   - lame：LAME 3.100 libmp3lame 编码子集（无 mpglib、无 SIMD/汇编）。
# 仅 C，无 STL 依赖。
cmake_minimum_required(VERSION 3.22)
project(ttsexport LANGUAGES C)

set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_C_STANDARD 99)

# ---------------------------------------------------------------------------
# SILK（定点版，与上游 Makefile 一样编 src/*.c 全集，链接器 gc-sections 裁剪）
# ---------------------------------------------------------------------------
file(GLOB SILK_SOURCES CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/third_party/silk/src/*.c")

add_library(silk STATIC ${SILK_SOURCES})
target_include_directories(silk PUBLIC
     "${CMAKE_CURRENT_SOURCE_DIR}/third_party/silk/interface"
     "${CMAKE_CURRENT_SOURCE_DIR}/third_party/silk/src")
# NO_ASM：不编 *_arm.S（老式 ARM32 汇编，arm64/x86 无法汇编），强制用
# AsmPreproc.h 的 C 回退；否则 armv7 下 EMBEDDED_ARM>=6 会把部分 C 函数
# 条件编译掉，链接报 undefined symbol。
target_compile_definitions(silk PRIVATE NO_ASM)
# 三方历史代码：静默其告警，只开优化与分段。
target_compile_options(silk PRIVATE
     -O2 -w -ffunction-sections -fdata-sections)

# ---------------------------------------------------------------------------
# LAME（仅编码 18 个 .c；config.h 由我们提供）
# ---------------------------------------------------------------------------
set(LAME_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/lame")
set(LAME_SOURCES
    ${LAME_DIR}/libmp3lame/bitstream.c
    ${LAME_DIR}/libmp3lame/encoder.c
    ${LAME_DIR}/libmp3lame/fft.c
    ${LAME_DIR}/libmp3lame/gain_analysis.c
    ${LAME_DIR}/libmp3lame/id3tag.c
    ${LAME_DIR}/libmp3lame/lame.c
    ${LAME_DIR}/libmp3lame/newmdct.c
    ${LAME_DIR}/libmp3lame/presets.c
    ${LAME_DIR}/libmp3lame/psymodel.c
    ${LAME_DIR}/libmp3lame/quantize.c
    ${LAME_DIR}/libmp3lame/quantize_pvt.c
    ${LAME_DIR}/libmp3lame/reservoir.c
    ${LAME_DIR}/libmp3lame/set_get.c
    ${LAME_DIR}/libmp3lame/tables.c
    # takehiro.c 是编码器的 Huffman 位计数/划分例程（count_bits 等），
    # 不是 mpglib 解码代码，quantize_pvt 依赖它。
    ${LAME_DIR}/libmp3lame/takehiro.c
    ${LAME_DIR}/libmp3lame/util.c
    ${LAME_DIR}/libmp3lame/vbrquantize.c
    ${LAME_DIR}/libmp3lame/VbrTag.c
    ${LAME_DIR}/libmp3lame/version.c)

add_library(lame STATIC ${LAME_SOURCES})
target_include_directories(lame PUBLIC
     ${LAME_DIR}/include-lame)
target_include_directories(lame PRIVATE
     ${LAME_DIR}/config
     ${LAME_DIR}/libmp3lame)
target_compile_definitions(lame PRIVATE HAVE_CONFIG_H)
# LAME 老代码有不少类型双关写法，关掉严格别名优化避免数值问题。
target_compile_options(lame PRIVATE
     -O2 -w -fno-strict-aliasing -ffunction-sections -fdata-sections)

# ---------------------------------------------------------------------------
# 导出共享库
# ---------------------------------------------------------------------------
add_library(ttsexport SHARED ttsexport.c)
target_link_libraries(ttsexport PRIVATE silk lame log m)
target_compile_options(ttsexport PRIVATE
     -O2 -Wall -ffunction-sections -fdata-sections)
# 不导出静态库里的任何符号，只留 tts_* 三个函数。
target_link_options(ttsexport PRIVATE
     -Wl,--gc-sections -Wl,--exclude-libs,ALL)
