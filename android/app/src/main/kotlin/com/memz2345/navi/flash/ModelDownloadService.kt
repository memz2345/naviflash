package com.memz2345.navi.flash

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

   
              
  
                                                   
                                             
                             
                                               
                                                        
                            
                                          
                                               
  
                                            
                                             
                                                                    
   
class ModelDownloadService : Service() {

                   
    data class FileSpec(
        val url: String,
        val path: String,
        val bytes: Long,
        val name: String
    ) {
        fun toMap(): Map<String, Any?> = mapOf(
            "url" to url, "path" to path, "bytes" to bytes, "name" to name
        )

        companion object {
            fun fromMap(m: Map<*, *>?): FileSpec? {
                if (m == null) return null
                val url = m["url"] as? String ?: return null
                val path = m["path"] as? String ?: return null
                val name = m["name"] as? String ?: File(path).name
                val bytes = when (val b = m["bytes"]) {
                    is Long -> b
                    is Int -> b.toLong()
                    is Double -> b.toLong()
                    else -> 0L
                }
                return FileSpec(url, path, bytes, name)
            }
        }
    }

    companion object {
        private const val TAG = "ModelDownloadService"
        const val CHANNEL_NAME = "com.memz2345.navi.flash/model_download"
        const val NOTIFICATION_ID = 4810
        private const val NOTIFICATION_CHANNEL_ID = "model_download"
        private const val ACTION_CANCEL = "com.memz2345.navi.flash.action.MODEL_DOWNLOAD_CANCEL"
        private const val BUFFER = 64 * 1024
        private const val AUTO_REMOVE_DELAY_MS = 5000L

                                                                          
        @Volatile
        var flutterChannel: MethodChannel? = null

                                                  
        @Volatile
        var running: Boolean = false
            private set
        @Volatile
        var lastReceived: Long = 0
            private set
        @Volatile
        var lastTotal: Long = 0
            private set
        @Volatile
        var lastName: String = ""
            private set

        fun start(context: Context, title: String, files: List<FileSpec>) {
            val intent = Intent(context, ModelDownloadService::class.java).apply {
                putExtra("title", title)
                putStringArrayListExtra("urls", ArrayList(files.map { it.url }))
                putStringArrayListExtra("paths", ArrayList(files.map { it.path }))
                putStringArrayListExtra("names", ArrayList(files.map { it.name }))
                putExtra("bytes", files.map { it.bytes }.toLongArray())
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Throwable) {
                Log.w(TAG, "startForegroundService 失败：${e.message}")
                                                 
                              
                try {
                    context.startService(intent)
                } catch (_: Throwable) {
                }
            }
        }

        fun cancel(context: Context) {
            context.startService(
                Intent(context, ModelDownloadService::class.java)
                    .setAction(ACTION_CANCEL)
            )
        }
    }

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val cancelled = AtomicBoolean(false)
    private val notificationManager by lazy {
        getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
    }

    private var titleText = "模型下载"
    private var specs: List<FileSpec> = emptyList()
    private var doneBytes = 0L
    private var totalBytes = 0L
    private var lastNotifyMs = 0L

