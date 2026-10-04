plugins {
    id("com.android.application")
    id("kotlin-android")
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.10"
    id("dev.flutter.flutter-gradle-plugin")
}

kotlin {
    // Kotlin 2.4 起 kotlinOptions 已移除，统一走 compilerOptions DSL
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
    }
}

android {
    namespace = "com.memz2345.navi.flash"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        compose = true
    }

    // 高通 Hexagon NPU：libggml-htp-v*.so skel 由 FastRPC 在运行时从
    // nativeLibraryDir 直接 dlopen，若 .so 以未解压方式留在 APK 内
    // （AGP 新默认），QNN/Hexagon 后端会静默加载失败。强制解压安装。
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    // TTS 导出编码器（libttsexport.so：SILK v3 + LAME MP3，纯 C）。
    // 随 abiFilters 自动为 armv7/arm64/x86_64（debug）或 arm64（release）构建。
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    defaultConfig {
        applicationId = "com.memz2345.navi.flash"
        // 显式写死：原来 manifest 里就是 24，避免随 Flutter 默认值漂移
        minSdk = 24
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 注意：ABI 策略按 buildType 分开配（见下方 buildTypes），
        // defaultConfig 里不锁 abiFilters。
        // 需配合 android/gradle.properties 里的 disable-abi-filtering=true，
        // 否则 Flutter 插件会在配置后期清空 abiFilters 填回全量 ABI。

        multiDexEnabled = true

        externalNativeBuild {
            cmake {
                // 纯 C 工程，不需要 C++ STL
                arguments += listOf("-DANDROID_STL=none")
            }
        }
    }

    buildTypes {
        debug {
            // AVD/真机联调：全架构（x86_64 模拟器可装），不压缩。
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
            }
        }
        release {
            // 正式包：arm64 单 ABI 最小体积（与打包脚本的
            // --target-platform=android-arm64 对齐）。
            ndk {
                abiFilters += "arm64-v8a"
            }
            // 默认开启自带压缩（R8 代码压缩 + 混淆 + res 资源收缩），
            // 以后裸 `flutter build apk`（默认即 release）也是这套；
            // Dart 层混淆见 tool/build-apk.ps1。
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // 2026.09.00 = Compose 1.12.1：backdrop（液态玻璃库）要求 androidx
    // compose 1.12，Kotlin 2.4.10 配套
    val composeBom = platform("androidx.compose:compose-bom:2026.09.00")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.9.3")
    // 液态玻璃（Kyant0/AndroidLiquidGlass）：真折射 / 模糊 / 高光的
    // Compose 效果库，原生底栏直接用它的 drawBackdrop
    implementation("io.github.kyant0:backdrop:2.0.1")
    implementation("io.github.kyant0:shapes:1.2.1")

    // StatsDialogHost：ComposeView 宿主需要显式装 ViewTree 生命周期三件套
    // （FlutterActivity 不是 ComponentActivity，视图树上没有），用到的
    // setViewTree*Owner 扩展来自这三个工件（版本与 activity-compose 栈一致）。
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
    implementation("androidx.savedstate:savedstate-ktx:1.2.1")
    debugImplementation("androidx.compose.ui:ui-tooling")
}

flutter {
    source = "../.."
}
