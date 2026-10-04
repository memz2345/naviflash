cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "desktop_shell_channels.cpp"
  "find_replace_window.cpp"
  "task_dialog.cpp"
  "flutter_window.cpp"
  "main.cpp"
  "smtc_controls.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# ✅ SMTC：C++/WinRT 投影头在 /W4 下偶发噪音警告，此文件单独降为 /W3（不影响 /WX 对自写代码的把关级别）
set_source_files_properties("smtc_controls.cpp" PROPERTIES COMPILE_OPTIONS "/W3")

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# ── llamadart（AI 朗读的 llama.cpp 运行时）原生库部署 ─────────────────────────
#
# Flutter 的 native assets 会把库编到 build/native_assets/<os>/，但它写进
# flutter_assets/NativeAssetsManifest.json 的路径只是裸文件名
# （形如 ["absolute", "llama.dll"]），运行时按名字找不到，llama 后端会以
# loadedModules=[] 启动，加载模型必然失败（症状：朗读点下去直接报加载失败）。
# 这里在构建完成后把库拷到 exe 同目录，走 Windows 的 DLL 搜索顺序即可命中。
#
# 跳过 LiteRT-LM 后端的库：本项目只用 GGUF / llama.cpp 这一路，
# 那几个 dll 合计数十 MB，没必要跟着进包。
set(NAVI_NATIVE_ASSETS_DIR
    "${CMAKE_CURRENT_SOURCE_DIR}/../../build/native_assets/windows")
if(EXISTS "${NAVI_NATIVE_ASSETS_DIR}")
  file(GLOB NAVI_NATIVE_DLLS "${NAVI_NATIVE_ASSETS_DIR}/*.dll")
  set(NAVI_DEPLOYED 0)
  foreach(NAVI_DLL ${NAVI_NATIVE_DLLS})
    get_filename_component(NAVI_DLL_NAME "${NAVI_DLL}" NAME)
    if(NAVI_DLL_NAME MATCHES "^(LiteRt|libLiteRt|libwebgpu|libGemma)")
      continue()
    endif()
    add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
              "${NAVI_DLL}" "$<TARGET_FILE_DIR:${BINARY_NAME}>"
      COMMENT "部署 AI 朗读运行时 ${NAVI_DLL_NAME}")
    math(EXPR NAVI_DEPLOYED "${NAVI_DEPLOYED} + 1")
  endforeach()
  if(NAVI_DEPLOYED EQUAL 0)
    message(WARNING
      "navi: ${NAVI_NATIVE_ASSETS_DIR} 下没找到可部署的库，"
      "先跑一次 flutter build/run 让 native assets 编译完再重新构建。")
  else()
    message(STATUS "navi: 将部署 ${NAVI_DEPLOYED} 个 AI 朗读运行时库")
  endif()
else()
  message(STATUS
    "navi: 未找到 ${NAVI_NATIVE_ASSETS_DIR}，跳过 AI 朗读运行时部署")
endif()
