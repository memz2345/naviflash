package com.memz2345.navi.flash

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

   
                           
  
                                         
      
                                                                           
                                                               
                                                                        
                                                                             
                                                                         
                                                       
  
                                                                                          
                                                             
                                                             
                                                         
  
                                                   
   
class LiveUpdateChannel(context: Context) {

    companion object {
        private const val CHANNEL_NAME = "com.memz2345.navi.flash/live_update"
        private const val NOTIFICATION_CHANNEL_ID = "live_update"
        private const val ACTION_DISMISSED =
            "com.memz2345.navi.flash.action.LIVE_UPDATE_DISMISSED"
        private const val EXTRA_ID = "live_update_id"
        private const val AUTO_REMOVE_DELAY_MS = 4000L
        private const val COVER_MAX_PX = 256

                                                                  
                                                        
                                                  
        private val receiverRegistered = java.util.concurrent.atomic.AtomicBoolean(false)
        private val dismissedIdsGlobal = HashSet<Int>()

        private val dismissReceiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                val id = intent?.getIntExtra(EXTRA_ID, Int.MIN_VALUE) ?: Int.MIN_VALUE
                if (id != Int.MIN_VALUE) synchronized(dismissedIdsGlobal) {
                    dismissedIdsGlobal.add(id)
                }
            }
        }
    }

    private val appContext: Context = context.applicationContext
    private val notificationManager: NotificationManager? =
        appContext.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
    private val mainHandler = Handler(Looper.getMainLooper())

                                         
    private val autoRemoveRunnables = HashMap<Int, Runnable>()

                                               
                                   
    private var currentCover: Bitmap? = null

    fun register(messenger: BinaryMessenger) {
        createNotificationChannel()
                                                
                                         
        if (receiverRegistered.compareAndSet(false, true)) {
            try {
                val filter = IntentFilter(ACTION_DISMISSED)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    ContextCompat.registerReceiver(
                        appContext,
                        dismissReceiver,
                        filter,
                        ContextCompat.RECEIVER_NOT_EXPORTED
                    )
                } else {
                    appContext.registerReceiver(dismissReceiver, filter)
                }
            } catch (_: Exception) {
                receiverRegistered.set(false)
                                       
            }
        }

        MethodChannel(messenger, CHANNEL_NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(isPromotedSupported())
                "start" -> {
                    val id = call.argument<Int>("id")
                    val title = call.argument<String>("title")
                    if (id == null || title == null) {
                        result.error("INVALID_ARG", "id/title is null", null)
                    } else {
                        val cover = call.argument<ByteArray>("cover")
                        start(id, title, call.argument<String>("text"), cover)
                        result.success(null)
                    }
                }
                "update" -> {
                    val id = call.argument<Int>("id")
                    if (id == null) {
                        result.error("INVALID_ARG", "id is null", null)
                    } else {
                        val progress = (call.argument<Number>("progress") ?: 0).toInt()
                        val indeterminate = call.argument<Boolean>("indeterminate") ?: false
                        update(id, progress, call.argument<String>("text"), indeterminate)
                        result.success(null)
                    }
                }
                "finish", "fail" -> {
                    val id = call.argument<Int>("id")
                    if (id == null) {
                        result.error("INVALID_ARG", "id is null", null)
                    } else if (call.method == "finish") {
                        finish(id, call.argument<String>("title"), call.argument<String>("text"))
                        result.success(null)
                    } else {
                        fail(id, call.argument<String>("title"), call.argument<String>("text"))
                        result.success(null)
                    }
                }
                "cancel" -> {
                    val id = call.argument<Int>("id")
                    if (id == null) {
                        result.error("INVALID_ARG", "id is null", null)
                    } else {
                        cancel(id)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

                                           
                                                               
                         
    private fun isPromotedSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.BAKLAVA) return false
        val nm = notificationManager ?: return false
        return try {
            if (!nm.areNotificationsEnabled()) return false
            val m = try {
                NotificationManager::class.java.getMethod("canPostPromotedNotifications")
            } catch (_: Throwable) {
                null
            }
            if (m != null) (m.invoke(nm) as? Boolean) ?: true else true
        } catch (_: Throwable) {
            false
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = notificationManager ?: return
                                                   
        if (nm.getNotificationChannel(NOTIFICATION_CHANNEL_ID) != null) return
        val ch = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "离线缓存实时更新",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "手动缓存视频时在锁屏与状态栏显示下载进度"
            setShowBadge(false)
            enableVibration(false)
            enableLights(false)
        }
        nm.createNotificationChannel(ch)
    }

    private fun start(id: Int, title: String, text: String?, cover: ByteArray?) {
        synchronized(dismissedIdsGlobal) { dismissedIdsGlobal.remove(id) }
        cancelAutoRemove(id)
        currentCover = cover?.let { decodeCover(it) }
        notificationManager?.notify(
            id,
            buildNotification(
                id = id,
                title = title,
                text = text ?: "准备下载…",
                progress = 0,
                indeterminate = true,
                ongoing = true,
                promoted = true
            )
        )
    }

    private fun update(id: Int, progress: Int, text: String?, indeterminate: Boolean) {
        synchronized(dismissedIdsGlobal) {
            if (dismissedIdsGlobal.contains(id)) return
        }
        notificationManager?.notify(
            id,
            buildNotification(
                id = id,
                title = currentTitle(id) ?: "离线缓存",
                text = text ?: "",
                progress = progress,
                indeterminate = indeterminate,
                ongoing = true,
                promoted = true
            )
        )
    }

    private fun finish(id: Int, title: String?, text: String?) {
        synchronized(dismissedIdsGlobal) { dismissedIdsGlobal.remove(id) }
        notificationManager?.notify(
            id,
            buildNotification(
                id = id,
                title = title ?: currentTitle(id) ?: "离线缓存",
                text = text ?: "下载完成",
                progress = 100,
                indeterminate = false,
                ongoing = false,
                promoted = false
            )
        )
        scheduleAutoRemove(id)
    }

    private fun fail(id: Int, title: String?, text: String?) {
        synchronized(dismissedIdsGlobal) { dismissedIdsGlobal.remove(id) }
        notificationManager?.notify(
            id,
            buildNotification(
                id = id,
                title = title ?: currentTitle(id) ?: "离线缓存",
                text = text ?: "下载失败",
                progress = 0,
                indeterminate = false,
                ongoing = false,
                promoted = false
            )
        )
        scheduleAutoRemove(id)
    }

    private fun cancel(id: Int) {
        cancelAutoRemove(id)
        currentCover = null
        notificationManager?.cancel(id)
    }

                                            
                                       
    private fun decodeCover(bytes: ByteArray): Bitmap? {
        return try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            var sample = 1
            val maxEdge = maxOf(bounds.outWidth, bounds.outHeight)
            while (maxEdge > 0 && maxEdge / sample > COVER_MAX_PX) sample *= 2
            val opts = BitmapFactory.Options().apply { inSampleSize = sample }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, opts)
        } catch (_: Throwable) {
            null
        }
    }

    private fun scheduleAutoRemove(id: Int) {
        cancelAutoRemove(id)
        val r = Runnable {
            notificationManager?.cancel(id)
            autoRemoveRunnables.remove(id)
        }
        autoRemoveRunnables[id] = r
        mainHandler.postDelayed(r, AUTO_REMOVE_DELAY_MS)
    }

    private fun cancelAutoRemove(id: Int) {
        autoRemoveRunnables.remove(id)?.let { mainHandler.removeCallbacks(it) }
    }

                                     
    private fun currentTitle(id: Int): String? {
        return try {
            notificationManager?.activeNotifications
                ?.firstOrNull { it.id == id }
                ?.notification
                ?.extras
                ?.getCharSequence(Notification.EXTRA_TITLE)
                ?.toString()
        } catch (_: Throwable) {
            null
        }
    }

    private fun deleteIntent(id: Int): PendingIntent {
        val intent = Intent(ACTION_DISMISSED)
            .setPackage(appContext.packageName)
            .putExtra(EXTRA_ID, id)
        return PendingIntent.getBroadcast(appContext,
            id,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun buildNotification(
        id: Int,
        title: String,
        text: String,
        progress: Int,
        indeterminate: Boolean,
        ongoing: Boolean,
        promoted: Boolean
    ): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(appContext, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(appContext)
        }
        builder
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title)
            .setContentText(text)
            .setOnlyAlertOnce(true)
            .setOngoing(ongoing)
            .setAutoCancel(!ongoing)
            .setDeleteIntent(deleteIntent(id))

                                         
        currentCover?.let { builder.setLargeIcon(it) }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
                                                               
            val style = Notification.ProgressStyle()
            if (indeterminate) {
                style.setProgressIndeterminate(true)
            } else {
                style.setProgress(progress.coerceIn(0, 100))
            }
            builder.setStyle(style)
                                       
            if (promoted && ongoing) requestPromotedOngoing(builder)
        } else {
                          
            builder.setProgress(100, progress.coerceIn(0, 100), indeterminate)
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
            if (key != null) {
                builder.extras.putBoolean(key, true)
            }
        } catch (_: Throwable) {
                                  
        }
    }
}
