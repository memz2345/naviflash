plugins {
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.10" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.10" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 部分老插件（如 video_thumbnail）把 compileSdk 写死在 33，而它们依赖的
// androidx（fragment 1.7+ / window 1.2+）要求 compileSdk >= 34 —— AGP 9 的
// AAR metadata 检查会直接让构建失败。这里给所有 Android 子项目统一抬到 37。
subprojects {
    // 必须在 afterEvaluate 里改：插件自己的 android {} 块是在评估阶段跑的，
    // 早于此时设置会被它覆盖。
    afterEvaluate {
        extensions.findByType(com.android.build.api.dsl.LibraryExtension::class.java)
            ?.let { ext ->
                if (ext.compileSdk == null || ext.compileSdk!! < 37) ext.compileSdk = 37
            }
        extensions.findByType(com.android.build.api.dsl.ApplicationExtension::class.java)
            ?.let { ext ->
                if (ext.compileSdk == null || ext.compileSdk!! < 37) ext.compileSdk = 37
            }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectDir: Directory = rootProject.layout.buildDirectory.dir(project.name).get()
    project.layout.buildDirectory.value(newSubprojectDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