    override fun onBind(intent: Intent?) = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_CANCEL) {
            cancelled.set(true)
            return START_NOT_STICKY
        }
        titleText = intent?.getStringExtra("title") ?: "模型下载"
        specs = parseSpecs(intent)
        if (specs.isEmpty()) {
            stopSelf()
            return START_NOT_STICKY
        }
        totalBytes = specs.sumOf { it.bytes }
        doneBytes = 0L
        lastReceived = 0L
        lastTotal = totalBytes
        lastName = specs.firstOrNull()?.name ?: ""
        running = true
        cancelled.set(false)

        startAsForeground()
        executor.execute { runDownload() }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        running = false
        cancelled.set(true)
        executor.shutdownNow()
        super.onDestroy()
    }

    private fun parseSpecs(intent: Intent?): List<FileSpec> {
        val urls = intent?.getStringArrayListExtra("urls") ?: return emptyList()
        val paths = intent?.getStringArrayListExtra("paths") ?: return emptyList()
        val names = intent?.getStringArrayListExtra("names") ?: return emptyList()
        val bytes = intent?.getLongArrayExtra("bytes") ?: LongArray(0)
        val out = ArrayList<FileSpec>()
        for (i in urls.indices) {
            if (i >= paths.size) break
            out.add(
                FileSpec(
                    url = urls[i],
                    path = paths[i],
                    bytes = bytes.getOrNull(i) ?: 0L,
                    name = names.getOrNull(i) ?: File(paths[i]).name
                )
            )
        }
        return out
    }

                                                
          
                                                

    private fun runDownload() {
        var error: String? = null
        try {
            for (spec in specs) {
                if (cancelled.get()) break
                if (isComplete(spec)) {
                    doneBytes += spec.bytes
                    continue
                }
                downloadOne(spec)
                if (cancelled.get()) break
                doneBytes += spec.bytes
            }
        } catch (e: Throwable) {
            error = e.message ?: e.toString()
            Log.w(TAG, "下载异常：$error")
        }

        if (cancelled.get()) {
            notifyCancelled()
            push("onCanceled", mapOf("received" to doneBytes, "total" to totalBytes))
        } else if (error != null) {
            val msg = "下载中断：$error"
            notifyFinished(false, msg)
            push("onError", mapOf("message" to msg, "received" to doneBytes))
        } else {
            notifyFinished(true, "下载完成")
            push(
                "onComplete",
                mapOf(
                    "paths" to specs.map { it.path },
                    "received" to totalBytes,
                    "total" to totalBytes
                )
            )
        }
        running = false
                                
        mainHandler.postDelayed({
            stopForegroundCompat()
            stopSelf()
        }, AUTO_REMOVE_DELAY_MS)
    }

    private fun isComplete(spec: FileSpec): Boolean {
        if (spec.bytes <= 0) return false
        val f = File(spec.path)
        if (!f.exists()) return false
        return f.length() >= spec.bytes * 98L / 100L
    }

    private fun downloadOne(spec: FileSpec) {
        val target = File(spec.path)
        val part = File(spec.path + ".part")
        target.parentFile?.mkdirs()

        var offset = if (part.exists()) part.length() else 0L
        if (offset == 0L && target.exists() && target.length() > 0) {
                                        
            if (target.renameTo(part)) offset = part.length()
        }
        if (offset > spec.bytes && spec.bytes > 0) {
            part.delete()
            offset = 0L
        }

        val conn = java.net.URL(spec.url).openConnection() as HttpURLConnection
        try {
            conn.instanceFollowRedirects = true
            conn.connectTimeout = 30_000
            conn.readTimeout = 60_000
            if (offset > 0) conn.setRequestProperty("Range", "bytes=$offset-")
            conn.connect()
            val code = conn.responseCode
            if (code == HttpURLConnection.HTTP_OK && offset > 0) {
                                         
                offset = 0L
            } else if (code != HttpURLConnection.HTTP_OK &&
                code != HttpURLConnection.HTTP_PARTIAL
            ) {
                throw IllegalStateException("HTTP $code")
            }
            val contentLength = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                conn.contentLengthLong
            } else {
                conn.contentLength.toLong()
            }
            val streamFull = if (code == HttpURLConnection.HTTP_PARTIAL) {
                offset + contentLength.coerceAtLeast(0)
            } else {
                contentLength.coerceAtMost(spec.bytes.takeIf { it > 0 } ?: Long.MAX_VALUE)
                    .coerceAtLeast(0)
            }

            FileOutputStream(part, offset > 0).use { out ->
                conn.inputStream.use { input ->
                    val buf = ByteArray(BUFFER)
                    var received = offset
                    while (true) {
                        if (cancelled.get()) return
                        val n = input.read(buf)
                        if (n <= 0) break
                        out.write(buf, 0, n)
                        received += n
                        report(received, streamFull.coerceAtLeast(spec.bytes), spec.name)
                    }
                }
            }
            if (spec.bytes > 0 && part.length() < spec.bytes * 98L / 100L) {
                throw IllegalStateException("文件不完整（${part.length()}/${spec.bytes}）")
            }
            if (target.exists()) target.delete()
            if (!part.renameTo(target)) {
                throw IllegalStateException("无法写入 ${target.absolutePath}")
            }
        } finally {
            conn.disconnect()
        }
    }

                                                    
    private fun report(received: Long, totalOfFile: Long, name: String) {
        val now = android.os.SystemClock.elapsedRealtime()
        if (now - lastNotifyMs < 200L && received < totalOfFile) return
        lastNotifyMs = now
                                
        val overall = doneBytes + received.coerceAtMost(totalOfFile)
        lastReceived = overall
        lastTotal = totalBytes.coerceAtLeast(overall)
        lastName = name
        val percent = if (lastTotal > 0) {
            (overall * 100L / lastTotal).toInt().coerceIn(0, 100)
        } else {
            0
        }
        updateNotification(percent, name, sizeText(overall, lastTotal))
        push(
            "onProgress",
            mapOf(
                "received" to overall,
                "total" to lastTotal,
                "percent" to percent,
                "name" to name
            )
        )
    }

    private fun sizeText(received: Long, total: Long): String {
        fun mb(v: Long) = "%.1fMB".format(v / 1024.0 / 1024.0)
        return if (total > 0) "${mb(received)} / ${mb(total)}" else mb(received)
    }

                                                
                                   
                                                

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = notificationManager ?: return
        if (nm.getNotificationChannel(NOTIFICATION_CHANNEL_ID) != null) return
        val ch = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "模型下载",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "AI 朗读 / 智能防遮挡模型的后台下载进度"
            setShowBadge(false)
            enableVibration(false)
            enableLights(false)
        }
        nm.createNotificationChannel(ch)
    }

    private fun startAsForeground() {
        val notif = buildNotification(
            title = titleText,
            text = "准备下载…",
            progress = 0,
            indeterminate = true,
            ongoing = true
        )
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notif,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                )
            } else {
                startForeground(NOTIFICATION_ID, notif)
            }
        } catch (e: Throwable) {
            Log.w(TAG, "startForeground 失败：${e.message}")
        }
    }

    private fun updateNotification(percent: Int, name: String, text: String) {
        notificationManager?.notify(
            NOTIFICATION_ID,
            buildNotification(
                title = titleText,
                text = "$name · $text",
                progress = percent,
                indeterminate = false,
                ongoing = true
            )
        )
    }

    private fun notifyFinished(ok: Boolean, text: String) {
        notificationManager?.notify(
            NOTIFICATION_ID,
            buildNotification(
                title = titleText,
                text = text,
                progress = if (ok) 100 else 0,
                indeterminate = false,
                ongoing = false
            )
        )
    }

    private fun notifyCancelled() {
        notificationManager?.notify(
            NOTIFICATION_ID,
            buildNotification(
                title = titleText,
                text = "已取消（断点已保留）",
                progress = 0,
                indeterminate = false,
                ongoing = false
            )
        )
    }

    private fun buildNotification(
        title: String,
        text: String,
        progress: Int,
        indeterminate: Boolean,
        ongoing: Boolean
    ): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        builder
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title)
            .setContentText(text)
            .setOnlyAlertOnce(true)
            .setOngoing(ongoing)
            .setAutoCancel(!ongoing)
            .setDeleteIntent(cancelIntent())

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            val style = Notification.ProgressStyle()
            if (indeterminate) style.setProgressIndeterminate(true) else style.setProgress(progress)
            builder.setStyle(style)
            if (ongoing) requestPromotedOngoing(builder)
        } else {
            builder.setProgress(100, progress, indeterminate)
        }
        return builder.build()
    }

       
                                           
                                                                            
                                   
       
    private fun requestPromotedOngoing(builder: Notification.Builder) {
        try {
            val m = Notification.Builder::class.java.getMethod(
                "setRequestPromotedOngoing",
                Boolean::class.javaPrimitiveType
            )
            m.invoke(builder, true)
            return
        } catch (_: Throwable) {
        }
        try {
            val key = Notification::class.java
                .getField("EXTRA_REQUEST_PROMOTED_ONGOING")
                .get(null) as? String
            if (key != null) builder.extras.putBoolean(key, true)
        } catch (_: Throwable) {
        }
    }

                      
    private fun cancelIntent(): PendingIntent? {
        return try {
            val intent = Intent(this, ModelDownloadReceiver::class.java)
                .setAction(ACTION_CANCEL)
            val flags = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                PendingIntent.getBroadcast(this, NOTIFICATION_ID, intent, flags)
            } else {
                PendingIntent.getBroadcast(this, NOTIFICATION_ID, intent, flags)
            }
        } catch (_: Throwable) {
            null
        }
    }

    private fun stopForegroundCompat() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Throwable) {
        }
    }

                                                

                             
    private fun push(method: String, args: Map<String, Any?>) {
        val channel = flutterChannel ?: return
        mainHandler.post {
            try {
                channel.invokeMethod(method, args)
            } catch (e: Throwable) {
                Log.w(TAG, "回推 $method 失败：${e.message}")
            }
        }
    }
}
