# NaviFlash release 混淆/压缩规则（与 `flutter build apk --shrink` 同源）。
#
# 默认只启用 R8 自带规则；若 release 包出现插件反射类被裁剪
#（通常表现为启动闪退 + ClassNotFoundException），按报错类名在此追加：
#   -keep class com.example.Foo { *; }
#
# 注意：assets/（模型 / 着色器 / 字体）不受 shrinkResources 影响，
# R8 只处理 Java/Kotlin 代码与 res/ 资源。

# audio_service：通知/MediaSession 回调经 AndroidManifest 声明的 receiver 与
# 反射桥接（AudioServicePlugin ↔ Dart），R8 裁剪会表现为通知按钮无响应或
# 崩溃。官方文档要求整包 keep（https://pub.dev/packages/audio_service）。
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**
