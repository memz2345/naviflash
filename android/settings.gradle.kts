pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()  
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

// ── media_kit mpv 离线库 ──
// media_kit_libs_android_video 在配置阶段就用 JDK 原始 HTTPS 直连 github releases 下载
// mpv jar（不走 Windows 信任链），国内网络常 TLS 失败。这里在该插件项目被评估之前，
// 把 android/media_kit_libs 下的 jar（MD5 已校验）恢复到其构建目录，插件校验 MD5
// 匹配后即跳过下载。
gradle.beforeProject {
    if (name == "media_kit_libs_android_video") {
        val srcDir = File(rootDir, "media_kit_libs")
        val destDir = File(rootDir, "../build/media_kit_libs_android_video/v1.1.7")
        if (srcDir.isDirectory) {
            destDir.mkdirs()
            srcDir.listFiles { f -> f.isFile && f.extension == "jar" }?.forEach { f ->
                f.copyTo(File(destDir, f.name), overwrite = true)
            }
        }
    }
}

include(":app")
