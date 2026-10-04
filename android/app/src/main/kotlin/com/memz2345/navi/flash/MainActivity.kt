package com.memz2345.navi.flash

import android.app.AlertDialog
import android.app.LocaleManager
import android.app.PictureInPictureParams
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.LocaleList
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Rational
import android.view.WindowManager                 
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
    private val DYNAMIC_COLOR_CHANNEL = "com.memz2345.navi.flash/dynamic_color"
    private val EXPORT_FILE_CHANNEL = "com.memz2345.navi.flash/export_file"
    private val STATS_CHANNEL = "com.memz2345.navi.flash/stats_dialog"
    private val SHORTCUT_EDITOR_CHANNEL = "com.memz2345.navi.flash/shortcut_editor"

    private var originalBrightness: Float? = null                      

                                               
    private var actionChannel: MethodChannel? = null
    private var pendingShortcutAction: String? = null

                                                   
                                                           
    private var localeChannel: MethodChannel? = null
    private var lastAppLocaleTags: Set<String> = emptySet()

                                                       
                                                        
    private var dynamicColorChannel: MethodChannel? = null

                                                 
    private var pendingVideoUri: Uri? = null
    private var pendingVideoName: String? = null
    private var openVideoChannel: MethodChannel? = null
    private var flutterReady = false                                 

                                        
                                  
    private val openVideoExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()

                                                  
    private val exportFileExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()

    companion object {
                                                   
                                                                 
        const val ACTION_EXTRA = "flash_action"

                                                   
                                                                
                                                            
                                                      
                                        
        @Volatile private var dartEverReady = false
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
                                                     
                                     
        SplashChannel.apply(this)
        configureFastRpcLibraryPath()
                                         
                                       
        DynamicShortcutPublisher.publish(this)
        handleVideoIntent(intent)
        handleLinkIntent(intent)
        handleShortcutIntent(intent)
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
                                          
        SplashChannel.onFlutterUiDisplayed()
    }

                                                                   
                                                             
                                                     
                                                           
                                                                 
                                                 
                                               
    private fun configureFastRpcLibraryPath() {
        try {
                                                                            
                                                    
                                
            val paths = listOf(
                applicationInfo.nativeLibraryDir,
                "/odm/dsp/cdsp",
                "/vendor/dsp/cdsp",
                "/vendor/lib/rfsa/adsp",
                "/system/lib/rfsa/adsp",
                "/dsp"
            ).joinToString(";")
            android.system.Os.setenv("ADSP_LIBRARY_PATH", paths, true)
        } catch (_: Exception) {
                                                 
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleVideoIntent(intent)
        handleLinkIntent(intent)
        handleShortcutIntent(intent)
    }

                                      
    private fun handleShortcutIntent(intent: Intent?) {
        val action = intent?.getStringExtra(ACTION_EXTRA) ?: return
                                                                       
                                                                    
                                                          
        dispatchAction(action)
    }

                                              
                                                            
                                         
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
                                                      
                                              
                                                         
                                    
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            dynamicColorChannel?.invokeMethod("onColorsChanged", null, null)
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val tags = currentAppLocaleTags().toSet()
        if (tags == lastAppLocaleTags) return
        lastAppLocaleTags = tags
        localeChannel?.invokeMethod(
            "onAppLocalesChanged",
            mapOf("tags" to tags.toList())
        )
    }

    override fun onResume() {
        super.onResume()
                                                            
                                                           
                                         
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            dynamicColorChannel?.invokeMethod("onColorsChanged", null, null)
        }
    }

                                                 
                                                       
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

                                                   
    private fun handleVideoIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        val scheme = uri.scheme ?: return
        if (!scheme.equals("content", true) && !scheme.equals("file", true)) return

                                  
        try {
            contentResolver.takePersistableUriPermission(
                uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (_: Exception) {}

        pendingVideoUri = uri
        pendingVideoName = queryDisplayName(uri)
        pushPendingVideoIfReady()
    }

                                                      
                                                      
                                                           
    private fun handleLinkIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_VIEW) return
        val uri = intent.data ?: return
        val scheme = uri.scheme?.lowercase() ?: return
        if (scheme != "http" && scheme != "https" && scheme != "bilibili") return
        dispatchAction("uri:$uri")
    }

                                              
    private fun dispatchAction(action: String) {
        val channel = actionChannel
        if (channel == null || (!flutterReady && !dartEverReady)) {
            pendingShortcutAction = action
        } else {
            channel.invokeMethod("onAction", action, null)
        }
    }

    private fun pushPendingVideoIfReady() {
        val uri = pendingVideoUri ?: return
        val channel = openVideoChannel ?: return
        if (!flutterReady && !dartEverReady) return
        openVideoExecutor.execute {
            val result = prepareVideoUri(uri)
            runOnUiThread {
                                                              
                if (result.first == null || pendingVideoUri !== uri) return@runOnUiThread
                pendingVideoUri = null
                pendingVideoName = null
                channel.invokeMethod(
                    "onVideoIntent",
                    mapOf("path" to result.first, "name" to (result.second ?: ""))
                )
            }
        }
    }

                                                       
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

                    
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXIT_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "exitApp") {
                showExitConfirmationDialog()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

                                 
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

                          
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enterPiP") {
                enterPiPMode()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

                                                     
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRIGHTNESS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBrightness" -> {
                    val lp = window.attributes
                                                     
                    result.success(if (lp.screenBrightness < 0) 0.5 else lp.screenBrightness.toDouble())
                }
                "setBrightness" -> {
                    val brightness = (call.arguments as? Double)?.toFloat() ?: 0.5f
                                          
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
                                   
                    lp.screenBrightness = originalBrightness ?: WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    window.attributes = lp
                    originalBrightness = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

                            
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EASTER_EGG_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openEasterEgg") {
                val intent = Intent(this@MainActivity, EasterEggActivity::class.java)
                startActivity(intent)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

                              
        openVideoChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OPEN_VIDEO_CHANNEL)
        openVideoChannel!!.setMethodCallHandler { call, result ->
            dartEverReady = true
            flutterReady = true                             
            when (call.method) {
                "consumePendingVideo" -> {
                    val uri = pendingVideoUri
                    pendingVideoUri = null
                    val name = pendingVideoName
                    pendingVideoName = null
                    if (uri != null) {
                                                         
                                               
                        openVideoExecutor.execute {
                            val prepared = prepareVideoUri(uri)
                            runOnUiThread {
                                if (prepared.first != null) {
                                    result.success(
                                        mapOf("path" to prepared.first, "name" to (prepared.second ?: ""))
                                    )
                                } else {
                                    result.success(null)
                                }
                            }
                        }
                    } else {
                        result.success(null)
                    }
                }
                                            
                "finishExternalSession" -> {
                    runOnUiThread { finishAndRemoveTask() }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

                                                      
                                                                      
                                                       
        localeChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCALE_CHANNEL)
        localeChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                                                         
                "getAppLocales" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        result.success(currentAppLocaleTags())
                    } else {
                        result.success(null)
                    }
                }
                                                    
                                                                      
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

                                        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getStorageInfo") {
                try {
                    val stat = android.os.StatFs(cacheDir.path)
                                                           
                                                                              
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

                                            
                                                            
                                                       
        actionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACTION_CHANNEL)
        actionChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "consumePendingAction") {
                dartEverReady = true
                flutterReady = true                             
                val action = pendingShortcutAction
                pendingShortcutAction = null
                result.success(action)
            } else {
                result.notImplemented()
            }
        }

                                                     
                                                                    
        LiveUpdateChannel(this).register(flutterEngine.dartExecutor.binaryMessenger)

                                         
                                                  
        SplashChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)

                                                               
                                                       
        dynamicColorChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DYNAMIC_COLOR_CHANNEL)

                                                  
                                                             
                                           
        FavWidgetChannel(this).register(flutterEngine.dartExecutor.binaryMessenger)

                                                   
                                                        
                                                  
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXPORT_FILE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "saveToDownloads") {
                val path = call.argument<String>("path")
                val name = call.argument<String>("name")
                val mime = call.argument<String>("mime") ?: "application/octet-stream"
                if (path == null || name == null) {
                    result.error("BAD_ARGS", "path/name is null", null)
                    return@setMethodCallHandler
                }
                val src = File(path)
                if (!src.exists()) {
                    result.error("NO_SOURCE", "source file not found: $path", null)
                    return@setMethodCallHandler
                }
                exportFileExecutor.execute {
                    try {
                        val saved = saveExportFileToDownloads(src, name, mime)
                        runOnUiThread { result.success(saved) }
                    } catch (e: Exception) {
                        runOnUiThread { result.error("SAVE_FAILED", e.message, null) }
                    }
                }
            } else {
                result.notImplemented()
            }
        }

                                                           
                                                                
                                                      
        val statsChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STATS_CHANNEL)
        statsChannel.setMethodCallHandler { call, result ->
            if (call.method == "showStats") {
                val title = call.argument<String>("title") ?: ""
                val copyLabel = call.argument<String>("copyLabel") ?: "复制"
                val closeLabel = call.argument<String>("closeLabel") ?: "关闭"
                val entries = (call.argument<List<*>>("entries") ?: emptyList<Any>())
                    .mapNotNull { row ->
                        val pair = row as? List<*> ?: return@mapNotNull null
                        val label = pair.getOrNull(0) as? String ?: return@mapNotNull null
                        val value = pair.getOrNull(1) as? String ?: return@mapNotNull null
                        label to value
                    }
                StatsDialogHost.show(this, statsChannel, title, entries, copyLabel, closeLabel)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

                                                       
                                                                  
                                          
        NativeMenuHost.install(this, flutterEngine.dartExecutor.binaryMessenger)

                                                        
                                                                       
        LiquidGlassBarHost.install(this, flutterEngine.dartExecutor.binaryMessenger)

                                                              
                                                              
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHORTCUT_EDITOR_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "open") {
                val colors = android.os.Bundle().apply {
                    fun putColor(key: String, value: Any?) {
                        val v = (value as? Number)?.toInt() ?: return
                        putInt(key, v)
                    }
                    val m = call.argument<Map<*, *>>("colors") ?: emptyMap<String, Any?>()
                    putColor("primary", m["primary"])
                    putColor("onSurface", m["onSurface"])
                    putColor("surface", m["surface"])
                    putColor("surfaceContainer", m["surfaceContainer"])
                    putColor("surfaceContainerHigh", m["surfaceContainerHigh"])
                    putColor("onSurfaceVariant", m["onSurfaceVariant"])
                    putColor("outline", m["outline"])
                    putBoolean("dark", (m["dark"] as? Boolean) ?: false)
                }
                val intent = Intent(this, ShortcutEditorActivity::class.java).apply {
                    putExtra("colors", colors)
                }
                startActivity(intent)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

                                                        
        InteractionBarHost.install(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
        )

                                              
                                                                          
        DeviceCornerChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)

                                      
                                                                 
        AppLinkChannel.register(this, flutterEngine.dartExecutor.binaryMessenger)

                                               
                                                        
        StorageLocationsChannel(this).register(flutterEngine.dartExecutor.binaryMessenger)

                                        
                                                                 
        ModelDownloadChannel(this).register(flutterEngine.dartExecutor.binaryMessenger)

                                                                        
                                                  
                                                                
        NativeTooltipHost.install(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
                                                           
                                       
        StatsDialogHost.dismiss()
                                                      
        NativeMenuHost.dispose()
        LiquidGlassBarHost.dispose()
        InteractionBarHost.dispose()
        NativeTooltipHost.dispose()
        super.onDestroy()
    }

                                 
    private fun saveExportFileToDownloads(src: File, rawName: String, mime: String): String {
                       
        val safeName = rawName.substringAfterLast('/')
            .replace(Regex("[\\\\/:*?\"<>|\\p{Cntrl}]"), "_")
            .ifBlank { "export_${System.currentTimeMillis()}" }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, safeName)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/NaviFlash"
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            val uri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("MediaStore.insert returned null")
            contentResolver.openOutputStream(uri, "w").use { os ->
                if (os == null) throw IllegalStateException("openOutputStream returned null")
                src.inputStream().use { it.copyTo(os, 64 * 1024) }
            }
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            return "Download/NaviFlash/$safeName"
        } else {
            val dir = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                "NaviFlash"
            )
            if (!dir.exists()) dir.mkdirs()
            var dst = File(dir, safeName)
                                
            if (dst.exists()) {
                val dot = safeName.lastIndexOf('.')
                val base = if (dot > 0) safeName.substring(0, dot) else safeName
                val ext = if (dot > 0) safeName.substring(dot) else ""
                var i = 1
                while (File(dir, "$base ($i)$ext").exists()) i++
                dst = File(dir, "$base ($i)$ext")
            }
            src.inputStream().use { input ->
                dst.outputStream().use { input.copyTo(it, 64 * 1024) }
            }
                             
            sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, Uri.fromFile(dst)))
            return dst.absolutePath
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
