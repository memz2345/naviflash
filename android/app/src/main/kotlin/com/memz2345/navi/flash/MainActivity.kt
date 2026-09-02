package com.memz2345.navi.flash

import android.app.AlertDialog
import android.app.LocaleManager
import android.app.PictureInPictureParams
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.LocaleList
import android.provider.OpenableColumns
import android.util.Rational
import android.view.WindowManager // ✅ 新增：用于控制系统亮度
import android.widget.Toast
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val TOAST_CHANNEL = "com.memz2345.navi.flash/toast"
    private val EXIT_CHANNEL = "com.memz2345.navi.flash/exit"
    private val MEDIA_SCAN_CHANNEL = "com.memz2345.navi.flash/media_scan"
    private val PIP_CHANNEL = "com.memz2345.navi.flash/pip"
    private val BRIGHTNESS_CHANNEL = "com.memz2345.navi.flash/brightness"
    private val EASTER_EGG_CHANNEL = "com.memz2345.navi.flash/easter_egg"
    private val OPEN_VIDEO_CHANNEL = "com.memz2345.navi.flash/open_video"
    private val LOCALE_CHANNEL = "com.memz2345.navi.flash/locale"
    private val STORAGE_CHANNEL = "com.memz2345.navi.flash/storage"
    private val ACTION_CHANNEL = "com.memz2345.navi.flash/action"
    private val ACTION_EXTRA = "flash_action"

    private var originalBrightness: Float? = null // ✅ 新增：记录进入播放器前的初始亮度

    // 桌面长按快捷入口（App Shortcuts）：冷启动暂存，Dart 就绪后消费
    private var actionChannel: MethodChannel? = null
    private var pendingShortcutAction: String? = null

    // ✅ Android 13+ 按应用设置语言：通道实例 + 上次已知的系统级应用语言标签，
    //    用于 onConfigurationChanged 里判断「应用语言」是否真的变化再推送 Dart
    private var localeChannel: MethodChannel? = null
    private var lastAppLocaleTags: Set<String> = emptySet()

    // ✅ 外部「打开方式」传入的视频 URI（冷启动时先暂存，Flutter 就绪后消费）
    private var pendingVideoUri: Uri? = null
    private var pendingVideoName: String? = null
    private var openVideoChannel: MethodChannel? = null
    private var flutterReady = false // Dart 侧已注册 handler 后才推送，避免消息丢失

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleVideoIntent(intent)
        handleShortcutIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleVideoIntent(intent)
        handleShortcutIntent(intent)
    }

    /// 桌面长按菜单（搜索 / 离线视频 / 推荐）点击后的动作下发
    private fun handleShortcutIntent(intent: Intent?) {
        val action = intent?.getStringExtra(ACTION_EXTRA) ?: return
        val channel = actionChannel
        if (channel == null || !flutterReady) {
            // 冷启动（或 Dart 尚未注册 handler）：先暂存，等 Dart 侧 consumePendingAction
            pendingShortcutAction = action
        } else {
            // 应用已在运行（热启动）：直接推送
            channel.invokeMethod("onAction", action, null)
        }
    }

    // ✅ Android 13+ 用户在「系统设置 → 应用信息 → 语言」改语言：
    //    MainActivity 在 manifest 里声明了自处理 locale 配置变更（不会重建），
    //    这里检测到应用语言变化后主动推送 Dart，驱动界面即时刷新。
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val tags = currentAppLocaleTags().toSet()
        if (tags == lastAppLocaleTags) return
        lastAppLocaleTags = tags
        localeChannel?.invokeMethod(
            "onAppLocalesChanged",
            mapOf("tags" to tags.toList())
        )
    }

    // ✅ 读取系统级「按应用设置语言」标签列表（如 ["zh-CN"]），空 = 跟随系统
    //    注意：android.os.LocaleList 未实现 Iterable，只能按下标遍历
    private fun currentAppLocaleTags(): List<String> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return emptyList()
        return try {
            val lm = getSystemService(LocaleManager::class.java) ?: return emptyList()
            val locales = lm.applicationLocales
            List(locales.size()) { locales.get(it).toLanguageTag() }
        } catch (_: Exception) {
            emptyList()
        }
    }

    // ✅ 处理外部 ACTION_VIEW 视频 intent：提取 URI 并暂存 / 推送
    private fun handleVideoIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        val scheme = uri.scheme ?: return
        if (!scheme.equals("content", true) && !scheme.equals("file", true)) return

        // 请求持久读取权限，保证后续读取流时授权仍然有效
        try {
            contentResolver.takePersistableUriPermission(
                uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (_: Exception) {}

        pendingVideoUri = uri
        pendingVideoName = queryDisplayName(uri)
        pushPendingVideoIfReady()
    }

    private fun pushPendingVideoIfReady() {
        val uri = pendingVideoUri ?: return
        val channel = openVideoChannel ?: return
        if (!flutterReady) return
        val result = prepareVideoUri(uri)
        if (result.first == null) return
        pendingVideoUri = null
        pendingVideoName = null
        channel.invokeMethod(
            "onVideoIntent",
            mapOf("path" to result.first, "name" to (result.second ?: ""))
        )
    }

    // ✅ 将 intent 的视频 URI 转成本地可播放路径（content:// 复制到缓存目录）
    private fun prepareVideoUri(uri: Uri): Pair<String?, String?> {
        val name = queryDisplayName(uri) ?: "外部视频"
        return try {
            if (uri.scheme.equals("file", true)) {
                Pair(uri.path, name)
            } else {
                val ext = name.substringAfterLast('.', "").ifBlank { "mp4" }
                val safeName = name.replace(Regex("[^a-zA-Z0-9._-]"), "_")
                val dir = File(cacheDir, "open_video")
                if (!dir.exists()) dir.mkdirs()
                val out = File(dir, "${System.currentTimeMillis()}_$safeName")
                val input = contentResolver.openInputStream(uri) ?: return null to null
                input.use { inp ->
                    out.outputStream().use { o -> inp.copyTo(o) }
                }
                Pair(out.absolutePath, name)
            }
        } catch (e: Exception) {
            null to null
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            contentResolver.query(
                uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null
            )?.use { c ->
                if (c.moveToFirst()) c.getString(0) else null
            }
        } catch (_: Exception) {
            null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Toast 通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TOAST_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showToast") {
                val message = call.argument<String>("message")
                if (message != null) {
                    showToast(message)
                    result.success(null)
                } else {
                    result.error("INVALID_ARG", "Message is null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // 2. 退出应用通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXIT_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "exitApp") {
                showExitConfirmationDialog()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // 3. 媒体扫描通道（用于保存图片后刷新相册）
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_SCAN_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                if (path != null && File(path).exists()) {
                    scanFile(path)
                    result.success(null)
                } else {
                    result.error("INVALID_PATH", "File path is invalid or null", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // 4. 画中画 (PiP) 通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enterPiP") {
                enterPiPMode()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // 5. ✅ 新增：亮度控制通道 (彻底替代 screen_brightness 插件)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRIGHTNESS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrightness" -> {
                    val lp = window.attributes
                    // 如果 < 0 说明是系统默认亮度，我们返回 0.5 作为基准
                    result.success(if (lp.screenBrightness < 0) 0.5 else lp.screenBrightness.toDouble())
                }
                "setBrightness" -> {
                    val brightness = (call.arguments as? Double)?.toFloat() ?: 0.5f
                    // 首次调节时记录初始亮度，以便退出时恢复
                    if (originalBrightness == null) {
                        originalBrightness = window.attributes.screenBrightness
                    }
                    val lp = window.attributes
                    lp.screenBrightness = brightness
                    window.attributes = lp
                    result.success(null)
                }
                "resetBrightness" -> {
                    val lp = window.attributes
                    // 退出播放器时恢复系统亮度
                    lp.screenBrightness = originalBrightness ?: WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    window.attributes = lp
                    originalBrightness = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 6. 彩蛋 Activity 通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EASTER_EGG_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openEasterEgg") {
                val intent = Intent(this@MainActivity, EasterEggActivity::class.java)
                startActivity(intent)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // 8. ✅ 外部「打开方式」播放视频通道
        openVideoChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OPEN_VIDEO_CHANNEL)
        openVideoChannel!!.setMethodCallHandler { call, result ->
            flutterReady = true // 能收到调用说明 Dart 侧已注册 handler
            when (call.method) {
                "consumePendingVideo" -> {
                    val uri = pendingVideoUri
                    pendingVideoUri = null
                    val name = pendingVideoName
                    pendingVideoName = null
                    if (uri != null) {
                        val prepared = prepareVideoUri(uri)
                        if (prepared.first != null) {
                            result.success(
                                mapOf("path" to prepared.first, "name" to (prepared.second ?: ""))
                            )
                        } else {
                            result.success(null)
                        }
                    } else {
                        result.success(null)
                    }
                }
                // ✅ 外部视频播放完毕：结束当前任务，返回调用方应用
                "finishExternalSession" -> {
                    runOnUiThread { finishAndRemoveTask() }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 9. ✅ Android 13+ 按应用设置语言通道（系统设置页 ↔ 应用内双向同步）
        //    manifest 已声明 android:localeConfig="@xml/locales_config"，
        //    用户可在「设置 → 应用 → 应用信息 → 语言」不改代码、不进应用直接切换语言。
        localeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCALE_CHANNEL)
        localeChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                // 读取系统级应用语言；Android < 13 返回 null 表示系统不支持
                "getAppLocales" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        result.success(currentAppLocaleTags())
                    } else {
                        result.success(null)
                    }
                }
                // 写入系统级应用语言；tag 为 null/空表示恢复「跟随系统」。
                // 返回 true = 系统级已生效，false = Android < 13（Dart 仅用应用内偏好）
                "setAppLocale" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val tag = call.argument<String>("tag")
                        try {
                            val lm = getSystemService(LocaleManager::class.java)
                            if (lm != null) {
                                val locales = if (tag.isNullOrBlank()) {
                                    LocaleList.getEmptyLocaleList()
                                } else {
                                    LocaleList.forLanguageTags(tag)
                                }
                                lm.applicationLocales = locales
                                lastAppLocaleTags = currentAppLocaleTags().toSet()
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.error("LOCALE_ERROR", e.message, null)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
        lastAppLocaleTags = currentAppLocaleTags().toSet()

        // 10. ✅ 存储空间：真实设备总/可用字节（StatFs）
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getStorageInfo") {
                try {
                    val stat = android.os.StatFs(cacheDir.path)
                    // 使用 cacheDir 所在分区的 StatFs，与应用实际可用空间一致
                    // 也可改用 Environment.getDataDirectory()，两者在现代 Android 上基本一致
                    val total = stat.blockCountLong * stat.blockSizeLong
                    val free = stat.availableBlocksLong * stat.blockSizeLong
                    val usable = total - free
                    result.success(mapOf(
                        "totalBytes" to total,
                        "freeBytes" to free,
                        "usedBytes" to usable
                    ))
                } catch (e: Exception) {
                    result.error("STORAGE_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }

        // 11. ✅ 桌面长按快捷入口动作通道（App Shortcuts）
        //     冷启动动作在此暂存，Dart 就绪后调用 consumePendingAction 取回；
        //     热启动时 handleShortcutIntent 直接推送 onAction。
        actionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACTION_CHANNEL)
        actionChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "consumePendingAction") {
                flutterReady = true // 能收到调用说明 Dart 侧已注册 handler
                val action = pendingShortcutAction
                pendingShortcutAction = null
                result.success(action)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun showToast(message: String) {
        runOnUiThread {
            Toast.makeText(this, message, Toast.LENGTH_LONG).show()
        }
    }

    private fun showExitConfirmationDialog() {
        runOnUiThread {
            AlertDialog.Builder(this)
                .setTitle("退出应用")
                .setMessage("退出应用吗？")
                .setIcon(android.R.drawable.ic_dialog_alert)
                .setPositiveButton("确定退出") { _, _ ->
                    finishAffinity()
                }
                .setNegativeButton("取消") { dialog, _ ->
                    dialog.dismiss()
                }
                .setCancelable(true)
                .show()
        }
    }

    private fun scanFile(path: String) {
        runOnUiThread {
            val file = File(path)
            val uri = Uri.fromFile(file)
            val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri)
            sendBroadcast(intent)
        }
    }

    private fun enterPiPMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val aspectRatio = Rational(16, 9)
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(aspectRatio)
                .build()
            try {
                enterPictureInPictureMode(params)
            } catch (e: Exception) {
                showToast("进入画中画失败: ${e.message}")
            }
        } else {
            showToast("当前 Android 版本不支持画中画")
        }
    }
}
